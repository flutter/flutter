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

#include <vector>

#include <google/protobuf/io/printer.h>
#include <google/protobuf/io/zero_copy_stream_impl.h>

#include <google/protobuf/stubs/common.h>
#include <google/protobuf/testing/googletest.h>
#include <gtest/gtest.h>

namespace google {
namespace protobuf {
namespace io {
namespace {

// Each test repeats over several block sizes in order to test both cases
// where particular writes cross a buffer boundary and cases where they do
// not.

TEST(Printer, EmptyPrinter) {
  char buffer[8192];
  const int block_size = 100;
  ArrayOutputStream output(buffer, GOOGLE_ARRAYSIZE(buffer), block_size);
  Printer printer(&output, '\0');
  EXPECT_TRUE(!printer.failed());
}

TEST(Printer, BasicPrinting) {
  char buffer[8192];

  for (int block_size = 1; block_size < 512; block_size *= 2) {
    ArrayOutputStream output(buffer, sizeof(buffer), block_size);

    {
      Printer printer(&output, '\0');

      printer.Print("Hello World!");
      printer.Print("  This is the same line.\n");
      printer.Print("But this is a new one.\nAnd this is another one.");

      EXPECT_FALSE(printer.failed());
    }

    buffer[output.ByteCount()] = '\0';

    EXPECT_STREQ("Hello World!  This is the same line.\n"
                 "But this is a new one.\n"
                 "And this is another one.",
                 buffer);
  }
}

TEST(Printer, WriteRaw) {
  char buffer[8192];

  for (int block_size = 1; block_size < 512; block_size *= 2) {
    ArrayOutputStream output(buffer, sizeof(buffer), block_size);

    {
      string string_obj = "From an object\n";
      Printer printer(&output, '$');
      printer.WriteRaw("Hello World!", 12);
      printer.PrintRaw("  This is the same line.\n");
      printer.PrintRaw("But this is a new one.\nAnd this is another one.");
      printer.WriteRaw("\n", 1);
      printer.PrintRaw(string_obj);
      EXPECT_FALSE(printer.failed());
    }

    buffer[output.ByteCount()] = '\0';

    EXPECT_STREQ("Hello World!  This is the same line.\n"
                 "But this is a new one.\n"
                 "And this is another one."
                 "\n"
                 "From an object\n",
                 buffer);
  }
}

TEST(Printer, VariableSubstitution) {
  char buffer[8192];

  for (int block_size = 1; block_size < 512; block_size *= 2) {
    ArrayOutputStream output(buffer, sizeof(buffer), block_size);

    {
      Printer printer(&output, '$');
      map<string, string> vars;

      vars["foo"] = "World";
      vars["bar"] = "$foo$";
      vars["abcdefg"] = "1234";

      printer.Print(vars, "Hello $foo$!\nbar = $bar$\n");
      printer.PrintRaw("RawBit\n");
      printer.Print(vars, "$abcdefg$\nA literal dollar sign:  $$");

      vars["foo"] = "blah";
      printer.Print(vars, "\nNow foo = $foo$.");

      EXPECT_FALSE(printer.failed());
    }

    buffer[output.ByteCount()] = '\0';

    EXPECT_STREQ("Hello World!\n"
                 "bar = $foo$\n"
                 "RawBit\n"
                 "1234\n"
                 "A literal dollar sign:  $\n"
                 "Now foo = blah.",
                 buffer);
  }
}

TEST(Printer, InlineVariableSubstitution) {
  char buffer[8192];

  ArrayOutputStream output(buffer, sizeof(buffer));

  {
    Printer printer(&output, '$');
    printer.Print("Hello $foo$!\n", "foo", "World");
    printer.PrintRaw("RawBit\n");
    printer.Print("$foo$ $bar$\n", "foo", "one", "bar", "two");
    EXPECT_FALSE(printer.failed());
  }

  buffer[output.ByteCount()] = '\0';

  EXPECT_STREQ("Hello World!\n"
               "RawBit\n"
               "one two\n",
               buffer);
}

TEST(Printer, Indenting) {
  char buffer[8192];

  for (int block_size = 1; block_size < 512; block_size *= 2) {
    ArrayOutputStream output(buffer, sizeof(buffer), block_size);

    {
      Printer printer(&output, '$');
      map<string, string> vars;

      vars["newline"] = "\n";

      printer.Print("This is not indented.\n");
      printer.Indent();
      printer.Print("This is indented\nAnd so is this\n");
      printer.Outdent();
      printer.Print("But this is not.");
      printer.Indent();
      printer.Print("  And this is still the same line.\n"
                    "But this is indented.\n");
      printer.PrintRaw("RawBit has indent at start\n");
      printer.PrintRaw("but not after a raw newline\n");
      printer.Print(vars, "Note that a newline in a variable will break "
                    "indenting, as we see$newline$here.\n");
      printer.Indent();
      printer.Print("And this");
      printer.Outdent();
      printer.Outdent();
      printer.Print(" is double-indented\nBack to normal.");

      EXPECT_FALSE(printer.failed());
    }

    buffer[output.ByteCount()] = '\0';

    EXPECT_STREQ(
      "This is not indented.\n"
      "  This is indented\n"
      "  And so is this\n"
      "But this is not.  And this is still the same line.\n"
      "  But this is indented.\n"
      "  RawBit has indent at start\n"
      "but not after a raw newline\n"
      "Note that a newline in a variable will break indenting, as we see\n"
      "here.\n"
      "    And this is double-indented\n"
      "Back to normal.",
      buffer);
  }
}

// Death tests do not work on Windows as of yet.
#ifdef PROTOBUF_HAS_DEATH_TEST
TEST(Printer, Death) {
  char buffer[8192];

  ArrayOutputStream output(buffer, sizeof(buffer));
  Printer printer(&output, '$');

  EXPECT_DEBUG_DEATH(printer.Print("$nosuchvar$"), "Undefined variable");
  EXPECT_DEBUG_DEATH(printer.Print("$unclosed"), "Unclosed variable name");
  EXPECT_DEBUG_DEATH(printer.Outdent(), "without matching Indent");
}
#endif  // PROTOBUF__HAS_DEATH_TEST

TEST(Printer, WriteFailurePartial) {
  char buffer[17];

  ArrayOutputStream output(buffer, sizeof(buffer));
  Printer printer(&output, '$');

  // Print 16 bytes to almost fill the buffer (should not fail).
  printer.Print("0123456789abcdef");
  EXPECT_FALSE(printer.failed());

  // Try to print 2 chars. Only one fits.
  printer.Print("<>");
  EXPECT_TRUE(printer.failed());

  // Anything else should fail too.
  printer.Print(" ");
  EXPECT_TRUE(printer.failed());
  printer.Print("blah");
  EXPECT_TRUE(printer.failed());

  // Buffer should contain the first 17 bytes written.
  EXPECT_EQ("0123456789abcdef<", string(buffer, sizeof(buffer)));
}

TEST(Printer, WriteFailureExact) {
  char buffer[16];

  ArrayOutputStream output(buffer, sizeof(buffer));
  Printer printer(&output, '$');

  // Print 16 bytes to fill the buffer exactly (should not fail).
  printer.Print("0123456789abcdef");
  EXPECT_FALSE(printer.failed());

  // Try to print one more byte (should fail).
  printer.Print(" ");
  EXPECT_TRUE(printer.failed());

  // Should not crash
  printer.Print("blah");
  EXPECT_TRUE(printer.failed());

  // Buffer should contain the first 16 bytes written.
  EXPECT_EQ("0123456789abcdef", string(buffer, sizeof(buffer)));
}

}  // namespace
}  // namespace io
}  // namespace protobuf
}  // namespace google
