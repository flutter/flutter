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

#ifndef GOOGLE_PROTOBUF_COMPILER_CPP_MESSAGE_H__
#define GOOGLE_PROTOBUF_COMPILER_CPP_MESSAGE_H__

#include <string>
#include <google/protobuf/stubs/common.h>
#include <google/protobuf/compiler/cpp/cpp_field.h>
#include <google/protobuf/compiler/cpp/cpp_options.h>

namespace google {
namespace protobuf {
  namespace io {
    class Printer;             // printer.h
  }
}

namespace protobuf {
namespace compiler {
namespace cpp {

class EnumGenerator;           // enum.h
class ExtensionGenerator;      // extension.h

class MessageGenerator {
 public:
  // See generator.cc for the meaning of dllexport_decl.
  explicit MessageGenerator(const Descriptor* descriptor,
                            const Options& options);
  ~MessageGenerator();

  // Header stuff.

  // Generate foward declarations for this class and all its nested types.
  void GenerateForwardDeclaration(io::Printer* printer);

  // Generate definitions of all nested enums (must come before class
  // definitions because those classes use the enums definitions).
  void GenerateEnumDefinitions(io::Printer* printer);

  // Generate specializations of GetEnumDescriptor<MyEnum>().
  // Precondition: in ::google::protobuf namespace.
  void GenerateGetEnumDescriptorSpecializations(io::Printer* printer);

  // Generate definitions for this class and all its nested types.
  void GenerateClassDefinition(io::Printer* printer);

  // Generate definitions of inline methods (placed at the end of the header
  // file).
  void GenerateInlineMethods(io::Printer* printer);

  // Source file stuff.

  // Generate code which declares all the global descriptor pointers which
  // will be initialized by the methods below.
  void GenerateDescriptorDeclarations(io::Printer* printer);

  // Generate code that initializes the global variable storing the message's
  // descriptor.
  void GenerateDescriptorInitializer(io::Printer* printer, int index);

  // Generate code that calls MessageFactory::InternalRegisterGeneratedMessage()
  // for all types.
  void GenerateTypeRegistrations(io::Printer* printer);

  // Generates code that allocates the message's default instance.
  void GenerateDefaultInstanceAllocator(io::Printer* printer);

  // Generates code that initializes the message's default instance.  This
  // is separate from allocating because all default instances must be
  // allocated before any can be initialized.
  void GenerateDefaultInstanceInitializer(io::Printer* printer);

  // Generates code that should be run when ShutdownProtobufLibrary() is called,
  // to delete all dynamically-allocated objects.
  void GenerateShutdownCode(io::Printer* printer);

  // Generate all non-inline methods for this class.
  void GenerateClassMethods(io::Printer* printer);

 private:
  // Generate declarations and definitions of accessors for fields.
  void GenerateFieldAccessorDeclarations(io::Printer* printer);
  void GenerateFieldAccessorDefinitions(io::Printer* printer);

  // Generate the field offsets array.
  void GenerateOffsets(io::Printer* printer);

  // Generate constructors and destructor.
  void GenerateStructors(io::Printer* printer);

  // The compiler typically generates multiple copies of each constructor and
  // destructor: http://gcc.gnu.org/bugs.html#nonbugs_cxx
  // Placing common code in a separate method reduces the generated code size.
  //
  // Generate the shared constructor code.
  void GenerateSharedConstructorCode(io::Printer* printer);
  // Generate the shared destructor code.
  void GenerateSharedDestructorCode(io::Printer* printer);

  // Generate standard Message methods.
  void GenerateClear(io::Printer* printer);
  void GenerateMergeFromCodedStream(io::Printer* printer);
  void GenerateSerializeWithCachedSizes(io::Printer* printer);
  void GenerateSerializeWithCachedSizesToArray(io::Printer* printer);
  void GenerateSerializeWithCachedSizesBody(io::Printer* printer,
                                            bool to_array);
  void GenerateByteSize(io::Printer* printer);
  void GenerateMergeFrom(io::Printer* printer);
  void GenerateCopyFrom(io::Printer* printer);
  void GenerateSwap(io::Printer* printer);
  void GenerateIsInitialized(io::Printer* printer);

  // Helpers for GenerateSerializeWithCachedSizes().
  void GenerateSerializeOneField(io::Printer* printer,
                                 const FieldDescriptor* field,
                                 bool unbounded);
  void GenerateSerializeOneExtensionRange(
      io::Printer* printer, const Descriptor::ExtensionRange* range,
      bool unbounded);


  const Descriptor* descriptor_;
  string classname_;
  Options options_;
  FieldGeneratorMap field_generators_;
  scoped_array<scoped_ptr<MessageGenerator> > nested_generators_;
  scoped_array<scoped_ptr<EnumGenerator> > enum_generators_;
  scoped_array<scoped_ptr<ExtensionGenerator> > extension_generators_;

  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(MessageGenerator);
};

}  // namespace cpp
}  // namespace compiler
}  // namespace protobuf

}  // namespace google
#endif  // GOOGLE_PROTOBUF_COMPILER_CPP_MESSAGE_H__
