// Browser-backed smoke tests, with a mocked KernelSU bridge and no device changes.
// Run from repository root: node tests/visual-webui.mjs
import assert from 'node:assert/strict'
import fs from 'node:fs'
import http from 'node:http'
import path from 'node:path'
import {fileURLToPath} from 'node:url'
import {chromium} from 'playwright'

const root=path.resolve('module/webroot')
const out=path.resolve('webui-screenshots')
fs.mkdirSync(out,{recursive:true})
const types={'.html':'text/html','.css':'text/css','.js':'text/javascript','.svg':'image/svg+xml'}
const server=http.createServer((req,res)=>{
  const name=decodeURIComponent((req.url||'/').split('?')[0])
  const full=path.resolve(root,'.'+name)
  if(!(full===root||full.startsWith(root+path.sep))){res.writeHead(403).end();return}
  const file=fs.statSync(full,{throwIfNoEntry:false})?.isFile()?full:path.join(root,'index.html')
  res.writeHead(200,{'Content-Type':types[path.extname(file)]||'text/plain','Cache-Control':'no-store'})
  fs.createReadStream(file).pipe(res)
})
await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve))
const url='http://127.0.0.1:'+server.address().port+'/index.html'
const failures=[]
const browser=await chromium.launch({headless:true})
try{
  for(const scenario of [
    {name:'mobile-393',width:393,height:852,dark:false,top:26,bottom:24},
    {name:'mobile-360',width:360,height:800,dark:false,top:29,bottom:0},
    {name:'small-320',width:320,height:720,dark:false,top:26,bottom:16},
    {name:'tablet-768',width:768,height:1024,dark:false,top:24,bottom:16},
    {name:'desktop-dark',width:1024,height:768,dark:true,top:0,bottom:0}
  ]){
    const page=await browser.newPage({
      viewport:{width:scenario.width,height:scenario.height},
      deviceScaleFactor:1, colorScheme:scenario.dark?'dark':'light'
    })
    page.on('pageerror',err=>failures.push(scenario.name+': JS: '+err.message))
    await page.route('https://mui.kernelsu.org/internal/**',route=>{
      if(route.request().url().endsWith('insets.css'))
        return route.fulfill({status:200,contentType:'text/css',body:
          ':root{--window-inset-top:'+scenario.top+'px;--window-inset-bottom:'+scenario.bottom+'px}'})
      return route.fulfill({status:200,contentType:'text/css',body:':root{}'})
    })
    await page.addInitScript(()=>{
      window.ksu={
        exec(command,options,callback){
          let output=''
          let status=0
          if(command==='cat /proc/1/mountinfo') output=[
            '36 25 0:34 / / rw - ext4 /dev/block/dm-0 rw',
            '41 36 0:42 / /system ro - overlay overlay ro',
            '42 36 0:43 / /vendor ro - ext4 /dev/block/dm-2 ro'
          ].join('\n')
          else if(command.includes("stat -f -c")) output='/system: overlayfs\n/vendor: ext4\n'
          else if(command.includes('susfs show version')) output='v2.3.0+\n'
          else if(command.includes('susfs show variant')) output='GKI\n'
          else if(command.includes('susfs show enabled_features')) output='CONFIG_KSU_SUSFS_SUS_KSTAT\nCONFIG_KSU_SUSFS_SUS_MAP\n'
          else if(command.includes('/module.prop')) output='version=v0.0.73-dev\n'
          else if(command.includes('/data/adb/brene/log.txt')) output='BRENE: running\n'
          else if(command.includes('/data/adb/brene/logs.txt')) output='Kernel: initialized\n'
          else if(command.startsWith('cat ')){status=1}
          window[callback]?.(status,output,status?'unavailable in mock':'')
        },
        toast(message){},
        spawn(command,args,options,callback){queueMicrotask(()=>window[callback]?.emit?.('exit',0))}
      }
    })
    await page.goto(url,{waitUntil:'networkidle',timeout:30000})
    await page.waitForSelector('.dock-btn.active',{timeout:8000})
    await page.waitForFunction(()=>!document.querySelector('.preload-hidden'),{timeout:8000})
    const baseline=await page.evaluate(()=>{
      const header=document.querySelector('.app-header').getBoundingClientRect()
      const title=document.querySelector('.app-header .title').getBoundingClientRect()
      const dock=document.querySelector('#tab-bar').getBoundingClientRect()
      const left=document.querySelectorAll('.dock-btn')
      const active=[...document.querySelectorAll('.tab-panel.active')].map(el=>el.dataset.panel)
      return {
        headerTop:header.top,headerBottom:header.bottom,titleTop:title.top,
        dockLeft:dock.left,dockRight:dock.right,dockBottom:dock.bottom,
        width:innerWidth,scrollWidth:document.documentElement.scrollWidth,
        dockPosition:getComputedStyle(document.querySelector('#tab-bar')).position,
        overflowX:getComputedStyle(document.querySelector('#tab-bar')).overflowX,
        navCount:left.length,active
      }
    })
    assert.equal(baseline.navCount,5,scenario.name+' dock must have five visible buttons')
    assert.equal(baseline.dockPosition,'fixed',scenario.name+' dock must float')
    assert.equal(baseline.overflowX,'visible',scenario.name+' dock must not scroll')
    assert.ok(baseline.dockLeft>=-1&&baseline.dockRight<=scenario.width+1,scenario.name+' dock overflow')
    assert.ok(baseline.scrollWidth<=scenario.width+3,scenario.name+' body horizontally overflows')
    assert.ok(baseline.headerTop>=-1&&baseline.headerTop<=scenario.top+15,scenario.name+' header container is displaced')
    assert.ok(baseline.titleTop>=Math.max(0,scenario.top-8)&&baseline.titleTop<=scenario.top+44,
      scenario.name+' header TITLE is too far below the status bar: '+baseline.titleTop)
    assert.deepEqual(baseline.active,['home'],scenario.name+' initial panel')

    if(scenario.name==='mobile-393'){
      await page.screenshot({path:path.join(out,'mobile-393-overview.png'),fullPage:true})
    }
    await page.locator('[data-group=privacy]').click()
    if(scenario.name==='mobile-393'){
      await page.screenshot({path:path.join(out,'mobile-393-privacy.png'),fullPage:true})
    }
    await page.locator('#subnav button').nth(2).click()
    assert.ok(await page.locator('[data-panel=rom]').isVisible(),scenario.name+' ROM panel')
    await page.locator('[data-group=kernel]').click()
    await page.locator('#subnav button').nth(1).click()
    assert.ok(await page.locator('[data-panel=ksu]').isVisible(),scenario.name+' KSU panel')
    await page.locator('[data-group=tools]').click()
    await page.locator('#subnav button').nth(1).click()
    assert.ok(await page.locator('[data-panel=advanced]').isVisible(),scenario.name+' advanced panel')
    await page.locator('[data-group=diagnostics]').click()
    await page.waitForFunction(()=>{
      const el=document.getElementById('mount_summary')
      return el && el.textContent.includes('overlay')
    })
    const diag=await page.evaluate(()=>{
      const txt=id=>document.getElementById(id)?.textContent||''
      const boxes=['mount-diagnostics','log-panel','duck-diagnostics'].map(id=>{
        const r=document.getElementById(id).getBoundingClientRect()
        return {id,top:r.top,bottom:r.bottom,left:r.left,right:r.right}
      })
      return {summary:txt('mount_summary'),logs:txt('logs'),boxes}
    })
    assert.ok(diag.summary.includes('overlay 挂载 1 条'),scenario.name+' overlay evidence')
    assert.ok(diag.logs.includes('BRENE: running'),scenario.name+' nested logs')
    for(const b of diag.boxes) assert.ok(b.right<=scenario.width+2&&b.left>=-2,scenario.name+' card overflow: '+b.id)
    await page.screenshot({path:path.join(out,scenario.name+'.png'),fullPage:true})
    await page.locator('[data-group=overview]').click()
    const locale=page.locator('#brene-locale-button')
    await locale.click()
    const overview=await page.locator('.dock-btn[data-group=overview] span').textContent()
    assert.equal(overview?.trim(),'Overview',scenario.name+' language toggling failed')
    await page.close()
    console.log('PASS',scenario.name,JSON.stringify({top:baseline.headerTop,dock:baseline.dockPosition,overlay:diag.summary}))
  }
  assert.deepEqual(failures,[], 'No WebUI JavaScript exceptions')
} finally {
  await browser.close()
  await new Promise(resolve=>server.close(resolve))
}
console.log('PASS Chromium render/interaction with five viewports; screenshots in webui-screenshots/')
