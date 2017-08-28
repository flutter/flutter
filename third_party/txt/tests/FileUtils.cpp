/*
 * Copyright (C) 2016 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <log/log.h>

#include <stdio.h>
#include <sys/stat.h>

#include <string>
#include <vector>

std::vector<uint8_t> readWholeFile(const std::string& filePath) {
  FILE* fp = fopen(filePath.c_str(), "r");
  LOG_ALWAYS_FATAL_IF(fp == nullptr);
  struct stat st;
  LOG_ALWAYS_FATAL_IF(fstat(fileno(fp), &st) != 0);

  std::vector<uint8_t> result(st.st_size);
  LOG_ALWAYS_FATAL_IF(fread(result.data(), 1, st.st_size, fp) !=
                      static_cast<size_t>(st.st_size));
  fclose(fp);
  return result;
}
