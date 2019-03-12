/*
 * Copyright 2017 Google, Inc.
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

#include <string>

namespace flow {

static std::string gGoldenDir;
static std::string gFontFile;

const std::string& GetGoldenDir() {
  return gGoldenDir;
}

void SetGoldenDir(const std::string& dir) {
  gGoldenDir = dir;
}

const std::string& GetFontFile() {
  return gFontFile;
}

void SetFontFile(const std::string& file) {
  gFontFile = file;
}

}  // namespace flow
