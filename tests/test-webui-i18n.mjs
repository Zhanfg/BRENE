#!/usr/bin/env node
// BRENE WebUI localization smoke test; no external packages required.
import fs from 'node:fs'
import vm from 'node:vm'
import assert from 'node:assert/strict'

const root = 'module/webroot/'
const html = fs.readFileSync(root+'index.html','utf8')
const locale = fs.readFileSync(root+'locale.js','utf8')
const css = fs.readFileSync(root+'modern.css','utf8')
const app = fs.readFileSync(root+'script.js','utf8')
const ids = [...html.matchAll(/\bid="([^"]+)"/g)].map(m=>m[1])
assert.equal(new Set(ids).size,ids.length,'duplicate HTML ID')
for(const id of ['tab-bar','brene-kstat-rules','brene-static-kstat-rules','brene-boot-payload','use_custom_cmdline_or_bootconfig']){
  assert.ok(ids.includes(id),'missing existing control '+id)
}
assert.match(html,/<html lang="zh-CN">/)
assert.match(html,/modern\.css/)
for(const selector of ['.tab-bar','.tab-btn.active','.card-row','.brene-kstat','@media (prefers-color-scheme: dark)']){
  assert.ok(css.includes(selector),'missing style: '+selector)
}
assert.match(css,/@media \(min-width: 780px\)/)
assert.match(app,/const configs = \[/)

let activeObserver
const listeners = new Map()
const attrs = new Map()
const button = {
  nodeType:1, id:'', className:'', type:'', textContent:'', title:'',
  matches:()=>false, getAttribute:k=>attrs.get(k)??null,
  setAttribute:(k,v)=>attrs.set(k,v),
  addEventListener:(key,cb)=>listeners.set(key,cb),
  querySelectorAll:()=>[]
}
const parent = {closest:selector=>null}
const home = {nodeType:3,nodeValue:'Home',parentElement:parent}
const auto = {nodeType:3,nodeValue:'扫描与预览',parentElement:parent}
const nodes = [home,auto]
const body = {nodeType:1,matches:()=>false,querySelectorAll:()=>[],getAttribute:()=>null,setAttribute:()=>{}}
const document = {
  documentElement:{lang:'en'},body,
  querySelector:selector=>selector==='.header-inner'?{append:()=>{}}:null,
  createElement:()=>button,
  createTreeWalker:()=>{let i=0;return{currentNode:null,nextNode(){if(i>=nodes.length)return false;this.currentNode=nodes[i++];return true}}}
}
class FakeObserver {
  constructor(callback){activeObserver=callback}
  observe(){}
}
const context = {
  document, NodeFilter:{SHOW_TEXT:4},
  MutationObserver: FakeObserver,
  localStorage:{getItem:()=>null,setItem:()=>{}},
  WeakMap, Map, Object, RegExp
}
vm.runInNewContext(locale,context,{filename:'locale.js'})
assert.equal(home.nodeValue,'概览','Simplified Chinese should be default')
assert.equal(auto.nodeValue,'扫描与预览')
assert.equal(document.documentElement.lang,'zh-CN')
assert.equal(button.textContent,'EN')
listeners.get('click')()
assert.equal(home.nodeValue,'Home','English toggle should restore source')
assert.equal(auto.nodeValue,'Scan and preview','English toggle should translate the Chinese-sourced AutoShield UI')
listeners.get('click')()
assert.equal(home.nodeValue,'概览','Chinese toggle should restore translation')
assert.equal(auto.nodeValue,'扫描与预览','AutoShield source should round-trip to Chinese')
home.nodeValue='Status: Installed'
activeObserver([{type:'characterData',target:home}])
assert.equal(home.nodeValue,'状态：已安装','dynamic updates must be translated')
listeners.get('click')()
assert.equal(home.nodeValue,'Status: Installed','dynamic text should restore on English toggle')
console.log('BRENE WebUI structure, responsive styles and zh-CN locale: passed')
