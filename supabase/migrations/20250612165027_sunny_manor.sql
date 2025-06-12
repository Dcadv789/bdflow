/*
  # Corrigir coluna plano_contratado na tabela core.empresa_base

  1. Alterações na Tabela
    - `core.empresa_base`
      - Renomear coluna `plano_contratado` para `plano_id`
      - Alterar tipo da coluna de text para UUID
      - Adicionar chave estrangeira para `planos.planos(id)`

  2. Segurança
    - Manter RLS existente
    - Conversão segura de dados existentes
    - Tratamento de valores inválidos

  3. Performance
    - Índices para consultas frequentes na nova estrutura
    - Otimizações para relacionamentos

  4. Documentação
    - Atualizar descrição na tabela core.documentacao_tabelas
*/

-- ETAPA 1: Preparar dados para conversão segura
-- Limpar valores que não podem ser convertidos para UUID
UPDATE core.empresa_base 
SET plano_contratado = NULL 
WHERE plano_contratado IS NOT NULL 
AND (
  trim(plano_contratado) = '' 
  OR length(trim(plano_contratado)) = 0
  OR NOT plano_contratado ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
);

-- ETAPA 2: Alterar o tipo da coluna plano_contratado para UUID
ALTER TABLE core.empresa_base 
ALTER COLUMN plano_contratado TYPE uuid 
USING CASE 
  WHEN plano_contratado IS NULL THEN NULL
  WHEN plano_contratado ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' 
  THEN plano_contratado::uuid
  ELSE NULL
END;

-- ETAPA 3: Renomear a coluna para plano_id
ALTER TABLE core.empresa_base RENAME COLUMN plano_contratado TO plano_id;

-- ETAPA 4: Adicionar chave estrangeira para planos.planos(id)
ALTER TABLE core.empresa_base 
ADD CONSTRAINT fk_empresa_base_plano_id 
FOREIGN KEY (plano_id) REFERENCES planos.planos(id) ON DELETE SET NULL;

-- ETAPA 5: Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_empresa_base_plano_id ON core.empresa_base(plano_id) WHERE plano_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_empresa_base_status_plano ON core.empresa_base(status, plano_id) WHERE plano_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_empresa_base_tipo_plano ON core.empresa_base(tipo_pessoa, plano_id) WHERE plano_id IS NOT NULL;

-- ETAPA 6: Atualizar documentação
UPDATE core.documentacao_tabelas 
SET 
  descricao = 'SCHEMA: core - Armazena os dados dos clientes da plataforma (empresas ou pessoas físicas). Cada registro corresponde a quem comprou e usa o sistema. O campo status ajuda a identificar a fase do relacionamento, e observacoes serve para anotações internas da equipe de suporte ou vendas. ATUALIZAÇÃO: A coluna plano_contratado foi renomeada para plano_id e alterada para tipo UUID com chave estrangeira para planos.planos(id), permitindo relacionamento direto com os planos disponíveis no sistema. Esta mudança melhora a integridade referencial e facilita consultas relacionadas aos planos contratados pelas empresas.',
  atualizado_em = now()
WHERE nome_tabela = 'empresa_base';

-- ETAPA 7: Inserir registro da alteração na documentação
INSERT INTO core.documentacao_tabelas (nome_tabela, descricao) VALUES
(
  'ALTERACAO_plano_contratado_para_plano_id',
  'SCHEMA: core - REGISTRO DE ALTERAÇÃO: Migration aplicou alteração na tabela empresa_base renomeando a coluna plano_contratado para plano_id e alterando o tipo de text para UUID. Processo executado: 1) Limpeza de dados inválidos que não podem ser convertidos para UUID, 2) Alteração segura do tipo da coluna de text para UUID, 3) Renomeação da coluna para plano_id, 4) Adição de chave estrangeira para planos.planos(id) com ON DELETE SET NULL, 5) Criação de índices otimizados para consultas frequentes. Esta alteração estabelece relacionamento íntegro entre empresas e planos contratados, melhorando a estrutura do banco de dados.'
);

-- ETAPA 8: Adicionar comentário explicativo na coluna
COMMENT ON COLUMN core.empresa_base.plano_id IS 'Referência UUID ao plano contratado pela empresa (FK para planos.planos) - Renomeado e convertido da coluna plano_contratado';

-- ETAPA 9: Verificação final da estrutura
DO $$
DECLARE
  coluna_existe boolean;
  tipo_correto boolean;
  constraint_existe boolean;
  indices_criados integer;
BEGIN
  -- Verificar se a coluna plano_id existe
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'core' 
    AND table_name = 'empresa_base' 
    AND column_name = 'plano_id'
  ) INTO coluna_existe;
  
  -- Verificar se o tipo é UUID
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'core' 
    AND table_name = 'empresa_base' 
    AND column_name = 'plano_id'
    AND data_type = 'uuid'
  ) INTO tipo_correto;
  
  -- Verificar se a constraint de FK existe
  SELECT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_schema = 'core' 
    AND table_name = 'empresa_base' 
    AND constraint_name = 'fk_empresa_base_plano_id'
  ) INTO constraint_existe;
  
  -- Contar índices criados
  SELECT COUNT(*) INTO indices_criados
  FROM pg_indexes 
  WHERE schemaname = 'core' 
  AND tablename = 'empresa_base' 
  AND indexname LIKE '%plano_id%';
  
  -- Verificar se a coluna plano_contratado ainda existe (não deveria)
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'core' 
    AND table_name = 'empresa_base' 
    AND column_name = 'plano_contratado'
  ) THEN
    RAISE WARNING 'ERRO: Coluna plano_contratado ainda existe - renomeação falhou';
  END IF;
  
  -- Relatório de verificação
  IF coluna_existe AND tipo_correto AND constraint_existe THEN
    RAISE NOTICE 'SUCESSO: Alteração da coluna plano_contratado para plano_id (UUID) com FK concluída. Índices criados: %', indices_criados;
  ELSE
    RAISE WARNING 'ERRO: Alteração incompleta - Coluna existe: %, Tipo UUID: %, FK existe: %', coluna_existe, tipo_correto, constraint_existe;
  END IF;
END $$;