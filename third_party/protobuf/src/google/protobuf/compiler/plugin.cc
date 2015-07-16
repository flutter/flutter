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

#include <google/protobuf/compiler/plugin.h>

#include <iostream>
#include <set>

#ifdef _WIN32
#include <io.h>
#include <fcntl.h>
#ifndef STDIN_FILENO
#define STDIN_FILENO 0
#endif
#ifndef STDOUT_FILENO
#define STDOUT_FILENO 1
#endif
#else
#include <unistd.h>
#endif

#include <google/protobuf/stubs/common.h>
#include <google/protobuf/compiler/plugin.pb.h>
#include <google/protobuf/compiler/code_generator.h>
#include <google/protobuf/descriptor.h>
#include <google/protobuf/io/zero_copy_stream_impl.h>


namespace google {
namespace protobuf {
namespace compiler {

class GeneratorResponseContext : public GeneratorContext {
 public:
  GeneratorResponseContext(CodeGeneratorResponse* response,
                           const vector<const FileDescriptor*>& parsed_files)
      : response_(response),
        parsed_files_(parsed_files) {}
  virtual ~GeneratorResponseContext() {}

  // implements GeneratorContext --------------------------------------

  virtual io::ZeroCopyOutputStream* Open(const string& filename) {
    CodeGeneratorResponse::File* file = response_->add_file();
    file->set_name(filename);
    return new io::StringOutputStream(file->mutable_content());
  }

  virtual io::ZeroCopyOutputStream* OpenForInsert(
      const string& filename, const string& insertion_point) {
    CodeGeneratorResponse::File* file = response_->add_file();
    file->set_name(filename);
    file->set_insertion_point(insertion_point);
    return new io::StringOutputStream(file->mutable_content());
  }

  void ListParsedFiles(vector<const FileDescriptor*>* output) {
    *output = parsed_files_;
  }

 private:
  CodeGeneratorResponse* response_;
  const vector<const FileDescriptor*>& parsed_files_;
};

int PluginMain(int argc, char* argv[], const CodeGenerator* generator) {

  if (argc > 1) {
    cerr << argv[0] << ": Unknown option: " << argv[1] << endl;
    return 1;
  }

#ifdef _WIN32
  _setmode(STDIN_FILENO, _O_BINARY);
  _setmode(STDOUT_FILENO, _O_BINARY);
#endif

  CodeGeneratorRequest request;
  if (!request.ParseFromFileDescriptor(STDIN_FILENO)) {
    cerr << argv[0] << ": protoc sent unparseable request to plugin." << endl;
    return 1;
  }

  DescriptorPool pool;
  for (int i = 0; i < request.proto_file_size(); i++) {
    const FileDescriptor* file = pool.BuildFile(request.proto_file(i));
    if (file == NULL) {
      // BuildFile() already wrote an error message.
      return 1;
    }
  }

  vector<const FileDescriptor*> parsed_files;
  for (int i = 0; i < request.file_to_generate_size(); i++) {
    parsed_files.push_back(pool.FindFileByName(request.file_to_generate(i)));
    if (parsed_files.back() == NULL) {
      cerr << argv[0] << ": protoc asked plugin to generate a file but "
              "did not provide a descriptor for the file: "
           << request.file_to_generate(i) << endl;
      return 1;
    }
  }

  CodeGeneratorResponse response;
  GeneratorResponseContext context(&response, parsed_files);

  for (int i = 0; i < parsed_files.size(); i++) {
    const FileDescriptor* file = parsed_files[i];

    string error;
    bool succeeded = generator->Generate(
        file, request.parameter(), &context, &error);

    if (!succeeded && error.empty()) {
      error = "Code generator returned false but provided no error "
              "description.";
    }
    if (!error.empty()) {
      response.set_error(file->name() + ": " + error);
      break;
    }
  }

  if (!response.SerializeToFileDescriptor(STDOUT_FILENO)) {
    cerr << argv[0] << ": Error writing to stdout." << endl;
    return 1;
  }

  return 0;
}

}  // namespace compiler
}  // namespace protobuf
}  // namespace google
