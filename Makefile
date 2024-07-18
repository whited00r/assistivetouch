GO_EASY_ON_ME = 1
THEOS_DEVICE_IP = 192.168.1.18
include theos/makefiles/common.mk

TWEAK_NAME = AssistiveTouch
AssistiveTouch_FILES = Tweak.xm UIImage+LiveBlur.m UIImage+StackBlur.m UIImage+Resize.m
AssistiveTouch_FRAMEWORKS = UIKit CoreGraphics Foundation QuartzCore
include $(THEOS_MAKE_PATH)/tweak.mk
