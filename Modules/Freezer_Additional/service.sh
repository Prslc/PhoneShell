#!/system/bin/sh
MODDIR="${0%/*}"

# 新的判断系统启动完成方法
resetprop -w sys.boot_completed 0

Version="$(dumpsys package "nep.timeline.freezer" | grep versionName | awk -F '=' '{print $NF}')"
VersionNumber="$(dumpsys package "nep.timeline.freezer" | sed -n 's/.*versionCode=\([0-9]*\).*/\1/p')"
logtype="$(awk -F ': ' '/"logPrintMode"/ {gsub(/[^0-9]/, "", $2); print $2}' /data/system/Freezer/GlobalSettings.json)"

# 获取日志类型
if [ $logtype -eq 0 ]; then
    logtype="文件"
elif [ $logtype -eq 1 ]; then
    logtype="框架"
elif [ $logtype -eq 2 ]; then
    logtype="关闭"
else
    logtype="未知"
fi

# 获取冻结方式
if [ -e /sys/fs/cgroup/uid_0/cgroup.freeze ]; then
    freezer="FreezerV2(UID)"
elif [[ -e /sys/fs/cgroup/frozen/cgroup.freeze ]] && [[ -e /sys/fs/cgroup/unfrozen/cgroup.freeze ]]; then
    freezer="FreezerV2(FROZEN)"
elif [ -e /sys/fs/cgroup/freezer/perf/frozen/freezer.state ]; then
    freezer="FreezerV1(FROZEN)"
fi

# 获取 Millet 状态
if [ "$(getprop persist.sys.gz.enable)" = "true" ]; then
    tombstone="😰 系统墓碑：Millet处于运行状态"
elif [ "$(getprop persist.sys.gz.enable)" = "false" ]; then
    tombstone="😋 系统墓碑：已关闭Millet"
# 获取 Hans 状态
elif [ "$(getprop persist.vendor.enable.hans)" = "true" ]; then
    tombstone="😰 系统墓碑：Hans处于运行状态"
elif [ "$(getprop persist.vendor.enable.hans)" = "false" ]; then
    tombstone="😋 系统墓碑：已关闭Hans"
else
    tombstone="🧐 系统墓碑：未知的系统墓碑"
fi

log_output="📒 日志输出：$logtype"
freezer_info="❄️ 冻结方式：$freezer"

# 构建新的描述
new_version="$Version($VersionNumber)"
new_description="$log_output\\\n$freezer_info\\\n$tombstone"

# 使用 sed 替换 module.prop 文件中的 description 行
if [ -e "$MODDIR/module.prop" ]; then
    sed -i "s/^description=.*/description=$new_description/" "$MODDIR/module.prop"
    sed -i "s/^version=.*/version=$new_version/" "$MODDIR/module.prop"
else
    echo "错误: $MODDIR/module.prop 文件不存在或不可写"
fi
