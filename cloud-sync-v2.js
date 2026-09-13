/* Fruit Tank Academy — non-blocking cloud sync bridge. */
(function(){
  const frame=document.getElementById('gameFrame');
  const sb=window.supabaseClientForFruitTank||null;
  const SUPABASE_URL='https://yxhtshjxvlgswfjhxara.supabase.co';
  const SUPABASE_KEY='sb_publishable_oLcXJtWtzj515ub8W-B4g_whX0nB6f';
  const client=sb||(window.supabase&&window.supabase.createClient?window.supabase.createClient(SUPABASE_URL,SUPABASE_KEY,{auth:{persistSession:true,autoRefreshToken:true}}):null);
  window.supabaseClientForFruitTank=client;
  let installed=false;
  const bridge=`
  (function(){
    if(window.__fruitTankCloudInstalled)return; window.__fruitTankCloudInstalled=true;
    const cloud=window.parent.supabaseClientForFruitTank;
    let currentSessionId=null;
    let sessionReady=Promise.resolve(null);
    const OUTBOX='fruitTankAttemptOutbox';
    const readOutbox=()=>{try{return JSON.parse(localStorage.getItem(OUTBOX)||'[]')}catch(e){return[]}};
    const writeOutbox=v=>{try{localStorage.setItem(OUTBOX,JSON.stringify(v.slice(-200)))}catch(e){}};
    let flushing=false,lastProfileSync=0,flushTimer=null;
    const withTimeout=(promise,ms)=>Promise.race([promise,new Promise((_,reject)=>setTimeout(()=>reject(new Error('cloud request timeout')),ms))]);
    function scheduleFlush(delay=1500){if(flushTimer)return;flushTimer=setTimeout(()=>{flushTimer=null;flushAttempts()},delay)}
    function enqueueAttempt(payload){const q=readOutbox();q.push(payload);writeOutbox(q);scheduleFlush(250)}
    async function flushAttempts(){
      if(flushing||!cloud||typeof profile==='undefined'||!profile.__cloudUserId)return;
      flushing=true;
      try{let q=readOutbox();while(q.length){const p=q[0];const {error}=await withTimeout(cloud.rpc('record_my_word_attempt',p),5000);if(error)throw error;q.shift();writeOutbox(q)}}catch(e){console.warn('[FruitTank Cloud] attempt outbox',e);scheduleFlush(10000)}finally{flushing=false}
    }
    async function syncProfile(force=false){
      const now=Date.now();if(!force&&now-lastProfileSync<30000)return;
      if(!cloud||typeof profile==='undefined'||!profile.__cloudUserId)return;lastProfileSync=now;
      try{await withTimeout(cloud.rpc('sync_my_learning',{p_xp:Number(profile.xp||0),p_level:Number(profile.level||1),p_streak:Number(profile.streak||0),p_total_words:Number(profile.totalWords||0),p_correct_attempts:Number(profile.correct||0),p_total_shots:Number(profile.shots||0)}),5000)}catch(e){console.warn('[FruitTank Cloud] profile sync',e)}
    }
    async function startSession(){
      if(!cloud||typeof profile==='undefined'||!profile.__cloudUserId)return null;
      try{const w=typeof world==='function'?world():{id:'orchard'};const mode=document.getElementById('difficulty')?.value||'Normal';const {data,error}=await withTimeout(cloud.rpc('start_my_session',{p_world:String(w.id),p_mode:String(mode)}),5000);if(error)throw error;currentSessionId=data||null;return currentSessionId}catch(e){console.warn('[FruitTank Cloud] session start',e);return null}
    }
    function recordAttempt(word,target,selected,isCorrect){
      if(!cloud||typeof profile==='undefined'||!profile.__cloudUserId||!word||!target||!selected)return;
      Promise.resolve(sessionReady).then(sid=>{const w=typeof world==='function'?world().id:'orchard';enqueueAttempt({p_session_id:sid||null,p_word:String(word),p_target_letter:String(target),p_selected_letter:String(selected),p_is_correct:Boolean(isCorrect),p_world:String(w)})}).catch(e=>console.warn('[FruitTank Cloud] attempt queue',e));
    }
    function saveWord(word){if(!cloud||!word||typeof profile==='undefined'||!profile.__cloudUserId)return;setTimeout(async()=>{try{const worldName=typeof world==='function'?world().id:'orchard';const {error}=await withTimeout(cloud.rpc('record_my_word_progress',{p_word:String(word),p_world:String(worldName)}),5000);if(error)throw error}catch(e){console.warn('[FruitTank Cloud] word sync',e)}},0)}
    function saveDaily(){if(!cloud||typeof profile==='undefined'||!profile.__cloudUserId)return;setTimeout(async()=>{try{const {error}=await withTimeout(cloud.rpc('complete_my_daily_quest'),5000);if(error)throw error}catch(e){console.warn('[FruitTank Cloud] daily sync',e)}},0)}
    function saveSession(){const sid=currentSessionId;if(!cloud||typeof profile==='undefined'||!sid)return;Promise.resolve(sessionReady).then(()=>flushAttempts()).then(()=>withTimeout(cloud.rpc('finish_my_session',{p_session_id:sid}),5000)).then(()=>syncProfile(true)).then(()=>saveDaily()).catch(e=>console.warn('[FruitTank Cloud] session sync',e)).finally(()=>{currentSessionId=null;sessionReady=Promise.resolve(null)})}
    async function bootstrap(){try{const {data:{user}}=await withTimeout(cloud.auth.getUser(),5000);if(!user)return;if(typeof profile!=='undefined')profile.__cloudUserId=user.id;syncProfile(true);scheduleFlush(500)}catch(e){console.warn('[FruitTank Cloud] bootstrap',e)}}
    const originalStart=startGame;startGame=function(){originalStart();sessionReady=startSession();syncProfile(false)};
    const originalComplete=completeWord;completeWord=function(){const completedWord=typeof state!=='undefined'?state.word:'';originalComplete();if(completedWord)saveWord(completedWord);saveDaily();syncProfile(false);scheduleFlush(500)};
    const originalFinish=finish;finish=function(won){originalFinish(won);saveSession()};
    const originalAddXP=addXP;addXP=function(n){try{if(typeof state!=='undefined'&&state.running&&state.word){const expected=state.word[state.index];if(expected)recordAttempt(state.word,expected,expected,true)}}catch(e){console.warn('[FruitTank Cloud] correct attempt hook',e)}return originalAddXP(n)};
    const originalToast=toast;toast=function(t,ms){try{const text=String(t||''),m=text.match(/^TRY AGAIN · REVIEW\\s+([A-Z])$/i);if(m&&typeof state!=='undefined'&&state.running&&state.word){const expected=state.word[state.index];if(expected)recordAttempt(state.word,expected,m[1],false)}}catch(e){console.warn('[FruitTank Cloud] wrong attempt hook',e)}return originalToast(t,ms)};
    window.addEventListener('online',()=>{syncProfile(true);scheduleFlush(0)});
    setInterval(()=>{if(typeof state!=='undefined'&&state.running)syncProfile(false);scheduleFlush(0)},30000);
    bootstrap();
  })();`;
  function install(){if(installed||!frame.contentWindow)return;try{frame.contentWindow.eval(bridge);installed=true;console.log('[FruitTank Cloud] sync installed')}catch(e){console.warn('[FruitTank Cloud] install failed',e)}}
  frame.addEventListener('load',()=>setTimeout(install,50));
  const timer=setInterval(()=>{if(!installed)install();else clearInterval(timer)},300);
})();