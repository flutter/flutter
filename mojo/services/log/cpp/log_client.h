// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This is a client library that constructs a MojoLogger that can talk to a
// Mojo logging service (see ../interfaces/log.mojo). It provides a |MojoLogger|
// implementation which can be used as the default environment logger.
//
// Example application that uses this log client to talk to the log service:
//
//  class MyDelegate : public mojo::ApplicationDelegate {
//   public:
//    void Initialize(mojo::ApplicationImpl* app) override {
//      LogPtr log;
//      app->ConnectToService("mojo:log", &log);
//      mojo::log::InitializeLogger(std::move(log),
//                                  ApplicationRunner::GetDefaultLogger());
//      mojo::ApplicationRunner::SetDefaultLogger(mojo::log::GetLogger());
//    }
//
//    void Quit() {
//      mojo::log::DestroyLogger();
//    }
//  };
//
//  MojoResult MojoMain(MojoHandle app_request) {
//    mojo::ApplicationRunner runner(new MyDelegate);
//    return runner.Run(app_request);
//  }

#ifndef MOJO_SERVICES_LOG_CPP_LOG_CLIENT_H_
#define MOJO_SERVICES_LOG_CPP_LOG_CLIENT_H_

#include "mojo/public/c/environment/logger.h"
#include "mojo/services/log/interfaces/log.mojom.h"

namespace mojo {
namespace log {

// Constructs a MojoLogger (which can be retrieved with |GetLogger()|) that
// talks to the provided log service. |fallback_logger| must be non-null and
// will be used if the provided |log_service| fails. The constructed MojoLogger
// may also call into |fallback_logger|'s [Set|Get]MinimumLogLevel functions to
// keep the minimum levels consistent.
void InitializeLogger(LogPtr log_service, const MojoLogger* fallback_logger);

// Must be called after |InitializeLogger()| and before |DestroyLogger()|. The
// returned MojoLogger is thread-safe.
const MojoLogger* GetLogger();

void DestroyLogger();

}  // namespace log
}  // namespace mojo

#endif  // MOJO_SERVICES_LOG_CPP_LOG_CLIENT_H_
