// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <chrono>

#include "mojo/public/cpp/application/connect.h"
#include "mojo/services/flog/cpp/flog.h"

namespace mojo {
namespace flog {

// static
void Flog::Initialize(Shell* shell, const std::string& label) {
  MOJO_DCHECK(!logger_);

  FlogServicePtr flog_service;
  ConnectToService(shell, "mojo:flog", GetProxy(&flog_service));
  // TODO(dalesat): Need a thread-safe proxy.

  FlogLoggerPtr flog_logger;
  flog_service->CreateLogger(GetProxy(&flog_logger), label);
  logger_ = flog_logger.Pass();

  fallback_logger_ = Environment::GetDefaultLogger();
  Environment::SetDefaultLogger(&kMojoLogger);
}

// static
void Flog::LogChannelCreation(uint32_t channel_id,
                              const char* channel_type_name,
                              uint64_t subject_address) {
  if (!logger_) {
    return;
  }

  logger_->LogChannelCreation(GetTime(), channel_id, channel_type_name,
                              subject_address);
}

// static
void Flog::LogChannelMessage(uint32_t channel_id, Message* message) {
  if (!logger_) {
    return;
  }

  Array<uint8_t> array = Array<uint8_t>::New(message->data_num_bytes());
  memcpy(array.data(), message->data(), message->data_num_bytes());
  logger_->LogChannelMessage(GetTime(), channel_id, array.Pass());
}

// static
void Flog::LogChannelDeletion(uint32_t channel_id) {
  if (!logger_) {
    return;
  }

  logger_->LogChannelDeletion(GetTime(), channel_id);
}

// static
void Flog::LogMojoLoggerMessage(MojoLogLevel log_level,
                                const char* source_file,
                                uint32_t source_line,
                                const char* message) {
  if (!logger_ || log_level < GetMinimumMojoLogLevel()) {
    return;
  }

  logger_->LogMojoLoggerMessage(GetTime(), log_level, message, source_file,
                                source_line);

  if (log_level >= MOJO_LOG_LEVEL_FATAL) {
    abort();
  }
}

// static
MojoLogLevel Flog::GetMinimumMojoLogLevel() {
  MOJO_DCHECK(fallback_logger_ != nullptr);
  return fallback_logger_->GetMinimumLogLevel();
}

// static
void Flog::SetMinimumMojoLogLevel(MojoLogLevel level) {
  MOJO_DCHECK(fallback_logger_ != nullptr);
  fallback_logger_->SetMinimumLogLevel(level);
}

// static
uint64_t Flog::GetTime() {
  return std::chrono::duration_cast<std::chrono::microseconds>(
             std::chrono::system_clock::now().time_since_epoch())
      .count();
}

// static
const MojoLogger Flog::kMojoLogger = {
    &LogMojoLoggerMessage, &GetMinimumMojoLogLevel, &SetMinimumMojoLogLevel};

// static
std::atomic_ulong Flog::last_allocated_channel_id_;

// static
FlogLoggerPtr Flog::logger_;

// static
const MojoLogger* Flog::fallback_logger_;

FlogChannel::FlogChannel(const char* channel_type_name,
                         uint64_t subject_address)
    : id_(Flog::AllocateChannelId()) {
  Flog::LogChannelCreation(id_, channel_type_name, subject_address);
}

FlogChannel::~FlogChannel() {
  Flog::LogChannelDeletion(id_);
}

bool FlogChannel::Accept(Message* message) {
  Flog::LogChannelMessage(id_, message);
  return true;
}

bool FlogChannel::AcceptWithResponder(Message* message,
                                      MessageReceiver* responder) {
  MOJO_DCHECK(false) << "Flog doesn't support messages with responses";
  abort();
}

}  // namespace flog
}  // namespace mojo
