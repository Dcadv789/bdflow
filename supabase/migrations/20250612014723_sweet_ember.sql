/*
  # Criar tabela interacao_cliente_final no schema público

  1. Nova Tabela
    - `interacao_cliente_final`
      - `id` (uuid, chave primária)
      - `cliente_final_id` (uuid, FK para clientes.cliente_final)
      - `usuario_id` (uuid, FK para core.usuario_interno)
      - `tipo_interacao` (text, obrigatório)
      - `titulo` (text, obrigatório)
      - `descricao` (text, opcional)
      - `data_interacao` (timestamp, obrigatório)
      - `criado_em` (timestamptz, default now())
      - `atualizado_em` (timestamptz, default now())

  2. Segurança
    - Habilitar RLS na tabela `interacao_cliente_final`
    - Políticas para usuários autenticados gerenciarem interações
    - Chaves estrangeiras com integridade referencial

  3. Performance
    - Índices em colunas frequentemente consultadas
    - Constraints de validação apropriadas

  4. Documentação
    - Inserir descrição na tabela core.documentacao_tabelas
*/

-- Criar tabela interacao_cliente_final no schema público
CREATE TABLE IF NOT EXISTS public.interacao_cliente_final (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cliente_final_id uuid NOT NULL REFERENCES clientes.cliente_final(id) ON DELETE CASCADE,
  usuario_id uuid NOT NULL REFERENCES core.usuario_interno(id) ON DELETE CASCADE,
  tipo_interacao text NOT NULL,
  titulo text NOT NULL,
  descricao text,
  data_interacao timestamp NOT NULL,
  criado_em timestamptz DEFAULT now(),
  atualizado_em timestamptz DEFAULT now()
);

-- Habilitar RLS
ALTER TABLE public.interacao_cliente_final ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança
CREATE POLICY "Usuários autenticados podem ler interações com clientes finais"
  ON public.interacao_cliente_final
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir interações com clientes finais"
  ON public.interacao_cliente_final
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar interações com clientes finais"
  ON public.interacao_cliente_final
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar interações com clientes finais"
  ON public.interacao_cliente_final
  FOR DELETE
  TO authenticated
  USING (true);

-- Trigger para atualizar automaticamente o timestamp
CREATE TRIGGER update_interacao_cliente_final_updated_at
  BEFORE UPDATE ON public.interacao_cliente_final
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_interacao_cliente_final_cliente_id ON public.interacao_cliente_final(cliente_final_id);
CREATE INDEX IF NOT EXISTS idx_interacao_cliente_final_usuario_id ON public.interacao_cliente_final(usuario_id);
CREATE INDEX IF NOT EXISTS idx_interacao_cliente_final_tipo_interacao ON public.interacao_cliente_final(tipo_interacao);
CREATE INDEX IF NOT EXISTS idx_interacao_cliente_final_data_interacao ON public.interacao_cliente_final(data_interacao);
CREATE INDEX IF NOT EXISTS idx_interacao_cliente_final_criado_em ON public.interacao_cliente_final(criado_em);
CREATE INDEX IF NOT EXISTS idx_interacao_cliente_final_cliente_data ON public.interacao_cliente_final(cliente_final_id, data_interacao);
CREATE INDEX IF NOT EXISTS idx_interacao_cliente_final_usuario_data ON public.interacao_cliente_final(usuario_id, data_interacao);
CREATE INDEX IF NOT EXISTS idx_interacao_cliente_final_tipo_data ON public.interacao_cliente_final(tipo_interacao, data_interacao);

-- Inserir documentação da nova tabela
INSERT INTO core.documentacao_tabelas (nome_tabela, descricao) VALUES
(
  'interacao_cliente_final',
  'SCHEMA: public - Armazena registros manuais ou automáticos de interações entre usuários internos e clientes finais. Pode conter ligações, e-mails, visitas ou outros formatos de comunicação com o cliente. Campos principais: id (identificador único), cliente_final_id (cliente relacionado), usuario_id (usuário interno que realizou a interação), tipo_interacao (formato da comunicação como ligação, e-mail, visita, whatsapp), titulo (resumo da interação), descricao (detalhes opcionais da comunicação), data_interacao (quando ocorreu a interação), criado_em/atualizado_em (timestamps de controle). Esta tabela é fundamental para manter histórico completo de relacionamento com cada cliente.'
);

-- Comentário explicativo sobre a tabela
COMMENT ON TABLE public.interacao_cliente_final IS 'Registra todas as interações entre usuários internos e clientes finais para controle de relacionamento';