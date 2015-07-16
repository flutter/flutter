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
// Implements the Protocol Compiler front-end such that it may be reused by
// custom compilers written to support other languages.

#ifndef GOOGLE_PROTOBUF_COMPILER_COMMAND_LINE_INTERFACE_H__
#define GOOGLE_PROTOBUF_COMPILER_COMMAND_LINE_INTERFACE_H__

#include <google/protobuf/stubs/common.h>
#include <string>
#include <vector>
#include <map>
#include <set>
#include <utility>

namespace google {
namespace protobuf {

class FileDescriptor;        // descriptor.h
class DescriptorPool;        // descriptor.h
class FileDescriptorProto;   // descriptor.pb.h
template<typename T> class RepeatedPtrField;  // repeated_field.h

namespace compiler {

class CodeGenerator;        // code_generator.h
class GeneratorContext;      // code_generator.h
class DiskSourceTree;       // importer.h

// This class implements the command-line interface to the protocol compiler.
// It is designed to make it very easy to create a custom protocol compiler
// supporting the languages of your choice.  For example, if you wanted to
// create a custom protocol compiler binary which includes both the regular
// C++ support plus support for your own custom output "Foo", you would
// write a class "FooGenerator" which implements the CodeGenerator interface,
// then write a main() procedure like this:
//
//   int main(int argc, char* argv[]) {
//     google::protobuf::compiler::CommandLineInterface cli;
//
//     // Support generation of C++ source and headers.
//     google::protobuf::compiler::cpp::CppGenerator cpp_generator;
//     cli.RegisterGenerator("--cpp_out", &cpp_generator,
//       "Generate C++ source and header.");
//
//     // Support generation of Foo code.
//     FooGenerator foo_generator;
//     cli.RegisterGenerator("--foo_out", &foo_generator,
//       "Generate Foo file.");
//
//     return cli.Run(argc, argv);
//   }
//
// The compiler is invoked with syntax like:
//   protoc --cpp_out=outdir --foo_out=outdir --proto_path=src src/foo.proto
//
// For a full description of the command-line syntax, invoke it with --help.
class LIBPROTOC_EXPORT CommandLineInterface {
 public:
  CommandLineInterface();
  ~CommandLineInterface();

  // Register a code generator for a language.
  //
  // Parameters:
  // * flag_name: The command-line flag used to specify an output file of
  //   this type.  The name must start with a '-'.  If the name is longer
  //   than one letter, it must start with two '-'s.
  // * generator: The CodeGenerator which will be called to generate files
  //   of this type.
  // * help_text: Text describing this flag in the --help output.
  //
  // Some generators accept extra parameters.  You can specify this parameter
  // on the command-line by placing it before the output directory, separated
  // by a colon:
  //   protoc --foo_out=enable_bar:outdir
  // The text before the colon is passed to CodeGenerator::Generate() as the
  // "parameter".
  void RegisterGenerator(const string& flag_name,
                         CodeGenerator* generator,
                         const string& help_text);

  // Register a code generator for a language.
  // Besides flag_name you can specify another option_flag_name that could be
  // used to pass extra parameters to the registered code generator.
  // Suppose you have registered a generator by calling:
  //   command_line_interface.RegisterGenerator("--foo_out", "--foo_opt", ...)
  // Then you could invoke the compiler with a command like:
  //   protoc --foo_out=enable_bar:outdir --foo_opt=enable_baz
  // This will pass "enable_bar,enable_baz" as the parameter to the generator.
  void RegisterGenerator(const string& flag_name,
                         const string& option_flag_name,
                         CodeGenerator* generator,
                         const string& help_text);

  // Enables "plugins".  In this mode, if a command-line flag ends with "_out"
  // but does not match any registered generator, the compiler will attempt to
  // find a "plugin" to implement the generator.  Plugins are just executables.
  // They should live somewhere in the PATH.
  //
  // The compiler determines the executable name to search for by concatenating
  // exe_name_prefix with the unrecognized flag name, removing "_out".  So, for
  // example, if exe_name_prefix is "protoc-" and you pass the flag --foo_out,
  // the compiler will try to run the program "protoc-foo".
  //
  // The plugin program should implement the following usage:
  //   plugin [--out=OUTDIR] [--parameter=PARAMETER] PROTO_FILES < DESCRIPTORS
  // --out indicates the output directory (as passed to the --foo_out
  // parameter); if omitted, the current directory should be used.  --parameter
  // gives the generator parameter, if any was provided.  The PROTO_FILES list
  // the .proto files which were given on the compiler command-line; these are
  // the files for which the plugin is expected to generate output code.
  // Finally, DESCRIPTORS is an encoded FileDescriptorSet (as defined in
  // descriptor.proto).  This is piped to the plugin's stdin.  The set will
  // include descriptors for all the files listed in PROTO_FILES as well as
  // all files that they import.  The plugin MUST NOT attempt to read the
  // PROTO_FILES directly -- it must use the FileDescriptorSet.
  //
  // The plugin should generate whatever files are necessary, as code generators
  // normally do.  It should write the names of all files it generates to
  // stdout.  The names should be relative to the output directory, NOT absolute
  // names or relative to the current directory.  If any errors occur, error
  // messages should be written to stderr.  If an error is fatal, the plugin
  // should exit with a non-zero exit code.
  void AllowPlugins(const string& exe_name_prefix);

  // Run the Protocol Compiler with the given command-line parameters.
  // Returns the error code which should be returned by main().
  //
  // It may not be safe to call Run() in a multi-threaded environment because
  // it calls strerror().  I'm not sure why you'd want to do this anyway.
  int Run(int argc, const char* const argv[]);

  // Call SetInputsAreCwdRelative(true) if the input files given on the command
  // line should be interpreted relative to the proto import path specified
  // using --proto_path or -I flags.  Otherwise, input file names will be
  // interpreted relative to the current working directory (or as absolute
  // paths if they start with '/'), though they must still reside inside
  // a directory given by --proto_path or the compiler will fail.  The latter
  // mode is generally more intuitive and easier to use, especially e.g. when
  // defining implicit rules in Makefiles.
  void SetInputsAreProtoPathRelative(bool enable) {
    inputs_are_proto_path_relative_ = enable;
  }

  // Provides some text which will be printed when the --version flag is
  // used.  The version of libprotoc will also be printed on the next line
  // after this text.
  void SetVersionInfo(const string& text) {
    version_info_ = text;
  }


 private:
  // -----------------------------------------------------------------

  class ErrorPrinter;
  class GeneratorContextImpl;
  class MemoryOutputStream;

  // Clear state from previous Run().
  void Clear();

  // Remaps each file in input_files_ so that it is relative to one of the
  // directories in proto_path_.  Returns false if an error occurred.  This
  // is only used if inputs_are_proto_path_relative_ is false.
  bool MakeInputsBeProtoPathRelative(
    DiskSourceTree* source_tree);

  // Return status for ParseArguments() and InterpretArgument().
  enum ParseArgumentStatus {
    PARSE_ARGUMENT_DONE_AND_CONTINUE,
    PARSE_ARGUMENT_DONE_AND_EXIT,
    PARSE_ARGUMENT_FAIL
  };

  // Parse all command-line arguments.
  ParseArgumentStatus ParseArguments(int argc, const char* const argv[]);

  // Parses a command-line argument into a name/value pair.  Returns
  // true if the next argument in the argv should be used as the value,
  // false otherwise.
  //
  // Exmaples:
  //   "-Isrc/protos" ->
  //     name = "-I", value = "src/protos"
  //   "--cpp_out=src/foo.pb2.cc" ->
  //     name = "--cpp_out", value = "src/foo.pb2.cc"
  //   "foo.proto" ->
  //     name = "", value = "foo.proto"
  bool ParseArgument(const char* arg, string* name, string* value);

  // Interprets arguments parsed with ParseArgument.
  ParseArgumentStatus InterpretArgument(const string& name,
                                        const string& value);

  // Print the --help text to stderr.
  void PrintHelpText();

  // Generate the given output file from the given input.
  struct OutputDirective;  // see below
  bool GenerateOutput(const vector<const FileDescriptor*>& parsed_files,
                      const OutputDirective& output_directive,
                      GeneratorContext* generator_context);
  bool GeneratePluginOutput(const vector<const FileDescriptor*>& parsed_files,
                            const string& plugin_name,
                            const string& parameter,
                            GeneratorContext* generator_context,
                            string* error);

  // Implements --encode and --decode.
  bool EncodeOrDecode(const DescriptorPool* pool);

  // Implements the --descriptor_set_out option.
  bool WriteDescriptorSet(const vector<const FileDescriptor*> parsed_files);

  // Get all transitive dependencies of the given file (including the file
  // itself), adding them to the given list of FileDescriptorProtos.  The
  // protos will be ordered such that every file is listed before any file that
  // depends on it, so that you can call DescriptorPool::BuildFile() on them
  // in order.  Any files in *already_seen will not be added, and each file
  // added will be inserted into *already_seen.  If include_source_code_info is
  // true then include the source code information in the FileDescriptorProtos.
  static void GetTransitiveDependencies(
      const FileDescriptor* file,
      bool include_source_code_info,
      set<const FileDescriptor*>* already_seen,
      RepeatedPtrField<FileDescriptorProto>* output);

  // -----------------------------------------------------------------

  // The name of the executable as invoked (i.e. argv[0]).
  string executable_name_;

  // Version info set with SetVersionInfo().
  string version_info_;

  // Registered generators.
  struct GeneratorInfo {
    string flag_name;
    string option_flag_name;
    CodeGenerator* generator;
    string help_text;
  };
  typedef map<string, GeneratorInfo> GeneratorMap;
  GeneratorMap generators_by_flag_name_;
  GeneratorMap generators_by_option_name_;
  // A map from generator names to the parameters specified using the option
  // flag. For example, if the user invokes the compiler with:
  //   protoc --foo_out=outputdir --foo_opt=enable_bar ...
  // Then there will be an entry ("--foo_out", "enable_bar") in this map.
  map<string, string> generator_parameters_;

  // See AllowPlugins().  If this is empty, plugins aren't allowed.
  string plugin_prefix_;

  // Maps specific plugin names to files.  When executing a plugin, this map
  // is searched first to find the plugin executable.  If not found here, the
  // PATH (or other OS-specific search strategy) is searched.
  map<string, string> plugins_;

  // Stuff parsed from command line.
  enum Mode {
    MODE_COMPILE,  // Normal mode:  parse .proto files and compile them.
    MODE_ENCODE,   // --encode:  read text from stdin, write binary to stdout.
    MODE_DECODE    // --decode:  read binary from stdin, write text to stdout.
  };

  Mode mode_;

  enum ErrorFormat {
    ERROR_FORMAT_GCC,   // GCC error output format (default).
    ERROR_FORMAT_MSVS   // Visual Studio output (--error_format=msvs).
  };

  ErrorFormat error_format_;

  vector<pair<string, string> > proto_path_;  // Search path for proto files.
  vector<string> input_files_;                // Names of the input proto files.

  // output_directives_ lists all the files we are supposed to output and what
  // generator to use for each.
  struct OutputDirective {
    string name;                // E.g. "--foo_out"
    CodeGenerator* generator;   // NULL for plugins
    string parameter;
    string output_location;
  };
  vector<OutputDirective> output_directives_;

  // When using --encode or --decode, this names the type we are encoding or
  // decoding.  (Empty string indicates --decode_raw.)
  string codec_type_;

  // If --descriptor_set_out was given, this is the filename to which the
  // FileDescriptorSet should be written.  Otherwise, empty.
  string descriptor_set_name_;

  // True if --include_imports was given, meaning that we should
  // write all transitive dependencies to the DescriptorSet.  Otherwise, only
  // the .proto files listed on the command-line are added.
  bool imports_in_descriptor_set_;

  // True if --include_source_info was given, meaning that we should not strip
  // SourceCodeInfo from the DescriptorSet.
  bool source_info_in_descriptor_set_;

  // Was the --disallow_services flag used?
  bool disallow_services_;

  // See SetInputsAreProtoPathRelative().
  bool inputs_are_proto_path_relative_;

  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(CommandLineInterface);
};

}  // namespace compiler
}  // namespace protobuf

}  // namespace google
#endif  // GOOGLE_PROTOBUF_COMPILER_COMMAND_LINE_INTERFACE_H__
