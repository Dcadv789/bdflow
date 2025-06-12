/*
  # Adicionar colunas na tabela tarefa_checklist

  1. Alterações na Tabela
    - `tarefas.tarefa_checklist`
      - Adicionar `atualizado_em` (timestamptz, default now())
      - Adicionar `criado_por_id` (uuid, FK para core.empresa_usuario)

  2. Segurança
    - Manter RLS existente
    - Adicionar índices para as novas colunas

  3. Performance
    - Índices para consultas frequentes nas novas colunas
    - Trigger para atualização automática do timestamp

  4. Documentação
    - Atualizar descrição na tabela core.documentacao_tabelas
*/

-- Adicionar coluna atualizado_em na tabela tarefa_checklist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'tarefas' AND table_name = 'tarefa_checklist' AND column_name = 'atualizado_em'
  ) THEN
    ALTER TABLE tarefas.tarefa_checklist ADD COLUMN atualizado_em timestamptz DEFAULT now();
  END IF;
END $$;

-- Adicionar coluna criado_por_id na tabela tarefa_checklist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'tarefas' AND table_name = 'tarefa_checklist' AND column_name = 'criado_por_id'
  ) THEN
    ALTER TABLE tarefas.tarefa_checklist ADD COLUMN criado_por_id uuid REFERENCES core.empresa_usuario(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Criar trigger para atualizar automaticamente o timestamp atualizado_em
DROP TRIGGER IF EXISTS update_tarefa_checklist_updated_at ON tarefas.tarefa_checklist;
CREATE TRIGGER update_tarefa_checklist_updated_at
  BEFORE UPDATE ON tarefas.tarefa_checklist
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Criar índices para as novas colunas
CREATE INDEX IF NOT EXISTS idx_tarefa_checklist_atualizado_em ON tarefas.tarefa_checklist(atualizado_em);
CREATE INDEX IF NOT EXISTS idx_tarefa_checklist_criado_por_id ON tarefas.tarefa_checklist(criado_por_id) WHERE criado_por_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tarefa_checklist_tarefa_criado_por ON tarefas.tarefa_checklist(tarefa_id, criado_por_id) WHERE criado_por_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tarefa_checklist_criado_por_atualizado ON tarefas.tarefa_checklist(criado_por_id, atualizado_em) WHERE criado_por_id IS NOT NULL;

-- Atualizar a descrição na tabela documentacao_tabelas
UPDATE core.documentacao_tabelas 
SET 
  descricao = 'SCHEMA: tarefas - Esta tabela armazena os itens de checklist (subtarefas) de cada tarefa. Permite adicionar múltiplos itens com marcação de concluído, mantendo a rastreabilidade e organização das etapas de execução de uma tarefa. ATUALIZAÇÃO: Adicionadas colunas atualizado_em (timestamp da última modificação do item) e criado_por_id (usuário da empresa contratante que criou o item) para rastreamento de edições e autoria. Campos principais: id (identificador único UUID), tarefa_id (referência à tarefa principal), descricao (descrição do item de checklist), concluido (status de conclusão do item, default false), ordem (ordem ou prioridade de exibição, opcional), criado_em (data e hora da criação), atualizado_em (data e hora da última modificação), criado_por_id (usuário da empresa que criou o item, referência para core.empresa_usuario). O controle de autoria permite identificar quem criou cada item do checklist, facilitando a responsabilização e o acompanhamento das contribuições de cada membro da equipe.',
  atualizado_em = now()
WHERE nome_tabela = 'tarefa_checklist';

-- Comentários explicativos sobre as novas colunas
COMMENT ON COLUMN tarefas.tarefa_checklist.atualizado_em IS 'Data e hora da última modificação do item do checklist';
COMMENT ON COLUMN tarefas.tarefa_checklist.criado_por_id IS 'Usuário da empresa contratante que criou este item do checklist';