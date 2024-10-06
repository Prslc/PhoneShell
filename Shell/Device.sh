#!/system/bin/bash

# 检查是否是 root 用户
if [ "$(whoami)" != "root" ]; then
    echo "请使用Root权限运行此脚本"
    exit 1
fi

# 存储应用列表
applist="$(pm list packages -3 2>&1 </dev/null)"

# 设备信息
compile_time=$(uname -v)
datetime_part=$(echo "$compile_time" | awk '{print $6, $7, $8, $9, $10}')
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
        NoActive_version=$(grep '当前版本' "$NoActive_file" | awk '{print $NF}')
    else
        NoActive_version=$(grep -l "modules" /data/adb/lspd/log/* | xargs sed -n '/当前版本/s/.*当前版本 \([0-9]*\).*/\1/p')
    fi
fi

# 冻结
status=$(ps -A | grep -E "refrigerator|do_freezer|signal" | awk '{print "😴"$6 " " $9}')
process1=$(echo "$status" | grep -v "sand" | grep -v ":" | grep -v "sh" | grep -c "")
process2=$(echo "$status" | grep -c "")

status=${status//"__refrigerator"/" FreezerV1冻结中:"}
status=${status//"do_freezer_trap"/" FreezerV2冻结中:"}
status=${status//"do_signal_stop"/" GSTOP冻结中:"}
status=${status//"get_signal"/" FreezerV2冻结中:"}
v1Info=$(mount | grep freezer | awk '{print "✔️已挂载 FreezerV1:", $3}')

# 获取应用版本号
GetAppVerison(){
    dumpsys package $1 | grep versionCode | awk -F' ' '{print $1}' | cut -d '=' -f2
}
# 基本信息
BasicInformation() {
    echo "安卓版本：$(getprop ro.build.version.release)"
    echo "手机型号：$(getprop ro.product.marketname) ($(getprop ro.product.board))"
    echo "安全补丁：$(getprop ro.build.version.security_patch)"
    echo "固件版本：$(getprop persist.sys.grant_version)"
    echo "内核版本：$(uname -r)"
    
    case $(echo "$compile_time" | awk '{print $5}') in
        "Jan") chinese_month="1月" ;;
        "Feb") chinese_month="2月" ;;
        "Mar") chinese_month="3月" ;;
        "Apr") chinese_month="4月" ;;
        "May") chinese_month="5月" ;;
        "Jun") chinese_month="6月" ;;
        "Jul") chinese_month="7月" ;;
        "Aug") chinese_month="8月" ;;
        "Sep") chinese_month="9月" ;;
        "Oct") chinese_month="10月" ;;
        "Nov") chinese_month="11月" ;;
        "Dec") chinese_month="12月" ;;
        *) chinese_month="未知" ;;
    esac

    case $(echo "$compile_time" | awk '{print $4}') in
        "Mon") chinese_day="星期一" ;;
        "Tue") chinese_day="星期二" ;;
        "Wed") chinese_day="星期三" ;;
        "Thu") chinese_day="星期四" ;;
        "Fri") chinese_day="星期五" ;;
        "Sat") chinese_day="星期六" ;;
        "Sun") chinese_day="星期日" ;;
        *) chinese_day="未知" ;;
    esac

    echo "编译时间：$(echo "$compile_time" | awk '{print $9}')年$chinese_month$(echo "$compile_time" | awk '{print $6}')日 $chinese_day $time_part"
    echo "处理器：$(getprop ro.soc.model)"
    echo "ZRAM大小："$(awk 'NR > 1 {size=$3/(1024*1024); printf "%.1fG\n", size}' /proc/swaps) "($Zram)"
    echo ""
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
    if env | grep -qn 'ksu'; then
        echo "Root环境：KernelSU($(GetAppVerison "me.weishu.kernelsu"))"
    elif [ -f "/data/adb/ap/modules.img" ]; then
        echo "Root环境：APatch($(GetAppVerison "me.bmax.apatch"))"
    elif echo "$applist" | grep -qw "com.topjohnwu.magisk"; then
        echo "Root环境：Magisk($(GetAppVerison "com.topjohnwu.magisk"))"
    elif echo "$applist" | grep -qw "io.github.huskydg.magisk"; then
        echo "Root环境：Magisk🦊($(GetAppVerison "io.github.huskydg.magisk"))"
    elif echo "$applist" | grep -qw "io.github.vvb2060.magisk"; then
        echo "Root环境：Magisk Alpha($(GetAppVerison "io.github.vvb2060.magisk"))"
    else
        echo "Root环境：未知"
    fi

    find /data/adb/modules/ -name 'module.prop' -exec awk -F= '/^name=/ {name=$2} /^version=/ {print " "++i"."" "name, $2}' {} +
    echo " "
}

# 墓碑
tombstone() {
    if [ -f "$NoActive_file" ] && [ "$(getprop persist.sys.powmillet.enable)" != "true" ]; then
        echo "墓碑：Noactive($NoActive_version)"
    elif echo "$applist" | grep -qw "com.sidesand.millet"; then
        echo "墓碑：SMillet($(GetAppVerison "com.sidesand.millet"))"
    elif [ "$(getprop persist.sys.powmillet.enable)" = "true" ]; then
        echo "墓碑：Millet"
    else
        echo "未知的墓碑"
    fi

    if [ -e /dev/cg2_bpf ]; then
        echo "✔️已挂载 FreezerV2 (dev/cg2_bpf)"
    fi

    if [ -e /sys/fs/cgroup/uid_0/cgroup.freeze ]; then
        echo "✔️已挂载 FreezerV2(UID)"
    fi

    if [ -e /sys/fs/cgroup/frozen/cgroup.freeze ] && [ -e /sys/fs/cgroup/unfrozen/cgroup.freeze ]; then
        echo "✔️已挂载 FreezerV2(FROZEN)"
    fi
    
    if [ -e /sys/fs/cgroup/freezer/perf/frozen/freezer.state ]; then
        echo "✔️已挂载 FreezerV1(FROZEN)"
    fi

    if [ ${#v1Info} -gt 2 ]; then
        echo "$v1Info"
    fi

    if [ ${#status} -gt 2 ]; then
        echo "==============[ 冻结状态 ]==============
$status
[已冻结 $process1 个应用 $process2 个进程]"
    else
        echo "暂无冻结状态的进程"
    fi
}

# 主函数调用
BasicInformation
Battery
Root
tombstone
