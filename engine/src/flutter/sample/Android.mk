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

LOCAL_PATH:= $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE_TAGS := tests

LOCAL_C_INCLUDES += \
	external/harfbuzz_ng/src \
	external/freetype/include \
	frameworks/minikin/include

LOCAL_SRC_FILES:= example.cpp

LOCAL_SHARED_LIBRARIES += \
	libutils \
	liblog \
	libcutils \
	libharfbuzz_ng \
	libicuuc \
	libft2 \
	libpng \
	libz \
	libminikin

LOCAL_MODULE:= minikin_example

include $(BUILD_EXECUTABLE)


include $(CLEAR_VARS)

LOCAL_MODULE_TAG := tests

LOCAL_C_INCLUDES += \
	external/harfbuzz_ng/src \
	external/freetype/include \
	frameworks/minikin/include \
	external/skia/src/core

LOCAL_SRC_FILES:= example_skia.cpp \
	MinikinSkia.cpp

LOCAL_SHARED_LIBRARIES += \
	libutils \
	liblog \
	libcutils \
	libharfbuzz_ng \
	libicuuc \
	libskia \
	libminikin \
	libft2

LOCAL_MODULE:= minikin_skia_example

include $(BUILD_EXECUTABLE)
