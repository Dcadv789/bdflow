/*
  # Criar tabelas de suporte para tarefas

  1. Novas Tabelas
    - `tarefa_comentario`
      - `id` (uuid, chave primária)
      - `tarefa_id` (uuid, FK para tarefa)
      - `usuario_id` (uuid, FK para empresa_usuario)
      - `comentario` (text, obrigatório)
      - `criado_em` (timestamptz, default now())

    - `tarefa_notificacao`
      - `id` (uuid, chave primária)
      - `usuario_id` (uuid, FK para empresa_usuario)
      - `tarefa_id` (uuid, FK para tarefa)
      - `mensagem` (text, obrigatório)
      - `tipo` (text, obrigatório)
      - `lida` (boolean, default false)
      - `criado_em` (timestamptz, default now())

    - `tarefa_checklist`
      - `id` (uuid, chave primária)
      - `tarefa_id` (uuid, FK para tarefa)
      - `descricao` (text, obrigatório)
      - `concluido` (boolean, default false)
      - `ordem` (integer, opcional)
      - `criado_em` (timestamptz, default now())

  2. Segurança
    - Habilitar RLS em todas as tabelas
    - Políticas para usuários autenticados gerenciarem dados
    - Chaves estrangeiras com integridade referencial

  3. Performance
    - Índices em colunas frequentemente consultadas
    - Constraints de validação apropriadas

  4. Documentação
    - Inserir descrições detalhadas na tabela documentacao_tabelas
*/

-- Criar tabela tarefa_comentario
CREATE TABLE IF NOT EXISTS tarefa_comentario (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tarefa_id uuid NOT NULL REFERENCES tarefa(id) ON DELETE CASCADE,
  usuario_id uuid NOT NULL REFERENCES empresa_usuario(id) ON DELETE CASCADE,
  comentario text NOT NULL,
  criado_em timestamptz DEFAULT now()
);

-- Criar tabela tarefa_notificacao
CREATE TABLE IF NOT EXISTS tarefa_notificacao (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id uuid NOT NULL REFERENCES empresa_usuario(id) ON DELETE CASCADE,
  tarefa_id uuid NOT NULL REFERENCES tarefa(id) ON DELETE CASCADE,
  mensagem text NOT NULL,
  tipo text NOT NULL,
  lida boolean DEFAULT false,
  criado_em timestamptz DEFAULT now()
);

-- Criar tabela tarefa_checklist
CREATE TABLE IF NOT EXISTS tarefa_checklist (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tarefa_id uuid NOT NULL REFERENCES tarefa(id) ON DELETE CASCADE,
  descricao text NOT NULL,
  concluido boolean DEFAULT false,
  ordem integer,
  criado_em timestamptz DEFAULT now()
);

-- Habilitar RLS em todas as tabelas
ALTER TABLE tarefa_comentario ENABLE ROW LEVEL SECURITY;
ALTER TABLE tarefa_notificacao ENABLE ROW LEVEL SECURITY;
ALTER TABLE tarefa_checklist ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança para tarefa_comentario
CREATE POLICY "Usuários autenticados podem ler comentários de tarefas"
  ON tarefa_comentario
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir comentários de tarefas"
  ON tarefa_comentario
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar comentários de tarefas"
  ON tarefa_comentario
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar comentários de tarefas"
  ON tarefa_comentario
  FOR DELETE
  TO authenticated
  USING (true);

-- Políticas de segurança para tarefa_notificacao
CREATE POLICY "Usuários autenticados podem ler notificações de tarefas"
  ON tarefa_notificacao
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir notificações de tarefas"
  ON tarefa_notificacao
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar notificações de tarefas"
  ON tarefa_notificacao
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar notificações de tarefas"
  ON tarefa_notificacao
  FOR DELETE
  TO authenticated
  USING (true);

-- Políticas de segurança para tarefa_checklist
CREATE POLICY "Usuários autenticados podem ler checklists de tarefas"
  ON tarefa_checklist
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir checklists de tarefas"
  ON tarefa_checklist
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar checklists de tarefas"
  ON tarefa_checklist
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar checklists de tarefas"
  ON tarefa_checklist
  FOR DELETE
  TO authenticated
  USING (true);

-- Criar índices para melhor performance

-- Índices para tarefa_comentario
CREATE INDEX IF NOT EXISTS idx_tarefa_comentario_tarefa_id ON tarefa_comentario(tarefa_id);
CREATE INDEX IF NOT EXISTS idx_tarefa_comentario_usuario_id ON tarefa_comentario(usuario_id);
CREATE INDEX IF NOT EXISTS idx_tarefa_comentario_criado_em ON tarefa_comentario(criado_em);
CREATE INDEX IF NOT EXISTS idx_tarefa_comentario_tarefa_criado ON tarefa_comentario(tarefa_id, criado_em);

-- Índices para tarefa_notificacao
CREATE INDEX IF NOT EXISTS idx_tarefa_notificacao_usuario_id ON tarefa_notificacao(usuario_id);
CREATE INDEX IF NOT EXISTS idx_tarefa_notificacao_tarefa_id ON tarefa_notificacao(tarefa_id);
CREATE INDEX IF NOT EXISTS idx_tarefa_notificacao_lida ON tarefa_notificacao(lida);
CREATE INDEX IF NOT EXISTS idx_tarefa_notificacao_tipo ON tarefa_notificacao(tipo);
CREATE INDEX IF NOT EXISTS idx_tarefa_notificacao_usuario_lida ON tarefa_notificacao(usuario_id, lida);
CREATE INDEX IF NOT EXISTS idx_tarefa_notificacao_criado_em ON tarefa_notificacao(criado_em);

-- Índices para tarefa_checklist
CREATE INDEX IF NOT EXISTS idx_tarefa_checklist_tarefa_id ON tarefa_checklist(tarefa_id);
CREATE INDEX IF NOT EXISTS idx_tarefa_checklist_concluido ON tarefa_checklist(concluido);
CREATE INDEX IF NOT EXISTS idx_tarefa_checklist_ordem ON tarefa_checklist(ordem) WHERE ordem IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tarefa_checklist_tarefa_ordem ON tarefa_checklist(tarefa_id, ordem);
CREATE INDEX IF NOT EXISTS idx_tarefa_checklist_tarefa_concluido ON tarefa_checklist(tarefa_id, concluido);

-- Inserir documentação das novas tabelas
INSERT INTO documentacao_tabelas (nome_tabela, descricao) VALUES
(
  'tarefa_comentario',
  'Esta tabela armazena os comentários feitos dentro de uma tarefa. Cada comentário pertence a um usuário e está vinculado a uma tarefa específica. Permite registrar históricos de discussões ou informações adicionais inseridas ao longo do andamento da tarefa. Campos principais: id (identificador único UUID), tarefa_id (referência à tarefa), usuario_id (referência ao autor do comentário), comentario (texto do comentário), criado_em (data e hora da criação).'
),
(
  'tarefa_notificacao',
  'Esta tabela armazena notificações relacionadas a tarefas, podendo ser usadas para lembretes, alertas de atraso ou outras comunicações internas. O campo lida indica se o usuário já visualizou a notificação. Campos principais: id (identificador único UUID), usuario_id (referência ao usuário que receberá a notificação), tarefa_id (referência à tarefa relacionada), mensagem (conteúdo da notificação), tipo (tipo da notificação: lembrete, vencimento, atraso), lida (status de leitura, default false), criado_em (data e hora da criação).'
),
(
  'tarefa_checklist',
  'Esta tabela armazena os itens de checklist (subtarefas) de cada tarefa. Permite adicionar múltiplos itens com marcação de concluído, mantendo a rastreabilidade e organização das etapas de execução de uma tarefa. Campos principais: id (identificador único UUID), tarefa_id (referência à tarefa principal), descricao (descrição do item de checklist), concluido (status de conclusão do item, default false), ordem (ordem ou prioridade de exibição, opcional), criado_em (data e hora da criação).'
);