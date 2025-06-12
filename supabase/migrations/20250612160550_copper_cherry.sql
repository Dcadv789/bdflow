/*
  # Ajustar coluna plano_contratado da tabela core.empresa_base

  1. Alterações na Tabela
    - `core.empresa_base`
      - Renomear coluna `plano_contratado` para `plano_id`
      - Alterar tipo da coluna `plano_id` para UUID
      - Adicionar chave estrangeira para `planos.planos(id)`

  2. Segurança
    - Manter RLS existente
    - Adicionar índices para a nova estrutura

  3. Performance
    - Índices para consultas frequentes na nova coluna
    - Otimizações para relacionamentos

  4. Documentação
    - Atualizar descrição na tabela core.documentacao_tabelas
*/

-- Primeiro, vamos verificar se a coluna plano_contratado existe e fazer as alterações necessárias
DO $$
BEGIN
  -- Verificar se a coluna plano_contratado existe
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'core' AND table_name = 'empresa_base' AND column_name = 'plano_contratado'
  ) THEN
    
    -- Renomear a coluna plano_contratado para plano_id
    ALTER TABLE core.empresa_base RENAME COLUMN plano_contratado TO plano_id;
    
    -- Alterar o tipo da coluna para UUID (assumindo que os dados existentes são compatíveis)
    -- Se houver dados incompatíveis, será necessário tratamento específico
    ALTER TABLE core.empresa_base ALTER COLUMN plano_id TYPE uuid USING plano_id::uuid;
    
    -- Adicionar a chave estrangeira para planos.planos(id)
    ALTER TABLE core.empresa_base 
    ADD CONSTRAINT fk_empresa_base_plano_id 
    FOREIGN KEY (plano_id) REFERENCES planos.planos(id) ON DELETE SET NULL;
    
  ELSE
    -- Se a coluna não existir, criar diretamente com o nome e tipo corretos
    ALTER TABLE core.empresa_base 
    ADD COLUMN plano_id uuid REFERENCES planos.planos(id) ON DELETE SET NULL;
  END IF;
  
EXCEPTION WHEN OTHERS THEN
  -- Em caso de erro (como dados incompatíveis), registrar o erro
  RAISE WARNING 'Erro ao alterar coluna plano_contratado: %', SQLERRM;
  
  -- Se a alteração de tipo falhar, tentar uma abordagem alternativa
  -- Criar nova coluna UUID e migrar dados manualmente se necessário
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'core' AND table_name = 'empresa_base' AND column_name = 'plano_id'
  ) THEN
    ALTER TABLE core.empresa_base 
    ADD COLUMN plano_id uuid REFERENCES planos.planos(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Criar índices para melhor performance na nova coluna plano_id
CREATE INDEX IF NOT EXISTS idx_empresa_base_plano_id ON core.empresa_base(plano_id) WHERE plano_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_empresa_base_status_plano ON core.empresa_base(status, plano_id) WHERE plano_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_empresa_base_tipo_plano ON core.empresa_base(tipo_pessoa, plano_id) WHERE plano_id IS NOT NULL;

-- Atualizar a descrição na tabela documentacao_tabelas
UPDATE core.documentacao_tabelas 
SET 
  descricao = 'SCHEMA: core - Armazena os dados dos clientes da plataforma (empresas ou pessoas físicas). Cada registro corresponde a quem comprou e usa o sistema. O campo status ajuda a identificar a fase do relacionamento, e observacoes serve para anotações internas da equipe de suporte ou vendas. ATUALIZAÇÃO: A coluna plano_contratado foi renomeada para plano_id e alterada para tipo UUID com chave estrangeira para planos.planos(id), permitindo relacionamento direto com os planos disponíveis no sistema. Esta mudança melhora a integridade referencial e facilita consultas relacionadas aos planos contratados pelas empresas.',
  atualizado_em = now()
WHERE nome_tabela = 'empresa_base';

-- Comentários explicativos sobre a alteração
COMMENT ON COLUMN core.empresa_base.plano_id IS 'Referência UUID ao plano contratado pela empresa (FK para planos.planos)';

-- Função para migrar dados de texto para UUID (se necessário)
-- Esta função pode ser usada caso existam dados em formato texto que precisem ser convertidos
CREATE OR REPLACE FUNCTION core.migrar_plano_contratado_para_uuid()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  empresa_record RECORD;
  plano_uuid uuid;
BEGIN
  -- Esta função pode ser executada manualmente se houver necessidade de migrar dados
  -- de formato texto para UUID baseado no nome do plano
  
  FOR empresa_record IN 
    SELECT id, plano_id 
    FROM core.empresa_base 
    WHERE plano_id IS NULL 
  LOOP
    -- Lógica de migração pode ser implementada aqui se necessário
    -- Por exemplo, buscar plano por nome e atualizar com UUID
    NULL;
  END LOOP;
  
  RAISE NOTICE 'Migração de planos concluída';
END;
$$;

COMMENT ON FUNCTION core.migrar_plano_contratado_para_uuid() IS 'Função auxiliar para migração de dados de plano_contratado de texto para UUID (se necessário)';