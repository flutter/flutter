// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TONIC_DART_LIBRARY_LOADER_H_
#define FLUTTER_TONIC_DART_LIBRARY_LOADER_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

#include "base/callback_forward.h"
#include "base/macros.h"
#include "base/memory/weak_ptr.h"
#include "dart/runtime/include/dart_api.h"

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
  // isolates or from the handle watcher isolate thread.
  static Dart_Handle HandleLibraryTag(Dart_LibraryTag tag,
                                      Dart_Handle library,
                                      Dart_Handle url);

  void LoadLibrary(const std::string& name);
  void LoadScript(const std::string& name);

  void WaitForDependencies(
      const std::unordered_set<DartDependency*>& dependencies,
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
  std::unordered_map<std::string, Job*> pending_libraries_;
  std::unordered_set<std::unique_ptr<Job>> jobs_;
  std::unordered_set<std::unique_ptr<DependencyWatcher>> dependency_watchers_;
  DartDependencyCatcher* dependency_catcher_;

  DISALLOW_COPY_AND_ASSIGN(DartLibraryLoader);
};

}  // namespace blink

#endif  // FLUTTER_TONIC_DART_LIBRARY_LOADER_H_
