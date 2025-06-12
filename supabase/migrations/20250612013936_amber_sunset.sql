/*
  # Criar módulo de agendamentos

  1. Novo Schema
    - agendamentos: schema dedicado ao sistema de agendamentos

  2. Novas Tabelas
    - `agendamentos.agendamento`
      - `id` (uuid, chave primária)
      - `cliente_final_id` (uuid, obrigatório, FK para clientes.cliente_final)
      - `titulo` (text, obrigatório)
      - `descricao` (text, opcional)
      - `data_inicio` (timestamptz, obrigatório)
      - `data_fim` (timestamptz, obrigatório)
      - `local` (text, opcional)
      - `status` (text, opcional - agendado, realizado, cancelado)
      - `criado_por_id` (uuid, obrigatório, FK para core.usuario_interno)
      - `criado_em` (timestamptz, default now())
      - `atualizado_em` (timestamptz, default now())

    - `agendamentos.agendamento_participante`
      - `id` (uuid, chave primária)
      - `agendamento_id` (uuid, obrigatório, FK para agendamentos.agendamento)
      - `usuario_interno_id` (uuid, opcional, FK para core.usuario_interno)
      - `colaborador_id` (uuid, opcional, FK para core.empresa_usuario)
      - `tipo` (text, opcional - interno, colaborador)
      - `criado_em` (timestamptz, default now())

    - `agendamentos.agendamento_comentario`
      - `id` (uuid, chave primária)
      - `agendamento_id` (uuid, obrigatório, FK para agendamentos.agendamento)
      - `usuario_interno_id` (uuid, obrigatório, FK para core.usuario_interno)
      - `comentario` (text, obrigatório)
      - `criado_em` (timestamptz, default now())

  3. Segurança
    - Habilitar RLS em todas as tabelas
    - Políticas para usuários autenticados gerenciarem agendamentos
    - Chaves estrangeiras com integridade referencial

  4. Performance
    - Índices em colunas frequentemente consultadas
    - Constraints de validação apropriadas

  5. Documentação
    - Inserir descrições detalhadas na tabela core.documentacao_tabelas
*/

-- Criar o schema agendamentos
CREATE SCHEMA IF NOT EXISTS agendamentos;

-- Criar enum para status do agendamento
CREATE TYPE agendamentos.status_agendamento AS ENUM ('agendado', 'realizado', 'cancelado');

-- Criar enum para tipo de participante
CREATE TYPE agendamentos.tipo_participante AS ENUM ('interno', 'colaborador');

-- Criar tabela agendamento
CREATE TABLE IF NOT EXISTS agendamentos.agendamento (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cliente_final_id uuid NOT NULL REFERENCES clientes.cliente_final(id) ON DELETE CASCADE,
  titulo text NOT NULL,
  descricao text,
  data_inicio timestamptz NOT NULL,
  data_fim timestamptz NOT NULL,
  local text,
  status agendamentos.status_agendamento DEFAULT 'agendado',
  criado_por_id uuid NOT NULL REFERENCES core.usuario_interno(id) ON DELETE CASCADE,
  criado_em timestamptz DEFAULT now(),
  atualizado_em timestamptz DEFAULT now(),
  
  -- Constraint para garantir que data_fim seja posterior a data_inicio
  CONSTRAINT check_data_fim_posterior CHECK (data_fim > data_inicio)
);

-- Criar tabela agendamento_participante
CREATE TABLE IF NOT EXISTS agendamentos.agendamento_participante (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  agendamento_id uuid NOT NULL REFERENCES agendamentos.agendamento(id) ON DELETE CASCADE,
  usuario_interno_id uuid REFERENCES core.usuario_interno(id) ON DELETE CASCADE,
  colaborador_id uuid REFERENCES core.empresa_usuario(id) ON DELETE CASCADE,
  tipo agendamentos.tipo_participante,
  criado_em timestamptz DEFAULT now(),
  
  -- Constraint para garantir que pelo menos um dos IDs seja preenchido
  CONSTRAINT check_participante_valido CHECK (
    (usuario_interno_id IS NOT NULL AND colaborador_id IS NULL) OR
    (usuario_interno_id IS NULL AND colaborador_id IS NOT NULL)
  ),
  
  -- Constraint para evitar duplicação de participantes
  UNIQUE(agendamento_id, usuario_interno_id, colaborador_id)
);

-- Criar tabela agendamento_comentario
CREATE TABLE IF NOT EXISTS agendamentos.agendamento_comentario (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  agendamento_id uuid NOT NULL REFERENCES agendamentos.agendamento(id) ON DELETE CASCADE,
  usuario_interno_id uuid NOT NULL REFERENCES core.usuario_interno(id) ON DELETE CASCADE,
  comentario text NOT NULL,
  criado_em timestamptz DEFAULT now()
);

-- Habilitar RLS em todas as tabelas
ALTER TABLE agendamentos.agendamento ENABLE ROW LEVEL SECURITY;
ALTER TABLE agendamentos.agendamento_participante ENABLE ROW LEVEL SECURITY;
ALTER TABLE agendamentos.agendamento_comentario ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança para agendamento
CREATE POLICY "Usuários autenticados podem ler agendamentos"
  ON agendamentos.agendamento
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir agendamentos"
  ON agendamentos.agendamento
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar agendamentos"
  ON agendamentos.agendamento
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar agendamentos"
  ON agendamentos.agendamento
  FOR DELETE
  TO authenticated
  USING (true);

-- Políticas de segurança para agendamento_participante
CREATE POLICY "Usuários autenticados podem ler participantes de agendamentos"
  ON agendamentos.agendamento_participante
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir participantes de agendamentos"
  ON agendamentos.agendamento_participante
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar participantes de agendamentos"
  ON agendamentos.agendamento_participante
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar participantes de agendamentos"
  ON agendamentos.agendamento_participante
  FOR DELETE
  TO authenticated
  USING (true);

-- Políticas de segurança para agendamento_comentario
CREATE POLICY "Usuários autenticados podem ler comentários de agendamentos"
  ON agendamentos.agendamento_comentario
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir comentários de agendamentos"
  ON agendamentos.agendamento_comentario
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar comentários de agendamentos"
  ON agendamentos.agendamento_comentario
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar comentários de agendamentos"
  ON agendamentos.agendamento_comentario
  FOR DELETE
  TO authenticated
  USING (true);

-- Trigger para atualizar automaticamente o timestamp na tabela agendamento
CREATE TRIGGER update_agendamento_updated_at
  BEFORE UPDATE ON agendamentos.agendamento
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Criar índices para melhor performance

-- Índices para agendamento
CREATE INDEX IF NOT EXISTS idx_agendamento_cliente_final_id ON agendamentos.agendamento(cliente_final_id);
CREATE INDEX IF NOT EXISTS idx_agendamento_criado_por_id ON agendamentos.agendamento(criado_por_id);
CREATE INDEX IF NOT EXISTS idx_agendamento_data_inicio ON agendamentos.agendamento(data_inicio);
CREATE INDEX IF NOT EXISTS idx_agendamento_data_fim ON agendamentos.agendamento(data_fim);
CREATE INDEX IF NOT EXISTS idx_agendamento_status ON agendamentos.agendamento(status);
CREATE INDEX IF NOT EXISTS idx_agendamento_data_inicio_fim ON agendamentos.agendamento(data_inicio, data_fim);
CREATE INDEX IF NOT EXISTS idx_agendamento_cliente_data ON agendamentos.agendamento(cliente_final_id, data_inicio);
CREATE INDEX IF NOT EXISTS idx_agendamento_status_data ON agendamentos.agendamento(status, data_inicio);

-- Índices para agendamento_participante
CREATE INDEX IF NOT EXISTS idx_agendamento_participante_agendamento_id ON agendamentos.agendamento_participante(agendamento_id);
CREATE INDEX IF NOT EXISTS idx_agendamento_participante_usuario_interno_id ON agendamentos.agendamento_participante(usuario_interno_id) WHERE usuario_interno_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_agendamento_participante_colaborador_id ON agendamentos.agendamento_participante(colaborador_id) WHERE colaborador_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_agendamento_participante_tipo ON agendamentos.agendamento_participante(tipo) WHERE tipo IS NOT NULL;

-- Índices para agendamento_comentario
CREATE INDEX IF NOT EXISTS idx_agendamento_comentario_agendamento_id ON agendamentos.agendamento_comentario(agendamento_id);
CREATE INDEX IF NOT EXISTS idx_agendamento_comentario_usuario_interno_id ON agendamentos.agendamento_comentario(usuario_interno_id);
CREATE INDEX IF NOT EXISTS idx_agendamento_comentario_criado_em ON agendamentos.agendamento_comentario(criado_em);
CREATE INDEX IF NOT EXISTS idx_agendamento_comentario_agendamento_criado ON agendamentos.agendamento_comentario(agendamento_id, criado_em);

-- Inserir documentação das novas tabelas na tabela core.documentacao_tabelas
INSERT INTO core.documentacao_tabelas (nome_tabela, descricao) VALUES
(
  'SCHEMA_agendamentos',
  'SCHEMA: agendamentos - Schema dedicado ao sistema de agendamentos e compromissos. Contém as tabelas: agendamento (dados principais dos compromissos), agendamento_participante (participantes de cada agendamento) e agendamento_comentario (comentários e observações). Permite gerenciar agenda completa com clientes finais, incluindo participantes internos e externos.'
),
(
  'agendamento',
  'SCHEMA: agendamentos - Tabela principal que armazena os compromissos agendados com clientes finais. Cada agendamento possui título, descrição, data/hora de início e fim, local e status. Todo agendamento está obrigatoriamente vinculado a um cliente final e é criado por um usuário interno. Campos principais: id (identificador único), cliente_final_id (cliente relacionado), titulo (nome do compromisso), descricao (detalhes opcionais), data_inicio/data_fim (período do agendamento), local (endereço ou sala), status (agendado/realizado/cancelado), criado_por_id (usuário que criou), criado_em/atualizado_em (timestamps de controle).'
),
(
  'agendamento_participante',
  'SCHEMA: agendamentos - Tabela que registra todos os participantes de um agendamento específico. Pode incluir usuários internos da equipe ou colaboradores associados ao cliente. Cada participante é identificado pelo tipo (interno ou colaborador) e possui referência para a tabela correspondente. Campos principais: id (identificador único), agendamento_id (agendamento relacionado), usuario_interno_id (usuário interno participante, opcional), colaborador_id (colaborador participante, opcional), tipo (classificação do participante), criado_em (timestamp de inclusão). Constraint garante que apenas um dos IDs seja preenchido por registro.'
),
(
  'agendamento_comentario',
  'SCHEMA: agendamentos - Tabela para armazenar comentários e observações sobre agendamentos específicos. Permite que usuários internos adicionem notas, resultados de reuniões ou outras informações relevantes. Todos os comentários são sempre feitos por usuários internos da equipe. Campos principais: id (identificador único), agendamento_id (agendamento relacionado), usuario_interno_id (autor do comentário), comentario (texto da observação), criado_em (timestamp de criação). Útil para manter histórico de interações e resultados dos compromissos.'
);

-- Comentário explicativo sobre o novo schema
COMMENT ON SCHEMA agendamentos IS 'Schema para sistema completo de agendamentos e compromissos com clientes finais';