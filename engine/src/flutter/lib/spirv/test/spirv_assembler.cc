// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <cstdint>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <vector>

#include "spirv-tools/libspirv.hpp"

namespace fs = std::filesystem;

int main(int argc, const char* argv[]) {
  if (argc != 3) {
    std::cerr << "Invalid argument count." << std::endl;
    return -1;
  }

  fs::path path(argv[1]);
  if (!fs::exists(path)) {
    std::cerr << "File does not exist." << std::endl;
    return -1;
  }

  std::fstream input;
  input.open(argv[1]);
  input.seekg(0, std::ios::end);
  std::streampos size = input.tellg();
  input.seekg(0, std::ios::beg);
  std::vector<char> buf(size);
  input.read(buf.data(), size);
  input.close();

  spvtools::SpirvTools tools(SPV_ENV_UNIVERSAL_1_0);
  std::vector<uint32_t> assembled_spirv;
  if (!tools.Assemble(buf.data(), size, &assembled_spirv)) {
    std::cerr << "Failed to assemble " << argv[1] << std::endl;
    return -1;
  }

  std::fstream output;
  output.open(argv[2], std::fstream::out | std::fstream::trunc);
  if (!output.is_open()) {
    output.close();
    std::cerr << "failed to open output file" << std::endl;
    std::abort();
  }

  output.write(reinterpret_cast<const char*>(assembled_spirv.data()),
               sizeof(uint32_t) * assembled_spirv.size());
  output.close();
  return 0;
}
