/*
  # Criar tabelas de planos e itens de planos

  1. Novas Tabelas
    - `planos`
      - `id` (uuid, chave primária)
      - `nome` (text, obrigatório)
      - `descricao` (text, opcional)
      - `valor_mensal` (numeric, opcional)
      - `status` (enum: ativo, inativo)
      - `criado_em` (timestamptz, default now())
      - `atualizado_em` (timestamptz, default now())
    
    - `plano_itens`
      - `id` (uuid, chave primária)
      - `plano_id` (uuid, FK para planos.id)
      - `nome_item` (text, obrigatório)
      - `descricao_item` (text, opcional)
      - `quantidade_incluida` (integer, opcional)
      - `tipo_item` (text, opcional)
      - `criado_em` (timestamptz, default now())
      - `atualizado_em` (timestamptz, default now())

  2. Segurança
    - Habilitar RLS em ambas as tabelas
    - Políticas para usuários autenticados

  3. Performance
    - Índices para consultas frequentes
    - Chave estrangeira com deleção em cascata

  4. Documentação
    - Inserir descrições na tabela documentacao_tabelas
*/

-- Criar enum para status do plano
CREATE TYPE status_plano AS ENUM ('ativo', 'inativo');

-- Criar tabela planos
CREATE TABLE IF NOT EXISTS planos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nome text NOT NULL,
  descricao text,
  valor_mensal numeric(10,2),
  status status_plano DEFAULT 'ativo',
  criado_em timestamptz DEFAULT now(),
  atualizado_em timestamptz DEFAULT now()
);

-- Criar tabela plano_itens
CREATE TABLE IF NOT EXISTS plano_itens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plano_id uuid NOT NULL REFERENCES planos(id) ON DELETE CASCADE,
  nome_item text NOT NULL,
  descricao_item text,
  quantidade_incluida integer,
  tipo_item text,
  criado_em timestamptz DEFAULT now(),
  atualizado_em timestamptz DEFAULT now()
);

-- Habilitar RLS em ambas as tabelas
ALTER TABLE planos ENABLE ROW LEVEL SECURITY;
ALTER TABLE plano_itens ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança para planos
CREATE POLICY "Usuários autenticados podem ler planos"
  ON planos
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir planos"
  ON planos
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar planos"
  ON planos
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar planos"
  ON planos
  FOR DELETE
  TO authenticated
  USING (true);

-- Políticas de segurança para plano_itens
CREATE POLICY "Usuários autenticados podem ler itens de planos"
  ON plano_itens
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir itens de planos"
  ON plano_itens
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar itens de planos"
  ON plano_itens
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar itens de planos"
  ON plano_itens
  FOR DELETE
  TO authenticated
  USING (true);

-- Triggers para atualizar automaticamente os timestamps
CREATE TRIGGER update_planos_updated_at
  BEFORE UPDATE ON planos
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_plano_itens_updated_at
  BEFORE UPDATE ON plano_itens
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_planos_nome ON planos(nome);
CREATE INDEX IF NOT EXISTS idx_planos_status ON planos(status);
CREATE INDEX IF NOT EXISTS idx_planos_valor_mensal ON planos(valor_mensal) WHERE valor_mensal IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_plano_itens_plano_id ON plano_itens(plano_id);
CREATE INDEX IF NOT EXISTS idx_plano_itens_tipo_item ON plano_itens(tipo_item) WHERE tipo_item IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_plano_itens_nome_item ON plano_itens(nome_item);

-- Inserir documentação das novas tabelas
INSERT INTO documentacao_tabelas (nome_tabela, descricao) VALUES
(
  'planos',
  'Tabela que armazena os planos disponíveis no sistema. Cada plano define um pacote de serviços ou recursos que pode ser associado a um cliente final. Os dados incluem nome, descrição, valor mensal e status do plano (ativo ou inativo). Um plano pode ter vários itens associados que descrevem seus benefícios. Esta tabela é fundamental para a gestão comercial e definição de pacotes de serviços oferecidos aos clientes.'
),
(
  'plano_itens',
  'Tabela que detalha os itens que compõem cada plano. Cada item representa um recurso ou funcionalidade oferecida, podendo ter nome, descrição, tipo e quantidade incluída. Está vinculada à tabela planos através de chave estrangeira e permite flexibilidade para compor diferentes pacotes conforme a necessidade. Os itens podem ser categorizados por tipo (usuário, relatório, dashboard, etc.) e ter limites quantitativos definidos.'
);