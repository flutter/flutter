// Protocol Buffers - Google's data interchange format
// Copyright 2008 Google Inc.  All rights reserved.
// http://code.google.com/p/protobuf/
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// Author: kenton@google.com (Kenton Varda)
//  Based on original Protocol Buffers design by
//  Sanjay Ghemawat, Jeff Dean, and others.
//
// DEPRECATED:  This module declares the abstract interfaces underlying proto2
// RPC services.  These are intented to be independent of any particular RPC
// implementation, so that proto2 services can be used on top of a variety
// of implementations.  Starting with version 2.3.0, RPC implementations should
// not try to build on these, but should instead provide code generator plugins
// which generate code specific to the particular RPC implementation.  This way
// the generated code can be more appropriate for the implementation in use
// and can avoid unnecessary layers of indirection.
//
//
// When you use the protocol compiler to compile a service definition, it
// generates two classes:  An abstract interface for the service (with
// methods matching the service definition) and a "stub" implementation.
// A stub is just a type-safe wrapper around an RpcChannel which emulates a
// local implementation of the service.
//
// For example, the service definition:
//   service MyService {
//     rpc Foo(MyRequest) returns(MyResponse);
//   }
// will generate abstract interface "MyService" and class "MyService::Stub".
// You could implement a MyService as follows:
//   class MyServiceImpl : public MyService {
//    public:
//     MyServiceImpl() {}
//     ~MyServiceImpl() {}
//
//     // implements MyService ---------------------------------------
//
//     void Foo(google::protobuf::RpcController* controller,
//              const MyRequest* request,
//              MyResponse* response,
//              Closure* done) {
//       // ... read request and fill in response ...
//       done->Run();
//     }
//   };
// You would then register an instance of MyServiceImpl with your RPC server
// implementation.  (How to do that depends on the implementation.)
//
// To call a remote MyServiceImpl, first you need an RpcChannel connected to it.
// How to construct a channel depends, again, on your RPC implementation.
// Here we use a hypothentical "MyRpcChannel" as an example:
//   MyRpcChannel channel("rpc:hostname:1234/myservice");
//   MyRpcController controller;
//   MyServiceImpl::Stub stub(&channel);
//   FooRequest request;
//   FooRespnose response;
//
//   // ... fill in request ...
//
//   stub.Foo(&controller, request, &response, NewCallback(HandleResponse));
//
// On Thread-Safety:
//
// Different RPC implementations may make different guarantees about what
// threads they may run callbacks on, and what threads the application is
// allowed to use to call the RPC system.  Portable software should be ready
// for callbacks to be called on any thread, but should not try to call the
// RPC system from any thread except for the ones on which it received the
// callbacks.  Realistically, though, simple software will probably want to
// use a single-threaded RPC system while high-end software will want to
// use multiple threads.  RPC implementations should provide multiple
// choices.

#ifndef GOOGLE_PROTOBUF_SERVICE_H__
#define GOOGLE_PROTOBUF_SERVICE_H__

#include <string>
#include <google/protobuf/stubs/common.h>

namespace google {
namespace protobuf {

// Defined in this file.
class Service;
class RpcController;
class RpcChannel;

// Defined in other files.
class Descriptor;            // descriptor.h
class ServiceDescriptor;     // descriptor.h
class MethodDescriptor;      // descriptor.h
class Message;               // message.h

// Abstract base interface for protocol-buffer-based RPC services.  Services
// themselves are abstract interfaces (implemented either by servers or as
// stubs), but they subclass this base interface.  The methods of this
// interface can be used to call the methods of the Service without knowing
// its exact type at compile time (analogous to Reflection).
class LIBPROTOBUF_EXPORT Service {
 public:
  inline Service() {}
  virtual ~Service();

  // When constructing a stub, you may pass STUB_OWNS_CHANNEL as the second
  // parameter to the constructor to tell it to delete its RpcChannel when
  // destroyed.
  enum ChannelOwnership {
    STUB_OWNS_CHANNEL,
    STUB_DOESNT_OWN_CHANNEL
  };

  // Get the ServiceDescriptor describing this service and its methods.
  virtual const ServiceDescriptor* GetDescriptor() = 0;

  // Call a method of the service specified by MethodDescriptor.  This is
  // normally implemented as a simple switch() that calls the standard
  // definitions of the service's methods.
  //
  // Preconditions:
  // * method->service() == GetDescriptor()
  // * request and response are of the exact same classes as the objects
  //   returned by GetRequestPrototype(method) and
  //   GetResponsePrototype(method).
  // * After the call has started, the request must not be modified and the
  //   response must not be accessed at all until "done" is called.
  // * "controller" is of the correct type for the RPC implementation being
  //   used by this Service.  For stubs, the "correct type" depends on the
  //   RpcChannel which the stub is using.  Server-side Service
  //   implementations are expected to accept whatever type of RpcController
  //   the server-side RPC implementation uses.
  //
  // Postconditions:
  // * "done" will be called when the method is complete.  This may be
  //   before CallMethod() returns or it may be at some point in the future.
  // * If the RPC succeeded, "response" contains the response returned by
  //   the server.
  // * If the RPC failed, "response"'s contents are undefined.  The
  //   RpcController can be queried to determine if an error occurred and
  //   possibly to get more information about the error.
  virtual void CallMethod(const MethodDescriptor* method,
                          RpcController* controller,
                          const Message* request,
                          Message* response,
                          Closure* done) = 0;

  // CallMethod() requires that the request and response passed in are of a
  // particular subclass of Message.  GetRequestPrototype() and
  // GetResponsePrototype() get the default instances of these required types.
  // You can then call Message::New() on these instances to construct mutable
  // objects which you can then pass to CallMethod().
  //
  // Example:
  //   const MethodDescriptor* method =
  //     service->GetDescriptor()->FindMethodByName("Foo");
  //   Message* request  = stub->GetRequestPrototype (method)->New();
  //   Message* response = stub->GetResponsePrototype(method)->New();
  //   request->ParseFromString(input);
  //   service->CallMethod(method, *request, response, callback);
  virtual const Message& GetRequestPrototype(
    const MethodDescriptor* method) const = 0;
  virtual const Message& GetResponsePrototype(
    const MethodDescriptor* method) const = 0;

 private:
  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(Service);
};

// An RpcController mediates a single method call.  The primary purpose of
// the controller is to provide a way to manipulate settings specific to the
// RPC implementation and to find out about RPC-level errors.
//
// The methods provided by the RpcController interface are intended to be a
// "least common denominator" set of features which we expect all
// implementations to support.  Specific implementations may provide more
// advanced features (e.g. deadline propagation).
class LIBPROTOBUF_EXPORT RpcController {
 public:
  inline RpcController() {}
  virtual ~RpcController();

  // Client-side methods ---------------------------------------------
  // These calls may be made from the client side only.  Their results
  // are undefined on the server side (may crash).

  // Resets the RpcController to its initial state so that it may be reused in
  // a new call.  Must not be called while an RPC is in progress.
  virtual void Reset() = 0;

  // After a call has finished, returns true if the call failed.  The possible
  // reasons for failure depend on the RPC implementation.  Failed() must not
  // be called before a call has finished.  If Failed() returns true, the
  // contents of the response message are undefined.
  virtual bool Failed() const = 0;

  // If Failed() is true, returns a human-readable description of the error.
  virtual string ErrorText() const = 0;

  // Advises the RPC system that the caller desires that the RPC call be
  // canceled.  The RPC system may cancel it immediately, may wait awhile and
  // then cancel it, or may not even cancel the call at all.  If the call is
  // canceled, the "done" callback will still be called and the RpcController
  // will indicate that the call failed at that time.
  virtual void StartCancel() = 0;

  // Server-side methods ---------------------------------------------
  // These calls may be made from the server side only.  Their results
  // are undefined on the client side (may crash).

  // Causes Failed() to return true on the client side.  "reason" will be
  // incorporated into the message returned by ErrorText().  If you find
  // you need to return machine-readable information about failures, you
  // should incorporate it into your response protocol buffer and should
  // NOT call SetFailed().
  virtual void SetFailed(const string& reason) = 0;

  // If true, indicates that the client canceled the RPC, so the server may
  // as well give up on replying to it.  The server should still call the
  // final "done" callback.
  virtual bool IsCanceled() const = 0;

  // Asks that the given callback be called when the RPC is canceled.  The
  // callback will always be called exactly once.  If the RPC completes without
  // being canceled, the callback will be called after completion.  If the RPC
  // has already been canceled when NotifyOnCancel() is called, the callback
  // will be called immediately.
  //
  // NotifyOnCancel() must be called no more than once per request.
  virtual void NotifyOnCancel(Closure* callback) = 0;

 private:
  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(RpcController);
};

// Abstract interface for an RPC channel.  An RpcChannel represents a
// communication line to a Service which can be used to call that Service's
// methods.  The Service may be running on another machine.  Normally, you
// should not call an RpcChannel directly, but instead construct a stub Service
// wrapping it.  Example:
//   RpcChannel* channel = new MyRpcChannel("remotehost.example.com:1234");
//   MyService* service = new MyService::Stub(channel);
//   service->MyMethod(request, &response, callback);
class LIBPROTOBUF_EXPORT RpcChannel {
 public:
  inline RpcChannel() {}
  virtual ~RpcChannel();

  // Call the given method of the remote service.  The signature of this
  // procedure looks the same as Service::CallMethod(), but the requirements
  // are less strict in one important way:  the request and response objects
  // need not be of any specific class as long as their descriptors are
  // method->input_type() and method->output_type().
  virtual void CallMethod(const MethodDescriptor* method,
                          RpcController* controller,
                          const Message* request,
                          Message* response,
                          Closure* done) = 0;

 private:
  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(RpcChannel);
};

}  // namespace protobuf

}  // namespace google
#endif  // GOOGLE_PROTOBUF_SERVICE_H__
