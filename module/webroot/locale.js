// Non-invasive bilingual presentation: all original config IDs and commands remain unchanged.
const labels = {
  'Home':'总览','Android':'安卓','Hiding':'隐藏','Spoofing':'伪装',
  'SuSFS':'SuSFS','KSU':'KSU','ROM':'ROM','Advanced':'高级','Info':'信息',
  'General':'设备概览','Recommendations':'使用建议','Recommended Modules':'推荐模块',
  'Incompatible Modules':'不兼容模块','Status':'状态','Enabled Features':'内核已启用功能',
  'Built-in Features':'内置功能','Manual Mode':'手动规则',
  'Custom ROM':'自定义 ROM','Kernel Umount':'内核卸载管理',
  'Device Model':'设备型号','Kernel Version':'内核版本','Android Version':'安卓版本',
  'Custom ROM':'自定义 ROM','SuSFS Variant':'SuSFS 变体','Suspicious Mounts':'可疑挂载',
  'BRENE Logs':'BRENE 日志','Hide Suspicious Mounts For Non-su Processes':'隐藏非 SU 进程的可疑挂载',
  'AVC Log Spoofing':'AVC 日志伪装','SuSFS Logs':'SuSFS 日志',
  'Hide Custom ROM Paths':'隐藏自定义 ROM 路径',
  'Hide Custom ROM Paths (Extreme)':'深度隐藏自定义 ROM 路径',
  'Hide /system/addon.d Path':'隐藏 /system/addon.d 路径',
  'Hide LineageOS Strings':'隐藏 LineageOS 字符串',
  'Hide SELinux modification':'隐藏 SELinux 修改',
  'Important Notes:':'注意事项：',
  'Example:':'示例：','Reset Settings':'重置设置',
  'APPLY':'保存规则','Apply':'应用','Settings':'设置',
  'Enable or disable BRENE Logs':'开启或关闭 BRENE 日志',
  'Enable or disable SuSFS Logs in kernel':'开启或关闭内核 SuSFS 日志',
};
const localeToggle = document.createElement('button');
localeToggle.type='button';
localeToggle.className='brene-locale-button';
localeToggle.id='brene-locale-button';
localeToggle.setAttribute('aria-label','Switch language / 切换语言');
document.querySelector('.header-inner')?.append(localeToggle);
let zh = true;
try{zh=localStorage.getItem('brene_locale') !== 'en'}catch(_){}
const entries = [];
const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
while(walker.nextNode()){
  const node=walker.currentNode;
  if(node.parentElement?.closest('script,style,pre,code,textarea'))continue;
  const original=node.nodeValue;
  const key=original.trim();
  if(Object.prototype.hasOwnProperty.call(labels,key)) entries.push([node,original,labels[key]]);
}
function renderLocale(){
  document.documentElement.lang=zh?'zh-CN':'en';
  for(const [node,orig,translated] of entries){
    node.nodeValue=zh?orig.replace(orig.trim(),translated):orig;
  }
  localeToggle.textContent=zh?'EN':'中文';
  localeToggle.title=zh?'Switch to English':'切换为中文';
}
localeToggle.addEventListener('click',()=>{
 zh=!zh;
 try{localStorage.setItem('brene_locale',zh?'zh':'en')}catch(_){}
 renderLocale();
});
renderLocale();
