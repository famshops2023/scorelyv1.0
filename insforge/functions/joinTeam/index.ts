import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type' } })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    const { team_id, profile_id } = await req.json()

    // 1. Verify team exists
    const { data: team, error: teamError } = await supabase
      .from('teams')
      .select('id')
      .eq('id', team_id)
      .single()

    if (teamError || !team) throw new Error('Team not found or link expired')

    // Optional user ID fallback from body if not using Auth headers strictly
    // but ideally we should use the authenticated user's ID
    let userId = profile_id;
    if (!userId) {
      const { data: { user }, error: userError } = await supabase.auth.getUser()
      if (userError || !user) throw new Error('Unauthorized')
      userId = user.id;
    }

    // 2. Check if already joined
    const { data: existingPlayer } = await supabase
      .from('players')
      .select('id')
      .eq('team_id', team_id)
      .eq('profile_id', userId)
      .maybeSingle()

    if (existingPlayer) {
      return new Response(JSON.stringify({ success: true, message: 'Already a member' }), {
        headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
        status: 200,
      })
    }

    // 3. Insert into players table
    const { error: insertError } = await supabase
      .from('players')
      .insert([{ team_id: team_id, profile_id: userId }])

    if (insertError) throw insertError

    return new Response(JSON.stringify({ success: true, message: 'Successfully joined team' }), {
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
      status: 200,
    })

  } catch (err) {
    return new Response(JSON.stringify({ error: err instanceof Error ? err.message : 'Unknown error' }), {
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
      status: 400,
    })
  }
})
