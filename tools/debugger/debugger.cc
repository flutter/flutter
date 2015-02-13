// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <algorithm>

#include "base/bind.h"
#include "base/debug/profiler.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/stringprintf.h"
#include "mojo/application/application_runner_chromium.h"
#include "mojo/public/c/system/main.h"
#include "mojo/public/cpp/application/application_delegate.h"
#include "mojo/public/cpp/application/application_impl.h"
#include "mojo/services/window_manager/public/interfaces/window_manager.mojom.h"
#include "net/base/net_errors.h"
#include "net/server/http_server.h"
#include "net/server/http_server_request_info.h"
#include "net/socket/tcp_server_socket.h"
#include "services/tracing/tracing.mojom.h"
#include "sky/tools/debugger/trace_collector.h"

namespace sky {
namespace debugger {
namespace {

const size_t kMinSendBufferSize = 1024 * 1024;
}

class SkyDebugger : public mojo::ApplicationDelegate,
                    public net::HttpServer::Delegate {
 public:
  SkyDebugger() : is_tracing_(false) {}
  virtual ~SkyDebugger() {}

 private:
  // Overridden from mojo::ApplicationDelegate:
  virtual void Initialize(mojo::ApplicationImpl* app) override {
    app->ConnectToService("mojo:tracing", &tracing_);
    // Format: --args-for="app_url command_port"
    if (app->args().size() < 2) {
      LOG(ERROR) << "--args-for required to specify command_port";
      mojo::ApplicationImpl::Terminate();
      return;
    }

    base::StringToUint(app->args()[1], &command_port_);

    scoped_ptr<net::ServerSocket> server_socket(
        new net::TCPServerSocket(NULL, net::NetLog::Source()));
    int result =
        server_socket->ListenWithAddressAndPort("0.0.0.0", command_port_, 1);
    if (result != net::OK) {
      LOG(ERROR) << "Failed to bind to port " << command_port_
                 << " skydb commands will not work.";
      mojo::ApplicationImpl::Terminate();
      return;
    }
    web_server_.reset(new net::HttpServer(server_socket.Pass(), this));

    app->ConnectToService("mojo:window_manager", &window_manager_);
  }

  virtual bool ConfigureIncomingConnection(
      mojo::ApplicationConnection* connection) override {
    return true;
  }

  // net::HttpServer::Delegate
  void OnConnect(int connection_id) override {}

  void OnClose(int connection_id) override {}

  void OnHttpRequest(int connection_id,
                     const net::HttpServerRequestInfo& info) override {
    // FIXME: We should use use a fancier lookup system more like what
    // services/http_server/http_server.cc does with AddHandler.
    if (info.path == "/reload")
      Load(connection_id, url_);
    else if (info.path == "/quit")
      Quit(connection_id);
    else if (info.path == "/load")
      Load(connection_id, info.data);
    else if (info.path == "/start_profiling")
      StartProfiling(connection_id);
    else if (info.path == "/stop_profiling")
      StopProfiling(connection_id);
    else if (info.path == "/start_tracing")
      StartTracing(connection_id);
    else if (info.path == "/stop_tracing")
      StopTracing(connection_id);
    else
      Help(info.path, connection_id);
  }

  void OnWebSocketRequest(int connection_id,
                          const net::HttpServerRequestInfo& info) override {
    Error(connection_id, "OnWebSocketRequest not implemented");
  }

  void OnWebSocketMessage(int connection_id, const std::string& data) override {
    Error(connection_id, "OnWebSocketMessage not implemented");
  }

  void Error(int connection_id, std::string message) {
    web_server_->Send500(connection_id, message);
  }

  void Respond(int connection_id, std::string response) {
    // When sending tracing data back over the wire to the client, we can blow
    // through the default send buffer size.
    web_server_->SetSendBufferSize(
        connection_id, std::max(kMinSendBufferSize, response.length()));
    web_server_->Send200(connection_id, response, "text/plain");
  }

  void Help(std::string path, int connection_id) {
    std::string help = base::StringPrintf(
        "Sky Debugger running on port %d\n"
        "Supported URLs:\n"
        "/reload           -- Reload the current page\n"
        "/quit             -- Quit\n"
        "/load             -- Load a new URL, url in POST body.\n",
        command_port_);
    if (path != "/")
      help = "Unknown path: " + path + "\n\n" + help;
    Respond(connection_id, help);
  }

  void Load(int connection_id, std::string url) {
    url_ = url;
    Reload();
    std::string response = std::string("Loaded ") + url + "\n";
    Respond(connection_id, response);
  }

  void Reload() {
    // SimpleWindowManager will wire up necessary services on our behalf.
    window_manager_->Embed(url_, nullptr, nullptr);
  }

  void Quit(int connection_id) {
    // TODO(eseidel): We should orderly shutdown once mojo can.
    exit(0);
  }

  void StartTracing(int connection_id) {
    if (is_tracing_) {
      Error(connection_id, "Already tracing. Use stop_tracing to stop.\n");
      return;
    }

    is_tracing_ = true;
    mojo::DataPipe pipe;
    tracing_->Start(pipe.producer_handle.Pass(), mojo::String("*"));
    trace_collector_.reset(new TraceCollector(pipe.consumer_handle.Pass()));
    Respond(connection_id, "Starting trace (type 'stop_tracing' to stop)\n");
  }

  void StopTracing(int connection_id) {
    if (!is_tracing_) {
      Error(connection_id, "Not tracing yet. Use start_tracing to start.\n");
      return;
    }

    is_tracing_ = false;
    tracing_->StopAndFlush();
    trace_collector_->GetTrace(base::Bind(
        &SkyDebugger::OnTraceAvailable, base::Unretained(this), connection_id));
  }

  void OnTraceAvailable(int connection_id, std::string trace) {
    trace_collector_.reset();
    Respond(connection_id, trace);
  }

  void StartProfiling(int connection_id) {
#if !defined(NDEBUG) || !defined(ENABLE_PROFILING)
    Error(connection_id,
          "Profiling requires is_debug=false and enable_profiling=true");
    return;
#else
    base::debug::StartProfiling("sky_viewer.pprof");
    Respond(connection_id, "Starting profiling (stop with 'stop_profiling')");
#endif
  }

  void StopProfiling(int connection_id) {
    if (!base::debug::BeingProfiled()) {
      Error(connection_id, "Profiling not started");
      return;
    }
    base::debug::StopProfiling();
    Respond(connection_id, "Stopped profiling");
  }

  bool is_tracing_;
  mojo::WindowManagerPtr window_manager_;
  tracing::TraceCoordinatorPtr tracing_;
  std::string url_;
  scoped_ptr<net::HttpServer> web_server_;
  uint32_t command_port_;

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
