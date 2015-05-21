// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/script/dart_loader.h"

#include "base/callback.h"
#include "base/trace_event/trace_event.h"
#include "mojo/common/data_pipe_drainer.h"
#include "sky/engine/core/script/dart_dependency_catcher.h"
#include "sky/engine/core/script/dom_dart_state.h"
#include "sky/engine/platform/fetcher/MojoFetcher.h"
#include "sky/engine/platform/weborigin/KURL.h"
#include "sky/engine/tonic/dart_api_scope.h"
#include "sky/engine/tonic/dart_converter.h"
#include "sky/engine/tonic/dart_error.h"
#include "sky/engine/tonic/dart_isolate_scope.h"
#include "sky/engine/wtf/MainThread.h"

using mojo::common::DataPipeDrainer;

namespace blink {
namespace {

Dart_Handle CanonicalizeURL(DartState* state,
                            Dart_Handle library,
                            Dart_Handle url) {
  String string = StringFromDart(url);
  if (string.startsWith("dart:") || string.startsWith("mojo:"))
    return url;
  // TODO(dart): Figure out how 'package:' should work in sky.
  if (string.startsWith("package:")) {
    string.replace("package:", "/packages/");
  }
  String library_url_string = StringFromDart(Dart_LibraryUrl(library));
  KURL library_url = KURL(ParsedURLString, library_url_string);
  KURL resolved_url = KURL(library_url, string);
  return StringToDart(state, resolved_url.string());
}

}  // namespace

// A DartLoader::Job represents a network load. It fetches data from the network
// and buffers the data in Vector. To cancel the job, delete this object.
class DartLoader::Job : public DartDependency,
                        public MojoFetcher::Client,
                        public DataPipeDrainer::Client {
 public:
  Job(DartLoader* loader, const KURL& url, mojo::URLResponsePtr response)
      : loader_(loader), url_(url)
  {
    if (!response) {
      fetcher_ = adoptPtr(new MojoFetcher(this, url));
    } else {
      OnReceivedResponse(response.Pass());
    }
  }

  const KURL& url() const { return url_; }

 protected:
  DartLoader* loader_;
  // TODO(abarth): Should we be using SharedBuffer to buffer the data?
  Vector<uint8_t> buffer_;

 private:
  // MojoFetcher::Client
  void OnReceivedResponse(mojo::URLResponsePtr response) override {
    if (response->status_code != 200) {
      loader_->DidFailJob(this);
      return;
    }
    drainer_ = adoptPtr(new DataPipeDrainer(this, response->body.Pass()));
  }

  // DataPipeDrainer::Client
  void OnDataAvailable(const void* data, size_t num_bytes) override {
    buffer_.append(static_cast<const uint8_t*>(data), num_bytes);
  }
  // Subclasses must implement OnDataComplete.

  KURL url_;
  OwnPtr<MojoFetcher> fetcher_;
  OwnPtr<DataPipeDrainer> drainer_;
};

class DartLoader::ImportJob : public Job {
 public:
  ImportJob(DartLoader* loader, const KURL& url, mojo::URLResponsePtr response = nullptr)
    : Job(loader, url, response.Pass()) {
    TRACE_EVENT_ASYNC_BEGIN1("sky", "DartLoader::ImportJob", this,
                             "url", url.string().ascii().toStdString());
  }

 private:
  // DataPipeDrainer::Client
  void OnDataComplete() override {
    TRACE_EVENT_ASYNC_END0("sky", "DartLoader::ImportJob", this);
    loader_->DidCompleteImportJob(this, buffer_);
  }
};

class DartLoader::SourceJob : public Job {
 public:
  SourceJob(DartLoader* loader, const KURL& url, Dart_Handle library)
      : Job(loader, url, nullptr), library_(loader->dart_state(), library) {
    TRACE_EVENT_ASYNC_BEGIN1("sky", "DartLoader::SourceJob", this,
                             "url", url.string().ascii().toStdString());
  }

  Dart_PersistentHandle library() const { return library_.value(); }

 private:
  // DataPipeDrainer::Client
  void OnDataComplete() override {
    TRACE_EVENT_ASYNC_END0("sky", "DartLoader::SourceJob", this);
    loader_->DidCompleteSourceJob(this, buffer_);
  }

  DartPersistentValue library_;
};

// A DependencyWatcher represents a request to watch for when a given set of
// dependencies (either libraries or parts of libraries) have finished loading.
// When the dependencies are satisfied (including transitive dependencies), then
// the |callback| will be invoked.
class DartLoader::DependencyWatcher {
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
class DartLoader::WatcherSignaler {
 public:
  WatcherSignaler(DartLoader& loader, DartDependency* resolved_dependency)
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
  DartLoader& loader_;
  OwnPtr<DartDependencyCatcher> catcher_;
  DartDependency* resolved_dependency_;
};

DartLoader::DartLoader(DartState* dart_state)
    : dart_state_(dart_state->GetWeakPtr()),
      dependency_catcher_(nullptr) {
}

DartLoader::~DartLoader() {
}

Dart_Handle DartLoader::HandleLibraryTag(Dart_LibraryTag tag,
                                         Dart_Handle library,
                                         Dart_Handle url) {
  DCHECK(Dart_IsLibrary(library));
  DCHECK(Dart_IsString(url));
  if (tag == Dart_kCanonicalizeUrl)
    return CanonicalizeURL(DartState::Current(), library, url);
  if (tag == Dart_kImportTag) {
    CHECK(WTF::isMainThread());

    String string = StringFromDart(url);
    if (string.startsWith("mojo:")) {
      Dart_Handle mojo_library = Dart_LookupLibrary(url);
      LogIfError(mojo_library);
      return mojo_library;
    }

    return DOMDartState::Current()->loader().Import(library, url);
  }
  if (tag == Dart_kSourceTag) {
    CHECK(WTF::isMainThread());
    return DOMDartState::Current()->loader().Source(library, url);
  }
  DCHECK(false);
  return Dart_NewApiError("Unknown library tag.");
}

void DartLoader::WaitForDependencies(
    const HashSet<DartDependency*>& dependencies,
    const base::Closure& callback) {
  if (dependencies.isEmpty())
    return callback.Run();
  dependency_watchers_.add(
      adoptPtr(new DependencyWatcher(dependencies, callback)));
}

void DartLoader::LoadLibrary(const KURL& url, mojo::URLResponsePtr response) {
  const auto& result = pending_libraries_.add(url.string(), nullptr);
  if (result.isNewEntry) {
    OwnPtr<Job> job = adoptPtr(new ImportJob(this, url));
    result.storedValue->value = job.get();
    jobs_.add(job.release());
  }
  if (dependency_catcher_)
    dependency_catcher_->AddDependency(result.storedValue->value);
}

Dart_Handle DartLoader::Import(Dart_Handle library, Dart_Handle url) {
  LoadLibrary(KURL(ParsedURLString, StringFromDart(url)));
  return Dart_True();
}

Dart_Handle DartLoader::Source(Dart_Handle library, Dart_Handle url) {
  KURL parsed_url(ParsedURLString, StringFromDart(url));
  OwnPtr<Job> job = adoptPtr(new SourceJob(this, parsed_url, library));
  if (dependency_catcher_)
    dependency_catcher_->AddDependency(job.get());
  jobs_.add(job.release());
  return Dart_True();
}

void DartLoader::DidCompleteImportJob(ImportJob* job,
                                      const Vector<uint8_t>& buffer) {
  DCHECK(dart_state_);
  DartIsolateScope scope(dart_state_->isolate());
  DartApiScope api_scope;

  WatcherSignaler watcher_signaler(*this, job);

  String url_string = job->url().string();
  LogIfError(Dart_LoadLibrary(
      StringToDart(dart_state_.get(), url_string),
      Dart_NewStringFromUTF8(buffer.data(), buffer.size()), 0, 0));

  pending_libraries_.remove(url_string);
  jobs_.remove(job);
}

void DartLoader::DidCompleteSourceJob(SourceJob* job,
                                      const Vector<uint8_t>& buffer) {
  DCHECK(dart_state_);
  DartIsolateScope scope(dart_state_->isolate());
  DartApiScope api_scope;

  WatcherSignaler watcher_signaler(*this, job);

  LogIfError(Dart_LoadSource(
      Dart_HandleFromPersistent(job->library()),
      StringToDart(dart_state_.get(), job->url().string()),
      Dart_NewStringFromUTF8(buffer.data(), buffer.size()), 0, 0));

  jobs_.remove(job);
}

void DartLoader::DidFailJob(Job* job) {
  DCHECK(dart_state_);
  DartIsolateScope scope(dart_state_->isolate());
  DartApiScope api_scope;

  WatcherSignaler watcher_signaler(*this, job);

  LOG(ERROR) << "Library Load failed: " << job->url().string().utf8().data();
  // TODO(eseidel): Call Dart_LibraryHandleError in the SourceJob case?

  jobs_.remove(job);
}

}  // namespace blink
