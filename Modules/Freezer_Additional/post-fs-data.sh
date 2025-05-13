# Millet
if [ "$(getprop persist.sys.gz.enable)" = "true" ]; then
    resetprop -n sys.millet.monitor 1
    resetprop -n persist.sys.gz.enable false
    resetprop -n persist.sys.brightmillet.enable false
    resetprop -n persist.sys.powmillet.enable false
    resetprop -n persist.sys.millet.handshake true
fi

# Hans
if [ "$(getprop persist.vendor.enable.hans)" = "true" ]; then
    resetprop -n persist.vendor.enable.hans false
    resetprop -n sys.hans.enable true
fi
