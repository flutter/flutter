# Copyright (C) 2013 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
# Generate unicode emoji data from UCD.
UNICODE_EMOJI_H_GEN_PY := $(LOCAL_PATH)/unicode_emoji_h_gen.py
UNICODE_EMOJI_DATA := $(TOP)/external/unicode/emoji-data.txt

UNICODE_EMOJI_H := $(intermediates)/generated/UnicodeData.h
$(UNICODE_EMOJI_H): $(UNICODE_EMOJI_H_GEN_PY) $(UNICODE_EMOJI_DATA)
$(LOCAL_PATH)/MinikinInternal.cpp: $(UNICODE_EMOJI_H)
$(UNICODE_EMOJI_H): PRIVATE_CUSTOM_TOOL := python $(UNICODE_EMOJI_H_GEN_PY) \
    -i $(UNICODE_EMOJI_DATA) \
    -o $(UNICODE_EMOJI_H)
$(UNICODE_EMOJI_H):
		$(transform-generated-source)

include $(CLEAR_VARS)
minikin_src_files := \
    AnalyzeStyle.cpp \
    CmapCoverage.cpp \
    FontCollection.cpp \
    FontFamily.cpp \
    FontLanguage.cpp \
    FontLanguageListCache.cpp \
    GraphemeBreak.cpp \
    HbFontCache.cpp \
    Hyphenator.cpp \
    Layout.cpp \
    LayoutUtils.cpp \
    LineBreaker.cpp \
    Measurement.cpp \
    MinikinInternal.cpp \
    MinikinRefCounted.cpp \
    MinikinFont.cpp \
    MinikinFontFreeType.cpp \
    SparseBitSet.cpp \
    WordBreaker.cpp

minikin_c_includes := \
    external/harfbuzz_ng/src \
    external/freetype/include \
    frameworks/minikin/include \
    $(intermediates)

minikin_shared_libraries := \
    libharfbuzz_ng \
    libft2 \
    liblog \
    libz \
    libicuuc \
    libutils

ifneq (,$(filter userdebug eng, $(TARGET_BUILD_VARIANT)))
# Enable race detection on eng and userdebug build.
enable_race_detection := -DENABLE_RACE_DETECTION
else
enable_race_detection :=
endif

LOCAL_MODULE := libminikin
LOCAL_EXPORT_C_INCLUDE_DIRS := frameworks/minikin/include
LOCAL_SRC_FILES := $(minikin_src_files)
LOCAL_C_INCLUDES := $(minikin_c_includes)
LOCAL_CPPFLAGS += -Werror -Wall -Wextra $(enable_race_detection)
LOCAL_SHARED_LIBRARIES := $(minikin_shared_libraries)
LOCAL_CLANG := true
LOCAL_SANITIZE := signed-integer-overflow
# b/26432628.
#LOCAL_SANITIZE += unsigned-integer-overflow

include $(BUILD_SHARED_LIBRARY)

include $(CLEAR_VARS)

LOCAL_MODULE := libminikin
LOCAL_MODULE_TAGS := optional
LOCAL_EXPORT_C_INCLUDE_DIRS := frameworks/minikin/include
LOCAL_SRC_FILES := $(minikin_src_files)
LOCAL_C_INCLUDES := $(minikin_c_includes)
LOCAL_CPPFLAGS += -Werror -Wall -Wextra $(enable_race_detection)
LOCAL_SHARED_LIBRARIES := $(minikin_shared_libraries)
LOCAL_CLANG := true
LOCAL_SANITIZE := signed-integer-overflow
# b/26432628.
#LOCAL_SANITIZE += unsigned-integer-overflow

include $(BUILD_STATIC_LIBRARY)

include $(CLEAR_VARS)

# Reduced library (currently just hyphenation) for host

LOCAL_MODULE := libminikin_host
LOCAL_MODULE_TAGS := optional
LOCAL_EXPORT_C_INCLUDE_DIRS := frameworks/minikin/include
LOCAL_C_INCLUDES := $(minikin_c_includes)
LOCAL_CPPFLAGS += -Werror -Wall -Wextra $(enable_race_detection)
LOCAL_SHARED_LIBRARIES := liblog libicuuc

LOCAL_SRC_FILES := Hyphenator.cpp

include $(BUILD_HOST_STATIC_LIBRARY)
