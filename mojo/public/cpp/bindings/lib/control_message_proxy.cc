// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/bindings/lib/control_message_proxy.h"

#include "mojo/public/cpp/bindings/lib/message_builder.h"
#include "mojo/public/cpp/bindings/message.h"
#include "mojo/public/cpp/system/macros.h"
#include "mojo/public/interfaces/bindings/interface_control_messages.mojom.h"

namespace mojo {
namespace internal {

namespace {

using RunCallback = Callback<void(QueryVersionResultPtr)>;

class RunResponseForwardToCallback : public MessageReceiver {
 public:
  RunResponseForwardToCallback(const RunCallback& callback)
      : callback_(callback) {}
  bool Accept(Message* message) override;

 private:
  RunCallback callback_;
  MOJO_DISALLOW_COPY_AND_ASSIGN(RunResponseForwardToCallback);
};

bool RunResponseForwardToCallback::Accept(Message* message) {
  RunResponseMessageParams_Data* params =
      reinterpret_cast<RunResponseMessageParams_Data*>(
          message->mutable_payload());
  params->DecodePointersAndHandles(message->mutable_handles());

  RunResponseMessageParamsPtr params_ptr;
  Deserialize_(params, &params_ptr);

  callback_.Run(params_ptr->query_version_result.Pass());
  return true;
}

void SendRunMessage(MessageReceiverWithResponder* receiver,
                    QueryVersionPtr query_version,
                    const RunCallback& callback) {
  RunMessageParamsPtr params_ptr(RunMessageParams::New());
  params_ptr->reserved0 = 16u;
  params_ptr->reserved1 = 0u;
  params_ptr->query_version = query_version.Pass();

  size_t size = GetSerializedSize_(params_ptr);
  RequestMessageBuilder builder(kRunMessageId, size);

  RunMessageParams_Data* params = nullptr;
  Serialize_(params_ptr.Pass(), builder.buffer(), &params);
  Message message;
  params->EncodePointersAndHandles(message.mutable_handles());
  builder.Finish(&message);
  MessageReceiver* responder = new RunResponseForwardToCallback(callback);
  if (!receiver->AcceptWithResponder(&message, responder))
    delete responder;
}

void SendRunOrClosePipeMessage(MessageReceiverWithResponder* receiver,
                               RequireVersionPtr require_version) {
  RunOrClosePipeMessageParamsPtr params_ptr(RunOrClosePipeMessageParams::New());
  params_ptr->reserved0 = 16u;
  params_ptr->reserved1 = 0u;
  params_ptr->require_version = require_version.Pass();

  size_t size = GetSerializedSize_(params_ptr);
  MessageBuilder builder(kRunOrClosePipeMessageId, size);

  RunOrClosePipeMessageParams_Data* params = nullptr;
  Serialize_(params_ptr.Pass(), builder.buffer(), &params);
  Message message;
  params->EncodePointersAndHandles(message.mutable_handles());
  builder.Finish(&message);
  bool ok = receiver->Accept(&message);
  MOJO_ALLOW_UNUSED_LOCAL(ok);
}

}  // namespace

ControlMessageProxy::ControlMessageProxy(MessageReceiverWithResponder* receiver)
    : receiver_(receiver) {
}

void ControlMessageProxy::QueryVersion(
    const Callback<void(uint32_t)>& callback) {
  auto run_callback = [callback](QueryVersionResultPtr query_version_result) {
    callback.Run(query_version_result->version);
  };
  SendRunMessage(receiver_, QueryVersion::New(), run_callback);
}

void ControlMessageProxy::RequireVersion(uint32_t version) {
  RequireVersionPtr require_version(RequireVersion::New());
  require_version->version = version;
  SendRunOrClosePipeMessage(receiver_, require_version.Pass());
}

}  // namespace internal
}  // namespace mojo
