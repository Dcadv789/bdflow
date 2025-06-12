/*
  # Criar tabela cliente_final

  1. Nova Tabela
    - `cliente_final`
      - `id` (uuid, chave primária)
      - `empresa_id` (uuid, FK para empresa_base.id)
      - `plano_id` (uuid, FK para planos.id, opcional)
      - `nome` (text, obrigatório)
      - `razao_social` (text, opcional)
      - `cpf` (text, opcional)
      - `cnpj` (text, opcional)
      - `tipo_pessoa` (enum: fisica, juridica)
      - `email` (text, opcional)
      - `telefone` (text, opcional)
      - `status` (enum: em_implantacao, implantado, suspenso, cancelado)
      - `ativo` (boolean, default true)
      - `observacoes` (text, opcional)
      - `criado_em` (timestamptz, default now())
      - `atualizado_em` (timestamptz, default now())

  2. Segurança
    - Habilitar RLS na tabela `cliente_final`
    - Políticas para usuários autenticados gerenciarem clientes finais
    - Chaves estrangeiras com integridade referencial

  3. Performance
    - Índices em colunas frequentemente consultadas
    - Constraints para garantir consistência de dados

  4. Documentação
    - Inserir descrição na tabela documentacao_tabelas
*/

-- Criar enums para tipo de pessoa e status do cliente final
CREATE TYPE tipo_pessoa_cliente AS ENUM ('fisica', 'juridica');
CREATE TYPE status_cliente_final AS ENUM ('em_implantacao', 'implantado', 'suspenso', 'cancelado');

-- Criar tabela cliente_final
CREATE TABLE IF NOT EXISTS cliente_final (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid NOT NULL REFERENCES empresa_base(id) ON DELETE CASCADE,
  plano_id uuid REFERENCES planos(id) ON DELETE SET NULL,
  nome text NOT NULL,
  razao_social text,
  cpf text,
  cnpj text,
  tipo_pessoa tipo_pessoa_cliente NOT NULL,
  email text,
  telefone text,
  status status_cliente_final DEFAULT 'em_implantacao',
  ativo boolean DEFAULT true,
  observacoes text,
  criado_em timestamptz DEFAULT now(),
  atualizado_em timestamptz DEFAULT now(),
  
  -- Constraints para garantir dados consistentes
  CONSTRAINT check_pessoa_juridica_dados 
    CHECK (
      (tipo_pessoa = 'fisica' AND cpf IS NOT NULL AND cnpj IS NULL) OR
      (tipo_pessoa = 'juridica' AND cnpj IS NOT NULL AND cpf IS NULL)
    ),
  CONSTRAINT check_pessoa_juridica_razao_social 
    CHECK (tipo_pessoa = 'fisica' OR (tipo_pessoa = 'juridica' AND razao_social IS NOT NULL))
);

-- Habilitar RLS
ALTER TABLE cliente_final ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança
CREATE POLICY "Usuários autenticados podem ler clientes finais"
  ON cliente_final
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir clientes finais"
  ON cliente_final
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar clientes finais"
  ON cliente_final
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar clientes finais"
  ON cliente_final
  FOR DELETE
  TO authenticated
  USING (true);

-- Trigger para atualizar automaticamente o timestamp
CREATE TRIGGER update_cliente_final_updated_at
  BEFORE UPDATE ON cliente_final
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_cliente_final_empresa_id ON cliente_final(empresa_id);
CREATE INDEX IF NOT EXISTS idx_cliente_final_plano_id ON cliente_final(plano_id) WHERE plano_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_cliente_final_tipo_pessoa ON cliente_final(tipo_pessoa);
CREATE INDEX IF NOT EXISTS idx_cliente_final_status ON cliente_final(status);
CREATE INDEX IF NOT EXISTS idx_cliente_final_ativo ON cliente_final(ativo);
CREATE INDEX IF NOT EXISTS idx_cliente_final_cpf ON cliente_final(cpf) WHERE cpf IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_cliente_final_cnpj ON cliente_final(cnpj) WHERE cnpj IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_cliente_final_email ON cliente_final(email) WHERE email IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_cliente_final_nome ON cliente_final(nome);

-- Agora podemos adicionar as chaves estrangeiras que estavam pendentes nas tabelas de relacionamento
-- Adicionar FK para cliente_final nas tabelas cliente_supervisor e cliente_colaborador
DO $$
BEGIN
  -- Adicionar FK na tabela cliente_supervisor
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'cliente_supervisor_id_cliente_final_fkey'
  ) THEN
    ALTER TABLE cliente_supervisor 
    ADD CONSTRAINT cliente_supervisor_id_cliente_final_fkey 
    FOREIGN KEY (id_cliente_final) REFERENCES cliente_final(id) ON DELETE CASCADE;
  END IF;

  -- Adicionar FK na tabela cliente_colaborador
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'cliente_colaborador_id_cliente_final_fkey'
  ) THEN
    ALTER TABLE cliente_colaborador 
    ADD CONSTRAINT cliente_colaborador_id_cliente_final_fkey 
    FOREIGN KEY (id_cliente_final) REFERENCES cliente_final(id) ON DELETE CASCADE;
  END IF;
END $$;

-- Inserir documentação da nova tabela
INSERT INTO documentacao_tabelas (nome_tabela, descricao) VALUES
(
  'cliente_final',
  'Tabela que armazena os clientes finais de cada empresa. Pode representar tanto pessoas físicas quanto jurídicas, sendo indicado pelo campo tipo_pessoa. Os campos cpf e cnpj são opcionais e usados conforme o tipo. O campo plano_id define o plano contratado, mas pode ser preenchido depois. A coluna status serve para acompanhar o estágio de implantação do cliente (em implantação, suspenso, etc.), enquanto a coluna ativo indica se o cliente está ativo ou não no sistema. Também há campos para observações e dados de contato.'
);