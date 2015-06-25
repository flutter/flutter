// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_TONIC_DART_LIBRARY_PROVIDER_H_
#define SKY_ENGINE_TONIC_DART_LIBRARY_PROVIDER_H_

#include "base/callback.h"
#include "dart/runtime/include/dart_api.h"
#include "mojo/public/cpp/system/data_pipe.h"
#include "sky/engine/wtf/text/WTFString.h"

namespace blink {

typedef base::Callback<void(mojo::ScopedDataPipeConsumerHandle)>
    DataPipeConsumerCallback;

class DartLibraryProvider {
 public:
  virtual void GetLibraryAsStream(const String& name,
                                  DataPipeConsumerCallback callback) = 0;

  virtual Dart_Handle CanonicalizeURL(Dart_Handle library, Dart_Handle url) = 0;

  virtual ~DartLibraryProvider();
};

}  // namespace blink

#endif  // SKY_ENGINE_TONIC_DART_LIBRARY_PROVIDER_H_
