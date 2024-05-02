#查看内核
echo "手机型号：$(getprop ro.product.odm.marketname) ($(getprop ro.product.board))"
echo "安卓版本：$(getprop ro.build.version.release)"
echo "安全补丁：$(getprop ro.build.version.security_patch)"
echo "固件版本：$(getprop persist.sys.grant_version)"
echo "内核版本：$(uname -r)"
compile_time=$(uname -v)
datetime_part=$(echo "$compile_time" | awk '{print $6, $7, $8, $9, $10}')
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
time_part=$(echo "$compile_time" | awk '{print $7}')
echo "编译时间：$(echo "$compile_time" | awk '{print $9}')年$chinese_month$(echo "$compile_time" | awk '{print $6}')日 $chinese_day $time_part"
echo "内核信息: $(awk -F ' ' '{print $5,$7,$8}' /proc/version | tr -d '()' | tr -d ',')\n"
soc=$(getprop ro.soc.model)
echo "处理器：$soc"
zip=$(cat /sys/block/zram0/comp_algorithm | cut -d '[' -f2 | cut -d ']' -f1)
echo "ZRAM："$(awk 'NR > 1 {size=$3/(1024*1024); printf "%.1fG\n", size}' /proc/swaps) "($zip)"

echo ""
if env | grep -qn 'ksu'; 
then
    echo "Root环境：KernelSU"
fi

if pm list packages | grep -qw "io.github.huskydg.magisk"; then
    echo "Root环境：Magisk🦊"
fi

find /data/adb/modules/ -name 'module.prop' -exec awk -F= '/^name=/ {name=$2} /^version=/ {print " 😋 ", name, "" $2 ""}' {} +
echo " "

# 查看冻结源码 作者：JARK006
if [ -f "/data/system/NoActive/log" ]; then
    Filever=$(head -n 1 /data/system/NoActive/log | awk '{print $NF}')
fi
Lspver=$(grep -l "modules" /data/adb/lspd/log/* | xargs sed -n '/当前版本/s/.*当前版本 \([0-9]*\).*/\1/p')

if pm list packages | grep -qw "cn.myflv.noactive"; then
    echo "墓碑环境：Noactive($Lspver)"
fi
apk=$(dumpsys package com.sidesand.millet | grep versionName | awk -F' ' '{print $1}' | cut -d '=' -f2)
if pm list packages | grep -qw "com.sidesand.millet1"; then
    echo "墓碑环境：SMillet($apk)"
fi
#echo "墓碑环境：Millet😇"
if [ -e /sys/fs/cgroup/uid_0/cgroup.freeze ]; then
    echo "✔️已挂载 FreezerV2(UID)"
fi
if [ -e /sys/fs/cgroup/freezer/perf/frozen/freezer.state ]; then
    echo "✔️已挂载 FreezerV1(FROZEN)"
fi
v1Info=$(mount | grep freezer | awk '{print"✔️已挂载 FreezerV1:",$3}')
if [ ${#v1Info} -gt 2 ]; then
    echo "$v1Info"
fi

status=$(ps -A | grep -E "refrigerator|do_freezer|signal" | awk '{print $6 " " $9}')
status=${status//"__refrigerator"/"😴 FreezerV1冻结中:"}
status=${status//"do_freezer_trap"/"😴 FreezerV2冻结中:"}
status=${status//"do_signal_stop"/"😴 GSTOP冻结中:"}
status=${status//"get_signal"/"😴 FreezerV2冻结中:"}

if [ ${#status} -gt 2 ]; then
echo "==============[ 冻结状态 ]==============
$status"
else
    echo "暂无冻结状态的进程"
fi