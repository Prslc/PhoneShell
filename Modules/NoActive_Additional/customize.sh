#!system/bin/sh

manager_Check() {
    # 检查 Magisk 版本
    if [ -n "$MAGISK_VER_CODE" ] && [ "$MAGISK_VER_CODE" -eq 27005 ] && [ -z "$KSU" ] && [ -z "$APATCH" ]; then
        ui_print "[x] 检测到 Magisk 版本为 27005，已停止安装"
        ui_print "[x] 请更新 Magisk 之后重新安装该模块"
        abort "Stop installation Module"
    fi
    if [ -n "$KSU" ]; then
        ui_print "[+] 检测到安装环境为：KernelSU"
        ui_print "[+] KerenlSU 内核版本：$KSU_KERNEL_VER_CODE"
        ui_print "[+] KernelSU 管理器版本：$KSU_VER_CODE"
        ui_print "[+] 处理器架构： $ARCH"
        ui_print "[+] 安卓版本：$API"
        ui_print "[+] 内核版本：$(uname -r)"
    elif [ -n "$APATCH" ]; then
        ui_print "[+] 检测到安装环境为：APatch"
        ui_print "[+] APatch 版本号：$APATCH_VER_CODE"
        ui_print "[+] APatch 版本名：$APATCH_VER"
        ui_print "[+] 处理器架构： $ARCH"
        ui_print "[+] 安卓版本：$API"
        ui_print "[+] 内核版本：$(uname -r)"
    else
        ui_print "[+] 检测到安装环境为：Magisk"
        ui_print "[+] Magisk 版本名：$MAGISK_VER"
        ui_print "[+] Magisk 版本号：$MAGISK_VER_CODE"
        ui_print "[+] 处理器架构： $ARCH"
        ui_print "[+] 安卓版本：$API"
        ui_print "[+] 内核版本：$(uname -r)"
    fi
}

# 获取模块名称
get_module_name() {
    local module_dir
    module_dir=$(dirname "$1" | cut -d'/' -f5) # 提取模块根目录
    local module_prop="/data/adb/modules/$module_dir/module.prop"

    if [ -f "$module_prop" ]; then
        grep -m 1 '^name=' "$module_prop" | cut -d'=' -f2
    else
        echo "未知模块 ($module_dir)"
    fi
}

# 检测 prop 冲突
conflict_Module() {
    # 检查是否有冲突的模块
    EXCLUDE_DIRS="NoActive_Additional lib_tombstone"
    PROPS_TO_CHECK="persist.sys.gz.enable persist.vendor.enable.hans"

    for prop in $PROPS_TO_CHECK; do
        CONFLICT_FOUND=false
        # 查找冲突的模块，排除指定目录
        FIND_CMD="find /data/adb/modules -type f"

        # 排除目录
        for dir in $EXCLUDE_DIRS; do
            FIND_CMD="$FIND_CMD -not -path \"*/$dir/*\""
        done

        # 执行 find 命令
        for file in $(eval $FIND_CMD); do
            MODULE_NAME=$(get_module_name "$file")

            if grep -q "$prop" "$file"; then
                ui_print "[x] 在模块 '$MODULE_NAME' 中发现冲突，属性 $prop 可能会导致无法关闭系统墓碑"
                CONFLICT_FOUND=true
            fi

            # 检查 setprop 和 resetprop -n 是否设置了该属性
            if grep -Eq "setprop\s+$prop|resetprop\s+-n\s+$prop" "$file"; then
                PROP_VALUE=$(getprop "$prop" || resetprop -p "$prop")
                ui_print "[x] 在模块 '$MODULE_NAME' 中发现 '$prop' 被 setprop 或 resetprop -n 设置，值为 '$PROP_VALUE'"
                CONFLICT_FOUND=true
            fi
        done

        if [ "$CONFLICT_FOUND" = false ]; then
            ui_print "[+] 未发现冲突的模块 $prop"
        fi
    done
}

# 检测 prop 持久化冲突
persistence_Check() {
    # 检查持久化设置
    if [ "$(getprop -p persist.sys.gz.enable)" = "true" ]; then
        ui_print "[x] 持久化设置存在问题，这可能导致你无法关闭 Millet"
    elif [ "$(getprop -p persist.vendor.enable.hans)" = "true" ]; then
        ui_print "[x] 持久化设置存在问题，这可能导致你无法关闭 Hans"
    else
        ui_print "[+] 未发现异常持久化设置"
    fi
}
#
manager_Webui() {
    # 检查 WebUI 支持
    if [ "$KSU" = "true" ] || [ "$APATCH" = "true" ]; then
        ui_print "[+] 你的管理器支持 WebUI 无需安装其他应用"
    else
        ui_print "[x] 你的管理器不支持 WebUI 需要安装其他应用来使用 WebUI 功能，例如"
        ui_print "[1] MMRL (https://github.com/MMRLApp/MMRL)"
        ui_print "[2] KsuWebUI (https://github.com/5ec1cff/KsuWebUIStandalone)"
    fi
}

# 音量键检测
key_check() {
    while true; do
        key_check=$(/system/bin/getevent -qlc 1)
        key_event=$(echo "$key_check" | awk '{ print $3 }' | grep 'KEY_')
        key_status=$(echo "$key_check" | awk '{ print $4 }')
        if [[ "$key_event" == *"KEY_"* && "$key_status" == "DOWN" ]]; then
            keycheck="$key_event"
            break
        fi
    done
    while true; do
        key_check=$(/system/bin/getevent -qlc 1)
        key_event=$(echo "$key_check" | awk '{ print $3 }' | grep 'KEY_')
        key_status=$(echo "$key_check" | awk '{ print $4 }')
        if [[ "$key_event" == *"KEY_"* && "$key_status" == "UP" ]]; then
            break
        fi
    done
    echo "$keycheck"
}

main() {
    manager_Check
    ui_print "[+] 请按音量键来选择是否进行一次模块冲突检测"
    ui_print "[+] 音量 + 进行冲突检测并安装"
    ui_print "[+] 音量 - 不进行冲突检测直接进入安装环节"
    ui_print "[+] 正常情况下建议跳过冲突检测"
    ui_print "[+] 如果进行冲突检测模块的安装时间将会更长"
    key_event=$(key_check)
    if [ "$key_event" == "KEY_VOLUMEUP" ]; then
        ui_print "你点击了音量上键，即将开始检测模块可能出现的冲突"
        conflict_Module
        persistence_Check
        manager_Webui
    else
        ui_print "你点击了音量下键，跳过检测环节开始安装"
        manager_Webui
    fi
}

main
