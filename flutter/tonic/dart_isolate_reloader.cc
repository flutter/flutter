// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/tonic/dart_isolate_reloader.h"

#include <utility>

#include "flutter/tonic/dart_dependency_catcher.h"
#include "flutter/tonic/dart_library_loader.h"
#include "flutter/tonic/dart_library_provider.h"
#include "flutter/tonic/dart_state.h"
#include "glue/thread.h"
#include "lib/ftl/logging.h"
#include "lib/ftl/synchronization/monitor.h"
#include "lib/tonic/converter/dart_converter.h"
#include "lib/tonic/logging/dart_error.h"
#include "lib/tonic/scopes/dart_api_scope.h"
#include "lib/tonic/scopes/dart_isolate_scope.h"
#include "mojo/data_pipe_utils/data_pipe_drainer.h"

using mojo::common::DataPipeDrainer;
using tonic::ToDart;
using tonic::StdStringToDart;
using tonic::StdStringFromDart;

namespace blink {

// As each source file is loaded, a LoadResult is queued to be processed on the
// isolate's thread. A LoadResult contains the payload or an error message.
class DartIsolateReloader::LoadResult {
 public:
  // Successful load result.
  LoadResult(intptr_t tag,
             const std::string& url,
             const std::string& library_url,
             const std::string& resolved_url,
             std::vector<uint8_t> payload)
      : success_(true),
        tag_(tag),
        url_(url),
        library_url_(library_url),
        resolved_url_(resolved_url),
        payload_(std::move(payload)) {
    FTL_DCHECK(success());
  }

  // Error load result.
  LoadResult(intptr_t tag,
             const std::string& url,
             const std::string& library_url,
             const std::string& error)
      : success_(false),
        tag_(tag),
        url_(url),
        library_url_(library_url),
        error_(error) {}

  bool success() const { return success_; }

  Dart_Handle Finish() {
    if (!success()) {
      return StdStringToDart(error_);
    }
    Dart_Handle uri = StdStringToDart(url_);
    Dart_Handle resolved_uri = Dart_Null();
    if (!resolved_url_.empty()) {
      resolved_uri = StdStringToDart(resolved_url_);
    }
    Dart_Handle library = Dart_Null();
    if (!library_url_.empty()) {
      library = Dart_LookupLibrary(StdStringToDart(library_url_));
    }
    Dart_Handle source =
        Dart_NewStringFromUTF8(payload_.data(), payload_.size());
    Dart_Handle result = Dart_Null();
    switch (tag_) {
      case Dart_kImportTag:
        result = Dart_LoadLibrary(uri, resolved_uri, source, 0, 0);
        break;
      case Dart_kSourceTag:
        result = Dart_LoadSource(library, uri, resolved_uri, source, 0, 0);
        break;
      case Dart_kScriptTag:
        result = Dart_LoadScript(uri, resolved_uri, source, 0, 0);
        break;
    }

    if (Dart_IsError(result)) {
      return result;
    }
    return Dart_Null();
  }

 private:
  bool success_;
  intptr_t tag_;
  std::string url_;
  std::string library_url_;
  std::string resolved_url_;
  std::string error_;
  std::vector<uint8_t> payload_;
};

DartIsolateReloader::DartIsolateReloader(DartLibraryProvider* library_provider)
    : thread_("DartIsolateReloader"),
      library_provider_(library_provider),
      load_error_(Dart_Null()),
      pending_requests_(0) {
  FTL_CHECK(thread_.Start());
}

DartIsolateReloader::~DartIsolateReloader() {}

void DartIsolateReloader::SendRequest(Dart_LibraryTag tag,
                                      Dart_Handle url,
                                      Dart_Handle library_url) {
  ftl::RefPtr<ftl::TaskRunner> runner = thread_.task_runner();
  std::string url_string = StdStringFromDart(url);
  std::string library_url_string = StdStringFromDart(library_url);

  ftl::MonitorLocker locker(&monitor_);

  // Post a task to the worker thread. This task will request the I/O and
  // post a LoadResult to be processed once complete.
  runner->PostTask([this, tag, url_string, library_url_string]() {
    RequestTask(library_provider_, this, static_cast<intptr_t>(tag), url_string,
                library_url_string);
  });

  pending_requests_++;
}

void DartIsolateReloader::PostResult(std::unique_ptr<LoadResult> load_result) {
  ftl::MonitorLocker locker(&monitor_);
  pending_requests_--;
  load_results_.push(std::move(load_result));
  locker.Signal();
}

// As each source file is requested, a LoadRequest is queued to be processed on
// worker thread.
class DartIsolateReloader::LoadRequest : public DataPipeDrainer::Client {
 public:
  LoadRequest(DartLibraryProvider* library_provider,
              DartIsolateReloader* isolate_reloader,
              intptr_t tag,
              const std::string& url,
              const std::string& library_url)
      : isolate_reloader_(isolate_reloader),
        tag_(tag),
        url_(url),
        library_url_(library_url) {
    auto stream = library_provider->GetLibraryAsStream(url_);
    OnStreamAvailable(std::move(stream.handle), std::move(stream.resolved_url));
  }

 protected:
  void OnStreamAvailable(mojo::ScopedDataPipeConsumerHandle handle,
                         std::string resolved_url) {
    if (!handle.is_valid()) {
      std::unique_ptr<DartIsolateReloader::LoadResult> result(
          new DartIsolateReloader::LoadResult(
              tag_, url_, library_url_,
              "File " + url_ + " could not be read."));
      LOG(ERROR) << "Load failed for " << url_;
      isolate_reloader_->PostResult(std::move(result));
      // We are finished with this request.
      delete this;
      return;
    }
    resolved_url_ = std::move(resolved_url);
    drainer_.reset(new DataPipeDrainer(this, std::move(handle)));
  }

  // DataPipeDrainer::Client
  void OnDataAvailable(const void* data, size_t num_bytes) override {
    const uint8_t* bytes = static_cast<const uint8_t*>(data);
    buffer_.insert(buffer_.end(), bytes, bytes + num_bytes);
  }

  // DataPipeDrainer::Client
  void OnDataComplete() override {
    std::unique_ptr<DartIsolateReloader::LoadResult> result(
        new DartIsolateReloader::LoadResult(tag_, url_, library_url_,
                                            resolved_url_, std::move(buffer_)));
    isolate_reloader_->PostResult(std::move(result));
    // We are finished with this request.
    delete this;
  }

 private:
  DartIsolateReloader* isolate_reloader_;
  intptr_t tag_;
  std::string url_;
  std::string library_url_;
  std::string resolved_url_;
  std::vector<uint8_t> buffer_;
  std::unique_ptr<DataPipeDrainer> drainer_;
};

void DartIsolateReloader::RequestTask(DartLibraryProvider* library_provider,
                                      DartIsolateReloader* isolate_reloader,
                                      intptr_t tag,
                                      const std::string& url,
                                      const std::string& library_url) {
  FTL_DCHECK(isolate_reloader);
  FTL_DCHECK(library_provider);
  FTL_DCHECK(tag > 0);
  // Construct a new LoadRequest. The pointer is dropped here because
  // the request deletes itself on success and failure.
  new LoadRequest(library_provider, isolate_reloader, tag, url, library_url);
}

void DartIsolateReloader::HandleLoadResultLocked(LoadResult* load_result) {
  if (load_error_ != Dart_Null()) {
    // Already have a sticky error. Just drop this result.
    return;
  }

  // Drop the lock temporarily around the call to Finish because it may
  // trigger a recursive call into the tag handler.
  monitor_.Exit();
  Dart_Handle error_or_null = load_result->Finish();
  monitor_.Enter();

  if (!Dart_IsNull(error_or_null)) {
    // Set sticky error.
    load_error_ = error_or_null;
  }
}

void DartIsolateReloader::ProcessResultQueueLocked() {
  while (load_results_.size() > 0) {
    // Grab the first load result.
    std::unique_ptr<LoadResult> result = std::move(load_results_.front());
    load_results_.pop();
    HandleLoadResultLocked(result.get());
  }
}

bool DartIsolateReloader::IsCompleteLocked() {
  return (pending_requests_ == 0) && load_results_.empty();
}

bool DartIsolateReloader::BlockUntilComplete() {
  ftl::MonitorLocker locker(&monitor_);

  while (true) {
    ProcessResultQueueLocked();

    if (IsCompleteLocked()) {
      break;
    }

    // Wait to be notified about new I/O results.
    locker.Wait();
  }
  return !Dart_IsNull(load_error_);
}

Dart_Handle DartIsolateReloader::HandleLibraryTag(Dart_LibraryTag tag,
                                                  Dart_Handle library,
                                                  Dart_Handle url) {
  if (tag == Dart_kCanonicalizeUrl) {
    // Pass through to actual tag handler.
    return DartLibraryLoader::HandleLibraryTag(tag, library, url);
  }
  DartState* dart_state = DartState::Current();
  FTL_DCHECK(dart_state);
  DartIsolateReloader* isolate_reloader = dart_state->isolate_reloader();
  // The first call into the tag handler ends up blocking the calling thread
  // until the entire reload has completed. All other calls into the
  // tag handler schedule requests and return immediately.
  const bool blocking_call = (tag == Dart_kScriptTag);
  if (!isolate_reloader) {
    // The first call into this tag handler must be for the script.
    FTL_DCHECK(tag == Dart_kScriptTag);
    // Associate the reloader with the isolate. The reloader is owned
    // by the dart_state.
    dart_state->set_isolate_reloader(
        std::unique_ptr<DartIsolateReloader>(new DartIsolateReloader(
            dart_state->library_loader().library_provider())));
    // Get a pointer to the reloader.
    isolate_reloader = dart_state->isolate_reloader();
    // Switch the tag handler.
    Dart_SetLibraryTagHandler(DartIsolateReloader::HandleLibraryTag);
  } else {
    // We should not see another request for the script.
    FTL_DCHECK(tag != Dart_kScriptTag);
  }

  // Issue I/O request.
  isolate_reloader->SendRequest(tag, url, (library != Dart_Null())
                                              ? Dart_LibraryUrl(library)
                                              : Dart_Null());

  if (blocking_call) {
    // Block and process LoadResults until the load is complete.
    const bool load_error = isolate_reloader->BlockUntilComplete();
    // Grab the (possibly null) load error from the reloader before its gone.
    Dart_Handle result = isolate_reloader->load_error_;
    // The reloader will be deleted once we call set_isolate_reloader below.
    isolate_reloader = nullptr;
    // Disassociate reloader from the isolate, this causes it to be deleted.
    dart_state->set_isolate_reloader(nullptr);
    Dart_SetLibraryTagHandler(DartLibraryLoader::HandleLibraryTag);
    if (load_error) {
      // If we hit an error, return the load error.
      return result;
    } else {
      // Finalize loading.
      result = Dart_FinalizeLoading(true);
      if (Dart_IsError(result)) {
        // If we hit an error, return the load error.
        return result;
      }
    }
  }

  return Dart_Null();
}

}  // namespace blink
