#!/system/bin/sh
MODDIR="${0%/*}"

# 新的判断系统启动完成方法
resetprop -w sys.boot_completed 0

# 判断NoActive目录
new_log_path=$(ls /data/system/ | grep NoActive_)
if [[ -f "/data/system/$new_log_path/log" && -f "/data/system/NoActive/log" ]]; then
    NoActive_file="/data/system/$new_log_path"
elif [ -f "/data/system/NoActive/log" ]; then
    NoActive_file="/data/system/NoActive"
elif [ -f "/data/system/$new_log_path/log" ]; then
    NoActive_file="/data/system/$new_log_path"
fi

# 定义变量
logtype=$(grep '"logType"' $NoActive_file/config/BaseConfig.json | awk -F':' '{print $2}' | sed 's/"//g' | tr -d ' ')
Noactive_version=$(dumpsys package cn.myflv.noactive | grep versionName | awk -F'=' '{print $2}')

# 读取日志类型配置
if [ "$logtype" = "file" ]; then
    logtype="文件"
    logpath="$NoActive_file/log"
else
    logtype="框架"
    logpath=$(ls /data/adb/lspd/log/module*)
fi

# 获取NoActive小版本号
if [ "$logtype" = "文件" ]; then
    Filever=$(grep '当前版本' "$logpath" | awk '{print $NF}')
    NoactiveVer="$Filever"
else
    lsp_log=$(grep "当前版本" "$logpath" | awk '{print $NF}' )
    NoactiveVer="$lsp_log"
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

# 检测附加模块是否正常
if grep -q "NoActive附加模块已安装" "$logpath"; then
    install="✔️ NoActive附加模块运行正常"
else
    install="❌ NoActive附加模块运行异常"
fi

log_output="📒 日志输出：$logtype"
freezer_info="❄️ 冻结方式：$freezer"

# 构建新的描述
new_version="$Noactive_version($NoactiveVer)"
new_description="$log_output\\\n$freezer_info\\\n$tombstone\\\n$install"

# 使用 sed 替换 module.prop 文件中的 description 行
if [ -e "$MODDIR/module.prop" ]; then
    sed -i "s/^description=.*/description=$new_description/" "$MODDIR/module.prop"
    sed -i "s/^version=.*/version=$new_version/" "$MODDIR/module.prop"
else
    echo "错误: $MODDIR/module.prop 文件不存在或不可写"
fi
