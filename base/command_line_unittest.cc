// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <string>
#include <vector>

#include "base/basictypes.h"
#include "base/command_line.h"
#include "base/files/file_path.h"
#include "base/memory/scoped_ptr.h"
#include "base/strings/utf_string_conversions.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

// To test Windows quoting behavior, we use a string that has some backslashes
// and quotes.
// Consider the command-line argument: q\"bs1\bs2\\bs3q\\\"
// Here it is with C-style escapes.
static const CommandLine::StringType kTrickyQuoted =
    FILE_PATH_LITERAL("q\\\"bs1\\bs2\\\\bs3q\\\\\\\"");
// It should be parsed by Windows as: q"bs1\bs2\\bs3q\"
// Here that is with C-style escapes.
static const CommandLine::StringType kTricky =
    FILE_PATH_LITERAL("q\"bs1\\bs2\\\\bs3q\\\"");

TEST(CommandLineTest, CommandLineConstructor) {
  const CommandLine::CharType* argv[] = {
      FILE_PATH_LITERAL("program"),
      FILE_PATH_LITERAL("--foo="),
      FILE_PATH_LITERAL("-bAr"),
      FILE_PATH_LITERAL("-spaetzel=pierogi"),
      FILE_PATH_LITERAL("-baz"),
      FILE_PATH_LITERAL("flim"),
      FILE_PATH_LITERAL("--other-switches=--dog=canine --cat=feline"),
      FILE_PATH_LITERAL("-spaetzle=Crepe"),
      FILE_PATH_LITERAL("-=loosevalue"),
      FILE_PATH_LITERAL("-"),
      FILE_PATH_LITERAL("FLAN"),
      FILE_PATH_LITERAL("a"),
      FILE_PATH_LITERAL("--input-translation=45--output-rotation"),
      FILE_PATH_LITERAL("--"),
      FILE_PATH_LITERAL("--"),
      FILE_PATH_LITERAL("--not-a-switch"),
      FILE_PATH_LITERAL("\"in the time of submarines...\""),
      FILE_PATH_LITERAL("unquoted arg-with-space")};
  CommandLine cl(arraysize(argv), argv);

  EXPECT_FALSE(cl.GetCommandLineString().empty());
  EXPECT_FALSE(cl.HasSwitch("cruller"));
  EXPECT_FALSE(cl.HasSwitch("flim"));
  EXPECT_FALSE(cl.HasSwitch("program"));
  EXPECT_FALSE(cl.HasSwitch("dog"));
  EXPECT_FALSE(cl.HasSwitch("cat"));
  EXPECT_FALSE(cl.HasSwitch("output-rotation"));
  EXPECT_FALSE(cl.HasSwitch("not-a-switch"));
  EXPECT_FALSE(cl.HasSwitch("--"));

  EXPECT_EQ(FilePath(FILE_PATH_LITERAL("program")).value(),
            cl.GetProgram().value());

  EXPECT_TRUE(cl.HasSwitch("foo"));
#if defined(OS_WIN)
  EXPECT_TRUE(cl.HasSwitch("bar"));
#else
  EXPECT_FALSE(cl.HasSwitch("bar"));
#endif
  EXPECT_TRUE(cl.HasSwitch("baz"));
  EXPECT_TRUE(cl.HasSwitch("spaetzle"));
  EXPECT_TRUE(cl.HasSwitch("other-switches"));
  EXPECT_TRUE(cl.HasSwitch("input-translation"));

  EXPECT_EQ("Crepe", cl.GetSwitchValueASCII("spaetzle"));
  EXPECT_EQ("", cl.GetSwitchValueASCII("foo"));
  EXPECT_EQ("", cl.GetSwitchValueASCII("bar"));
  EXPECT_EQ("", cl.GetSwitchValueASCII("cruller"));
  EXPECT_EQ("--dog=canine --cat=feline", cl.GetSwitchValueASCII(
      "other-switches"));
  EXPECT_EQ("45--output-rotation", cl.GetSwitchValueASCII("input-translation"));

  const CommandLine::StringVector& args = cl.GetArgs();
  ASSERT_EQ(8U, args.size());

  std::vector<CommandLine::StringType>::const_iterator iter = args.begin();
  EXPECT_EQ(FILE_PATH_LITERAL("flim"), *iter);
  ++iter;
  EXPECT_EQ(FILE_PATH_LITERAL("-"), *iter);
  ++iter;
  EXPECT_EQ(FILE_PATH_LITERAL("FLAN"), *iter);
  ++iter;
  EXPECT_EQ(FILE_PATH_LITERAL("a"), *iter);
  ++iter;
  EXPECT_EQ(FILE_PATH_LITERAL("--"), *iter);
  ++iter;
  EXPECT_EQ(FILE_PATH_LITERAL("--not-a-switch"), *iter);
  ++iter;
  EXPECT_EQ(FILE_PATH_LITERAL("\"in the time of submarines...\""), *iter);
  ++iter;
  EXPECT_EQ(FILE_PATH_LITERAL("unquoted arg-with-space"), *iter);
  ++iter;
  EXPECT_TRUE(iter == args.end());
}

TEST(CommandLineTest, CommandLineFromString) {
#if defined(OS_WIN)
  CommandLine cl = CommandLine::FromString(
      L"program --foo= -bAr  /Spaetzel=pierogi /Baz flim "
      L"--other-switches=\"--dog=canine --cat=feline\" "
      L"-spaetzle=Crepe   -=loosevalue  FLAN "
      L"--input-translation=\"45\"--output-rotation "
      L"--quotes=" + kTrickyQuoted + L" "
      L"-- -- --not-a-switch "
      L"\"in the time of submarines...\"");

  EXPECT_FALSE(cl.GetCommandLineString().empty());
  EXPECT_FALSE(cl.HasSwitch("cruller"));
  EXPECT_FALSE(cl.HasSwitch("flim"));
  EXPECT_FALSE(cl.HasSwitch("program"));
  EXPECT_FALSE(cl.HasSwitch("dog"));
  EXPECT_FALSE(cl.HasSwitch("cat"));
  EXPECT_FALSE(cl.HasSwitch("output-rotation"));
  EXPECT_FALSE(cl.HasSwitch("not-a-switch"));
  EXPECT_FALSE(cl.HasSwitch("--"));

  EXPECT_EQ(FilePath(FILE_PATH_LITERAL("program")).value(),
            cl.GetProgram().value());

  EXPECT_TRUE(cl.HasSwitch("foo"));
  EXPECT_TRUE(cl.HasSwitch("bar"));
  EXPECT_TRUE(cl.HasSwitch("baz"));
  EXPECT_TRUE(cl.HasSwitch("spaetzle"));
  EXPECT_TRUE(cl.HasSwitch("other-switches"));
  EXPECT_TRUE(cl.HasSwitch("input-translation"));
  EXPECT_TRUE(cl.HasSwitch("quotes"));

  EXPECT_EQ("Crepe", cl.GetSwitchValueASCII("spaetzle"));
  EXPECT_EQ("", cl.GetSwitchValueASCII("foo"));
  EXPECT_EQ("", cl.GetSwitchValueASCII("bar"));
  EXPECT_EQ("", cl.GetSwitchValueASCII("cruller"));
  EXPECT_EQ("--dog=canine --cat=feline", cl.GetSwitchValueASCII(
      "other-switches"));
  EXPECT_EQ("45--output-rotation", cl.GetSwitchValueASCII("input-translation"));
  EXPECT_EQ(kTricky, cl.GetSwitchValueNative("quotes"));

  const CommandLine::StringVector& args = cl.GetArgs();
  ASSERT_EQ(5U, args.size());

  std::vector<CommandLine::StringType>::const_iterator iter = args.begin();
  EXPECT_EQ(FILE_PATH_LITERAL("flim"), *iter);
  ++iter;
  EXPECT_EQ(FILE_PATH_LITERAL("FLAN"), *iter);
  ++iter;
  EXPECT_EQ(FILE_PATH_LITERAL("--"), *iter);
  ++iter;
  EXPECT_EQ(FILE_PATH_LITERAL("--not-a-switch"), *iter);
  ++iter;
  EXPECT_EQ(FILE_PATH_LITERAL("in the time of submarines..."), *iter);
  ++iter;
  EXPECT_TRUE(iter == args.end());

  // Check that a generated string produces an equivalent command line.
  CommandLine cl_duplicate = CommandLine::FromString(cl.GetCommandLineString());
  EXPECT_EQ(cl.GetCommandLineString(), cl_duplicate.GetCommandLineString());
#endif
}

// Tests behavior with an empty input string.
TEST(CommandLineTest, EmptyString) {
#if defined(OS_WIN)
  CommandLine cl_from_string = CommandLine::FromString(L"");
  EXPECT_TRUE(cl_from_string.GetCommandLineString().empty());
  EXPECT_TRUE(cl_from_string.GetProgram().empty());
  EXPECT_EQ(1U, cl_from_string.argv().size());
  EXPECT_TRUE(cl_from_string.GetArgs().empty());
#endif
  CommandLine cl_from_argv(0, NULL);
  EXPECT_TRUE(cl_from_argv.GetCommandLineString().empty());
  EXPECT_TRUE(cl_from_argv.GetProgram().empty());
  EXPECT_EQ(1U, cl_from_argv.argv().size());
  EXPECT_TRUE(cl_from_argv.GetArgs().empty());
}

TEST(CommandLineTest, GetArgumentsString) {
  static const FilePath::CharType kPath1[] =
      FILE_PATH_LITERAL("C:\\Some File\\With Spaces.ggg");
  static const FilePath::CharType kPath2[] =
      FILE_PATH_LITERAL("C:\\no\\spaces.ggg");

  static const char kFirstArgName[] = "first-arg";
  static const char kSecondArgName[] = "arg2";
  static const char kThirdArgName[] = "arg with space";
  static const char kFourthArgName[] = "nospace";
  static const char kFifthArgName[] = "%1";

  CommandLine cl(CommandLine::NO_PROGRAM);
  cl.AppendSwitchPath(kFirstArgName, FilePath(kPath1));
  cl.AppendSwitchPath(kSecondArgName, FilePath(kPath2));
  cl.AppendArg(kThirdArgName);
  cl.AppendArg(kFourthArgName);
  cl.AppendArg(kFifthArgName);

#if defined(OS_WIN)
  CommandLine::StringType expected_first_arg(UTF8ToUTF16(kFirstArgName));
  CommandLine::StringType expected_second_arg(UTF8ToUTF16(kSecondArgName));
  CommandLine::StringType expected_third_arg(UTF8ToUTF16(kThirdArgName));
  CommandLine::StringType expected_fourth_arg(UTF8ToUTF16(kFourthArgName));
  CommandLine::StringType expected_fifth_arg(UTF8ToUTF16(kFifthArgName));
#elif defined(OS_POSIX)
  CommandLine::StringType expected_first_arg(kFirstArgName);
  CommandLine::StringType expected_second_arg(kSecondArgName);
  CommandLine::StringType expected_third_arg(kThirdArgName);
  CommandLine::StringType expected_fourth_arg(kFourthArgName);
  CommandLine::StringType expected_fifth_arg(kFifthArgName);
#endif

#if defined(OS_WIN)
#define QUOTE_ON_WIN FILE_PATH_LITERAL("\"")
#else
#define QUOTE_ON_WIN FILE_PATH_LITERAL("")
#endif  // OS_WIN

  CommandLine::StringType expected_str;
  expected_str.append(FILE_PATH_LITERAL("--"))
              .append(expected_first_arg)
              .append(FILE_PATH_LITERAL("="))
              .append(QUOTE_ON_WIN)
              .append(kPath1)
              .append(QUOTE_ON_WIN)
              .append(FILE_PATH_LITERAL(" "))
              .append(FILE_PATH_LITERAL("--"))
              .append(expected_second_arg)
              .append(FILE_PATH_LITERAL("="))
              .append(QUOTE_ON_WIN)
              .append(kPath2)
              .append(QUOTE_ON_WIN)
              .append(FILE_PATH_LITERAL(" "))
              .append(QUOTE_ON_WIN)
              .append(expected_third_arg)
              .append(QUOTE_ON_WIN)
              .append(FILE_PATH_LITERAL(" "))
              .append(expected_fourth_arg)
              .append(FILE_PATH_LITERAL(" "));

  CommandLine::StringType expected_str_no_quote_placeholders(expected_str);
  expected_str_no_quote_placeholders.append(expected_fifth_arg);
  EXPECT_EQ(expected_str_no_quote_placeholders, cl.GetArgumentsString());

#if defined(OS_WIN)
  CommandLine::StringType expected_str_quote_placeholders(expected_str);
  expected_str_quote_placeholders.append(QUOTE_ON_WIN)
                                 .append(expected_fifth_arg)
                                 .append(QUOTE_ON_WIN);
  EXPECT_EQ(expected_str_quote_placeholders,
            cl.GetArgumentsStringWithPlaceholders());
#endif
}

// Test methods for appending switches to a command line.
TEST(CommandLineTest, AppendSwitches) {
  std::string switch1 = "switch1";
  std::string switch2 = "switch2";
  std::string value2 = "value";
  std::string switch3 = "switch3";
  std::string value3 = "a value with spaces";
  std::string switch4 = "switch4";
  std::string value4 = "\"a value with quotes\"";
  std::string switch5 = "quotes";
  CommandLine::StringType value5 = kTricky;

  CommandLine cl(FilePath(FILE_PATH_LITERAL("Program")));

  cl.AppendSwitch(switch1);
  cl.AppendSwitchASCII(switch2, value2);
  cl.AppendSwitchASCII(switch3, value3);
  cl.AppendSwitchASCII(switch4, value4);
  cl.AppendSwitchASCII(switch5, value4);
  cl.AppendSwitchNative(switch5, value5);

  EXPECT_TRUE(cl.HasSwitch(switch1));
  EXPECT_TRUE(cl.HasSwitch(switch2));
  EXPECT_EQ(value2, cl.GetSwitchValueASCII(switch2));
  EXPECT_TRUE(cl.HasSwitch(switch3));
  EXPECT_EQ(value3, cl.GetSwitchValueASCII(switch3));
  EXPECT_TRUE(cl.HasSwitch(switch4));
  EXPECT_EQ(value4, cl.GetSwitchValueASCII(switch4));
  EXPECT_TRUE(cl.HasSwitch(switch5));
  EXPECT_EQ(value5, cl.GetSwitchValueNative(switch5));

#if defined(OS_WIN)
  EXPECT_EQ(L"Program "
            L"--switch1 "
            L"--switch2=value "
            L"--switch3=\"a value with spaces\" "
            L"--switch4=\"\\\"a value with quotes\\\"\" "
            // Even though the switches are unique, appending can add repeat
            // switches to argv.
            L"--quotes=\"\\\"a value with quotes\\\"\" "
            L"--quotes=\"" + kTrickyQuoted + L"\"",
            cl.GetCommandLineString());
#endif
}

TEST(CommandLineTest, AppendSwitchesDashDash) {
 const CommandLine::CharType* raw_argv[] = { FILE_PATH_LITERAL("prog"),
                                             FILE_PATH_LITERAL("--"),
                                             FILE_PATH_LITERAL("--arg1") };
  CommandLine cl(arraysize(raw_argv), raw_argv);

  cl.AppendSwitch("switch1");
  cl.AppendSwitchASCII("switch2", "foo");

  cl.AppendArg("--arg2");

  EXPECT_EQ(FILE_PATH_LITERAL("prog --switch1 --switch2=foo -- --arg1 --arg2"),
            cl.GetCommandLineString());
  CommandLine::StringVector cl_argv = cl.argv();
  EXPECT_EQ(FILE_PATH_LITERAL("prog"), cl_argv[0]);
  EXPECT_EQ(FILE_PATH_LITERAL("--switch1"), cl_argv[1]);
  EXPECT_EQ(FILE_PATH_LITERAL("--switch2=foo"), cl_argv[2]);
  EXPECT_EQ(FILE_PATH_LITERAL("--"), cl_argv[3]);
  EXPECT_EQ(FILE_PATH_LITERAL("--arg1"), cl_argv[4]);
  EXPECT_EQ(FILE_PATH_LITERAL("--arg2"), cl_argv[5]);
}

// Tests that when AppendArguments is called that the program is set correctly
// on the target CommandLine object and the switches from the source
// CommandLine are added to the target.
TEST(CommandLineTest, AppendArguments) {
  CommandLine cl1(FilePath(FILE_PATH_LITERAL("Program")));
  cl1.AppendSwitch("switch1");
  cl1.AppendSwitchASCII("switch2", "foo");

  CommandLine cl2(CommandLine::NO_PROGRAM);
  cl2.AppendArguments(cl1, true);
  EXPECT_EQ(cl1.GetProgram().value(), cl2.GetProgram().value());
  EXPECT_EQ(cl1.GetCommandLineString(), cl2.GetCommandLineString());

  CommandLine c1(FilePath(FILE_PATH_LITERAL("Program1")));
  c1.AppendSwitch("switch1");
  CommandLine c2(FilePath(FILE_PATH_LITERAL("Program2")));
  c2.AppendSwitch("switch2");

  c1.AppendArguments(c2, true);
  EXPECT_EQ(c1.GetProgram().value(), c2.GetProgram().value());
  EXPECT_TRUE(c1.HasSwitch("switch1"));
  EXPECT_TRUE(c1.HasSwitch("switch2"));
}

#if defined(OS_WIN)
// Make sure that the command line string program paths are quoted as necessary.
// This only makes sense on Windows and the test is basically here to guard
// against regressions.
TEST(CommandLineTest, ProgramQuotes) {
  // Check that quotes are not added for paths without spaces.
  const FilePath kProgram(L"Program");
  CommandLine cl_program(kProgram);
  EXPECT_EQ(kProgram.value(), cl_program.GetProgram().value());
  EXPECT_EQ(kProgram.value(), cl_program.GetCommandLineString());

  const FilePath kProgramPath(L"Program Path");

  // Check that quotes are not returned from GetProgram().
  CommandLine cl_program_path(kProgramPath);
  EXPECT_EQ(kProgramPath.value(), cl_program_path.GetProgram().value());

  // Check that quotes are added to command line string paths containing spaces.
  CommandLine::StringType cmd_string(cl_program_path.GetCommandLineString());
  EXPECT_EQ(L"\"Program Path\"", cmd_string);

  // Check the optional quoting of placeholders in programs.
  CommandLine cl_quote_placeholder(FilePath(L"%1"));
  EXPECT_EQ(L"%1", cl_quote_placeholder.GetCommandLineString());
  EXPECT_EQ(L"\"%1\"",
            cl_quote_placeholder.GetCommandLineStringWithPlaceholders());
}
#endif

// Calling Init multiple times should not modify the previous CommandLine.
TEST(CommandLineTest, Init) {
  CommandLine* initial = CommandLine::ForCurrentProcess();
  EXPECT_FALSE(CommandLine::Init(0, NULL));
  CommandLine* current = CommandLine::ForCurrentProcess();
  EXPECT_EQ(initial, current);
}

// Test that copies of CommandLine have a valid StringPiece map.
TEST(CommandLineTest, Copy) {
  scoped_ptr<CommandLine> initial(new CommandLine(CommandLine::NO_PROGRAM));
  initial->AppendSwitch("a");
  initial->AppendSwitch("bbbbbbbbbbbbbbb");
  initial->AppendSwitch("c");
  CommandLine copy_constructed(*initial);
  CommandLine assigned = *initial;
  CommandLine::SwitchMap switch_map = initial->GetSwitches();
  initial.reset();
  for (const auto& pair : switch_map)
    EXPECT_TRUE(copy_constructed.HasSwitch(pair.first));
  for (const auto& pair : switch_map)
    EXPECT_TRUE(assigned.HasSwitch(pair.first));
}

} // namespace base
