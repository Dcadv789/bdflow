/*
  # Criar tabela empresa_usuario

  1. New Tables
    - `empresa_usuario`
      - `id` (uuid, primary key)
      - `empresa_id` (uuid, foreign key para empresa_base)
      - `nome_completo` (text, obrigatório)
      - `nome_exibicao` (text, obrigatório)
      - `email` (text, obrigatório e único)
      - `email_corporativo` (text, opcional)
      - `telefone` (text, opcional)
      - `papel` (enum: owner, supervisor, colaborador)
      - `status` (enum: ativo, inativo, suspenso)
      - `avatar_url` (text, opcional)
      - `ultimo_login` (timestamptz, opcional)
      - `observacoes` (text, opcional)
      - `criado_em` (timestamptz, default now())
      - `atualizado_em` (timestamptz, default now())

  2. Security
    - Enable RLS on `empresa_usuario` table
    - Add policies for authenticated users to manage user data
    - Foreign key constraint to empresa_base

  3. Performance
    - Indexes on frequently queried columns (empresa_id, email, papel, status)

  4. Documentation
    - Update description in documentacao_tabelas
*/

-- Criar enums para papel e status do usuário
CREATE TYPE papel_usuario AS ENUM ('owner', 'supervisor', 'colaborador');
CREATE TYPE status_usuario AS ENUM ('ativo', 'inativo', 'suspenso');

-- Criar tabela empresa_usuario
CREATE TABLE IF NOT EXISTS empresa_usuario (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid NOT NULL REFERENCES empresa_base(id) ON DELETE CASCADE,
  nome_completo text NOT NULL,
  nome_exibicao text NOT NULL,
  email text NOT NULL UNIQUE,
  email_corporativo text,
  telefone text,
  papel papel_usuario NOT NULL DEFAULT 'colaborador',
  status status_usuario NOT NULL DEFAULT 'ativo',
  avatar_url text,
  ultimo_login timestamptz,
  observacoes text,
  criado_em timestamptz DEFAULT now(),
  atualizado_em timestamptz DEFAULT now()
);

-- Habilitar RLS
ALTER TABLE empresa_usuario ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança
CREATE POLICY "Usuários autenticados podem ler usuários da empresa"
  ON empresa_usuario
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir usuários da empresa"
  ON empresa_usuario
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar usuários da empresa"
  ON empresa_usuario
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar usuários da empresa"
  ON empresa_usuario
  FOR DELETE
  TO authenticated
  USING (true);

-- Trigger para atualizar automaticamente o timestamp
CREATE TRIGGER update_empresa_usuario_updated_at
  BEFORE UPDATE ON empresa_usuario
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_empresa_usuario_empresa_id ON empresa_usuario(empresa_id);
CREATE INDEX IF NOT EXISTS idx_empresa_usuario_email ON empresa_usuario(email);
CREATE INDEX IF NOT EXISTS idx_empresa_usuario_papel ON empresa_usuario(papel);
CREATE INDEX IF NOT EXISTS idx_empresa_usuario_status ON empresa_usuario(status);
CREATE INDEX IF NOT EXISTS idx_empresa_usuario_ultimo_login ON empresa_usuario(ultimo_login) WHERE ultimo_login IS NOT NULL;

-- Constraint para garantir que cada empresa tenha pelo menos um owner
-- (Esta constraint será implementada via trigger para permitir flexibilidade)

-- Atualizar a descrição na tabela documentacao_tabelas
UPDATE documentacao_tabelas 
SET 
  descricao = 'Armazena os dados dos usuários vinculados a uma empresa que contratou o sistema. Cada usuário pode ter um papel específico (owner, supervisor ou colaborador) e terá permissões conforme seu nível. Esta tabela serve como o principal ponto de controle de acesso por empresa. Os dados aqui representam os usuários do meu cliente (quem comprou o software) e não os usuários finais da plataforma.',
  atualizado_em = now()
WHERE nome_tabela = 'empresa_usuario';