/* Fruit Tank Academy — non-blocking cloud sync bridge. */
(function(){
  const frame=document.getElementById('gameFrame');
  if(!frame)return;
  const SUPABASE_URL='https://yxhtshjxvlgswfjhxara.supabase.co';
  const SUPABASE_KEY='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl4aHRzaGp4dmxnc3dmamh4YXJhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU3MjE2MjMsImV4cCI6MjA4MTI5NzYyM30.J4kpzCZkKiU4E0wFHxBgmBr-mKGD6MF9AGS8nTJKDM4';
  const client=window.supabaseClientForFruitTank||(window.supabase&&window.supabase.createClient?window.supabase.createClient(SUPABASE_URL,SUPABASE_KEY,{auth:{persistSession:true,autoRefreshToken:true,storageKey:'fruit-tank-academy-auth'}}):null);
  window.supabaseClientForFruitTank=client;
  let installed=false;
  const bridge=`
  (function(){
    if(window.__fruitTankCloudInstalled)return;
    window.__fruitTankCloudInstalled=true;
    const cloud=window.parent.supabaseClientForFruitTank;
    if(!cloud)return;
    let currentSessionId=null;
    let sessionReady=Promise.resolve(null);
    const OUTBOX='fruitTankAttemptOutbox';
    const readOutbox=()=>{try{return JSON.parse(localStorage.getItem(OUTBOX)||'[]')}catch(e){return[]}};
    const writeOutbox=v=>{try{localStorage.setItem(OUTBOX,JSON.stringify(v.slice(-200)))}catch(e){}};
    const timeout=(p,ms=5000)=>Promise.race([p,new Promise((_,r)=>setTimeout(()=>r(new Error('cloud request timeout')),ms))]);
    let flushing=false;
    function queueAttempt(p){const q=readOutbox();q.push(p);writeOutbox(q);flushAttempts()}
    async function flushAttempts(){
      if(flushing||!cloud||typeof profile==='undefined'||!profile.__cloudUserId)return;
      flushing=true;
      try{let q=readOutbox();while(q.length){const {error}=await timeout(cloud.rpc('record_my_word_attempt',q[0]));if(error)throw error;q.shift();writeOutbox(q)}}catch(e){console.warn('[FruitTank Cloud] attempt sync',e)}finally{flushing=false}
    }
    async function syncProfile(){
      if(!cloud||typeof profile==='undefined'||!profile.__cloudUserId)return;
      try{await timeout(cloud.rpc('sync_my_learning',{p_xp:Number(profile.xp||0),p_level:Number(profile.level||1),p_streak:Number(profile.streak||0),p_total_words:Number(profile.totalWords||0),p_correct_attempts:Number(profile.correct||0),p_total_shots:Number(profile.shots||0)}))}catch(e){console.warn('[FruitTank Cloud] profile sync',e)}
    }
    async function startSession(){
      if(!cloud||typeof profile==='undefined'||!profile.__cloudUserId)return null;
      try{const w=typeof world==='function'?world():{id:'orchard'};const mode=document.getElementById('difficulty')?.value||'Normal';const {data,error}=await timeout(cloud.rpc('start_my_session',{p_world:String(w.id),p_mode:String(mode)}));if(error)throw error;currentSessionId=data||null;return currentSessionId}catch(e){console.warn('[FruitTank Cloud] session start',e);return null}
    }
    function recordAttempt(word,target,selected,isCorrect){
      if(!cloud||typeof profile==='undefined'||!profile.__cloudUserId||!word||!target||!selected)return;
      Promise.resolve(sessionReady).then(sid=>{const w=typeof world==='function'?world().id:'orchard';queueAttempt({p_session_id:sid||null,p_word:String(word),p_target_letter:String(target),p_selected_letter:String(selected),p_is_correct:Boolean(isCorrect),p_world:String(w)})});
    }
    async function saveSession(){
      const sid=currentSessionId;if(!sid||!cloud)return;
      try{await sessionReady;await flushAttempts();await timeout(cloud.rpc('finish_my_session',{p_session_id:sid}));await syncProfile();await timeout(cloud.rpc('complete_my_daily_quest'))}catch(e){console.warn('[FruitTank Cloud] session sync',e)}finally{currentSessionId=null;sessionReady=Promise.resolve(null)}
    }
    async function bootstrap(){try{const {data:{user}}=await timeout(cloud.auth.getUser());if(user&&typeof profile!=='undefined')profile.__cloudUserId=user.id;await syncProfile();await flushAttempts()}catch(e){console.warn('[FruitTank Cloud] bootstrap',e)}}
    const originalStart=startGame;startGame=function(){originalStart();sessionReady=startSession();syncProfile()};
    const originalComplete=completeWord;completeWord=function(){originalComplete();syncProfile();flushAttempts()};
    const originalFinish=finish;finish=function(won){originalFinish(won);saveSession()};
    const originalAddXP=addXP;addXP=function(n){try{if(typeof state!=='undefined'&&state.running&&state.word){const expected=state.word[state.index];if(expected)recordAttempt(state.word,expected,expected,true)}}catch(e){}return originalAddXP(n)};
    const originalToast=toast;toast=function(t,ms){try{const m=String(t||'').match(/^TRY AGAIN · REVIEW\\s+([A-Z])$/i);if(m&&typeof state!=='undefined'&&state.running&&state.word){recordAttempt(state.word,state.word[state.index],m[1],false)}}catch(e){}return originalToast(t,ms)};
    window.addEventListener('online',()=>{syncProfile();flushAttempts()});
    bootstrap();
  })();`;
  function install(){if(installed||!frame.contentWindow)return;try{frame.contentWindow.eval(bridge);installed=true}catch(e){console.warn('[FruitTank Cloud] install failed',e)}}
  frame.addEventListener('load',()=>setTimeout(install,50));
  const timer=setInterval(()=>{if(!installed)install();else clearInterval(timer)},300);
})();
