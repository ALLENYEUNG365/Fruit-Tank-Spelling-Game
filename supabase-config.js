/* Fruit Tank Academy — single public Supabase client configuration. */
(function(){
  const URL='https://yxhtshjxvlgswfjhxara.supabase.co';
  // Use the same legacy anon key already proven compatible with browser Auth/RPC.
  // This is a public browser key; RLS remains the security boundary.
  const KEY='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl4aHRzaGp4dmxnc3dmamh4YXJhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU3MjE2MjMsImV4cCI6MjA4MTI5NzYyM30.J4kpzCZkKiU4E0wFHxBgmBr-mKGD6MF9AGS8nTJKDM4';
  const OPTIONS={auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true,storageKey:'fruit-tank-academy-auth'}};
  window.FRUIT_TANK_SUPABASE={URL,KEY,OPTIONS,createClient:function(){
    if(!window.supabase||!window.supabase.createClient) throw new Error('Supabase JS client unavailable');
    if(!window.__fruitTankSupabaseClient) window.__fruitTankSupabaseClient=window.supabase.createClient(URL,KEY,OPTIONS);
    return window.__fruitTankSupabaseClient;
  }};
})();
