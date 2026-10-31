#!/usr/bin/env node
// No browser dependency: exercises the actual five-category navigation.
import fs from 'node:fs'
import vm from 'node:vm'
import assert from 'node:assert/strict'
const root='module/webroot/'
const html=fs.readFileSync(root+'index.html','utf8')
const modern=fs.readFileSync(root+'modern.css','utf8')
const main=fs.readFileSync(root+'script.js','utf8')
const diag=fs.readFileSync(root+'diagnostics.js','utf8')
const nav=fs.readFileSync(root+'navigation.js','utf8')
const ids=[...html.matchAll(/\bid="([^"]+)"/g)].map(m=>m[1])
assert.equal(ids.length,new Set(ids).size,'duplicate HTML ID')
const groups=[...html.matchAll(/class="dock-btn(?: active)?" data-group="([^"]+)"/g)].map(m=>m[1])
assert.deepEqual(groups,['overview','privacy','kernel','tools','diagnostics'])
const panels=[...html.matchAll(/data-panel="([^"]+)"/g)].map(m=>m[1])
assert.deepEqual(new Set(panels),new Set(['home','android','hiding','spoofing','susfs','ksu','rom','advanced','info']))
assert.match(modern,/#tab-bar\.tab-bar\s*\{[^}]*grid-template-columns:repeat\(5,minmax\(0,1fr\)\)/s)
assert.match(modern,/body\.body-content\s*\{[^}]*padding-top:0!important/s)
assert.ok(!main.includes('SWIPE_THRESHOLD'),'old swipe handler remains')
assert.ok(!main.includes('^2[0-9]{9,}'),'old incomplete mount-ID regex remains')
assert.ok(diag.includes('/proc/1/mountinfo')&&diag.includes('命名空间')||diag.includes('namespace'))
for(const id of ['logs','mount_summary','suspicious_mounts','duck-audit-button']){
  assert.ok(ids.includes(id),'missing diagnostic element '+id)
}
assert.ok(html.includes('navigation.js')&&html.includes('diagnostics.js'))
assert.ok(html.includes('id="brene-mount-control"')&&html.includes('data-open-panel="susfs"'))
assert.ok(modern.includes('.dock-glyph')&&modern.includes('grid-template-rows:26px 16px'))
for (const id of ['brene-susfs-tools','brene-feature-audit','brene-snapshot-backup','brene-snapshot-restore','brene-mount-excludes','brene-mount-excludes-save']) {
 assert.ok(ids.includes(id),'SuSFS toolkit UI missing '+id)
}
assert.ok(main.includes('susfs-capability-audit.sh')&&main.includes('susfs-snapshot.sh'),'SuSFS CLI bridge absent')
assert.ok(ids.includes('brene-auto-profile')&&ids.includes('susfs_auto_enable'),'missing automatic capability status')
assert.ok(['brene-binary-manager','brene-binary-status','brene-binary-check','brene-binary-apply','brene-binary-rollback','susfs_binary_auto_update'].every(id=>ids.includes(id)),'missing binary updater controls')


const createElement=(dataset={})=>{
  const handlers={}
  const attrs={}
  const classes=new Set()
  return {
    dataset,hidden:false,children:[],type:'',textContent:'',className:'',
    classList:{
      toggle(cls,value){if(value)classes.add(cls);else classes.delete(cls)},
      contains(cls){return classes.has(cls)}
    },
    setAttribute(k,v){attrs[k]=v},
    getAttribute(k){return attrs[k]},
    addEventListener(k,f){handlers[k]=f},
    dispatch(k){handlers[k]?.()},
    append(child){this.children.push(child)},
    replaceChildren(){this.children.length=0}
  }
}
const buttons=groups.map(group=>createElement({group}))
const dock=createElement()
dock.querySelectorAll=()=>buttons
const secondary=createElement()
const views=panels.map(panel=>createElement({panel}))
const listeners={}
const values=new Map()
const ctx={
  document:{
    getElementById(id){return id==='tab-bar'?dock:id==='subnav'?secondary:null},
    querySelectorAll(sel){assert.equal(sel,'.tab-panel');return views},
    createElement(){return createElement()}
  },
  sessionStorage:{getItem:k=>values.get(k)||null,setItem:(k,v)=>values.set(k,v)},
  localStorage:{getItem:()=>null},
  window:{scrollTo(){},addEventListener(k,fn){listeners[k]=fn}}
}
vm.runInNewContext(nav,ctx,{filename:'navigation.js'})
function activePanel(){return views.filter(v=>v.classList.contains('active')).map(v=>v.dataset.panel)}
assert.deepEqual(activePanel(),['home'])
assert.equal(secondary.hidden,true)
buttons[1].dispatch('click')
assert.deepEqual(activePanel(),['hiding'])
assert.equal(secondary.children.length,2)
secondary.children[1].dispatch('click')
assert.deepEqual(activePanel(),['spoofing'])
buttons[3].dispatch('click')
assert.deepEqual(activePanel(),['android'])
assert.equal(secondary.children.length,3)
secondary.children[1].dispatch('click')
assert.deepEqual(activePanel(),['rom'])
secondary.children[2].dispatch('click')
assert.deepEqual(activePanel(),['advanced'])
buttons[2].dispatch('click')
assert.deepEqual(activePanel(),['susfs'])
assert.equal(secondary.children.length,2)
secondary.children[1].dispatch('click')
assert.deepEqual(activePanel(),['ksu'])
buttons[4].dispatch('click')
assert.deepEqual(activePanel(),['info'])
assert.equal(secondary.hidden,true)
listeners['brene-locale-change']({detail:'en'})
buttons[1].dispatch('click')
assert.equal(secondary.children[0].textContent,'Paths')
console.log('PASS: five-item fixed dock, nine preserved panels, subnavigation and layout')
