// BRENE 中文界面：默认简体中文，保留英文切换以便对照原版设置。
// 仅修改呈现层的文本/标签，不修改命令、配置键、用户规则或终端日志。
const CN = {
  'Home':'概览', 'Android':'系统', 'Hiding':'隐藏', 'Spoofing':'伪装',
  'Advanced':'高级', 'Info':'日志', 'General':'设备信息', 'Device Model':'设备型号',
  'Kernel Version':'内核版本', 'Android Version':'安卓版本', 'Custom ROM':'第三方系统',
  'Recommendations':'使用建议', '- Global Umount modules enabled':'— 已启用全局模块卸载',
  '- Use a file manager with root access or not umounted':'— 请使用具有 Root 权限或未被卸载模块的文件管理器',
  'Strong Keyboxes':'强密钥箱', 'Recommended Modules':'推荐模块',
  'Incompatible Modules':'不兼容模块', 'Status: Not installed':'状态：未安装',
  'Latest CI (nightly.link)':'最新 CI 构建（nightly.link）',
  'Settings':'系统设置', 'Developer options':'开发者选项',
  'Options for developers':'启用系统开发者选项', 'USB debugging':'USB 调试',
  'Debug mode when USB is connected':'允许通过 USB 连接进行调试',
  'Wireless debugging':'无线调试','Debug mode when Wi-Fi is connected':'允许通过无线网络调试',
  'Show refresh rate':'显示刷新率','Show the current display refresh rate':'在屏幕上显示当前刷新率',
  'Disable child process restrictions':'关闭子进程限制',
  'Disable restrictions on the system resource usage of the app child processes':'关闭系统对应用子进程资源使用的限制',
  'Max color saturation':'最高色彩饱和度', 'Force maximum color saturation via SurfaceFlinger':'通过 SurfaceFlinger 强制设置最高色彩饱和度',
  'Set logcat and logd buffer to 64K':'将 logcat / logd 缓冲区限制为 64 KB',
  'Reduce CPU overhead and battery drain by shrinking buffer size':'缩小日志缓冲区以减少部分资源占用，可能导致排障日志缺失',
  'Paths Hiding':'路径隐藏','Important Notes:':'注意事项：',
  'Only effective for umounted process with uid ≥ 10.000':'仅对 UID ≥ 10000 且已标记为卸载模块的进程生效',
  'Hide KernelSU directories':'隐藏 KernelSU 目录（可能删除文件）',
  'E.g., /storage/emulated/0/Android/[data|obb|media]/me.weishu.kernelsu':'例如：/storage/emulated/0/Android/[data|obb|media]/me.weishu.kernelsu（此选项会删除部分目录内容）',
  'Hide Custom Recovery':'隐藏第三方 Recovery',
  'Hide Non-standard /sdcard Paths':'隐藏非标准 /sdcard 路径',
  'Standard Paths:':'标准目录：','Hide Non-standard /sdcard/Android Paths':'隐藏非标准 /sdcard/Android 路径',
  'Hide /data/local/tmp Paths':'隐藏 /data/local/tmp 路径',
  'Hide Suspicious PTYs':'隐藏可疑伪终端',
  'Spoofing Features':'伪装功能', 'Spoof Uname':'伪装内核信息（uname）',
  'Spoof uname for all processes':'对所有进程伪装 uname 信息',
  "Only 'release' and 'version' are spoofed as others are no longer needed":'仅伪装 release 和 version 字段',
  'Spoof /proc/cmdline or /proc/bootconfig':'伪装内核启动参数',
  'Spoof the output of /proc/cmdline (non-gki) or /proc/bootconfig (gki) from a text file':'使用文本文件替换 /proc/cmdline（非 GKI）或 /proc/bootconfig（GKI）的读取结果',
  "No root process detects it for now, and this spoofing won't help much actually":'此功能不能保证规避检测；通常不建议无目的启用',
  'System Property Spoofing':'系统属性伪装','Spoof System Properties':'伪装系统属性',
  'Spoof some android system properties':'修改部分 Android 系统属性的报告值',
  'Spoof Fingerprint Properties':'伪装设备指纹属性',
  'Spoof UTC Properties':'伪装时区相关属性',
  'Spoof Date Properties':'伪装日期属性',
  'Spoof OS Security Patch Level Property':'伪装系统安全补丁日期',
  'Spoof Vendor Security Patch Level Property':'伪装厂商安全补丁日期',
  'Spoof Verified Boot Hash Property':'伪装 Verified Boot 哈希',
  'Verified Boot Hash':'Verified Boot 哈希',
  'APPLY':'应用','Apply':'应用','RESET':'重置','Reset':'重置',
  'Status':'状态','SuSFS Variant':'SuSFS 分支类型',
  '..5.u.S Status':'隐藏路径状态（..5.u.S）',
  "SuSFS redirects the sus path to a supposed not-existing path named '..5.u.S', and this is the only way to settle the cross check of returned errno from various syscalls, but one disadvantage is that if the path itself can be written/created by the app (MANAGE_EXTERNAL_STORAGE granted), then it is futile to hide it":'SuSFS 会将隐藏路径重定向至假定不存在的 ..5.u.S 路径，以尽量保持系统调用错误码一致。如果应用有权限创建该路径，隐藏可能失效。',
  'Enabled Features':'内核已启用功能',
  'Built-in Features':'内置功能',
  'Hide Suspicious Mounts For Non-su Processes':'隐藏非 SU 进程的可疑挂载',
  'Prevent zygote from caching the sus mounts in memory, and to keep them hidden from /proc/self/[mounts|mountinfo|mountstat] for non-su processes':'防止 Zygote 缓存可疑挂载，并从非 SU 进程读取的 /proc/self/mounts、mountinfo、mountstats 等信息中隐藏相关条目',
  'AVC Log Spoofing':'AVC 日志伪装',
  "Spoof the sus tcontext 'su' with 'u:r:priv_app:s0:c512,c768' shown in avc log in kernel":'将内核 AVC 日志中的 su 目标安全上下文替换为预设的应用安全上下文',
  'Enabling this may sometimes make developers hard to identify the cause when they are debugging with some permission or selinux issues, so users are advised to disable this when doing so':'启用后可能妨碍 SELinux 权限问题排查，调试时建议关闭',
  'SuSFS Logs':'SuSFS 日志',
  'Enable or disable SuSFS Logs in kernel':'开启或关闭内核 SuSFS 日志',
  'Manual Mode':'自定义规则',
  'Custom Spoof Uname':'自定义 uname 信息',
  "Spoof uname for all processes, set string to 'default' to imply the function to use original string":'对所有进程伪装 uname。填写 default 表示使用原始值。',
  'Kernel Release':'内核 Release','Kernel Version':'内核版本',
  'Added real file path which gets mmapped will be hidden from /proc/self/[maps|smaps|smaps_rollup|map_files|mem|pagemap]':'将被映射的真实文件路径加入隐藏列表，以减少其在进程内存映射信息中的可见性',
  '- It does NOT support hiding for anon memory.':'— 不支持隐藏匿名内存',
  '- It does NOT hide any inline hooks or plt hooks cause by the injected library itself':'— 无法隐藏注入库自身造成的 inline hook 或 PLT hook',
  '- It may not be able to evade detections by apps that implement a good injection detection':'— 不能保证绕过应用的注入检测',
  'Added path and all its sub-paths will be hidden for umounted app process from several syscalls':'对已标记卸载的应用进程，从部分系统调用结果中隐藏指定路径及子路径',
  'Please be reminded that if the target path has upper mounts then make sure the proper layer is added, otherwise it may not be effective for the target process':'目标路径如果存在上层挂载，请确认正确处理对应层级，否则规则可能无效',
  "For paths that are read-only all the time, add them via 'add_sus_path'":'长期只读路径建议使用 add_sus_path',
  'The only difference to add_sus_path is that the added sus_path via this cli will be flagged as SUS_PATH again for the app process when it is being spawned by zygote and marked umounted':'与 add_sus_path 的主要区别：Zygote 创建并标记卸载的新进程会再次应用 SUS_PATH 标记',
  'Also it does not check if the path is existed or not, instead it checks for empty string only, so be careful what to add':'该接口仅检查输入是否为空，不检查路径是否存在，请确认目标路径',
  "For paths that are frequently modified, we can add them via 'add_sus_path_loop'":'经常变化的路径可考虑使用 add_sus_path_loop',
  'Redirect the target path to be opened with user defined path and pre-defined uid scheme':'按照所选 UID 生效范围，将目标文件的打开操作重定向到指定文件',
  'uid_scheme':'UID 生效范围','0: Effective for non-app processes (uid &lt; 10000)':'0：非应用进程（UID 小于 10000）',
  '1: Effective for non-su processes of which uid is 0 (All root process but not with su domain)':'1：UID 为 0、但不在 su 域内的非 SU 进程',
  '2: Effective for non-su processes (Use it carefully!)':'2：所有非 SU 进程（谨慎使用）',
  '= 10000 (Use it carefully!)':'UID ≥ 10000 的应用进程（谨慎使用）',
  '4: Effective for processes that are marked umounted (include most of the init spawned process, use it carefully!)':'4：已标记卸载模块的进程（谨慎使用）',
  '* Important Notes *':'注意事项',
  '- Both target_pathname and redirected_pathname must be existed before they can be added to open_redirect':'— 原路径和重定向目标路径必须都已存在',
  '- Users have to take care of the selinux permission of both target_pathname and redirected_pathname by themselves':'— 请自行确认原路径与重定向路径的 SELinux 权限',
  '- Only effective for current process that matches the pre-defined uid scheme':'— 只对满足指定 UID 条件的进程生效',
  'SUS MAP':'内存映射隐藏 · SUS MAP','SUS PATH':'路径隐藏 · SUS PATH',
  'SUS PATH LOOP':'循环路径隐藏 · SUS PATH LOOP','OPEN_REDIRECT':'文件打开重定向 · OPEN_REDIRECT',
  'MAP':'内存映射','PATH':'路径','PATH LOOP':'循环路径',
  'SUS_KSTAT · Advanced':'文件元数据 · KSTAT',
  '动态 KSTAT 规则 / Dynamic KSTAT':'动态 KSTAT 规则',
  '规则列表 / Rules':'规则列表','Checking kernel support…':'正在检查内核支持情况…',
  '保存规则 / Save':'保存规则',
  '静态 KSTAT / Static KSTAT':'静态 KSTAT 规则',
  '静态规则 / Static rules':'静态规则',
  '保存静态规则 / Save':'保存静态规则',
  'Cmdline / Bootconfig':'启动参数 · Cmdline / Bootconfig',
  '自定义启动参数视图 / Custom boot arguments':'自定义启动参数内容',
  '启用自定义内容 / Enable full-file override':'启用完整文件替换',
  '替代内容 / Replacement content':'替代文件内容',
  '保存启动参数 / Save':'保存启动参数',
  '内核功能矩阵 / Kernel features':'内核功能矩阵',
  'Hide Custom ROM Paths':'隐藏第三方 ROM 路径',
  'Disable umount for your app if it does not work':'若应用运行异常，请取消对该应用的模块卸载设置',
  'Example: Web Browsers':'例如：网页浏览器',
  'Hide Custom ROM Paths (Extreme)':'深度隐藏第三方 ROM 路径',
  'Hide /system/addon.d Path':'隐藏 /system/addon.d 路径',
  'Hide LineageOS Strings':'隐藏 LineageOS 标识',
  'Spoof /system/etc/hosts':'伪装 /system/etc/hosts',
  'Spoof /system/lib64/libstagefright.so':'伪装 /system/lib64/libstagefright.so',
  'Some Custom ROMs use a custom libstagefright.so':'一些第三方 ROM 使用修改过的 libstagefright.so',
  'Remove Custom ROM Properties':'移除第三方 ROM 属性',
  'Some Custom ROM properties':'部分第三方 ROM 属性',
  'Remove Play Integrity Fix Properties':'移除 Play Integrity Fix 属性',
  'Some Play Integrity Fix properties':'部分 Play Integrity Fix 属性',
  'Hide framework-res.apk':'隐藏 framework-res.apk',
  'EXPERIMENTAL':'实验性',
  'It uses SUS MAP to hide it':'通过 SUS MAP 隐藏该文件',
  'SELinux Enforcing':'SELinux 强制模式',
  'Set SELinux mode to Enforcing at boot':'启动时将 SELinux 设为强制模式',
  'Fix /data/local/tmp Inconsistencies':'修正 /data/local/tmp 状态不一致',
  'Reset Settings':'恢复默认设置',
  'Confirm action':'确认操作','Are you sure?':'确定要继续吗？','No':'取消','Yes':'确定',
  'Module Control':'模块管理', 'Disable Modules':'禁用模块','Enable Modules':'启用模块',
  'KernelSU Features':'KernelSU 功能',
  'SU Compat':'SU 兼容模式',
  "SU Compatibility Mode - allows authorized apps to gain root via traditional 'su' command":'允许已授权的应用通过传统 su 命令获取 Root 权限',
  'Kernel Umount':'内核卸载模块',
  'Kernel Umount - controls whether kernel automatically unmounts modules when not needed':'控制内核是否自动为应用卸载不需要的模块挂载',
  'Hide SELinux modification':'隐藏 SELinux 修改痕迹',
  'SELinux Hide - sanitize /sys/fs/selinux access results for app UIDs':'为应用 UID 清理 /sys/fs/selinux 中暴露的修改痕迹',
  'Adding sus mounts to umount list via built-in KernelSU kernel umount':'使用 KernelSU 内置卸载功能将可疑挂载加入卸载列表',
  'Suspicious Mounts':'可疑挂载','BRENE Logs':'BRENE 日志',
  'Enable or disable BRENE Logs':'开启或关闭 BRENE 日志',
  'MOUNTS':'挂载规则','Kernel Release':'内核版本号',
  'Example:':'示例：',
  'UID Filter':'UID 过滤器',
  '0: Effective for non-app processes (uid < 10000)':'0：非应用进程（UID 小于 10000）',
  '3: Effective for processes that are marked umounted with uid >= 10000 (Use it carefully!)':'3：UID 不小于 10000 且已标记卸载的应用进程（谨慎使用）',
  'Status: Installed':'状态：已安装',
  'Failed to load':'读取失败',
  'Normal':'正常','Abnormal':'异常',
  '每行一条：/system/etc/hosts|update 或 /system/etc/hosts|clone。仅在内核启用 SUS_KSTAT 时写入；重启生效。首次记录在 early boot，更新在 boot-completed，因此无法覆盖更早发生的挂载操作。':'每行一条：/system/etc/hosts|update 或 /system/etc/hosts|clone。仅当内核支持 KSTAT 时生效，保存后需重启；开机前后两个阶段不能覆盖全部挂载时机。',
  '每行 13 项，以 | 分隔：绝对路径、ino、dev、nlink、size、atime、atime_nsec、mtime、mtime_nsec、ctime、ctime_nsec、blocks、blksize。值为非负整数或 default。仅在重启后、已存在的文件上应用。':'每行 13 项，以 | 分隔：文件绝对路径及 12 个元数据字段（inode、设备号、链接数、大小、时间、块数等）。填写非负整数或 default，重启后应用。',
  '高级功能：完整替代内容，不是增量参数。必须同时开启上方原有“Cmdline/Bootconfig spoofing”及下面的自定义开关；两者默认关闭。不要删除未知参数。':'高级功能：替换全部启动参数内容，而不是只修改单个参数。必须同时开启内核启动参数伪装和自定义开关，两者默认关闭。请保留未知参数。'
}
const button = document.createElement('button')
button.type = 'button'
button.id = 'brene-locale-button'
button.className = 'brene-locale-button'
button.setAttribute('aria-label', '切换界面语言')
document.querySelector('.header-inner')?.append(button)

let chinese = true
try { chinese = localStorage.getItem('brene_locale') !== 'en' } catch (_) {}
const originals = new WeakMap()
const attributeOriginals = new WeakMap()
const SELECTOR_SKIP = 'script, style, textarea, pre, code, .mono-block, .enabled-config, [contenteditable="true"]'
function clean(text) {
  return text.replace(/\s+/g, ' ').trim()
}
function translate(text) {
  const value = clean(text)
  if (!value || !Object.prototype.hasOwnProperty.call(CN,value)) return null
  return CN[value]
}
const EN_SOURCE = {
  '概览':'Overview',
  '隐私':'Privacy',
  '内核':'Kernel',
  '工具':'Tools',
  '诊断':'Diagnostics',
  '路径隐藏':'Path hiding',
  '信息伪装':'Spoofing',
  'ROM 适配':'ROM settings',
  '高级设置':'Advanced',
  '运行诊断':'Diagnostics',
  '挂载来源与异常线索':'Mount evidence',
  'BRENE 运行日志':'BRENE runtime logs',
  '只读检查当前环境；不会修改挂载或内核状态。':'Read-only checks of the current environment; nothing is modified.',
  '查看启动及规则应用记录':'View boot and rule application logs',
  '生成只读检测报告':'Generate read-only report',
  'AutoShield · 自动规则管理':'AutoShield · Automatic Rules',
  '自动发现模块映射路径':'Discover module native-library mappings',
  '扫描已启用模块中 Zygisk 的原生 .so 文件，生成 SUS_MAP 候选清单。默认只预览，不隐藏，不删除文件。开启自动应用后，每次启动仅尝试应用内核支持的规则。':'Scan enabled modules for Zygisk .so files and preview SUS_MAP candidates. Preview never applies rules or deletes files.',
  '正在读取 AutoShield 状态…':'Reading AutoShield status…',
  '尚未扫描':'Not scanned yet',
  '扫描与预览':'Scan and preview',
  '启用并应用':'Enable and apply',
  '关闭自动应用':'Disable automatic application',
  '仅对符合条件的映射文件生成规则；并不保证所有模块痕迹都能隐藏。关闭后不再自动添加规则，已有内核规则必须重启才能清除。':'Only eligible library mappings are considered. Results are not guaranteed. Reboot after disabling to clear already-applied kernel rules.'
}
function localizedOutput(original,node, outputChinese = chinese) {
  if (!outputChinese) return EN_SOURCE[clean(original)] ?? original
  let output = applyText(original)
  // Device summaries are UI text, but raw kernel logs and paths are untouched.
  if (node?.parentElement?.closest('#custom-rom') && /^Yes\\s*$/.test(original)) output = '检测到'
  if (node?.parentElement?.closest('#custom-rom') && /^No\\s*$/.test(original)) output = '未检测到'
  if (/^Default: /m.test(original)) output = output.replace(/Default:/g,'原始值：').replace(/Spoofed:/g,'伪装值：')
  return output
}
function updateNode(node) {
  if (!node || node.nodeType !== 3 || node.parentElement?.closest(SELECTOR_SKIP)) return
  const current = node.nodeValue || ''
  const saved = originals.get(node)
  const previousChinese = saved ? localizedOutput(saved,node,true) : null
  const previousEnglish = saved ? localizedOutput(saved,node,false) : null
  // A runtime component may replace its own text after the first translation.
  let original = saved || current
  if (saved && current !== saved && current !== previousChinese && current !== previousEnglish) original = current
  originals.set(node,original)
  const output = localizedOutput(original,node)
  if (current !== output) node.nodeValue = output
}
function applyText(raw) {
  const replacement = translate(raw)
  return replacement == null ? raw : raw.replace(raw.trim(),replacement)
}
function updateAttributes(element) {
  if (!element || element.nodeType !== 1 || element.matches(SELECTOR_SKIP)) return
  const attrs = ['label','placeholder','title','aria-label']
  let saved = attributeOriginals.get(element)
  if (!saved) { saved = new Map(); attributeOriginals.set(element,saved) }
  for (const name of attrs) {
    const current = element.getAttribute(name)
    if (current == null) continue
    let original = saved.get(name)
    if (original === undefined || (current !== original && current !== localizedOutput(original,null,true) && current !== localizedOutput(original,null,false))) {
      original = current; saved.set(name,original)
    }
    const target = localizedOutput(original,null)
    if (current !== target) element.setAttribute(name,target)
  }
}
function applyTree(root) {
  if (!root) return
  if (root.nodeType === 3) { updateNode(root); return }
  if (root.nodeType !== 1 && root.nodeType !== 9) return
  if (root.nodeType === 1) updateAttributes(root)
  const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT)
  while (walker.nextNode()) updateNode(walker.currentNode)
  if (root.querySelectorAll) root.querySelectorAll('[label],[placeholder],[title],[aria-label]').forEach(updateAttributes)
}
function render() {
  document.documentElement.lang = chinese ? 'zh-CN' : 'en'
  button.textContent = chinese ? 'EN' : '中文'
  button.title = chinese ? '切换为英文' : '切换为中文'
  applyTree(document.body)
}
button.addEventListener('click', () => {
  chinese = !chinese
  try { localStorage.setItem('brene_locale', chinese ? 'zh' : 'en') } catch (_) {}
  render()
  if (typeof window !== 'undefined' && typeof window.dispatchEvent === 'function') {
    window.dispatchEvent(new CustomEvent('brene-locale-change', {detail:chinese?'zh':'en'}))
  }
})
// Observe runtime text refreshes (feature reports and module status) without touching logs.
const observer = new MutationObserver(records => {
  for(const record of records) {
    if(record.type === 'characterData') updateNode(record.target)
    if(record.type === 'attributes') updateAttributes(record.target)
    if(record.type === 'childList') record.addedNodes.forEach(applyTree)
  }
})
observer.observe(document.body, {childList:true,subtree:true,characterData:true,attributes:true,attributeFilter:['label','placeholder','title','aria-label']})
render()
