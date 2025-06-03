#!/system/bin/sh

# 检查是否是 root 用户
if [ "$(whoami)" != "root" ]; then
    echo "请使用Root权限运行此脚本"
    exit 1
fi

# 存储应用列表
applist="$(pm list packages -3 2>&1 </dev/null)"

# 设备信息
compile_time=$(uname -v)
time_part=$(echo "$compile_time" | awk '{print $7}')
Zram=$(cat /sys/block/zram0/comp_algorithm | cut -d '[' -f2 | cut -d ']' -f1)

# 电池
charge_full_design=$(cat /sys/class/power_supply/battery/charge_full_design)
cycle_count=$(cat /sys/class/power_supply/battery/cycle_count)
charge_full=$(cat /sys/class/power_supply/battery/charge_full)
JKD=$(echo "100*$charge_full/$charge_full_design" | bc)

# 判断NoActive目录
if echo "$applist" | grep -q "cn.myflv.noactive"; then
    new_log_path=$(ls /data/system/ | grep NoActive_)
    if [[ -d "/data/system/$new_log_path" && -d "/data/system/NoActive/log" ]]; then
        NoActive_Path="/data/system/$new_log_path"
    elif [ -d "/data/system/NoActive/" ]; then
        NoActive_Path="/data/system/NoActive/"
    elif [ -d "/data/system/$new_log_path" ]; then
        NoActive_Path="/data/system/$new_log_path"
    fi

    # 读取NoActive日志输出方式
    NoActive_logoutput=$(grep "logType" "$NoActive_Path/config/BaseConfig.json" | awk -F':' '{print $2}' | sed 's/"//g' | tr -d ' ')
    if [ "$NoActive_logoutput" = "file" ]; then
        NoActive_file="$NoActive_Path/log"
        NoActive_Version=$(grep '当前版本' "$NoActive_file" | awk '{print $NF}')
    else
        NoActive_Version=$(grep -l "modules" /data/adb/lspd/log/* | xargs sed -n '/当前版本/s/.*当前版本 \([0-9]*\).*/\1/p')
    fi
fi

# 获取目标进程的状态信息
status=$(ps -A | awk '/refrigerator|do_freezer|signal/ {print "😴"$6, $9}')

# 替换进程状态
status=$(echo "$status" | sed \
    -e 's/__refrigerator/ FreezerV1冻结中:/' \
    -e 's/do_freezer_trap/ FreezerV2冻结中:/' \
    -e 's/do_signal_stop/ GSTOP冻结中:/' \
    -e 's/get_signal/ FreezerV2冻结中:/')

# 获取挂载信息
v1Info=$(mount | grep freezer | awk '{print "✔️已挂载 FreezerV1:", $3}')

# 获取应用版本号
GetAppVerison() {
    dumpsys package $1 | grep versionCode | awk -F' ' '{print $1}' | cut -d '=' -f2
}
# 基本信息
BasicInformation() {
    echo "安卓版本：$(getprop ro.build.version.release)"
    echo "手机型号：$(getprop ro.product.marketname) ($(getprop ro.product.board))"
    echo "安全补丁：$(getprop ro.build.version.security_patch)"
    echo "固件版本：$(getprop persist.sys.grant_version)"
    echo "内核版本：$(uname -r)"
    echo "处理器：$(getprop ro.soc.model)"
    echo "ZRAM大小："$(awk 'NR > 1 {size=$3/(1024*1024); printf "%.1fG\n", size}' /proc/swaps) "($Zram)"
    echo " "
}

# 电池寿命
Battery() {
    echo "电池设计容量：$(echo "scale=0;$charge_full_design/1000" | bc)mAh"
    echo "循环次数：$cycle_count次"
    echo "电池当前充满：$(echo "scale=0;$charge_full/1000" | bc)mAh"
    echo "当前电池健康度：$JKD%"
    echo " "
}

# Root环境
Root() {
    if su -v | grep -qn 'KernelSU'; then
        echo "Root：KernelSU ($(su -V))"
    elif su -v | grep -qn 'MAGISKSU'; then
        echo "Root：Magisk ($(su -V))" then
    elif apd -v | grep -qn 'APatch'; then
        echo "Root：APatch ($(apd -V))"
    else
        echo "Root: not found"
    fi

    i=1
    for module_dir in /data/adb/modules/*; do
        if [ -f "$module_dir/disable" ]; then
            continue
        elif [ -f "$module_dir/module.prop" ]; then
            awk -F= -v i="$i" '/^name=/ {name=$2} /^version=/ { print i ". " name, $2; i++;}' "$module_dir/module.prop"
            i=$((i + 1))
        fi
    done

    echo " "
}

# 墓碑
tombstone() {
    ReKernel="$(ls /proc/rekernel 2>/dev/null | head -n 1)" && [ -n "$ReKernel" ] && echo "Re:Kernel端口: $ReKernel"
    if echo "$applist" | grep -qw "cn.myflv.noactive"; then
        echo "墓碑：NoActive($NoActive_Version)"
    elif echo "$applist" | grep -qw "com.sidesand.millet"; then
        echo "墓碑：SMillet($(GetAppVerison "com.sidesand.millet"))"
    elif [ "$(getprop persist.sys.powmillet.enable)" = "true" ]; then
        echo "墓碑：Millet"
    else
        echo "未知的墓碑"
    fi

    [ -e /sys/fs/cgroup/uid_0/cgroup.freeze ] && echo "✔️ 已挂载 FreezerV2(UID)"
    [ -e /sys/fs/cgroup/frozen/cgroup.freeze ] && [ -e /sys/fs/cgroup/unfrozen/cgroup.freeze ] && echo "✔️ 已挂载 FreezerV2(FROZEN)"
    [ -e /dev/cg2_bpf ] && echo "✔️ 已挂载 FreezerV2 (dev/cg2_bpf)"
    [ -e /sys/fs/cgroup/freezer/perf/frozen/freezer.state ] && echo "✔️ 已挂载 FreezerV1(FROZEN)"

    if [ ${#v1Info} -gt 2 ]; then
        echo "$v1Info"
    fi

    if [ ${#status} -gt 2 ]; then
        echo "==============[ 冻结状态 ]==============
$status"
    else
        echo "暂无冻结状态的进程"
    fi
}

# 主函数调用
BasicInformation
Battery
Root
tombstone
