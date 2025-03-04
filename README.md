# Device

**查看手机的部分状态**

感谢 Cute_9970 提供的查看电池状态代码

感谢 JARK006 提供的查看冻结状态代码

# FBO Check

**查看 FBO 环境**

感谢 The Voyager 提供的检测方法

感谢 Weverse 提供触发条件判断

# Disable_Millet

**关闭 Millet 的模块，让 NoActive 更好的工作**

感谢 Myflvor 的 Millet_Config_v2 模块

Disable_Millet 在 Millet_Config_v2 的基础上增加了环境判断后写入到模块描述的功能

# Power_status

**此脚本用来查看电池掉电的情况，数据来自 `dumpsys batterystats`，数据仅供参考**

# xiaomi_neofetch

**在 Device 的基础上，增加了 ASCII art 模仿 Linux 的 `neofetch` 写的，有厂商检测如果不是 mi 系无法显示内容**

# Noactive inject

**利用 NoActive 提供的命令注入，来查看应用的状态**

# SCM
**到达设定的电量之后停止充电，支持电流为 0 时停止充电保证完全充满，支持调整检测频率**

还未完成的功能

- 到达指定温度停充
- 设置充电时最大功率

日志文件：`/data/adb/modules/scm/config/log.txt`

配置文件：`/data/adb/modules/scm/config/config.env`

计数文件：`/data/adb/modules/scm/config/count.env`

感谢 Top 大佬的 QSC 定量停充模块

感谢 Cong 的 ShortX - 定量停充

# NoActive Additional

**此模块为墓碑附加模块二改，关闭 Millet 和 Hans，为 NoAtive 提供必要的环境**

修改内容

- 优化模块描述
- 增加 WebUI 用于查看日志

感谢 Timeline && Myflvor 的墓碑附加模块

感谢后宫学长的 NoActive - 附加模块 - 改版

# PartitionTool

注意：Backup Partition 已更名为 PartitionTool

使用 dd 命令对分区进行操作，可以提取分区和刷入分区
