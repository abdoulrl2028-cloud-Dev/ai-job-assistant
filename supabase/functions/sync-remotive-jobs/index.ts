import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const admin = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
const allowedOrigins = new Set([Deno.env.get('APP_URL'), 'http://localhost:8080'].filter(Boolean));

Deno.serve(async (request) => {
  const origin = request.headers.get('origin') ?? '';
  const headers = { 'Content-Type': 'application/json', ...(allowedOrigins.has(origin) ? { 'Access-Control-Allow-Origin': origin, Vary: 'Origin' } : {}) };
  if (request.method === 'OPTIONS') return new Response(null, { headers: { ...headers, 'Access-Control-Allow-Headers': 'authorization, x-sync-secret', 'Access-Control-Allow-Methods': 'POST, OPTIONS' } });
  if (request.method !== 'POST' || request.headers.get('x-sync-secret') !== Deno.env.get('JOB_SYNC_SECRET')) return new Response('Unauthorized', { status: 401, headers });

  const response = await fetch('https://remotive.com/api/remote-jobs?limit=100', { headers: { Accept: 'application/json' } });
  if (!response.ok) return new Response('Upstream job source unavailable', { status: 502, headers });
  const payload = await response.json();
  const jobs = (payload.jobs as Array<Record<string, unknown>>).map((job) => ({
    source_id: 'remotive', external_id: String(job.id), company_name: String(job.company_name ?? 'Unknown'), title: String(job.title ?? ''),
    country: null, city: null, location: String(job.candidate_required_location ?? 'Remote'), work_mode: 'remote', salary_text: job.salary ? String(job.salary) : null,
    salary_min: null, salary_max: null, experience_level: job.category ? String(job.category) : null,
    description: String(job.description ?? ''), requirements: String(job.description ?? ''), technologies: [], languages: [],
    source_url: String(job.url), published_at: job.publication_date ? new Date(String(job.publication_date)).toISOString() : null, synced_at: new Date().toISOString(),
  })).filter((job) => job.title && job.source_url);
  const { error } = await admin.from('jobs').upsert(jobs, { onConflict: 'source_id,external_id' });
  if (error) return new Response('Unable to save jobs', { status: 500, headers });
  await admin.from('job_sources').update({ last_synced_at: new Date().toISOString() }).eq('id', 'remotive');
  return Response.json({ synchronized: jobs.length }, { headers });
});