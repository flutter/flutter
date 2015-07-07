// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/tonic/dart_library_loader.h"

#include "base/callback.h"
#include "base/trace_event/trace_event.h"
#include "mojo/common/data_pipe_drainer.h"
#include "sky/engine/tonic/dart_api_scope.h"
#include "sky/engine/tonic/dart_converter.h"
#include "sky/engine/tonic/dart_dependency_catcher.h"
#include "sky/engine/tonic/dart_error.h"
#include "sky/engine/tonic/dart_isolate_scope.h"
#include "sky/engine/tonic/dart_library_provider.h"
#include "sky/engine/tonic/dart_state.h"
#include "sky/engine/wtf/MainThread.h"

using mojo::common::DataPipeDrainer;

namespace blink {

// A DartLibraryLoader::Job represents a network load. It fetches data from the
// network and buffers the data in Vector. To cancel the job, delete this
// object.
class DartLibraryLoader::Job : public DartDependency,
                               public DataPipeDrainer::Client {
 public:
  Job(DartLibraryLoader* loader, const String& name)
      : loader_(loader), name_(name), weak_factory_(this) {
    loader->library_provider()->GetLibraryAsStream(
        name, base::Bind(&Job::OnStreamAvailable, weak_factory_.GetWeakPtr()));
  }

  const String& name() const { return name_; }

 protected:
  DartLibraryLoader* loader_;
  // TODO(abarth): Should we be using SharedBuffer to buffer the data?
  Vector<uint8_t> buffer_;

 private:
  void OnStreamAvailable(mojo::ScopedDataPipeConsumerHandle pipe) {
    if (!pipe.is_valid()) {
      loader_->DidFailJob(this);
      return;
    }
    drainer_ = adoptPtr(new DataPipeDrainer(this, pipe.Pass()));
  }

  // DataPipeDrainer::Client
  void OnDataAvailable(const void* data, size_t num_bytes) override {
    buffer_.append(static_cast<const uint8_t*>(data), num_bytes);
  }
  // Subclasses must implement OnDataComplete.

  String name_;
  OwnPtr<DataPipeDrainer> drainer_;

  base::WeakPtrFactory<Job> weak_factory_;
};

class DartLibraryLoader::ImportJob : public Job {
 public:
  ImportJob(DartLibraryLoader* loader, const String& name) : Job(loader, name) {
    TRACE_EVENT_ASYNC_BEGIN1("sky", "DartLibraryLoader::ImportJob", this, "url",
                             name.ascii().toStdString());
  }

 private:
  // DataPipeDrainer::Client
  void OnDataComplete() override {
    TRACE_EVENT_ASYNC_END0("sky", "DartLibraryLoader::ImportJob", this);
    loader_->DidCompleteImportJob(this, buffer_);
  }
};

class DartLibraryLoader::SourceJob : public Job {
 public:
  SourceJob(DartLibraryLoader* loader, const String& name, Dart_Handle library)
      : Job(loader, name), library_(loader->dart_state(), library) {
    TRACE_EVENT_ASYNC_BEGIN1("sky", "DartLibraryLoader::SourceJob", this, "url",
                             name.ascii().toStdString());
  }

  Dart_PersistentHandle library() const { return library_.value(); }

 private:
  // DataPipeDrainer::Client
  void OnDataComplete() override {
    TRACE_EVENT_ASYNC_END0("sky", "DartLibraryLoader::SourceJob", this);
    loader_->DidCompleteSourceJob(this, buffer_);
  }

  DartPersistentValue library_;
};

// A DependencyWatcher represents a request to watch for when a given set of
// dependencies (either libraries or parts of libraries) have finished loading.
// When the dependencies are satisfied (including transitive dependencies), then
// the |callback| will be invoked.
class DartLibraryLoader::DependencyWatcher {
 public:
  DependencyWatcher(const HashSet<DartDependency*>& dependencies,
                    const base::Closure& callback)
      : dependencies_(dependencies), callback_(callback) {
    DCHECK(!dependencies_.isEmpty());
  }

  bool DidResolveDependency(DartDependency* resolved_dependency,
                            const HashSet<DartDependency*>& new_dependencies) {
    const auto& it = dependencies_.find(resolved_dependency);
    if (it == dependencies_.end())
      return false;
    dependencies_.remove(it);
    for (const auto& dependency : new_dependencies)
      dependencies_.add(dependency);
    return dependencies_.isEmpty();
  }

  const base::Closure& callback() const { return callback_; }

 private:
  HashSet<DartDependency*> dependencies_;
  base::Closure callback_;
};

// A WatcherSignaler is responsible for signaling DependencyWatchers when their
// dependencies resolve and for calling the DependencyWatcher's callback. We use
// a separate object of this task because we want to carefully manage when we
// call the callbacks, which can call into us again reentrantly.
//
// WatcherSignaler is designed to be placed on the stack as a RAII. After its
// destructor runs, we might have executed aribitrary script.
class DartLibraryLoader::WatcherSignaler {
 public:
  WatcherSignaler(DartLibraryLoader& loader,
                  DartDependency* resolved_dependency)
      : loader_(loader),
        catcher_(adoptPtr(new DartDependencyCatcher(loader))),
        resolved_dependency_(resolved_dependency) {}

  ~WatcherSignaler() {
    Vector<DependencyWatcher*> completed_watchers;
    for (const auto& watcher : loader_.dependency_watchers_) {
      if (watcher->DidResolveDependency(resolved_dependency_,
                                        catcher_->dependencies()))
        completed_watchers.append(watcher.get());
    }

    // Notice that we remove the dependency catcher and extract all the
    // callbacks before running any of them. We don't want to be re-entered
    // below the callbacks and end up in an inconsistent state.
    catcher_.clear();
    Vector<base::Closure> callbacks;
    for (const auto& watcher : completed_watchers) {
      callbacks.append(watcher->callback());
      loader_.dependency_watchers_.remove(watcher);
    }

    // Finally, run all the callbacks while touching only data on the stack.
    for (const auto& callback : callbacks)
      callback.Run();
  }

 private:
  DartLibraryLoader& loader_;
  OwnPtr<DartDependencyCatcher> catcher_;
  DartDependency* resolved_dependency_;
};

DartLibraryLoader::DartLibraryLoader(DartState* dart_state)
    : dart_state_(dart_state),
      library_provider_(nullptr),
      dependency_catcher_(nullptr) {
}

DartLibraryLoader::~DartLibraryLoader() {
}

Dart_Handle DartLibraryLoader::HandleLibraryTag(Dart_LibraryTag tag,
                                                Dart_Handle library,
                                                Dart_Handle url) {
  DCHECK(Dart_IsLibrary(library));
  DCHECK(Dart_IsString(url));
  if (tag == Dart_kCanonicalizeUrl)
    return DartState::Current()->library_loader().CanonicalizeURL(library, url);
  if (tag == Dart_kImportTag) {
    CHECK(WTF::isMainThread());
    return DartState::Current()->library_loader().Import(library, url);
  }
  if (tag == Dart_kSourceTag) {
    CHECK(WTF::isMainThread());
    return DartState::Current()->library_loader().Source(library, url);
  }
  DCHECK(false);
  return Dart_NewApiError("Unknown library tag.");
}

void DartLibraryLoader::WaitForDependencies(
    const HashSet<DartDependency*>& dependencies,
    const base::Closure& callback) {
  if (dependencies.isEmpty())
    return callback.Run();
  dependency_watchers_.add(
      adoptPtr(new DependencyWatcher(dependencies, callback)));
}

void DartLibraryLoader::LoadLibrary(const String& name) {
  const auto& result = pending_libraries_.add(name, nullptr);
  if (result.isNewEntry) {
    OwnPtr<Job> job = adoptPtr(new ImportJob(this, name));
    result.storedValue->value = job.get();
    jobs_.add(job.release());
  }
  if (dependency_catcher_)
    dependency_catcher_->AddDependency(result.storedValue->value);
}

Dart_Handle DartLibraryLoader::Import(Dart_Handle library, Dart_Handle url) {
  LoadLibrary(StringFromDart(url));
  return Dart_True();
}

Dart_Handle DartLibraryLoader::Source(Dart_Handle library, Dart_Handle url) {
  OwnPtr<Job> job = adoptPtr(new SourceJob(this, StringFromDart(url), library));
  if (dependency_catcher_)
    dependency_catcher_->AddDependency(job.get());
  jobs_.add(job.release());
  return Dart_True();
}

Dart_Handle DartLibraryLoader::CanonicalizeURL(Dart_Handle library,
                                               Dart_Handle url) {
  return library_provider_->CanonicalizeURL(library, url);
}

void DartLibraryLoader::DidCompleteImportJob(ImportJob* job,
                                             const Vector<uint8_t>& buffer) {
  DartIsolateScope scope(dart_state_->isolate());
  DartApiScope api_scope;

  WatcherSignaler watcher_signaler(*this, job);

  Dart_Handle result = Dart_LoadLibrary(
      StringToDart(dart_state_, job->name()),
      Dart_NewStringFromUTF8(buffer.data(), buffer.size()), 0, 0);
  if (Dart_IsError(result)) {
    LOG(ERROR) << "Error Loading " << job->name().utf8().data() << " "
        << Dart_GetError(result);
  }

  pending_libraries_.remove(job->name());
  jobs_.remove(job);
}

void DartLibraryLoader::DidCompleteSourceJob(SourceJob* job,
                                             const Vector<uint8_t>& buffer) {
  DartIsolateScope scope(dart_state_->isolate());
  DartApiScope api_scope;

  WatcherSignaler watcher_signaler(*this, job);

  Dart_Handle result = Dart_LoadSource(
      Dart_HandleFromPersistent(job->library()),
      StringToDart(dart_state_, job->name()),
      Dart_NewStringFromUTF8(buffer.data(), buffer.size()), 0, 0);

  if (Dart_IsError(result)) {
    LOG(ERROR) << "Error Loading " << job->name().utf8().data() << " "
        << Dart_GetError(result);
  }

  jobs_.remove(job);
}

void DartLibraryLoader::DidFailJob(Job* job) {
  DartIsolateScope scope(dart_state_->isolate());
  DartApiScope api_scope;

  WatcherSignaler watcher_signaler(*this, job);

  LOG(ERROR) << "Library Load failed: " << job->name().utf8().data();
  // TODO(eseidel): Call Dart_LibraryHandleError in the SourceJob case?

  jobs_.remove(job);
}

}  // namespace blink
