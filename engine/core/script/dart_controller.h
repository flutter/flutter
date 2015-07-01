// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_SCRIPT_DART_CONTROLLER_H_
#define SKY_ENGINE_CORE_SCRIPT_DART_CONTROLLER_H_

#include "base/callback_forward.h"
#include "base/macros.h"
#include "base/memory/weak_ptr.h"
#include "dart/runtime/include/dart_api.h"
#include "mojo/services/network/public/interfaces/url_loader.mojom.h"
#include "sky/engine/wtf/OwnPtr.h"
#include "sky/engine/wtf/text/AtomicString.h"
#include "sky/engine/wtf/text/TextPosition.h"

namespace blink {
class AbstractModule;
class BuiltinSky;
class DOMDartState;
class DartLibraryProvider;
class DartLibraryProviderWebView;
class DartSnapshotLoader;
class DartValue;
class KURL;
class View;

class DartController {
 public:
  DartController();
  ~DartController();

  static void InitVM();

  typedef base::Callback<void(RefPtr<AbstractModule>, RefPtr<DartValue>)>
      LoadFinishedCallback;

  void RunFromLibrary(const String& name,
                      DartLibraryProvider* library_provider);
  void RunFromSnapshot(mojo::ScopedDataPipeConsumerHandle snapshot);

  void ClearForClose();
  void CreateIsolateFor(PassOwnPtr<DOMDartState> dom_dart_state);
  void InstallView(View* view);

  DOMDartState* dart_state() const { return dom_dart_state_.get(); }

 private:
  void DidLoadMainLibrary(String url);
  void DidLoadSnapshot();

  OwnPtr<DOMDartState> dom_dart_state_;
  OwnPtr<BuiltinSky> builtin_sky_;
  OwnPtr<DartLibraryProviderWebView> library_provider_;
  OwnPtr<DartSnapshotLoader> snapshot_loader_;

  base::WeakPtrFactory<DartController> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(DartController);
};

}

#endif // SKY_ENGINE_CORE_SCRIPT_DART_CONTROLLER_H_
