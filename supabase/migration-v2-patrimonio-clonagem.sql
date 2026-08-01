-- ============================================================================
-- CASAL NO CONTROLE — MIGRAÇÃO INCREMENTAL V2
-- Patrimônio Conjunto + controle de competências + clonagem do mês anterior
-- ============================================================================
-- Execute este arquivo no SQL Editor do Supabase ANTES de publicar o novo
-- index.html. Esta migração NÃO apaga tabelas nem dados existentes.
-- Pode ser executada novamente com segurança.
-- ============================================================================

begin;

create extension if not exists "uuid-ossp";

-- ---------------------------------------------------------------------------
-- 1. PATRIMÔNIO CONJUNTO
-- ---------------------------------------------------------------------------
create table if not exists public.patrimonio_conjunto (
  id                       uuid primary key default uuid_generate_v4(),
  household_id             uuid not null references public.households(id) on delete cascade,
  nome                     text not null,
  categoria                text not null default 'Outros',
  valor_total_estimado     numeric(14,2) not null default 0 check (valor_total_estimado >= 0),
  valor_usuario            numeric(14,2) not null default 0 check (valor_usuario >= 0),
  valor_parceira           numeric(14,2) not null default 0 check (valor_parceira >= 0),
  percentual_usuario       numeric(7,4) generated always as (
    case
      when (valor_usuario + valor_parceira) > 0
        then round((valor_usuario / (valor_usuario + valor_parceira)) * 100, 4)
      else 0
    end
  ) stored,
  percentual_parceira      numeric(7,4) generated always as (
    case
      when (valor_usuario + valor_parceira) > 0
        then round((valor_parceira / (valor_usuario + valor_parceira)) * 100, 4)
      else 0
    end
  ) stored,
  data_referencia          date,
  observacoes              text,
  origem_investimento_id   uuid unique,
  created_at               timestamptz not null default now(),
  updated_at               timestamptz not null default now()
);

comment on table public.patrimonio_conjunto is
  'Bens e valores do casal, com divisão de participação entre titular e parceiro(a).';
comment on column public.patrimonio_conjunto.origem_investimento_id is
  'Identificador legado usado somente para impedir que uma migração de investimentos seja repetida.';

create index if not exists patrimonio_conjunto_household_idx
  on public.patrimonio_conjunto (household_id);
create index if not exists patrimonio_conjunto_categoria_idx
  on public.patrimonio_conjunto (household_id, categoria);
create index if not exists patrimonio_conjunto_data_idx
  on public.patrimonio_conjunto (household_id, data_referencia desc);

-- Atualiza updated_at automaticamente.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists patrimonio_conjunto_set_updated_at on public.patrimonio_conjunto;
create trigger patrimonio_conjunto_set_updated_at
  before update on public.patrimonio_conjunto
  for each row execute function public.set_updated_at();

alter table public.patrimonio_conjunto enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'patrimonio_conjunto'
      and policyname = 'patrimonio_all_own'
  ) then
    create policy patrimonio_all_own on public.patrimonio_conjunto
      for all
      using (household_id = public.current_household_id())
      with check (household_id = public.current_household_id());
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- 2. CONTROLE DE COMPETÊNCIAS
--    A restrição UNIQUE abaixo é a trava que impede uma clonagem repetida.
-- ---------------------------------------------------------------------------
create table if not exists public.meses_financeiros (
  id          uuid primary key default uuid_generate_v4(),
  household_id uuid not null references public.households(id) on delete cascade,
  ano         integer not null check (ano between 2000 and 2200),
  mes         integer not null check (mes between 1 and 12),
  modo        text not null default 'vazio' check (modo in ('vazio','clonado','manual')),
  origem_ano  integer,
  origem_mes  integer check (origem_mes is null or origem_mes between 1 and 12),
  created_at  timestamptz not null default now(),
  unique (household_id, ano, mes)
);

comment on table public.meses_financeiros is
  'Registra como cada competência foi iniciada e impede clonagem duplicada.';

create index if not exists meses_financeiros_household_idx
  on public.meses_financeiros (household_id, ano desc, mes desc);

alter table public.meses_financeiros enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'meses_financeiros'
      and policyname = 'meses_financeiros_all_own'
  ) then
    create policy meses_financeiros_all_own on public.meses_financeiros
      for all
      using (household_id = public.current_household_id())
      with check (household_id = public.current_household_id());
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- 3. FUNÇÃO PARA INICIAR UMA COMPETÊNCIA VAZIA
-- ---------------------------------------------------------------------------
create or replace function public.iniciar_mes_vazio(p_ano integer, p_mes integer)
returns jsonb
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_household uuid := public.current_household_id();
  v_inicio date;
begin
  if v_household is null then
    raise exception 'USUARIO_SEM_HOUSEHOLD';
  end if;
  if p_ano not between 2000 and 2200 or p_mes not between 1 and 12 then
    raise exception 'COMPETENCIA_INVALIDA';
  end if;

  v_inicio := make_date(p_ano, p_mes, 1);
  perform pg_advisory_xact_lock(hashtext(v_household::text), p_ano * 100 + p_mes);

  if exists (select 1 from public.despesas where household_id = v_household and data >= v_inicio and data < (v_inicio + interval '1 month'))
     or exists (select 1 from public.schultz_bank where household_id = v_household and data >= v_inicio and data < (v_inicio + interval '1 month'))
     or exists (select 1 from public.sicredi_black where household_id = v_household and data >= v_inicio and data < (v_inicio + interval '1 month')) then
    raise exception 'DESTINO_COM_DADOS';
  end if;

  insert into public.meses_financeiros (household_id, ano, mes, modo)
  values (v_household, p_ano, p_mes, 'vazio')
  on conflict (household_id, ano, mes) do nothing;

  return jsonb_build_object('ano', p_ano, 'mes', p_mes, 'modo', 'vazio');
end;
$$;

-- ---------------------------------------------------------------------------
-- 4. FUNÇÃO TRANSACIONAL PARA CLONAR O MÊS ANTERIOR
--    - bloqueia operações concorrentes para a mesma competência;
--    - recusa destino que já possua dados;
--    - gera novos IDs, deixando origem e destino independentes;
--    - registra a operação em meses_financeiros.
-- ---------------------------------------------------------------------------
create or replace function public.clonar_mes_anterior(p_ano integer, p_mes integer)
returns jsonb
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_household uuid := public.current_household_id();
  v_destino date;
  v_origem date;
  v_exp integer := 0;
  v_sch integer := 0;
  v_sic integer := 0;
begin
  if v_household is null then
    raise exception 'USUARIO_SEM_HOUSEHOLD';
  end if;
  if p_ano not between 2000 and 2200 or p_mes not between 1 and 12 then
    raise exception 'COMPETENCIA_INVALIDA';
  end if;

  v_destino := make_date(p_ano, p_mes, 1);
  v_origem := (v_destino - interval '1 month')::date;

  perform pg_advisory_xact_lock(hashtext(v_household::text), p_ano * 100 + p_mes);

  if exists (select 1 from public.despesas where household_id = v_household and data >= v_destino and data < (v_destino + interval '1 month'))
     or exists (select 1 from public.schultz_bank where household_id = v_household and data >= v_destino and data < (v_destino + interval '1 month'))
     or exists (select 1 from public.sicredi_black where household_id = v_household and data >= v_destino and data < (v_destino + interval '1 month')) then
    raise exception 'DESTINO_COM_DADOS';
  end if;

  if not exists (select 1 from public.despesas where household_id = v_household and data >= v_origem and data < v_destino)
     and not exists (select 1 from public.schultz_bank where household_id = v_household and data >= v_origem and data < v_destino)
     and not exists (select 1 from public.sicredi_black where household_id = v_household and data >= v_origem and data < v_destino) then
    raise exception 'ORIGEM_SEM_DADOS';
  end if;

  insert into public.meses_financeiros
    (household_id, ano, mes, modo, origem_ano, origem_mes)
  values
    (v_household, p_ano, p_mes, 'clonado', extract(year from v_origem)::integer, extract(month from v_origem)::integer)
  on conflict (household_id, ano, mes) do update
    set modo = 'clonado',
        origem_ano = excluded.origem_ano,
        origem_mes = excluded.origem_mes
    where public.meses_financeiros.modo = 'vazio';

  if not found then
    raise exception 'COMPETENCIA_JA_INICIADA';
  end if;

  insert into public.despesas
    (household_id, data, categoria, descricao, valor, responsavel_pagamento)
  select household_id, v_destino, categoria, descricao, valor, responsavel_pagamento
  from public.despesas
  where household_id = v_household
    and data >= v_origem and data < v_destino;
  get diagnostics v_exp = row_count;

  insert into public.schultz_bank
    (household_id, data, descricao, valor)
  select household_id, v_destino, descricao, valor
  from public.schultz_bank
  where household_id = v_household
    and data >= v_origem and data < v_destino;
  get diagnostics v_sch = row_count;

  insert into public.sicredi_black
    (household_id, data, descricao, valor)
  select household_id, v_destino, descricao, valor
  from public.sicredi_black
  where household_id = v_household
    and data >= v_origem and data < v_destino;
  get diagnostics v_sic = row_count;

  return jsonb_build_object(
    'origem', to_char(v_origem, 'YYYY-MM'),
    'destino', to_char(v_destino, 'YYYY-MM'),
    'despesas', v_exp,
    'schultz_bank', v_sch,
    'sicredi_black', v_sic,
    'total', v_exp + v_sch + v_sic
  );
end;
$$;

grant execute on function public.iniciar_mes_vazio(integer, integer) to authenticated;
grant execute on function public.clonar_mes_anterior(integer, integer) to authenticated;

-- ---------------------------------------------------------------------------
-- 5. MIGRAÇÃO NÃO DESTRUTIVA DOS INVESTIMENTOS LEGADOS
--    Os valores são preservados como patrimônio, porém a divisão entre o casal
--    fica zerada para ser revisada manualmente, pois a tabela antiga não
--    armazenava titularidade individual.
-- ---------------------------------------------------------------------------
do $$
begin
  if to_regclass('public.investimentos') is not null then
    execute $migrate$
      insert into public.patrimonio_conjunto
        (household_id, nome, categoria, valor_total_estimado, valor_usuario,
         valor_parceira, data_referencia, observacoes, origem_investimento_id)
      select
        i.household_id,
        i.ativo,
        coalesce(nullif(i.categoria, ''), 'Investimentos'),
        greatest(coalesce(i.valor, 0), 0),
        0,
        0,
        i.data_referencia,
        concat_ws(E'\n',
          case when nullif(i.instituicao, '') is not null then 'Instituição: ' || i.instituicao end,
          'Migrado automaticamente da antiga área Investir. Revise a divisão entre o casal.'
        ),
        i.id
      from public.investimentos i
      where not exists (
        select 1 from public.patrimonio_conjunto p
        where p.origem_investimento_id = i.id
      )
    $migrate$;
  end if;
end;
$$;

commit;
