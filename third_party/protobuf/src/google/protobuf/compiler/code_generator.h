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
// Defines the abstract interface implemented by each of the language-specific
// code generators.

#ifndef GOOGLE_PROTOBUF_COMPILER_CODE_GENERATOR_H__
#define GOOGLE_PROTOBUF_COMPILER_CODE_GENERATOR_H__

#include <google/protobuf/stubs/common.h>
#include <string>
#include <vector>
#include <utility>

namespace google {
namespace protobuf {

namespace io { class ZeroCopyOutputStream; }
class FileDescriptor;

namespace compiler {

// Defined in this file.
class CodeGenerator;
class GeneratorContext;

// The abstract interface to a class which generates code implementing a
// particular proto file in a particular language.  A number of these may
// be registered with CommandLineInterface to support various languages.
class LIBPROTOC_EXPORT CodeGenerator {
 public:
  inline CodeGenerator() {}
  virtual ~CodeGenerator();

  // Generates code for the given proto file, generating one or more files in
  // the given output directory.
  //
  // A parameter to be passed to the generator can be specified on the
  // command line.  This is intended to be used by Java and similar languages
  // to specify which specific class from the proto file is to be generated,
  // though it could have other uses as well.  It is empty if no parameter was
  // given.
  //
  // Returns true if successful.  Otherwise, sets *error to a description of
  // the problem (e.g. "invalid parameter") and returns false.
  virtual bool Generate(const FileDescriptor* file,
                        const string& parameter,
                        GeneratorContext* generator_context,
                        string* error) const = 0;

 private:
  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(CodeGenerator);
};

// CodeGenerators generate one or more files in a given directory.  This
// abstract interface represents the directory to which the CodeGenerator is
// to write and other information about the context in which the Generator
// runs.
class LIBPROTOC_EXPORT GeneratorContext {
 public:
  inline GeneratorContext() {}
  virtual ~GeneratorContext();

  // Opens the given file, truncating it if it exists, and returns a
  // ZeroCopyOutputStream that writes to the file.  The caller takes ownership
  // of the returned object.  This method never fails (a dummy stream will be
  // returned instead).
  //
  // The filename given should be relative to the root of the source tree.
  // E.g. the C++ generator, when generating code for "foo/bar.proto", will
  // generate the files "foo/bar.pb.h" and "foo/bar.pb.cc"; note that
  // "foo/" is included in these filenames.  The filename is not allowed to
  // contain "." or ".." components.
  virtual io::ZeroCopyOutputStream* Open(const string& filename) = 0;

  // Creates a ZeroCopyOutputStream which will insert code into the given file
  // at the given insertion point.  See plugin.proto (plugin.pb.h) for more
  // information on insertion points.  The default implementation
  // assert-fails -- it exists only for backwards-compatibility.
  //
  // WARNING:  This feature is currently EXPERIMENTAL and is subject to change.
  virtual io::ZeroCopyOutputStream* OpenForInsert(
      const string& filename, const string& insertion_point);

  // Returns a vector of FileDescriptors for all the files being compiled
  // in this run.  Useful for languages, such as Go, that treat files
  // differently when compiled as a set rather than individually.
  virtual void ListParsedFiles(vector<const FileDescriptor*>* output);

 private:
  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(GeneratorContext);
};

// The type GeneratorContext was once called OutputDirectory. This typedef
// provides backward compatibility.
typedef GeneratorContext OutputDirectory;

// Several code generators treat the parameter argument as holding a
// list of options separated by commas.  This helper function parses
// a set of comma-delimited name/value pairs: e.g.,
//   "foo=bar,baz,qux=corge"
// parses to the pairs:
//   ("foo", "bar"), ("baz", ""), ("qux", "corge")
extern void ParseGeneratorParameter(const string&,
            vector<pair<string, string> >*);

}  // namespace compiler
}  // namespace protobuf

}  // namespace google
#endif  // GOOGLE_PROTOBUF_COMPILER_CODE_GENERATOR_H__
