// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_TONIC_DART_LIBRARY_LOADER_H_
#define SKY_ENGINE_TONIC_DART_LIBRARY_LOADER_H_

#include <vector>
#include "base/callback_forward.h"
#include "base/macros.h"
#include "base/memory/weak_ptr.h"
#include "dart/runtime/include/dart_api.h"
#include "sky/engine/wtf/HashMap.h"
#include "sky/engine/wtf/HashSet.h"
#include "sky/engine/wtf/OwnPtr.h"
#include "sky/engine/wtf/text/WTFString.h"

namespace blink {
class DartDependency;
class DartDependencyCatcher;
class DartLibraryProvider;
class DartState;

// TODO(abarth): This class seems more complicated than it needs to be. Is
// there some way of simplifying this system? For example, we have a bunch
// of inner classes that could potentially be factored out in some other way.
class DartLibraryLoader {
 public:
  explicit DartLibraryLoader(DartState* dart_state);
  ~DartLibraryLoader();

  // TODO(dart): This can be called both on the main thread from application
  // solates or from the handle watcher isolate thread.
  static Dart_Handle HandleLibraryTag(Dart_LibraryTag tag,
                                      Dart_Handle library,
                                      Dart_Handle url);

  void LoadLibrary(const String& name);

  void WaitForDependencies(const HashSet<DartDependency*>& dependencies,
                           const base::Closure& callback);

  void set_dependency_catcher(DartDependencyCatcher* dependency_catcher) {
    DCHECK(!dependency_catcher_ || !dependency_catcher);
    dependency_catcher_ = dependency_catcher;
  }

  DartState* dart_state() const { return dart_state_; }

  DartLibraryProvider* library_provider() const { return library_provider_; }

  // The |DartLibraryProvider| must outlive the |DartLibraryLoader|.
  void set_library_provider(DartLibraryProvider* library_provider) {
    library_provider_ = library_provider;
  }

 private:
  class Job;
  class ImportJob;
  class SourceJob;
  class DependencyWatcher;
  class WatcherSignaler;

  Dart_Handle Import(Dart_Handle library, Dart_Handle url);
  Dart_Handle Source(Dart_Handle library, Dart_Handle url);
  Dart_Handle CanonicalizeURL(Dart_Handle library, Dart_Handle url);
  void DidCompleteImportJob(ImportJob* job, const std::vector<uint8_t>& buffer);
  void DidCompleteSourceJob(SourceJob* job, const std::vector<uint8_t>& buffer);
  void DidFailJob(Job* job);

  DartState* dart_state_;
  DartLibraryProvider* library_provider_;
  HashMap<String, Job*> pending_libraries_;
  HashSet<OwnPtr<Job>> jobs_;
  HashSet<OwnPtr<DependencyWatcher>> dependency_watchers_;
  DartDependencyCatcher* dependency_catcher_;

  DISALLOW_COPY_AND_ASSIGN(DartLibraryLoader);
};

}  // namespace blink

#endif  // SKY_ENGINE_TONIC_DART_LIBRARY_LOADER_H_
