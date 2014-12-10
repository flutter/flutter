// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_PLATFORM_FETCHER_MOJOFETCHER_H_
#define SKY_ENGINE_PLATFORM_FETCHER_MOJOFETCHER_H_

#include "base/memory/weak_ptr.h"
#include "mojo/services/network/public/interfaces/url_loader.mojom.h"

namespace blink {
class KURL;

class MojoFetcher {
 public:
  class Client {
   public:
    virtual void OnReceivedResponse(mojo::URLResponsePtr) = 0;

   protected:
    virtual ~Client() { }
  };

  MojoFetcher(Client*, const KURL&);
  ~MojoFetcher();

 private:
  void OnReceivedResponse(mojo::URLResponsePtr);

  Client* client_;
  mojo::URLLoaderPtr url_loader_;
  base::WeakPtrFactory<MojoFetcher> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(MojoFetcher);
};

}  // namespace blink

#endif  // SKY_ENGINE_PLATFORM_FETCHER_MOJOFETCHER_H_
