// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_SCRIPT_EMBEDDER_RESOURCES_H_
#define SKY_ENGINE_CORE_SCRIPT_EMBEDDER_RESOURCES_H_

namespace mojo {
namespace dart {

struct ResourcesEntry {
  const char* path_;
  const char* resource_;
  int length_;
};

}  // namespace dart
}  // namespace mojo

namespace blink {

class EmbedderResources {
 public:
  EmbedderResources(mojo::dart::ResourcesEntry* resources_table);

  static const int kNoSuchInstance;

  int ResourceLookup(const char* path, const char** resource);
  const char* Path(int idx);

 private:
  mojo::dart::ResourcesEntry* At(int idx);

  mojo::dart::ResourcesEntry* resources_table_;
};

}  // namespace blink

#endif  // SKY_ENGINE_CORE_SCRIPT_EMBEDDER_RESOURCES_H_
