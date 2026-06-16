-- ════════════════════════════════════════════════════════════════
-- CASAL NO CONTROLE — SCHEMA COMPLETO
-- ════════════════════════════════════════════════════════════════
-- Execute este arquivo INTEIRO de uma vez no SQL Editor do seu
-- projeto Supabase (Painel -> SQL Editor -> New query -> cole tudo
-- -> Run).
--
-- Arquitetura: multi-tenant por "casa" (household).
-- Cada casal cria UMA conta de login (e-mail/senha) compartilhada
-- pelos dois parceiros. Essa conta vira automaticamente uma linha
-- em `households`, e dela nascem os dois perfis (titular/parceiro)
-- em `usuarios`. Todas as tabelas de dados carregam `household_id`,
-- e as Row Level Security Policies abaixo garantem que cada casal
-- só vê e edita os próprios dados — mesmo que o mesmo projeto
-- Supabase seja usado por vários casais ao mesmo tempo no futuro.
-- ════════════════════════════════════════════════════════════════

create extension if not exists "uuid-ossp";

-- ────────────────────────────────────────────────────────────────
-- HOUSEHOLDS — 1 linha por casal/conta (login único e compartilhado)
-- ────────────────────────────────────────────────────────────────
create table if not exists public.households (
  id            uuid primary key default uuid_generate_v4(),
  auth_user_id  uuid not null unique references auth.users(id) on delete cascade,
  nome          text not null default 'Nossa Casa',
  created_at    timestamptz not null default now()
);

comment on table public.households is 'Uma linha por casal. auth_user_id é a conta de login (única, compartilhada pelos dois parceiros).';

-- ────────────────────────────────────────────────────────────────
-- USUARIOS — os dois perfis de cada casa (titular e parceiro)
-- ────────────────────────────────────────────────────────────────
create table if not exists public.usuarios (
  id            uuid primary key default uuid_generate_v4(),
  household_id  uuid not null references public.households(id) on delete cascade,
  nome          text not null,
  perfil        text not null check (perfil in ('titular','parceiro')),
  created_at    timestamptz not null default now(),
  unique (household_id, perfil)
);

comment on table public.usuarios is 'titular = quem paga Schultz Bank e Sicredi Black integralmente. parceiro = quem reembolsa a cota e a metade do Sicredi Black.';

-- ────────────────────────────────────────────────────────────────
-- DESPESAS DO APARTAMENTO
-- ────────────────────────────────────────────────────────────────
create table if not exists public.despesas (
  id                      uuid primary key default uuid_generate_v4(),
  household_id            uuid not null references public.households(id) on delete cascade,
  data                    date not null,
  categoria               text not null default 'Apartamento',
  descricao               text not null,
  valor                   numeric(12,2) not null default 0,
  responsavel_pagamento   uuid references public.usuarios(id) on delete set null,
  created_at              timestamptz not null default now()
);

-- ────────────────────────────────────────────────────────────────
-- SCHULTZ BANK — pago integralmente pelo titular, entra inteiro no acerto
-- ────────────────────────────────────────────────────────────────
create table if not exists public.schultz_bank (
  id            uuid primary key default uuid_generate_v4(),
  household_id  uuid not null references public.households(id) on delete cascade,
  data          date not null,
  descricao     text not null,
  valor         numeric(12,2) not null default 0,
  created_at    timestamptz not null default now()
);

-- ────────────────────────────────────────────────────────────────
-- SICREDI BLACK — pago pelo titular, só a metade entra no acerto
-- ────────────────────────────────────────────────────────────────
create table if not exists public.sicredi_black (
  id            uuid primary key default uuid_generate_v4(),
  household_id  uuid not null references public.households(id) on delete cascade,
  data          date not null,
  descricao     text not null,
  valor         numeric(12,2) not null default 0,
  created_at    timestamptz not null default now()
);

-- ────────────────────────────────────────────────────────────────
-- HISTÓRICO MENSAL — totais agregados de anos anteriores (2022-2025),
-- usado pelas Crônicas junto com os totais calculados em tempo real
-- a partir de despesas/schultz_bank/sicredi_black do ano corrente.
-- ────────────────────────────────────────────────────────────────
create table if not exists public.historico_mensal (
  id            uuid primary key default uuid_generate_v4(),
  household_id  uuid not null references public.households(id) on delete cascade,
  ano           int not null,
  mes           int not null check (mes between 1 and 12),
  total         numeric(12,2) not null default 0,
  created_at    timestamptz not null default now(),
  unique (household_id, ano, mes)
);

-- ────────────────────────────────────────────────────────────────
-- INVESTIMENTOS
-- ────────────────────────────────────────────────────────────────
create table if not exists public.investimentos (
  id                uuid primary key default uuid_generate_v4(),
  household_id      uuid not null references public.households(id) on delete cascade,
  instituicao       text,
  ativo             text not null,
  categoria         text not null,
  valor             numeric(12,2) not null default 0,
  data_referencia   date not null default current_date,
  created_at        timestamptz not null default now()
);

-- ────────────────────────────────────────────────────────────────
-- METAS FINANCEIRAS
-- ────────────────────────────────────────────────────────────────
create table if not exists public.metas_financeiras (
  id            uuid primary key default uuid_generate_v4(),
  household_id  uuid not null references public.households(id) on delete cascade,
  descricao     text not null,
  valor_meta    numeric(12,2) not null default 0,
  valor_atual   numeric(12,2) not null default 0,
  prazo         date,
  created_at    timestamptz not null default now()
);

-- ════════════════════════════════════════════════════════════════
-- HELPER — devolve o household_id do usuário autenticado atual
-- ════════════════════════════════════════════════════════════════
create or replace function public.current_household_id()
returns uuid
language sql
security definer
stable
as $$
  select id from public.households where auth_user_id = auth.uid();
$$;

-- ════════════════════════════════════════════════════════════════
-- TRIGGER — ao criar a conta (signUp), monta a casa automaticamente
-- usando os metadados enviados no cadastro (nome_casa, titular_nome,
-- parceiro_nome). O usuário só preenche o formulário; o resto é
-- automático.
-- ════════════════════════════════════════════════════════════════
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

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ════════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY
-- ════════════════════════════════════════════════════════════════
alter table public.households          enable row level security;
alter table public.usuarios            enable row level security;
alter table public.despesas            enable row level security;
alter table public.schultz_bank        enable row level security;
alter table public.sicredi_black       enable row level security;
alter table public.historico_mensal    enable row level security;
alter table public.investimentos       enable row level security;
alter table public.metas_financeiras   enable row level security;

-- households: cada casal só vê/edita a própria linha
create policy "households_select_own" on public.households
  for select using (auth_user_id = auth.uid());

create policy "households_update_own" on public.households
  for update using (auth_user_id = auth.uid());

-- demais tabelas: tudo escopado pelo household_id da conta logada
create policy "usuarios_all_own" on public.usuarios
  for all using (household_id = public.current_household_id())
  with check (household_id = public.current_household_id());

create policy "despesas_all_own" on public.despesas
  for all using (household_id = public.current_household_id())
  with check (household_id = public.current_household_id());

create policy "schultz_all_own" on public.schultz_bank
  for all using (household_id = public.current_household_id())
  with check (household_id = public.current_household_id());

create policy "sicredi_all_own" on public.sicredi_black
  for all using (household_id = public.current_household_id())
  with check (household_id = public.current_household_id());

create policy "historico_all_own" on public.historico_mensal
  for all using (household_id = public.current_household_id())
  with check (household_id = public.current_household_id());

create policy "investimentos_all_own" on public.investimentos
  for all using (household_id = public.current_household_id())
  with check (household_id = public.current_household_id());

create policy "metas_all_own" on public.metas_financeiras
  for all using (household_id = public.current_household_id())
  with check (household_id = public.current_household_id());
