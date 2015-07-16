// Copyright (c) 2008, Google Inc.
// All rights reserved.
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

// ---
// Author: Craig Silverstein
//
// This tests ReadStackTraces and ReadGrowthStackTraces.  It does this
// by doing a bunch of allocations and then calling those functions.
// A driver shell-script can call this, and then call pprof, and
// verify the expected output.  The output is written to
// argv[1].heap and argv[1].growth

#include "config_for_unittests.h"
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include "base/logging.h"
#include <gperftools/malloc_extension.h>

using std::string;

extern "C" void* AllocateAllocate() ATTRIBUTE_NOINLINE;

extern "C" void* AllocateAllocate() {
  // The VLOG's are mostly to discourage inlining
  VLOG(1, "Allocating some more");
  void* p = malloc(10000);
  VLOG(1, "Done allocating");
  return p;
}

static void WriteStringToFile(const string& s, const string& filename) {
  FILE* fp = fopen(filename.c_str(), "w");
  fwrite(s.data(), 1, s.length(), fp);
  fclose(fp);
}

int main(int argc, char** argv) {
  if (argc < 2) {
    fprintf(stderr, "USAGE: %s <base of output files>\n", argv[0]);
    exit(1);
  }
  for (int i = 0; i < 8000; i++) {
    AllocateAllocate();
  }

  string s;
  MallocExtension::instance()->GetHeapSample(&s);
  WriteStringToFile(s, string(argv[1]) + ".heap");

  s.clear();
  MallocExtension::instance()->GetHeapGrowthStacks(&s);
  WriteStringToFile(s, string(argv[1]) + ".growth");

  return 0;
}
