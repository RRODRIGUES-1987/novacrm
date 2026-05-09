-- =============================================
-- NovaCRM — Multi-empresa
-- Execute no SQL Editor do Supabase
-- =============================================

-- TABELA: empresas
create table public.companies (
  id uuid primary key default gen_random_uuid(),
  cnpj text not null unique,
  name text not null,
  created_by uuid references auth.users(id),
  created_at timestamptz default now()
);

-- TABELA: perfis de usuário
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  email text,
  role text not null default 'vendedor', -- 'admin', 'gestor', 'vendedor'
  company_id uuid references public.companies(id),
  created_at timestamptz default now()
);

-- Atualiza tabelas existentes para incluir company_id e owner_id
alter table public.contacts add column if not exists company_id uuid references public.companies(id);
alter table public.contacts add column if not exists owner_id uuid references auth.users(id);

alter table public.deals add column if not exists company_id uuid references public.companies(id);
alter table public.deals add column if not exists owner_id uuid references auth.users(id);

alter table public.tasks add column if not exists company_id uuid references public.companies(id);
alter table public.tasks add column if not exists owner_id uuid references auth.users(id);

-- =============================================
-- RLS — companies
-- =============================================
alter table public.companies enable row level security;
alter table public.profiles enable row level security;

-- Qualquer autenticado pode ler empresas
create policy "companies_select" on public.companies
  for select using (auth.uid() is not null);

-- Só admin pode criar/editar empresas
create policy "companies_insert" on public.companies
  for insert with check (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

create policy "companies_update" on public.companies
  for update using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

create policy "companies_delete" on public.companies
  for delete using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- =============================================
-- RLS — profiles
-- =============================================

-- Admin vê todos; gestor vê sua empresa; vendedor vê só o próprio
create policy "profiles_select" on public.profiles
  for select using (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
    or
    (
      exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'gestor')
      and company_id = (select company_id from public.profiles where id = auth.uid())
    )
    or id = auth.uid()
  );

-- Só admin pode inserir/editar perfis
create policy "profiles_insert" on public.profiles
  for insert with check (
    id = auth.uid()
    or exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

create policy "profiles_update" on public.profiles
  for update using (
    id = auth.uid()
    or exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

create policy "profiles_delete" on public.profiles
  for delete using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- =============================================
-- RLS — contacts
-- =============================================
drop policy if exists "contacts_select" on public.contacts;
drop policy if exists "contacts_insert" on public.contacts;
drop policy if exists "contacts_update" on public.contacts;
drop policy if exists "contacts_delete" on public.contacts;

create policy "contacts_select" on public.contacts
  for select using (
    -- admin vê tudo
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
    or
    -- gestor vê sua empresa
    (
      exists (select 1 from public.profiles where id = auth.uid() and role = 'gestor')
      and company_id = (select company_id from public.profiles where id = auth.uid())
    )
    or
    -- vendedor vê só os seus
    owner_id = auth.uid()
  );

create policy "contacts_insert" on public.contacts
  for insert with check (
    owner_id = auth.uid()
    and company_id = (select company_id from public.profiles where id = auth.uid())
  );

create policy "contacts_update" on public.contacts
  for update using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
    or exists (select 1 from public.profiles where id = auth.uid() and role = 'gestor' and company_id = (select company_id from public.profiles where id = auth.uid()))
    or owner_id = auth.uid()
  );

create policy "contacts_delete" on public.contacts
  for delete using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
    or owner_id = auth.uid()
  );

-- =============================================
-- RLS — deals
-- =============================================
drop policy if exists "deals_select" on public.deals;
drop policy if exists "deals_insert" on public.deals;
drop policy if exists "deals_update" on public.deals;
drop policy if exists "deals_delete" on public.deals;

create policy "deals_select" on public.deals
  for select using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
    or (exists (select 1 from public.profiles where id = auth.uid() and role = 'gestor') and company_id = (select company_id from public.profiles where id = auth.uid()))
    or owner_id = auth.uid()
  );

create policy "deals_insert" on public.deals
  for insert with check (owner_id = auth.uid() and company_id = (select company_id from public.profiles where id = auth.uid()));

create policy "deals_update" on public.deals
  for update using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
    or exists (select 1 from public.profiles where id = auth.uid() and role = 'gestor' and company_id = (select company_id from public.profiles where id = auth.uid()))
    or owner_id = auth.uid()
  );

create policy "deals_delete" on public.deals
  for delete using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
    or owner_id = auth.uid()
  );

-- =============================================
-- RLS — tasks
-- =============================================
drop policy if exists "tasks_select" on public.tasks;
drop policy if exists "tasks_insert" on public.tasks;
drop policy if exists "tasks_update" on public.tasks;
drop policy if exists "tasks_delete" on public.tasks;

create policy "tasks_select" on public.tasks
  for select using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
    or (exists (select 1 from public.profiles where id = auth.uid() and role = 'gestor') and company_id = (select company_id from public.profiles where id = auth.uid()))
    or owner_id = auth.uid()
  );

create policy "tasks_insert" on public.tasks
  for insert with check (owner_id = auth.uid() and company_id = (select company_id from public.profiles where id = auth.uid()));

create policy "tasks_update" on public.tasks
  for update using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
    or exists (select 1 from public.profiles where id = auth.uid() and role = 'gestor' and company_id = (select company_id from public.profiles where id = auth.uid()))
    or owner_id = auth.uid()
  );

create policy "tasks_delete" on public.tasks
  for delete using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
    or owner_id = auth.uid()
  );

-- =============================================
-- FUNÇÃO: promover primeiro usuário a admin
-- Execute após criar sua conta
-- Substitua 'seu@email.com' pelo seu email
-- =============================================
-- update public.profiles set role = 'admin' where email = 'seu@email.com';
