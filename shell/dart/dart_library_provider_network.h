// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_DART_DART_LIBRARY_PROVIDER_NETWORK_H_
#define SKY_SHELL_DART_DART_LIBRARY_PROVIDER_NETWORK_H_

#include "mojo/services/network/public/interfaces/network_service.mojom.h"
#include "sky/engine/tonic/dart_library_provider.h"
#include "sky/engine/wtf/HashSet.h"
#include "sky/engine/wtf/OwnPtr.h"

namespace sky {
namespace shell {

class DartLibraryProviderNetwork : public blink::DartLibraryProvider {
 public:
  explicit DartLibraryProviderNetwork(mojo::NetworkService* network_service);
  ~DartLibraryProviderNetwork() override;

  mojo::NetworkService* network_service() const { return network_service_; }

 protected:
  // |DartLibraryProvider| implementation:
  void GetLibraryAsStream(const String& name,
                          blink::DataPipeConsumerCallback callback) override;
  Dart_Handle CanonicalizeURL(Dart_Handle library, Dart_Handle url) override;

 private:
  class Job;

  mojo::NetworkService* network_service_;
  HashSet<OwnPtr<Job>> jobs_;

  DISALLOW_COPY_AND_ASSIGN(DartLibraryProviderNetwork);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_DART_DART_LIBRARY_PROVIDER_NETWORK_H_
