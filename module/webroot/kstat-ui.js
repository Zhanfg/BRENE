import { exec, toast } from './assets/kernelsu.js'

// BRENE 2.3.0 UI: feature-gated editors. Files are data, never sourced or evaluated.
const BASE = '/data/adb/brene'
const NAMES = [
  ['SUS_PATH','路径隐藏'], ['SUS_MOUNT','挂载隐藏'],
  ['SUS_KSTAT','文件元数据'], ['SPOOF_UNAME','内核版本'],
  ['ENABLE_LOG','内核日志'], ['SPOOF_CMDLINE_OR_BOOTCONFIG','启动参数'],
  ['OPEN_REDIRECT','打开重定向'], ['SUS_MAP','内存映射'],
  ['HIDE_KSU_SUSFS_SYMBOLS','符号隐藏（编译期）']
]
const el = id => document.getElementById(id)
const status = (id, value) => { if(el(id)) el(id).textContent = value }
const active = (features, name) => new RegExp('\\b(?:CONFIG_KSU_SUSFS_)?' + name + '\\b').test(features)
function b64(value) {
  const bytes = new TextEncoder().encode(value)
  let binary = ''
  for (const byte of bytes) binary += String.fromCharCode(byte)
  return btoa(binary)
}
function bytes(value) { return new TextEncoder().encode(value).length }
async function save(file, text) {
  const allowed = ['custom_sus_kstat.txt','custom_static_kstat.txt','custom_cmdline.txt','custom_bootconfig.txt']
  if (!allowed.includes(file)) throw new Error('Invalid rules target')
  const encoded = b64(text.replace(/\r\n/g,'\n'))
  // Only a validated filename and base64 alphabet reach this shell command.
  const response = await exec("printf '%s' '" + encoded + "' | base64 -d > " + BASE + "/" + file)
  if (response.errno !== 0) throw new Error(response.stderr || 'Save failed')
}
function cleanLines(text) {
  return text.split(/\r?\n/).filter(line => line.trim() && !line.trim().startsWith('#'))
}
function checkPath(path) {
  return path.startsWith('/') && path.length <= 1024 && !/[\x00-\x1f\x7f|]/.test(path)
}
function validateDynamic(text) {
  if (bytes(text) > 32768) return '规则文件不得超过 32 KiB'
  const lines = cleanLines(text)
  if (lines.length > 200) return '最多 200 条规则'
  for (const [idx,line] of lines.entries()) {
    const p=line.split('|')
    if (p.length > 2 || !checkPath(p[0]) || (p.length === 2 && !['update','clone'].includes(p[1]))) {
      return '动态 KSTAT 第 ' + (idx+1) + ' 条格式不正确'
    }
  }
  return null
}
function validateStatic(text) {
  if (bytes(text) > 32768) return '规则文件不得超过 32 KiB'
  const lines = cleanLines(text)
  if (lines.length > 200) return '最多 200 条规则'
  for (const [idx,line] of lines.entries()) {
    const p=line.split('|')
    if (p.length !== 13 || !checkPath(p[0]) ||
       !p.slice(1).every(v => v === 'default' || (/^\d{1,20}$/.test(v)))) {
      return '静态 KSTAT 第 ' + (idx+1) + ' 条须有路径及 12 个数字/default 字段'
    }
  }
  return null
}
function validateBoot(text, isGki) {
  if (bytes(text) > 8192) return '内容不得超过 8 KiB'
  if (/[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]/.test(text)) return '包含不支持的控制字符'
  if (!isGki && text.trim() && /[\r\n]/.test(text.trim())) return '非 GKI cmdline 必须是单行'
  return null
}
async function init() {
  const [features,variant,version] = await Promise.all([
    exec('susfs show enabled_features'),exec('susfs show variant'),exec('susfs show version')
  ])
  const flags = features.errno === 0 ? features.stdout : ''
  const kstat = features.errno === 0 && active(flags,'SUS_KSTAT')
  const cmdline = features.errno === 0 && active(flags,'SPOOF_CMDLINE_OR_BOOTCONFIG')
  const isGki = variant.errno === 0 && variant.stdout.trim() === 'GKI'
  const mode = isGki ? 'Bootconfig / GKI' : 'Cmdline / non-GKI'
  const grid = el('brene-feature-matrix')
  if (grid) {
    const header = 'SuSFS: ' + (version.errno === 0 ? version.stdout.trim() : 'unknown') +
      ' · 变体: ' + (variant.errno === 0 ? variant.stdout.trim() : 'unknown')
    const lines = NAMES.map(([feature,title]) => title + ' · ' + feature + ': ' +
      (features.errno !== 0 ? '无法查询' : active(flags,feature) ? '已编译' : '未报告/未编译'))
    grid.textContent = [header,...lines].join('\n')
  }
  const panels = [
    {field:'brene-kstat-rules',button:'brene-kstat-save',state:'brene-kstat-status',
     file:'custom_sus_kstat.txt',enabled:kstat,validate:validateDynamic},
    {field:'brene-static-kstat-rules',button:'brene-static-kstat-save',state:'brene-static-kstat-status',
     file:'custom_static_kstat.txt',enabled:kstat,validate:validateStatic},
    {field:'brene-boot-payload',button:'brene-boot-save',state:'brene-boot-status',
     file:isGki?'custom_bootconfig.txt':'custom_cmdline.txt',enabled:cmdline,
     validate:text=>validateBoot(text,isGki)}
  ]
  for (const panel of panels) {
    const input=el(panel.field),button=el(panel.button)
    if(!input || !button) continue
    const read = await exec('cat ' + BASE + '/' + panel.file)
    if(read.errno === 0) input.value = read.stdout
    button.disabled = !panel.enabled || read.errno !== 0
    status(panel.state, panel.enabled
      ? '已检测到内核支持 · ' + (panel.file.startsWith('custom_') ? panel.file : mode) + ' · 保存后重启生效'
      : '功能未报告或查询失败；禁止保存。')
    button.addEventListener('click',async()=>{
      const problem=panel.validate(input.value)
      if(problem){toast(problem);return}
      button.disabled=true
      try {
        await save(panel.file,input.value)
        toast('已保存到 ' + panel.file + '，重启后生效')
      } catch(e) { toast(String(e.message || e)) }
      finally {button.disabled = !panel.enabled}
    })
  }
}
init().catch(err => {
  status('brene-kstat-status','读取失败: ' + String(err))
  status('brene-static-kstat-status','无法确认内核能力')
  status('brene-boot-status','无法确认内核能力')
})
