/*
  # Criar tabelas de tarefas e tarefas recorrentes

  1. Novas Tabelas
    - `tarefa`
      - `id` (uuid, chave primária)
      - `nome` (text, obrigatório)
      - `descricao` (text, opcional)
      - `empresa_id` (uuid, FK para empresa_base)
      - `usuario_responsavel_id` (uuid, FK para empresa_usuario)
      - `cliente_final_id` (uuid, FK para cliente_final, opcional)
      - `data_vencimento` (date, obrigatório)
      - `status` (enum: pendente, em_andamento, concluida)
      - `prioridade` (enum: baixa, media, alta)
      - `criado_em` (timestamptz, default now())
      - `atualizado_em` (timestamptz, default now())

    - `tarefa_recorrente`
      - `id` (uuid, chave primária)
      - `nome` (text, obrigatório)
      - `descricao` (text, opcional)
      - `empresa_id` (uuid, FK para empresa_base)
      - `usuario_responsavel_id` (uuid, FK para empresa_usuario)
      - `cliente_final_id` (uuid, FK para cliente_final, opcional)
      - `inicio_em` (date, obrigatório)
      - `fim_em` (date, opcional)
      - `tipo_recorrencia` (enum: diaria, semanal, mensal, dias_uteis, intervalo_dias)
      - `frequencia` (integer, default 1)
      - `dias_semana` (jsonb, opcional)
      - `dia_do_mes` (integer, opcional)
      - `ordem_semana` (integer, opcional)
      - `dia_semana_ordem` (text, opcional)
      - `criado_em` (timestamptz, default now())
      - `atualizado_em` (timestamptz, default now())

  2. Segurança
    - Habilitar RLS em ambas as tabelas
    - Políticas para usuários autenticados gerenciarem tarefas
    - Chaves estrangeiras com integridade referencial

  3. Performance
    - Índices em colunas frequentemente consultadas
    - Constraints para garantir consistência de dados

  4. Documentação
    - Inserir descrições detalhadas na tabela documentacao_tabelas
*/

-- Criar enums para status e prioridade da tarefa
CREATE TYPE status_tarefa AS ENUM ('pendente', 'em_andamento', 'concluida');
CREATE TYPE prioridade_tarefa AS ENUM ('baixa', 'media', 'alta');

-- Criar enum para tipo de recorrência
CREATE TYPE tipo_recorrencia AS ENUM ('diaria', 'semanal', 'mensal', 'dias_uteis', 'intervalo_dias');

-- Criar tabela tarefa
CREATE TABLE IF NOT EXISTS tarefa (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nome text NOT NULL,
  descricao text,
  empresa_id uuid NOT NULL REFERENCES empresa_base(id) ON DELETE CASCADE,
  usuario_responsavel_id uuid NOT NULL REFERENCES empresa_usuario(id) ON DELETE CASCADE,
  cliente_final_id uuid REFERENCES cliente_final(id) ON DELETE SET NULL,
  data_vencimento date NOT NULL,
  status status_tarefa DEFAULT 'pendente',
  prioridade prioridade_tarefa DEFAULT 'media',
  criado_em timestamptz DEFAULT now(),
  atualizado_em timestamptz DEFAULT now()
);

-- Criar tabela tarefa_recorrente
CREATE TABLE IF NOT EXISTS tarefa_recorrente (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nome text NOT NULL,
  descricao text,
  empresa_id uuid NOT NULL REFERENCES empresa_base(id) ON DELETE CASCADE,
  usuario_responsavel_id uuid NOT NULL REFERENCES empresa_usuario(id) ON DELETE CASCADE,
  cliente_final_id uuid REFERENCES cliente_final(id) ON DELETE SET NULL,
  inicio_em date NOT NULL,
  fim_em date,
  tipo_recorrencia tipo_recorrencia NOT NULL,
  frequencia integer DEFAULT 1,
  dias_semana jsonb,
  dia_do_mes integer,
  ordem_semana integer,
  dia_semana_ordem text,
  criado_em timestamptz DEFAULT now(),
  atualizado_em timestamptz DEFAULT now(),
  
  -- Constraints para validar dados de recorrência
  CONSTRAINT check_frequencia_positiva CHECK (frequencia > 0),
  CONSTRAINT check_dia_do_mes_valido CHECK (dia_do_mes IS NULL OR (dia_do_mes >= 1 AND dia_do_mes <= 31)),
  CONSTRAINT check_ordem_semana_valida CHECK (ordem_semana IS NULL OR (ordem_semana >= 1 AND ordem_semana <= 5)),
  CONSTRAINT check_fim_em_posterior CHECK (fim_em IS NULL OR fim_em >= inicio_em)
);

-- Habilitar RLS em ambas as tabelas
ALTER TABLE tarefa ENABLE ROW LEVEL SECURITY;
ALTER TABLE tarefa_recorrente ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança para tarefa
CREATE POLICY "Usuários autenticados podem ler tarefas"
  ON tarefa
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir tarefas"
  ON tarefa
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar tarefas"
  ON tarefa
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar tarefas"
  ON tarefa
  FOR DELETE
  TO authenticated
  USING (true);

-- Políticas de segurança para tarefa_recorrente
CREATE POLICY "Usuários autenticados podem ler tarefas recorrentes"
  ON tarefa_recorrente
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir tarefas recorrentes"
  ON tarefa_recorrente
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar tarefas recorrentes"
  ON tarefa_recorrente
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar tarefas recorrentes"
  ON tarefa_recorrente
  FOR DELETE
  TO authenticated
  USING (true);

-- Triggers para atualizar automaticamente os timestamps
CREATE TRIGGER update_tarefa_updated_at
  BEFORE UPDATE ON tarefa
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tarefa_recorrente_updated_at
  BEFORE UPDATE ON tarefa_recorrente
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Criar índices para melhor performance na tabela tarefa
CREATE INDEX IF NOT EXISTS idx_tarefa_empresa_id ON tarefa(empresa_id);
CREATE INDEX IF NOT EXISTS idx_tarefa_usuario_responsavel_id ON tarefa(usuario_responsavel_id);
CREATE INDEX IF NOT EXISTS idx_tarefa_cliente_final_id ON tarefa(cliente_final_id) WHERE cliente_final_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tarefa_data_vencimento ON tarefa(data_vencimento);
CREATE INDEX IF NOT EXISTS idx_tarefa_status ON tarefa(status);
CREATE INDEX IF NOT EXISTS idx_tarefa_prioridade ON tarefa(prioridade);
CREATE INDEX IF NOT EXISTS idx_tarefa_empresa_usuario ON tarefa(empresa_id, usuario_responsavel_id);
CREATE INDEX IF NOT EXISTS idx_tarefa_status_vencimento ON tarefa(status, data_vencimento);

-- Criar índices para melhor performance na tabela tarefa_recorrente
CREATE INDEX IF NOT EXISTS idx_tarefa_recorrente_empresa_id ON tarefa_recorrente(empresa_id);
CREATE INDEX IF NOT EXISTS idx_tarefa_recorrente_usuario_responsavel_id ON tarefa_recorrente(usuario_responsavel_id);
CREATE INDEX IF NOT EXISTS idx_tarefa_recorrente_cliente_final_id ON tarefa_recorrente(cliente_final_id) WHERE cliente_final_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tarefa_recorrente_inicio_em ON tarefa_recorrente(inicio_em);
CREATE INDEX IF NOT EXISTS idx_tarefa_recorrente_fim_em ON tarefa_recorrente(fim_em) WHERE fim_em IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tarefa_recorrente_tipo ON tarefa_recorrente(tipo_recorrencia);
CREATE INDEX IF NOT EXISTS idx_tarefa_recorrente_empresa_usuario ON tarefa_recorrente(empresa_id, usuario_responsavel_id);

-- Inserir documentação das novas tabelas
INSERT INTO documentacao_tabelas (nome_tabela, descricao) VALUES
(
  'tarefa',
  'Tabela que armazena tarefas atribuídas a usuários, podendo estar vinculadas a uma empresa e opcionalmente a um cliente final. Campos principais: id (uuid – Identificador único da tarefa), nome (text – Nome ou título da tarefa), descricao (text – Descrição ou observações sobre a tarefa), empresa_id (uuid – ID da empresa responsável pela tarefa), usuario_responsavel_id (uuid – ID do usuário responsável por executar a tarefa), cliente_final_id (uuid – ID do cliente final, opcional), data_vencimento (date – Data limite para conclusão da tarefa), status (text – Status da tarefa: pendente, em andamento, concluída), prioridade (text – Prioridade: baixa, média, alta), criado_em (timestamp – Data de criação da tarefa), atualizado_em (timestamp – Data da última modificação).'
),
(
  'tarefa_recorrente',
  'Tabela para configuração de tarefas recorrentes. Serve como base para gerar tarefas futuras automaticamente com diferentes regras de repetição. Campos principais: id (uuid – Identificador único da tarefa recorrente), nome (text – Nome ou título da tarefa recorrente), descricao (text – Observações ou instruções sobre a tarefa recorrente), empresa_id (uuid – ID da empresa relacionada à tarefa), usuario_responsavel_id (uuid – ID do usuário responsável por executar a tarefa), cliente_final_id (uuid – ID do cliente final, opcional), inicio_em (date – Data de início da recorrência), fim_em (date – Data de término da recorrência, opcional), tipo_recorrencia (text – Tipo de recorrência: diaria, semanal, mensal, dias_uteis, intervalo_dias), frequencia (integer – Intervalo da repetição, ex: a cada 2 dias), dias_semana (json – Lista de dias da semana para recorrência, ex: ["segunda", "quarta"]), dia_do_mes (integer – Dia fixo do mês para recorrência, ex: dia 5), ordem_semana (integer – Ordem da semana no mês: 1=primeira, 2=segunda, etc.), dia_semana_ordem (text – Dia da semana usado em conjunto com ordem_semana, ex: "segunda-feira"), criado_em (timestamp – Data de criação do padrão de recorrência).'
);