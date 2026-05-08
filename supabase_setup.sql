-- =============================================
-- NovaCRM — Setup do banco de dados Supabase
-- Execute este SQL no SQL Editor do Supabase
-- =============================================

-- TABELA: contatos
create table public.contacts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  name text not null,
  company text,
  email text,
  phone text,
  status text default 'Lead',
  created_at timestamptz default now()
);

-- TABELA: negócios (pipeline)
create table public.deals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  name text not null,
  contact_name text,
  value numeric default 0,
  stage text default 'Prospecção',
  created_at timestamptz default now()
);

-- TABELA: tarefas
create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  title text not null,
  due_date text,
  done boolean default false,
  created_at timestamptz default now()
);

-- =============================================
-- SEGURANÇA: Row Level Security (RLS)
-- Cada usuário só acessa seus próprios dados
-- =============================================

alter table public.contacts enable row level security;
alter table public.deals    enable row level security;
alter table public.tasks    enable row level security;

-- Políticas para contacts
create policy "contacts_select" on public.contacts for select using (auth.uid() = user_id);
create policy "contacts_insert" on public.contacts for insert with check (auth.uid() = user_id);
create policy "contacts_update" on public.contacts for update using (auth.uid() = user_id);
create policy "contacts_delete" on public.contacts for delete using (auth.uid() = user_id);

-- Políticas para deals
create policy "deals_select" on public.deals for select using (auth.uid() = user_id);
create policy "deals_insert" on public.deals for insert with check (auth.uid() = user_id);
create policy "deals_update" on public.deals for update using (auth.uid() = user_id);
create policy "deals_delete" on public.deals for delete using (auth.uid() = user_id);

-- Políticas para tasks
create policy "tasks_select" on public.tasks for select using (auth.uid() = user_id);
create policy "tasks_insert" on public.tasks for insert with check (auth.uid() = user_id);
create policy "tasks_update" on public.tasks for update using (auth.uid() = user_id);
create policy "tasks_delete" on public.tasks for delete using (auth.uid() = user_id);

-- =============================================
-- Pronto! Agora configure o index.html com
-- sua URL e chave do Supabase.
-- =============================================
