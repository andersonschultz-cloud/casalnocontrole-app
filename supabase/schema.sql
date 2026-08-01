-- ============================================================================
-- CASAL NO CONTROLE — SCHEMA COMPLETO PARA UMA INSTALAÇÃO NOVA
-- ============================================================================
-- ATENÇÃO:
--   • Banco já existente: NÃO execute este arquivo.
--     Use migration-v2-patrimonio-clonagem.sql.
--   • Projeto Supabase vazio: execute este arquivo uma única vez.
-- ============================================================================

create extension if not exists "uuid-ossp";

-- ---------------------------------------------------------------------------
-- CASA E PERFIS
-- ---------------------------------------------------------------------------
create table public.households (
  id            uuid primary key default uuid_generate_v4(),
  auth_user_id  uuid not null unique references auth.users(id) on delete cascade,
  nome          text not null default 'Nossa Casa',
  created_at    timestamptz not null default now()
);

create table public.usuarios (
  id            uuid primary key default uuid_generate_v4(),
  household_id  uuid not null references public.households(id) on delete cascade,
  nome          text not null,
  perfil        text not null check (perfil in ('titular','parceiro')),
  created_at    timestamptz not null default now(),
  unique (household_id, perfil)
);

-- ---------------------------------------------------------------------------
-- LANÇAMENTOS MENSAIS
-- ---------------------------------------------------------------------------
create table public.despesas (
  id                    uuid primary key default uuid_generate_v4(),
  household_id          uuid not null references public.households(id) on delete cascade,
  data                  date not null,
  categoria             text not null default 'Apartamento',
  descricao             text not null,
  valor                 numeric(12,2) not null default 0,
  responsavel_pagamento uuid references public.usuarios(id) on delete set null,
  created_at            timestamptz not null default now()
);

create table public.schultz_bank (
  id            uuid primary key default uuid_generate_v4(),
  household_id  uuid not null references public.households(id) on delete cascade,
  data          date not null,
  descricao     text not null,
  valor         numeric(12,2) not null default 0,
  created_at    timestamptz not null default now()
);

create table public.sicredi_black (
  id            uuid primary key default uuid_generate_v4(),
  household_id  uuid not null references public.households(id) on delete cascade,
  data          date not null,
  descricao     text not null,
  valor         numeric(12,2) not null default 0,
  created_at    timestamptz not null default now()
);

create table public.historico_mensal (
  id            uuid primary key default uuid_generate_v4(),
  household_id  uuid not null references public.households(id) on delete cascade,
  ano           integer not null,
  mes           integer not null check (mes between 1 and 12),
  total         numeric(12,2) not null default 0,
  created_at    timestamptz not null default now(),
  unique (household_id, ano, mes)
);

-- ---------------------------------------------------------------------------
-- PATRIMÔNIO CONJUNTO
-- ---------------------------------------------------------------------------
create table public.patrimonio_conjunto (
  id                       uuid primary key default uuid_generate_v4(),
  household_id             uuid not null references public.households(id) on delete cascade,
  nome                     text not null,
  categoria                text not null default 'Outros',
  valor_total_estimado     numeric(14,2) not null default 0 check (valor_total_estimado >= 0),
  valor_usuario            numeric(14,2) not null default 0 check (valor_usuario >= 0),
  valor_parceira           numeric(14,2) not null default 0 check (valor_parceira >= 0),
  percentual_usuario       numeric(7,4) generated always as (
    case when (valor_usuario + valor_parceira) > 0
      then round((valor_usuario / (valor_usuario + valor_parceira)) * 100, 4)
      else 0 end
  ) stored,
  percentual_parceira      numeric(7,4) generated always as (
    case when (valor_usuario + valor_parceira) > 0
      then round((valor_parceira / (valor_usuario + valor_parceira)) * 100, 4)
      else 0 end
  ) stored,
  data_referencia          date,
  observacoes              text,
  origem_investimento_id   uuid unique,
  created_at               timestamptz not null default now(),
  updated_at               timestamptz not null default now()
);

create table public.meses_financeiros (
  id           uuid primary key default uuid_generate_v4(),
  household_id uuid not null references public.households(id) on delete cascade,
  ano          integer not null check (ano between 2000 and 2200),
  mes          integer not null check (mes between 1 and 12),
  modo         text not null default 'vazio' check (modo in ('vazio','clonado','manual')),
  origem_ano   integer,
  origem_mes   integer check (origem_mes is null or origem_mes between 1 and 12),
  created_at   timestamptz not null default now(),
  unique (household_id, ano, mes)
);

create index despesas_household_data_idx on public.despesas (household_id, data);
create index schultz_household_data_idx on public.schultz_bank (household_id, data);
create index sicredi_household_data_idx on public.sicredi_black (household_id, data);
create index patrimonio_conjunto_household_idx on public.patrimonio_conjunto (household_id);
create index patrimonio_conjunto_categoria_idx on public.patrimonio_conjunto (household_id, categoria);
create index meses_financeiros_household_idx on public.meses_financeiros (household_id, ano desc, mes desc);

-- ---------------------------------------------------------------------------
-- FUNÇÕES AUXILIARES E TRIGGERS
-- ---------------------------------------------------------------------------
create or replace function public.current_household_id()
returns uuid
language sql
security definer
stable
set search_path = public
as $$
  select id from public.households where auth_user_id = auth.uid();
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  hid uuid;
begin
  insert into public.households (auth_user_id, nome)
  values (new.id, coalesce(new.raw_user_meta_data->>'nome_casa', 'Nossa Casa'))
  returning id into hid;

  insert into public.usuarios (household_id, nome, perfil) values
    (hid, coalesce(new.raw_user_meta_data->>'titular_nome', 'Titular'), 'titular'),
    (hid, coalesce(new.raw_user_meta_data->>'parceiro_nome', 'Parceiro'), 'parceiro');
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

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

create trigger patrimonio_conjunto_set_updated_at
  before update on public.patrimonio_conjunto
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- ROW LEVEL SECURITY
-- ---------------------------------------------------------------------------
alter table public.households enable row level security;
alter table public.usuarios enable row level security;
alter table public.despesas enable row level security;
alter table public.schultz_bank enable row level security;
alter table public.sicredi_black enable row level security;
alter table public.historico_mensal enable row level security;
alter table public.patrimonio_conjunto enable row level security;
alter table public.meses_financeiros enable row level security;

create policy households_select_own on public.households
  for select using (auth_user_id = auth.uid());
create policy households_update_own on public.households
  for update using (auth_user_id = auth.uid());
create policy usuarios_all_own on public.usuarios
  for all using (household_id = public.current_household_id())
  with check (household_id = public.current_household_id());
create policy despesas_all_own on public.despesas
  for all using (household_id = public.current_household_id())
  with check (household_id = public.current_household_id());
create policy schultz_all_own on public.schultz_bank
  for all using (household_id = public.current_household_id())
  with check (household_id = public.current_household_id());
create policy sicredi_all_own on public.sicredi_black
  for all using (household_id = public.current_household_id())
  with check (household_id = public.current_household_id());
create policy historico_all_own on public.historico_mensal
  for all using (household_id = public.current_household_id())
  with check (household_id = public.current_household_id());
create policy patrimonio_all_own on public.patrimonio_conjunto
  for all using (household_id = public.current_household_id())
  with check (household_id = public.current_household_id());
create policy meses_financeiros_all_own on public.meses_financeiros
  for all using (household_id = public.current_household_id())
  with check (household_id = public.current_household_id());

-- ---------------------------------------------------------------------------
-- RPC: INICIAR MÊS VAZIO
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
  if v_household is null then raise exception 'USUARIO_SEM_HOUSEHOLD'; end if;
  if p_ano not between 2000 and 2200 or p_mes not between 1 and 12 then raise exception 'COMPETENCIA_INVALIDA'; end if;
  v_inicio := make_date(p_ano, p_mes, 1);
  perform pg_advisory_xact_lock(hashtext(v_household::text), p_ano * 100 + p_mes);
  if exists (select 1 from public.despesas where household_id=v_household and data>=v_inicio and data<(v_inicio+interval '1 month'))
     or exists (select 1 from public.schultz_bank where household_id=v_household and data>=v_inicio and data<(v_inicio+interval '1 month'))
     or exists (select 1 from public.sicredi_black where household_id=v_household and data>=v_inicio and data<(v_inicio+interval '1 month')) then
    raise exception 'DESTINO_COM_DADOS';
  end if;
  insert into public.meses_financeiros (household_id,ano,mes,modo)
  values (v_household,p_ano,p_mes,'vazio')
  on conflict (household_id,ano,mes) do nothing;
  return jsonb_build_object('ano',p_ano,'mes',p_mes,'modo','vazio');
end;
$$;

-- ---------------------------------------------------------------------------
-- RPC: CLONAR MÊS ANTERIOR
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
  if v_household is null then raise exception 'USUARIO_SEM_HOUSEHOLD'; end if;
  if p_ano not between 2000 and 2200 or p_mes not between 1 and 12 then raise exception 'COMPETENCIA_INVALIDA'; end if;
  v_destino := make_date(p_ano,p_mes,1);
  v_origem := (v_destino - interval '1 month')::date;
  perform pg_advisory_xact_lock(hashtext(v_household::text), p_ano * 100 + p_mes);

  if exists (select 1 from public.despesas where household_id=v_household and data>=v_destino and data<(v_destino+interval '1 month'))
     or exists (select 1 from public.schultz_bank where household_id=v_household and data>=v_destino and data<(v_destino+interval '1 month'))
     or exists (select 1 from public.sicredi_black where household_id=v_household and data>=v_destino and data<(v_destino+interval '1 month')) then
    raise exception 'DESTINO_COM_DADOS';
  end if;

  if not exists (select 1 from public.despesas where household_id=v_household and data>=v_origem and data<v_destino)
     and not exists (select 1 from public.schultz_bank where household_id=v_household and data>=v_origem and data<v_destino)
     and not exists (select 1 from public.sicredi_black where household_id=v_household and data>=v_origem and data<v_destino) then
    raise exception 'ORIGEM_SEM_DADOS';
  end if;

  insert into public.meses_financeiros (household_id,ano,mes,modo,origem_ano,origem_mes)
  values (v_household,p_ano,p_mes,'clonado',extract(year from v_origem)::integer,extract(month from v_origem)::integer)
  on conflict (household_id,ano,mes) do update
    set modo='clonado',origem_ano=excluded.origem_ano,origem_mes=excluded.origem_mes
    where public.meses_financeiros.modo='vazio';
  if not found then raise exception 'COMPETENCIA_JA_INICIADA'; end if;

  insert into public.despesas (household_id,data,categoria,descricao,valor,responsavel_pagamento)
    select household_id,v_destino,categoria,descricao,valor,responsavel_pagamento
    from public.despesas where household_id=v_household and data>=v_origem and data<v_destino;
  get diagnostics v_exp = row_count;
  insert into public.schultz_bank (household_id,data,descricao,valor)
    select household_id,v_destino,descricao,valor
    from public.schultz_bank where household_id=v_household and data>=v_origem and data<v_destino;
  get diagnostics v_sch = row_count;
  insert into public.sicredi_black (household_id,data,descricao,valor)
    select household_id,v_destino,descricao,valor
    from public.sicredi_black where household_id=v_household and data>=v_origem and data<v_destino;
  get diagnostics v_sic = row_count;

  return jsonb_build_object('origem',to_char(v_origem,'YYYY-MM'),'destino',to_char(v_destino,'YYYY-MM'),'despesas',v_exp,'schultz_bank',v_sch,'sicredi_black',v_sic,'total',v_exp+v_sch+v_sic);
end;
$$;

grant execute on function public.iniciar_mes_vazio(integer, integer) to authenticated;
grant execute on function public.clonar_mes_anterior(integer, integer) to authenticated;
