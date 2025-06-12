/*
  # Reorganização do banco em schemas específicos

  1. Criação de Schemas
    - core: tabelas fundamentais do sistema
    - clientes: tabelas relacionadas aos clientes finais
    - planos: tabelas de planos e itens
    - tarefas: tabelas do sistema de tarefas

  2. Movimentação de Tabelas
    - Mover tabelas existentes para os schemas apropriados
    - Manter integridade referencial
    - Preservar políticas RLS e índices

  3. Atualização de Referências
    - Atualizar chaves estrangeiras
    - Manter triggers e funções
    - Preservar dados existentes
*/

-- Criar os schemas
CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS clientes;
CREATE SCHEMA IF NOT EXISTS planos;
CREATE SCHEMA IF NOT EXISTS tarefas;

-- Mover tabelas para o schema core
ALTER TABLE documentacao_tabelas SET SCHEMA core;
ALTER TABLE empresa_base SET SCHEMA core;
ALTER TABLE empresa_usuario SET SCHEMA core;
ALTER TABLE usuario_interno SET SCHEMA core;
ALTER TABLE empresa_acesso_interno SET SCHEMA core;

-- Mover tabelas para o schema clientes
ALTER TABLE cliente_final SET SCHEMA clientes;
ALTER TABLE cliente_colaborador SET SCHEMA clientes;
ALTER TABLE cliente_supervisor SET SCHEMA clientes;
ALTER TABLE supervisor_colaborador SET SCHEMA clientes;

-- Mover tabelas para o schema planos
ALTER TABLE planos SET SCHEMA planos;
ALTER TABLE plano_itens SET SCHEMA planos;

-- Mover tabelas para o schema tarefas
ALTER TABLE tarefa SET SCHEMA tarefas;
ALTER TABLE tarefa_recorrente SET SCHEMA tarefas;
ALTER TABLE tarefa_comentario SET SCHEMA tarefas;
ALTER TABLE tarefa_notificacao SET SCHEMA tarefas;
ALTER TABLE tarefa_checklist SET SCHEMA tarefas;

-- Atualizar a documentação das tabelas com os novos schemas
UPDATE core.documentacao_tabelas 
SET 
  descricao = CONCAT('SCHEMA: core - ', descricao),
  atualizado_em = now()
WHERE nome_tabela IN ('documentacao_tabelas', 'empresa_base', 'empresa_usuario', 'usuario_interno', 'empresa_acesso_interno');

UPDATE core.documentacao_tabelas 
SET 
  descricao = CONCAT('SCHEMA: clientes - ', descricao),
  atualizado_em = now()
WHERE nome_tabela IN ('cliente_final', 'cliente_colaborador', 'cliente_supervisor', 'supervisor_colaborador');

UPDATE core.documentacao_tabelas 
SET 
  descricao = CONCAT('SCHEMA: planos - ', descricao),
  atualizado_em = now()
WHERE nome_tabela IN ('planos', 'plano_itens');

UPDATE core.documentacao_tabelas 
SET 
  descricao = CONCAT('SCHEMA: tarefas - ', descricao),
  atualizado_em = now()
WHERE nome_tabela IN ('tarefa', 'tarefa_recorrente', 'tarefa_comentario', 'tarefa_notificacao', 'tarefa_checklist');

-- Inserir documentação dos schemas criados
INSERT INTO core.documentacao_tabelas (nome_tabela, descricao) VALUES
(
  'SCHEMA_core',
  'SCHEMA: core - Schema principal que contém as tabelas fundamentais do sistema: empresa_base (dados das empresas clientes), empresa_usuario (usuários das empresas), usuario_interno (usuários da equipe interna), empresa_acesso_interno (controle de acesso interno) e documentacao_tabelas (documentação do sistema). Este schema representa o núcleo operacional da plataforma.'
),
(
  'SCHEMA_clientes',
  'SCHEMA: clientes - Schema dedicado ao gerenciamento de clientes finais e seus relacionamentos: cliente_final (dados dos clientes finais), cliente_colaborador (relacionamento colaborador-cliente), cliente_supervisor (relacionamento supervisor-cliente) e supervisor_colaborador (hierarquia supervisor-colaborador). Centraliza toda a gestão de relacionamento com clientes.'
),
(
  'SCHEMA_planos',
  'SCHEMA: planos - Schema para gestão de planos e pacotes de serviços: planos (definição dos planos disponíveis) e plano_itens (itens que compõem cada plano). Permite estruturar diferentes ofertas comerciais e controlar recursos disponíveis por plano contratado.'
),
(
  'SCHEMA_tarefas',
  'SCHEMA: tarefas - Schema completo para o sistema de gestão de tarefas: tarefa (tarefas individuais), tarefa_recorrente (padrões de recorrência), tarefa_comentario (comentários nas tarefas), tarefa_notificacao (sistema de notificações) e tarefa_checklist (subtarefas e checklists). Centraliza toda a funcionalidade de produtividade e acompanhamento de atividades.'
);

-- Criar views para facilitar consultas cross-schema (opcional)
-- Estas views podem ser úteis para consultas que precisam acessar múltiplos schemas

CREATE OR REPLACE VIEW public.v_empresa_completa AS
SELECT 
  eb.*,
  COUNT(eu.id) as total_usuarios,
  COUNT(cf.id) as total_clientes
FROM core.empresa_base eb
LEFT JOIN core.empresa_usuario eu ON eb.id = eu.empresa_id
LEFT JOIN clientes.cliente_final cf ON eb.id = cf.empresa_id
GROUP BY eb.id;

CREATE OR REPLACE VIEW public.v_tarefa_completa AS
SELECT 
  t.*,
  eb.nome as empresa_nome,
  eu.nome_exibicao as responsavel_nome,
  cf.nome as cliente_nome,
  COUNT(tc.id) as total_comentarios,
  COUNT(CASE WHEN tcl.concluido = false THEN 1 END) as itens_pendentes,
  COUNT(tcl.id) as total_itens_checklist
FROM tarefas.tarefa t
JOIN core.empresa_base eb ON t.empresa_id = eb.id
JOIN core.empresa_usuario eu ON t.usuario_responsavel_id = eu.id
LEFT JOIN clientes.cliente_final cf ON t.cliente_final_id = cf.id
LEFT JOIN tarefas.tarefa_comentario tc ON t.id = tc.tarefa_id
LEFT JOIN tarefas.tarefa_checklist tcl ON t.id = tcl.tarefa_id
GROUP BY t.id, eb.nome, eu.nome_exibicao, cf.nome;

-- Comentários explicativos sobre a nova estrutura
COMMENT ON SCHEMA core IS 'Schema principal com tabelas fundamentais do sistema (empresas, usuários, documentação)';
COMMENT ON SCHEMA clientes IS 'Schema para gestão de clientes finais e relacionamentos hierárquicos';
COMMENT ON SCHEMA planos IS 'Schema para definição de planos comerciais e seus componentes';
COMMENT ON SCHEMA tarefas IS 'Schema completo para sistema de gestão de tarefas e produtividade';