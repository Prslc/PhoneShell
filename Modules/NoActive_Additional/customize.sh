#!/system/bin/sh

# 拦截 Magisk 为 27005 的版本
if [[ "$MAGISK_VER_CODE" -eq 27005 && -z "$KSU" && -z "$APATCH" ]]; then
    ui_print "- 检测到 Magisk 版本为 27005，已停止安装"
    ui_print "- 请更新 Magisk 之后重新安装该模块"
    abort "Stop installation Module"
fi

# 检测 Magisk 版本是否小于 27000
if [[ "$MAGISK_VER_CODE" -lt 27000 && -z "$KSU" && -z "$APATCH" ]]; then
    ui_print "你的 Magisk 版本 < 27000 已被拦截"
    abort "Stop installation Module"
fi

# 检测 KernelSU 版本是否小于 11422
if [[ "$KSU" == "true" && "$KSU_VER_CODE" -lt 11422 ]]; then
    ui_print "你的 KernelSU 管理器版本 < 11422 已被拦截"
    abort "Stop installation Module"
fi
