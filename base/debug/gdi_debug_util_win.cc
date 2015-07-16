// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include "base/debug/gdi_debug_util_win.h"

#include <cmath>

#include <psapi.h>
#include <TlHelp32.h>

#include "base/debug/alias.h"
#include "base/logging.h"
#include "base/win/scoped_handle.h"

namespace {

void CollectChildGDIUsageAndDie(DWORD parent_pid) {
  HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  CHECK_NE(INVALID_HANDLE_VALUE, snapshot);

  int child_count = 0;
  base::debug::Alias(&child_count);
  int peak_gdi_count = 0;
  base::debug::Alias(&peak_gdi_count);
  int sum_gdi_count = 0;
  base::debug::Alias(&sum_gdi_count);
  int sum_user_count = 0;
  base::debug::Alias(&sum_user_count);

  PROCESSENTRY32 proc_entry = {0};
  proc_entry.dwSize = sizeof(PROCESSENTRY32);
  CHECK(Process32First(snapshot, &proc_entry));

  do {
    if (parent_pid != proc_entry.th32ParentProcessID)
      continue;
    // Got a child process. Compute GDI usage.
    base::win::ScopedHandle process(
        OpenProcess(PROCESS_QUERY_INFORMATION,
                    FALSE,
                    proc_entry.th32ParentProcessID));
    if (!process.IsValid())
      continue;

    int num_gdi_handles = GetGuiResources(process.Get(), GR_GDIOBJECTS);
    int num_user_handles = GetGuiResources(process.Get(), GR_USEROBJECTS);

    // Compute sum and peak counts.
    ++child_count;
    sum_user_count += num_user_handles;
    sum_gdi_count += num_gdi_handles;
    if (peak_gdi_count < num_gdi_handles)
      peak_gdi_count = num_gdi_handles;

  } while (Process32Next(snapshot, &proc_entry));

  CloseHandle(snapshot);
  CHECK(false);
}

}  // namespace

namespace base {
namespace debug {

void GDIBitmapAllocFailure(BITMAPINFOHEADER* header, HANDLE shared_section) {
  // Make sure parameters are saved in the minidump.
  DWORD last_error = GetLastError();

  LONG width = header->biWidth;
  LONG heigth = header->biHeight;

  base::debug::Alias(&last_error);
  base::debug::Alias(&width);
  base::debug::Alias(&heigth);
  base::debug::Alias(&shared_section);

  int num_user_handles = GetGuiResources(GetCurrentProcess(),
                                         GR_USEROBJECTS);

  int num_gdi_handles = GetGuiResources(GetCurrentProcess(),
                                        GR_GDIOBJECTS);
  if (num_gdi_handles == 0) {
    DWORD get_gui_resources_error = GetLastError();
    base::debug::Alias(&get_gui_resources_error);
    CHECK(false);
  }

  base::debug::Alias(&num_gdi_handles);
  base::debug::Alias(&num_user_handles);

  const DWORD kLotsOfHandles = 9990;
  CHECK_LE(num_gdi_handles, kLotsOfHandles);

  PROCESS_MEMORY_COUNTERS_EX pmc;
  pmc.cb = sizeof(pmc);
  CHECK(GetProcessMemoryInfo(GetCurrentProcess(),
                             reinterpret_cast<PROCESS_MEMORY_COUNTERS*>(&pmc),
                             sizeof(pmc)));
  const size_t kLotsOfMemory = 1500 * 1024 * 1024; // 1.5GB
  CHECK_LE(pmc.PagefileUsage, kLotsOfMemory);
  CHECK_LE(pmc.PrivateUsage, kLotsOfMemory);

  void* small_data = NULL;
  base::debug::Alias(&small_data);

  if (std::abs(heigth) * width > 100) {
    // Huh, that's weird.  We don't have crazy handle count, we don't have
    // ridiculous memory usage. Try to allocate a small bitmap and see if that
    // fails too.
    header->biWidth = 5;
    header->biHeight = -5;
    HBITMAP small_bitmap = CreateDIBSection(
        NULL, reinterpret_cast<BITMAPINFO*>(&header),
        0, &small_data, shared_section, 0);
    CHECK(small_bitmap != NULL);
    DeleteObject(small_bitmap);
  }
  // Maybe the child processes are the ones leaking GDI or USER resouces.
  CollectChildGDIUsageAndDie(GetCurrentProcessId());
}

}  // namespace debug
}  // namespace base
