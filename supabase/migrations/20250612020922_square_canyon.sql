/*
  # Criar tabela cliente_comentario no schema clientes

  1. Nova Tabela
    - `clientes.cliente_comentario`
      - `id` (uuid, chave primária)
      - `cliente_final_id` (uuid, FK para clientes.cliente_final)
      - `usuario_interno_id` (uuid, FK para core.usuario_interno)
      - `texto` (text, obrigatório)
      - `criado_em` (timestamptz, default now())
      - `atualizado_em` (timestamptz, default now())

  2. Segurança
    - Habilitar RLS na tabela `cliente_comentario`
    - Políticas para usuários autenticados gerenciarem comentários
    - Chaves estrangeiras com integridade referencial

  3. Performance
    - Índices em colunas frequentemente consultadas
    - Constraints de validação apropriadas

  4. Documentação
    - Inserir descrição detalhada na tabela core.documentacao_tabelas
*/

-- Criar tabela cliente_comentario no schema clientes
CREATE TABLE IF NOT EXISTS clientes.cliente_comentario (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cliente_final_id uuid NOT NULL REFERENCES clientes.cliente_final(id) ON DELETE CASCADE,
  usuario_interno_id uuid NOT NULL REFERENCES core.usuario_interno(id) ON DELETE CASCADE,
  texto text NOT NULL,
  criado_em timestamptz DEFAULT now(),
  atualizado_em timestamptz DEFAULT now()
);

-- Habilitar RLS
ALTER TABLE clientes.cliente_comentario ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança
CREATE POLICY "Usuários autenticados podem ler comentários de clientes"
  ON clientes.cliente_comentario
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir comentários de clientes"
  ON clientes.cliente_comentario
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar comentários de clientes"
  ON clientes.cliente_comentario
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar comentários de clientes"
  ON clientes.cliente_comentario
  FOR DELETE
  TO authenticated
  USING (true);

-- Trigger para atualizar automaticamente o timestamp
CREATE TRIGGER update_cliente_comentario_updated_at
  BEFORE UPDATE ON clientes.cliente_comentario
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_cliente_comentario_cliente_final_id ON clientes.cliente_comentario(cliente_final_id);
CREATE INDEX IF NOT EXISTS idx_cliente_comentario_usuario_interno_id ON clientes.cliente_comentario(usuario_interno_id);
CREATE INDEX IF NOT EXISTS idx_cliente_comentario_criado_em ON clientes.cliente_comentario(criado_em);
CREATE INDEX IF NOT EXISTS idx_cliente_comentario_atualizado_em ON clientes.cliente_comentario(atualizado_em);
CREATE INDEX IF NOT EXISTS idx_cliente_comentario_cliente_criado ON clientes.cliente_comentario(cliente_final_id, criado_em);
CREATE INDEX IF NOT EXISTS idx_cliente_comentario_usuario_criado ON clientes.cliente_comentario(usuario_interno_id, criado_em);

-- Inserir documentação da nova tabela
INSERT INTO core.documentacao_tabelas (nome_tabela, descricao) VALUES
(
  'cliente_comentario',
  'SCHEMA: clientes - Tabela destinada ao registro de comentários internos sobre clientes finais. Os comentários são vinculados ao cliente, identificam o autor (usuário interno) e possuem controle de data de criação e atualização. Serve para registrar observações importantes, interações relevantes, feedbacks e qualquer tipo de anotação que ajude no acompanhamento do cliente. Campos principais: id (identificador único UUID), cliente_final_id (referência ao cliente final), usuario_interno_id (referência ao autor do comentário), texto (conteúdo do comentário), criado_em (data e hora da criação), atualizado_em (data e hora da última atualização). Esta tabela é fundamental para manter um histórico de observações internas sobre cada cliente, facilitando o acompanhamento e a continuidade do atendimento.'
);

-- Comentário explicativo sobre a tabela
COMMENT ON TABLE clientes.cliente_comentario IS 'Registra comentários internos sobre clientes finais para acompanhamento e observações da equipe';