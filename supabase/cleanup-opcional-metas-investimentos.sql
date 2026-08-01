-- ============================================================================
-- CASAL NO CONTROLE — LIMPEZA OPCIONAL DE ESTRUTURAS LEGADAS
-- ============================================================================
-- NÃO execute este arquivo antes de:
--   1) executar migration-v2-patrimonio-clonagem.sql;
--   2) conferir os resultados das consultas abaixo;
--   3) fazer um backup, caso deseje guardar o histórico de Metas.
--
-- Este arquivo é deliberadamente conservador:
--   - interrompe se houver qualquer meta cadastrada;
--   - interrompe se algum investimento ainda não tiver sido migrado.
-- ============================================================================

-- DIAGNÓSTICO — execute e confira antes da parte destrutiva.
select count(*) as total_metas_legadas
from public.metas_financeiras;

select count(*) as total_investimentos_legados
from public.investimentos;

select count(*) as investimentos_ainda_nao_migrados
from public.investimentos i
where not exists (
  select 1
  from public.patrimonio_conjunto p
  where p.origem_investimento_id = i.id
);

-- PARTE DESTRUTIVA OPCIONAL.
-- Os blocos de segurança abaixo abortam a transação se houver risco de perda.
begin;

do $$
begin
  if to_regclass('public.metas_financeiras') is not null
     and exists (select 1 from public.metas_financeiras) then
    raise exception
      'LIMPEZA CANCELADA: metas_financeiras ainda possui registros. Exporte ou remova esses dados conscientemente antes de tentar novamente.';
  end if;

  if to_regclass('public.investimentos') is not null
     and exists (
       select 1
       from public.investimentos i
       where not exists (
         select 1
         from public.patrimonio_conjunto p
         where p.origem_investimento_id = i.id
       )
     ) then
    raise exception
      'LIMPEZA CANCELADA: existem investimentos que ainda não foram migrados para patrimonio_conjunto.';
  end if;
end;
$$;

-- DROP TABLE remove também as policies e índices exclusivos dessas tabelas.
drop table if exists public.metas_financeiras;
drop table if exists public.investimentos;

commit;
