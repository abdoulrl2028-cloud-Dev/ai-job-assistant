import Stripe from 'npm:stripe@17.7.0';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, { apiVersion: '2024-12-18.acacia' });
const admin = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);

Deno.serve(async (request) => {
  const signature = request.headers.get('stripe-signature');
  if (!signature) return new Response('Missing signature', { status: 400 });

  let event: Stripe.Event;
  try {
    event = await stripe.webhooks.constructEventAsync(await request.text(), signature, Deno.env.get('STRIPE_WEBHOOK_SECRET')!);
  } catch (_) {
    return new Response('Invalid signature', { status: 400 });
  }

  const { error: duplicateError } = await admin.from('payment_webhook_events').insert({ provider_event_id: event.id });
  if (duplicateError?.code === '23505') return new Response('Already processed');
  if (duplicateError) return new Response('Unable to record event', { status: 500 });

  if (event.type.startsWith('customer.subscription.')) {
    const subscription = event.data.object as Stripe.Subscription;
    const userId = subscription.metadata.user_id;
    const planId = subscription.metadata.plan_id;
    if (!userId || !planId) return new Response('Subscription metadata missing', { status: 400 });

    const status = subscription.status === 'active' || subscription.status === 'trialing'
      ? 'active'
      : subscription.status === 'past_due' ? 'past_due'
      : subscription.status === 'canceled' ? 'canceled' : 'incomplete';
    const { error } = await admin.from('subscriptions').upsert({
      user_id: userId,
      plan_id: planId,
      status,
      stripe_customer_id: String(subscription.customer),
      stripe_subscription_id: subscription.id,
      current_period_start: new Date(subscription.current_period_start * 1000).toISOString(),
      current_period_end: new Date(subscription.current_period_end * 1000).toISOString(),
      canceled_at: subscription.canceled_at ? new Date(subscription.canceled_at * 1000).toISOString() : null,
      updated_at: new Date().toISOString(),
    }, { onConflict: 'user_id' });
    if (error) return new Response('Unable to update subscription', { status: 500 });
  }
  return new Response('OK');
});