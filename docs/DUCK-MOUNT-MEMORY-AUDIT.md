# DuckDetector PJZ110 — Mount/Memory 证据校验

本工具只进行 **read-only 检查**，不添加隐藏规则，不修改 `/proc`、`statx`、挂载命名空间或进程内存。TEE 不在 BRENE 范围。

参考：Duck Detector [Memory EVIDENCE](https://github.com/eltavine/Duck-Detector-Refactoring/blob/23d053f8b2f8291bf88d1a556a04cc8c19f64765/feature/memory/EVIDENCE.md) 和 [Mount EVIDENCE](https://github.com/eltavine/Duck-Detector-Refactoring/blob/23d053f8b2f8291bf88d1a556a04cc8c19f64765/feature/mount/EVIDENCE.md)。

## PJZ110 报告的实际问题

- Memory：13 个高风险信号均来自 `/vendor/lib64` 厂商库可执行映射的 **Shared_Dirty** 统计；另有 9 个 Swap review。报告中的 GOT/PLT、函数入口、加载器可见性、FD-backed code、signal handlers 均为 Clean。高风险启发式结果需要同机型同 ROM、同负载条件下的基线，而不是自动遮蔽这些驱动库。
- Mount：`/system/bin/busybox` 可见，`/system` 和 `/vendor` 解析为 overlayfs。抓取的 `/proc/self/mountinfo` 未发现明确 Root 路径。单独 overlayfs 并不证明隐藏或异常：AOSP 的 adb remount 工具也会使用 overlayfs。
- Mount 的 anonymous minor gap、peer group ID、非原子 statx mount IDs 以及隔离进程 namespace inode 差异，按检测器自身说明 **不能单独认定为隐藏/Root**。
- Zygisk/SELinux/Kernel 标志属于报告中的 Clean 项，不需要额外追加不必要的内核 Hook。

## 收集运行态信息

安装 BRENE 开发包后，在 Root Shell 运行（**脚本无需参数**）：

```sh
sh /data/adb/modules/brene/tools/duck-evidence-audit.sh
```

报告写入 `/sdcard/Download/BRENE_Duck_Evidence_日期_时间.txt`；SD 卡不可写时退回 `/data/local/tmp`。

**运行时确保 DuckDetector 尚在运行**，这样才能读取 `/proc/<pid>/smaps` 和该进程的挂载表。报告还会列出当前 Shell 所见的 `statfs` 类型；该值属于 shell 命名空间，不能替代 DuckDetector 的具体 namespace。

采集器：
- 只统计进程可执行系统/厂商库 VMA 的 Shared_Dirty 和 Swap，不读取代码字节，也不会修改页状态；
- 记录指定进程中相关挂载信息和 BusyBox 可见位置；
- 对不可访问路径标记 unavailable，不当作干净或异常；
- 不上传诊断数据，不启用或关闭 Root/SuSFS 配置。

如果下一轮报告与初始报告值不一致，先控制测试条件（同 ROM、相同 DuckDetector 页面、同 GPU 负载、尽量相同启动阶段），否则大小不同不能说明修复成功。

## 外部 KO 编译的可验证性

第三方内核模块必须与运行的确切内核版本、配置、符号版本及 KMI 匹配。`modules_prepare` 不等于完整模块所需的 `Module.symvers`；没有可核对的内核构建输出，就无法证明外置 `.ko` 能加载。即使成功加载，模拟 `smaps` 或 `mountinfo` 结果也不能修复真实脏页或错误挂载。

此阶段 **没有编译或者装载额外 KO**。下一步应当先确认 overlay 的来源和厂商页统计的基线，然后才选择实际修复手段。
