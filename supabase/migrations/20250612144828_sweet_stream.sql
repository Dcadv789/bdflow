/*
  # Criar sistema de auditoria no schema public

  1. Nova Tabela
    - `public.auditoria`
      - `id` (uuid, chave primária)
      - `empresa_id` (uuid, FK para core.empresa_base)
      - `usuario_id` (uuid, FK para core.empresa_usuario)
      - `acao` (text, obrigatório)
      - `entidade` (text, obrigatório)
      - `entidade_id` (uuid, opcional)
      - `valores_anteriores` (jsonb, opcional)
      - `valores_novos` (jsonb, opcional)
      - `criado_em` (timestamptz, default now())

  2. Função Genérica
    - `public.log_auditoria_padrao()` - função de trigger para auditoria automática

  3. Triggers Automáticos
    - Aplicados nas tabelas do schema tarefas para auditoria completa

  4. Segurança
    - Habilitar RLS na tabela auditoria
    - Políticas para usuários autenticados
    - Índices otimizados para performance

  5. Documentação
    - Atualizar tabela core.documentacao_tabelas
*/

-- Criar tabela auditoria no schema public
CREATE TABLE IF NOT EXISTS public.auditoria (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id uuid REFERENCES core.empresa_base(id) ON DELETE SET NULL,
  usuario_id uuid REFERENCES core.empresa_usuario(id) ON DELETE SET NULL,
  acao text NOT NULL,
  entidade text NOT NULL,
  entidade_id uuid,
  valores_anteriores jsonb,
  valores_novos jsonb,
  criado_em timestamptz DEFAULT now()
);

-- Habilitar RLS
ALTER TABLE public.auditoria ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança
CREATE POLICY "Usuários autenticados podem ler logs de auditoria"
  ON public.auditoria
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usuários autenticados podem inserir logs de auditoria"
  ON public.auditoria
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem atualizar logs de auditoria"
  ON public.auditoria
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Usuários autenticados podem deletar logs de auditoria"
  ON public.auditoria
  FOR DELETE
  TO authenticated
  USING (true);

-- Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_auditoria_empresa_id ON public.auditoria(empresa_id) WHERE empresa_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_auditoria_usuario_id ON public.auditoria(usuario_id) WHERE usuario_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_auditoria_acao ON public.auditoria(acao);
CREATE INDEX IF NOT EXISTS idx_auditoria_entidade ON public.auditoria(entidade);
CREATE INDEX IF NOT EXISTS idx_auditoria_entidade_id ON public.auditoria(entidade_id) WHERE entidade_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_auditoria_criado_em ON public.auditoria(criado_em);
CREATE INDEX IF NOT EXISTS idx_auditoria_empresa_criado ON public.auditoria(empresa_id, criado_em) WHERE empresa_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_auditoria_usuario_criado ON public.auditoria(usuario_id, criado_em) WHERE usuario_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_auditoria_entidade_criado ON public.auditoria(entidade, criado_em);
CREATE INDEX IF NOT EXISTS idx_auditoria_acao_criado ON public.auditoria(acao, criado_em);
CREATE INDEX IF NOT EXISTS idx_auditoria_entidade_entidade_id ON public.auditoria(entidade, entidade_id) WHERE entidade_id IS NOT NULL;

-- Índices para consultas em JSONB
CREATE INDEX IF NOT EXISTS idx_auditoria_valores_anteriores ON public.auditoria USING GIN(valores_anteriores) WHERE valores_anteriores IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_auditoria_valores_novos ON public.auditoria USING GIN(valores_novos) WHERE valores_novos IS NOT NULL;

-- Função genérica para log de auditoria no schema public
CREATE OR REPLACE FUNCTION public.log_auditoria_padrao()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  acao_executada text;
  empresa_id_valor uuid;
  usuario_id_valor uuid;
  entidade_nome text;
  entidade_id_valor uuid;
  valores_antigos jsonb;
  valores_novos jsonb;
BEGIN
  -- Determinar o tipo de operação
  CASE TG_OP
    WHEN 'INSERT' THEN
      acao_executada := 'inseriu';
      valores_antigos := NULL;
      valores_novos := to_jsonb(NEW);
      entidade_id_valor := (NEW.id)::uuid;
      
      -- Tentar extrair empresa_id e usuario_id do NEW
      IF NEW ? 'empresa_id' THEN
        empresa_id_valor := (NEW.empresa_id)::uuid;
      END IF;
      
      IF NEW ? 'usuario_responsavel_id' THEN
        usuario_id_valor := (NEW.usuario_responsavel_id)::uuid;
      ELSIF NEW ? 'usuario_id' THEN
        usuario_id_valor := (NEW.usuario_id)::uuid;
      ELSIF NEW ? 'criado_por_id' THEN
        usuario_id_valor := (NEW.criado_por_id)::uuid;
      END IF;
      
    WHEN 'UPDATE' THEN
      acao_executada := 'atualizou';
      valores_antigos := to_jsonb(OLD);
      valores_novos := to_jsonb(NEW);
      entidade_id_valor := (NEW.id)::uuid;
      
      -- Tentar extrair empresa_id e usuario_id do NEW
      IF NEW ? 'empresa_id' THEN
        empresa_id_valor := (NEW.empresa_id)::uuid;
      END IF;
      
      IF NEW ? 'usuario_responsavel_id' THEN
        usuario_id_valor := (NEW.usuario_responsavel_id)::uuid;
      ELSIF NEW ? 'usuario_id' THEN
        usuario_id_valor := (NEW.usuario_id)::uuid;
      ELSIF NEW ? 'criado_por_id' THEN
        usuario_id_valor := (NEW.criado_por_id)::uuid;
      END IF;
      
    WHEN 'DELETE' THEN
      acao_executada := 'excluiu';
      valores_antigos := to_jsonb(OLD);
      valores_novos := NULL;
      entidade_id_valor := (OLD.id)::uuid;
      
      -- Tentar extrair empresa_id e usuario_id do OLD
      IF OLD ? 'empresa_id' THEN
        empresa_id_valor := (OLD.empresa_id)::uuid;
      END IF;
      
      IF OLD ? 'usuario_responsavel_id' THEN
        usuario_id_valor := (OLD.usuario_responsavel_id)::uuid;
      ELSIF OLD ? 'usuario_id' THEN
        usuario_id_valor := (OLD.usuario_id)::uuid;
      ELSIF OLD ? 'criado_por_id' THEN
        usuario_id_valor := (OLD.criado_por_id)::uuid;
      END IF;
  END CASE;
  
  -- Construir nome da entidade (schema.tabela)
  entidade_nome := TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME;
  
  -- Inserir registro de auditoria
  INSERT INTO public.auditoria (
    empresa_id,
    usuario_id,
    acao,
    entidade,
    entidade_id,
    valores_anteriores,
    valores_novos
  ) VALUES (
    empresa_id_valor,
    usuario_id_valor,
    acao_executada,
    entidade_nome,
    entidade_id_valor,
    valores_antigos,
    valores_novos
  );
  
  -- Retornar o registro apropriado
  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  ELSE
    RETURN NEW;
  END IF;
  
EXCEPTION WHEN OTHERS THEN
  -- Em caso de erro, não interromper a operação principal
  -- Apenas registrar o erro em um log (se necessário)
  RAISE WARNING 'Erro ao registrar auditoria: %', SQLERRM;
  
  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  ELSE
    RETURN NEW;
  END IF;
END;
$$;

-- Criar triggers nas tabelas do schema tarefas

-- Trigger para tarefas.tarefa
DROP TRIGGER IF EXISTS trigger_auditoria_tarefa ON tarefas.tarefa;
CREATE TRIGGER trigger_auditoria_tarefa
  AFTER INSERT OR UPDATE OR DELETE ON tarefas.tarefa
  FOR EACH ROW
  EXECUTE FUNCTION public.log_auditoria_padrao();

-- Trigger para tarefas.tarefa_comentario
DROP TRIGGER IF EXISTS trigger_auditoria_tarefa_comentario ON tarefas.tarefa_comentario;
CREATE TRIGGER trigger_auditoria_tarefa_comentario
  AFTER INSERT OR UPDATE OR DELETE ON tarefas.tarefa_comentario
  FOR EACH ROW
  EXECUTE FUNCTION public.log_auditoria_padrao();

-- Trigger para tarefas.tarefa_notificacao
DROP TRIGGER IF EXISTS trigger_auditoria_tarefa_notificacao ON tarefas.tarefa_notificacao;
CREATE TRIGGER trigger_auditoria_tarefa_notificacao
  AFTER INSERT OR UPDATE OR DELETE ON tarefas.tarefa_notificacao
  FOR EACH ROW
  EXECUTE FUNCTION public.log_auditoria_padrao();

-- Trigger para tarefas.tarefa_checklist
DROP TRIGGER IF EXISTS trigger_auditoria_tarefa_checklist ON tarefas.tarefa_checklist;
CREATE TRIGGER trigger_auditoria_tarefa_checklist
  AFTER INSERT OR UPDATE OR DELETE ON tarefas.tarefa_checklist
  FOR EACH ROW
  EXECUTE FUNCTION public.log_auditoria_padrao();

-- Inserir documentação das novas funcionalidades na tabela core.documentacao_tabelas
INSERT INTO core.documentacao_tabelas (nome_tabela, descricao) VALUES
(
  'auditoria',
  'SCHEMA: public - Tabela principal do sistema de auditoria que registra automaticamente todas as ações realizadas pelos usuários nas tabelas críticas do sistema. Cada registro captura informações completas sobre a operação: quem fez, quando, o que foi alterado e os valores antes/depois da mudança. Campos principais: id (identificador único UUID), empresa_id (empresa relacionada à ação), usuario_id (usuário que executou a ação), acao (tipo de operação: inseriu, atualizou, excluiu), entidade (nome da tabela afetada no formato schema.tabela), entidade_id (ID do registro afetado), valores_anteriores (dados antes da alteração em JSONB), valores_novos (dados após a alteração em JSONB), criado_em (timestamp da ação). Os triggers automáticos nas tabelas do schema tarefas garantem que todas as operações sejam registradas sem intervenção manual. Sistema fundamental para compliance, auditoria e rastreabilidade completa das operações.'
),
(
  'log_auditoria_padrao_function',
  'SCHEMA: public - Função genérica de trigger que registra automaticamente alterações em qualquer tabela do sistema. Identifica o tipo de operação (INSERT, UPDATE, DELETE), extrai informações relevantes como empresa_id e usuario_id dos registros, e insere um log completo na tabela public.auditoria. A função é robusta e trata erros sem interromper as operações principais. Configurada como SECURITY DEFINER para garantir permissões adequadas. Utilizada pelos triggers automáticos nas tabelas críticas do sistema para auditoria transparente e completa.'
);

-- Comentários explicativos sobre o sistema de auditoria
COMMENT ON TABLE public.auditoria IS 'Tabela principal de auditoria que registra todas as ações dos usuários automaticamente';
COMMENT ON COLUMN public.auditoria.id IS 'Identificador único do registro de auditoria';
COMMENT ON COLUMN public.auditoria.empresa_id IS 'Empresa relacionada à ação auditada (extraída automaticamente)';
COMMENT ON COLUMN public.auditoria.usuario_id IS 'Usuário que executou a ação (extraído automaticamente)';
COMMENT ON COLUMN public.auditoria.acao IS 'Tipo de operação realizada: inseriu, atualizou ou excluiu';
COMMENT ON COLUMN public.auditoria.entidade IS 'Nome da tabela afetada no formato schema.tabela';
COMMENT ON COLUMN public.auditoria.entidade_id IS 'ID do registro específico que foi afetado';
COMMENT ON COLUMN public.auditoria.valores_anteriores IS 'Dados completos antes da alteração (NULL para INSERT)';
COMMENT ON COLUMN public.auditoria.valores_novos IS 'Dados completos após a alteração (NULL para DELETE)';
COMMENT ON COLUMN public.auditoria.criado_em IS 'Timestamp exato de quando a ação foi executada';

COMMENT ON FUNCTION public.log_auditoria_padrao() IS 'Função genérica de trigger para auditoria automática de alterações em tabelas';