// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "services/sky/dart_library_provider_impl.h"

namespace sky {

DartLibraryProviderImpl::PrefetchedLibrary::PrefetchedLibrary() {
}

DartLibraryProviderImpl::PrefetchedLibrary::~PrefetchedLibrary() {
}

DartLibraryProviderImpl::DartLibraryProviderImpl(
    mojo::NetworkService* network_service,
    scoped_ptr<PrefetchedLibrary> prefetched)
    : shell::DartLibraryProviderNetwork(network_service),
      prefetched_library_(prefetched.Pass()) {
}

DartLibraryProviderImpl::~DartLibraryProviderImpl() {
}

void DartLibraryProviderImpl::GetLibraryAsStream(
    const std::string& name,
    blink::DataPipeConsumerCallback callback) {
  if (prefetched_library_ && prefetched_library_->name == name) {
    mojo::ScopedDataPipeConsumerHandle pipe = prefetched_library_->pipe.Pass();
    prefetched_library_ = nullptr;
    callback.Run(pipe.Pass());
    return;
  }

  shell::DartLibraryProviderNetwork::GetLibraryAsStream(name, callback);
}

}  // namespace sky
