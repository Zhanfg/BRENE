import {exec, toast} from './assets/kernelsu.js'

// Transparent diagnostics. Unlike the previous regex, this does not claim
// that zero markers in PID 1 mountinfo means a detector process is clean.
const elem = id => document.getElementById(id);
const summary = elem('mount_summary');
const mountDetail = elem('suspicious_mounts');
const logOutput = elem('logs');

async function loadMountEvidence(){
  if(!summary || !mountDetail) return;
  const [mounts,stat]=await Promise.all([
    exec('cat /proc/1/mountinfo'),
    exec("stat -f -c '%n: %T' /system /vendor")
  ]);
  if(mounts.errno!==0){
    summary.textContent='无法读取 init 挂载表（未检测，不是 0）';
    mountDetail.textContent='读取失败：'+(mounts.stderr || '权限受限');
    return;
  }
  const lines=mounts.stdout.split(/\r?\n/).filter(Boolean);
  const overlay=lines.filter(s=>/\s-\soverlay\s/.test(s));
  const candidates=lines.filter(s=>/\/data\/adb(?:\/|\s)|\b(?:magisk|kernelsu|ksu|zygisk|apatch)\b/i.test(s));
  // This is a descriptive view of PID 1, not an app-namespace verdict.
  summary.textContent=`已读取 ${lines.length} 条记录 · overlay 挂载 ${overlay.length} 条 · 关键词候选 ${candidates.length} 条`;
  const preview=[
    '文件系统类型（当前诊断 Shell）：',
    stat.errno===0 ? stat.stdout.trim() : '不可用（'+(stat.stderr||'命令失败')+'）',
    '',
    'overlayfs 挂载记录（init）：',
    ...(overlay.length?overlay.slice(0,8):['未在本次 /proc/1/mountinfo 中发现；不代表不存在']),
    '',
    '附加关键词候选（init）：',
    ...(candidates.length?candidates.slice(0,8):['没有关键词命中']),
    '',
    '注意：init 与普通应用的 mount namespace 可能不同。',
    '本统计不能替代 DuckDetector 的 Mount/Memory 扫描。'
  ];
  mountDetail.textContent=preview.join('\n');
}
async function loadLogEvidence(){
  if(!logOutput) return;
  const paths=['/data/adb/brene/log.txt','/data/adb/brene/logs.txt'];
  const responses=await Promise.all(paths.map(x=>exec('cat '+x)));
  const entries=responses.map((r,i)=>r.errno===0 && r.stdout.trim()
    ? r.stdout.trim() : '').filter(Boolean);
  logOutput.textContent=entries.length?entries.join('\n\n──────────\n\n'):
    '暂无可用日志。请开启 BRENE 日志，并在重启后查看记录。';
}
const auditButton=elem('duck-audit-button');
const auditStatus=elem('duck-audit-status');
auditButton?.addEventListener('click',async ()=>{
  auditButton.disabled=true;
  if(auditStatus)auditStatus.textContent='正在生成本机只读诊断文件…';
  try{
    const r=await exec('sh /data/adb/modules/brene/tools/duck-evidence-audit.sh');
    if(r.errno!==0)throw new Error(r.stderr||'脚本执行失败');
    if(auditStatus)auditStatus.textContent=r.stdout.trim();
    toast('已完成只读诊断，详见 Download');
  }catch(e){
    if(auditStatus)auditStatus.textContent='生成失败：'+String(e.message||e);
  }finally {auditButton.disabled=false}
});
loadMountEvidence().catch(err=>{
  if(summary)summary.textContent='挂载诊断异常（未完成）';
  if(mountDetail)mountDetail.textContent=String(err);
});
loadLogEvidence().catch(err=>{
  if(logOutput)logOutput.textContent='读取日志失败：'+String(err);
});
