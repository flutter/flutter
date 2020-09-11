// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <string>

namespace flutter {

const std::string& GetGoldenDir();

void SetGoldenDir(const std::string& dir);

const std::string& GetFontFile();

void SetFontFile(const std::string& dir);

}  // namespace flutter
