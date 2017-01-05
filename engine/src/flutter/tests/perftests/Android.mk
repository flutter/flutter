#
# Copyright (C) 2016 The Android Open Source Project
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
#

LOCAL_PATH := $(call my-dir)

perftest_src_files := \
  ../util/FileUtils.cpp \
  ../util/FontTestUtils.cpp \
  ../util/MinikinFontForTest.cpp \
  ../util/UnicodeUtils.cpp \
  FontCollection.cpp \
  FontFamily.cpp \
  FontLanguage.cpp \
  GraphemeBreak.cpp \
  Hyphenator.cpp \
  WordBreaker.cpp \
  main.cpp

include $(CLEAR_VARS)
LOCAL_MODULE := minikin_perftests
LOCAL_CPPFLAGS := -Werror -Wall -Wextra
LOCAL_SRC_FILES := $(perftest_src_files)
LOCAL_STATIC_LIBRARIES := \
  libminikin \
  libxml2

LOCAL_SHARED_LIBRARIES := \
  libharfbuzz_ng \
  libicuuc \
  liblog \
  libskia

LOCAL_C_INCLUDES := \
  $(LOCAL_PATH)/../ \
  $(LOCAL_PATH)/../../libs/minikin \
  external/harfbuzz_ng/src \
  external/libxml2/include

include $(BUILD_NATIVE_BENCHMARK)
