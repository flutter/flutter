#
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
#

common_cppflags := -Wall -Wextra -Wunused -Werror -Wold-style-cast

LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_CPP_EXTENSION := .cc

LOCAL_SRC_FILES := \
  src/debug.cc \
  src/delta_encoder.cc \
  src/elf_file.cc \
  src/packer.cc \
  src/sleb128.cc \

LOCAL_STATIC_LIBRARIES := libelf
LOCAL_C_INCLUDES := external/elfutils/src/libelf
LOCAL_MODULE := lib_relocation_packer

LOCAL_CPPFLAGS := $(common_cppflags)

LOCAL_ADDITIONAL_DEPENDENCIES := $(LOCAL_PATH)/Android.mk

include $(BUILD_HOST_STATIC_LIBRARY)

include $(CLEAR_VARS)

LOCAL_CPP_EXTENSION := .cc

LOCAL_SRC_FILES := src/main.cc
LOCAL_STATIC_LIBRARIES := lib_relocation_packer libelf

# Statically linking libc++ to make it work from prebuilts
LOCAL_CXX_STL := libc++_static
LOCAL_C_INCLUDES := external/elfutils/src/libelf libnativehelper/include

LOCAL_MODULE := relocation_packer

LOCAL_CPPFLAGS := $(common_cppflags)

LOCAL_ADDITIONAL_DEPENDENCIES := $(LOCAL_PATH)/Android.mk

include $(BUILD_HOST_EXECUTABLE)

include $(CLEAR_VARS)

LOCAL_CPP_EXTENSION := .cc

LOCAL_SRC_FILES := \
  src/debug_unittest.cc \
  src/delta_encoder_unittest.cc \
  src/elf_file_unittest.cc \
  src/sleb128_unittest.cc \
  src/packer_unittest.cc \

LOCAL_STATIC_LIBRARIES := lib_relocation_packer libelf
LOCAL_C_INCLUDES := external/elfutils/src/libelf

LOCAL_CPPFLAGS := $(common_cppflags)

LOCAL_MODULE := relocation_packer_unit_tests
LOCAL_ADDITIONAL_DEPENDENCIES := $(LOCAL_PATH)/Android.mk

include $(BUILD_HOST_NATIVE_TEST)

# $(1) library name
define copy-test-library
include $(CLEAR_VARS)
LOCAL_IS_HOST_MODULE := true
LOCAL_MODULE := $(1)
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_MODULE_PATH := $(HOST_OUT_EXECUTABLES)
LOCAL_STRIP_MODULE := false
LOCAL_SRC_FILES := test_data/$(1)
include $(BUILD_PREBUILT)
endef

$(eval $(call copy-test-library,elf_file_unittest_relocs_arm32.so))
$(eval $(call copy-test-library,elf_file_unittest_relocs_arm32_packed.so))
$(eval $(call copy-test-library,elf_file_unittest_relocs_arm64.so))
$(eval $(call copy-test-library,elf_file_unittest_relocs_arm64_packed.so))
$(eval $(call copy-test-library,elf_file_unittest_relocs_ia32.so))
$(eval $(call copy-test-library,elf_file_unittest_relocs_ia32_packed.so))
$(eval $(call copy-test-library,elf_file_unittest_relocs_x64.so))
$(eval $(call copy-test-library,elf_file_unittest_relocs_x64_packed.so))
$(eval $(call copy-test-library,elf_file_unittest_relocs_mips32.so))
$(eval $(call copy-test-library,elf_file_unittest_relocs_mips32_packed.so))
