// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SERVICES_SKY_DART_LIBRARY_PROVIDER_IMPL_H_
#define SERVICES_SKY_DART_LIBRARY_PROVIDER_IMPL_H_

#include "base/memory/scoped_ptr.h"
#include "sky/shell/dart/dart_library_provider_network.h"

namespace sky {

class DartLibraryProviderImpl : public shell::DartLibraryProviderNetwork {
 public:
  struct PrefetchedLibrary {
    PrefetchedLibrary();
    ~PrefetchedLibrary();

    std::string name;
    mojo::ScopedDataPipeConsumerHandle pipe;
  };

  explicit DartLibraryProviderImpl(mojo::NetworkService* network_service,
                                   scoped_ptr<PrefetchedLibrary> prefetched);
  ~DartLibraryProviderImpl() override;

 private:
  void GetLibraryAsStream(const std::string& name,
                          blink::DataPipeConsumerCallback callback) override;

  scoped_ptr<PrefetchedLibrary> prefetched_library_;

  DISALLOW_COPY_AND_ASSIGN(DartLibraryProviderImpl);
};

}  // namespace sky

#endif  // SERVICES_SKY_DART_LIBRARY_PROVIDER_IMPL_H_
