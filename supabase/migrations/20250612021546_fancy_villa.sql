/*
  # Criar schema projetos e tabelas relacionadas

  1. Novo Schema
    - `projetos` - Schema para organizar projetos e seus comentários

  2. Novas Tabelas
    - `projetos.projeto` - Dados principais dos projetos vinculados a clientes finais
    - `projetos.projeto_comentario` - Comentários em projetos

  3. Alterações em Tabelas Existentes
    - Adicionar coluna `projeto_id` na tabela `tarefas.tarefa`
    - Adicionar coluna `projeto_id` na tabela `tarefas.tarefa_recorrente`

  4. Segurança
    - Habilitar RLS em todas as tabelas
    - Políticas para usuários autenticados gerenciarem projetos
    - Chaves estrangeiras com integridade referencial

  5. Performance
    - Índices em colunas frequentemente consultadas
    - Constraints de validação apropriadas

  6. Documentação
    - Inserir descrições detalhadas na tabela core.documentacao_tabelas
*/

-- Criar o schema projetos
CREATE SCHEMA IF NOT EXISTS projetos;

-- Criar enums para status e prioridade do projeto
CREATE TYPE projetos.status_projeto AS ENUM ('planejado', 'em_andamento', 'pausado', 'concluido', 'cancelado');
CREATE TYPE projetos.prioridade_projeto AS ENUM ('baixa', 'media', 'alta', 'critica');

-- Criar tabela projeto
CREATE TABLE IF NOT EXISTS projetos.projeto (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cliente_id uuid NOT NULL REFERENCES clientes.cliente_final(id) ON DELETE CASCADE,
  nome text NOT NULL,
  descricao text,
  data_inicio date,
  data_fim date,
  status projetos.status_projeto DEFAULT 'planejado',
  prioridade projetos.prioridade_projeto DEFAULT 'media',
  responsavel_id uuid REFERENCES core.usuario_interno(id) ON DELETE SET NULL,
  ativo boolean DEFAULT true,
  criado_em timestamptz DEFAULT now(),
  atualizado_em timestamptz DEFAULT now(),
  
  -- Constraint para garantir que data_fim seja posterior a data_inicio
  CONSTRAINT check_data_fim_posterior CHECK (data_fim IS NULL OR data_inicio IS NULL OR data_fim >= data_inicio)
);

-- Criar tabela projeto_comentario
CREATE TABLE IF NOT EXISTS projetos.projeto_comentario (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  projeto_id uuid NOT NULL REFERENCES projetos.projeto(id) ON DELETE CASCADE,
  usuario_id uuid NOT NULL REFERENCES core.usuario_interno(id) ON DELETE CASCADE,
  comentario text NOT NULL,
  criado_em timestamptz DEFAULT now()
);

-- Habilitar RLS em ambas as tabelas
ALTER TABLE projetos.projeto ENABLE ROW LEVEL SECURITY;
ALTER TABLE projetos.projeto_comentario ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança para projeto
CREATE POLICY "Usuários autenticados podem ler projetos"
  ON projetos.projeto
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir projetos"
  ON projetos.projeto
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar projetos"
  ON projetos.projeto
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar projetos"
  ON projetos.projeto
  FOR DELETE
  TO authenticated
  USING (true);

-- Políticas de segurança para projeto_comentario
CREATE POLICY "Usuários autenticados podem ler comentários de projetos"
  ON projetos.projeto_comentario
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir comentários de projetos"
  ON projetos.projeto_comentario
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar comentários de projetos"
  ON projetos.projeto_comentario
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar comentários de projetos"
  ON projetos.projeto_comentario
  FOR DELETE
  TO authenticated
  USING (true);

-- Trigger para atualizar automaticamente o timestamp na tabela projeto
CREATE TRIGGER update_projeto_updated_at
  BEFORE UPDATE ON projetos.projeto
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Criar índices para melhor performance

-- Índices para projeto
CREATE INDEX IF NOT EXISTS idx_projeto_cliente_id ON projetos.projeto(cliente_id);
CREATE INDEX IF NOT EXISTS idx_projeto_responsavel_id ON projetos.projeto(responsavel_id) WHERE responsavel_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_projeto_status ON projetos.projeto(status);
CREATE INDEX IF NOT EXISTS idx_projeto_prioridade ON projetos.projeto(prioridade);
CREATE INDEX IF NOT EXISTS idx_projeto_ativo ON projetos.projeto(ativo);
CREATE INDEX IF NOT EXISTS idx_projeto_data_inicio ON projetos.projeto(data_inicio) WHERE data_inicio IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_projeto_data_fim ON projetos.projeto(data_fim) WHERE data_fim IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_projeto_nome ON projetos.projeto(nome);
CREATE INDEX IF NOT EXISTS idx_projeto_cliente_status ON projetos.projeto(cliente_id, status);
CREATE INDEX IF NOT EXISTS idx_projeto_cliente_ativo ON projetos.projeto(cliente_id, ativo);
CREATE INDEX IF NOT EXISTS idx_projeto_responsavel_status ON projetos.projeto(responsavel_id, status) WHERE responsavel_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_projeto_status_prioridade ON projetos.projeto(status, prioridade);

-- Índices para projeto_comentario
CREATE INDEX IF NOT EXISTS idx_projeto_comentario_projeto_id ON projetos.projeto_comentario(projeto_id);
CREATE INDEX IF NOT EXISTS idx_projeto_comentario_usuario_id ON projetos.projeto_comentario(usuario_id);
CREATE INDEX IF NOT EXISTS idx_projeto_comentario_criado_em ON projetos.projeto_comentario(criado_em);
CREATE INDEX IF NOT EXISTS idx_projeto_comentario_projeto_criado ON projetos.projeto_comentario(projeto_id, criado_em);
CREATE INDEX IF NOT EXISTS idx_projeto_comentario_usuario_criado ON projetos.projeto_comentario(usuario_id, criado_em);

-- Agora adicionar as colunas projeto_id nas tabelas de tarefas
-- Adicionar coluna projeto_id na tabela tarefa
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'tarefas' AND table_name = 'tarefa' AND column_name = 'projeto_id'
  ) THEN
    ALTER TABLE tarefas.tarefa ADD COLUMN projeto_id uuid REFERENCES projetos.projeto(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Adicionar coluna projeto_id na tabela tarefa_recorrente
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'tarefas' AND table_name = 'tarefa_recorrente' AND column_name = 'projeto_id'
  ) THEN
    ALTER TABLE tarefas.tarefa_recorrente ADD COLUMN projeto_id uuid REFERENCES projetos.projeto(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Criar índices para as novas colunas projeto_id
CREATE INDEX IF NOT EXISTS idx_tarefa_projeto_id ON tarefas.tarefa(projeto_id) WHERE projeto_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tarefa_recorrente_projeto_id ON tarefas.tarefa_recorrente(projeto_id) WHERE projeto_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tarefa_empresa_projeto ON tarefas.tarefa(empresa_id, projeto_id) WHERE projeto_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tarefa_recorrente_empresa_projeto ON tarefas.tarefa_recorrente(empresa_id, projeto_id) WHERE projeto_id IS NOT NULL;

-- Inserir documentação das novas tabelas e alterações
INSERT INTO core.documentacao_tabelas (nome_tabela, descricao) VALUES
(
  'SCHEMA_projetos',
  'SCHEMA: projetos - Schema dedicado ao gerenciamento de projetos vinculados a clientes finais. Organiza projetos estruturados com prazos, responsáveis e tarefas relacionadas. Contém as tabelas: projeto (dados principais dos projetos) e projeto_comentario (comentários e observações sobre projetos). Permite controle completo de entregas e processos internos organizados por projeto.'
),
(
  'projeto',
  'SCHEMA: projetos - Esta tabela armazena informações sobre projetos vinculados a clientes finais. Cada projeto representa uma entrega estruturada ou processo interno com prazos, responsáveis e tarefas relacionadas. Os arquivos são vinculados a esta tabela através da tabela genérica de arquivos usando a entidade "projeto". Campos principais: id (identificador único UUID), cliente_id (ID do cliente final relacionado ao projeto), nome (nome do projeto), descricao (descrição detalhada do projeto), data_inicio (data de início planejada), data_fim (data de término planejada), status (situação atual: planejado, em_andamento, pausado, concluído, cancelado), prioridade (nível de prioridade: baixa, média, alta, crítica), responsavel_id (usuário responsável principal pelo projeto), ativo (indica se o projeto está ativo ou arquivado), criado_em/atualizado_em (timestamps de controle).'
),
(
  'projeto_comentario',
  'SCHEMA: projetos - Comentários deixados por usuários nos projetos, servindo como histórico de comunicação e alinhamentos internos. Permite registrar observações, decisões, mudanças de escopo e outras informações relevantes ao longo do ciclo de vida do projeto. Campos principais: id (identificador único UUID), projeto_id (ID do projeto relacionado), usuario_id (ID do usuário que fez o comentário), comentario (conteúdo do comentário), criado_em (timestamp de criação). Essencial para manter histórico de comunicação e decisões tomadas durante a execução dos projetos.'
);

-- Atualizar documentação das tabelas de tarefas para incluir informação sobre projeto_id
UPDATE core.documentacao_tabelas 
SET 
  descricao = CONCAT(descricao, ' ATUALIZAÇÃO: Adicionada coluna projeto_id (UUID opcional) que permite associar tarefas a projetos específicos, facilitando a organização e visualização do progresso dos projetos no sistema.'),
  atualizado_em = now()
WHERE nome_tabela IN ('tarefa', 'tarefa_recorrente');

-- Comentários explicativos sobre o novo schema e alterações
COMMENT ON SCHEMA projetos IS 'Schema para gerenciamento completo de projetos vinculados a clientes finais';
COMMENT ON TABLE projetos.projeto IS 'Armazena dados principais de projetos estruturados vinculados a clientes finais';
COMMENT ON TABLE projetos.projeto_comentario IS 'Registra comentários e observações sobre projetos para histórico de comunicação';
COMMENT ON COLUMN tarefas.tarefa.projeto_id IS 'Referência opcional ao projeto relacionado a esta tarefa';
COMMENT ON COLUMN tarefas.tarefa_recorrente.projeto_id IS 'Referência opcional ao projeto vinculado a esta tarefa recorrente';