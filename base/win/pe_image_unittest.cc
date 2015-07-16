// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file contains unit tests for PEImage.
#include <algorithm>
#include <vector>

#include "base/files/file_path.h"
#include "base/path_service.h"
#include "base/win/pe_image.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace win {

namespace {

// Just counts the number of invocations.
bool ImportsCallback(const PEImage& image,
                     LPCSTR module,
                     DWORD ordinal,
                     LPCSTR name,
                     DWORD hint,
                     PIMAGE_THUNK_DATA iat,
                     PVOID cookie) {
  int* count = reinterpret_cast<int*>(cookie);
  (*count)++;
  return true;
}

// Just counts the number of invocations.
bool SectionsCallback(const PEImage& image,
                      PIMAGE_SECTION_HEADER header,
                      PVOID section_start,
                      DWORD section_size,
                      PVOID cookie) {
  int* count = reinterpret_cast<int*>(cookie);
  (*count)++;
  return true;
}

// Just counts the number of invocations.
bool RelocsCallback(const PEImage& image,
                    WORD type,
                    PVOID address,
                    PVOID cookie) {
  int* count = reinterpret_cast<int*>(cookie);
  (*count)++;
  return true;
}

// Just counts the number of invocations.
bool ImportChunksCallback(const PEImage& image,
                          LPCSTR module,
                          PIMAGE_THUNK_DATA name_table,
                          PIMAGE_THUNK_DATA iat,
                          PVOID cookie) {
  int* count = reinterpret_cast<int*>(cookie);
  (*count)++;
  return true;
}

// Just counts the number of invocations.
bool DelayImportChunksCallback(const PEImage& image,
                               PImgDelayDescr delay_descriptor,
                               LPCSTR module,
                               PIMAGE_THUNK_DATA name_table,
                               PIMAGE_THUNK_DATA iat,
                               PIMAGE_THUNK_DATA bound_iat,
                               PIMAGE_THUNK_DATA unload_iat,
                               PVOID cookie) {
  int* count = reinterpret_cast<int*>(cookie);
  (*count)++;
  return true;
}

// Just counts the number of invocations.
bool ExportsCallback(const PEImage& image,
                     DWORD ordinal,
                     DWORD hint,
                     LPCSTR name,
                     PVOID function,
                     LPCSTR forward,
                     PVOID cookie) {
  int* count = reinterpret_cast<int*>(cookie);
  (*count)++;
  return true;
}

}  // namespace

// Tests that we are able to enumerate stuff from a PE file, and that
// the actual number of items found matches an expected value.
TEST(PEImageTest, EnumeratesPE) {
  base::FilePath pe_image_test_path;
  ASSERT_TRUE(PathService::Get(DIR_TEST_DATA, &pe_image_test_path));
  pe_image_test_path = pe_image_test_path.Append(FILE_PATH_LITERAL("pe_image"));

#if defined(ARCH_CPU_64_BITS)
  pe_image_test_path =
      pe_image_test_path.Append(FILE_PATH_LITERAL("pe_image_test_64.dll"));
  const int sections = 6;
  const int imports_dlls = 2;
  const int delay_dlls = 2;
  const int exports = 2;
  const int imports = 69;
  const int delay_imports = 2;
  const int relocs = 632;
#else
  pe_image_test_path =
      pe_image_test_path.Append(FILE_PATH_LITERAL("pe_image_test_32.dll"));
  const int sections = 5;
  const int imports_dlls = 2;
  const int delay_dlls = 2;
  const int exports = 2;
  const int imports = 66;
  const int delay_imports = 2;
  const int relocs = 1586;
#endif

  HMODULE module = LoadLibrary(pe_image_test_path.value().c_str());
  ASSERT_TRUE(NULL != module);

  PEImage pe(module);
  int count = 0;
  EXPECT_TRUE(pe.VerifyMagic());

  pe.EnumSections(SectionsCallback, &count);
  EXPECT_EQ(sections, count);

  count = 0;
  pe.EnumImportChunks(ImportChunksCallback, &count);
  EXPECT_EQ(imports_dlls, count);

  count = 0;
  pe.EnumDelayImportChunks(DelayImportChunksCallback, &count);
  EXPECT_EQ(delay_dlls, count);

  count = 0;
  pe.EnumExports(ExportsCallback, &count);
  EXPECT_EQ(exports, count);

  count = 0;
  pe.EnumAllImports(ImportsCallback, &count);
  EXPECT_EQ(imports, count);

  count = 0;
  pe.EnumAllDelayImports(ImportsCallback, &count);
  EXPECT_EQ(delay_imports, count);

  count = 0;
  pe.EnumRelocs(RelocsCallback, &count);
  EXPECT_EQ(relocs, count);

  FreeLibrary(module);
}

// Tests that we can locate an specific exported symbol, by name and by ordinal.
TEST(PEImageTest, RetrievesExports) {
  HMODULE module = LoadLibrary(L"advapi32.dll");
  ASSERT_TRUE(NULL != module);

  PEImage pe(module);
  WORD ordinal;

  EXPECT_TRUE(pe.GetProcOrdinal("RegEnumKeyExW", &ordinal));

  FARPROC address1 = pe.GetProcAddress("RegEnumKeyExW");
  FARPROC address2 = pe.GetProcAddress(reinterpret_cast<char*>(ordinal));
  EXPECT_TRUE(address1 != NULL);
  EXPECT_TRUE(address2 != NULL);
  EXPECT_TRUE(address1 == address2);

  FreeLibrary(module);
}

// Test that we can get debug id out of a module.
TEST(PEImageTest, GetDebugId) {
  HMODULE module = LoadLibrary(L"advapi32.dll");
  ASSERT_TRUE(NULL != module);

  PEImage pe(module);
  GUID guid = {0};
  DWORD age = 0;
  EXPECT_TRUE(pe.GetDebugId(&guid, &age));

  GUID empty_guid = {0};
  EXPECT_TRUE(!IsEqualGUID(empty_guid, guid));
  EXPECT_NE(0U, age);
  FreeLibrary(module);
}

}  // namespace win
}  // namespace base
