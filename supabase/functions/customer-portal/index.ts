import Stripe from 'npm:stripe@17.7.0';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, { apiVersion: '2024-12-18.acacia' });

Deno.serve(async (request) => {
  const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: request.headers.get('Authorization') ?? '' } },
  });
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return Response.json({ error: 'Unauthorized' }, { status: 401 });
  const { data: subscription } = await supabase.from('subscriptions').select('stripe_customer_id').eq('user_id', user.id).maybeSingle();
  if (!subscription?.stripe_customer_id) return Response.json({ error: 'No active billing customer' }, { status: 404 });
  const session = await stripe.billingPortal.sessions.create({ customer: subscription.stripe_customer_id, return_url: Deno.env.get('APP_URL')! });
  return Response.json({ portalUrl: session.url });
});