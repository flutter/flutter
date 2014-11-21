// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_APP_MODULE_LOADER_H_
#define SKY_ENGINE_CORE_APP_MODULE_LOADER_H_

#include "base/memory/weak_ptr.h"
#include "sky/engine/platform/fetcher/MojoFetcher.h"
#include "sky/engine/wtf/OwnPtr.h"
#include "sky/engine/wtf/RefCounted.h"
#include "sky/engine/wtf/RefPtr.h"

namespace blink {
class Application;
class Document;
class Module;

class ModuleLoader : public MojoFetcher::Client {
 public:
  class Client {
   public:
    virtual void OnModuleLoadComplete(ModuleLoader*, Module*) = 0;

   protected:
    virtual ~Client();
  };

  enum State {
    LOADING,
    COMPLETE,
  };

  ModuleLoader(Client*, Application*, const KURL&);
  ~ModuleLoader();

  State state() const { return state_; }
  Module* module() const { return module_.get(); }

 private:
  // MojoFetcher::Client
  void OnReceivedResponse(mojo::URLResponsePtr) override;

  void OnParsingComplete();

  State state_;
  Client* client_;
  Application* application_;
  OwnPtr<MojoFetcher> fetcher_;
  RefPtr<Module> module_;

  base::WeakPtrFactory<ModuleLoader> weak_factory_;
};

} // namespace blink

#endif // SKY_ENGINE_CORE_APP_MODULE_LOADER_H_
