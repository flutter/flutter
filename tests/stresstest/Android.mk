# Copyright (C) 2017 The Android Open Source Project
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

LOCAL_TEST_DATA := $(foreach f,$(LOCAL_TEST_DATA),frameworks/minikin/tests:$(f))

LOCAL_MODULE := minikin_stress_tests
LOCAL_MODULE_TAGS := tests
LOCAL_MODULE_CLASS := NATIVE_TESTS

LOCAL_STATIC_LIBRARIES := libminikin

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
    ../util/FontTestUtils.cpp \
    ../util/MinikinFontForTest.cpp \
    MultithreadTest.cpp \

LOCAL_C_INCLUDES := \
    $(LOCAL_PATH)/../../libs/minikin/ \
    $(LOCAL_PATH)/../util \
    external/libxml2/include \

LOCAL_CPPFLAGS += -Werror -Wall -Wextra

include $(BUILD_NATIVE_TEST)
