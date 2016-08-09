// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Tool to pack and unpack relative relocations in a shared library.
//
// Packing removes relative relocations from .rel.dyn and writes them
// in a more compact form to .android.rel.dyn.  Unpacking does the reverse.
//
// Invoke with -v to trace actions taken when packing or unpacking.
// Invoke with -p to pad removed relocations with R_*_NONE.  Suppresses
// shrinking of .rel.dyn.
// See PrintUsage() below for full usage details.
//
// NOTE: Breaks with libelf 0.152, which is buggy.  libelf 0.158 works.

#include <errno.h>
#include <fcntl.h>
#include <getopt.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>
#include <string>

#include "debug.h"
#include "elf_file.h"
#include "libelf.h"

namespace {

void PrintUsage(const char* argv0) {
  std::string temporary = argv0;
  const size_t last_slash = temporary.find_last_of("/");
  if (last_slash != temporary.npos) {
    temporary.erase(0, last_slash + 1);
  }
  const char* basename = temporary.c_str();

  printf(
      "Usage: %s [-u] [-v] [-p] file\n\n"
      "Pack or unpack relative relocations in a shared library.\n\n"
      "  -u, --unpack   unpack previously packed relative relocations\n"
      "  -v, --verbose  trace object file modifications (for debugging)\n"
      "  -p, --pad      do not shrink relocations, but pad (for debugging)\n\n",
      basename);

  if (ELF::kMachine == EM_ARM) {
    printf(
        "Extracts relative relocations from the .rel.dyn section, packs them\n"
        "into a more compact format, and stores the packed relocations in\n"
        ".android.rel.dyn.  Expands .android.rel.dyn to hold the packed\n"
        "data, and shrinks .rel.dyn by the amount of unpacked data removed\n"
        "from it.\n\n"
        "Before being packed, a shared library needs to be prepared by adding\n"
        "a null .android.rel.dyn section.\n\n"
        "To pack relocations in a shared library:\n\n"
        "    echo -n 'NULL' >/tmp/small\n"
        "    arm-linux-androideabi-objcopy \\\n"
        "        --add-section .android.rel.dyn=/tmp/small \\\n"
        "        libchrome.<version>.so\n"
        "    rm /tmp/small\n"
        "    %s libchrome.<version>.so\n\n"
        "To unpack and restore the shared library to its original state:\n\n"
        "    %s -u libchrome.<version>.so\n"
        "    arm-linux-androideabi-objcopy \\\n"
        "        --remove-section=.android.rel.dyn libchrome.<version>.so\n\n",
        basename, basename);
  } else if (ELF::kMachine == EM_AARCH64) {
    printf(
        "Extracts relative relocations from the .rela.dyn section, packs them\n"
        "into a more compact format, and stores the packed relocations in\n"
        ".android.rela.dyn.  Expands .android.rela.dyn to hold the packed\n"
        "data, and shrinks .rela.dyn by the amount of unpacked data removed\n"
        "from it.\n\n"
        "Before being packed, a shared library needs to be prepared by adding\n"
        "a null .android.rela.dyn section.\n\n"
        "To pack relocations in a shared library:\n\n"
        "    echo -n 'NULL' >/tmp/small\n"
        "    aarch64-linux-android-objcopy \\\n"
        "        --add-section .android.rela.dyn=/tmp/small \\\n"
        "        libchrome.<version>.so\n"
        "    rm /tmp/small\n"
        "    %s libchrome.<version>.so\n\n"
        "To unpack and restore the shared library to its original state:\n\n"
        "    %s -u libchrome.<version>.so\n"
        "    aarch64-linux-android-objcopy \\\n"
        "        --remove-section=.android.rela.dyn libchrome.<version>.so\n\n",
        basename, basename);
  } else {
    NOTREACHED();
  }

  printf(
      "Debug sections are not handled, so packing should not be used on\n"
      "shared libraries compiled for debugging or otherwise unstripped.\n");
}

}  // namespace

int main(int argc, char* argv[]) {
  bool is_unpacking = false;
  bool is_verbose = false;
  bool is_padding = false;

  static const option options[] = {
    {"unpack", 0, 0, 'u'}, {"verbose", 0, 0, 'v'}, {"pad", 0, 0, 'p'},
    {"help", 0, 0, 'h'}, {NULL, 0, 0, 0}
  };
  bool has_options = true;
  while (has_options) {
    int c = getopt_long(argc, argv, "uvph", options, NULL);
    switch (c) {
      case 'u':
        is_unpacking = true;
        break;
      case 'v':
        is_verbose = true;
        break;
      case 'p':
        is_padding = true;
        break;
      case 'h':
        PrintUsage(argv[0]);
        return 0;
      case '?':
        LOG(INFO) << "Try '" << argv[0] << " --help' for more information.";
        return 1;
      case -1:
        has_options = false;
        break;
      default:
        NOTREACHED();
        return 1;
    }
  }
  if (optind != argc - 1) {
    LOG(INFO) << "Try '" << argv[0] << " --help' for more information.";
    return 1;
  }

  if (elf_version(EV_CURRENT) == EV_NONE) {
    LOG(WARNING) << "Elf Library is out of date!";
  }

  LOG(INFO) << "Configured for " << ELF::Machine();

  const char* file = argv[argc - 1];
  const int fd = open(file, O_RDWR);
  if (fd == -1) {
    LOG(ERROR) << file << ": " << strerror(errno);
    return 1;
  }

  if (is_verbose)
    relocation_packer::Logger::SetVerbose(1);

  relocation_packer::ElfFile elf_file(fd);
  elf_file.SetPadding(is_padding);

  bool status;
  if (is_unpacking)
    status = elf_file.UnpackRelocations();
  else
    status = elf_file.PackRelocations();

  close(fd);

  if (!status) {
    LOG(ERROR) << file << ": failed to pack/unpack file";
    return 1;
  }

  return 0;
}
