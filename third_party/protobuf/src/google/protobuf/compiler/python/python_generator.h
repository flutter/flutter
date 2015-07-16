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

// Author: robinson@google.com (Will Robinson)
//
// Generates Python code for a given .proto file.

#ifndef GOOGLE_PROTOBUF_COMPILER_PYTHON_GENERATOR_H__
#define GOOGLE_PROTOBUF_COMPILER_PYTHON_GENERATOR_H__

#include <string>

#include <google/protobuf/compiler/code_generator.h>
#include <google/protobuf/stubs/common.h>

namespace google {
namespace protobuf {

class Descriptor;
class EnumDescriptor;
class EnumValueDescriptor;
class FieldDescriptor;
class ServiceDescriptor;

namespace io { class Printer; }

namespace compiler {
namespace python {

// CodeGenerator implementation for generated Python protocol buffer classes.
// If you create your own protocol compiler binary and you want it to support
// Python output, you can do so by registering an instance of this
// CodeGenerator with the CommandLineInterface in your main() function.
class LIBPROTOC_EXPORT Generator : public CodeGenerator {
 public:
  Generator();
  virtual ~Generator();

  // CodeGenerator methods.
  virtual bool Generate(const FileDescriptor* file,
                        const string& parameter,
                        GeneratorContext* generator_context,
                        string* error) const;

 private:
  void PrintImports() const;
  void PrintFileDescriptor() const;
  void PrintTopLevelEnums() const;
  void PrintAllNestedEnumsInFile() const;
  void PrintNestedEnums(const Descriptor& descriptor) const;
  void PrintEnum(const EnumDescriptor& enum_descriptor) const;

  void PrintTopLevelExtensions() const;

  void PrintFieldDescriptor(
      const FieldDescriptor& field, bool is_extension) const;
  void PrintFieldDescriptorsInDescriptor(
      const Descriptor& message_descriptor,
      bool is_extension,
      const string& list_variable_name,
      int (Descriptor::*CountFn)() const,
      const FieldDescriptor* (Descriptor::*GetterFn)(int) const) const;
  void PrintFieldsInDescriptor(const Descriptor& message_descriptor) const;
  void PrintExtensionsInDescriptor(const Descriptor& message_descriptor) const;
  void PrintMessageDescriptors() const;
  void PrintDescriptor(const Descriptor& message_descriptor) const;
  void PrintNestedDescriptors(const Descriptor& containing_descriptor) const;

  void PrintMessages() const;
  void PrintMessage(const Descriptor& message_descriptor) const;
  void PrintNestedMessages(const Descriptor& containing_descriptor) const;

  void FixForeignFieldsInDescriptors() const;
  void FixForeignFieldsInDescriptor(
      const Descriptor& descriptor,
      const Descriptor* containing_descriptor) const;
  void FixForeignFieldsInField(const Descriptor* containing_type,
                               const FieldDescriptor& field,
                               const string& python_dict_name) const;
  void AddMessageToFileDescriptor(const Descriptor& descriptor) const;
  string FieldReferencingExpression(const Descriptor* containing_type,
                                    const FieldDescriptor& field,
                                    const string& python_dict_name) const;
  template <typename DescriptorT>
  void FixContainingTypeInDescriptor(
      const DescriptorT& descriptor,
      const Descriptor* containing_descriptor) const;

  void FixForeignFieldsInExtensions() const;
  void FixForeignFieldsInExtension(
      const FieldDescriptor& extension_field) const;
  void FixForeignFieldsInNestedExtensions(const Descriptor& descriptor) const;

  void PrintServices() const;
  void PrintServiceDescriptor(const ServiceDescriptor& descriptor) const;
  void PrintServiceClass(const ServiceDescriptor& descriptor) const;
  void PrintServiceStub(const ServiceDescriptor& descriptor) const;

  void PrintEnumValueDescriptor(const EnumValueDescriptor& descriptor) const;
  string OptionsValue(const string& class_name,
                      const string& serialized_options) const;
  bool GeneratingDescriptorProto() const;

  template <typename DescriptorT>
  string ModuleLevelDescriptorName(const DescriptorT& descriptor) const;
  string ModuleLevelMessageName(const Descriptor& descriptor) const;
  string ModuleLevelServiceDescriptorName(
      const ServiceDescriptor& descriptor) const;

  template <typename DescriptorT, typename DescriptorProtoT>
  void PrintSerializedPbInterval(
      const DescriptorT& descriptor, DescriptorProtoT& proto) const;

  void FixAllDescriptorOptions() const;
  void FixOptionsForField(const FieldDescriptor& field) const;
  void FixOptionsForEnum(const EnumDescriptor& descriptor) const;
  void FixOptionsForMessage(const Descriptor& descriptor) const;

  // Very coarse-grained lock to ensure that Generate() is reentrant.
  // Guards file_, printer_ and file_descriptor_serialized_.
  mutable Mutex mutex_;
  mutable const FileDescriptor* file_;  // Set in Generate().  Under mutex_.
  mutable string file_descriptor_serialized_;
  mutable io::Printer* printer_;  // Set in Generate().  Under mutex_.

  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(Generator);
};

}  // namespace python
}  // namespace compiler
}  // namespace protobuf

}  // namespace google
#endif  // GOOGLE_PROTOBUF_COMPILER_PYTHON_GENERATOR_H__
