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

#include <google/protobuf/compiler/java/java_file.h>
#include <google/protobuf/compiler/java/java_enum.h>
#include <google/protobuf/compiler/java/java_service.h>
#include <google/protobuf/compiler/java/java_extension.h>
#include <google/protobuf/compiler/java/java_helpers.h>
#include <google/protobuf/compiler/java/java_message.h>
#include <google/protobuf/compiler/code_generator.h>
#include <google/protobuf/io/printer.h>
#include <google/protobuf/io/zero_copy_stream.h>
#include <google/protobuf/descriptor.pb.h>
#include <google/protobuf/dynamic_message.h>
#include <google/protobuf/stubs/strutil.h>

namespace google {
namespace protobuf {
namespace compiler {
namespace java {

namespace {


// Recursively searches the given message to collect extensions.
// Returns true if all the extensions can be recognized. The extensions will be
// appended in to the extensions parameter.
// Returns false when there are unknown fields, in which case the data in the
// extensions output parameter is not reliable and should be discarded.
bool CollectExtensions(const Message& message,
                       vector<const FieldDescriptor*>* extensions) {
  const Reflection* reflection = message.GetReflection();

  // There are unknown fields that could be extensions, thus this call fails.
  if (reflection->GetUnknownFields(message).field_count() > 0) return false;

  vector<const FieldDescriptor*> fields;
  reflection->ListFields(message, &fields);

  for (int i = 0; i < fields.size(); i++) {
    if (fields[i]->is_extension()) extensions->push_back(fields[i]);

    if (GetJavaType(fields[i]) == JAVATYPE_MESSAGE) {
      if (fields[i]->is_repeated()) {
        int size = reflection->FieldSize(message, fields[i]);
        for (int j = 0; j < size; j++) {
          const Message& sub_message =
            reflection->GetRepeatedMessage(message, fields[i], j);
          if (!CollectExtensions(sub_message, extensions)) return false;
        }
      } else {
        const Message& sub_message = reflection->GetMessage(message, fields[i]);
        if (!CollectExtensions(sub_message, extensions)) return false;
      }
    }
  }

  return true;
}

// Finds all extensions in the given message and its sub-messages.  If the
// message contains unknown fields (which could be extensions), then those
// extensions are defined in alternate_pool.
// The message will be converted to a DynamicMessage backed by alternate_pool
// in order to handle this case.
void CollectExtensions(const FileDescriptorProto& file_proto,
                       const DescriptorPool& alternate_pool,
                       vector<const FieldDescriptor*>* extensions,
                       const string& file_data) {
  if (!CollectExtensions(file_proto, extensions)) {
    // There are unknown fields in the file_proto, which are probably
    // extensions. We need to parse the data into a dynamic message based on the
    // builder-pool to find out all extensions.
    const Descriptor* file_proto_desc = alternate_pool.FindMessageTypeByName(
        file_proto.GetDescriptor()->full_name());
    GOOGLE_CHECK(file_proto_desc)
        << "Find unknown fields in FileDescriptorProto when building "
        << file_proto.name()
        << ". It's likely that those fields are custom options, however, "
           "descriptor.proto is not in the transitive dependencies. "
           "This normally should not happen. Please report a bug.";
    DynamicMessageFactory factory;
    scoped_ptr<Message> dynamic_file_proto(
        factory.GetPrototype(file_proto_desc)->New());
    GOOGLE_CHECK(dynamic_file_proto.get() != NULL);
    GOOGLE_CHECK(dynamic_file_proto->ParseFromString(file_data));

    // Collect the extensions again from the dynamic message. There should be no
    // more unknown fields this time, i.e. all the custom options should be
    // parsed as extensions now.
    extensions->clear();
    GOOGLE_CHECK(CollectExtensions(*dynamic_file_proto, extensions))
        << "Find unknown fields in FileDescriptorProto when building "
        << file_proto.name()
        << ". It's likely that those fields are custom options, however, "
           "those options cannot be recognized in the builder pool. "
           "This normally should not happen. Please report a bug.";
  }
}


}  // namespace

FileGenerator::FileGenerator(const FileDescriptor* file)
  : file_(file),
    java_package_(FileJavaPackage(file)),
    classname_(FileClassName(file)) {
}

FileGenerator::~FileGenerator() {}

bool FileGenerator::Validate(string* error) {
  // Check that no class name matches the file's class name.  This is a common
  // problem that leads to Java compile errors that can be hard to understand.
  // It's especially bad when using the java_multiple_files, since we would
  // end up overwriting the outer class with one of the inner ones.

  bool found_conflict = false;
  for (int i = 0; i < file_->enum_type_count() && !found_conflict; i++) {
    if (file_->enum_type(i)->name() == classname_) {
      found_conflict = true;
    }
  }
  for (int i = 0; i < file_->message_type_count() && !found_conflict; i++) {
    if (file_->message_type(i)->name() == classname_) {
      found_conflict = true;
    }
  }
  for (int i = 0; i < file_->service_count() && !found_conflict; i++) {
    if (file_->service(i)->name() == classname_) {
      found_conflict = true;
    }
  }

  if (found_conflict) {
    error->assign(file_->name());
    error->append(
      ": Cannot generate Java output because the file's outer class name, \"");
    error->append(classname_);
    error->append(
      "\", matches the name of one of the types declared inside it.  "
      "Please either rename the type or use the java_outer_classname "
      "option to specify a different outer class name for the .proto file.");
    return false;
  }

  return true;
}

void FileGenerator::Generate(io::Printer* printer) {
  // We don't import anything because we refer to all classes by their
  // fully-qualified names in the generated source.
  printer->Print(
    "// Generated by the protocol buffer compiler.  DO NOT EDIT!\n"
    "// source: $filename$\n"
    "\n",
    "filename", file_->name());
  if (!java_package_.empty()) {
    printer->Print(
      "package $package$;\n"
      "\n",
      "package", java_package_);
  }
  printer->Print(
    "public final class $classname$ {\n"
    "  private $classname$() {}\n",
    "classname", classname_);
  printer->Indent();

  // -----------------------------------------------------------------

  printer->Print(
    "public static void registerAllExtensions(\n"
    "    com.google.protobuf.ExtensionRegistry$lite$ registry) {\n",
    "lite", HasDescriptorMethods(file_) ? "" : "Lite");

  printer->Indent();

  for (int i = 0; i < file_->extension_count(); i++) {
    ExtensionGenerator(file_->extension(i)).GenerateRegistrationCode(printer);
  }

  for (int i = 0; i < file_->message_type_count(); i++) {
    MessageGenerator(file_->message_type(i))
      .GenerateExtensionRegistrationCode(printer);
  }

  printer->Outdent();
  printer->Print(
    "}\n");

  // -----------------------------------------------------------------

  if (!file_->options().java_multiple_files()) {
    for (int i = 0; i < file_->enum_type_count(); i++) {
      EnumGenerator(file_->enum_type(i)).Generate(printer);
    }
    for (int i = 0; i < file_->message_type_count(); i++) {
      MessageGenerator messageGenerator(file_->message_type(i));
      messageGenerator.GenerateInterface(printer);
      messageGenerator.Generate(printer);
    }
    if (HasGenericServices(file_)) {
      for (int i = 0; i < file_->service_count(); i++) {
        ServiceGenerator(file_->service(i)).Generate(printer);
      }
    }
  }

  // Extensions must be generated in the outer class since they are values,
  // not classes.
  for (int i = 0; i < file_->extension_count(); i++) {
    ExtensionGenerator(file_->extension(i)).Generate(printer);
  }

  // Static variables.
  for (int i = 0; i < file_->message_type_count(); i++) {
    // TODO(kenton):  Reuse MessageGenerator objects?
    MessageGenerator(file_->message_type(i)).GenerateStaticVariables(printer);
  }

  printer->Print("\n");

  if (HasDescriptorMethods(file_)) {
    GenerateEmbeddedDescriptor(printer);
  } else {
    printer->Print(
      "static {\n");
    printer->Indent();

    for (int i = 0; i < file_->message_type_count(); i++) {
      // TODO(kenton):  Reuse MessageGenerator objects?
      MessageGenerator(file_->message_type(i))
        .GenerateStaticVariableInitializers(printer);
    }

    printer->Outdent();
    printer->Print(
      "}\n");
  }

  printer->Print(
    "\n"
    "// @@protoc_insertion_point(outer_class_scope)\n");

  printer->Outdent();
  printer->Print("}\n");
}

void FileGenerator::GenerateEmbeddedDescriptor(io::Printer* printer) {
  // Embed the descriptor.  We simply serialize the entire FileDescriptorProto
  // and embed it as a string literal, which is parsed and built into real
  // descriptors at initialization time.  We unfortunately have to put it in
  // a string literal, not a byte array, because apparently using a literal
  // byte array causes the Java compiler to generate *instructions* to
  // initialize each and every byte of the array, e.g. as if you typed:
  //   b[0] = 123; b[1] = 456; b[2] = 789;
  // This makes huge bytecode files and can easily hit the compiler's internal
  // code size limits (error "code to large").  String literals are apparently
  // embedded raw, which is what we want.
  FileDescriptorProto file_proto;
  file_->CopyTo(&file_proto);

  string file_data;
  file_proto.SerializeToString(&file_data);

  printer->Print(
    "public static com.google.protobuf.Descriptors.FileDescriptor\n"
    "    getDescriptor() {\n"
    "  return descriptor;\n"
    "}\n"
    "private static com.google.protobuf.Descriptors.FileDescriptor\n"
    "    descriptor;\n"
    "static {\n"
    "  java.lang.String[] descriptorData = {\n");
  printer->Indent();
  printer->Indent();

  // Only write 40 bytes per line.
  static const int kBytesPerLine = 40;
  for (int i = 0; i < file_data.size(); i += kBytesPerLine) {
    if (i > 0) {
      // Every 400 lines, start a new string literal, in order to avoid the
      // 64k length limit.
      if (i % 400 == 0) {
        printer->Print(",\n");
      } else {
        printer->Print(" +\n");
      }
    }
    printer->Print("\"$data$\"",
      "data", CEscape(file_data.substr(i, kBytesPerLine)));
  }

  printer->Outdent();
  printer->Print("\n};\n");

  // -----------------------------------------------------------------
  // Create the InternalDescriptorAssigner.

  printer->Print(
    "com.google.protobuf.Descriptors.FileDescriptor."
      "InternalDescriptorAssigner assigner =\n"
    "  new com.google.protobuf.Descriptors.FileDescriptor."
      "InternalDescriptorAssigner() {\n"
    "    public com.google.protobuf.ExtensionRegistry assignDescriptors(\n"
    "        com.google.protobuf.Descriptors.FileDescriptor root) {\n"
    "      descriptor = root;\n");

  printer->Indent();
  printer->Indent();
  printer->Indent();

  for (int i = 0; i < file_->message_type_count(); i++) {
    // TODO(kenton):  Reuse MessageGenerator objects?
    MessageGenerator(file_->message_type(i))
      .GenerateStaticVariableInitializers(printer);
  }
  for (int i = 0; i < file_->extension_count(); i++) {
    // TODO(kenton):  Reuse ExtensionGenerator objects?
    ExtensionGenerator(file_->extension(i))
        .GenerateNonNestedInitializationCode(printer);
  }

  // Proto compiler builds a DescriptorPool, which holds all the descriptors to
  // generate, when processing the ".proto" files. We call this DescriptorPool
  // the parsed pool (a.k.a. file_->pool()).
  //
  // Note that when users try to extend the (.*)DescriptorProto in their
  // ".proto" files, it does not affect the pre-built FileDescriptorProto class
  // in proto compiler. When we put the descriptor data in the file_proto, those
  // extensions become unknown fields.
  //
  // Now we need to find out all the extension value to the (.*)DescriptorProto
  // in the file_proto message, and prepare an ExtensionRegistry to return.
  //
  // To find those extensions, we need to parse the data into a dynamic message
  // of the FileDescriptor based on the builder-pool, then we can use
  // reflections to find all extension fields
  vector<const FieldDescriptor*> extensions;
  CollectExtensions(file_proto, *file_->pool(), &extensions, file_data);

  if (extensions.size() > 0) {
    // Must construct an ExtensionRegistry containing all existing extensions
    // and return it.
    printer->Print(
      "com.google.protobuf.ExtensionRegistry registry =\n"
      "  com.google.protobuf.ExtensionRegistry.newInstance();\n");
    for (int i = 0; i < extensions.size(); i++) {
      ExtensionGenerator(extensions[i]).GenerateRegistrationCode(printer);
    }
    printer->Print(
      "return registry;\n");
  } else {
    printer->Print(
      "return null;\n");
  }

  printer->Outdent();
  printer->Outdent();
  printer->Outdent();

  printer->Print(
    "    }\n"
    "  };\n");

  // -----------------------------------------------------------------
  // Invoke internalBuildGeneratedFileFrom() to build the file.

  printer->Print(
    "com.google.protobuf.Descriptors.FileDescriptor\n"
    "  .internalBuildGeneratedFileFrom(descriptorData,\n"
    "    new com.google.protobuf.Descriptors.FileDescriptor[] {\n");

  for (int i = 0; i < file_->dependency_count(); i++) {
    if (ShouldIncludeDependency(file_->dependency(i))) {
      printer->Print(
        "      $dependency$.getDescriptor(),\n",
        "dependency", ClassName(file_->dependency(i)));
    }
  }

  printer->Print(
    "    }, assigner);\n");

  printer->Outdent();
  printer->Print(
    "}\n");
}

template<typename GeneratorClass, typename DescriptorClass>
static void GenerateSibling(const string& package_dir,
                            const string& java_package,
                            const DescriptorClass* descriptor,
                            GeneratorContext* context,
                            vector<string>* file_list,
                            const string& name_suffix,
                            void (GeneratorClass::*pfn)(io::Printer* printer)) {
  string filename = package_dir + descriptor->name() + name_suffix + ".java";
  file_list->push_back(filename);

  scoped_ptr<io::ZeroCopyOutputStream> output(context->Open(filename));
  io::Printer printer(output.get(), '$');

  printer.Print(
    "// Generated by the protocol buffer compiler.  DO NOT EDIT!\n"
    "// source: $filename$\n"
    "\n",
    "filename", descriptor->file()->name());
  if (!java_package.empty()) {
    printer.Print(
      "package $package$;\n"
      "\n",
      "package", java_package);
  }

  GeneratorClass generator(descriptor);
  (generator.*pfn)(&printer);
}

void FileGenerator::GenerateSiblings(const string& package_dir,
                                     GeneratorContext* context,
                                     vector<string>* file_list) {
  if (file_->options().java_multiple_files()) {
    for (int i = 0; i < file_->enum_type_count(); i++) {
      GenerateSibling<EnumGenerator>(package_dir, java_package_,
                                     file_->enum_type(i),
                                     context, file_list, "",
                                     &EnumGenerator::Generate);
    }
    for (int i = 0; i < file_->message_type_count(); i++) {
      GenerateSibling<MessageGenerator>(package_dir, java_package_,
                                        file_->message_type(i),
                                        context, file_list, "OrBuilder",
                                        &MessageGenerator::GenerateInterface);
      GenerateSibling<MessageGenerator>(package_dir, java_package_,
                                        file_->message_type(i),
                                        context, file_list, "",
                                        &MessageGenerator::Generate);
    }
    if (HasGenericServices(file_)) {
      for (int i = 0; i < file_->service_count(); i++) {
        GenerateSibling<ServiceGenerator>(package_dir, java_package_,
                                          file_->service(i),
                                          context, file_list, "",
                                          &ServiceGenerator::Generate);
      }
    }
  }
}

bool FileGenerator::ShouldIncludeDependency(const FileDescriptor* descriptor) {
  return true;
}

}  // namespace java
}  // namespace compiler
}  // namespace protobuf
}  // namespace google
