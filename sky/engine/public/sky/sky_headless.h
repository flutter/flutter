// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_PUBLIC_SKY_SKY_HEADLESS_H_
#define SKY_ENGINE_PUBLIC_SKY_SKY_HEADLESS_H_

#include <memory>

#include "base/basictypes.h"
#include "sky/engine/bindings/flutter_dart_state.h"
#include "sky/engine/core/window/window.h"
#include "sky/engine/wtf/OwnPtr.h"
#include "sky/engine/wtf/text/WTFString.h"

typedef struct _Dart_Isolate* Dart_Isolate;

namespace blink {
class DartController;
class Scene;

// This class provides a way to run Dart script without a View.
class SkyHeadless : public WindowClient, public IsolateClient {
 public:
  class Client {
   public:
    virtual void DidCreateIsolate(Dart_Isolate isolate) = 0;

   protected:
    virtual ~Client() {}
  };

  SkyHeadless(Client* client);
  ~SkyHeadless();

  void Init(const std::string& name);
  void RunFromSnapshotBuffer(const uint8_t* buffer, size_t size);

 private:
  void ScheduleFrame() override;
  void FlushRealTimeEvents() override;
  void Render(Scene* scene) override;

  void DidCreateSecondaryIsolate(Dart_Isolate isolate) override;

  std::unique_ptr<DartController> dart_controller_;
  Client* client_;

  DISALLOW_COPY_AND_ASSIGN(SkyHeadless);
};

} // namespace blink

#endif  // SKY_ENGINE_PUBLIC_SKY_SKY_HEADLESS_H_
