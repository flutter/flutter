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

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#ifdef _MSC_VER
#include <io.h>
#else
#include <unistd.h>
#endif
#include <vector>

#include <google/protobuf/descriptor.pb.h>
#include <google/protobuf/descriptor.h>
#include <google/protobuf/io/zero_copy_stream.h>
#include <google/protobuf/compiler/command_line_interface.h>
#include <google/protobuf/compiler/code_generator.h>
#include <google/protobuf/compiler/mock_code_generator.h>
#include <google/protobuf/compiler/subprocess.h>
#include <google/protobuf/io/printer.h>
#include <google/protobuf/unittest.pb.h>
#include <google/protobuf/testing/file.h>
#include <google/protobuf/stubs/strutil.h>
#include <google/protobuf/stubs/substitute.h>

#include <google/protobuf/testing/googletest.h>
#include <gtest/gtest.h>

namespace google {
namespace protobuf {
namespace compiler {

#if defined(_WIN32)
#ifndef STDIN_FILENO
#define STDIN_FILENO 0
#endif
#ifndef STDOUT_FILENO
#define STDOUT_FILENO 1
#endif
#ifndef F_OK
#define F_OK 00  // not defined by MSVC for whatever reason
#endif
#endif

namespace {

class CommandLineInterfaceTest : public testing::Test {
 protected:
  virtual void SetUp();
  virtual void TearDown();

  // Runs the CommandLineInterface with the given command line.  The
  // command is automatically split on spaces, and the string "$tmpdir"
  // is replaced with TestTempDir().
  void Run(const string& command);

  // -----------------------------------------------------------------
  // Methods to set up the test (called before Run()).

  class NullCodeGenerator;

  // Normally plugins are allowed for all tests.  Call this to explicitly
  // disable them.
  void DisallowPlugins() { disallow_plugins_ = true; }

  // Create a temp file within temp_directory_ with the given name.
  // The containing directory is also created if necessary.
  void CreateTempFile(const string& name, const string& contents);

  // Create a subdirectory within temp_directory_.
  void CreateTempDir(const string& name);

  void SetInputsAreProtoPathRelative(bool enable) {
    cli_.SetInputsAreProtoPathRelative(enable);
  }

  // -----------------------------------------------------------------
  // Methods to check the test results (called after Run()).

  // Checks that no text was written to stderr during Run(), and Run()
  // returned 0.
  void ExpectNoErrors();

  // Checks that Run() returned non-zero and the stderr output is exactly
  // the text given.  expected_test may contain references to "$tmpdir",
  // which will be replaced by the temporary directory path.
  void ExpectErrorText(const string& expected_text);

  // Checks that Run() returned non-zero and the stderr contains the given
  // substring.
  void ExpectErrorSubstring(const string& expected_substring);

  // Like ExpectErrorSubstring, but checks that Run() returned zero.
  void ExpectErrorSubstringWithZeroReturnCode(
      const string& expected_substring);

  // Returns true if ExpectErrorSubstring(expected_substring) would pass, but
  // does not fail otherwise.
  bool HasAlternateErrorSubstring(const string& expected_substring);

  // Checks that MockCodeGenerator::Generate() was called in the given
  // context (or the generator in test_plugin.cc, which produces the same
  // output).  That is, this tests if the generator with the given name
  // was called with the given parameter and proto file and produced the
  // given output file.  This is checked by reading the output file and
  // checking that it contains the content that MockCodeGenerator would
  // generate given these inputs.  message_name is the name of the first
  // message that appeared in the proto file; this is just to make extra
  // sure that the correct file was parsed.
  void ExpectGenerated(const string& generator_name,
                       const string& parameter,
                       const string& proto_name,
                       const string& message_name);
  void ExpectGenerated(const string& generator_name,
                       const string& parameter,
                       const string& proto_name,
                       const string& message_name,
                       const string& output_directory);
  void ExpectGeneratedWithMultipleInputs(const string& generator_name,
                                         const string& all_proto_names,
                                         const string& proto_name,
                                         const string& message_name);
  void ExpectGeneratedWithInsertions(const string& generator_name,
                                     const string& parameter,
                                     const string& insertions,
                                     const string& proto_name,
                                     const string& message_name);

  void ExpectNullCodeGeneratorCalled(const string& parameter);

  void ReadDescriptorSet(const string& filename,
                         FileDescriptorSet* descriptor_set);

 private:
  // The object we are testing.
  CommandLineInterface cli_;

  // Was DisallowPlugins() called?
  bool disallow_plugins_;

  // We create a directory within TestTempDir() in order to add extra
  // protection against accidentally deleting user files (since we recursively
  // delete this directory during the test).  This is the full path of that
  // directory.
  string temp_directory_;

  // The result of Run().
  int return_code_;

  // The captured stderr output.
  string error_text_;

  // Pointers which need to be deleted later.
  vector<CodeGenerator*> mock_generators_to_delete_;

  NullCodeGenerator* null_generator_;
};

class CommandLineInterfaceTest::NullCodeGenerator : public CodeGenerator {
 public:
  NullCodeGenerator() : called_(false) {}
  ~NullCodeGenerator() {}

  mutable bool called_;
  mutable string parameter_;

  // implements CodeGenerator ----------------------------------------
  bool Generate(const FileDescriptor* file,
                const string& parameter,
                GeneratorContext* context,
                string* error) const {
    called_ = true;
    parameter_ = parameter;
    return true;
  }
};

// ===================================================================

void CommandLineInterfaceTest::SetUp() {
  // Most of these tests were written before this option was added, so we
  // run with the option on (which used to be the only way) except in certain
  // tests where we turn it off.
  cli_.SetInputsAreProtoPathRelative(true);

  temp_directory_ = TestTempDir() + "/proto2_cli_test_temp";

  // If the temp directory already exists, it must be left over from a
  // previous run.  Delete it.
  if (File::Exists(temp_directory_)) {
    File::DeleteRecursively(temp_directory_, NULL, NULL);
  }

  // Create the temp directory.
  GOOGLE_CHECK(File::CreateDir(temp_directory_.c_str(), DEFAULT_FILE_MODE));

  // Register generators.
  CodeGenerator* generator = new MockCodeGenerator("test_generator");
  mock_generators_to_delete_.push_back(generator);
  cli_.RegisterGenerator("--test_out", "--test_opt", generator, "Test output.");
  cli_.RegisterGenerator("-t", generator, "Test output.");

  generator = new MockCodeGenerator("alt_generator");
  mock_generators_to_delete_.push_back(generator);
  cli_.RegisterGenerator("--alt_out", generator, "Alt output.");

  generator = null_generator_ = new NullCodeGenerator();
  mock_generators_to_delete_.push_back(generator);
  cli_.RegisterGenerator("--null_out", generator, "Null output.");

  disallow_plugins_ = false;
}

void CommandLineInterfaceTest::TearDown() {
  // Delete the temp directory.
  File::DeleteRecursively(temp_directory_, NULL, NULL);

  // Delete all the MockCodeGenerators.
  for (int i = 0; i < mock_generators_to_delete_.size(); i++) {
    delete mock_generators_to_delete_[i];
  }
  mock_generators_to_delete_.clear();
}

void CommandLineInterfaceTest::Run(const string& command) {
  vector<string> args;
  SplitStringUsing(command, " ", &args);

  if (!disallow_plugins_) {
    cli_.AllowPlugins("prefix-");
    const char* possible_paths[] = {
      // When building with shared libraries, libtool hides the real executable
      // in .libs and puts a fake wrapper in the current directory.
      // Unfortunately, due to an apparent bug on Cygwin/MinGW, if one program
      // wrapped in this way (e.g. protobuf-tests.exe) tries to execute another
      // program wrapped in this way (e.g. test_plugin.exe), the latter fails
      // with error code 127 and no explanation message.  Presumably the problem
      // is that the wrapper for protobuf-tests.exe set some environment
      // variables that confuse the wrapper for test_plugin.exe.  Luckily, it
      // turns out that if we simply invoke the wrapped test_plugin.exe
      // directly, it works -- I guess the environment variables set by the
      // protobuf-tests.exe wrapper happen to be correct for it too.  So we do
      // that.
      ".libs/test_plugin.exe",  // Win32 w/autotool (Cygwin / MinGW)
      "test_plugin.exe",        // Other Win32 (MSVC)
      "test_plugin",            // Unix
    };

    string plugin_path;

    for (int i = 0; i < GOOGLE_ARRAYSIZE(possible_paths); i++) {
      if (access(possible_paths[i], F_OK) == 0) {
        plugin_path = possible_paths[i];
        break;
      }
    }

    if (plugin_path.empty()) {
      GOOGLE_LOG(ERROR)
          << "Plugin executable not found.  Plugin tests are likely to fail.";
    } else {
      args.push_back("--plugin=prefix-gen-plug=" + plugin_path);
    }
  }

  scoped_array<const char*> argv(new const char*[args.size()]);

  for (int i = 0; i < args.size(); i++) {
    args[i] = StringReplace(args[i], "$tmpdir", temp_directory_, true);
    argv[i] = args[i].c_str();
  }

  CaptureTestStderr();

  return_code_ = cli_.Run(args.size(), argv.get());

  error_text_ = GetCapturedTestStderr();
}

// -------------------------------------------------------------------

void CommandLineInterfaceTest::CreateTempFile(
    const string& name,
    const string& contents) {
  // Create parent directory, if necessary.
  string::size_type slash_pos = name.find_last_of('/');
  if (slash_pos != string::npos) {
    string dir = name.substr(0, slash_pos);
    File::RecursivelyCreateDir(temp_directory_ + "/" + dir, 0777);
  }

  // Write file.
  string full_name = temp_directory_ + "/" + name;
  File::WriteStringToFileOrDie(contents, full_name);
}

void CommandLineInterfaceTest::CreateTempDir(const string& name) {
  File::RecursivelyCreateDir(temp_directory_ + "/" + name, 0777);
}

// -------------------------------------------------------------------

void CommandLineInterfaceTest::ExpectNoErrors() {
  EXPECT_EQ(0, return_code_);
  EXPECT_EQ("", error_text_);
}

void CommandLineInterfaceTest::ExpectErrorText(const string& expected_text) {
  EXPECT_NE(0, return_code_);
  EXPECT_EQ(StringReplace(expected_text, "$tmpdir", temp_directory_, true),
            error_text_);
}

void CommandLineInterfaceTest::ExpectErrorSubstring(
    const string& expected_substring) {
  EXPECT_NE(0, return_code_);
  EXPECT_PRED_FORMAT2(testing::IsSubstring, expected_substring, error_text_);
}

void CommandLineInterfaceTest::ExpectErrorSubstringWithZeroReturnCode(
    const string& expected_substring) {
  EXPECT_EQ(0, return_code_);
  EXPECT_PRED_FORMAT2(testing::IsSubstring, expected_substring, error_text_);
}

bool CommandLineInterfaceTest::HasAlternateErrorSubstring(
    const string& expected_substring) {
  EXPECT_NE(0, return_code_);
  return error_text_.find(expected_substring) != string::npos;
}

void CommandLineInterfaceTest::ExpectGenerated(
    const string& generator_name,
    const string& parameter,
    const string& proto_name,
    const string& message_name) {
  MockCodeGenerator::ExpectGenerated(
      generator_name, parameter, "", proto_name, message_name, proto_name,
      temp_directory_);
}

void CommandLineInterfaceTest::ExpectGenerated(
    const string& generator_name,
    const string& parameter,
    const string& proto_name,
    const string& message_name,
    const string& output_directory) {
  MockCodeGenerator::ExpectGenerated(
      generator_name, parameter, "", proto_name, message_name, proto_name,
      temp_directory_ + "/" + output_directory);
}

void CommandLineInterfaceTest::ExpectGeneratedWithMultipleInputs(
    const string& generator_name,
    const string& all_proto_names,
    const string& proto_name,
    const string& message_name) {
  MockCodeGenerator::ExpectGenerated(
      generator_name, "", "", proto_name, message_name,
      all_proto_names,
      temp_directory_);
}

void CommandLineInterfaceTest::ExpectGeneratedWithInsertions(
    const string& generator_name,
    const string& parameter,
    const string& insertions,
    const string& proto_name,
    const string& message_name) {
  MockCodeGenerator::ExpectGenerated(
      generator_name, parameter, insertions, proto_name, message_name,
      proto_name, temp_directory_);
}

void CommandLineInterfaceTest::ExpectNullCodeGeneratorCalled(
    const string& parameter) {
  EXPECT_TRUE(null_generator_->called_);
  EXPECT_EQ(parameter, null_generator_->parameter_);
}

void CommandLineInterfaceTest::ReadDescriptorSet(
    const string& filename, FileDescriptorSet* descriptor_set) {
  string path = temp_directory_ + "/" + filename;
  string file_contents;
  if (!File::ReadFileToString(path, &file_contents)) {
    FAIL() << "File not found: " << path;
  }
  if (!descriptor_set->ParseFromString(file_contents)) {
    FAIL() << "Could not parse file contents: " << path;
  }
}

// ===================================================================

TEST_F(CommandLineInterfaceTest, BasicOutput) {
  // Test that the common case works.

  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "message Foo {}\n");

  Run("protocol_compiler --test_out=$tmpdir "
      "--proto_path=$tmpdir foo.proto");

  ExpectNoErrors();
  ExpectGenerated("test_generator", "", "foo.proto", "Foo");
}

TEST_F(CommandLineInterfaceTest, BasicPlugin) {
  // Test that basic plugins work.

  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "message Foo {}\n");

  Run("protocol_compiler --plug_out=$tmpdir "
      "--proto_path=$tmpdir foo.proto");

  ExpectNoErrors();
  ExpectGenerated("test_plugin", "", "foo.proto", "Foo");
}

TEST_F(CommandLineInterfaceTest, GeneratorAndPlugin) {
  // Invoke a generator and a plugin at the same time.

  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "message Foo {}\n");

  Run("protocol_compiler --test_out=$tmpdir --plug_out=$tmpdir "
      "--proto_path=$tmpdir foo.proto");

  ExpectNoErrors();
  ExpectGenerated("test_generator", "", "foo.proto", "Foo");
  ExpectGenerated("test_plugin", "", "foo.proto", "Foo");
}

TEST_F(CommandLineInterfaceTest, MultipleInputs) {
  // Test parsing multiple input files.

  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "message Foo {}\n");
  CreateTempFile("bar.proto",
    "syntax = \"proto2\";\n"
    "message Bar {}\n");

  Run("protocol_compiler --test_out=$tmpdir --plug_out=$tmpdir "
      "--proto_path=$tmpdir foo.proto bar.proto");

  ExpectNoErrors();
  ExpectGeneratedWithMultipleInputs("test_generator", "foo.proto,bar.proto",
                                    "foo.proto", "Foo");
  ExpectGeneratedWithMultipleInputs("test_generator", "foo.proto,bar.proto",
                                    "bar.proto", "Bar");
  ExpectGeneratedWithMultipleInputs("test_plugin", "foo.proto,bar.proto",
                                    "foo.proto", "Foo");
  ExpectGeneratedWithMultipleInputs("test_plugin", "foo.proto,bar.proto",
                                    "bar.proto", "Bar");
}

TEST_F(CommandLineInterfaceTest, MultipleInputsWithImport) {
  // Test parsing multiple input files with an import of a separate file.

  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "message Foo {}\n");
  CreateTempFile("bar.proto",
    "syntax = \"proto2\";\n"
    "import \"baz.proto\";\n"
    "message Bar {\n"
    "  optional Baz a = 1;\n"
    "}\n");
  CreateTempFile("baz.proto",
    "syntax = \"proto2\";\n"
    "message Baz {}\n");

  Run("protocol_compiler --test_out=$tmpdir --plug_out=$tmpdir "
      "--proto_path=$tmpdir foo.proto bar.proto");

  ExpectNoErrors();
  ExpectGeneratedWithMultipleInputs("test_generator", "foo.proto,bar.proto",
                                    "foo.proto", "Foo");
  ExpectGeneratedWithMultipleInputs("test_generator", "foo.proto,bar.proto",
                                    "bar.proto", "Bar");
  ExpectGeneratedWithMultipleInputs("test_plugin", "foo.proto,bar.proto",
                                    "foo.proto", "Foo");
  ExpectGeneratedWithMultipleInputs("test_plugin", "foo.proto,bar.proto",
                                    "bar.proto", "Bar");
}

TEST_F(CommandLineInterfaceTest, CreateDirectory) {
  // Test that when we output to a sub-directory, it is created.

  CreateTempFile("bar/baz/foo.proto",
    "syntax = \"proto2\";\n"
    "message Foo {}\n");
  CreateTempDir("out");
  CreateTempDir("plugout");

  Run("protocol_compiler --test_out=$tmpdir/out --plug_out=$tmpdir/plugout "
      "--proto_path=$tmpdir bar/baz/foo.proto");

  ExpectNoErrors();
  ExpectGenerated("test_generator", "", "bar/baz/foo.proto", "Foo", "out");
  ExpectGenerated("test_plugin", "", "bar/baz/foo.proto", "Foo", "plugout");
}

TEST_F(CommandLineInterfaceTest, GeneratorParameters) {
  // Test that generator parameters are correctly parsed from the command line.

  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "message Foo {}\n");

  Run("protocol_compiler --test_out=TestParameter:$tmpdir "
      "--plug_out=TestPluginParameter:$tmpdir "
      "--proto_path=$tmpdir foo.proto");

  ExpectNoErrors();
  ExpectGenerated("test_generator", "TestParameter", "foo.proto", "Foo");
  ExpectGenerated("test_plugin", "TestPluginParameter", "foo.proto", "Foo");
}

TEST_F(CommandLineInterfaceTest, ExtraGeneratorParameters) {
  // Test that generator parameters specified with the option flag are
  // correctly passed to the code generator.

  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "message Foo {}\n");
  // Create the "a" and "b" sub-directories.
  CreateTempDir("a");
  CreateTempDir("b");

  Run("protocol_compiler "
      "--test_opt=foo1 "
      "--test_out=bar:$tmpdir/a "
      "--test_opt=foo2 "
      "--test_out=baz:$tmpdir/b "
      "--test_opt=foo3 "
      "--proto_path=$tmpdir foo.proto");

  ExpectNoErrors();
  ExpectGenerated(
      "test_generator", "bar,foo1,foo2,foo3", "foo.proto", "Foo", "a");
  ExpectGenerated(
      "test_generator", "baz,foo1,foo2,foo3", "foo.proto", "Foo", "b");
}

TEST_F(CommandLineInterfaceTest, Insert) {
  // Test running a generator that inserts code into another's output.

  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "message Foo {}\n");

  Run("protocol_compiler "
      "--test_out=TestParameter:$tmpdir "
      "--plug_out=TestPluginParameter:$tmpdir "
      "--test_out=insert=test_generator,test_plugin:$tmpdir "
      "--plug_out=insert=test_generator,test_plugin:$tmpdir "
      "--proto_path=$tmpdir foo.proto");

  ExpectNoErrors();
  ExpectGeneratedWithInsertions(
      "test_generator", "TestParameter", "test_generator,test_plugin",
      "foo.proto", "Foo");
  ExpectGeneratedWithInsertions(
      "test_plugin", "TestPluginParameter", "test_generator,test_plugin",
      "foo.proto", "Foo");
}

#if defined(_WIN32)

TEST_F(CommandLineInterfaceTest, WindowsOutputPath) {
  // Test that the output path can be a Windows-style path.

  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n");

  Run("protocol_compiler --null_out=C:\\ "
      "--proto_path=$tmpdir foo.proto");

  ExpectNoErrors();
  ExpectNullCodeGeneratorCalled("");
}

TEST_F(CommandLineInterfaceTest, WindowsOutputPathAndParameter) {
  // Test that we can have a windows-style output path and a parameter.

  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n");

  Run("protocol_compiler --null_out=bar:C:\\ "
      "--proto_path=$tmpdir foo.proto");

  ExpectNoErrors();
  ExpectNullCodeGeneratorCalled("bar");
}

TEST_F(CommandLineInterfaceTest, TrailingBackslash) {
  // Test that the directories can end in backslashes.  Some users claim this
  // doesn't work on their system.

  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "message Foo {}\n");

  Run("protocol_compiler --test_out=$tmpdir\\ "
      "--proto_path=$tmpdir\\ foo.proto");

  ExpectNoErrors();
  ExpectGenerated("test_generator", "", "foo.proto", "Foo");
}

#endif  // defined(_WIN32) || defined(__CYGWIN__)

TEST_F(CommandLineInterfaceTest, PathLookup) {
  // Test that specifying multiple directories in the proto search path works.

  CreateTempFile("b/bar.proto",
    "syntax = \"proto2\";\n"
    "message Bar {}\n");
  CreateTempFile("a/foo.proto",
    "syntax = \"proto2\";\n"
    "import \"bar.proto\";\n"
    "message Foo {\n"
    "  optional Bar a = 1;\n"
    "}\n");
  CreateTempFile("b/foo.proto", "this should not be parsed\n");

  Run("protocol_compiler --test_out=$tmpdir "
      "--proto_path=$tmpdir/a --proto_path=$tmpdir/b foo.proto");

  ExpectNoErrors();
  ExpectGenerated("test_generator", "", "foo.proto", "Foo");
}

TEST_F(CommandLineInterfaceTest, ColonDelimitedPath) {
  // Same as PathLookup, but we provide the proto_path in a single flag.

  CreateTempFile("b/bar.proto",
    "syntax = \"proto2\";\n"
    "message Bar {}\n");
  CreateTempFile("a/foo.proto",
    "syntax = \"proto2\";\n"
    "import \"bar.proto\";\n"
    "message Foo {\n"
    "  optional Bar a = 1;\n"
    "}\n");
  CreateTempFile("b/foo.proto", "this should not be parsed\n");

#undef PATH_SEPARATOR
#if defined(_WIN32)
#define PATH_SEPARATOR ";"
#else
#define PATH_SEPARATOR ":"
#endif

  Run("protocol_compiler --test_out=$tmpdir "
      "--proto_path=$tmpdir/a"PATH_SEPARATOR"$tmpdir/b foo.proto");

#undef PATH_SEPARATOR

  ExpectNoErrors();
  ExpectGenerated("test_generator", "", "foo.proto", "Foo");
}

TEST_F(CommandLineInterfaceTest, NonRootMapping) {
  // Test setting up a search path mapping a directory to a non-root location.

  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "message Foo {}\n");

  Run("protocol_compiler --test_out=$tmpdir "
      "--proto_path=bar=$tmpdir bar/foo.proto");

  ExpectNoErrors();
  ExpectGenerated("test_generator", "", "bar/foo.proto", "Foo");
}

TEST_F(CommandLineInterfaceTest, MultipleGenerators) {
  // Test that we can have multiple generators and use both in one invocation,
  // each with a different output directory.

  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "message Foo {}\n");
  // Create the "a" and "b" sub-directories.
  CreateTempDir("a");
  CreateTempDir("b");

  Run("protocol_compiler "
      "--test_out=$tmpdir/a "
      "--alt_out=$tmpdir/b "
      "--proto_path=$tmpdir foo.proto");

  ExpectNoErrors();
  ExpectGenerated("test_generator", "", "foo.proto", "Foo", "a");
  ExpectGenerated("alt_generator", "", "foo.proto", "Foo", "b");
}

TEST_F(CommandLineInterfaceTest, DisallowServicesNoServices) {
  // Test that --disallow_services doesn't cause a problem when there are no
  // services.

  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "message Foo {}\n");

  Run("protocol_compiler --disallow_services --test_out=$tmpdir "
      "--proto_path=$tmpdir foo.proto");

  ExpectNoErrors();
  ExpectGenerated("test_generator", "", "foo.proto", "Foo");
}

TEST_F(CommandLineInterfaceTest, DisallowServicesHasService) {
  // Test that --disallow_services produces an error when there are services.

  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "message Foo {}\n"
    "service Bar {}\n");

  Run("protocol_compiler --disallow_services --test_out=$tmpdir "
      "--proto_path=$tmpdir foo.proto");

  ExpectErrorSubstring("foo.proto: This file contains services");
}

TEST_F(CommandLineInterfaceTest, AllowServicesHasService) {
  // Test that services work fine as long as --disallow_services is not used.

  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "message Foo {}\n"
    "service Bar {}\n");

  Run("protocol_compiler --test_out=$tmpdir "
      "--proto_path=$tmpdir foo.proto");

  ExpectNoErrors();
  ExpectGenerated("test_generator", "", "foo.proto", "Foo");
}

TEST_F(CommandLineInterfaceTest, CwdRelativeInputs) {
  // Test that we can accept working-directory-relative input files.

  SetInputsAreProtoPathRelative(false);

  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "message Foo {}\n");

  Run("protocol_compiler --test_out=$tmpdir "
      "--proto_path=$tmpdir $tmpdir/foo.proto");

  ExpectNoErrors();
  ExpectGenerated("test_generator", "", "foo.proto", "Foo");
}

TEST_F(CommandLineInterfaceTest, WriteDescriptorSet) {
  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "message Foo {}\n");
  CreateTempFile("bar.proto",
    "syntax = \"proto2\";\n"
    "import \"foo.proto\";\n"
    "message Bar {\n"
    "  optional Foo foo = 1;\n"
    "}\n");

  Run("protocol_compiler --descriptor_set_out=$tmpdir/descriptor_set "
      "--proto_path=$tmpdir bar.proto");

  ExpectNoErrors();

  FileDescriptorSet descriptor_set;
  ReadDescriptorSet("descriptor_set", &descriptor_set);
  if (HasFatalFailure()) return;
  ASSERT_EQ(1, descriptor_set.file_size());
  EXPECT_EQ("bar.proto", descriptor_set.file(0).name());
  // Descriptor set should not have source code info.
  EXPECT_FALSE(descriptor_set.file(0).has_source_code_info());
}

TEST_F(CommandLineInterfaceTest, WriteDescriptorSetWithSourceInfo) {
  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "message Foo {}\n");
  CreateTempFile("bar.proto",
    "syntax = \"proto2\";\n"
    "import \"foo.proto\";\n"
    "message Bar {\n"
    "  optional Foo foo = 1;\n"
    "}\n");

  Run("protocol_compiler --descriptor_set_out=$tmpdir/descriptor_set "
      "--include_source_info --proto_path=$tmpdir bar.proto");

  ExpectNoErrors();

  FileDescriptorSet descriptor_set;
  ReadDescriptorSet("descriptor_set", &descriptor_set);
  if (HasFatalFailure()) return;
  ASSERT_EQ(1, descriptor_set.file_size());
  EXPECT_EQ("bar.proto", descriptor_set.file(0).name());
  // Source code info included.
  EXPECT_TRUE(descriptor_set.file(0).has_source_code_info());
}

TEST_F(CommandLineInterfaceTest, WriteTransitiveDescriptorSet) {
  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "message Foo {}\n");
  CreateTempFile("bar.proto",
    "syntax = \"proto2\";\n"
    "import \"foo.proto\";\n"
    "message Bar {\n"
    "  optional Foo foo = 1;\n"
    "}\n");

  Run("protocol_compiler --descriptor_set_out=$tmpdir/descriptor_set "
      "--include_imports --proto_path=$tmpdir bar.proto");

  ExpectNoErrors();

  FileDescriptorSet descriptor_set;
  ReadDescriptorSet("descriptor_set", &descriptor_set);
  if (HasFatalFailure()) return;
  ASSERT_EQ(2, descriptor_set.file_size());
  if (descriptor_set.file(0).name() == "bar.proto") {
    std::swap(descriptor_set.mutable_file()->mutable_data()[0],
              descriptor_set.mutable_file()->mutable_data()[1]);
  }
  EXPECT_EQ("foo.proto", descriptor_set.file(0).name());
  EXPECT_EQ("bar.proto", descriptor_set.file(1).name());
  // Descriptor set should not have source code info.
  EXPECT_FALSE(descriptor_set.file(0).has_source_code_info());
  EXPECT_FALSE(descriptor_set.file(1).has_source_code_info());
}

TEST_F(CommandLineInterfaceTest, WriteTransitiveDescriptorSetWithSourceInfo) {
  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "message Foo {}\n");
  CreateTempFile("bar.proto",
    "syntax = \"proto2\";\n"
    "import \"foo.proto\";\n"
    "message Bar {\n"
    "  optional Foo foo = 1;\n"
    "}\n");

  Run("protocol_compiler --descriptor_set_out=$tmpdir/descriptor_set "
      "--include_imports --include_source_info --proto_path=$tmpdir bar.proto");

  ExpectNoErrors();

  FileDescriptorSet descriptor_set;
  ReadDescriptorSet("descriptor_set", &descriptor_set);
  if (HasFatalFailure()) return;
  ASSERT_EQ(2, descriptor_set.file_size());
  if (descriptor_set.file(0).name() == "bar.proto") {
    std::swap(descriptor_set.mutable_file()->mutable_data()[0],
              descriptor_set.mutable_file()->mutable_data()[1]);
  }
  EXPECT_EQ("foo.proto", descriptor_set.file(0).name());
  EXPECT_EQ("bar.proto", descriptor_set.file(1).name());
  // Source code info included.
  EXPECT_TRUE(descriptor_set.file(0).has_source_code_info());
  EXPECT_TRUE(descriptor_set.file(1).has_source_code_info());
}

// -------------------------------------------------------------------

TEST_F(CommandLineInterfaceTest, ParseErrors) {
  // Test that parse errors are reported.

  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "badsyntax\n");

  Run("protocol_compiler --test_out=$tmpdir "
      "--proto_path=$tmpdir foo.proto");

  ExpectErrorText(
    "foo.proto:2:1: Expected top-level statement (e.g. \"message\").\n");
}

TEST_F(CommandLineInterfaceTest, ParseErrorsMultipleFiles) {
  // Test that parse errors are reported from multiple files.

  // We set up files such that foo.proto actually depends on bar.proto in
  // two ways:  Directly and through baz.proto.  bar.proto's errors should
  // only be reported once.
  CreateTempFile("bar.proto",
    "syntax = \"proto2\";\n"
    "badsyntax\n");
  CreateTempFile("baz.proto",
    "syntax = \"proto2\";\n"
    "import \"bar.proto\";\n");
  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "import \"bar.proto\";\n"
    "import \"baz.proto\";\n");

  Run("protocol_compiler --test_out=$tmpdir "
      "--proto_path=$tmpdir foo.proto");

  ExpectErrorText(
    "bar.proto:2:1: Expected top-level statement (e.g. \"message\").\n"
    "baz.proto: Import \"bar.proto\" was not found or had errors.\n"
    "foo.proto: Import \"bar.proto\" was not found or had errors.\n"
    "foo.proto: Import \"baz.proto\" was not found or had errors.\n");
}

TEST_F(CommandLineInterfaceTest, InputNotFoundError) {
  // Test what happens if the input file is not found.

  Run("protocol_compiler --test_out=$tmpdir "
      "--proto_path=$tmpdir foo.proto");

  ExpectErrorText(
    "foo.proto: File not found.\n");
}

TEST_F(CommandLineInterfaceTest, CwdRelativeInputNotFoundError) {
  // Test what happens when a working-directory-relative input file is not
  // found.

  SetInputsAreProtoPathRelative(false);

  Run("protocol_compiler --test_out=$tmpdir "
      "--proto_path=$tmpdir $tmpdir/foo.proto");

  ExpectErrorText(
    "$tmpdir/foo.proto: No such file or directory\n");
}

TEST_F(CommandLineInterfaceTest, CwdRelativeInputNotMappedError) {
  // Test what happens when a working-directory-relative input file is not
  // mapped to a virtual path.

  SetInputsAreProtoPathRelative(false);

  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "message Foo {}\n");

  // Create a directory called "bar" so that we can point --proto_path at it.
  CreateTempFile("bar/dummy", "");

  Run("protocol_compiler --test_out=$tmpdir "
      "--proto_path=$tmpdir/bar $tmpdir/foo.proto");

  ExpectErrorText(
    "$tmpdir/foo.proto: File does not reside within any path "
      "specified using --proto_path (or -I).  You must specify a "
      "--proto_path which encompasses this file.  Note that the "
      "proto_path must be an exact prefix of the .proto file "
      "names -- protoc is too dumb to figure out when two paths "
      "(e.g. absolute and relative) are equivalent (it's harder "
      "than you think).\n");
}

TEST_F(CommandLineInterfaceTest, CwdRelativeInputNotFoundAndNotMappedError) {
  // Check what happens if the input file is not found *and* is not mapped
  // in the proto_path.

  SetInputsAreProtoPathRelative(false);

  // Create a directory called "bar" so that we can point --proto_path at it.
  CreateTempFile("bar/dummy", "");

  Run("protocol_compiler --test_out=$tmpdir "
      "--proto_path=$tmpdir/bar $tmpdir/foo.proto");

  ExpectErrorText(
    "$tmpdir/foo.proto: No such file or directory\n");
}

TEST_F(CommandLineInterfaceTest, CwdRelativeInputShadowedError) {
  // Test what happens when a working-directory-relative input file is shadowed
  // by another file in the virtual path.

  SetInputsAreProtoPathRelative(false);

  CreateTempFile("foo/foo.proto",
    "syntax = \"proto2\";\n"
    "message Foo {}\n");
  CreateTempFile("bar/foo.proto",
    "syntax = \"proto2\";\n"
    "message Bar {}\n");

  Run("protocol_compiler --test_out=$tmpdir "
      "--proto_path=$tmpdir/foo --proto_path=$tmpdir/bar "
      "$tmpdir/bar/foo.proto");

  ExpectErrorText(
    "$tmpdir/bar/foo.proto: Input is shadowed in the --proto_path "
    "by \"$tmpdir/foo/foo.proto\".  Either use the latter "
    "file as your input or reorder the --proto_path so that the "
    "former file's location comes first.\n");
}

TEST_F(CommandLineInterfaceTest, ProtoPathNotFoundError) {
  // Test what happens if the input file is not found.

  Run("protocol_compiler --test_out=$tmpdir "
      "--proto_path=$tmpdir/foo foo.proto");

  ExpectErrorText(
    "$tmpdir/foo: warning: directory does not exist.\n"
    "foo.proto: File not found.\n");
}

TEST_F(CommandLineInterfaceTest, MissingInputError) {
  // Test that we get an error if no inputs are given.

  Run("protocol_compiler --test_out=$tmpdir "
      "--proto_path=$tmpdir");

  ExpectErrorText("Missing input file.\n");
}

TEST_F(CommandLineInterfaceTest, MissingOutputError) {
  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "message Foo {}\n");

  Run("protocol_compiler --proto_path=$tmpdir foo.proto");

  ExpectErrorText("Missing output directives.\n");
}

TEST_F(CommandLineInterfaceTest, OutputWriteError) {
  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "message Foo {}\n");

  string output_file =
      MockCodeGenerator::GetOutputFileName("test_generator", "foo.proto");

  // Create a directory blocking our output location.
  CreateTempDir(output_file);

  Run("protocol_compiler --test_out=$tmpdir "
      "--proto_path=$tmpdir foo.proto");

  // MockCodeGenerator no longer detects an error because we actually write to
  // an in-memory location first, then dump to disk at the end.  This is no
  // big deal.
  //   ExpectErrorSubstring("MockCodeGenerator detected write error.");

#if defined(_WIN32) && !defined(__CYGWIN__)
  // Windows with MSVCRT.dll produces EPERM instead of EISDIR.
  if (HasAlternateErrorSubstring(output_file + ": Permission denied")) {
    return;
  }
#endif

  ExpectErrorSubstring(output_file + ": Is a directory");
}

TEST_F(CommandLineInterfaceTest, PluginOutputWriteError) {
  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "message Foo {}\n");

  string output_file =
      MockCodeGenerator::GetOutputFileName("test_plugin", "foo.proto");

  // Create a directory blocking our output location.
  CreateTempDir(output_file);

  Run("protocol_compiler --plug_out=$tmpdir "
      "--proto_path=$tmpdir foo.proto");

#if defined(_WIN32) && !defined(__CYGWIN__)
  // Windows with MSVCRT.dll produces EPERM instead of EISDIR.
  if (HasAlternateErrorSubstring(output_file + ": Permission denied")) {
    return;
  }
#endif

  ExpectErrorSubstring(output_file + ": Is a directory");
}

TEST_F(CommandLineInterfaceTest, OutputDirectoryNotFoundError) {
  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "message Foo {}\n");

  Run("protocol_compiler --test_out=$tmpdir/nosuchdir "
      "--proto_path=$tmpdir foo.proto");

  ExpectErrorSubstring("nosuchdir/: No such file or directory");
}

TEST_F(CommandLineInterfaceTest, PluginOutputDirectoryNotFoundError) {
  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "message Foo {}\n");

  Run("protocol_compiler --plug_out=$tmpdir/nosuchdir "
      "--proto_path=$tmpdir foo.proto");

  ExpectErrorSubstring("nosuchdir/: No such file or directory");
}

TEST_F(CommandLineInterfaceTest, OutputDirectoryIsFileError) {
  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "message Foo {}\n");

  Run("protocol_compiler --test_out=$tmpdir/foo.proto "
      "--proto_path=$tmpdir foo.proto");

#if defined(_WIN32) && !defined(__CYGWIN__)
  // Windows with MSVCRT.dll produces EINVAL instead of ENOTDIR.
  if (HasAlternateErrorSubstring("foo.proto/: Invalid argument")) {
    return;
  }
#endif

  ExpectErrorSubstring("foo.proto/: Not a directory");
}

TEST_F(CommandLineInterfaceTest, GeneratorError) {
  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "message MockCodeGenerator_Error {}\n");

  Run("protocol_compiler --test_out=$tmpdir "
      "--proto_path=$tmpdir foo.proto");

  ExpectErrorSubstring(
      "--test_out: foo.proto: Saw message type MockCodeGenerator_Error.");
}

TEST_F(CommandLineInterfaceTest, GeneratorPluginError) {
  // Test a generator plugin that returns an error.

  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "message MockCodeGenerator_Error {}\n");

  Run("protocol_compiler --plug_out=TestParameter:$tmpdir "
      "--proto_path=$tmpdir foo.proto");

  ExpectErrorSubstring(
      "--plug_out: foo.proto: Saw message type MockCodeGenerator_Error.");
}

TEST_F(CommandLineInterfaceTest, GeneratorPluginFail) {
  // Test a generator plugin that exits with an error code.

  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "message MockCodeGenerator_Exit {}\n");

  Run("protocol_compiler --plug_out=TestParameter:$tmpdir "
      "--proto_path=$tmpdir foo.proto");

  ExpectErrorSubstring("Saw message type MockCodeGenerator_Exit.");
  ExpectErrorSubstring(
      "--plug_out: prefix-gen-plug: Plugin failed with status code 123.");
}

TEST_F(CommandLineInterfaceTest, GeneratorPluginCrash) {
  // Test a generator plugin that crashes.

  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "message MockCodeGenerator_Abort {}\n");

  Run("protocol_compiler --plug_out=TestParameter:$tmpdir "
      "--proto_path=$tmpdir foo.proto");

  ExpectErrorSubstring("Saw message type MockCodeGenerator_Abort.");

#ifdef _WIN32
  // Windows doesn't have signals.  It looks like abort()ing causes the process
  // to exit with status code 3, but let's not depend on the exact number here.
  ExpectErrorSubstring(
      "--plug_out: prefix-gen-plug: Plugin failed with status code");
#else
  // Don't depend on the exact signal number.
  ExpectErrorSubstring(
      "--plug_out: prefix-gen-plug: Plugin killed by signal");
#endif
}

TEST_F(CommandLineInterfaceTest, PluginReceivesSourceCodeInfo) {
  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "message MockCodeGenerator_HasSourceCodeInfo {}\n");

  Run("protocol_compiler --plug_out=$tmpdir --proto_path=$tmpdir foo.proto");

  ExpectErrorSubstring(
      "Saw message type MockCodeGenerator_HasSourceCodeInfo: 1.");
}

TEST_F(CommandLineInterfaceTest, GeneratorPluginNotFound) {
  // Test what happens if the plugin isn't found.

  CreateTempFile("error.proto",
    "syntax = \"proto2\";\n"
    "message Foo {}\n");

  Run("protocol_compiler --badplug_out=TestParameter:$tmpdir "
      "--plugin=prefix-gen-badplug=no_such_file "
      "--proto_path=$tmpdir error.proto");

#ifdef _WIN32
  ExpectErrorSubstring("--badplug_out: prefix-gen-badplug: " +
      Subprocess::Win32ErrorMessage(ERROR_FILE_NOT_FOUND));
#else
  // Error written to stdout by child process after exec() fails.
  ExpectErrorSubstring(
      "no_such_file: program not found or is not executable");

  // Error written by parent process when child fails.
  ExpectErrorSubstring(
      "--badplug_out: prefix-gen-badplug: Plugin failed with status code 1.");
#endif
}

TEST_F(CommandLineInterfaceTest, GeneratorPluginNotAllowed) {
  // Test what happens if plugins aren't allowed.

  CreateTempFile("error.proto",
    "syntax = \"proto2\";\n"
    "message Foo {}\n");

  DisallowPlugins();
  Run("protocol_compiler --plug_out=TestParameter:$tmpdir "
      "--proto_path=$tmpdir error.proto");

  ExpectErrorSubstring("Unknown flag: --plug_out");
}

TEST_F(CommandLineInterfaceTest, HelpText) {
  Run("test_exec_name --help");

  ExpectErrorSubstringWithZeroReturnCode("Usage: test_exec_name ");
  ExpectErrorSubstringWithZeroReturnCode("--test_out=OUT_DIR");
  ExpectErrorSubstringWithZeroReturnCode("Test output.");
  ExpectErrorSubstringWithZeroReturnCode("--alt_out=OUT_DIR");
  ExpectErrorSubstringWithZeroReturnCode("Alt output.");
}

TEST_F(CommandLineInterfaceTest, GccFormatErrors) {
  // Test --error_format=gcc (which is the default, but we want to verify
  // that it can be set explicitly).

  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "badsyntax\n");

  Run("protocol_compiler --test_out=$tmpdir "
      "--proto_path=$tmpdir --error_format=gcc foo.proto");

  ExpectErrorText(
    "foo.proto:2:1: Expected top-level statement (e.g. \"message\").\n");
}

TEST_F(CommandLineInterfaceTest, MsvsFormatErrors) {
  // Test --error_format=msvs

  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "badsyntax\n");

  Run("protocol_compiler --test_out=$tmpdir "
      "--proto_path=$tmpdir --error_format=msvs foo.proto");

  ExpectErrorText(
    "$tmpdir/foo.proto(2) : error in column=1: Expected top-level statement "
      "(e.g. \"message\").\n");
}

TEST_F(CommandLineInterfaceTest, InvalidErrorFormat) {
  // Test --error_format=msvs

  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "badsyntax\n");

  Run("protocol_compiler --test_out=$tmpdir "
      "--proto_path=$tmpdir --error_format=invalid foo.proto");

  ExpectErrorText(
    "Unknown error format: invalid\n");
}

// -------------------------------------------------------------------
// Flag parsing tests

TEST_F(CommandLineInterfaceTest, ParseSingleCharacterFlag) {
  // Test that a single-character flag works.

  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "message Foo {}\n");

  Run("protocol_compiler -t$tmpdir "
      "--proto_path=$tmpdir foo.proto");

  ExpectNoErrors();
  ExpectGenerated("test_generator", "", "foo.proto", "Foo");
}

TEST_F(CommandLineInterfaceTest, ParseSpaceDelimitedValue) {
  // Test that separating the flag value with a space works.

  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "message Foo {}\n");

  Run("protocol_compiler --test_out $tmpdir "
      "--proto_path=$tmpdir foo.proto");

  ExpectNoErrors();
  ExpectGenerated("test_generator", "", "foo.proto", "Foo");
}

TEST_F(CommandLineInterfaceTest, ParseSingleCharacterSpaceDelimitedValue) {
  // Test that separating the flag value with a space works for
  // single-character flags.

  CreateTempFile("foo.proto",
    "syntax = \"proto2\";\n"
    "message Foo {}\n");

  Run("protocol_compiler -t $tmpdir "
      "--proto_path=$tmpdir foo.proto");

  ExpectNoErrors();
  ExpectGenerated("test_generator", "", "foo.proto", "Foo");
}

TEST_F(CommandLineInterfaceTest, MissingValueError) {
  // Test that we get an error if a flag is missing its value.

  Run("protocol_compiler --test_out --proto_path=$tmpdir foo.proto");

  ExpectErrorText("Missing value for flag: --test_out\n");
}

TEST_F(CommandLineInterfaceTest, MissingValueAtEndError) {
  // Test that we get an error if the last argument is a flag requiring a
  // value.

  Run("protocol_compiler --test_out");

  ExpectErrorText("Missing value for flag: --test_out\n");
}

// ===================================================================

// Test for --encode and --decode.  Note that it would be easier to do this
// test as a shell script, but we'd like to be able to run the test on
// platforms that don't have a Bourne-compatible shell available (especially
// Windows/MSVC).
class EncodeDecodeTest : public testing::Test {
 protected:
  virtual void SetUp() {
    duped_stdin_ = dup(STDIN_FILENO);
  }

  virtual void TearDown() {
    dup2(duped_stdin_, STDIN_FILENO);
    close(duped_stdin_);
  }

  void RedirectStdinFromText(const string& input) {
    string filename = TestTempDir() + "/test_stdin";
    File::WriteStringToFileOrDie(input, filename);
    GOOGLE_CHECK(RedirectStdinFromFile(filename));
  }

  bool RedirectStdinFromFile(const string& filename) {
    int fd = open(filename.c_str(), O_RDONLY);
    if (fd < 0) return false;
    dup2(fd, STDIN_FILENO);
    close(fd);
    return true;
  }

  // Remove '\r' characters from text.
  string StripCR(const string& text) {
    string result;

    for (int i = 0; i < text.size(); i++) {
      if (text[i] != '\r') {
        result.push_back(text[i]);
      }
    }

    return result;
  }

  enum Type { TEXT, BINARY };
  enum ReturnCode { SUCCESS, ERROR };

  bool Run(const string& command) {
    vector<string> args;
    args.push_back("protoc");
    SplitStringUsing(command, " ", &args);
    args.push_back("--proto_path=" + TestSourceDir());

    scoped_array<const char*> argv(new const char*[args.size()]);
    for (int i = 0; i < args.size(); i++) {
      argv[i] = args[i].c_str();
    }

    CommandLineInterface cli;
    cli.SetInputsAreProtoPathRelative(true);

    CaptureTestStdout();
    CaptureTestStderr();

    int result = cli.Run(args.size(), argv.get());

    captured_stdout_ = GetCapturedTestStdout();
    captured_stderr_ = GetCapturedTestStderr();

    return result == 0;
  }

  void ExpectStdoutMatchesBinaryFile(const string& filename) {
    string expected_output;
    ASSERT_TRUE(File::ReadFileToString(filename, &expected_output));

    // Don't use EXPECT_EQ because we don't want to print raw binary data to
    // stdout on failure.
    EXPECT_TRUE(captured_stdout_ == expected_output);
  }

  void ExpectStdoutMatchesTextFile(const string& filename) {
    string expected_output;
    ASSERT_TRUE(File::ReadFileToString(filename, &expected_output));

    ExpectStdoutMatchesText(expected_output);
  }

  void ExpectStdoutMatchesText(const string& expected_text) {
    EXPECT_EQ(StripCR(expected_text), StripCR(captured_stdout_));
  }

  void ExpectStderrMatchesText(const string& expected_text) {
    EXPECT_EQ(StripCR(expected_text), StripCR(captured_stderr_));
  }

 private:
  int duped_stdin_;
  string captured_stdout_;
  string captured_stderr_;
};

TEST_F(EncodeDecodeTest, Encode) {
  RedirectStdinFromFile(TestSourceDir() +
    "/google/protobuf/testdata/text_format_unittest_data.txt");
  EXPECT_TRUE(Run("google/protobuf/unittest.proto "
                  "--encode=protobuf_unittest.TestAllTypes"));
  ExpectStdoutMatchesBinaryFile(TestSourceDir() +
    "/google/protobuf/testdata/golden_message");
  ExpectStderrMatchesText("");
}

TEST_F(EncodeDecodeTest, Decode) {
  RedirectStdinFromFile(TestSourceDir() +
    "/google/protobuf/testdata/golden_message");
  EXPECT_TRUE(Run("google/protobuf/unittest.proto "
                  "--decode=protobuf_unittest.TestAllTypes"));
  ExpectStdoutMatchesTextFile(TestSourceDir() +
    "/google/protobuf/testdata/text_format_unittest_data.txt");
  ExpectStderrMatchesText("");
}

TEST_F(EncodeDecodeTest, Partial) {
  RedirectStdinFromText("");
  EXPECT_TRUE(Run("google/protobuf/unittest.proto "
                  "--encode=protobuf_unittest.TestRequired"));
  ExpectStdoutMatchesText("");
  ExpectStderrMatchesText(
    "warning:  Input message is missing required fields:  a, b, c\n");
}

TEST_F(EncodeDecodeTest, DecodeRaw) {
  protobuf_unittest::TestAllTypes message;
  message.set_optional_int32(123);
  message.set_optional_string("foo");
  string data;
  message.SerializeToString(&data);

  RedirectStdinFromText(data);
  EXPECT_TRUE(Run("--decode_raw"));
  ExpectStdoutMatchesText("1: 123\n"
                          "14: \"foo\"\n");
  ExpectStderrMatchesText("");
}

TEST_F(EncodeDecodeTest, UnknownType) {
  EXPECT_FALSE(Run("google/protobuf/unittest.proto "
                   "--encode=NoSuchType"));
  ExpectStdoutMatchesText("");
  ExpectStderrMatchesText("Type not defined: NoSuchType\n");
}

TEST_F(EncodeDecodeTest, ProtoParseError) {
  EXPECT_FALSE(Run("google/protobuf/no_such_file.proto "
                   "--encode=NoSuchType"));
  ExpectStdoutMatchesText("");
  ExpectStderrMatchesText(
    "google/protobuf/no_such_file.proto: File not found.\n");
}

}  // anonymous namespace

}  // namespace compiler
}  // namespace protobuf
}  // namespace google
