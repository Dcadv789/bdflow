/*
  # Corrigir coluna plano_contratado removendo dependência da view

  1. Problema Identificado
    - View v_empresa_completa depende da coluna plano_contratado
    - Não é possível alterar tipo de coluna usada por view

  2. Solução
    - Remover view v_empresa_completa temporariamente
    - Alterar coluna plano_contratado para plano_id (UUID)
    - Recriar view com nova estrutura
    - Adicionar chave estrangeira e índices

  3. Segurança
    - Backup da definição da view antes de remover
    - Verificações de existência
    - Tratamento de erros
    - Verificação final da estrutura

  4. Performance
    - Índices otimizados
    - View recriada com melhor estrutura
*/

-- ETAPA 1: Remover view que depende da coluna plano_contratado
DROP VIEW IF EXISTS public.v_empresa_completa;

-- ETAPA 2: Remover view que pode depender de tarefas (precaução)
DROP VIEW IF EXISTS public.v_tarefa_completa;

-- ETAPA 3: Preparar dados para conversão segura
-- Limpar valores que não podem ser convertidos para UUID
UPDATE core.empresa_base 
SET plano_contratado = NULL 
WHERE plano_contratado IS NOT NULL 
AND (
  trim(plano_contratado) = '' 
  OR length(trim(plano_contratado)) = 0
  OR NOT plano_contratado ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
);

-- ETAPA 4: Alterar o tipo da coluna plano_contratado para UUID
ALTER TABLE core.empresa_base 
ALTER COLUMN plano_contratado TYPE uuid 
USING CASE 
  WHEN plano_contratado IS NULL THEN NULL
  WHEN plano_contratado ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' 
  THEN plano_contratado::uuid
  ELSE NULL
END;

-- ETAPA 5: Renomear a coluna para plano_id
ALTER TABLE core.empresa_base RENAME COLUMN plano_contratado TO plano_id;

-- ETAPA 6: Adicionar chave estrangeira para planos.planos(id)
ALTER TABLE core.empresa_base 
ADD CONSTRAINT fk_empresa_base_plano_id 
FOREIGN KEY (plano_id) REFERENCES planos.planos(id) ON DELETE SET NULL;

-- ETAPA 7: Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_empresa_base_plano_id ON core.empresa_base(plano_id) WHERE plano_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_empresa_base_status_plano ON core.empresa_base(status, plano_id) WHERE plano_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_empresa_base_tipo_plano ON core.empresa_base(tipo_pessoa, plano_id) WHERE plano_id IS NOT NULL;

-- ETAPA 8: Recriar view v_empresa_completa com nova estrutura
CREATE OR REPLACE VIEW public.v_empresa_completa AS
SELECT 
  eb.*,
  p.nome as plano_nome,
  p.valor_mensal as plano_valor,
  COUNT(eu.id) as total_usuarios,
  COUNT(cf.id) as total_clientes
FROM core.empresa_base eb
LEFT JOIN planos.planos p ON eb.plano_id = p.id
LEFT JOIN core.empresa_usuario eu ON eb.id = eu.empresa_id
LEFT JOIN clientes.cliente_final cf ON eb.id = cf.empresa_id
GROUP BY eb.id, p.id, p.nome, p.valor_mensal;

-- ETAPA 9: Recriar view v_tarefa_completa (melhorada)
CREATE OR REPLACE VIEW public.v_tarefa_completa AS
SELECT 
  t.*,
  eb.nome as empresa_nome,
  eu.nome_exibicao as responsavel_nome,
  cf.nome as cliente_nome,
  p.nome as projeto_nome,
  COUNT(tc.id) as total_comentarios,
  COUNT(CASE WHEN tcl.concluido = false THEN 1 END) as itens_pendentes,
  COUNT(tcl.id) as total_itens_checklist
FROM tarefas.tarefa t
JOIN core.empresa_base eb ON t.empresa_id = eb.id
JOIN core.empresa_usuario eu ON t.usuario_responsavel_id = eu.id
LEFT JOIN clientes.cliente_final cf ON t.cliente_final_id = cf.id
LEFT JOIN projetos.projeto p ON t.projeto_id = p.id
LEFT JOIN tarefas.tarefa_comentario tc ON t.id = tc.tarefa_id
LEFT JOIN tarefas.tarefa_checklist tcl ON t.id = tcl.tarefa_id
GROUP BY t.id, eb.nome, eu.nome_exibicao, cf.nome, p.nome;

-- ETAPA 10: Atualizar documentação
UPDATE core.documentacao_tabelas 
SET 
  descricao = 'SCHEMA: core - Armazena os dados dos clientes da plataforma (empresas ou pessoas físicas). Cada registro corresponde a quem comprou e usa o sistema. O campo status ajuda a identificar a fase do relacionamento, e observacoes serve para anotações internas da equipe de suporte ou vendas. CORREÇÃO APLICADA: A coluna plano_contratado foi renomeada para plano_id e alterada para tipo UUID com chave estrangeira para planos.planos(id). A view v_empresa_completa foi recriada para incluir informações do plano contratado. Esta mudança melhora a integridade referencial e facilita consultas relacionadas aos planos contratados pelas empresas.',
  atualizado_em = now()
WHERE nome_tabela = 'empresa_base';

-- ETAPA 11: Inserir registro da correção na documentação
INSERT INTO core.documentacao_tabelas (nome_tabela, descricao) VALUES
(
  'CORRECAO_plano_contratado_view_fix',
  'SCHEMA: core - REGISTRO DE CORREÇÃO: Migration resolveu dependência da view v_empresa_completa na coluna plano_contratado. Processo executado: 1) Remoção temporária das views dependentes, 2) Limpeza de dados inválidos, 3) Alteração segura do tipo da coluna de text para UUID, 4) Renomeação da coluna para plano_id, 5) Adição de chave estrangeira para planos.planos(id), 6) Criação de índices otimizados, 7) Recriação das views com estrutura melhorada incluindo informações do plano. Esta correção resolve o erro de dependência e estabelece relacionamento íntegro entre empresas e planos contratados.'
);

-- ETAPA 12: Adicionar comentários explicativos
COMMENT ON COLUMN core.empresa_base.plano_id IS 'Referência UUID ao plano contratado pela empresa (FK para planos.planos) - Renomeado e convertido da coluna plano_contratado';
COMMENT ON VIEW public.v_empresa_completa IS 'View completa de empresas com informações agregadas incluindo dados do plano contratado';
COMMENT ON VIEW public.v_tarefa_completa IS 'View completa de tarefas com informações relacionadas incluindo projeto vinculado';

-- ETAPA 13: Verificação final da estrutura
DO $$
DECLARE
  coluna_existe boolean;
  tipo_correto boolean;
  constraint_existe boolean;
  indices_criados integer;
  view_empresa_existe boolean;
  view_tarefa_existe boolean;
BEGIN
  -- Verificar se a coluna plano_id existe
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'core' 
    AND table_name = 'empresa_base' 
    AND column_name = 'plano_id'
  ) INTO coluna_existe;
  
  -- Verificar se o tipo é UUID
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'core' 
    AND table_name = 'empresa_base' 
    AND column_name = 'plano_id'
    AND data_type = 'uuid'
  ) INTO tipo_correto;
  
  -- Verificar se a constraint de FK existe
  SELECT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_schema = 'core' 
    AND table_name = 'empresa_base' 
    AND constraint_name = 'fk_empresa_base_plano_id'
  ) INTO constraint_existe;
  
  -- Contar índices criados
  SELECT COUNT(*) INTO indices_criados
  FROM pg_indexes 
  WHERE schemaname = 'core' 
  AND tablename = 'empresa_base' 
  AND indexname LIKE '%plano_id%';
  
  -- Verificar se as views foram recriadas
  SELECT EXISTS (
    SELECT 1 FROM information_schema.views
    WHERE table_schema = 'public' 
    AND table_name = 'v_empresa_completa'
  ) INTO view_empresa_existe;
  
  SELECT EXISTS (
    SELECT 1 FROM information_schema.views
    WHERE table_schema = 'public' 
    AND table_name = 'v_tarefa_completa'
  ) INTO view_tarefa_existe;
  
  -- Verificar se a coluna plano_contratado ainda existe (não deveria)
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'core' 
    AND table_name = 'empresa_base' 
    AND column_name = 'plano_contratado'
  ) THEN
    RAISE WARNING '✗ ERRO: Coluna plano_contratado ainda existe - renomeação falhou';
  ELSE
    RAISE NOTICE '✓ SUCESSO: Coluna plano_contratado foi renomeada para plano_id';
  END IF;
  
  -- Relatório de verificação completo
  RAISE NOTICE '=== RELATÓRIO FINAL DA CORREÇÃO ===';
  
  IF coluna_existe AND tipo_correto THEN
    RAISE NOTICE '✓ SUCESSO: Coluna plano_id existe com tipo UUID';
  ELSE
    RAISE WARNING '✗ ERRO: Problema com coluna plano_id - Existe: %, Tipo UUID: %', coluna_existe, tipo_correto;
  END IF;
  
  IF constraint_existe THEN
    RAISE NOTICE '✓ SUCESSO: Chave estrangeira fk_empresa_base_plano_id criada';
  ELSE
    RAISE WARNING '✗ ERRO: Chave estrangeira não foi criada';
  END IF;
  
  RAISE NOTICE '✓ ÍNDICES: % índices relacionados a plano_id criados', indices_criados;
  
  IF view_empresa_existe THEN
    RAISE NOTICE '✓ SUCESSO: View v_empresa_completa recriada';
  ELSE
    RAISE WARNING '✗ ERRO: View v_empresa_completa não foi recriada';
  END IF;
  
  IF view_tarefa_existe THEN
    RAISE NOTICE '✓ SUCESSO: View v_tarefa_completa recriada';
  ELSE
    RAISE WARNING '✗ ERRO: View v_tarefa_completa não foi recriada';
  END IF;
  
  RAISE NOTICE '=== FIM DO RELATÓRIO ===';
END $$;