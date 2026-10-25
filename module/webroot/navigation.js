// Five fixed categories, preserving every existing BRENE panel and setting ID.
const GROUPS = [
  {id: 'overview', panels: [{id:'home', title:'概览', english:'Overview'}]},
  {id: 'privacy', panels: [
    {id:'hiding', title:'路径隐藏', english:'Paths'},
    {id:'spoofing', title:'信息伪装', english:'Spoofing'},
    {id:'rom', title:'ROM 适配', english:'ROM'}]},
  {id: 'kernel', panels: [
    {id:'susfs', title:'SuSFS', english:'SuSFS'},
    {id:'ksu', title:'KernelSU', english:'KernelSU'}]},
  {id: 'tools', panels: [
    {id:'android', title:'系统', english:'Android'},
    {id:'advanced', title:'高级设置', english:'Advanced'}]},
  {id: 'diagnostics', panels: [{id:'info', title:'诊断', english:'Diagnostics'}]},
];
const dock = document.getElementById('tab-bar');
const secondary = document.getElementById('subnav');
const allPanels = [...document.querySelectorAll('.tab-panel')];
const groupButtons = [...dock.querySelectorAll('button[data-group]')];
let english = false;
try { english = localStorage.getItem('brene_locale') === 'en' } catch (_) {}
function stored(key) {
  try { return sessionStorage.getItem(key) } catch (_) { return null }
}
function save(key,val) {
  try { sessionStorage.setItem(key,val) } catch (_) {}
}
function show(groupId,panelId,scroll=true) {
  const group = GROUPS.find(x=>x.id===groupId) || GROUPS[0];
  const target = group.panels.find(x=>x.id===panelId) || group.panels[0];
  groupButtons.forEach(button=>{
    const selected=button.dataset.group===group.id;
    button.classList.toggle('active',selected);
    button.setAttribute('aria-current',selected?'page':'false');
  });
  allPanels.forEach(panel=>{
    const selected=panel.dataset.panel===target.id;
    panel.classList.toggle('active',selected);
    panel.hidden=!selected;
  });
  secondary.replaceChildren();
  if(group.panels.length>1){
    secondary.hidden=false;
    for(const sub of group.panels){
      const button=document.createElement('button');
      button.type='button';
      button.className='subnav-btn'+(sub.id===target.id?' active':'');
      button.textContent=english?sub.english:sub.title;
      button.setAttribute('aria-pressed',sub.id===target.id?'true':'false');
      button.addEventListener('click',()=>show(group.id,sub.id));
      secondary.append(button);
    }
  } else secondary.hidden=true;
  save('brene_group',group.id);
  save('brene_tab',target.id); // Preserve compatibility with the original navigation preference.
  if(scroll && typeof window.scrollTo==='function') window.scrollTo({top:0,behavior:'instant'});
}
for(const button of groupButtons){
  button.addEventListener('click',()=>{
    const id=button.dataset.group;
    const group=GROUPS.find(x=>x.id===id);
    if(!group) return;
    const last=stored('brene_last_'+id);
    show(id,last);
  });
}
const fromLegacy=stored('brene_tab');
const found=GROUPS.find(group=>group.panels.some(panel=>panel.id===fromLegacy));
let initialGroup=stored('brene_group');
if(!GROUPS.some(x=>x.id===initialGroup)) initialGroup=found?.id || 'overview';
let initialPanel=fromLegacy;
if(!GROUPS.find(x=>x.id===initialGroup)?.panels.some(x=>x.id===initialPanel))
  initialPanel=stored('brene_last_'+initialGroup);
show(initialGroup,initialPanel,false);
const oldShow=show;
// Keep the panel remembered even when user switches to a different category.
function rememberPanel(){
  const selected=allPanels.find(p=>p.classList.contains('active'));
  const group=GROUPS.find(g=>g.panels.some(p=>p.id===selected?.dataset.panel));
  if(group && selected) save('brene_last_'+group.id,selected.dataset.panel);
}
secondary.addEventListener('click',rememberPanel);
dock.addEventListener('click',rememberPanel);
window.addEventListener('brene-locale-change',event=>{
  english=event.detail==='en';
  const selected=allPanels.find(p=>p.classList.contains('active'));
  const group=GROUPS.find(g=>g.panels.some(p=>p.id===selected?.dataset.panel));
  if(group) show(group.id,selected.dataset.panel,false);
});
