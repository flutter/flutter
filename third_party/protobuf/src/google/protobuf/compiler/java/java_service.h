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

#ifndef GOOGLE_PROTOBUF_COMPILER_JAVA_SERVICE_H__
#define GOOGLE_PROTOBUF_COMPILER_JAVA_SERVICE_H__

#include <map>
#include <google/protobuf/descriptor.h>

namespace google {
namespace protobuf {
  namespace io {
    class Printer;             // printer.h
  }
}

namespace protobuf {
namespace compiler {
namespace java {

class ServiceGenerator {
 public:
  explicit ServiceGenerator(const ServiceDescriptor* descriptor);
  ~ServiceGenerator();

  void Generate(io::Printer* printer);

 private:

  // Generate the getDescriptorForType() method.
  void GenerateGetDescriptorForType(io::Printer* printer);

  // Generate a Java interface for the service.
  void GenerateInterface(io::Printer* printer);

  // Generate newReflectiveService() method.
  void GenerateNewReflectiveServiceMethod(io::Printer* printer);

  // Generate newReflectiveBlockingService() method.
  void GenerateNewReflectiveBlockingServiceMethod(io::Printer* printer);

  // Generate abstract method declarations for all methods.
  void GenerateAbstractMethods(io::Printer* printer);

  // Generate the implementation of Service.callMethod().
  void GenerateCallMethod(io::Printer* printer);

  // Generate the implementation of BlockingService.callBlockingMethod().
  void GenerateCallBlockingMethod(io::Printer* printer);

  // Generate the implementations of Service.get{Request,Response}Prototype().
  enum RequestOrResponse { REQUEST, RESPONSE };
  void GenerateGetPrototype(RequestOrResponse which, io::Printer* printer);

  // Generate a stub implementation of the service.
  void GenerateStub(io::Printer* printer);

  // Generate a method signature, possibly abstract, without body or trailing
  // semicolon.
  enum IsAbstract { IS_ABSTRACT, IS_CONCRETE };
  void GenerateMethodSignature(io::Printer* printer,
                               const MethodDescriptor* method,
                               IsAbstract is_abstract);

  // Generate a blocking stub interface and implementation of the service.
  void GenerateBlockingStub(io::Printer* printer);

  // Generate the method signature for one method of a blocking stub.
  void GenerateBlockingMethodSignature(io::Printer* printer,
                                       const MethodDescriptor* method);

  const ServiceDescriptor* descriptor_;

  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(ServiceGenerator);
};

}  // namespace java
}  // namespace compiler
}  // namespace protobuf

#endif  // NET_PROTO2_COMPILER_JAVA_SERVICE_H__
}  // namespace google
