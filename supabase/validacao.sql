-- ════════════════════════════════════════════════════════════════
-- CASAL NO CONTROLE — VALIDAÇÃO DO SCHEMA
-- ════════════════════════════════════════════════════════════════
-- Cole cada bloco (ou tudo de uma vez) no SQL Editor do Supabase e
-- confira o resultado contra o "Esperado" de cada um.
-- ════════════════════════════════════════════════════════════════

-- 1) As 8 tabelas existem?
select table_name
from information_schema.tables
where table_schema = 'public'
order by table_name;
-- Esperado (8 linhas): despesas, historico_mensal, households,
-- investimentos, metas_financeiras, schultz_bank, sicredi_black, usuarios

-- 2) RLS está ativo em todas?
select relname as tabela, relrowsecurity as rls_ativo
from pg_class
where relnamespace = 'public'::regnamespace and relkind = 'r'
order by relname;
-- Esperado: rls_ativo = true nas 8 linhas

-- 3) As 9 policies foram criadas?
select tablename as tabela, policyname, cmd as operacao
from pg_policies
where schemaname = 'public'
order by tablename, policyname;
-- Esperado (9 linhas):
--   households        -> households_select_own (SELECT), households_update_own (UPDATE)
--   usuarios           -> usuarios_all_own (ALL)
--   despesas           -> despesas_all_own (ALL)
--   schultz_bank       -> schultz_all_own (ALL)
--   sicredi_black      -> sicredi_all_own (ALL)
--   historico_mensal   -> historico_all_own (ALL)
--   investimentos      -> investimentos_all_own (ALL)
--   metas_financeiras  -> metas_all_own (ALL)

-- 4) A função helper current_household_id() existe?
select proname as funcao, prosecdef as security_definer
from pg_proc
where proname = 'current_household_id';
-- Esperado: 1 linha, security_definer = true

-- 5) A função/trigger que cria a "casa" no cadastro existe e está ativa?
select tgname as gatilho, tgenabled as status
from pg_trigger
where tgname = 'on_auth_user_created';
-- Esperado: 1 linha, status = 'O' (Origin = ativo)

-- 6) As foreign keys de household_id estão todas apontando certo?
select
  tc.table_name as tabela,
  kcu.column_name as coluna,
  ccu.table_name as referencia
from information_schema.table_constraints tc
join information_schema.key_column_usage kcu
  on tc.constraint_name = kcu.constraint_name and tc.table_schema = kcu.table_schema
join information_schema.constraint_column_usage ccu
  on tc.constraint_name = ccu.constraint_name and tc.table_schema = ccu.table_schema
where tc.constraint_type = 'FOREIGN KEY' and tc.table_schema = 'public'
order by tc.table_name;
-- Esperado: despesas, historico_mensal, investimentos, metas_financeiras,
-- schultz_bank, sicredi_black e usuarios todos referenciando "households";
-- households.auth_user_id referenciando auth.users (essa linha pode não
-- aparecer aqui porque auth.users fica fora do schema "public" — normal).

-- 7) Quantas casas e usuários existem até agora?
select
  (select count(*) from public.households) as total_casas,
  (select count(*) from public.usuarios)   as total_usuarios;
-- Esperado, ANTES do primeiro cadastro bem-sucedido no app: 0 e 0.
-- Depois do primeiro "Criar conta" funcionar: 1 e 2 (titular + parceiro).
