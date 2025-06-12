/*
  # Criar schema documentos e tabelas de contratos/arquivos

  1. Novo Schema
    - `documentos` - Schema para organizar contratos e documentação de clientes finais

  2. Novas Tabelas
    - `documento_cliente` - Documentos vinculados aos clientes finais
    - `arquivo_documento_cliente` - Arquivos reais dos documentos
    - `log_acesso_documento_cliente` - Log de acessos aos documentos
    - `historico_documento_cliente` - Histórico de alterações nos documentos

  3. Segurança
    - Habilitar RLS em todas as tabelas
    - Políticas para usuários autenticados gerenciarem documentos
    - Chaves estrangeiras com integridade referencial

  4. Performance
    - Índices em colunas frequentemente consultadas
    - Constraints para garantir consistência de dados

  5. Documentação
    - Inserir descrições detalhadas na tabela core.documentacao_tabelas
*/

-- Criar o schema documentos
CREATE SCHEMA IF NOT EXISTS documentos;

-- Criar enums para status e tipos de documento
CREATE TYPE documentos.status_documento AS ENUM ('pendente', 'assinado', 'vencido', 'cancelado');
CREATE TYPE documentos.tipo_acao_documento AS ENUM ('visualizou', 'baixou', 'editou');

-- Criar tabela documento_cliente
CREATE TABLE IF NOT EXISTS documentos.documento_cliente (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cliente_final_id uuid NOT NULL REFERENCES clientes.cliente_final(id) ON DELETE CASCADE,
  titulo text NOT NULL,
  descricao text,
  tipo_documento text NOT NULL,
  versao text DEFAULT 'v1.0',
  status documentos.status_documento DEFAULT 'pendente',
  data_assinatura date,
  data_validade date,
  foi_renovado boolean DEFAULT false,
  criado_por_id uuid NOT NULL REFERENCES core.usuario_interno(id) ON DELETE CASCADE,
  criado_em timestamptz DEFAULT now(),
  atualizado_em timestamptz DEFAULT now(),
  
  -- Constraint para garantir que data_validade seja posterior à data_assinatura
  CONSTRAINT check_data_validade_posterior CHECK (
    data_validade IS NULL OR data_assinatura IS NULL OR data_validade >= data_assinatura
  )
);

-- Criar tabela arquivo_documento_cliente
CREATE TABLE IF NOT EXISTS documentos.arquivo_documento_cliente (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  documento_id uuid NOT NULL REFERENCES documentos.documento_cliente(id) ON DELETE CASCADE,
  nome_arquivo text NOT NULL,
  url text NOT NULL,
  tipo_arquivo text NOT NULL,
  criado_em timestamptz DEFAULT now()
);

-- Criar tabela log_acesso_documento_cliente
CREATE TABLE IF NOT EXISTS documentos.log_acesso_documento_cliente (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  documento_id uuid NOT NULL REFERENCES documentos.documento_cliente(id) ON DELETE CASCADE,
  usuario_id uuid NOT NULL REFERENCES core.usuario_interno(id) ON DELETE CASCADE,
  acao documentos.tipo_acao_documento NOT NULL,
  data timestamptz DEFAULT now()
);

-- Criar tabela historico_documento_cliente
CREATE TABLE IF NOT EXISTS documentos.historico_documento_cliente (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  documento_id uuid NOT NULL REFERENCES documentos.documento_cliente(id) ON DELETE CASCADE,
  campo_alterado text NOT NULL,
  valor_anterior text,
  valor_novo text,
  alterado_por_id uuid NOT NULL REFERENCES core.usuario_interno(id) ON DELETE CASCADE,
  alterado_em timestamptz DEFAULT now()
);

-- Habilitar RLS em todas as tabelas
ALTER TABLE documentos.documento_cliente ENABLE ROW LEVEL SECURITY;
ALTER TABLE documentos.arquivo_documento_cliente ENABLE ROW LEVEL SECURITY;
ALTER TABLE documentos.log_acesso_documento_cliente ENABLE ROW LEVEL SECURITY;
ALTER TABLE documentos.historico_documento_cliente ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança para documento_cliente
CREATE POLICY "Usuários autenticados podem ler documentos de clientes"
  ON documentos.documento_cliente
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir documentos de clientes"
  ON documentos.documento_cliente
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar documentos de clientes"
  ON documentos.documento_cliente
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar documentos de clientes"
  ON documentos.documento_cliente
  FOR DELETE
  TO authenticated
  USING (true);

-- Políticas de segurança para arquivo_documento_cliente
CREATE POLICY "Usuários autenticados podem ler arquivos de documentos"
  ON documentos.arquivo_documento_cliente
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir arquivos de documentos"
  ON documentos.arquivo_documento_cliente
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar arquivos de documentos"
  ON documentos.arquivo_documento_cliente
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar arquivos de documentos"
  ON documentos.arquivo_documento_cliente
  FOR DELETE
  TO authenticated
  USING (true);

-- Políticas de segurança para log_acesso_documento_cliente
CREATE POLICY "Usuários autenticados podem ler logs de acesso a documentos"
  ON documentos.log_acesso_documento_cliente
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir logs de acesso a documentos"
  ON documentos.log_acesso_documento_cliente
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar logs de acesso a documentos"
  ON documentos.log_acesso_documento_cliente
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar logs de acesso a documentos"
  ON documentos.log_acesso_documento_cliente
  FOR DELETE
  TO authenticated
  USING (true);

-- Políticas de segurança para historico_documento_cliente
CREATE POLICY "Usuários autenticados podem ler histórico de documentos"
  ON documentos.historico_documento_cliente
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir histórico de documentos"
  ON documentos.historico_documento_cliente
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar histórico de documentos"
  ON documentos.historico_documento_cliente
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar histórico de documentos"
  ON documentos.historico_documento_cliente
  FOR DELETE
  TO authenticated
  USING (true);

-- Trigger para atualizar automaticamente o timestamp na tabela documento_cliente
CREATE TRIGGER update_documento_cliente_updated_at
  BEFORE UPDATE ON documentos.documento_cliente
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Criar índices para melhor performance

-- Índices para documento_cliente
CREATE INDEX IF NOT EXISTS idx_documento_cliente_cliente_final_id ON documentos.documento_cliente(cliente_final_id);
CREATE INDEX IF NOT EXISTS idx_documento_cliente_criado_por_id ON documentos.documento_cliente(criado_por_id);
CREATE INDEX IF NOT EXISTS idx_documento_cliente_tipo_documento ON documentos.documento_cliente(tipo_documento);
CREATE INDEX IF NOT EXISTS idx_documento_cliente_status ON documentos.documento_cliente(status);
CREATE INDEX IF NOT EXISTS idx_documento_cliente_data_assinatura ON documentos.documento_cliente(data_assinatura) WHERE data_assinatura IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_documento_cliente_data_validade ON documentos.documento_cliente(data_validade) WHERE data_validade IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_documento_cliente_foi_renovado ON documentos.documento_cliente(foi_renovado);
CREATE INDEX IF NOT EXISTS idx_documento_cliente_versao ON documentos.documento_cliente(versao);
CREATE INDEX IF NOT EXISTS idx_documento_cliente_cliente_tipo ON documentos.documento_cliente(cliente_final_id, tipo_documento);
CREATE INDEX IF NOT EXISTS idx_documento_cliente_cliente_status ON documentos.documento_cliente(cliente_final_id, status);
CREATE INDEX IF NOT EXISTS idx_documento_cliente_status_validade ON documentos.documento_cliente(status, data_validade);

-- Índices para arquivo_documento_cliente
CREATE INDEX IF NOT EXISTS idx_arquivo_documento_cliente_documento_id ON documentos.arquivo_documento_cliente(documento_id);
CREATE INDEX IF NOT EXISTS idx_arquivo_documento_cliente_tipo_arquivo ON documentos.arquivo_documento_cliente(tipo_arquivo);
CREATE INDEX IF NOT EXISTS idx_arquivo_documento_cliente_nome_arquivo ON documentos.arquivo_documento_cliente(nome_arquivo);
CREATE INDEX IF NOT EXISTS idx_arquivo_documento_cliente_criado_em ON documentos.arquivo_documento_cliente(criado_em);

-- Índices para log_acesso_documento_cliente
CREATE INDEX IF NOT EXISTS idx_log_acesso_documento_cliente_documento_id ON documentos.log_acesso_documento_cliente(documento_id);
CREATE INDEX IF NOT EXISTS idx_log_acesso_documento_cliente_usuario_id ON documentos.log_acesso_documento_cliente(usuario_id);
CREATE INDEX IF NOT EXISTS idx_log_acesso_documento_cliente_acao ON documentos.log_acesso_documento_cliente(acao);
CREATE INDEX IF NOT EXISTS idx_log_acesso_documento_cliente_data ON documentos.log_acesso_documento_cliente(data);
CREATE INDEX IF NOT EXISTS idx_log_acesso_documento_cliente_documento_data ON documentos.log_acesso_documento_cliente(documento_id, data);
CREATE INDEX IF NOT EXISTS idx_log_acesso_documento_cliente_usuario_data ON documentos.log_acesso_documento_cliente(usuario_id, data);
CREATE INDEX IF NOT EXISTS idx_log_acesso_documento_cliente_acao_data ON documentos.log_acesso_documento_cliente(acao, data);

-- Índices para historico_documento_cliente
CREATE INDEX IF NOT EXISTS idx_historico_documento_cliente_documento_id ON documentos.historico_documento_cliente(documento_id);
CREATE INDEX IF NOT EXISTS idx_historico_documento_cliente_alterado_por_id ON documentos.historico_documento_cliente(alterado_por_id);
CREATE INDEX IF NOT EXISTS idx_historico_documento_cliente_campo_alterado ON documentos.historico_documento_cliente(campo_alterado);
CREATE INDEX IF NOT EXISTS idx_historico_documento_cliente_alterado_em ON documentos.historico_documento_cliente(alterado_em);
CREATE INDEX IF NOT EXISTS idx_historico_documento_cliente_documento_campo ON documentos.historico_documento_cliente(documento_id, campo_alterado);
CREATE INDEX IF NOT EXISTS idx_historico_documento_cliente_documento_data ON documentos.historico_documento_cliente(documento_id, alterado_em);

-- Inserir documentação das novas tabelas na tabela core.documentacao_tabelas
INSERT INTO core.documentacao_tabelas (nome_tabela, descricao) VALUES
(
  'SCHEMA_documentos',
  'SCHEMA: documentos - Schema dedicado ao gerenciamento completo de contratos e documentação de clientes finais. Organiza todas as tabelas relacionadas a documentos, arquivos, controle de acesso e auditoria. Contém as tabelas: documento_cliente (dados principais dos documentos), arquivo_documento_cliente (arquivos físicos), log_acesso_documento_cliente (auditoria de acessos) e historico_documento_cliente (histórico de alterações). Permite controle total sobre documentação contratual e legal.'
),
(
  'documento_cliente',
  'SCHEMA: documentos - Tabela principal que armazena todos os documentos vinculados a clientes finais, como contratos, propostas, termos de aceite, comprovantes e arquivos gerais. Permite controle de múltiplos tipos de documentos, versões, status, datas importantes (assinatura e validade) e registro do criador. Campos principais: id (identificador único), cliente_final_id (cliente proprietário), titulo (nome do documento), descricao (propósito ou conteúdo), tipo_documento (categoria como contrato, proposta, termo), versao (controle de versões), status (situação atual: pendente, assinado, vencido, cancelado), data_assinatura (quando foi assinado), data_validade (data de expiração), foi_renovado (indicador de renovação), criado_por_id (usuário interno criador), criado_em/atualizado_em (timestamps de controle).'
),
(
  'arquivo_documento_cliente',
  'SCHEMA: documentos - Tabela que armazena os arquivos reais (PDFs, imagens, etc.) relacionados a cada documento. Um mesmo documento pode ter múltiplos arquivos, como versões assinadas, documentos complementares ou anexos. Gerencia o storage e organização física dos arquivos. Campos principais: id (identificador único), documento_id (documento relacionado), nome_arquivo (nome original do arquivo), url (link para acesso no storage), tipo_arquivo (extensão como pdf, jpg, png, docx), criado_em (timestamp de upload). Essencial para manter a integridade e organização dos arquivos físicos dos documentos.'
),
(
  'log_acesso_documento_cliente',
  'SCHEMA: documentos - Tabela de auditoria que registra todos os acessos aos documentos, incluindo quem acessou, quando e que ação foi realizada. Fundamental para controle interno, compliance e rastreabilidade de acesso a documentos sensíveis. Campos principais: id (identificador único), documento_id (documento acessado), usuario_id (usuário interno que realizou a ação), acao (tipo de ação: visualizou, baixou, editou), data (timestamp do acesso). Permite monitoramento completo de quem está acessando quais documentos e quando, essencial para segurança e auditoria.'
),
(
  'historico_documento_cliente',
  'SCHEMA: documentos - Tabela que mantém histórico completo de todas as alterações feitas nos dados dos documentos. Rastreia mudanças sensíveis como status, validade, tipo, título e outros campos críticos. Essencial para auditoria e compliance. Campos principais: id (identificador único), documento_id (documento alterado), campo_alterado (nome do campo modificado), valor_anterior (valor antes da alteração), valor_novo (valor após a alteração), alterado_por_id (usuário interno responsável), alterado_em (timestamp da alteração). Garante rastreabilidade total de modificações em documentos contratuais e legais.'
);

-- Comentário explicativo sobre o novo schema
COMMENT ON SCHEMA documentos IS 'Schema completo para gestão de contratos, documentos e arquivos de clientes finais com controle de acesso e auditoria';