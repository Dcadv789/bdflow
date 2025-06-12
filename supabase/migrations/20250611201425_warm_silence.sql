/*
  # Criar tabelas de relacionamento para controle de acesso

  1. Novas Tabelas
    - `cliente_supervisor`
      - `id` (uuid, chave primária)
      - `id_empresa` (uuid, FK para empresa_base)
      - `id_supervisor` (uuid, FK para empresa_usuario)
      - `id_cliente_final` (uuid, FK para cliente_final_base)
      - `criado_em` (timestamptz)
      - `modificado_em` (timestamptz)

    - `cliente_colaborador`
      - `id` (uuid, chave primária)
      - `id_empresa` (uuid, FK para empresa_base)
      - `id_colaborador` (uuid, FK para empresa_usuario)
      - `id_cliente_final` (uuid, FK para cliente_final_base)
      - `criado_em` (timestamptz)
      - `modificado_em` (timestamptz)

    - `supervisor_colaborador`
      - `id` (uuid, chave primária)
      - `id_empresa` (uuid, FK para empresa_base)
      - `id_supervisor` (uuid, FK para empresa_usuario)
      - `id_colaborador` (uuid, FK para empresa_usuario)
      - `criado_em` (timestamptz)
      - `modificado_em` (timestamptz)

  2. Segurança
    - Habilitar RLS em todas as tabelas
    - Políticas para usuários autenticados

  3. Performance
    - Índices em chaves estrangeiras e combinações frequentes
    - Constraints de unicidade para evitar duplicações

  4. Documentação
    - Inserir descrições detalhadas na tabela documentacao_tabelas
*/

-- Criar tabela cliente_supervisor
CREATE TABLE IF NOT EXISTS cliente_supervisor (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  id_empresa uuid NOT NULL REFERENCES empresa_base(id) ON DELETE CASCADE,
  id_supervisor uuid NOT NULL REFERENCES empresa_usuario(id) ON DELETE CASCADE,
  id_cliente_final uuid NOT NULL, -- Referência será criada quando a tabela cliente_final_base existir
  criado_em timestamptz DEFAULT now(),
  modificado_em timestamptz DEFAULT now(),
  
  -- Constraint para evitar duplicação
  UNIQUE(id_empresa, id_supervisor, id_cliente_final)
);

-- Criar tabela cliente_colaborador
CREATE TABLE IF NOT EXISTS cliente_colaborador (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  id_empresa uuid NOT NULL REFERENCES empresa_base(id) ON DELETE CASCADE,
  id_colaborador uuid NOT NULL REFERENCES empresa_usuario(id) ON DELETE CASCADE,
  id_cliente_final uuid NOT NULL, -- Referência será criada quando a tabela cliente_final_base existir
  criado_em timestamptz DEFAULT now(),
  modificado_em timestamptz DEFAULT now(),
  
  -- Constraint para evitar duplicação
  UNIQUE(id_empresa, id_colaborador, id_cliente_final)
);

-- Criar tabela supervisor_colaborador
CREATE TABLE IF NOT EXISTS supervisor_colaborador (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  id_empresa uuid NOT NULL REFERENCES empresa_base(id) ON DELETE CASCADE,
  id_supervisor uuid NOT NULL REFERENCES empresa_usuario(id) ON DELETE CASCADE,
  id_colaborador uuid NOT NULL REFERENCES empresa_usuario(id) ON DELETE CASCADE,
  criado_em timestamptz DEFAULT now(),
  modificado_em timestamptz DEFAULT now(),
  
  -- Constraint para evitar duplicação e auto-supervisão
  UNIQUE(id_empresa, id_supervisor, id_colaborador),
  CHECK(id_supervisor != id_colaborador)
);

-- Habilitar RLS em todas as tabelas
ALTER TABLE cliente_supervisor ENABLE ROW LEVEL SECURITY;
ALTER TABLE cliente_colaborador ENABLE ROW LEVEL SECURITY;
ALTER TABLE supervisor_colaborador ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança para cliente_supervisor
CREATE POLICY "Usuários autenticados podem ler relacionamentos supervisor-cliente"
  ON cliente_supervisor
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir relacionamentos supervisor-cliente"
  ON cliente_supervisor
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar relacionamentos supervisor-cliente"
  ON cliente_supervisor
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar relacionamentos supervisor-cliente"
  ON cliente_supervisor
  FOR DELETE
  TO authenticated
  USING (true);

-- Políticas de segurança para cliente_colaborador
CREATE POLICY "Usuários autenticados podem ler relacionamentos colaborador-cliente"
  ON cliente_colaborador
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir relacionamentos colaborador-cliente"
  ON cliente_colaborador
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar relacionamentos colaborador-cliente"
  ON cliente_colaborador
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar relacionamentos colaborador-cliente"
  ON cliente_colaborador
  FOR DELETE
  TO authenticated
  USING (true);

-- Políticas de segurança para supervisor_colaborador
CREATE POLICY "Usuários autenticados podem ler relacionamentos supervisor-colaborador"
  ON supervisor_colaborador
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir relacionamentos supervisor-colaborador"
  ON supervisor_colaborador
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar relacionamentos supervisor-colaborador"
  ON supervisor_colaborador
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar relacionamentos supervisor-colaborador"
  ON supervisor_colaborador
  FOR DELETE
  TO authenticated
  USING (true);

-- Triggers para atualizar automaticamente os timestamps
CREATE TRIGGER update_cliente_supervisor_updated_at
  BEFORE UPDATE ON cliente_supervisor
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cliente_colaborador_updated_at
  BEFORE UPDATE ON cliente_colaborador
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_supervisor_colaborador_updated_at
  BEFORE UPDATE ON supervisor_colaborador
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Criar índices para melhor performance
-- Índices para cliente_supervisor
CREATE INDEX IF NOT EXISTS idx_cliente_supervisor_empresa ON cliente_supervisor(id_empresa);
CREATE INDEX IF NOT EXISTS idx_cliente_supervisor_supervisor ON cliente_supervisor(id_supervisor);
CREATE INDEX IF NOT EXISTS idx_cliente_supervisor_cliente ON cliente_supervisor(id_cliente_final);
CREATE INDEX IF NOT EXISTS idx_cliente_supervisor_empresa_supervisor ON cliente_supervisor(id_empresa, id_supervisor);

-- Índices para cliente_colaborador
CREATE INDEX IF NOT EXISTS idx_cliente_colaborador_empresa ON cliente_colaborador(id_empresa);
CREATE INDEX IF NOT EXISTS idx_cliente_colaborador_colaborador ON cliente_colaborador(id_colaborador);
CREATE INDEX IF NOT EXISTS idx_cliente_colaborador_cliente ON cliente_colaborador(id_cliente_final);
CREATE INDEX IF NOT EXISTS idx_cliente_colaborador_empresa_colaborador ON cliente_colaborador(id_empresa, id_colaborador);

-- Índices para supervisor_colaborador
CREATE INDEX IF NOT EXISTS idx_supervisor_colaborador_empresa ON supervisor_colaborador(id_empresa);
CREATE INDEX IF NOT EXISTS idx_supervisor_colaborador_supervisor ON supervisor_colaborador(id_supervisor);
CREATE INDEX IF NOT EXISTS idx_supervisor_colaborador_colaborador ON supervisor_colaborador(id_colaborador);
CREATE INDEX IF NOT EXISTS idx_supervisor_colaborador_empresa_supervisor ON supervisor_colaborador(id_empresa, id_supervisor);

-- Inserir documentação das novas tabelas
INSERT INTO documentacao_tabelas (nome_tabela, descricao) VALUES
(
  'cliente_supervisor',
  'Relaciona supervisores aos clientes finais que eles podem acessar dentro da empresa. Permite limitar a visão do supervisor apenas aos clientes finais designados. Esta tabela é fundamental para o controle de acesso granular, garantindo que cada supervisor veja apenas os clientes sob sua responsabilidade. Campos principais: id (identificador único), id_empresa (empresa dona do relacionamento), id_supervisor (supervisor relacionado), id_cliente_final (cliente final acessível pelo supervisor), criado_em (data de criação), modificado_em (data da última modificação).'
),
(
  'cliente_colaborador',
  'Relaciona colaboradores aos clientes finais que eles podem acessar dentro da empresa. Limita a visão do colaborador aos clientes finais designados, proporcionando controle de acesso específico por colaborador. Esta segmentação garante que cada colaborador trabalhe apenas com os clientes atribuídos a ele. Campos principais: id (identificador único), id_empresa (empresa dona do relacionamento), id_colaborador (colaborador relacionado), id_cliente_final (cliente final acessível pelo colaborador), criado_em (data de criação), modificado_em (data da última modificação).'
),
(
  'supervisor_colaborador',
  'Relaciona supervisores com colaboradores que eles supervisionam dentro da empresa. Controla a hierarquia e delegação de acesso, permitindo que supervisores gerenciem suas equipes e tenham visibilidade sobre o trabalho dos colaboradores sob sua supervisão. Esta estrutura hierárquica é essencial para o fluxo de trabalho e controle organizacional. Campos principais: id (identificador único), id_empresa (empresa dona do relacionamento), id_supervisor (supervisor responsável), id_colaborador (colaborador supervisionado), criado_em (data de criação), modificado_em (data da última modificação).'
);