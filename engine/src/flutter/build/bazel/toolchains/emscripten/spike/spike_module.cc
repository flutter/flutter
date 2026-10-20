// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// The emsdk spike's module (phased_plan metric 0.6): an embind module with
// one function of each kind the web engine exports -- an embind binding
// and a plain C export -- compiled and linked by the Emscripten toolchain
// (build/bazel/toolchains/emscripten) and run by spike_test under the
// SDK's Node.js.

#include <emscripten/bind.h>
#include <emscripten/emscripten.h>

#include <string>

namespace {

int Add(int a, int b) {
  return a + b;
}

std::string Greet(const std::string& name) {
  return "hello, " + name;
}

}  // namespace

extern "C" EMSCRIPTEN_KEEPALIVE int spike_add(int a, int b) {
  return Add(a, b);
}

EMSCRIPTEN_BINDINGS(spike) {
  emscripten::function("add", &Add);
  emscripten::function("greet", &Greet);
}
