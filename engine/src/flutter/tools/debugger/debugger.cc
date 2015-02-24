// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <algorithm>

#include "base/bind.h"
#include "base/debug/profiler.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/stringprintf.h"
#include "mojo/application/application_runner_chromium.h"
#include "mojo/common/data_pipe_utils.h"
#include "mojo/public/c/system/main.h"
#include "mojo/public/cpp/application/application_delegate.h"
#include "mojo/public/cpp/application/application_impl.h"
#include "mojo/public/cpp/bindings/binding.h"
#include "mojo/services/window_manager/public/interfaces/window_manager.mojom.h"
#include "services/http_server/public/http_server.mojom.h"
#include "services/http_server/public/http_server_factory.mojom.h"
#include "services/http_server/public/http_server_util.h"
#include "services/tracing/tracing.mojom.h"
#include "sky/tools/debugger/trace_collector.h"

namespace sky {
namespace debugger {

class SkyDebugger : public mojo::ApplicationDelegate,
                    public http_server::HttpHandler {
 public:
  SkyDebugger() : is_tracing_(false), handler_binding_(this) {}
  virtual ~SkyDebugger() {}

 private:
  // mojo::ApplicationDelegate:
  void Initialize(mojo::ApplicationImpl* app) override {
    app->ConnectToService("mojo:tracing", &tracing_);
    app->ConnectToService("mojo:window_manager", &window_manager_);

    // Format: --args-for="app_url command_port"
    if (app->args().size() < 2) {
      LOG(ERROR) << "--args-for required to specify command_port";
      mojo::ApplicationImpl::Terminate();
      return;
    }
    base::StringToUint(app->args()[1], &command_port_);
    http_server::HttpServerFactoryPtr http_server_factory;
    app->ConnectToService("mojo:http_server", &http_server_factory);
    http_server_factory->CreateHttpServer(GetProxy(&http_server_).Pass(),
                                          command_port_);

    http_server::HttpHandlerPtr handler_ptr;
    handler_binding_.Bind(GetProxy(&handler_ptr).Pass());
    http_server_->SetHandler(".*", handler_ptr.Pass(),
                             [](bool result) { DCHECK(result); });
  }

  bool ConfigureIncomingConnection(
      mojo::ApplicationConnection* connection) override {
    return true;
  }

  // http_server::HttpHandler:
  void HandleRequest(http_server::HttpRequestPtr request,
                     const HandleRequestCallback& callback) override {
    // FIXME: We should use use a fancier lookup system more like what
    // services/http_server/http_server.cc does with AddHandler.
    if (request->relative_url == "/reload") {
      Load(callback, url_);
    } else if (request->relative_url == "/quit") {
      Exit();
    } else if (request->relative_url == "/load") {
      std::string url;
      mojo::common::BlockingCopyToString(request->body.Pass(), &url);
      Load(callback, url);
    } else if (request->relative_url == "/start_profiling") {
      StartProfiling(callback);
    } else if (request->relative_url == "/stop_profiling") {
      StopProfiling(callback);
    } else if (request->relative_url == "/start_tracing") {
      StartTracing(callback);
    } else if (request->relative_url == "/stop_tracing") {
      StopTracing(callback);
    } else {
      Help(callback, request->relative_url);
    }
  }

  void Error(const HandleRequestCallback& callback, std::string message) {
    callback.Run(http_server::CreateHttpResponse(500, message));
  }

  void Respond(const HandleRequestCallback& callback, std::string response) {
    callback.Run(http_server::CreateHttpResponse(200, response));
  }

  void Help(const HandleRequestCallback& callback, std::string path) {
    std::string help = base::StringPrintf(
        "Sky Debugger running on port %d\n"
        "Supported URLs:\n"
        "/reload           -- Reload the current page\n"
        "/quit             -- Quit\n"
        "/load             -- Load a new URL, url in POST body.\n",
        command_port_);
    if (path != "/")
      help = "Unknown path: " + path + "\n\n" + help;
    Respond(callback, help);
  }

  void Load(const HandleRequestCallback& callback, std::string url) {
    url_ = url;
    Reload();
    std::string response = std::string("Loaded ") + url + "\n";
    Respond(callback, response);
  }

  void Reload() {
    // SimpleWindowManager will wire up necessary services on our behalf.
    window_manager_->Embed(url_, nullptr, nullptr);
  }

  void Exit() {
    // TODO(eseidel): We should orderly shutdown once mojo can.
    exit(0);
  }

  void StartTracing(const HandleRequestCallback& callback) {
    if (is_tracing_) {
      Error(callback, "Already tracing. Use stop_tracing to stop.\n");
      return;
    }

    is_tracing_ = true;
    mojo::DataPipe pipe;
    tracing_->Start(pipe.producer_handle.Pass(), mojo::String("*"));
    trace_collector_.reset(new TraceCollector(pipe.consumer_handle.Pass()));
    Respond(callback, "Starting trace (type 'stop_tracing' to stop)\n");
  }

  void StopTracing(const HandleRequestCallback& callback) {
    if (!is_tracing_) {
      Error(callback, "Not tracing yet. Use start_tracing to start.\n");
      return;
    }

    is_tracing_ = false;
    tracing_->StopAndFlush();
    trace_collector_->GetTrace(base::Bind(&SkyDebugger::OnTraceAvailable,
                                          base::Unretained(this), callback));
  }

  void OnTraceAvailable(HandleRequestCallback callback, std::string trace) {
    trace_collector_.reset();
    Respond(callback, trace);
  }

  void StartProfiling(const HandleRequestCallback& callback) {
#if !defined(NDEBUG) || !defined(ENABLE_PROFILING)
    Error(callback,
          "Profiling requires is_debug=false and enable_profiling=true");
    return;
#else
    base::debug::StartProfiling("sky_viewer.pprof");
    Respond(callback, "Starting profiling (stop with 'stop_profiling')");
#endif
  }

  void StopProfiling(const HandleRequestCallback& callback) {
    if (!base::debug::BeingProfiled()) {
      Error(callback, "Profiling not started");
      return;
    }
    base::debug::StopProfiling();
    Respond(callback, "Stopped profiling");
  }

  bool is_tracing_;
  mojo::WindowManagerPtr window_manager_;
  tracing::TraceCoordinatorPtr tracing_;
  std::string url_;
  uint32_t command_port_;

  http_server::HttpServerPtr http_server_;
  mojo::Binding<http_server::HttpHandler> handler_binding_;

  scoped_ptr<TraceCollector> trace_collector_;

  DISALLOW_COPY_AND_ASSIGN(SkyDebugger);
};

}  // namespace debugger
}  // namespace sky

MojoResult MojoMain(MojoHandle shell_handle) {
  mojo::ApplicationRunnerChromium runner(new sky::debugger::SkyDebugger);
  runner.set_message_loop_type(base::MessageLoop::TYPE_IO);
  return runner.Run(shell_handle);
}
