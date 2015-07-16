# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

TOOLCHAIN=../../../../third_party/android_tools/ndk/toolchains/arm-linux-androideabi-4.6/prebuilt/linux-x86_64/bin/arm-linux-androideabi-
CXX=$(TOOLCHAIN)g++

lib%.so: %.cc
	$(CXX) -nostdlib -g -fPIC -shared $< -o $@

all: liba.so libb.so
