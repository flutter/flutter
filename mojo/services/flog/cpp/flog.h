// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_SERVICES_FLOG_CPP_FLOG_H_
#define MOJO_SERVICES_FLOG_CPP_FLOG_H_

#include <atomic>
#include <memory>

#include "mojo/public/c/environment/logger.h"
#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/cpp/bindings/array.h"
#include "mojo/public/cpp/bindings/message.h"
#include "mojo/public/cpp/environment/logging.h"
#include "mojo/public/cpp/system/time.h"
#include "mojo/services/flog/interfaces/flog.mojom.h"

namespace mojo {
namespace flog {

//
// FORMATTED LOGGING
//
// The Flog class and associated macros provide a means of logging 'formatted'
// log messages serialized by Mojo. Flog uses an instance of FlogLogger to
// log events to the FlogService. Messages pulled from the FlogService can be
// deserialized using Mojo on behalf of log visualization and analysis tools.
//
// Message logging is performed using a 'channel', which is bound to a Mojo
// proxy for a particular interface. Mojo interfaces used for this purpose must
// be request-only, meaning the constituent methods must not have responses.
//
// Assume that we've defined the following interface:
//
//     [ServiceName="my_namespace::MyFlogChannelInterface"]
//     interface MyFlogChannelInterface {
//       Thing1(int64 a, int32 b);
//       Thing2(string c);
//     };
//
// Note that the ServiceName annotation is required.
//
// A channel instance may be defined as a member of a class as follows:
//
//     FLOG_INSTANCE_CHANNEL(MyFlogChannelInterface, my_flog_channel_);
//
// For cases in which the channel isn't a class instance member, the
// FLOG_CHANNEL macro is provided:
//
//     FLOG_CHANNEL(MyFlogChannelInterface, g_my_flog_channel);
//
// If NDEBUG is defined, these compile to nothing. Otherwise, they declare and
// initialize my_flog_channel_instance (or g_my_flog_channel), which can be used
// via the FLOG macro:
//
//     FLOG(my_flog_channel_, Thing1(1234, 5678));
//     FLOG(my_flog_channel_, Thing2("To the lifeboats!"));
//
// These invocations compile to nothing if NDEBUG is defined. Otherwise, they
// log messages to the channel represented by my_flog_channel_instance.
//
// FLOG_CHANNEL_DECL produces only a declaration for cases in which a channel
// must be declared but not defined (e.g. as a static class member).
//
// Logging to a channel does nothing unless the Flog class has been initialized
// with a call to Flog::Initialize (via the FLOG_INITIALIZE macro).
// Flog::Initialize provides a FlogLogger implementation to be used for logging.
// Typically, this implementation would be acquired from the FlogService using
// CreateLogger.
//

// Converts a pointer to a uint64_t for channel messages that have address
// parameters. Addresses can't be accessed by log consumers, but they can be
// used for identification.
#define FLOG_ADDRESS(p) reinterpret_cast<uintptr_t>(p)

#if !defined(NDEBUG)

// Initializes flog, connecting to the service and creating a new log. |shell|
// is the application's shell (for connecting to the service), and |label| is
// the log label, usually the name of the service or application. Should be
// called once on startup, usually in the OnInitialize override of the
// ApplicationImplBase subclass.
#define FLOG_INITIALIZE(shell, label) mojo::flog::Flog::Initialize(shell, label)

// Destroys the resources created by FLOG_INITIALIZE. Should be called once on
// shutdown, usually in the destructor of the ApplicationImplBase subclass.
#define FLOG_DESTROY() mojo::flog::Flog::Destroy()

// Declares a flog channel but does not initialize it. This is useful when the
// declaration and definition must be separate.
#define FLOG_CHANNEL_DECL(channel_type, channel_name) \
  std::unique_ptr<mojo::flog::FlogProxy<channel_type>> channel_name

// Defines a variable with the indicated name (|channel_name|) and the indicated
// type (|channel_type|, which must be a mojo interface type). |subject_address|
// is provided to associate an address with the channel. Use FLOG_CHANNEL or
// FLOG_INSTANCE_CHANNEL instead of this macro unless there is a need to be
// specific about the subject. A |subject_address| value of 0 indicates there
// is no subject address for the channel.
#define FLOG_CHANNEL_WITH_SUBJECT(channel_type, channel_name, subject_address) \
  FLOG_CHANNEL_DECL(channel_type, channel_name) =                              \
      mojo::flog::FlogProxy<channel_type>::Create(subject_address)

// Logs a channel message on the specified channel (a name previously declared
// using FLOG_CHANNEL, FLOG_INSTANCE_CHANNEL, FLOG_CHANNEL_WITH_SUBJECT or
// FLOG_CHANNEL_DECL). |call| is a valid method call for the channel type. See
// the example above.
#define FLOG(channel_name, call) channel_name->call

// Gets the numeric channel id from a channel.
#define FLOG_ID(channel_name) channel_name->flog_channel()->id()

#else

#define FLOG_INITIALIZE(shell, label) ((void)0)
#define FLOG_DESTROY() ((void)0)
#define FLOG_CHANNEL_DECL(channel_type, channel_name)
#define FLOG_CHANNEL_WITH_SUBJECT(channel_type, channel_name, subject)
#define FLOG(channel_name, call) ((void)0)
#define FLOG_ID(channel_name) 0

#endif

// Same as FLOG_CHANNEL_WITH_SUBJECT but supplies the address of |this| as
// the subject address. This is the preferred form for declaring channels that
// are instance members.
#define FLOG_INSTANCE_CHANNEL(channel_type, channel_name) \
  FLOG_CHANNEL_WITH_SUBJECT(channel_type, channel_name, FLOG_ADDRESS(this))

// Same as FLOG_CHANNEL_WITH_SUBJECT but supplies a null subject address.
#define FLOG_CHANNEL(channel_type, channel_name) \
  FLOG_CHANNEL_WITH_SUBJECT(channel_type, channel_name, 0)

// Thread-safe logger for all channels in a given process.
class Flog {
 public:
  static void Initialize(Shell* shell, const std::string& label);

  // Deletes the flog logger singleton.
  static void Destroy() {
    MOJO_DCHECK(logger_);
    logger_.reset();
  }

  // Allocates a unique id for a new channel. Never returns 0.
  static uint32_t AllocateChannelId() { return ++last_allocated_channel_id_; }

  // Logs the creation of a channel.
  static void LogChannelCreation(uint32_t channel_id,
                                 const char* channel_type_name,
                                 uint64_t subject_address);

  // Logs a channel message.
  static void LogChannelMessage(uint32_t channel_id, Message* message);

  // Logs the deletion of a channel.
  static void LogChannelDeletion(uint32_t channel_id);

  // TODO(dalesat): Add method for text/file/line

 private:
  static const MojoLogger kMojoLogger;

  // Logs a message string for MojoLogger support.
  static void LogMojoLoggerMessage(MojoLogLevel log_level,
                                   const char* source_file,
                                   uint32_t source_line,
                                   const char* message);

  // Gets the minimum MojoLogLevel for MojoLogger support.
  static MojoLogLevel GetMinimumMojoLogLevel();

  // Sets the minimum MojoLogLevel for MojoLogger support.
  static void SetMinimumMojoLogLevel(MojoLogLevel level);

  // Gets the current time in microseconds since epoch.
  static uint64_t GetTime();

  static std::atomic_ulong last_allocated_channel_id_;
  static FlogLoggerPtr logger_;
  static const MojoLogger* fallback_logger_;
};

// Channel backing a FlogProxy.
class FlogChannel : public MessageReceiverWithResponder {
 public:
  FlogChannel(const char* channel_type_name, uint64_t subject_address);

  ~FlogChannel() override;

  // Returns the channel id.
  uint32_t id() const { return id_; }

  // MessageReceiverWithResponder implementation.
  bool Accept(Message* message) override;

  bool AcceptWithResponder(Message* message,
                           MessageReceiver* responder) override;

 private:
  uint32_t id_ = 0;
};

template <typename T>
class FlogProxy : public T::Proxy_ {
 public:
  static std::unique_ptr<FlogProxy<T>> Create(uint64_t subject_address) {
    return std::unique_ptr<FlogProxy<T>>(new FlogProxy<T>(subject_address));
  }

  FlogChannel* flog_channel() {
    return reinterpret_cast<FlogChannel*>(this->receiver_);
  }

 private:
  explicit FlogProxy(uint64_t subject_address)
      : T::Proxy_(new FlogChannel(T::Name_, subject_address)) {}
};

}  // namespace flog
}  // namespace mojo

#endif  // MOJO_SERVICES_FLOG_CPP_FLOG_H_
