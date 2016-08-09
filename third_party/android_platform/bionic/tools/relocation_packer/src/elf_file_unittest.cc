// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "elf_file.h"

#include <limits.h>
#include <stdio.h>
#include <unistd.h>
#include <string>
#include <vector>
#include "debug.h"
#include "elf_traits.h"
#include "gtest/gtest.h"

namespace {

void GetDataFilePath(const char* name, std::string* path) {
  std::string data_dir;

  const char* bindir = getenv("bindir");
  if (bindir) {
    data_dir = std::string(bindir);
  } else {
    char path[PATH_MAX];
    memset(path, 0, sizeof(path));
    ASSERT_NE(-1, readlink("/proc/self/exe", path, sizeof(path) - 1));

    data_dir = std::string(path);
    size_t pos = data_dir.rfind('/');
    ASSERT_NE(std::string::npos, pos);

    data_dir.erase(pos);
  }

  *path = data_dir + "/" + name;
}

void OpenRelocsTestFile(const char* name, FILE** stream) {
  std::string path;
  GetDataFilePath(name, &path);

  FILE* testfile = fopen(path.c_str(), "rb");
  ASSERT_FALSE(testfile == NULL) << "Error opening '" << path << "'";

  FILE* temporary = tmpfile();
  ASSERT_FALSE(temporary == NULL);

  static const size_t buffer_size = 4096;
  unsigned char buffer[buffer_size];

  size_t bytes;
  do {
    bytes = fread(buffer, 1, sizeof(buffer), testfile);
    ASSERT_EQ(bytes, fwrite(buffer, 1, bytes, temporary));
  } while (bytes > 0);

  ASSERT_EQ(0, fclose(testfile));
  ASSERT_EQ(0, fseek(temporary, 0, SEEK_SET));
  ASSERT_EQ(0, lseek(fileno(temporary), 0, SEEK_SET));

  *stream = temporary;
}

void OpenRelocsTestFiles(const std::string& arch, FILE** relocs_so, FILE** packed_relocs_so) {
  const std::string base = std::string("elf_file_unittest_relocs_") + arch;
  const std::string relocs = base + ".so";
  const std::string packed_relocs = base + "_packed.so";

  OpenRelocsTestFile(relocs.c_str(), relocs_so);
  OpenRelocsTestFile(packed_relocs.c_str(), packed_relocs_so);
}

void CloseRelocsTestFile(FILE* temporary) {
  fclose(temporary);
}

void CloseRelocsTestFiles(FILE* relocs_so, FILE* packed_relocs_so) {
  CloseRelocsTestFile(relocs_so);
  CloseRelocsTestFile(packed_relocs_so);
}

void CheckFileContentsEqual(FILE* first, FILE* second) {
  ASSERT_EQ(0, fseek(first, 0, SEEK_SET));
  ASSERT_EQ(0, fseek(second, 0, SEEK_SET));

  static const size_t buffer_size = 4096;
  unsigned char first_buffer[buffer_size];
  unsigned char second_buffer[buffer_size];

  do {
    size_t first_read = fread(first_buffer, 1, sizeof(first_buffer), first);
    size_t second_read = fread(second_buffer, 1, sizeof(second_buffer), second);

    EXPECT_EQ(first_read, second_read);
    EXPECT_EQ(0, memcmp(first_buffer, second_buffer, first_read));
  } while (!feof(first) && !feof(second));

  EXPECT_TRUE(feof(first) && feof(second));
}

template <typename ELF>
static void ProcessUnpack(FILE* relocs_so, FILE* packed_relocs_so) {
  relocation_packer::ElfFile<ELF> elf_file(fileno(packed_relocs_so));

  // Ensure packing already packed elf-file does not fail the build.
  EXPECT_TRUE(elf_file.PackRelocations());

  // Unpack golden relocations, and check files are now identical.
  EXPECT_TRUE(elf_file.UnpackRelocations());
  CheckFileContentsEqual(packed_relocs_so, relocs_so);

  CloseRelocsTestFiles(relocs_so, packed_relocs_so);
}

static void RunUnpackRelocationsTestFor(const std::string& arch) {
  ASSERT_NE(static_cast<uint32_t>(EV_NONE), elf_version(EV_CURRENT));

  FILE* relocs_so = NULL;
  FILE* packed_relocs_so = NULL;
  OpenRelocsTestFiles(arch, &relocs_so, &packed_relocs_so);

  if (relocs_so != NULL && packed_relocs_so != NULL) {
    // lets detect elf class
    ASSERT_EQ(0, fseek(relocs_so, EI_CLASS, SEEK_SET))
        << "Invalid file length: " << strerror(errno);
    uint8_t elf_class = 0;
    ASSERT_EQ(1U, fread(&elf_class, 1, 1, relocs_so));
    ASSERT_EQ(0, fseek(relocs_so, 0, SEEK_SET));
    if (elf_class == ELFCLASS32) {
      ProcessUnpack<ELF32_traits>(relocs_so, packed_relocs_so);
    } else {
      ProcessUnpack<ELF64_traits>(relocs_so, packed_relocs_so);
    }
  }
}

template <typename ELF>
static void ProcessPack(FILE* relocs_so, FILE* packed_relocs_so) {
  relocation_packer::ElfFile<ELF> elf_file(fileno(relocs_so));

  // Ensure unpacking fails (not packed).
  EXPECT_FALSE(elf_file.UnpackRelocations());

  // Pack relocations, and check files are now identical.
  EXPECT_TRUE(elf_file.PackRelocations());
  CheckFileContentsEqual(relocs_so, packed_relocs_so);

  CloseRelocsTestFiles(relocs_so, packed_relocs_so);
}

static void RunPackRelocationsTestFor(const std::string& arch) {
  ASSERT_NE(static_cast<uint32_t>(EV_NONE), elf_version(EV_CURRENT));

  FILE* relocs_so = NULL;
  FILE* packed_relocs_so = NULL;
  OpenRelocsTestFiles(arch, &relocs_so, &packed_relocs_so);

  if (relocs_so != NULL && packed_relocs_so != NULL) {
    // lets detect elf class
    ASSERT_EQ(0, fseek(packed_relocs_so, EI_CLASS, SEEK_SET))
        << "Invalid file length: " << strerror(errno);
    uint8_t elf_class = 0;
    ASSERT_EQ(1U, fread(&elf_class, 1, 1, packed_relocs_so));
    fseek(packed_relocs_so, 0, SEEK_SET);
    if (elf_class == ELFCLASS32) {
      ProcessPack<ELF32_traits>(relocs_so, packed_relocs_so);
    } else {
      ProcessPack<ELF64_traits>(relocs_so, packed_relocs_so);
    }
  }
}

}  // namespace

namespace relocation_packer {

TEST(ElfFile, PackRelocationsArm32) {
  RunPackRelocationsTestFor("arm32");
}

TEST(ElfFile, PackRelocationsArm64) {
  RunPackRelocationsTestFor("arm64");
}

TEST(ElfFile, PackRelocationsMips32) {
  RunPackRelocationsTestFor("mips32");
}

TEST(ElfFile, PackRelocationsIa32) {
  RunPackRelocationsTestFor("ia32");
}

TEST(ElfFile, PackRelocationsX64) {
  RunPackRelocationsTestFor("x64");
}

TEST(ElfFile, UnpackRelocationsArm32) {
  RunUnpackRelocationsTestFor("arm32");
}

TEST(ElfFile, UnpackRelocationsArm64) {
  RunUnpackRelocationsTestFor("arm64");
}

TEST(ElfFile, UnpackRelocationsMips32) {
  RunUnpackRelocationsTestFor("mips32");
}

TEST(ElfFile, UnpackRelocationsIa32) {
  RunUnpackRelocationsTestFor("ia32");
}

TEST(ElfFile, UnpackRelocationsX64) {
  RunUnpackRelocationsTestFor("x64");
}

}  // namespace relocation_packer
