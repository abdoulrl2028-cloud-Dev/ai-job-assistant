create table public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  headline text,
  country text,
  city text,
  preferred_languages text[] not null default '{}',
  preferred_work_modes text[] not null default '{}',
  skills text[] not null default '{}',
  updated_at timestamptz not null default now()
);

create table public.job_sources (
  id text primary key,
  name text not null,
  homepage_url text not null,
  enabled boolean not null default true,
  last_synced_at timestamptz
);

insert into public.job_sources (id, name, homepage_url) values
  ('remotive', 'Remotive', 'https://remotive.com') on conflict do nothing;

create table public.companies (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  website_url text,
  logo_url text,
  unique (name)
);

create table public.jobs (
  id uuid primary key default gen_random_uuid(),
  source_id text not null references public.job_sources(id),
  external_id text not null,
  company_id uuid references public.companies(id),
  company_name text not null,
  title text not null,
  country text,
  city text,
  location text,
  work_mode text not null default 'remote' check (work_mode in ('remote', 'hybrid', 'onsite')),
  salary_text text,
  salary_min numeric,
  salary_max numeric,
  experience_level text,
  description text not null,
  requirements text,
  technologies text[] not null default '{}',
  languages text[] not null default '{}',
  source_url text not null,
  published_at timestamptz,
  expires_at timestamptz,
  synced_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (source_id, external_id)
);
create index jobs_search_idx on public.jobs (published_at desc);
create index jobs_work_mode_idx on public.jobs (work_mode, published_at desc);
create index jobs_company_idx on public.jobs (company_name);
alter table public.job_applications add column job_id uuid references public.jobs(id) on delete set null;

create table public.resumes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  file_name text not null,
  storage_path text not null unique,
  mime_type text not null check (mime_type in ('application/pdf', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')),
  file_size_bytes bigint not null check (file_size_bytes > 0 and file_size_bytes <= 10485760),
  extracted_text text,
  extracted_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.resume_analysis (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  resume_id uuid not null references public.resumes(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  provider text not null,
  estimated_match_percentage integer not null check (estimated_match_percentage between 0 and 100),
  result jsonb not null,
  created_at timestamptz not null default now(),
  unique (resume_id, job_id)
);

create table public.saved_jobs (
  user_id uuid not null references auth.users(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, job_id)
);

create table public.interviews (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  status text not null default 'in_progress' check (status in ('in_progress', 'completed', 'canceled')),
  provider text,
  technical_score integer check (technical_score between 0 and 100),
  communication_score integer check (communication_score between 0 and 100),
  overall_score integer check (overall_score between 0 and 100),
  feedback jsonb,
  created_at timestamptz not null default now(),
  completed_at timestamptz
);
create table public.interview_questions (
  id uuid primary key default gen_random_uuid(),
  interview_id uuid not null references public.interviews(id) on delete cascade,
  sequence integer not null,
  question text not null,
  unique (interview_id, sequence)
);
create table public.interview_answers (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.interview_questions(id) on delete cascade,
  answer_text text,
  audio_path text,
  evaluation jsonb,
  created_at timestamptz not null default now()
);
create table public.interview_reports (
  id uuid primary key default gen_random_uuid(),
  interview_id uuid not null unique references public.interviews(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  storage_path text,
  report jsonb not null,
  share_authorized_at timestamptz,
  created_at timestamptz not null default now()
);
create table public.messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  application_id uuid references public.job_applications(id) on delete set null,
  channel text not null check (channel in ('email', 'whatsapp')),
  recipient text not null,
  body text not null,
  status text not null default 'draft' check (status in ('draft', 'authorized', 'sent', 'delivered', 'failed', 'received')),
  sent_at timestamptz,
  created_at timestamptz not null default now()
);
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null,
  title text not null,
  body text not null,
  job_id uuid references public.jobs(id) on delete set null,
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create table public.audit_logs (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.job_sources enable row level security;
alter table public.companies enable row level security;
alter table public.jobs enable row level security;
alter table public.resumes enable row level security;
alter table public.resume_analysis enable row level security;
alter table public.saved_jobs enable row level security;
alter table public.interviews enable row level security;
alter table public.interview_questions enable row level security;
alter table public.interview_answers enable row level security;
alter table public.interview_reports enable row level security;
alter table public.messages enable row level security;
alter table public.notifications enable row level security;
alter table public.audit_logs enable row level security;

create policy "authenticated users read jobs" on public.jobs for select to authenticated using (expires_at is null or expires_at > now());
create policy "authenticated users read companies" on public.companies for select to authenticated using (true);
create policy "authenticated users read sources" on public.job_sources for select to authenticated using (enabled);
create policy "users manage own profile" on public.profiles for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "users manage own resumes" on public.resumes for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "users read own analyses" on public.resume_analysis for select using (auth.uid() = user_id);
create policy "users manage saved jobs" on public.saved_jobs for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "users manage interviews" on public.interviews for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "users read interview questions" on public.interview_questions for select using (exists (select 1 from public.interviews where id = interview_id and user_id = auth.uid()));
create policy "users manage interview answers" on public.interview_answers for all using (exists (select 1 from public.interview_questions q join public.interviews i on i.id = q.interview_id where q.id = question_id and i.user_id = auth.uid()));
create policy "users manage own reports" on public.interview_reports for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "users manage own messages" on public.messages for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "users manage own notifications" on public.notifications for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "users read own audit logs" on public.audit_logs for select using (auth.uid() = user_id);

alter publication supabase_realtime add table public.jobs;
alter publication supabase_realtime add table public.notifications;
alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.interviews;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('user-resumes', 'user-resumes', false, 10485760, array['application/pdf', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'])
on conflict (id) do nothing;
create policy "users upload own resumes" on storage.objects for insert to authenticated with check (bucket_id = 'user-resumes' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "users read own resumes" on storage.objects for select to authenticated using (bucket_id = 'user-resumes' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "users delete own resumes" on storage.objects for delete to authenticated using (bucket_id = 'user-resumes' and (storage.foldername(name))[1] = auth.uid()::text);