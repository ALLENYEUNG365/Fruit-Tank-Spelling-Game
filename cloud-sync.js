/* Fruit Tank Academy — cloud sync bridge. Loaded by cloud-game.html. */
(function(){
  const frame=document.getElementById('gameFrame');
  const sb=window.supabaseClientForFruitTank || null;
  const SUPABASE_URL='https://yxhtshjxvlgswfjhxara.supabase.co';
  const SUPABASE_KEY='sb_publishable_oLcXJtWtzj515ub8W-BF4g_whX0nB6f';
  const client=sb || (window.supabase&&window.supabase.createClient?window.supabase.createClient(SUPABASE_URL,SUPABASE_KEY,{auth:{persistSession:true,autoRefreshToken:true}}):null);
  window.supabaseClientForFruitTank=client;
  let installed=false;
  const bridge=`
  (function(){
    if(window.__fruitTankCloudInstalled)return; window.__fruitTankCloudInstalled=true;
    const cloud=window.parent.supabaseClientForFruitTank;
    let sessionStartedAt=null, startSnapshot=null, lastWord='';
    async function syncProfile(){
      try{
        if(!cloud||typeof profile==='undefined')return;
        await cloud.rpc('sync_my_learning',{p_xp:Number(profile.xp||0),p_level:Number(profile.level||1),p_streak:Number(profile.streak||0),p_total_words:Number(profile.totalWords||0),p_correct_attempts:Number(profile.correct||0),p_total_shots:Number(profile.shots||0)});
      }catch(e){console.warn('[FruitTank Cloud] profile sync',e)}
    }
    async function saveWord(word){
      if(!cloud||!word||typeof profile==='undefined')return;
      try{
        const worldName=typeof world==='function'?world().id:'orchard';
        const {data}=await cloud.from('word_progress').select('attempts,correct_attempts,mastered').eq('student_id',profile.__cloudUserId||'').eq('word',word).maybeSingle();
        const attempts=Number(data?.attempts||0)+1, correct=Number(data?.correct_attempts||0)+1;
        await cloud.from('word_progress').upsert({student_id:profile.__cloudUserId,word,world:worldName,attempts,correct_attempts:correct,mastered:true,last_attempt_at:new Date().toISOString()},{onConflict:'student_id,word'});
      }catch(e){console.warn('[FruitTank Cloud] word sync',e)}
    }
    async function saveDaily(){
      if(!cloud||typeof profile==='undefined'||!profile.__cloudUserId)return;
      try{
        const d=new Date().toISOString().slice(0,10);
        await cloud.from('daily_quests').upsert({student_id:profile.__cloudUserId,quest_date:d,words_completed:Number(profile.daily||0),target_words:3,completed:Number(profile.daily||0)>=3},{onConflict:'student_id,quest_date'});
      }catch(e){console.warn('[FruitTank Cloud] daily sync',e)}
    }
    async function saveSession(){
      if(!cloud||typeof profile==='undefined'||!sessionStartedAt)return;
      try{
        const started=new Date(sessionStartedAt).toISOString();
        const ended=new Date().toISOString();
        const w=typeof world==='function'?world():{id:'orchard'};
        const mode=document.getElementById('difficulty')?.value||'Normal';
        await cloud.rpc('record_my_session',{p_world:w.id,p_mode:mode,p_score:Number(state.score||0),p_words_completed:Number(state.words||0),p_shots:Number(profile.shots||0)-Number(startSnapshot?.shots||0),p_correct_attempts:Number(profile.correct||0)-Number(startSnapshot?.correct||0),p_duration_seconds:Math.max(0,Math.round((Date.now()-sessionStartedAt)/1000)),p_started_at:started,p_ended_at:ended});
        await syncProfile(); await saveDaily();
      }catch(e){console.warn('[FruitTank Cloud] session sync',e)}
      sessionStartedAt=null; startSnapshot=null;
    }
    async function bootstrap(){
      try{
        const {data:{user}}=await cloud.auth.getUser();
        if(!user)return;
        if(typeof profile!=='undefined')profile.__cloudUserId=user.id;
        await syncProfile();
      }catch(e){console.warn('[FruitTank Cloud] bootstrap',e)}
    }
    const originalStart=startGame;
    startGame=function(){
      originalStart();
      sessionStartedAt=Date.now();
      startSnapshot={shots:Number(profile.shots||0),correct:Number(profile.correct||0)};
      syncProfile();
    };
    const originalComplete=completeWord;
    completeWord=function(){
      const completedWord=typeof state!=='undefined'?state.word:'';
      originalComplete();
      if(completedWord)saveWord(completedWord);
      saveDaily(); syncProfile();
    };
    const originalFinish=finish;
    finish=function(won){ originalFinish(won); saveSession(); };
    window.addEventListener('beforeunload',()=>{syncProfile();});
    setInterval(()=>{if(typeof state!=='undefined'&&state.running)syncProfile()},15000);
    bootstrap();
  })();`;
  function install(){
    if(installed||!frame.contentWindow)return;
    try{frame.contentWindow.eval(bridge);installed=true;console.log('[FruitTank Cloud] sync installed')}catch(e){console.warn('[FruitTank Cloud] install failed',e)}
  }
  frame.addEventListener('load',()=>setTimeout(install,50));
  const timer=setInterval(()=>{if(!installed)install();else clearInterval(timer)},300);
})();