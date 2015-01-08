// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/bind.h"
#include "base/memory/weak_ptr.h"
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

namespace sky {
namespace debugger {

class Prompt : public mojo::ApplicationDelegate, public net::HttpServer::Delegate {
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
    if (app->args().size() > 1)
      url_ = app->args()[1];
    else {
      url_ = "https://raw.githubusercontent.com/domokit/mojo/master/sky/"
          "examples/home.sky";
    }
    scoped_ptr<net::ServerSocket> server_socket(
        new net::TCPServerSocket(NULL, net::NetLog::Source()));
    // FIXME: This port needs to be configurable, as-is we can only run
    // one copy of mojo_shell with sky at a time!
    uint16 port = 7777;
    int result = server_socket->ListenWithAddressAndPort("0.0.0.0", port, 1);
    if (result != net::OK) {
      // FIXME: Should we quit here?
      LOG(ERROR) << "Failed to bind to port " << port
                 << " skydb commands will not work, exiting.";
      exit(2);
      return;
    }
    web_server_.reset(new net::HttpServer(server_socket.Pass(), this));
  }

  virtual bool ConfigureIncomingConnection(
      mojo::ApplicationConnection* connection) override {
    connection->ConnectToService(&debugger_);
    Reload();
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
    web_server_->Send200(connection_id, response, "text/plain");
  }

  void Help(std::string path, int connection_id) {
    std::string help = "Sky Debugger\n"
        "Supported URLs:\n"
        "/toggle_tracing   -- Start/stop tracing\n"
        "/reload           -- Reload the current page\n"
        "/inspect          -- Start inspector server for current page\n"
        "/quit             -- Quit\n"
        "/load             -- Load a new URL, url in POST body.\n";
    if (path != "/")
      help = "Unknown path: " + path + "\n\n" + help;
    Respond(connection_id, help);
  }

  void Load(int connection_id, std::string url) {
    url_ = url;
    Reload();
    Respond(connection_id, "OK\n");
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
    std::string response;
    if (is_tracing_) {
      response = "Stopping trace (writing to sky_viewer.trace)\n";
      tracing_->StopAndFlush();
    } else {
      response = "Starting trace (type 'trace' to stop tracing)\n";
      tracing_->Start(mojo::String("sky_viewer"), mojo::String("*"));
    }
    is_tracing_ = !is_tracing_;
    Respond(connection_id, response);
  }

  bool is_tracing_;
  DebuggerPtr debugger_;
  tracing::TraceCoordinatorPtr tracing_;
  std::string url_;
  base::WeakPtrFactory<Prompt> weak_ptr_factory_;
  scoped_ptr<net::HttpServer> web_server_;

  DISALLOW_COPY_AND_ASSIGN(Prompt);
};

}  // namespace debugger
}  // namespace sky

MojoResult MojoMain(MojoHandle shell_handle) {
  mojo::ApplicationRunnerChromium runner(new sky::debugger::Prompt);
  runner.set_message_loop_type(base::MessageLoop::TYPE_IO);
  return runner.Run(shell_handle);
}
