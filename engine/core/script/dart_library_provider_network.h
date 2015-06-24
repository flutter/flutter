// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_SCRIPT_DART_LIBRARY_PROVIDER_NETWORK_H_
#define SKY_ENGINE_CORE_SCRIPT_DART_LIBRARY_PROVIDER_NETWORK_H_

#include "sky/engine/tonic/dart_library_provider.h"
#include "sky/engine/wtf/HashSet.h"
#include "sky/engine/wtf/OwnPtr.h"

namespace blink {

class DartLibraryProviderNetwork : public DartLibraryProvider {
 public:
  struct PrefetchedLibrary {
    PrefetchedLibrary();
    ~PrefetchedLibrary();

    String name;
    mojo::ScopedDataPipeConsumerHandle pipe;
  };

  explicit DartLibraryProviderNetwork(PassOwnPtr<PrefetchedLibrary> prefetched);
  ~DartLibraryProviderNetwork() override;

 private:
  class Job;

  // |DartLibraryProvider| implementation:
  void GetLibraryAsStream(
      const String& name,
      base::Callback<void(mojo::ScopedDataPipeConsumerHandle)> callback)
      override;

  Dart_Handle CanonicalizeURL(Dart_Handle library, Dart_Handle url) override;

  OwnPtr<PrefetchedLibrary> prefetched_library_;
  HashSet<OwnPtr<Job>> jobs_;
};

}  // namespace blink

#endif  // SKY_ENGINE_CORE_SCRIPT_DART_LIBRARY_PROVIDER_NETWORK_H_
