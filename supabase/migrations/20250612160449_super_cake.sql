/*
  # Criar tabela template_plano no schema templates

  1. Nova Tabela
    - `templates.template_plano`
      - `id` (uuid, chave primária)
      - `template_base_id` (uuid, FK para templates.template_base)
      - `plano_id` (uuid, FK para planos.planos)
      - `criado_em` (timestamptz, default now())

  2. Segurança
    - Habilitar RLS na tabela `template_plano`
    - Políticas para usuários autenticados gerenciarem associações
    - Chaves estrangeiras com integridade referencial

  3. Performance
    - Índices em colunas frequentemente consultadas
    - Constraint única para evitar duplicação de associações

  4. Documentação
    - Inserir descrição detalhada na tabela core.documentacao_tabelas
*/

-- Criar tabela template_plano no schema templates
CREATE TABLE IF NOT EXISTS templates.template_plano (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  template_base_id uuid NOT NULL REFERENCES templates.template_base(id) ON DELETE CASCADE,
  plano_id uuid NOT NULL REFERENCES planos.planos(id) ON DELETE CASCADE,
  criado_em timestamptz DEFAULT now(),
  
  -- Constraint para evitar duplicação da mesma associação template-plano
  UNIQUE(template_base_id, plano_id)
);

-- Habilitar RLS
ALTER TABLE templates.template_plano ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança
CREATE POLICY "Usuários autenticados podem ler associações template-plano"
  ON templates.template_plano
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir associações template-plano"
  ON templates.template_plano
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar associações template-plano"
  ON templates.template_plano
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar associações template-plano"
  ON templates.template_plano
  FOR DELETE
  TO authenticated
  USING (true);

-- Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_template_plano_template_base_id ON templates.template_plano(template_base_id);
CREATE INDEX IF NOT EXISTS idx_template_plano_plano_id ON templates.template_plano(plano_id);
CREATE INDEX IF NOT EXISTS idx_template_plano_criado_em ON templates.template_plano(criado_em);
CREATE INDEX IF NOT EXISTS idx_template_plano_template_criado ON templates.template_plano(template_base_id, criado_em);
CREATE INDEX IF NOT EXISTS idx_template_plano_plano_criado ON templates.template_plano(plano_id, criado_em);

-- Inserir documentação da nova tabela na tabela core.documentacao_tabelas
INSERT INTO core.documentacao_tabelas (nome_tabela, descricao) VALUES
(
  'template_plano',
  'SCHEMA: templates - Tabela de associação que vincula templates de fluxo de trabalho aos planos comerciais disponíveis no sistema. Esta relação permite definir quais templates estão disponíveis para cada plano contratado, criando uma estrutura de permissões baseada no nível de serviço. Quando uma empresa contrata um plano específico, ela terá acesso apenas aos templates associados a esse plano, permitindo diferenciação de funcionalidades por nível de assinatura. Campos principais: id (identificador único UUID), template_base_id (referência ao template de fluxo de trabalho), plano_id (referência ao plano comercial), criado_em (timestamp de criação da associação). A constraint única evita duplicação da mesma associação template-plano. Esta estrutura é fundamental para o modelo de negócio, permitindo oferecer diferentes conjuntos de templates conforme o plano contratado pelo cliente, desde templates básicos em planos iniciais até fluxos complexos em planos premium.'
);

-- Comentários explicativos sobre a tabela
COMMENT ON TABLE templates.template_plano IS 'Associa templates de fluxo de trabalho aos planos comerciais para controle de acesso por nível de assinatura';
COMMENT ON COLUMN templates.template_plano.id IS 'Identificador único da associação template-plano';
COMMENT ON COLUMN templates.template_plano.template_base_id IS 'Referência ao template de fluxo de trabalho';
COMMENT ON COLUMN templates.template_plano.plano_id IS 'Referência ao plano comercial';
COMMENT ON COLUMN templates.template_plano.criado_em IS 'Data e hora em que a associação foi criada';