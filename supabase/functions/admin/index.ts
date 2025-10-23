// Edge Function: admin
// Privileged operations using service role without exposing credentials to clients.
// - Validates authenticated user and requires `user.user_metadata.is_admin === true`.
// - Consolidates business rules for status updates.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!; // used only to validate the caller's JWT
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!; // used for privileged DB ops

const ALLOWED_STATUSES = new Set([
  'pending',
  'awaiting_approval',
  'awaiting_payment',
  'in_progress',
  'completed',
  'cancelled',
]);

// Allowed transitions business rule
const ALLOWED_TRANSITIONS: Record<string, string[]> = {
  pending: ['awaiting_approval', 'awaiting_payment', 'in_progress', 'cancelled'],
  awaiting_approval: ['awaiting_payment', 'in_progress', 'cancelled'],
  awaiting_payment: ['in_progress', 'completed', 'cancelled'],
  in_progress: ['completed', 'cancelled'],
  completed: ['cancelled'],
  cancelled: [],
};

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json; charset=utf-8' },
  });
}

async function getAuthenticatedUser(req: Request) {
  const authHeader = req.headers.get('Authorization') || '';
  if (!authHeader.startsWith('Bearer ')) {
    return { user: null, error: 'Missing Bearer token' };
  }
  const authClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data, error } = await authClient.auth.getUser();
  return { user: data?.user ?? null, error: error?.message ?? null };
}

async function updateOrderStatus(orderId: string, targetStatus: string, actorUserId: string) {
  const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  // Fetch current status
  const { data: currentRow, error: fetchErr } = await adminClient
    .from('service_orders')
    .select('id,status')
    .eq('id', orderId)
    .maybeSingle();
  if (fetchErr) return { error: `Erro ao buscar ordem: ${fetchErr.message}` };
  if (!currentRow) return { error: 'Ordem não encontrada' };

  const currentStatus = (currentRow.status as string) ?? 'pending';
  if (!ALLOWED_STATUSES.has(targetStatus)) {
    return { error: 'Status inválido' };
  }
  const allowed = ALLOWED_TRANSITIONS[currentStatus] ?? [];
  if (!allowed.includes(targetStatus) && currentStatus !== targetStatus) {
    return { error: `Transição de '${currentStatus}' para '${targetStatus}' não permitida` };
  }

  const { data: updated, error: updErr } = await adminClient
    .from('service_orders')
    .update({ status: targetStatus })
    .eq('id', orderId)
    .select('id,status,updated_at')
    .maybeSingle();

  if (updErr) return { error: `Erro ao atualizar status: ${updErr.message}` };

  // Insert audit log (best-effort, does not block main result)
  await adminClient.from('order_status_audit').insert({
    order_id: orderId,
    user_id: actorUserId,
    old_status: currentStatus,
    new_status: targetStatus,
    source: 'admin_function',
  });

  return { data: updated };
}

Deno.serve(async (req) => {
  try {
    if (req.method === 'GET') {
      // Health check
      return jsonResponse({ ok: true, service: 'admin', time: new Date().toISOString() });
    }

    if (req.method !== 'POST') {
      return jsonResponse({ error: 'Método não suportado' }, 405);
    }

    const { user, error: authError } = await getAuthenticatedUser(req);
    if (!user || authError) {
      return jsonResponse({ error: 'Não autenticado' }, 401);
    }

    const isAdmin = user.user_metadata?.is_admin === true;
    if (!isAdmin) {
      return jsonResponse({ error: 'Acesso negado: requer admin' }, 403);
    }

    const body = await req.json().catch(() => ({}));
    const action = (body?.action ?? '').toString();

    if (action === 'update_status') {
      const orderId = (body?.order_id ?? '').toString();
      const status = (body?.status ?? '').toString();
      if (!orderId || !status) {
        return jsonResponse({ error: 'Parâmetros ausentes: order_id, status' }, 400);
      }
      const result = await updateOrderStatus(orderId, status, user.id);
      if (result.error) return jsonResponse({ error: result.error }, 400);
      return jsonResponse({ ok: true, order: result.data });
    }

    return jsonResponse({ error: 'Ação desconhecida' }, 400);
  } catch (err) {
    return jsonResponse({ error: `Falha interna: ${err?.message ?? err}` }, 500);
  }
});