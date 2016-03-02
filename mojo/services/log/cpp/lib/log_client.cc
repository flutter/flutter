// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/services/log/cpp/log_client.h"

#include <assert.h>

#include <string>
#include <utility>

#include "mojo/public/c/environment/logger.h"
#include "mojo/public/cpp/bindings/interface_handle.h"
#include "mojo/public/cpp/bindings/lib/message_builder.h"
#include "mojo/public/cpp/system/macros.h"
#include "mojo/public/cpp/system/message_pipe.h"
#include "mojo/services/log/interfaces/entry.mojom.h"
#include "mojo/services/log/interfaces/log.mojom.h"

namespace mojo {
namespace {

class LogClient;

// Forward declare for constructing |g_logclient_logger|.
void LogMessage(MojoLogLevel log_level,
                const char* source_file,
                uint32_t source_line,
                const char* message);
MojoLogLevel GetMinimumLogLevel();
void SetMinimumLogLevel(MojoLogLevel level);

// This logger is what |GetLogger()| returns, and delegates all of its work to
// |g_logclient|.
const MojoLogger g_logclient_logger = {&LogMessage, &GetMinimumLogLevel,
                                       &SetMinimumLogLevel};
LogClient* g_log_client = nullptr;

class LogClient {
 public:
  LogClient(log::LogPtr log_service, const MojoLogger* fallback_logger);
  void LogMessage(MojoLogLevel log_level,
                  const char* source_file,
                  uint32_t source_line,
                  const char* message) const;

  MojoLogLevel GetMinimumLogLevel() const;
  void SetMinimumLogLevel(MojoLogLevel level);

 private:
  const InterfaceHandle<mojo::log::Log> log_interface_;
  const MojoLogger* const fallback_logger_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(LogClient);
};

LogClient::LogClient(log::LogPtr log, const MojoLogger* fallback_logger)
    : log_interface_(log.PassInterfaceHandle()),
      fallback_logger_(fallback_logger) {
  assert(log_interface_.is_valid());
  assert(fallback_logger_);
}

void LogClient::LogMessage(MojoLogLevel log_level,
                           const char* source_file,
                           uint32_t source_line,
                           const char* message) const {
  // We avoid the use of C++ bindings to do interface calls in order to be
  // thread-safe (as of this writing, the bindings are not).  Because the
  // AddEntry message of the Log interface does not have a response message, we
  // can fire-and-forget the message: construct the params for the call, frame
  // it inside a Message and write the Message to the message pipe connecting to
  // the log service.

  if (log_level < GetMinimumLogLevel())
    return;

  // TODO(vardhan):  Use synchronous interface bindings here.
  mojo::log::Log_AddEntry_Params request_params;
  request_params.entry = mojo::log::Entry::New();
  request_params.entry->timestamp = GetTimeTicksNow();
  request_params.entry->log_level = log_level;
  request_params.entry->source_file = source_file;
  request_params.entry->source_line = source_line;
  request_params.entry->message = message;

  size_t params_size = request_params.GetSerializedSize();
  MessageBuilder builder(
      static_cast<uint32_t>(mojo::log::Log::MessageOrdinals::AddEntry),
      params_size);

  request_params.Serialize(
      static_cast<void*>(builder.message()->mutable_payload()), params_size);

  auto result =
      WriteMessageRaw(log_interface_.handle().get(), builder.message()->data(),
                      builder.message()->data_num_bytes(), nullptr, 0,
                      MOJO_WRITE_MESSAGE_FLAG_NONE);
  switch (result) {
    case MOJO_RESULT_OK:
      break;

    // TODO(vardhan): Are any of these error cases recoverable (in which case
    // we shouldn't close our handle)?  Maybe MOJO_RESULT_RESOURCE_EXHAUSTED?
    case MOJO_RESULT_INVALID_ARGUMENT:
    case MOJO_RESULT_RESOURCE_EXHAUSTED:
    case MOJO_RESULT_FAILED_PRECONDITION:
    case MOJO_RESULT_UNIMPLEMENTED:
    case MOJO_RESULT_BUSY: {
      return fallback_logger_->LogMessage(log_level, source_file, source_line,
                                          message);
    }

    default:
      // Should not reach here.
      assert(false);
  }

  if (log_level >= MOJO_LOG_LEVEL_FATAL)
    abort();
}

MojoLogLevel LogClient::GetMinimumLogLevel() const {
  return fallback_logger_->GetMinimumLogLevel();
}

void LogClient::SetMinimumLogLevel(MojoLogLevel level) {
  assert(fallback_logger_);
  fallback_logger_->SetMinimumLogLevel(level);
}

void LogMessage(MojoLogLevel log_level,
                const char* source_file,
                uint32_t source_line,
                const char* message) {
  assert(g_log_client);
  g_log_client->LogMessage(log_level, source_file, source_line, message);
}

MojoLogLevel GetMinimumLogLevel() {
  assert(g_log_client);
  return g_log_client->GetMinimumLogLevel();
}

void SetMinimumLogLevel(MojoLogLevel level) {
  assert(g_log_client);
  g_log_client->SetMinimumLogLevel(level);
}

}  // namespace

namespace log {

void InitializeLogger(LogPtr log_service, const MojoLogger* fallback_logger) {
  assert(!g_log_client);
  g_log_client = new LogClient(std::move(log_service), fallback_logger);
}

const MojoLogger* GetLogger() {
  assert(g_log_client);
  return &g_logclient_logger;
}

void DestroyLogger() {
  assert(g_log_client);
  delete g_log_client;
  g_log_client = nullptr;
}

}  // namespace log
}  // namespace mojo
