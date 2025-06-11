/*
  # Criar tabela de documentação das tabelas

  1. Nova Tabela
    - `documentacao_tabelas`
      - `id` (uuid, chave primária)
      - `nome_tabela` (text, nome da tabela)
      - `descricao` (text, descrição detalhada da tabela)
      - `criado_em` (timestamptz, timestamp de criação)
      - `atualizado_em` (timestamptz, timestamp de atualização)

  2. Segurança
    - Habilitar RLS na tabela `documentacao_tabelas`
    - Adicionar política para usuários autenticados lerem os dados
    - Adicionar política para usuários autenticados modificarem os dados

  3. Dados Iniciais
    - Inserir documentação das tabelas principais do sistema CRM
*/

-- Criar tabela documentacao_tabelas
CREATE TABLE IF NOT EXISTS documentacao_tabelas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nome_tabela text NOT NULL UNIQUE,
  descricao text NOT NULL,
  criado_em timestamptz DEFAULT now(),
  atualizado_em timestamptz DEFAULT now()
);

-- Habilitar RLS
ALTER TABLE documentacao_tabelas ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança
CREATE POLICY "Usuários autenticados podem ler documentação"
  ON documentacao_tabelas
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir documentação"
  ON documentacao_tabelas
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar documentação"
  ON documentacao_tabelas
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar documentação"
  ON documentacao_tabelas
  FOR DELETE
  TO authenticated
  USING (true);

-- Função para atualizar automaticamente o campo atualizado_em
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.atualizado_em = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para atualizar automaticamente o timestamp
CREATE TRIGGER update_documentacao_tabelas_updated_at
  BEFORE UPDATE ON documentacao_tabelas
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Inserir documentação das tabelas principais
INSERT INTO documentacao_tabelas (nome_tabela, descricao) VALUES
(
  'empresa_base',
  'Armazena os dados das empresas ou pessoas físicas que contratam o sistema. Permite pessoa física ou jurídica, com campos separados para nome, razão social, CPF ou CNPJ.'
),
(
  'empresa_usuario',
  'Armazena os usuários internos de cada empresa (como dono, supervisores e colaboradores), com indicação do tipo de papel.'
),
(
  'cliente_final_base',
  'Armazena os dados dos clientes finais atendidos pelas empresas contratantes. Contém informações comerciais e de contato.'
),
(
  'cliente_final_usuario',
  'Relaciona quais colaboradores (usuários) têm acesso a quais clientes finais. Útil para controle de acesso individualizado.'
),
(
  'rel_supervisor_colaborador',
  'Define os supervisores e os colaboradores sob sua supervisão, permitindo segmentação por equipe.'
);