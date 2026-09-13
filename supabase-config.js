/* Fruit Tank Academy — single public Supabase client configuration. */
(function(){
  const URL='https://yxhtshjxvlgswfjhxara.supabase.co';
  const KEY='sb_publishable_oLcXJtWtzj515ub8W-B4g_whX0nB6f';
  const OPTIONS={auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true,storageKey:'fruit-tank-academy-auth'}};
  window.FRUIT_TANK_SUPABASE={URL,KEY,OPTIONS,createClient:function(){
    if(!window.supabase||!window.supabase.createClient) throw new Error('Supabase JS client unavailable');
    if(!window.__fruitTankSupabaseClient) window.__fruitTankSupabaseClient=window.supabase.createClient(URL,KEY,OPTIONS);
    return window.__fruitTankSupabaseClient;
  }};
})();
