/*
  # Criação da tabela empresa_base

  1. Nova Tabela
    - `empresa_base`
      - `id` (uuid, chave primária)
      - `tipo_pessoa` (texto - "fisica" ou "juridica")
      - `razao_social` (texto, obrigatório para pessoa jurídica)
      - `nome` (texto - nome do responsável ou pessoa física)
      - `cnpj` (texto)
      - `cpf` (texto)
      - `email` (texto)
      - `telefone` (texto)
      - `plano_contratado` (texto)
      - `data_inicio_contrato` (data)
      - `status` (enum - ativo, inativo, em_implantacao, suspenso)
      - `observacoes` (texto livre)
      - `criado_em` (timestamp)
      - `atualizado_em` (timestamp)

  2. Segurança
    - Habilitar RLS na tabela `empresa_base`
    - Políticas para usuários autenticados

  3. Atualizações
    - Atualizar descrição na tabela `documentacao_tabelas`
*/

-- Criar enum para status
CREATE TYPE status_empresa AS ENUM ('ativo', 'inativo', 'em_implantacao', 'suspenso');

-- Criar tabela empresa_base
CREATE TABLE IF NOT EXISTS empresa_base (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tipo_pessoa text NOT NULL CHECK (tipo_pessoa IN ('fisica', 'juridica')),
  razao_social text,
  nome text NOT NULL,
  cnpj text,
  cpf text,
  email text,
  telefone text,
  plano_contratado text,
  data_inicio_contrato date,
  status status_empresa DEFAULT 'em_implantacao',
  observacoes text,
  criado_em timestamptz DEFAULT now(),
  atualizado_em timestamptz DEFAULT now(),
  
  -- Constraints para garantir dados consistentes
  CONSTRAINT check_pessoa_juridica_razao_social 
    CHECK (tipo_pessoa = 'fisica' OR (tipo_pessoa = 'juridica' AND razao_social IS NOT NULL)),
  CONSTRAINT check_cnpj_ou_cpf 
    CHECK ((tipo_pessoa = 'juridica' AND cnpj IS NOT NULL) OR (tipo_pessoa = 'fisica' AND cpf IS NOT NULL))
);

-- Habilitar RLS
ALTER TABLE empresa_base ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança
CREATE POLICY "Usuários autenticados podem ler empresas"
  ON empresa_base
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir empresas"
  ON empresa_base
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar empresas"
  ON empresa_base
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar empresas"
  ON empresa_base
  FOR DELETE
  TO authenticated
  USING (true);

-- Trigger para atualizar automaticamente o timestamp
CREATE TRIGGER update_empresa_base_updated_at
  BEFORE UPDATE ON empresa_base
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_empresa_base_tipo_pessoa ON empresa_base(tipo_pessoa);
CREATE INDEX IF NOT EXISTS idx_empresa_base_status ON empresa_base(status);
CREATE INDEX IF NOT EXISTS idx_empresa_base_cnpj ON empresa_base(cnpj) WHERE cnpj IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_empresa_base_cpf ON empresa_base(cpf) WHERE cpf IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_empresa_base_email ON empresa_base(email) WHERE email IS NOT NULL;

-- Atualizar a descrição na tabela documentacao_tabelas
UPDATE documentacao_tabelas 
SET 
  descricao = 'Armazena os dados dos clientes da plataforma (empresas ou pessoas físicas). Cada registro corresponde a quem comprou e usa o sistema. O campo status ajuda a identificar a fase do relacionamento, e observacoes serve para anotações internas da equipe de suporte ou vendas.',
  atualizado_em = now()
WHERE nome_tabela = 'empresa_base';