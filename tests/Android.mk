# Copyright (C) 2015 The Android Open Source Project
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

# see how_to_run.txt for instructions on running these tests

LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

data_root_for_test_zip := $(TARGET_OUT_DATA)/DATA/
minikin_tests_subpath_from_data := nativetest/minikin_tests
minikin_tests_root_in_device := /data/$(minikin_tests_subpath_from_data)
minikin_tests_root_for_test_zip := $(data_root_for_test_zip)/$(minikin_tests_subpath_from_data)

font_src_files := \
    data/BoldItalic.ttf \
    data/Bold.ttf \
    data/ColorEmojiFont.ttf \
    data/ColorTextMixedEmojiFont.ttf \
    data/Emoji.ttf \
    data/Italic.ttf \
    data/Ja.ttf \
    data/Ko.ttf \
    data/NoGlyphFont.ttf \
    data/Regular.ttf \
    data/TextEmojiFont.ttf \
    data/VarioationSelectorTest-Regular.ttf \
    data/ZhHans.ttf \
    data/ZhHant.ttf \
    data/itemize.xml \
    data/emoji.xml

LOCAL_MODULE := minikin_tests
LOCAL_MODULE_TAGS := tests

GEN := $(addprefix $(minikin_tests_root_for_test_zip)/, $(font_src_files))
$(GEN): PRIVATE_PATH := $(LOCAL_PATH)
$(GEN): PRIVATE_CUSTOM_TOOL = cp $< $@
$(GEN): $(minikin_tests_root_for_test_zip)/data/% : $(LOCAL_PATH)/data/%
	$(transform-generated-source)
LOCAL_GENERATED_SOURCES += $(GEN)

LOCAL_STATIC_LIBRARIES := libminikin
LOCAL_PICKUP_FILES := $(data_root_for_test_zip)

# Shared libraries which are dependencies of minikin; these are not automatically
# pulled in by the build system (and thus sadly must be repeated).

LOCAL_SHARED_LIBRARIES := \
    libskia \
    libft2 \
    libharfbuzz_ng \
    libicuuc \
    liblog \
    libutils \
    libz

LOCAL_STATIC_LIBRARIES += \
    libxml2

LOCAL_SRC_FILES += \
    FontCollectionTest.cpp \
    FontCollectionItemizeTest.cpp \
    FontFamilyTest.cpp \
    FontLanguageListCacheTest.cpp \
    FontTestUtils.cpp \
    HbFontCacheTest.cpp \
    MinikinFontForTest.cpp \
    MinikinInternalTest.cpp \
    GraphemeBreakTests.cpp \
    LayoutUtilsTest.cpp \
    UnicodeUtils.cpp \
    WordBreakerTests.cpp

LOCAL_C_INCLUDES := \
    $(LOCAL_PATH)/../libs/minikin/ \
    external/harfbuzz_ng/src \
    external/libxml2/include \
    external/skia/src/core

LOCAL_CPPFLAGS += -Werror -Wall -Wextra \
    -DkTestFontDir="\"$(minikin_tests_root_in_device)/data/\""

include $(BUILD_NATIVE_TEST)
