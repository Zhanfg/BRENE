import { exec, toast } from './assets/kernelsu.js'
import './assets/mwc.js'

document.querySelector('div.preload-hidden').classList.remove('preload-hidden')

const MODDIR = '/data/adb/modules/brene'
const PERSISTENT_DIR = '/data/adb/brene'
const configs = [
	{
		id: 'hide_sus_mnts_for_non_su_procs',
		action: (enabled) => setFeature(`susfs hide_sus_mnts_for_non_su_procs ${enabled ? 1 : 0}`),
	},
	{
		id: 'su_compat',
		action: (enabled) => setFeature(`ksud feature set su_compat ${enabled ? 1 : 0} && ksud feature save`),
	},
	{
		id: 'kernel_umount',
		action: (enabled) => setFeature(`ksud feature set kernel_umount ${enabled ? 1 : 0} && ksud feature save`),
	},
	{
		id: 'selinux_hide',
		action: (enabled) => setFeature(`ksud feature set selinux_hide ${enabled ? 1 : 0} && ksud feature save`),
	},
	{
		id: 'developer_options',
		action: (enabled) => setFeature(`settings put global development_settings_enabled ${enabled ? 1 : 0}`),
	},
	{
		id: 'usb_debugging',
		action: (enabled) => setFeature(`settings put global adb_enabled ${enabled ? 1 : 0}`),
	},
	{
		id: 'wireless_debugging',
		action: (enabled) => setFeature(`settings put global adb_wifi_enabled ${enabled ? 1 : 0}`),
	},
	{
		id: 'selinux',
		action: (enabled) => setFeature(`setenforce ${enabled ? 1 : 0}`),
	},
	{
		id: 'saturation',
		action: (enabled) => setFeature(`service call SurfaceFlinger 1022 f ${enabled ? 2.0 : 1.0}`),
	},
	{
		id: 'show_refresh_rate',
		action: (enabled) => setFeature(`service call SurfaceFlinger 1034 i32 ${enabled ? 1 : 0}`),
	},
	{
		id: 'disable_child_process_restrictions',
		action: (enabled) => {
			setFeature(`resetprop -n persist.sys.fflag.override.settings_enable_monitor_phantom_procs ${enabled ? false : true}`)
		},
	},
	{ id: 'pif_props' },
	{ id: 'rom_props' },
	{ id: 'brene_logs' },
	{ id: 'enable_log' },
	{ id: 'spoof_uname' },
	{ id: 'spoof_hosts' },
	{ id: 'hide_addon_d' },
	{ id: 'shrink_buffer_size' },
	{ id: 'custom_spoof_uname' },
	{ id: 'hide_suspicious_pty' },
	{ id: 'hide_custom_recovery' },
	{ id: 'hide_lineage_strings' },
	{ id: 'spoof_libstagefright' },
	{ id: 'hide_ksu_directories' },
	{ id: 'hide_custom_rom_paths' },
	{ id: 'hide_custom_rom_paths_2' },
	{ id: 'hide_framework_res_apk' },
	{ id: 'enable_avc_log_spoofing' },
	{ id: 'spoof_cmdline_or_bootconfig' },
	{ id: 'use_custom_cmdline_or_bootconfig' },
	{ id: 'fix_data_local_tmp_inconsistencies' },
	{ id: 'spoof_system_properties' },
	{ id: 'spoof_fingerprint_properties' },
	{ id: 'spoof_utc_properties' },
	{ id: 'spoof_date_properties' },
	{ id: 'spoof_os_security_patch_level_property' },
	{ id: 'spoof_vendor_security_patch_level_property' },

	{ id: 'paths_hiding__non_standard_sdcard' },
	{ id: 'paths_hiding__non_standard_sdcard_android' },
	{ id: 'paths_hiding__data_local_tmp' },
]

// Open URLs
document.querySelectorAll('a[href]').forEach((element) => {
	element.addEventListener('click', (event) => {
		event.preventDefault()
		if (element.href.startsWith('https://') || element.href.startsWith('http://')) exec(`am start -a android.intent.action.VIEW -d ${shellQuote(element.href)}`)
	})
})

// Load Android Version
exec('resetprop ro.build.version.release && resetprop ro.build.version.sdk').then((result) => {
	const container = document.querySelector('#android-version .card-row__sub')

	if (result.errno !== 0) {
		container.innerText = 'Failed to load'
		return
	}
	const results = result.stdout.replaceAll('\n', ' ')
	const splits = results.split(' ')
	container.innerText = `${splits[0]} (API ${splits[1]}) | SDK ${splits[1]}`
})

// Load SuSFS Variant
exec('susfs show variant').then((result) => {
	const container = document.querySelector('#susfs-variant .card-row__sub')

	if (result.errno !== 0) {
		container.innerText = 'Failed to load'
		return
	}
	container.innerText = result.stdout
})

// Load Kernel Version
exec("cat /proc/version | awk '{print $3}' && uname -r").then((result) => {
	const container = document.querySelector('#kernel-version .card-row__sub')

	if (result.errno !== 0) {
		container.innerText = 'Failed to load'
		return
	}

	const [procVersion, uname] = result.stdout.split('\n')
	if (procVersion === uname) {
		container.innerText = `Default: ${procVersion}`
	} else {
		container.innerText = `Default: ${procVersion}\nSpoofed: ${uname}`
	}
})

// Load Device Model Status
exec('resetprop ro.product.manufacturer && resetprop ro.product.model && resetprop ro.product.device').then((result) => {
	const container = document.querySelector('#device-model .card-row__sub')

	if (result.errno !== 0) {
		container.innerText = 'Failed to load'
		return
	}

	let model
	const splits = result.stdout.split('\n')

	exec('resetprop ro.product.marketname')
		.then((result) => {
			if (result.errno !== 0) return
			model = result.stdout
		})
		.then(() => {
			model = model || splits[1]
			container.innerText = `${splits[0]} ${model} | ${splits[2]}`
		})
})

// Load Custom ROM Status
exec('[[ -n "$(find /system -iname "*lineage*")" ]] && echo "Yes" || echo "No"').then((result) => {
	const container = document.querySelector('#custom-rom .card-row__sub')

	if (result.errno !== 0) {
		container.innerText = 'Failed to load'
		return
	}
	container.innerText = result.stdout
})

// Load ..5.u.S Status
exec('[[ -e /storage/emulated/0/..5.u.S ]] && echo "Abnormal" || echo "Normal"').then((result) => {
	const container = document.querySelector('#sus-status .card-row__sub')

	if (result.errno !== 0) {
		container.innerText = 'Failed to load'
		return
	}
	container.innerText = result.stdout
})

// Query modules once and tolerate unavailable, blank or unexpected ksud output.
exec('ksud module list').then((result) => {
  const recommended = document.querySelector('#recommended-modules')
  const incompatible = document.querySelector('#incompatible-modules')
  let modules = null
  if (result.errno === 0 && result.stdout.trim()) {
    try {
      const decoded = JSON.parse(result.stdout)
      if (Array.isArray(decoded)) modules = decoded
      else if (Array.isArray(decoded?.modules)) modules = decoded.modules
    } catch (_) { /* Leave status as unavailable instead of crashing WebUI. */ }
  }
  for (const group of [recommended, incompatible]) {
    if (!group) continue
    group.querySelectorAll('.card-row').forEach(row => {
      const status = row.querySelector('.status-text')
      if (!status) return
      if (!modules) {
        status.textContent = '状态：无法读取模块列表'
        status.style.color = 'var(--brene-muted)'
        return
      }
      const ids = new Set(modules.map(mod => mod?.id).filter(Boolean))
      if (ids.has(row.getAttribute('data-module'))) {
        status.textContent = 'Status: Installed'
        status.style.color = group === recommended ? '#4CAF50' : '#d24b4b'
      } else {
        status.textContent = 'Status: Not installed'
        status.style.color = ''
      }
    })
  }
  // Preserve upstream special case for Tricky Addon.
  if (recommended) {
    exec('test -e /data/adb/modules/TA_utl').then(check => {
      if (check.errno !== 0) return
      const row = recommended.querySelector('[data-module="tricky_addon"] .status-text')
      if (row) {
        row.textContent = 'Status: Installed'
        row.style.color = '#4CAF50'
      }
    })
  }
}).catch(() => {
  document.querySelectorAll('#recommended-modules .status-text, #incompatible-modules .status-text')
    .forEach(node => { node.textContent='状态：查询失败' })
})

// Load enabled features
exec('susfs show enabled_features').then((result) => {
	const container = document.getElementById('kernel-features-container')

	if (result.errno !== 0) {
		container.innerText = '无法读取内核功能列表'
		return
	}
	container.innerText = result.stdout.replaceAll('CONFIG_KSU_SUSFS_', '')
})

// Mount diagnostics and log handling are centralized in diagnostics.js.

// Load brene version
exec(`grep "^version=" ${MODDIR}/module.prop | cut -d'=' -f2`).then((result) => {
	const element = document.getElementById('brene-version')
	element.innerText = result.errno === 0 ? result.stdout : 'unknown'
})

// Load susfs version
exec('susfs show version').then((result) => {
	const element = document.getElementById('susfs-version')
	element.innerText = result.errno === 0 ? `${result.stdout}+` : 'unknown'
})

// Helper function to update config
// Never put WebUI text directly inside a shell program or here-document.
function shellQuote(input) {
 return "'" + String(input).replace(/'/g, "'\\''") + "'"
}
function safeSaveTextFile(filename, content) {
 const allowed = new Set(['custom_sus_map.txt','custom_sus_path.txt','custom_sus_path_loop.txt',
  'custom_open_redirect.txt','custom_kernel_umount.txt'])
 if(!allowed.has(filename)) return Promise.resolve({errno:1,stderr:'Invalid target'})
 const bytes = new TextEncoder().encode(content)
 if(bytes.length > 65536) return Promise.resolve({errno:1,stderr:'Too much text (64 KiB limit)'})
 let binary=''
 for(const byte of bytes) binary+=String.fromCharCode(byte)
 const base64=btoa(binary)
 return exec(`printf '%s' ${shellQuote(base64)} | base64 -d > ${shellQuote(PERSISTENT_DIR+'/'+filename)}`)
}
function updateConfig(config, value) {
	exec(`sed -i "s/^${config}=.*/${config}=${value}/" ${PERSISTENT_DIR}/config.sh`).then((result) => {
		if (result.errno !== 0) toast('保存配置失败')
	})
}

// TEMP
// Helper function to update config
function updateConfig2(config, value) {
 if (!/^[a-z_]+$/.test(config) || !/^[A-Za-z0-9._+:@#, -]{0,128}$/.test(value)) {
  toast('配置值不合法')
  return
 }
 const escaped = value.replace(/[\\&|]/g, char => '\\' + char)
 const sedExpr = `s|^${config}=.*|${config}='${escaped}'|`
 exec(`sed -i ${shellQuote(sedExpr)} ${shellQuote(PERSISTENT_DIR+'/config.sh')}`).then(result => {
  if(result.errno !== 0) toast('保存配置失败')
 })
}

// Helper function to set config immedialtely that no need to reboot
function setFeature(cmd) {
	exec(cmd).then((result) => {
		toast(result.errno === 0 ? '已应用，无需重启' : result.stderr)
	})
}

// Load config and add toggle event
exec(`cat ${PERSISTENT_DIR}/config.sh`).then((result) => {
	if (result.errno !== 0) {
		toast('读取配置失败')
		return
	}

	const configValues = Object.fromEntries(
		result.stdout
			.split('\n')
			.filter((line) => line.includes('='))
			.map((line) => {
				const [key, ...val] = line.split('=')
				return [
					key.trim(),
					val
						.join('=')
						.trim()
						.replace(/^['"](.*)['"]$/, '$1'),
				]
			}),
	)

	// custom uname
	document.getElementById('custom_uname_release').value = configValues['config_custom_uname_kernel_release']
	document.getElementById('custom_uname_version').value = configValues['config_custom_uname_kernel_version']

	// Verified Boot Hash
	document.getElementById('vbh_text_field').value = configValues['config_spoof_verified_boot_hash']

	// toggle
	configs.forEach((config) => {
		const configId = `config_${config.id}`
		const element = document.getElementById(config.id)
		if (!element) return

		const value = configValues[configId]
		if (value !== undefined) {
			element.selected = parseInt(value) === 1
		}

		element.addEventListener('change', async () => {
			const enabled = element.selected
			const newConfigValue = +enabled
			updateConfig(configId, newConfigValue)
			if (config.action) config.action(enabled)
		})
	})

	// Reset Settings
	const dialog = document.getElementById('dialog')
	const openButton = document.getElementById('reset_settings')
	openButton.addEventListener('click', () => {
		dialog.show()
	})
	dialog.addEventListener('close', async () => {
		if (dialog.returnValue !== 'confirm') return
		const result = await exec(`cp -f ${MODDIR}/config.sh ${PERSISTENT_DIR}/config.sh`)
		if (result.errno !== 0) { toast(result.stderr || '恢复默认设置失败'); return }
		const defaults = await exec(`cat ${PERSISTENT_DIR}/config.sh`)
		if (defaults.errno !== 0) { toast('无法重新加载默认配置'); return }
		const newValues = Object.fromEntries(defaults.stdout.split('\n')
			.filter(line => /^config_[a-z_]+=/.test(line))
			.map(line => {
				const pos = line.indexOf('=')
				return [line.slice(0,pos), line.slice(pos+1).trim().replace(/^['"](.*)['"]$/, '$1')]
			}))
		configs.forEach(config => {
			const element = document.getElementById(config.id)
			const value = newValues['config_'+config.id]
			if (element && value !== undefined) element.selected = Number(value) === 1
		})
		const release = document.getElementById('custom_uname_release')
		const version = document.getElementById('custom_uname_version')
		const digest = document.getElementById('vbh_text_field')
		if(release) release.value = newValues.config_custom_uname_kernel_release || 'default'
		if(version) version.value = newValues.config_custom_uname_kernel_version || 'default'
		if(digest) digest.value = newValues.config_spoof_verified_boot_hash || ''
		toast('已恢复默认设置，重启后生效')
	})
})

// KSU Module Control
;(async () => {
	const enableButton = document.getElementById('enable_ksu_modules')
	const disableButton = document.getElementById('disable_ksu_modules')

	const toggleAllModules = (enable) => {
		exec(`
			for i in /data/adb/modules/*; do
				${enable ? 'rm -f' : 'touch'} "$i/disable"
			done
		`).then((result) => {
			toast(result.errno === 0 ? '保存成功' : result.stderr)
		})
	}

	enableButton.addEventListener('click', () => toggleAllModules(true))
	disableButton.addEventListener('click', () => toggleAllModules(false))
})()

// Custom Uname buttons
;(async () => {
	const unameRelease = document.getElementById('custom_uname_release')
	const unameVersion = document.getElementById('custom_uname_version')

	const updateUname = (release, version) => {
		updateConfig2('config_custom_uname_kernel_release', release)
		updateConfig2('config_custom_uname_kernel_version', version)
		setFeature(`susfs set_uname ${shellQuote(release)} ${shellQuote(version)}`)
	}

	// Apply
	document.getElementById(`button_custom_uname_apply`).onclick = () => {
		if (unameRelease.value !== '' && unameVersion.value !== '') {
			updateUname(unameRelease.value, unameVersion.value)
		}
	}

	// Reset
	document.getElementById(`button_custom_uname_reset`).onclick = () => {
		updateUname('default', 'default')
		unameRelease.value = 'default'
		unameVersion.value = 'default'
	}
})()

// Verified Boot Hash
;(async () => {
	const button = document.getElementById('vbh_button')
	const textField = document.getElementById('vbh_text_field')

	button.addEventListener('click', () => {
		const digest = textField.value.trim()
  if (!/^[0-9a-fA-F]{64}$/.test(digest)) { toast('请输入 64 位十六进制哈希'); return }
  updateConfig2('config_spoof_verified_boot_hash', digest)

		exec(`resetprop -n ro.boot.vbmeta.digest ${shellQuote(digest)}`).then((result) => {
			if (result.errno === 0) {
				toast('已应用，无需重启')
			} else {
				toast('更新系统属性失败')
			}
		})
	})

	// textField.addEventListener('focus', () => {
	// 	setTimeout(() => {
	// 		window.scrollTo({
	// 			top: Math.max(document.body.scrollHeight, document.documentElement.scrollHeight),
	// 		})
	// 	}, 500)
	// })
})()

//
;(async () => {
	const mapField = document.getElementById('custom_sus_map_text_field')
	const pathField = document.getElementById('custom_sus_path_text_field')
	const loopField = document.getElementById('custom_sus_path_loop_text_field')
	const openRedirectField = document.getElementById('custom_open_redirect_text_field')
	const applyButton = document.getElementById('unified_apply_button')
	const tabs = document.getElementById('sus_tabs')
	const scrollContainer = document.getElementById('horizontal_scroll_container')

	// Load all contents
	exec(`cat ${PERSISTENT_DIR}/custom_sus_map.txt`).then((result) => {
		mapField.value = result.errno === 0 ? `${result.stdout}` : ''
	})
	exec(`cat ${PERSISTENT_DIR}/custom_sus_path.txt`).then((result) => {
		pathField.value = result.errno === 0 ? `${result.stdout}` : ''
	})
	exec(`cat ${PERSISTENT_DIR}/custom_sus_path_loop.txt`).then((result) => {
		loopField.value = result.errno === 0 ? `${result.stdout}` : ''
	})
	exec(`cat ${PERSISTENT_DIR}/custom_open_redirect.txt`).then((result) => {
		openRedirectField.value = result.errno === 0 ? `${result.stdout}` : ''
	})

	// Tabs and Scroll Sync
	tabs.addEventListener('change', () => {
		const index = tabs.activeTabIndex
		const width = scrollContainer.getBoundingClientRect().width
		scrollContainer.scrollTo({
			left: width * index,
			behavior: 'smooth',
		})
	})

	let scrollTimeout
	scrollContainer.addEventListener('scroll', () => {
		clearTimeout(scrollTimeout)
		scrollTimeout = setTimeout(() => {
			const width = scrollContainer.getBoundingClientRect().width
			const index = Math.round(scrollContainer.scrollLeft / width)
			if (tabs.activeTabIndex !== index) {
				tabs.activeTabIndex = index
			}
		}, 50)
	})

	applyButton.onclick = () => {
		const index = tabs.activeTabIndex
		let file = ''
		let content = ''

		switch (index) {
			case 0:
				file = 'custom_sus_map.txt'
				content = mapField.value
				break
			case 1:
				file = 'custom_sus_path.txt'
				content = pathField.value
				break
			case 2:
				file = 'custom_sus_path_loop.txt'
				content = loopField.value
				break
			case 3:
				file = 'custom_open_redirect.txt'
				content = openRedirectField.value
				break
		}

		if (file) {
			if (content === '') {
				safeSaveTextFile(file, '').then((result) => {
					toast(result.errno === 0 ? '保存成功，重启后生效' : result.stderr)
				})
			} else {
				content = content.replaceAll('/sdcard', '/storage/emulated/0')

				safeSaveTextFile(file, content).then((result) => {
					toast(result.errno === 0 ? '保存成功，重启后生效' : result.stderr)
				})
			}
		}
	}
})()

// Manual Kernel Umount
;(async () => {
	const mountField = document.getElementById('custom_kernel_umount_text_field')
	const applyButton = document.getElementById('kernel_umount_apply_button')

	// Load all content
	exec(`cat ${PERSISTENT_DIR}/custom_kernel_umount.txt`).then((result) => {
		mountField.value = result.errno === 0 ? `${result.stdout}` : ''
	})

	applyButton.onclick = () => {
		let file = 'custom_kernel_umount.txt'
		let content = mountField.value

		if (file) {
			if (content === '') {
				safeSaveTextFile(file, '').then((result) => {
					toast(result.errno === 0 ? '保存成功' : result.stderr)
				})
			} else {
				safeSaveTextFile(file, content).then((result) => {
					toast(result.errno === 0 ? '保存成功' : result.stderr)
				})
			}
		}
	}
})()

// Navigation is managed by navigation.js. Original panel IDs remain unchanged.
