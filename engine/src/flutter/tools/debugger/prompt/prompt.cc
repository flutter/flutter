// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <algorithm>

#include "base/bind.h"
#include "base/debug/profiler.h"
#include "base/memory/weak_ptr.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/stringprintf.h"
#include "mojo/application/application_runner_chromium.h"
#include "mojo/public/c/system/main.h"
#include "mojo/public/cpp/application/application_delegate.h"
#include "mojo/public/cpp/application/application_impl.h"
#include "net/base/net_errors.h"
#include "net/server/http_server.h"
#include "net/server/http_server_request_info.h"
#include "net/socket/tcp_server_socket.h"
#include "services/tracing/tracing.mojom.h"
#include "sky/tools/debugger/debugger.mojom.h"
#include "sky/tools/debugger/prompt/trace_collector.h"

namespace sky {
namespace debugger {
namespace {

const size_t kMinSendBufferSize = 1024 * 1024;
}

class Prompt : public mojo::ApplicationDelegate,
               public net::HttpServer::Delegate {
 public:
  Prompt()
      : is_tracing_(false),
        weak_ptr_factory_(this) {
  }
  virtual ~Prompt() {
  }

 private:
  // Overridden from mojo::ApplicationDelegate:
  virtual void Initialize(mojo::ApplicationImpl* app) override {
    app->ConnectToService("mojo:tracing", &tracing_);
    // app_url, command_port, url_to_load
    if (app->args().size() < 2) {
      LOG(ERROR) << "--args-for required to specify command_port";
      exit(2);
    }

    base::StringToUint(app->args()[1], &command_port_);

    scoped_ptr<net::ServerSocket> server_socket(
        new net::TCPServerSocket(NULL, net::NetLog::Source()));
    int result = server_socket->ListenWithAddressAndPort("0.0.0.0", command_port_, 1);
    if (result != net::OK) {
      // FIXME: Should we quit here?
      LOG(ERROR) << "Failed to bind to port " << command_port_
                 << " skydb commands will not work, exiting.";
      exit(2);
      return;
    }
    web_server_.reset(new net::HttpServer(server_socket.Pass(), this));
  }

  virtual bool ConfigureIncomingConnection(
      mojo::ApplicationConnection* connection) override {
    connection->ConnectToService(&debugger_);
    return true;
  }

  // net::HttpServer::Delegate
  void OnConnect(int connection_id) override {
  }

  void OnClose(int connection_id) override {
  }

  void OnHttpRequest(
      int connection_id, const net::HttpServerRequestInfo& info) override {

    // FIXME: We should use use a fancier lookup system more like what
    // services/http_server/http_server.cc does with AddHandler.
    if (info.path == "/trace")
      ToggleTracing(connection_id);
    else if (info.path == "/reload")
      Load(connection_id, url_);
    else if (info.path == "/inspect")
      Inspect(connection_id);
    else if (info.path == "/quit")
      Quit(connection_id);
    else if (info.path == "/load")
      Load(connection_id, info.data);
    else if (info.path == "/start_profiling")
      StartProfiling(connection_id);
    else if (info.path == "/stop_profiling")
      StopProfiling(connection_id);
    else {
      Help(info.path, connection_id);
    }
  }

  void OnWebSocketRequest(
      int connection_id, const net::HttpServerRequestInfo& info) override {
    web_server_->Send500(connection_id, "http only");
  }

  void OnWebSocketMessage(
      int connection_id, const std::string& data) override {
    web_server_->Send500(connection_id, "http only");
  }

  void Respond(int connection_id, std::string response) {
    // When sending tracing data back over the wire to the client, we can blow
    // through the default send buffer size.
    web_server_->SetSendBufferSize(
        connection_id, std::max(kMinSendBufferSize, response.length()));
    web_server_->Send200(connection_id, response, "text/plain");
  }

  void Help(std::string path, int connection_id) {
    std::string help = base::StringPrintf("Sky Debugger running on port %d\n"
        "Supported URLs:\n"
        "/toggle_tracing   -- Start/stop tracing\n"
        "/reload           -- Reload the current page\n"
        "/inspect          -- Start inspector server for current page\n"
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
    debugger_->NavigateToURL(url_);
  }

  void Inspect(int connection_id) {
    debugger_->InjectInspector();
    Respond(connection_id,
        "Open the following URL in Chrome:\n"
        "chrome-devtools://devtools/bundled/devtools.html?ws=localhost:9898\n");
  }

  void Quit(int connection_id) {
    debugger_->Shutdown();
  }

  void ToggleTracing(int connection_id) {
    bool was_tracing = is_tracing_;
    is_tracing_ = !is_tracing_;

    if (was_tracing) {
      tracing_->StopAndFlush();
      trace_collector_->GetTrace(base::Bind(
          &Prompt::OnTraceAvailable, base::Unretained(this), connection_id));
      return;
    }

    mojo::DataPipe pipe;
    tracing_->Start(pipe.producer_handle.Pass(), mojo::String("*"));
    trace_collector_.reset(new TraceCollector(pipe.consumer_handle.Pass()));
    Respond(connection_id, "Starting trace (type 'trace' to stop tracing)\n");
  }

  void OnTraceAvailable(int connection_id, std::string trace) {
    trace_collector_.reset();
    Respond(connection_id, trace);
  }

  void StartProfiling(int connection_id) {
    base::debug::StartProfiling("sky_viewer.pprof");
    Respond(connection_id, "Starting profiling (type 'stop_profiling' to stop");
  }

  void StopProfiling(int connection_id) {
    base::debug::StopProfiling();
    Respond(connection_id, "Stopped profiling");
  }

  bool is_tracing_;
  DebuggerPtr debugger_;
  tracing::TraceCoordinatorPtr tracing_;
  std::string url_;
  base::WeakPtrFactory<Prompt> weak_ptr_factory_;
  scoped_ptr<net::HttpServer> web_server_;
  uint32_t command_port_;

  scoped_ptr<TraceCollector> trace_collector_;

  DISALLOW_COPY_AND_ASSIGN(Prompt);
};

}  // namespace debugger
}  // namespace sky

MojoResult MojoMain(MojoHandle shell_handle) {
  mojo::ApplicationRunnerChromium runner(new sky::debugger::Prompt);
  runner.set_message_loop_type(base::MessageLoop::TYPE_IO);
  return runner.Run(shell_handle);
}
