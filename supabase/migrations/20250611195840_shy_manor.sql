/*
  # Criar tabelas de usuários internos e controle de acesso

  1. Novas Tabelas
    - `usuario_interno`
      - `id` (uuid, chave primária)
      - `nome_completo` (text, obrigatório)
      - `nome_exibicao` (text, obrigatório)
      - `email` (text, obrigatório e único)
      - `telefone` (text, opcional)
      - `papel` (enum: admin, suporte, dev)
      - `status` (enum: ativo, inativo, suspenso)
      - `avatar_url` (text, opcional)
      - `ultimo_login` (timestamptz, opcional)
      - `observacoes` (text, opcional)
      - `criado_em` (timestamptz, default now())
      - `atualizado_em` (timestamptz, default now())

    - `empresa_acesso_interno`
      - `id` (uuid, chave primária)
      - `usuario_interno_id` (uuid, foreign key para usuario_interno)
      - `empresa_id` (uuid, foreign key para empresa_base)
      - `criado_em` (timestamptz, default now())
      - `atualizado_em` (timestamptz, default now())

  2. Segurança
    - Habilitar RLS em ambas as tabelas
    - Políticas para usuários autenticados gerenciarem dados internos
    - Constraints de integridade referencial

  3. Performance
    - Índices em colunas frequentemente consultadas
    - Constraint única para evitar duplicação de acesso

  4. Documentação
    - Inserir descrições das novas tabelas na documentacao_tabelas
*/

-- Criar enums para papel e status do usuário interno
CREATE TYPE papel_usuario_interno AS ENUM ('admin', 'suporte', 'dev');
CREATE TYPE status_usuario_interno AS ENUM ('ativo', 'inativo', 'suspenso');

-- Criar tabela usuario_interno
CREATE TABLE IF NOT EXISTS usuario_interno (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nome_completo text NOT NULL,
  nome_exibicao text NOT NULL,
  email text NOT NULL UNIQUE,
  telefone text,
  papel papel_usuario_interno NOT NULL DEFAULT 'suporte',
  status status_usuario_interno NOT NULL DEFAULT 'ativo',
  avatar_url text,
  ultimo_login timestamptz,
  observacoes text,
  criado_em timestamptz DEFAULT now(),
  atualizado_em timestamptz DEFAULT now()
);

-- Criar tabela empresa_acesso_interno
CREATE TABLE IF NOT EXISTS empresa_acesso_interno (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_interno_id uuid NOT NULL REFERENCES usuario_interno(id) ON DELETE CASCADE,
  empresa_id uuid NOT NULL REFERENCES empresa_base(id) ON DELETE CASCADE,
  criado_em timestamptz DEFAULT now(),
  atualizado_em timestamptz DEFAULT now(),
  
  -- Constraint para evitar duplicação de acesso
  UNIQUE(usuario_interno_id, empresa_id)
);

-- Habilitar RLS nas tabelas
ALTER TABLE usuario_interno ENABLE ROW LEVEL SECURITY;
ALTER TABLE empresa_acesso_interno ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança para usuario_interno
CREATE POLICY "Usuários autenticados podem ler usuários internos"
  ON usuario_interno
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir usuários internos"
  ON usuario_interno
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar usuários internos"
  ON usuario_interno
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar usuários internos"
  ON usuario_interno
  FOR DELETE
  TO authenticated
  USING (true);

-- Políticas de segurança para empresa_acesso_interno
CREATE POLICY "Usuários autenticados podem ler acessos internos"
  ON empresa_acesso_interno
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir acessos internos"
  ON empresa_acesso_interno
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar acessos internos"
  ON empresa_acesso_interno
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar acessos internos"
  ON empresa_acesso_interno
  FOR DELETE
  TO authenticated
  USING (true);

-- Triggers para atualizar automaticamente os timestamps
CREATE TRIGGER update_usuario_interno_updated_at
  BEFORE UPDATE ON usuario_interno
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_empresa_acesso_interno_updated_at
  BEFORE UPDATE ON empresa_acesso_interno
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_usuario_interno_email ON usuario_interno(email);
CREATE INDEX IF NOT EXISTS idx_usuario_interno_papel ON usuario_interno(papel);
CREATE INDEX IF NOT EXISTS idx_usuario_interno_status ON usuario_interno(status);
CREATE INDEX IF NOT EXISTS idx_usuario_interno_ultimo_login ON usuario_interno(ultimo_login) WHERE ultimo_login IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_empresa_acesso_interno_usuario_id ON empresa_acesso_interno(usuario_interno_id);
CREATE INDEX IF NOT EXISTS idx_empresa_acesso_interno_empresa_id ON empresa_acesso_interno(empresa_id);

-- Inserir documentação das novas tabelas
INSERT INTO documentacao_tabelas (nome_tabela, descricao) VALUES
(
  'usuario_interno',
  'Representa os usuários internos da plataforma, como administradores, desenvolvedores ou membros do time de suporte. Estes usuários podem ter acesso irrestrito a todas as empresas, clientes e projetos, ou podem ter acesso restrito a empresas específicas conforme definido na tabela empresa_acesso_interno. Se um usuário interno não possuir registros na tabela empresa_acesso_interno, ele terá acesso total ao sistema.'
),
(
  'empresa_acesso_interno',
  'Relação entre usuários internos e empresas específicas para controlar o acesso restrito de colaboradores internos às empresas que eles podem visualizar e gerenciar. Quando um usuário interno possui registros nesta tabela, seu acesso fica limitado apenas às empresas vinculadas. Se não houver registros para um usuário interno, ele terá acesso irrestrito a todas as empresas do sistema.'
);