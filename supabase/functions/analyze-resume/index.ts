import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

type AnalysisResult = {
  estimated_match_percentage: number;
  skills_found: string[];
  skills_missing: string[];
  relevant_experience: string[];
  strengths: string[];
  weaknesses: string[];
  missing_keywords: string[];
  suggestions: string[];
  disclaimer: string;
};

const corsHeaders = {
  'Access-Control-Allow-Headers': 'authorization, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Content-Type': 'application/json',
};

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response(null, { headers: corsHeaders });
  if (request.method !== 'POST') return Response.json({ error: 'Method not allowed' }, { status: 405, headers: corsHeaders });

  const userClient = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: request.headers.get('Authorization') ?? '' } },
  });
  const adminClient = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  const { data: { user } } = await userClient.auth.getUser();
  if (!user) return Response.json({ error: 'Unauthorized' }, { status: 401, headers: corsHeaders });

  const { resumeId, jobId } = await request.json();
  if (typeof resumeId !== 'string' || typeof jobId !== 'string') {
    return Response.json({ error: 'resumeId and jobId are required' }, { status: 400, headers: corsHeaders });
  }

  const [{ data: resume }, { data: job }] = await Promise.all([
    adminClient.from('resumes').select('id, user_id, extracted_text, extracted_data').eq('id', resumeId).eq('user_id', user.id).maybeSingle(),
    adminClient.from('jobs').select('id, title, company_name, description, requirements, technologies').eq('id', jobId).maybeSingle(),
  ]);
  if (!resume || !job) return Response.json({ error: 'Resume or job not found' }, { status: 404, headers: corsHeaders });

  const apiKey = Deno.env.get('AI_PROVIDER_API_KEY');
  const baseUrl = Deno.env.get('AI_BASE_URL');
  const model = Deno.env.get('AI_MODEL');
  if (!apiKey || !baseUrl || !model) return Response.json({ error: 'AI provider is not configured' }, { status: 503, headers: corsHeaders });

  const prompt = JSON.stringify({ resume: resume.extracted_text ?? resume.extracted_data, job: { title: job.title, company: job.company_name, description: job.description, requirements: job.requirements, technologies: job.technologies } });
  const providerResponse = await fetch(`${baseUrl.replace(/\/$/, '')}/chat/completions`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ model, temperature: 0.1, response_format: { type: 'json_object' }, messages: [
      { role: 'system', content: 'Compare um CV e uma vaga. Responda apenas JSON com estimated_match_percentage (0-100), skills_found, skills_missing, relevant_experience, strengths, weaknesses, missing_keywords e suggestions, todos arrays de strings quando aplicavel. Inclua o campo disclaimer com: Esta e uma compatibilidade estimada, nao uma previsao de contratacao.' },
      { role: 'user', content: prompt },
    ] }),
  });
  if (!providerResponse.ok) return Response.json({ error: 'AI provider unavailable' }, { status: 502, headers: corsHeaders });

  const providerPayload = await providerResponse.json();
  const content = providerPayload.choices?.[0]?.message?.content;
  let result: AnalysisResult;
  try {
    result = JSON.parse(content) as AnalysisResult;
  } catch (_) {
    return Response.json({ error: 'AI provider returned invalid analysis' }, { status: 502, headers: corsHeaders });
  }
  result.disclaimer = 'Esta e uma compatibilidade estimada, nao uma previsao de contratacao.';

  const { data: saved, error } = await adminClient.from('resume_analysis').upsert({
    user_id: user.id,
    resume_id: resumeId,
    job_id: jobId,
    provider: model,
    estimated_match_percentage: Math.max(0, Math.min(100, Number(result.estimated_match_percentage) || 0)),
    result,
  }, { onConflict: 'resume_id,job_id' }).select().single();
  if (error) return Response.json({ error: 'Unable to save analysis' }, { status: 500, headers: corsHeaders });
  return Response.json(saved, { headers: corsHeaders });
});