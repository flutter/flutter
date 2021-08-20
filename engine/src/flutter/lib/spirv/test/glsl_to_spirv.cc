// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <cstdint>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <vector>

#include "third_party/shaderc/libshaderc/include/shaderc/shaderc.hpp"

namespace fs = std::filesystem;

int main(int argc, const char* argv[]) {
  if (argc != 3) {
    std::cerr << "Invalid argument count." << std::endl;
    return -1;
  }

  fs::path path(argv[1]);
  if (!fs::is_regular_file(path)) {
    std::cerr << "File is not a regular file." << std::endl;
    return -1;
  }

  std::fstream input;
  input.open(argv[1]);
  input.seekg(0, std::ios::end);
  std::streampos size = input.tellg();
  input.seekg(0, std::ios::beg);
  std::vector<char> buf(static_cast<int>(size) + 1);
  input.read(buf.data(), size);
  buf[size] = 0;  // make sure the string is null terminated.
  input.close();

  shaderc::Compiler compiler;
  shaderc::CompileOptions options;
  options.SetOptimizationLevel(shaderc_optimization_level_zero);
  options.SetTargetEnvironment(shaderc_target_env_opengl, 0);
  shaderc::SpvCompilationResult result = compiler.CompileGlslToSpv(
      buf.data(), shaderc_glsl_default_fragment_shader, argv[1], options);

  if (result.GetCompilationStatus() != shaderc_compilation_status_success) {
    std::cerr << "Failed to transpile: " + result.GetErrorMessage() << argv[1]
              << std::endl;
    return -1;
  }

  std::vector<uint32_t> spirv =
      std::vector<uint32_t>(result.cbegin(), result.cend());

  std::fstream output;
  output.open(argv[2], std::fstream::out | std::fstream::trunc);

  if (!output.is_open()) {
    output.close();
    std::cerr << "failed to open output file" << std::endl;
    return -1;
  }

  output.write(reinterpret_cast<const char*>(spirv.data()),
               sizeof(uint32_t) * spirv.size());
  output.close();
  return 0;
}
