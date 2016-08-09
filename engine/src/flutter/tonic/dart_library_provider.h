// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TONIC_DART_LIBRARY_PROVIDER_H_
#define FLUTTER_TONIC_DART_LIBRARY_PROVIDER_H_

#include <functional>
#include <string>

#include "dart/runtime/include/dart_api.h"
#include "mojo/public/cpp/system/data_pipe.h"

namespace blink {

struct DartLibraryStream {
  mojo::ScopedDataPipeConsumerHandle handle;
  std::string resolved_url;
};

class DartLibraryProvider {
 public:
  virtual DartLibraryStream GetLibraryAsStream(const std::string& name) = 0;

  virtual Dart_Handle CanonicalizeURL(Dart_Handle library, Dart_Handle url) = 0;

  virtual ~DartLibraryProvider();
};

}  // namespace blink

#endif  // FLUTTER_TONIC_DART_LIBRARY_PROVIDER_H_
