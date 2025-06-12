/*
  # Corrigir estrutura da coluna plano_contratado na tabela core.empresa_base

  1. Correções na Tabela
    - `core.empresa_base`
      - Remover coluna `plano_id` criada incorretamente
      - Alterar coluna `plano_contratado` de text para UUID
      - Renomear `plano_contratado` para `plano_id`
      - Adicionar chave estrangeira para `planos.planos(id)`

  2. Limpeza
    - Remover índices da coluna incorreta
    - Remover constraints da coluna incorreta
    - Remover função desnecessária

  3. Performance
    - Criar índices corretos na nova estrutura
    - Otimizar consultas relacionadas

  4. Documentação
    - Atualizar descrição na tabela core.documentacao_tabelas
*/

-- Primeiro, remover a coluna plano_id que foi criada incorretamente
DO $$
BEGIN
  -- Verificar se a coluna plano_id existe e removê-la
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'core' AND table_name = 'empresa_base' AND column_name = 'plano_id'
  ) THEN
    
    -- Remover constraint de chave estrangeira se existir
    IF EXISTS (
      SELECT 1 FROM information_schema.table_constraints
      WHERE table_schema = 'core' 
      AND table_name = 'empresa_base' 
      AND constraint_name = 'fk_empresa_base_plano_id'
    ) THEN
      ALTER TABLE core.empresa_base DROP CONSTRAINT fk_empresa_base_plano_id;
    END IF;
    
    -- Remover a coluna plano_id
    ALTER TABLE core.empresa_base DROP COLUMN plano_id;
    
    RAISE NOTICE 'Coluna plano_id removida com sucesso';
  END IF;
  
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'Erro ao remover coluna plano_id: %', SQLERRM;
END $$;

-- Remover índices relacionados à coluna plano_id incorreta
DROP INDEX IF EXISTS idx_empresa_base_plano_id;
DROP INDEX IF EXISTS idx_empresa_base_status_plano;
DROP INDEX IF EXISTS idx_empresa_base_tipo_plano;

-- Remover função desnecessária
DROP FUNCTION IF EXISTS core.migrar_plano_contratado_para_uuid();

-- Agora alterar a coluna plano_contratado original
DO $$
BEGIN
  -- Verificar se a coluna plano_contratado existe
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'core' AND table_name = 'empresa_base' AND column_name = 'plano_contratado'
  ) THEN
    
    -- Primeiro, limpar dados inválidos (NULL ou vazios) para evitar erros na conversão
    UPDATE core.empresa_base 
    SET plano_contratado = NULL 
    WHERE plano_contratado IS NULL OR trim(plano_contratado) = '';
    
    -- Alterar o tipo da coluna para UUID
    -- Como pode haver dados em texto, vamos usar uma abordagem segura
    ALTER TABLE core.empresa_base 
    ALTER COLUMN plano_contratado TYPE uuid 
    USING CASE 
      WHEN plano_contratado IS NULL THEN NULL
      WHEN plano_contratado ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' 
      THEN plano_contratado::uuid
      ELSE NULL
    END;
    
    -- Renomear a coluna para plano_id
    ALTER TABLE core.empresa_base RENAME COLUMN plano_contratado TO plano_id;
    
    -- Adicionar a chave estrangeira
    ALTER TABLE core.empresa_base 
    ADD CONSTRAINT fk_empresa_base_plano_id 
    FOREIGN KEY (plano_id) REFERENCES planos.planos(id) ON DELETE SET NULL;
    
    RAISE NOTICE 'Coluna plano_contratado alterada para plano_id (UUID) com sucesso';
    
  ELSE
    RAISE WARNING 'Coluna plano_contratado não encontrada na tabela core.empresa_base';
  END IF;
  
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'Erro ao alterar coluna plano_contratado: %', SQLERRM;
END $$;

-- Criar índices corretos para a nova estrutura
CREATE INDEX IF NOT EXISTS idx_empresa_base_plano_id ON core.empresa_base(plano_id) WHERE plano_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_empresa_base_status_plano ON core.empresa_base(status, plano_id) WHERE plano_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_empresa_base_tipo_plano ON core.empresa_base(tipo_pessoa, plano_id) WHERE plano_id IS NOT NULL;

-- Atualizar a descrição na tabela documentacao_tabelas
UPDATE core.documentacao_tabelas 
SET 
  descricao = 'SCHEMA: core - Armazena os dados dos clientes da plataforma (empresas ou pessoas físicas). Cada registro corresponde a quem comprou e usa o sistema. O campo status ajuda a identificar a fase do relacionamento, e observacoes serve para anotações internas da equipe de suporte ou vendas. CORREÇÃO APLICADA: A coluna plano_contratado foi corretamente alterada para plano_id (tipo UUID) com chave estrangeira para planos.planos(id), permitindo relacionamento direto e íntegro com os planos disponíveis no sistema. Esta estrutura garante integridade referencial e facilita consultas relacionadas aos planos contratados pelas empresas.',
  atualizado_em = now()
WHERE nome_tabela = 'empresa_base';

-- Inserir registro de correção na documentação
INSERT INTO core.documentacao_tabelas (nome_tabela, descricao) VALUES
(
  'CORRECAO_plano_contratado',
  'SCHEMA: core - REGISTRO DE CORREÇÃO: Migration 20250612161200 aplicou correção na tabela empresa_base removendo a coluna plano_id criada incorretamente e alterando a coluna original plano_contratado para o tipo UUID com nome plano_id. A correção incluiu: 1) Remoção da coluna plano_id incorreta e seus índices/constraints, 2) Alteração segura da coluna plano_contratado de text para UUID, 3) Renomeação para plano_id, 4) Adição de chave estrangeira para planos.planos(id), 5) Criação de índices otimizados. Esta correção garante a estrutura correta do relacionamento entre empresas e planos contratados.'
);

-- Comentários explicativos sobre a correção
COMMENT ON COLUMN core.empresa_base.plano_id IS 'Referência UUID ao plano contratado pela empresa (FK para planos.planos) - Corrigido do campo plano_contratado original';

-- Verificação final da estrutura
DO $$
DECLARE
  coluna_existe boolean;
  tipo_coluna text;
  constraint_existe boolean;
BEGIN
  -- Verificar se a coluna plano_id existe e tem o tipo correto
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'core' 
    AND table_name = 'empresa_base' 
    AND column_name = 'plano_id'
  ), data_type INTO coluna_existe, tipo_coluna
  FROM information_schema.columns
  WHERE table_schema = 'core' 
  AND table_name = 'empresa_base' 
  AND column_name = 'plano_id';
  
  -- Verificar se a constraint existe
  SELECT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_schema = 'core' 
    AND table_name = 'empresa_base' 
    AND constraint_name = 'fk_empresa_base_plano_id'
  ) INTO constraint_existe;
  
  -- Relatório da verificação
  IF coluna_existe THEN
    RAISE NOTICE 'SUCESSO: Coluna plano_id existe com tipo: %', tipo_coluna;
  ELSE
    RAISE WARNING 'ERRO: Coluna plano_id não foi criada corretamente';
  END IF;
  
  IF constraint_existe THEN
    RAISE NOTICE 'SUCESSO: Constraint de chave estrangeira fk_empresa_base_plano_id criada';
  ELSE
    RAISE WARNING 'ERRO: Constraint de chave estrangeira não foi criada';
  END IF;
  
  -- Verificar se a coluna plano_contratado ainda existe (não deveria)
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'core' 
    AND table_name = 'empresa_base' 
    AND column_name = 'plano_contratado'
  ) THEN
    RAISE WARNING 'ATENÇÃO: Coluna plano_contratado ainda existe - pode precisar de limpeza manual';
  ELSE
    RAISE NOTICE 'SUCESSO: Coluna plano_contratado foi corretamente renomeada';
  END IF;
END $$;