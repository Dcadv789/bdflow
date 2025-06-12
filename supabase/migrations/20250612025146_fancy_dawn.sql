/*
  # Sistema Keep-Alive para manter projeto Supabase ativo

  1. Nova Tabela
    - `core.keep_alive_logs`
      - `id` (bigserial, chave primária)
      - `data_hora_execucao` (timestamptz, obrigatório)
      - `sucesso` (boolean, obrigatório)
      - `mensagem_erro` (text, opcional)
      - `criado_em` (timestamptz, default now())
      - `atualizado_em` (timestamptz, default now())

  2. Segurança
    - Habilitar RLS na tabela `keep_alive_logs`
    - Políticas para usuários autenticados gerenciarem logs
    - Índices para consultas eficientes

  3. Performance
    - Índices em colunas frequentemente consultadas
    - Otimizações para consultas por data e status

  4. Documentação
    - Inserir descrição completa na tabela core.documentacao_tabelas
*/

-- Criar tabela keep_alive_logs no schema core
CREATE TABLE IF NOT EXISTS core.keep_alive_logs (
  id bigserial PRIMARY KEY,
  data_hora_execucao timestamptz NOT NULL,
  sucesso boolean NOT NULL,
  mensagem_erro text,
  criado_em timestamptz DEFAULT now(),
  atualizado_em timestamptz DEFAULT now()
);

-- Habilitar RLS
ALTER TABLE core.keep_alive_logs ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança
CREATE POLICY "Usuários autenticados podem ler logs keep-alive"
  ON core.keep_alive_logs
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir logs keep-alive"
  ON core.keep_alive_logs
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar logs keep-alive"
  ON core.keep_alive_logs
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar logs keep-alive"
  ON core.keep_alive_logs
  FOR DELETE
  TO authenticated
  USING (true);

-- Trigger para atualizar automaticamente o timestamp
CREATE TRIGGER update_keep_alive_logs_updated_at
  BEFORE UPDATE ON core.keep_alive_logs
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_keep_alive_logs_data_hora_execucao ON core.keep_alive_logs(data_hora_execucao);
CREATE INDEX IF NOT EXISTS idx_keep_alive_logs_sucesso ON core.keep_alive_logs(sucesso);
CREATE INDEX IF NOT EXISTS idx_keep_alive_logs_criado_em ON core.keep_alive_logs(criado_em);
CREATE INDEX IF NOT EXISTS idx_keep_alive_logs_data_sucesso ON core.keep_alive_logs(data_hora_execucao, sucesso);
CREATE INDEX IF NOT EXISTS idx_keep_alive_logs_criado_sucesso ON core.keep_alive_logs(criado_em, sucesso);

-- Índice para consultas de logs recentes
CREATE INDEX IF NOT EXISTS idx_keep_alive_logs_recentes ON core.keep_alive_logs(data_hora_execucao DESC);

-- Inserir documentação da nova tabela
INSERT INTO core.documentacao_tabelas (nome_tabela, descricao) VALUES
(
  'keep_alive_logs',
  'SCHEMA: core - Tabela de logs para o sistema keep-alive automatizado que mantém o projeto Supabase ativo executando consultas simples a cada 2 dias às 20h (horário de São Paulo). Registra cada execução da rotina de keep-alive para monitoramento e auditoria. Campos principais: id (identificador único bigserial), data_hora_execucao (timestamp da execução da consulta keep-alive), sucesso (booleano indicando se a consulta foi executada com sucesso), mensagem_erro (texto da mensagem de erro caso a execução falhe, pode ser NULL), criado_em (timestamp de criação do registro), atualizado_em (timestamp da última atualização). Esta tabela é essencial para garantir que o projeto não seja suspenso por inatividade, já que o Supabase suspende projetos sem consultas por 7 dias. Os logs permitem monitorar a saúde do sistema automatizado e identificar possíveis falhas na execução.'
);

-- Função para executar keep-alive e registrar log
CREATE OR REPLACE FUNCTION core.execute_keep_alive()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  resultado json;
  erro_msg text;
  execucao_sucesso boolean := true;
  data_execucao timestamptz := now();
BEGIN
  BEGIN
    -- Executar consulta simples para manter projeto ativo
    PERFORM 1;
    
    -- Se chegou até aqui, a execução foi bem-sucedida
    resultado := json_build_object(
      'status', 'success',
      'message', 'Keep-alive executado com sucesso',
      'timestamp', data_execucao
    );
    
  EXCEPTION WHEN OTHERS THEN
    -- Capturar qualquer erro
    execucao_sucesso := false;
    erro_msg := SQLERRM;
    
    resultado := json_build_object(
      'status', 'error',
      'message', 'Erro na execução do keep-alive',
      'error', erro_msg,
      'timestamp', data_execucao
    );
  END;
  
  -- Registrar log da execução
  INSERT INTO core.keep_alive_logs (
    data_hora_execucao,
    sucesso,
    mensagem_erro
  ) VALUES (
    data_execucao,
    execucao_sucesso,
    CASE WHEN execucao_sucesso THEN NULL ELSE erro_msg END
  );
  
  RETURN resultado;
END;
$$;

-- Comentários explicativos sobre a tabela e função
COMMENT ON TABLE core.keep_alive_logs IS 'Logs do sistema automatizado de keep-alive para manter projeto Supabase ativo';
COMMENT ON COLUMN core.keep_alive_logs.id IS 'Identificador único sequencial do log';
COMMENT ON COLUMN core.keep_alive_logs.data_hora_execucao IS 'Data e hora exata da execução da consulta keep-alive';
COMMENT ON COLUMN core.keep_alive_logs.sucesso IS 'Indica se a consulta keep-alive foi executada com sucesso';
COMMENT ON COLUMN core.keep_alive_logs.mensagem_erro IS 'Mensagem de erro caso a execução tenha falhado (NULL se sucesso)';
COMMENT ON COLUMN core.keep_alive_logs.criado_em IS 'Timestamp de criação do registro de log';
COMMENT ON COLUMN core.keep_alive_logs.atualizado_em IS 'Timestamp da última atualização do registro';

COMMENT ON FUNCTION core.execute_keep_alive() IS 'Função que executa keep-alive e registra log automaticamente';