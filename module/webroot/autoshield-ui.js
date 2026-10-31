import { exec, toast } from './assets/kernelsu.js'

const TOOL = '/data/adb/modules/brene/autoshield.sh'
const CFG = '/data/adb/brene/config.sh'
const BASE = '/data/adb/brene'
const el = id => document.getElementById(id)
const status = el('brene-auto-status')
const preview = el('brene-auto-candidates')
const buttons = [el('brene-auto-scan'), el('brene-auto-enable'), el('brene-auto-disable')]
let busy = false

function setBusy(next) {
  busy = next
  buttons.forEach(button => { if(button) button.disabled = next })
}
async function run(command) {
  const result = await exec(command)
  if (result.errno !== 0) throw new Error(result.stderr || '命令执行失败')
  return result.stdout.trim()
}
async function refresh() {
  if (!status || !preview) return
  const [state, candidates] = await Promise.all([
    run('sh ' + TOOL + ' status'),
    exec('cat ' + BASE + '/autoshield.candidates')
  ])
  status.textContent = state
  preview.textContent = candidates.errno === 0 && candidates.stdout.trim()
    ? candidates.stdout.trim() : '暂无候选路径；点击“扫描与预览”'
}
async function handle(action) {
  if (busy) return
  setBusy(true)
  try {
    if (action === 'scan') {
      const message = await run('sh ' + TOOL + ' scan')
      toast(message)
    }
    if (action === 'enable') {
      const capabilities = await run('sh ' + TOOL + ' status')
      if (capabilities.includes('SUS_MAP：未报告支持')) {
        throw new Error('当前内核尚未报告 SUS_MAP；没有启用自动应用')
      }
      // Fixed trusted flag and filesystem path; user-provided text is never interpolated.
      await run("sed -i 's/^config_auto_hide=.*/config_auto_hide=1/' " + CFG)
      const message = await run('sh ' + TOOL + ' apply')
      toast(message || '已开启自动应用')
    }
    if (action === 'disable') {
      await run("sed -i 's/^config_auto_hide=.*/config_auto_hide=0/' " + CFG)
      toast('已关闭自动应用；当前已生效的 SUS_MAP 规则将在重启后清除')
    }
    await refresh()
  } catch(e) {
    if(status) status.textContent = '操作失败：' + String(e.message || e)
    toast('操作失败，请查看状态和日志')
  } finally {
    setBusy(false)
  }
}
el('brene-auto-scan')?.addEventListener('click', () => handle('scan'))
el('brene-auto-enable')?.addEventListener('click', () => handle('enable'))
el('brene-auto-disable')?.addEventListener('click', () => handle('disable'))
refresh().catch(e => { if (status) status.textContent = '无法读取状态：' + String(e.message || e) })
