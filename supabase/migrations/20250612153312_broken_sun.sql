/*
  # Criar schema templates e tabelas para sistema de templates de tarefas

  1. Novo Schema
    - `templates` - Schema para organizar templates de fluxos de trabalho

  2. Novas Tabelas
    - `templates.template_base` - Cabeçalho dos templates
    - `templates.template_tarefa` - Tarefas dentro dos templates
    - `templates.template_tarefa_recorrente` - Configuração de recorrência para tarefas de templates

  3. Segurança
    - Habilitar RLS em todas as tabelas
    - Políticas para usuários autenticados gerenciarem templates
    - Chaves estrangeiras com integridade referencial

  4. Performance
    - Índices em colunas frequentemente consultadas
    - Constraints de validação apropriadas

  5. Documentação
    - Inserir descrições detalhadas na tabela core.documentacao_tabelas
*/

-- Criar o schema templates
CREATE SCHEMA IF NOT EXISTS templates;

-- Criar enum para tipo de recorrência (reutilizando a estrutura existente)
CREATE TYPE templates.tipo_recorrencia_template AS ENUM ('diaria', 'semanal', 'mensal', 'dias_uteis', 'intervalo_dias');

-- Criar tabela template_base
CREATE TABLE IF NOT EXISTS templates.template_base (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid NOT NULL REFERENCES core.empresa_base(id) ON DELETE CASCADE,
  nome text NOT NULL,
  descricao text,
  tipo_template text NOT NULL,
  criado_por_id uuid NOT NULL REFERENCES core.empresa_usuario(id) ON DELETE CASCADE,
  criado_em timestamptz DEFAULT now(),
  
  -- Constraints de validação
  CONSTRAINT check_nome_template_nao_vazio CHECK (length(trim(nome)) > 0),
  CONSTRAINT check_tipo_template_nao_vazio CHECK (length(trim(tipo_template)) > 0)
);

-- Criar tabela template_tarefa
CREATE TABLE IF NOT EXISTS templates.template_tarefa (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  template_base_id uuid NOT NULL REFERENCES templates.template_base(id) ON DELETE CASCADE,
  nome text NOT NULL,
  descricao text,
  responsavel_default_id uuid REFERENCES core.empresa_usuario(id) ON DELETE SET NULL,
  dias_apos_inicio integer NOT NULL DEFAULT 0,
  obrigatoria boolean DEFAULT true,
  ordem integer,
  criado_em timestamptz DEFAULT now(),
  
  -- Constraints de validação
  CONSTRAINT check_nome_tarefa_template_nao_vazio CHECK (length(trim(nome)) > 0),
  CONSTRAINT check_dias_apos_inicio_nao_negativo CHECK (dias_apos_inicio >= 0),
  CONSTRAINT check_ordem_positiva CHECK (ordem IS NULL OR ordem > 0)
);

-- Criar tabela template_tarefa_recorrente
CREATE TABLE IF NOT EXISTS templates.template_tarefa_recorrente (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  template_tarefa_id uuid NOT NULL REFERENCES templates.template_tarefa(id) ON DELETE CASCADE,
  tipo_recorrencia templates.tipo_recorrencia_template NOT NULL,
  frequencia integer DEFAULT 1,
  dias_semana jsonb,
  dia_do_mes integer,
  ordem_semana integer,
  dia_semana_ordem text,
  data_inicio_relativa integer DEFAULT 0,
  duracao_em_dias integer,
  nome text,
  descricao text,
  
  -- Constraints para validar dados de recorrência
  CONSTRAINT check_frequencia_template_positiva CHECK (frequencia > 0),
  CONSTRAINT check_dia_do_mes_template_valido CHECK (dia_do_mes IS NULL OR (dia_do_mes >= 1 AND dia_do_mes <= 31)),
  CONSTRAINT check_ordem_semana_template_valida CHECK (ordem_semana IS NULL OR (ordem_semana >= 1 AND ordem_semana <= 5)),
  CONSTRAINT check_data_inicio_relativa_nao_negativa CHECK (data_inicio_relativa >= 0),
  CONSTRAINT check_duracao_em_dias_positiva CHECK (duracao_em_dias IS NULL OR duracao_em_dias > 0)
);

-- Habilitar RLS em todas as tabelas
ALTER TABLE templates.template_base ENABLE ROW LEVEL SECURITY;
ALTER TABLE templates.template_tarefa ENABLE ROW LEVEL SECURITY;
ALTER TABLE templates.template_tarefa_recorrente ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança para template_base
CREATE POLICY "Usuários autenticados podem ler templates base"
  ON templates.template_base
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir templates base"
  ON templates.template_base
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar templates base"
  ON templates.template_base
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar templates base"
  ON templates.template_base
  FOR DELETE
  TO authenticated
  USING (true);

-- Políticas de segurança para template_tarefa
CREATE POLICY "Usuários autenticados podem ler tarefas de templates"
  ON templates.template_tarefa
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir tarefas de templates"
  ON templates.template_tarefa
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar tarefas de templates"
  ON templates.template_tarefa
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar tarefas de templates"
  ON templates.template_tarefa
  FOR DELETE
  TO authenticated
  USING (true);

-- Políticas de segurança para template_tarefa_recorrente
CREATE POLICY "Usuários autenticados podem ler recorrências de templates"
  ON templates.template_tarefa_recorrente
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir recorrências de templates"
  ON templates.template_tarefa_recorrente
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar recorrências de templates"
  ON templates.template_tarefa_recorrente
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar recorrências de templates"
  ON templates.template_tarefa_recorrente
  FOR DELETE
  TO authenticated
  USING (true);

-- Criar índices para melhor performance

-- Índices para template_base
CREATE INDEX IF NOT EXISTS idx_template_base_empresa_id ON templates.template_base(empresa_id);
CREATE INDEX IF NOT EXISTS idx_template_base_criado_por_id ON templates.template_base(criado_por_id);
CREATE INDEX IF NOT EXISTS idx_template_base_tipo_template ON templates.template_base(tipo_template);
CREATE INDEX IF NOT EXISTS idx_template_base_nome ON templates.template_base(nome);
CREATE INDEX IF NOT EXISTS idx_template_base_criado_em ON templates.template_base(criado_em);
CREATE INDEX IF NOT EXISTS idx_template_base_empresa_tipo ON templates.template_base(empresa_id, tipo_template);
CREATE INDEX IF NOT EXISTS idx_template_base_empresa_criado ON templates.template_base(empresa_id, criado_em);
CREATE INDEX IF NOT EXISTS idx_template_base_criado_por_criado ON templates.template_base(criado_por_id, criado_em);

-- Índices para template_tarefa
CREATE INDEX IF NOT EXISTS idx_template_tarefa_template_base_id ON templates.template_tarefa(template_base_id);
CREATE INDEX IF NOT EXISTS idx_template_tarefa_responsavel_default_id ON templates.template_tarefa(responsavel_default_id) WHERE responsavel_default_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_template_tarefa_dias_apos_inicio ON templates.template_tarefa(dias_apos_inicio);
CREATE INDEX IF NOT EXISTS idx_template_tarefa_obrigatoria ON templates.template_tarefa(obrigatoria);
CREATE INDEX IF NOT EXISTS idx_template_tarefa_ordem ON templates.template_tarefa(ordem) WHERE ordem IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_template_tarefa_criado_em ON templates.template_tarefa(criado_em);
CREATE INDEX IF NOT EXISTS idx_template_tarefa_template_ordem ON templates.template_tarefa(template_base_id, ordem);
CREATE INDEX IF NOT EXISTS idx_template_tarefa_template_dias ON templates.template_tarefa(template_base_id, dias_apos_inicio);
CREATE INDEX IF NOT EXISTS idx_template_tarefa_template_obrigatoria ON templates.template_tarefa(template_base_id, obrigatoria);

-- Índices para template_tarefa_recorrente
CREATE INDEX IF NOT EXISTS idx_template_tarefa_recorrente_template_tarefa_id ON templates.template_tarefa_recorrente(template_tarefa_id);
CREATE INDEX IF NOT EXISTS idx_template_tarefa_recorrente_tipo_recorrencia ON templates.template_tarefa_recorrente(tipo_recorrencia);
CREATE INDEX IF NOT EXISTS idx_template_tarefa_recorrente_frequencia ON templates.template_tarefa_recorrente(frequencia);
CREATE INDEX IF NOT EXISTS idx_template_tarefa_recorrente_data_inicio_relativa ON templates.template_tarefa_recorrente(data_inicio_relativa);
CREATE INDEX IF NOT EXISTS idx_template_tarefa_recorrente_duracao_em_dias ON templates.template_tarefa_recorrente(duracao_em_dias) WHERE duracao_em_dias IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_template_tarefa_recorrente_dia_do_mes ON templates.template_tarefa_recorrente(dia_do_mes) WHERE dia_do_mes IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_template_tarefa_recorrente_ordem_semana ON templates.template_tarefa_recorrente(ordem_semana) WHERE ordem_semana IS NOT NULL;

-- Inserir documentação das novas tabelas na tabela core.documentacao_tabelas
INSERT INTO core.documentacao_tabelas (nome_tabela, descricao) VALUES
(
  'SCHEMA_templates',
  'SCHEMA: templates - Schema dedicado ao sistema de templates de fluxos de trabalho. Permite criar modelos reutilizáveis de conjuntos de tarefas que podem ser aplicados a diferentes clientes e projetos. Contém as tabelas: template_base (cabeçalho dos templates), template_tarefa (tarefas individuais dentro dos templates) e template_tarefa_recorrente (configuração de recorrência para tarefas de templates). Facilita a padronização de processos como onboarding de clientes, início de serviços, fluxos customizados e outros procedimentos repetitivos.'
),
(
  'template_base',
  'SCHEMA: templates - Tabela que define o cabeçalho de um template de fluxo de trabalho. Um template pode conter uma ou várias tarefas (recorrentes ou não) e serve como modelo reutilizável para diferentes clientes e projetos. Permite categorização através do campo tipo_template para organizar diferentes tipos de fluxos (onboarding, início_servico, custom, etc.). Campos principais: id (identificador único UUID), empresa_id (empresa proprietária do template), nome (nome descritivo do template), descricao (explicação do propósito e funcionamento do template), tipo_template (categoria do template para organização), criado_por_id (usuário da empresa que criou o template), criado_em (timestamp de criação). Esta tabela é fundamental para a reutilização de processos padronizados e melhoria da eficiência operacional.'
),
(
  'template_tarefa',
  'SCHEMA: templates - Tabela que define uma tarefa individual dentro de um template. Cada tarefa possui configurações que serão usadas para criar tarefas reais quando o template for aplicado a um cliente ou projeto específico. Permite definir responsável padrão, timing relativo e obrigatoriedade. Campos principais: id (identificador único UUID), template_base_id (template ao qual esta tarefa pertence), nome (nome da tarefa), descricao (instruções ou observações sobre a tarefa), responsavel_default_id (usuário padrão que será responsável quando a tarefa for criada), dias_apos_inicio (quantos dias após o início da aplicação do template esta tarefa deve ser criada), obrigatoria (indica se a tarefa é obrigatória no fluxo), ordem (sequência de execução das tarefas), criado_em (timestamp de criação). Esta estrutura permite flexibilidade na definição de fluxos de trabalho padronizados.'
),
(
  'template_tarefa_recorrente',
  'SCHEMA: templates - Tabela que define configurações de recorrência para tarefas dentro de templates. Baseada na estrutura da tabela tarefas.tarefa_recorrente, permite criar tarefas que se repetem automaticamente quando o template for aplicado. Campos principais: id (identificador único UUID), template_tarefa_id (tarefa do template à qual esta recorrência se aplica), tipo_recorrencia (tipo: diaria, semanal, mensal, dias_uteis, intervalo_dias), frequencia (intervalo da repetição), dias_semana (array JSON com dias da semana para recorrência semanal), dia_do_mes (dia fixo do mês para recorrência mensal), ordem_semana (primeira, segunda, etc. semana do mês), dia_semana_ordem (dia da semana específico para ordem_semana), data_inicio_relativa (dias após aplicação do template para iniciar a recorrência), duracao_em_dias (duração total da recorrência em dias), nome (nome específico da tarefa recorrente), descricao (instruções adicionais para a recorrência). Permite automatizar tarefas repetitivas dentro de fluxos de trabalho padronizados.'
);

-- Comentários explicativos sobre o novo schema e tabelas
COMMENT ON SCHEMA templates IS 'Schema para sistema completo de templates de fluxos de trabalho reutilizáveis';
COMMENT ON TABLE templates.template_base IS 'Cabeçalho dos templates de fluxo de trabalho com informações gerais e categorização';
COMMENT ON TABLE templates.template_tarefa IS 'Tarefas individuais dentro dos templates com configurações para aplicação futura';
COMMENT ON TABLE templates.template_tarefa_recorrente IS 'Configurações de recorrência para tarefas de templates';

-- Comentários específicos sobre colunas importantes
COMMENT ON COLUMN templates.template_base.tipo_template IS 'Categoria do template (ex: onboarding, inicio_servico, custom) para organização';
COMMENT ON COLUMN templates.template_tarefa.dias_apos_inicio IS 'Dias após início da aplicação do template para criar esta tarefa';
COMMENT ON COLUMN templates.template_tarefa.obrigatoria IS 'Indica se esta tarefa é obrigatória no fluxo de trabalho';
COMMENT ON COLUMN templates.template_tarefa.ordem IS 'Sequência de execução das tarefas dentro do template';
COMMENT ON COLUMN templates.template_tarefa_recorrente.data_inicio_relativa IS 'Dias após aplicação do template para iniciar a recorrência';
COMMENT ON COLUMN templates.template_tarefa_recorrente.duracao_em_dias IS 'Duração total da recorrência em dias (opcional)';