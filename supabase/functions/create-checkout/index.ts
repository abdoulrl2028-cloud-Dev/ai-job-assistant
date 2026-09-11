import Stripe from 'npm:stripe@17.7.0';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, { apiVersion: '2024-12-18.acacia' });

Deno.serve(async (request) => {
  const authorization = request.headers.get('Authorization');
  const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: authorization ?? '' } },
  });
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return Response.json({ error: 'Unauthorized' }, { status: 401 });

  const { planId } = await request.json();
  if (!['premium', 'pro'].includes(planId)) return Response.json({ error: 'Invalid plan' }, { status: 400 });

  const priceId = Deno.env.get(planId === 'premium' ? 'STRIPE_PRICE_PREMIUM' : 'STRIPE_PRICE_PRO');
  if (!priceId) return Response.json({ error: 'Plan is not configured' }, { status: 503 });

  const appUrl = Deno.env.get('APP_URL')!;
  const session = await stripe.checkout.sessions.create({
    mode: 'subscription',
    payment_method_types: ['card'],
    line_items: [{ price: priceId, quantity: 1 }],
    client_reference_id: user.id,
    customer_email: user.email,
    subscription_data: { metadata: { user_id: user.id, plan_id: planId } },
    success_url: `${appUrl}/?checkout=success`,
    cancel_url: `${appUrl}/?checkout=cancelled`,
  });
  return Response.json({ checkoutUrl: session.url });
});