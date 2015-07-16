// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/bindings/lib/control_message_handler.h"

#include "mojo/public/cpp/bindings/lib/message_builder.h"
#include "mojo/public/cpp/environment/logging.h"
#include "mojo/public/interfaces/bindings/interface_control_messages.mojom.h"

namespace mojo {
namespace internal {

// static
bool ControlMessageHandler::IsControlMessage(const Message* message) {
  return message->header()->name == kRunMessageId ||
         message->header()->name == kRunOrClosePipeMessageId;
}

ControlMessageHandler::ControlMessageHandler(uint32_t interface_version)
    : interface_version_(interface_version) {
}

ControlMessageHandler::~ControlMessageHandler() {
}

bool ControlMessageHandler::Accept(Message* message) {
  if (message->header()->name == kRunOrClosePipeMessageId)
    return RunOrClosePipe(message);

  MOJO_NOTREACHED();
  return false;
}

bool ControlMessageHandler::AcceptWithResponder(
    Message* message,
    MessageReceiverWithStatus* responder) {
  if (message->header()->name == kRunMessageId)
    return Run(message, responder);

  MOJO_NOTREACHED();
  return false;
}

bool ControlMessageHandler::Run(Message* message,
                                MessageReceiverWithStatus* responder) {
  RunResponseMessageParamsPtr response_params_ptr(
      RunResponseMessageParams::New());
  response_params_ptr->reserved0 = 16u;
  response_params_ptr->reserved1 = 0u;
  response_params_ptr->query_version_result = QueryVersionResult::New();
  response_params_ptr->query_version_result->version = interface_version_;

  size_t size = GetSerializedSize_(response_params_ptr);
  ResponseMessageBuilder builder(kRunMessageId, size, message->request_id());

  RunResponseMessageParams_Data* response_params = nullptr;
  Serialize_(response_params_ptr.Pass(), builder.buffer(), &response_params);
  Message response_message;
  response_params->EncodePointersAndHandles(response_message.mutable_handles());
  builder.Finish(&response_message);
  bool ok = responder->Accept(&response_message);
  MOJO_ALLOW_UNUSED_LOCAL(ok);
  delete responder;

  return true;
}

bool ControlMessageHandler::RunOrClosePipe(Message* message) {
  RunOrClosePipeMessageParams_Data* params =
      reinterpret_cast<RunOrClosePipeMessageParams_Data*>(
          message->mutable_payload());
  params->DecodePointersAndHandles(message->mutable_handles());

  RunOrClosePipeMessageParamsPtr params_ptr;
  Deserialize_(params, &params_ptr);

  return interface_version_ >= params_ptr->require_version->version;
}

}  // namespace internal
}  // namespace mojo
