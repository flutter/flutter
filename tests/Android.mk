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

LOCAL_MODULE := minikin_tests
LOCAL_MODULE_TAGS := tests

LOCAL_STATIC_LIBRARIES := libminikin

# Shared libraries which are dependencies of minikin; these are not automatically
# pulled in by the build system (and thus sadly must be repeated).

LOCAL_SHARED_LIBRARIES := \
    libharfbuzz_ng \
    libft2 \
    liblog \
    libz \
    libicuuc \
    libutils

LOCAL_SRC_FILES += \
    GraphemeBreakTests.cpp \
    LayoutUtilsTest.cpp \
    UnicodeUtils.cpp

LOCAL_C_INCLUDES := $(LOCAL_PATH)/../libs/minikin/

include $(BUILD_NATIVE_TEST)
