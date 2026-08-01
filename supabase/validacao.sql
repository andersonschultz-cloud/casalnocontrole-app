-- ============================================================================
-- CASAL NO CONTROLE — VALIDAÇÃO APÓS A MIGRAÇÃO V2
-- Execute no SQL Editor do Supabase. Somente consultas; nada é alterado.
-- ============================================================================

-- 1. Estruturas principais esperadas.
select
  to_regclass('public.households') as households,
  to_regclass('public.usuarios') as usuarios,
  to_regclass('public.despesas') as despesas,
  to_regclass('public.schultz_bank') as schultz_bank,
  to_regclass('public.sicredi_black') as sicredi_black,
  to_regclass('public.historico_mensal') as historico_mensal,
  to_regclass('public.patrimonio_conjunto') as patrimonio_conjunto,
  to_regclass('public.meses_financeiros') as meses_financeiros;

-- 2. Funções da clonagem.
select routine_name
from information_schema.routines
where routine_schema = 'public'
  and routine_name in ('iniciar_mes_vazio','clonar_mes_anterior','current_household_id')
order by routine_name;

-- 3. RLS deve estar habilitada.
select relname as tabela, relrowsecurity as rls_habilitada
from pg_class
where oid in (
  'public.patrimonio_conjunto'::regclass,
  'public.meses_financeiros'::regclass
);

-- 4. Policies esperadas.
select tablename, policyname, cmd
from pg_policies
where schemaname = 'public'
  and tablename in ('patrimonio_conjunto','meses_financeiros')
order by tablename, policyname;

-- 5. Totais por casa sem expor detalhes financeiros individuais.
select household_id, count(*) as itens_patrimoniais,
       sum(valor_total_estimado) as patrimonio_total
from public.patrimonio_conjunto
group by household_id;

-- 6. Verifica se investimentos legados foram migrados, caso a tabela ainda exista.
do $$
declare
  faltantes integer;
begin
  if to_regclass('public.investimentos') is not null then
    execute '
      select count(*)
      from public.investimentos i
      where not exists (
        select 1 from public.patrimonio_conjunto p
        where p.origem_investimento_id = i.id
      )' into faltantes;
    raise notice 'Investimentos ainda não migrados: %', faltantes;
  else
    raise notice 'Tabela investimentos não existe; nenhuma validação legada necessária.';
  end if;
end;
$$;
