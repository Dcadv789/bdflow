/*
  # Criar tabelas de tags para clientes e tarefas

  1. Novas Tabelas
    - `clientes.tags_cliente`
      - `id` (uuid, chave primária)
      - `cliente_id` (uuid, FK para clientes.cliente_final)
      - `tag` (text, nome da tag)
      - `criado_em` (timestamptz, default now())

    - `tarefas.tags_tarefa`
      - `id` (uuid, chave primária)
      - `tarefa_id` (uuid, FK para tarefas.tarefa)
      - `tag` (text, nome da tag)
      - `criado_em` (timestamptz, default now())

  2. Segurança
    - Habilitar RLS em ambas as tabelas
    - Políticas para usuários autenticados gerenciarem tags
    - Chaves estrangeiras com integridade referencial

  3. Performance
    - Índices em colunas frequentemente consultadas
    - Constraints para evitar duplicação de tags por entidade
    - Índices compostos para consultas otimizadas

  4. Documentação
    - Inserir descrições detalhadas na tabela core.documentacao_tabelas
*/

-- Criar tabela tags_cliente no schema clientes
CREATE TABLE IF NOT EXISTS clientes.tags_cliente (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cliente_id uuid NOT NULL REFERENCES clientes.cliente_final(id) ON DELETE CASCADE,
  tag text NOT NULL,
  criado_em timestamptz DEFAULT now(),
  
  -- Constraint para evitar duplicação da mesma tag para o mesmo cliente
  UNIQUE(cliente_id, tag),
  
  -- Constraint para garantir que a tag não seja vazia
  CONSTRAINT check_tag_cliente_nao_vazia CHECK (length(trim(tag)) > 0)
);

-- Criar tabela tags_tarefa no schema tarefas
CREATE TABLE IF NOT EXISTS tarefas.tags_tarefa (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tarefa_id uuid NOT NULL REFERENCES tarefas.tarefa(id) ON DELETE CASCADE,
  tag text NOT NULL,
  criado_em timestamptz DEFAULT now(),
  
  -- Constraint para evitar duplicação da mesma tag para a mesma tarefa
  UNIQUE(tarefa_id, tag),
  
  -- Constraint para garantir que a tag não seja vazia
  CONSTRAINT check_tag_tarefa_nao_vazia CHECK (length(trim(tag)) > 0)
);

-- Habilitar RLS em ambas as tabelas
ALTER TABLE clientes.tags_cliente ENABLE ROW LEVEL SECURITY;
ALTER TABLE tarefas.tags_tarefa ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança para tags_cliente
CREATE POLICY "Usuários autenticados podem ler tags de clientes"
  ON clientes.tags_cliente
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir tags de clientes"
  ON clientes.tags_cliente
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar tags de clientes"
  ON clientes.tags_cliente
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar tags de clientes"
  ON clientes.tags_cliente
  FOR DELETE
  TO authenticated
  USING (true);

-- Políticas de segurança para tags_tarefa
CREATE POLICY "Usuários autenticados podem ler tags de tarefas"
  ON tarefas.tags_tarefa
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir tags de tarefas"
  ON tarefas.tags_tarefa
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar tags de tarefas"
  ON tarefas.tags_tarefa
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar tags de tarefas"
  ON tarefas.tags_tarefa
  FOR DELETE
  TO authenticated
  USING (true);

-- Criar índices para melhor performance

-- Índices para tags_cliente
CREATE INDEX IF NOT EXISTS idx_tags_cliente_cliente_id ON clientes.tags_cliente(cliente_id);
CREATE INDEX IF NOT EXISTS idx_tags_cliente_tag ON clientes.tags_cliente(tag);
CREATE INDEX IF NOT EXISTS idx_tags_cliente_criado_em ON clientes.tags_cliente(criado_em);
CREATE INDEX IF NOT EXISTS idx_tags_cliente_tag_lower ON clientes.tags_cliente(lower(tag));
CREATE INDEX IF NOT EXISTS idx_tags_cliente_cliente_criado ON clientes.tags_cliente(cliente_id, criado_em);

-- Índices para tags_tarefa
CREATE INDEX IF NOT EXISTS idx_tags_tarefa_tarefa_id ON tarefas.tags_tarefa(tarefa_id);
CREATE INDEX IF NOT EXISTS idx_tags_tarefa_tag ON tarefas.tags_tarefa(tag);
CREATE INDEX IF NOT EXISTS idx_tags_tarefa_criado_em ON tarefas.tags_tarefa(criado_em);
CREATE INDEX IF NOT EXISTS idx_tags_tarefa_tag_lower ON tarefas.tags_tarefa(lower(tag));
CREATE INDEX IF NOT EXISTS idx_tags_tarefa_tarefa_criado ON tarefas.tags_tarefa(tarefa_id, criado_em);

-- Inserir documentação das novas tabelas na tabela core.documentacao_tabelas
INSERT INTO core.documentacao_tabelas (nome_tabela, descricao) VALUES
(
  'tags_cliente',
  'SCHEMA: clientes - Tabela que relaciona tags com clientes finais, permitindo categorização flexível e organização dos clientes através de palavras-chave personalizadas. Cada cliente pode ter múltiplas tags associadas, facilitando filtros, buscas e segmentação. A estrutura permite inserção rápida de tags sem necessidade de tabela de tags pré-definidas, oferecendo máxima flexibilidade para os usuários. Campos principais: id (identificador único UUID), cliente_id (referência ao cliente final), tag (nome da tag em texto livre), criado_em (timestamp de criação). Constraint única evita duplicação da mesma tag para o mesmo cliente. Índices otimizados para busca por tag (incluindo busca case-insensitive) e consultas por cliente. Essencial para organização e filtros avançados na gestão de clientes.'
),
(
  'tags_tarefa',
  'SCHEMA: tarefas - Tabela que relaciona tags com tarefas, permitindo categorização e organização flexível das atividades através de palavras-chave personalizadas. Cada tarefa pode ter múltiplas tags associadas, facilitando filtros por tipo de atividade, prioridade, departamento ou qualquer critério definido pelos usuários. A estrutura permite inserção rápida de tags sem necessidade de tabela de tags pré-definidas, oferecendo máxima flexibilidade para categorização. Campos principais: id (identificador único UUID), tarefa_id (referência à tarefa), tag (nome da tag em texto livre), criado_em (timestamp de criação). Constraint única evita duplicação da mesma tag para a mesma tarefa. Índices otimizados para busca por tag (incluindo busca case-insensitive) e consultas por tarefa. Fundamental para organização, filtros avançados e relatórios segmentados no sistema de gestão de tarefas.'
);

-- Comentários explicativos sobre as tabelas
COMMENT ON TABLE clientes.tags_cliente IS 'Relaciona tags personalizadas com clientes finais para categorização e organização flexível';
COMMENT ON COLUMN clientes.tags_cliente.cliente_id IS 'Referência ao cliente final que possui esta tag';
COMMENT ON COLUMN clientes.tags_cliente.tag IS 'Nome da tag em texto livre para categorização do cliente';
COMMENT ON COLUMN clientes.tags_cliente.criado_em IS 'Data e hora em que a tag foi associada ao cliente';

COMMENT ON TABLE tarefas.tags_tarefa IS 'Relaciona tags personalizadas com tarefas para categorização e organização flexível';
COMMENT ON COLUMN tarefas.tags_tarefa.tarefa_id IS 'Referência à tarefa que possui esta tag';
COMMENT ON COLUMN tarefas.tags_tarefa.tag IS 'Nome da tag em texto livre para categorização da tarefa';
COMMENT ON COLUMN tarefas.tags_tarefa.criado_em IS 'Data e hora em que a tag foi associada à tarefa';