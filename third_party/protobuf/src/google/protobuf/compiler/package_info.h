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
// This file exists solely to document the google::protobuf::compiler namespace.
// It is not compiled into anything, but it may be read by an automated
// documentation generator.

namespace google {

namespace protobuf {

// Implementation of the Protocol Buffer compiler.
//
// This package contains code for parsing .proto files and generating code
// based on them.  There are two reasons you might be interested in this
// package:
// - You want to parse .proto files at runtime.  In this case, you should
//   look at importer.h.  Since this functionality is widely useful, it is
//   included in the libprotobuf base library; you do not have to link against
//   libprotoc.
// - You want to write a custom protocol compiler which generates different
//   kinds of code, e.g. code in a different language which is not supported
//   by the official compiler.  For this purpose, command_line_interface.h
//   provides you with a complete compiler front-end, so all you need to do
//   is write a custom implementation of CodeGenerator and a trivial main()
//   function.  You can even make your compiler support the official languages
//   in addition to your own.  Since this functionality is only useful to those
//   writing custom compilers, it is in a separate library called "libprotoc"
//   which you will have to link against.
namespace compiler {}

}  // namespace protobuf
}  // namespace google
