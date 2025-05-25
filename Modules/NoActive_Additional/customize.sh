#!system/bin/sh

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

# 检查 WebUI 支持
if [ "$KSU" = "true" ] || [ "$APATCH" = "true" ]; then
    ui_print "[+] 你的管理器支持 WebUI 无需安装其他应用"
else
    ui_print "[x] 你的管理器不支持 WebUI 需要安装其他应用来使用 WebUI 功能，例如"
    ui_print "[1] MMRL (https://github.com/MMRLApp/MMRL)"
    ui_print "[2] KsuWebUI (https://github.com/5ec1cff/KsuWebUIStandalone)"
fi
