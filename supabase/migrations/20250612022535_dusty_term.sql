/*
  # Criar tabela notificacao_geral no schema core

  1. Nova Tabela
    - `core.notificacao_geral`
      - `id` (uuid, chave primária)
      - `usuario_destinatario_id` (uuid, obrigatório)
      - `tipo_usuario` (enum: interno, cliente)
      - `titulo` (text, obrigatório)
      - `mensagem` (text, obrigatório)
      - `link_referencia` (text, opcional)
      - `lida` (boolean, default false)
      - `criada_em` (timestamptz, default now())
      - `atualizada_em` (timestamptz, default now())

  2. Segurança
    - Habilitar RLS na tabela `notificacao_geral`
    - Políticas para usuários autenticados gerenciarem notificações
    - Constraints de validação apropriadas

  3. Performance
    - Índices em colunas frequentemente consultadas
    - Otimizações para consultas por usuário e status de leitura

  4. Documentação
    - Inserir descrição completa na tabela core.documentacao_tabelas
*/

-- Criar enum para tipo de usuário
CREATE TYPE core.tipo_usuario_notificacao AS ENUM ('interno', 'cliente');

-- Criar tabela notificacao_geral no schema core
CREATE TABLE IF NOT EXISTS core.notificacao_geral (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_destinatario_id uuid NOT NULL,
  tipo_usuario core.tipo_usuario_notificacao NOT NULL,
  titulo text NOT NULL,
  mensagem text NOT NULL,
  link_referencia text,
  lida boolean DEFAULT false,
  criada_em timestamptz DEFAULT now(),
  atualizada_em timestamptz DEFAULT now()
);

-- Habilitar RLS
ALTER TABLE core.notificacao_geral ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança
CREATE POLICY "Usuários autenticados podem ler notificações gerais"
  ON core.notificacao_geral
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir notificações gerais"
  ON core.notificacao_geral
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar notificações gerais"
  ON core.notificacao_geral
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar notificações gerais"
  ON core.notificacao_geral
  FOR DELETE
  TO authenticated
  USING (true);

-- Trigger para atualizar automaticamente o timestamp
CREATE TRIGGER update_notificacao_geral_updated_at
  BEFORE UPDATE ON core.notificacao_geral
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_notificacao_geral_usuario_destinatario_id ON core.notificacao_geral(usuario_destinatario_id);
CREATE INDEX IF NOT EXISTS idx_notificacao_geral_tipo_usuario ON core.notificacao_geral(tipo_usuario);
CREATE INDEX IF NOT EXISTS idx_notificacao_geral_lida ON core.notificacao_geral(lida);
CREATE INDEX IF NOT EXISTS idx_notificacao_geral_criada_em ON core.notificacao_geral(criada_em);
CREATE INDEX IF NOT EXISTS idx_notificacao_geral_atualizada_em ON core.notificacao_geral(atualizada_em);
CREATE INDEX IF NOT EXISTS idx_notificacao_geral_usuario_tipo ON core.notificacao_geral(usuario_destinatario_id, tipo_usuario);
CREATE INDEX IF NOT EXISTS idx_notificacao_geral_usuario_lida ON core.notificacao_geral(usuario_destinatario_id, lida);
CREATE INDEX IF NOT EXISTS idx_notificacao_geral_tipo_lida ON core.notificacao_geral(tipo_usuario, lida);
CREATE INDEX IF NOT EXISTS idx_notificacao_geral_usuario_tipo_lida ON core.notificacao_geral(usuario_destinatario_id, tipo_usuario, lida);
CREATE INDEX IF NOT EXISTS idx_notificacao_geral_criada_lida ON core.notificacao_geral(criada_em, lida);

-- Inserir documentação da nova tabela
INSERT INTO core.documentacao_tabelas (nome_tabela, descricao) VALUES
(
  'notificacao_geral',
  'SCHEMA: core - Tabela central para gerenciamento de notificações do sistema, servindo tanto usuários internos quanto clientes finais. A coluna usuario_destinatario_id identifica o usuário que receberá a notificação, podendo ser tanto um usuário interno da empresa quanto um cliente final que utiliza o software. A coluna tipo_usuario diferencia os usuários internos (interno) dos clientes finais (cliente), garantindo que as notificações sejam direcionadas corretamente conforme o tipo de usuário. Campos principais: id (identificador único UUID), usuario_destinatario_id (UUID do usuário destinatário), tipo_usuario (tipo do usuário: interno ou cliente), titulo (título resumido da notificação), mensagem (mensagem completa da notificação), link_referencia (link opcional para onde a notificação aponta, ex: tarefa, projeto, contrato), lida (booleano indicando se foi lida, padrão falso), criada_em (data e hora da criação), atualizada_em (data e hora da última atualização). Esta tabela centraliza todo o sistema de notificações, permitindo comunicação eficiente com diferentes tipos de usuários da plataforma.'
);

-- Comentário explicativo sobre a tabela
COMMENT ON TABLE core.notificacao_geral IS 'Sistema central de notificações para usuários internos e clientes finais da plataforma';
COMMENT ON COLUMN core.notificacao_geral.usuario_destinatario_id IS 'ID do usuário destinatário (pode ser interno ou cliente final)';
COMMENT ON COLUMN core.notificacao_geral.tipo_usuario IS 'Tipo do usuário destinatário: interno ou cliente';
COMMENT ON COLUMN core.notificacao_geral.link_referencia IS 'Link opcional para onde a notificação aponta (tarefa, projeto, contrato, etc.)';