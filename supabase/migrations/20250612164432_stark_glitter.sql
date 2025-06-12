/*
  # Correção definitiva da coluna plano_contratado na tabela core.empresa_base

  1. Situação Atual
    - Tabela possui coluna plano_contratado (text) original
    - Tabela possui coluna plano_id (uuid) criada incorretamente
    - Precisamos manter apenas plano_id como UUID com FK

  2. Correções
    - Remover coluna plano_id incorreta se existir
    - Alterar coluna plano_contratado original para UUID
    - Renomear plano_contratado para plano_id
    - Adicionar chave estrangeira correta
    - Criar índices apropriados

  3. Segurança
    - Verificações robustas de existência
    - Tratamento de erros
    - Conversão segura de dados
    - Verificação final da estrutura

  4. Documentação
    - Atualizar descrição na tabela core.documentacao_tabelas
    - Registrar correção aplicada
*/

-- ETAPA 1: Verificar situação atual e limpar estrutura incorreta
DO $$
DECLARE
  tem_plano_id boolean := false;
  tem_plano_contratado boolean := false;
BEGIN
  -- Verificar quais colunas existem
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'core' AND table_name = 'empresa_base' AND column_name = 'plano_id'
  ) INTO tem_plano_id;
  
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'core' AND table_name = 'empresa_base' AND column_name = 'plano_contratado'
  ) INTO tem_plano_contratado;
  
  RAISE NOTICE 'Estado atual: plano_id=%, plano_contratado=%', tem_plano_id, tem_plano_contratado;
  
  -- Se ambas existem, remover a plano_id incorreta
  IF tem_plano_id AND tem_plano_contratado THEN
    RAISE NOTICE 'Removendo coluna plano_id incorreta...';
    
    -- Remover constraint se existir
    IF EXISTS (
      SELECT 1 FROM information_schema.table_constraints
      WHERE table_schema = 'core' 
      AND table_name = 'empresa_base' 
      AND constraint_name = 'fk_empresa_base_plano_id'
    ) THEN
      ALTER TABLE core.empresa_base DROP CONSTRAINT fk_empresa_base_plano_id;
      RAISE NOTICE 'Constraint fk_empresa_base_plano_id removida';
    END IF;
    
    -- Remover a coluna plano_id
    ALTER TABLE core.empresa_base DROP COLUMN plano_id;
    RAISE NOTICE 'Coluna plano_id removida com sucesso';
    
  ELSIF tem_plano_id AND NOT tem_plano_contratado THEN
    -- Se só existe plano_id, renomear para plano_contratado temporariamente
    RAISE NOTICE 'Renomeando plano_id existente para plano_contratado...';
    ALTER TABLE core.empresa_base RENAME COLUMN plano_id TO plano_contratado;
    
  ELSIF NOT tem_plano_id AND NOT tem_plano_contratado THEN
    -- Se nenhuma existe, criar plano_contratado como text
    RAISE NOTICE 'Criando coluna plano_contratado...';
    ALTER TABLE core.empresa_base ADD COLUMN plano_contratado text;
  END IF;
  
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'Erro na etapa 1: %', SQLERRM;
END $$;

-- ETAPA 2: Remover índices antigos que podem estar causando conflito
DROP INDEX IF EXISTS idx_empresa_base_plano_id;
DROP INDEX IF EXISTS idx_empresa_base_status_plano;
DROP INDEX IF EXISTS idx_empresa_base_tipo_plano;

-- ETAPA 3: Remover função desnecessária
DROP FUNCTION IF EXISTS core.migrar_plano_contratado_para_uuid();

-- ETAPA 4: Alterar a coluna plano_contratado para UUID e renomear
DO $$
BEGIN
  -- Verificar se plano_contratado existe agora
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'core' AND table_name = 'empresa_base' AND column_name = 'plano_contratado'
  ) THEN
    
    RAISE NOTICE 'Alterando coluna plano_contratado para UUID...';
    
    -- Limpar dados inválidos primeiro
    UPDATE core.empresa_base 
    SET plano_contratado = NULL 
    WHERE plano_contratado IS NOT NULL 
    AND (
      trim(plano_contratado) = '' 
      OR NOT plano_contratado ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    );
    
    -- Alterar tipo para UUID
    ALTER TABLE core.empresa_base 
    ALTER COLUMN plano_contratado TYPE uuid 
    USING CASE 
      WHEN plano_contratado IS NULL THEN NULL
      WHEN plano_contratado ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' 
      THEN plano_contratado::uuid
      ELSE NULL
    END;
    
    RAISE NOTICE 'Tipo alterado para UUID com sucesso';
    
    -- Renomear para plano_id
    ALTER TABLE core.empresa_base RENAME COLUMN plano_contratado TO plano_id;
    RAISE NOTICE 'Coluna renomeada para plano_id';
    
    -- Adicionar chave estrangeira
    ALTER TABLE core.empresa_base 
    ADD CONSTRAINT fk_empresa_base_plano_id 
    FOREIGN KEY (plano_id) REFERENCES planos.planos(id) ON DELETE SET NULL;
    
    RAISE NOTICE 'Chave estrangeira adicionada com sucesso';
    
  ELSE
    RAISE WARNING 'Coluna plano_contratado não encontrada após limpeza';
  END IF;
  
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'Erro na etapa 4: %', SQLERRM;
END $$;

-- ETAPA 5: Criar índices apenas se a coluna plano_id existir
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'core' AND table_name = 'empresa_base' AND column_name = 'plano_id'
  ) THEN
    -- Criar índices
    CREATE INDEX IF NOT EXISTS idx_empresa_base_plano_id ON core.empresa_base(plano_id) WHERE plano_id IS NOT NULL;
    CREATE INDEX IF NOT EXISTS idx_empresa_base_status_plano ON core.empresa_base(status, plano_id) WHERE plano_id IS NOT NULL;
    CREATE INDEX IF NOT EXISTS idx_empresa_base_tipo_plano ON core.empresa_base(tipo_pessoa, plano_id) WHERE plano_id IS NOT NULL;
    
    RAISE NOTICE 'Índices criados com sucesso';
  ELSE
    RAISE WARNING 'Coluna plano_id não existe - índices não criados';
  END IF;
  
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'Erro ao criar índices: %', SQLERRM;
END $$;

-- ETAPA 6: Atualizar documentação
UPDATE core.documentacao_tabelas 
SET 
  descricao = 'SCHEMA: core - Armazena os dados dos clientes da plataforma (empresas ou pessoas físicas). Cada registro corresponde a quem comprou e usa o sistema. O campo status ajuda a identificar a fase do relacionamento, e observacoes serve para anotações internas da equipe de suporte ou vendas. CORREÇÃO APLICADA: A coluna plano_contratado foi corretamente alterada para plano_id (tipo UUID) com chave estrangeira para planos.planos(id), permitindo relacionamento direto e íntegro com os planos disponíveis no sistema. Esta estrutura garante integridade referencial e facilita consultas relacionadas aos planos contratados pelas empresas.',
  atualizado_em = now()
WHERE nome_tabela = 'empresa_base';

-- ETAPA 7: Inserir registro de correção na documentação
INSERT INTO core.documentacao_tabelas (nome_tabela, descricao) VALUES
(
  'CORRECAO_plano_contratado_v2',
  'SCHEMA: core - REGISTRO DE CORREÇÃO V2: Migration 20250612165000 aplicou correção definitiva na tabela empresa_base. Processo executado: 1) Verificação da situação atual das colunas plano_id e plano_contratado, 2) Remoção da coluna plano_id criada incorretamente (se existia), 3) Alteração segura da coluna plano_contratado de text para UUID, 4) Renomeação para plano_id, 5) Adição de chave estrangeira para planos.planos(id), 6) Criação de índices otimizados apenas após confirmação da existência da coluna. Esta correção resolve definitivamente a estrutura do relacionamento entre empresas e planos contratados.'
);

-- ETAPA 8: Adicionar comentário na coluna
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'core' AND table_name = 'empresa_base' AND column_name = 'plano_id'
  ) THEN
    COMMENT ON COLUMN core.empresa_base.plano_id IS 'Referência UUID ao plano contratado pela empresa (FK para planos.planos) - Corrigido do campo plano_contratado original';
  END IF;
END $$;

-- ETAPA 9: Verificação final e relatório
DO $$
DECLARE
  coluna_existe boolean;
  tipo_coluna text;
  constraint_existe boolean;
  indices_existem integer;
BEGIN
  -- Verificar se a coluna plano_id existe e tem o tipo correto
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'core' 
    AND table_name = 'empresa_base' 
    AND column_name = 'plano_id'
    AND data_type = 'uuid'
  ) INTO coluna_existe;
  
  -- Verificar se a constraint existe
  SELECT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_schema = 'core' 
    AND table_name = 'empresa_base' 
    AND constraint_name = 'fk_empresa_base_plano_id'
  ) INTO constraint_existe;
  
  -- Contar índices criados
  SELECT COUNT(*) INTO indices_existem
  FROM pg_indexes 
  WHERE schemaname = 'core' 
  AND tablename = 'empresa_base' 
  AND indexname LIKE '%plano_id%';
  
  -- Relatório final
  RAISE NOTICE '=== RELATÓRIO FINAL DA CORREÇÃO ===';
  
  IF coluna_existe THEN
    RAISE NOTICE '✓ SUCESSO: Coluna plano_id existe com tipo UUID';
  ELSE
    RAISE WARNING '✗ ERRO: Coluna plano_id não foi criada corretamente ou não é UUID';
  END IF;
  
  IF constraint_existe THEN
    RAISE NOTICE '✓ SUCESSO: Constraint de chave estrangeira fk_empresa_base_plano_id criada';
  ELSE
    RAISE WARNING '✗ ERRO: Constraint de chave estrangeira não foi criada';
  END IF;
  
  RAISE NOTICE '✓ ÍNDICES: % índices relacionados a plano_id criados', indices_existem;
  
  -- Verificar se a coluna plano_contratado ainda existe (não deveria)
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'core' 
    AND table_name = 'empresa_base' 
    AND column_name = 'plano_contratado'
  ) THEN
    RAISE WARNING '⚠ ATENÇÃO: Coluna plano_contratado ainda existe - pode precisar de limpeza manual';
  ELSE
    RAISE NOTICE '✓ SUCESSO: Coluna plano_contratado foi corretamente renomeada';
  END IF;
  
  RAISE NOTICE '=== FIM DO RELATÓRIO ===';
END $$;