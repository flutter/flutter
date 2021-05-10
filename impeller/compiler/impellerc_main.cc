// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/command_line.h"
#include "flutter/fml/macros.h"
#include "third_party/shaderc/libshaderc/include/shaderc/shaderc.hpp"

namespace impeller {
namespace compiler {

bool Main(const fml::CommandLine& command_line) {
  return false;
}

}  // namespace compiler
}  // namespace impeller

int main(int argc, char const* argv[]) {
  return impeller::compiler::Main(fml::CommandLineFromArgcArgv(argc, argv))
             ? EXIT_SUCCESS
             : EXIT_FAILURE;
}
