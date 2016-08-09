// Copyright 2009 Google Inc. All Rights Reserved.
// Author: sanjay@google.com (Sanjay Ghemawat)

#include "raw_printer.h"
#include <stdio.h>
#include <string>
#include "base/logging.h"

using std::string;

#define TEST(a, b)  void TEST_##a##_##b()
#define RUN_TEST(a, b)  TEST_##a##_##b()

TEST(RawPrinter, Empty) {
  char buffer[1];
  base::RawPrinter printer(buffer, arraysize(buffer));
  CHECK_EQ(0, printer.length());
  CHECK_EQ(string(""), buffer);
  CHECK_EQ(0, printer.space_left());
  printer.Printf("foo");
  CHECK_EQ(string(""), string(buffer));
  CHECK_EQ(0, printer.length());
  CHECK_EQ(0, printer.space_left());
}

TEST(RawPrinter, PartiallyFilled) {
  char buffer[100];
  base::RawPrinter printer(buffer, arraysize(buffer));
  printer.Printf("%s %s", "hello", "world");
  CHECK_EQ(string("hello world"), string(buffer));
  CHECK_EQ(11, printer.length());
  CHECK_LT(0, printer.space_left());
}

TEST(RawPrinter, Truncated) {
  char buffer[3];
  base::RawPrinter printer(buffer, arraysize(buffer));
  printer.Printf("%d", 12345678);
  CHECK_EQ(string("12"), string(buffer));
  CHECK_EQ(2, printer.length());
  CHECK_EQ(0, printer.space_left());
}

TEST(RawPrinter, ExactlyFilled) {
  char buffer[12];
  base::RawPrinter printer(buffer, arraysize(buffer));
  printer.Printf("%s %s", "hello", "world");
  CHECK_EQ(string("hello world"), string(buffer));
  CHECK_EQ(11, printer.length());
  CHECK_EQ(0, printer.space_left());
}

int main(int argc, char **argv) {
  RUN_TEST(RawPrinter, Empty);
  RUN_TEST(RawPrinter, PartiallyFilled);
  RUN_TEST(RawPrinter, Truncated);
  RUN_TEST(RawPrinter, ExactlyFilled);
  printf("PASS\n");
  return 0;   // 0 means success
}
