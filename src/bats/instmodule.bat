adb wait-for-device push %1 /sdcard/temp_module.zip
adb wait-for-device shell "su -c magisk --install-module /sdcard/temp_module.zip"
adb wait-for-device shell rm /sdcard/temp_module.zip