import {exec, toast} from './assets/kernelsu.js'
const DIR='/data/adb/brene'
const field=document.getElementById('brene-kstat-rules')
const status=document.getElementById('brene-kstat-status')
const apply=document.getElementById('brene-kstat-save')
function show(s){ if(status) status.textContent=s }
function validate(text){
  const lines=text.split(/\r?\n/).filter(l=>l.trim() && !l.trim().startsWith('#'))
  if(lines.length>200 || new TextEncoder().encode(text).length>32768) return '规则数量或大小超过限制'
  for(const [index,line] of lines.entries()){
    const parts=line.split('|')
    if(parts.length>2 || !parts[0].startsWith('/') || parts[0].length>1024 || /[\x00-\x1f]/.test(line)) return '第 '+(index+1)+' 条规则格式错误'
    if(parts.length===2 && !['update','clone'].includes(parts[1])) return '第 '+(index+1)+' 条模式应为 update 或 clone'
  }
  return null
}
function base64(data){
 const bytes=new TextEncoder().encode(data)
 let binary=''
 for(const v of bytes)binary+=String.fromCharCode(v)
 return btoa(binary)
}
async function load(){
 if(!field || !apply || !status)return
 const [features,rules,version]=await Promise.all([
  exec('susfs show enabled_features'),exec('cat /data/adb/brene/custom_sus_kstat.txt'),exec('susfs show version')
 ])
 if(rules.errno===0)field.value=rules.stdout
 const enabled=features.errno===0 && /\b(?:CONFIG_KSU_SUSFS_)?SUS_KSTAT\b/.test(features.stdout)
 apply.disabled=!enabled
 show(enabled?'SUS_KSTAT 已在内核中启用 · '+version.stdout.trim()+' · 保存后需重启':
   '当前内核未报告 SUS_KSTAT，已禁用规则写入；请检查内核编译选项')
}
apply?.addEventListener('click',async ()=>{
 const error=validate(field.value)
 if(error){toast(error);return}
 const payload=base64(field.value.replace(/\r\n/g,'\n'))
 const result=await exec("printf '%s' '"+payload+"' | base64 -d > /data/adb/brene/custom_sus_kstat.txt")
 toast(result.errno===0?'KSTAT 规则已保存，重启后生效':(result.stderr||'保存失败'))
})
load().catch(()=>show('SuSFS 运行时状态查询失败'))
