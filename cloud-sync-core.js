/* Fruit Tank Academy — isolated, non-blocking cloud bridge for the single game iframe. */
(function(){
  const cfg=window.FRUIT_TANK_SUPABASE;
  if(!cfg)return;
  const cloud=cfg.createClient();
  const OUTBOX='fruitTankAttemptOutbox';
  const read=()=>{try{return JSON.parse(localStorage.getItem(OUTBOX)||'[]')}catch(e){return[]}};
  const write=v=>{try{localStorage.setItem(OUTBOX,JSON.stringify(v.slice(-200)))}catch(e){}};
  const timeout=(p,ms=5000)=>Promise.race([p,new Promise((_,reject)=>setTimeout(()=>reject(new Error('cloud request timeout')),ms))]);
  let frame=null,installed=false,currentSessionId=null,sessionReady=Promise.resolve(null),flushing=false,lastProfileSync=0;
  function enqueue(p){const q=read();q.push(p);write(q);flush()}
  async function flush(){if(flushing||!installed)return;flushing=true;try{let q=read();while(q.length){const r=await timeout(cloud.rpc('record_my_word_attempt',q[0]));if(r.error)throw r.error;q.shift();write(q)}}catch(e){console.warn('[FruitTank Cloud] attempt queue',e)}finally{flushing=false}}
  async function profileSync(force){const now=Date.now();if(!force&&now-lastProfileSync<30000)return;lastProfileSync=now;try{const p=frame?.contentWindow?.profile;if(!p)return;await timeout(cloud.rpc('sync_my_learning',{p_xp:Number(p.xp||0),p_level:Number(p.level||1),p_streak:Number(p.streak||0),p_total_words:Number(p.totalWords||0),p_correct_attempts:Number(p.correct||0),p_total_shots:Number(p.shots||0)}))}catch(e){console.warn('[FruitTank Cloud] profile sync',e)}}
  async function startSession(){try{const w=frame.contentWindow.world();const mode=frame.contentDocument.getElementById('difficulty')?.value||'Normal';const r=await timeout(cloud.rpc('start_my_session',{p_world:String(w.id),p_mode:String(mode)}));if(r.error)throw r.error;currentSessionId=r.data||null;return currentSessionId}catch(e){console.warn('[FruitTank Cloud] session start',e);return null}}
  function attempt(word,target,selected){if(!installed||!word||!target||!selected)return;Promise.resolve(sessionReady).then(sid=>{const w=frame.contentWindow.world().id;enqueue({p_session_id:sid||null,p_word:String(word),p_target_letter:String(target),p_selected_letter:String(selected),p_is_correct:String(target).toUpperCase()===String(selected).toUpperCase(),p_world:String(w)})})}
  async function finish(){const sid=currentSessionId;if(!sid)return;try{await sessionReady;await flush();const r=await timeout(cloud.rpc('finish_my_session',{p_session_id:sid}));if(r.error)throw r.error;await profileSync(true);await timeout(cloud.rpc('complete_my_daily_quest'))}catch(e){console.warn('[FruitTank Cloud] session finish',e)}finally{currentSessionId=null;sessionReady=Promise.resolve(null)}}
  function install(target){if(installed)return;frame=target;if(!frame||!frame.contentWindow)return;try{const bridge=`
(function(){
 if(window.__fruitTankCloudInstalled)return;window.__fruitTankCloudInstalled=true;
 const record=(word,target,selected)=>window.parent.__fruitTankRecordAttempt&&window.parent.__fruitTankRecordAttempt(word,target,selected);
 const originalStart=startGame;startGame=function(){originalStart();window.parent.__fruitTankSessionReady=window.parent.__fruitTankStartSession();};
 const originalFinish=finish;finish=function(won){originalFinish(won);window.parent.__fruitTankFinishSession&&window.parent.__fruitTankFinishSession();};
 const originalAddXP=addXP;addXP=function(n){try{if(typeof state!=='undefined'&&state.running&&state.word){const expected=state.word[state.index];if(expected)record(state.word,expected,expected)}}catch(e){}return originalAddXP(n)};
 const originalToast=toast;toast=function(t,ms){try{const m=String(t||'').match(/^TRY AGAIN\\s*[·—-]\\s*REVIEW\\s+([A-Z])$/i);if(m&&typeof state!=='undefined'&&state.running&&state.word){record(state.word,state.word[state.index],m[1])}}catch(e){}return originalToast(t,ms)};
})();`;
    frame.contentWindow.eval(bridge);installed=true;window.__fruitTankStartSession=startSession;window.__fruitTankFinishSession=finish;window.__fruitTankRecordAttempt=attempt;window.__fruitTankSessionReady=sessionReady;sessionReady=startSession();profileSync(true);flush();
  }catch(e){console.warn('[FruitTank Cloud] install failed',e)}}
  window.FRUIT_TANK_CLOUD={install};
  window.addEventListener('online',()=>{profileSync(true);flush()});
})();
