/*
  # Criar tabela arquivo_geral no schema core

  1. Nova Tabela
    - `core.arquivo_geral`
      - `id` (uuid, chave primária)
      - `nome_original` (text, obrigatório)
      - `caminho_armazenamento` (text, obrigatório)
      - `tipo_arquivo` (text, obrigatório)
      - `tamanho_bytes` (bigint, obrigatório)
      - `descricao` (text, opcional)
      - `data_upload` (timestamptz, default now())
      - `usuario_upload_id` (uuid, FK para core.usuario_interno)
      - `cliente_id` (uuid, FK para clientes.cliente_final, opcional)
      - `tarefa_id` (uuid, FK para tarefas.tarefa, opcional)
      - `projeto_id` (uuid, FK para projetos.projeto, opcional)
      - `contrato_id` (uuid, opcional para futuro schema contratos)
      - `ativo` (boolean, default true)
      - `tags` (text[], default array vazio)
      - `criado_em` (timestamptz, default now())
      - `atualizado_em` (timestamptz, default now())

  2. Segurança
    - Habilitar RLS na tabela `arquivo_geral`
    - Políticas para usuários autenticados gerenciarem arquivos
    - Chaves estrangeiras com integridade referencial

  3. Performance
    - Índices em colunas frequentemente consultadas
    - Constraints de validação apropriadas

  4. Documentação
    - Inserir descrição detalhada na tabela core.documentacao_tabelas
*/

-- Criar tabela arquivo_geral no schema core
CREATE TABLE IF NOT EXISTS core.arquivo_geral (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nome_original text NOT NULL,
  caminho_armazenamento text NOT NULL,
  tipo_arquivo text NOT NULL,
  tamanho_bytes bigint NOT NULL,
  descricao text,
  data_upload timestamptz DEFAULT now(),
  usuario_upload_id uuid NOT NULL REFERENCES core.usuario_interno(id) ON DELETE CASCADE,
  cliente_id uuid REFERENCES clientes.cliente_final(id) ON DELETE SET NULL,
  tarefa_id uuid REFERENCES tarefas.tarefa(id) ON DELETE SET NULL,
  projeto_id uuid REFERENCES projetos.projeto(id) ON DELETE SET NULL,
  contrato_id uuid, -- Para futuro schema contratos
  ativo boolean DEFAULT true,
  tags text[] DEFAULT '{}',
  criado_em timestamptz DEFAULT now(),
  atualizado_em timestamptz DEFAULT now(),
  
  -- Constraints de validação
  CONSTRAINT check_tamanho_bytes_positivo CHECK (tamanho_bytes > 0),
  CONSTRAINT check_nome_original_nao_vazio CHECK (length(trim(nome_original)) > 0),
  CONSTRAINT check_caminho_armazenamento_nao_vazio CHECK (length(trim(caminho_armazenamento)) > 0),
  CONSTRAINT check_tipo_arquivo_nao_vazio CHECK (length(trim(tipo_arquivo)) > 0)
);

-- Habilitar RLS
ALTER TABLE core.arquivo_geral ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança
CREATE POLICY "Usuários autenticados podem ler arquivos gerais"
  ON core.arquivo_geral
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir arquivos gerais"
  ON core.arquivo_geral
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar arquivos gerais"
  ON core.arquivo_geral
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar arquivos gerais"
  ON core.arquivo_geral
  FOR DELETE
  TO authenticated
  USING (true);

-- Trigger para atualizar automaticamente o timestamp
CREATE TRIGGER update_arquivo_geral_updated_at
  BEFORE UPDATE ON core.arquivo_geral
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_arquivo_geral_usuario_upload_id ON core.arquivo_geral(usuario_upload_id);
CREATE INDEX IF NOT EXISTS idx_arquivo_geral_cliente_id ON core.arquivo_geral(cliente_id) WHERE cliente_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_arquivo_geral_tarefa_id ON core.arquivo_geral(tarefa_id) WHERE tarefa_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_arquivo_geral_projeto_id ON core.arquivo_geral(projeto_id) WHERE projeto_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_arquivo_geral_contrato_id ON core.arquivo_geral(contrato_id) WHERE contrato_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_arquivo_geral_ativo ON core.arquivo_geral(ativo);
CREATE INDEX IF NOT EXISTS idx_arquivo_geral_data_upload ON core.arquivo_geral(data_upload);
CREATE INDEX IF NOT EXISTS idx_arquivo_geral_criado_em ON core.arquivo_geral(criado_em);
CREATE INDEX IF NOT EXISTS idx_arquivo_geral_atualizado_em ON core.arquivo_geral(atualizado_em);
CREATE INDEX IF NOT EXISTS idx_arquivo_geral_tipo_arquivo ON core.arquivo_geral(tipo_arquivo);
CREATE INDEX IF NOT EXISTS idx_arquivo_geral_nome_original ON core.arquivo_geral(nome_original);
CREATE INDEX IF NOT EXISTS idx_arquivo_geral_tamanho_bytes ON core.arquivo_geral(tamanho_bytes);

-- Índices compostos para consultas frequentes
CREATE INDEX IF NOT EXISTS idx_arquivo_geral_usuario_ativo ON core.arquivo_geral(usuario_upload_id, ativo);
CREATE INDEX IF NOT EXISTS idx_arquivo_geral_cliente_ativo ON core.arquivo_geral(cliente_id, ativo) WHERE cliente_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_arquivo_geral_tarefa_ativo ON core.arquivo_geral(tarefa_id, ativo) WHERE tarefa_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_arquivo_geral_projeto_ativo ON core.arquivo_geral(projeto_id, ativo) WHERE projeto_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_arquivo_geral_tipo_ativo ON core.arquivo_geral(tipo_arquivo, ativo);
CREATE INDEX IF NOT EXISTS idx_arquivo_geral_data_ativo ON core.arquivo_geral(data_upload, ativo);

-- Índice para busca em tags usando operador ANY
CREATE INDEX IF NOT EXISTS idx_arquivo_geral_tags ON core.arquivo_geral USING GIN(tags);

-- Inserir documentação da nova tabela
INSERT INTO core.documentacao_tabelas (nome_tabela, descricao) VALUES
(
  'arquivo_geral',
  'SCHEMA: core - Esta tabela centraliza o armazenamento de arquivos no sistema, incluindo documentos, imagens e outros tipos, utilizados por diversos módulos (clientes, tarefas, projetos, contratos e afins). Cada arquivo tem informações completas sobre o upload, metadados e possíveis vínculos com outras entidades, facilitando controle e histórico. Campos principais: id (identificador único UUID), nome_original (nome original do arquivo), caminho_armazenamento (caminho ou URL do arquivo no storage), tipo_arquivo (tipo MIME ou categoria), tamanho_bytes (tamanho em bytes), descricao (descrição opcional), data_upload (timestamp do upload), usuario_upload_id (usuário interno responsável pelo upload), cliente_id/tarefa_id/projeto_id/contrato_id (vínculos opcionais com outras entidades), ativo (status do arquivo), tags (array de texto para categorização), criado_em/atualizado_em (timestamps de controle). Campos de controle permitem gerenciamento do status do arquivo (ativo), organização via tags, e auditoria por meio de timestamps. O vínculo com o usuário que fez o upload garante segurança e rastreabilidade. Ter esta tabela no schema core facilita a gestão integrada e evita dispersão dos arquivos pelo banco, melhorando organização e manutenção.'
);

-- Comentários explicativos sobre a tabela
COMMENT ON TABLE core.arquivo_geral IS 'Tabela centralizada para gerenciamento de todos os arquivos do sistema';
COMMENT ON COLUMN core.arquivo_geral.nome_original IS 'Nome original do arquivo conforme enviado pelo usuário';
COMMENT ON COLUMN core.arquivo_geral.caminho_armazenamento IS 'Caminho ou URL onde o arquivo está armazenado (storage)';
COMMENT ON COLUMN core.arquivo_geral.tipo_arquivo IS 'Tipo MIME ou categoria do arquivo (ex: image/jpeg, application/pdf)';
COMMENT ON COLUMN core.arquivo_geral.tamanho_bytes IS 'Tamanho do arquivo em bytes';
COMMENT ON COLUMN core.arquivo_geral.descricao IS 'Descrição opcional do arquivo para contexto adicional';
COMMENT ON COLUMN core.arquivo_geral.data_upload IS 'Data e hora em que o arquivo foi enviado para o sistema';
COMMENT ON COLUMN core.arquivo_geral.usuario_upload_id IS 'Usuário interno responsável pelo upload do arquivo';
COMMENT ON COLUMN core.arquivo_geral.cliente_id IS 'Vínculo opcional com cliente final';
COMMENT ON COLUMN core.arquivo_geral.tarefa_id IS 'Vínculo opcional com tarefa específica';
COMMENT ON COLUMN core.arquivo_geral.projeto_id IS 'Vínculo opcional com projeto específico';
COMMENT ON COLUMN core.arquivo_geral.contrato_id IS 'Vínculo opcional com contrato (para futuro schema contratos)';
COMMENT ON COLUMN core.arquivo_geral.ativo IS 'Indica se o arquivo está ativo (true) ou arquivado (false)';
COMMENT ON COLUMN core.arquivo_geral.tags IS 'Array de tags para categorização e busca do arquivo';