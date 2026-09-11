create extension if not exists pgcrypto;

create type public.subscription_status as enum ('free', 'active', 'past_due', 'canceled', 'incomplete');

create table public.job_applications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  company text not null,
  role text not null,
  status text not null default 'saved',
  created_at timestamptz not null default now()
);

create table public.plans (
  id text primary key,
  name text not null,
  monthly_price_cents integer not null check (monthly_price_cents >= 0),
  application_limit integer,
  features jsonb not null default '[]'::jsonb,
  active boolean not null default true
);

insert into public.plans (id, name, monthly_price_cents, application_limit, features) values
  ('free', 'Plano Gratis', 0, 5, '["Funcoes basicas", "Compatibilidade de vagas", "Mensagem para recrutador", "Acompanhamento de candidatura"]'),
  ('premium', 'Plano Premium', 1990, null, '["Mais candidaturas", "Alertas de novas vagas", "Filtros avancados", "Recursos de IA", "Analise de curriculo", "Mensagens para recrutadores"]'),
  ('pro', 'Plano Pro', 3990, null, '["Tudo do Premium", "IA para adaptar curriculo", "Compatibilidade com a vaga", "Candidatura automatica", "Relatorios de desempenho"]');

create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  plan_id text not null references public.plans(id),
  status public.subscription_status not null default 'free',
  stripe_customer_id text unique,
  stripe_subscription_id text unique,
  current_period_start timestamptz,
  current_period_end timestamptz,
  canceled_at timestamptz,
  updated_at timestamptz not null default now(),
  unique (user_id)
);

create table public.payment_webhook_events (
  provider_event_id text primary key,
  received_at timestamptz not null default now()
);

alter table public.plans enable row level security;
alter table public.job_applications enable row level security;
alter table public.subscriptions enable row level security;
alter table public.payment_webhook_events enable row level security;

create policy "plans are visible to everyone" on public.plans for select using (active = true);
create policy "users read their own applications" on public.job_applications for select using (auth.uid() = user_id);
create policy "users update their own applications" on public.job_applications for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "users delete their own applications" on public.job_applications for delete using (auth.uid() = user_id);
create policy "users read their own subscription" on public.subscriptions for select using (auth.uid() = user_id);

create or replace function public.can_use_premium_feature()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.subscriptions
    where user_id = auth.uid()
      and plan_id in ('premium', 'pro')
      and status = 'active'
      and (current_period_end is null or current_period_end > now())
  );
$$;

create or replace function public.can_create_application()
returns boolean language sql stable security definer set search_path = public as $$
  select public.can_use_premium_feature() or (
    select count(*) < coalesce((select application_limit from public.plans where id = 'free'), 5)
    from public.job_applications where user_id = auth.uid()
  );
$$;

create policy "free plan limits application creation" on public.job_applications
  for insert with check (auth.uid() = user_id and public.can_create_application());

grant execute on function public.can_use_premium_feature() to authenticated;
grant execute on function public.can_create_application() to authenticated;

alter publication supabase_realtime add table public.subscriptions;