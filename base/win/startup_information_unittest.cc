// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <windows.h>

#include <string>

#include "base/command_line.h"
#include "base/test/multiprocess_test.h"
#include "base/win/scoped_handle.h"
#include "base/win/scoped_process_information.h"
#include "base/win/startup_information.h"
#include "base/win/windows_version.h"
#include "testing/multiprocess_func_list.h"

const wchar_t kSectionName[] = L"EventTestSection";
const size_t kSectionSize = 4096;

MULTIPROCESS_TEST_MAIN(FireInheritedEvents) {
  HANDLE section = ::OpenFileMappingW(PAGE_READWRITE, false, kSectionName);
  HANDLE* events = reinterpret_cast<HANDLE*>(::MapViewOfFile(section,
      PAGE_READWRITE, 0, 0, kSectionSize));
  // This event should not be valid because it wasn't explicitly inherited.
  if (::SetEvent(events[1]))
    return -1;
  // This event should be valid because it was explicitly inherited.
  if (!::SetEvent(events[0]))
    return -1;

  return 0;
}

class StartupInformationTest : public base::MultiProcessTest {};

// Verify that only the explicitly specified event is inherited.
TEST_F(StartupInformationTest, InheritStdOut) {
  if (base::win::GetVersion() < base::win::VERSION_VISTA)
    return;

  base::win::StartupInformation startup_info;

  HANDLE section = ::CreateFileMappingW(INVALID_HANDLE_VALUE, NULL,
                                        PAGE_READWRITE, 0, kSectionSize,
                                        kSectionName);
  ASSERT_TRUE(section);

  HANDLE* events = reinterpret_cast<HANDLE*>(::MapViewOfFile(section,
      FILE_MAP_READ | FILE_MAP_WRITE, 0, 0, kSectionSize));

  // Make two inheritable events.
  SECURITY_ATTRIBUTES security_attributes = { sizeof(security_attributes),
                                              NULL, true };
  events[0] = ::CreateEvent(&security_attributes, false, false, NULL);
  ASSERT_TRUE(events[0]);
  events[1] = ::CreateEvent(&security_attributes, false, false, NULL);
  ASSERT_TRUE(events[1]);

  ASSERT_TRUE(startup_info.InitializeProcThreadAttributeList(1));
  ASSERT_TRUE(startup_info.UpdateProcThreadAttribute(
      PROC_THREAD_ATTRIBUTE_HANDLE_LIST, &events[0],
      sizeof(events[0])));

  std::wstring cmd_line =
      MakeCmdLine("FireInheritedEvents").GetCommandLineString();

  PROCESS_INFORMATION temp_process_info = {};
  ASSERT_TRUE(::CreateProcess(NULL, &cmd_line[0],
                              NULL, NULL, true, EXTENDED_STARTUPINFO_PRESENT,
                              NULL, NULL, startup_info.startup_info(),
                              &temp_process_info)) << ::GetLastError();
  base::win::ScopedProcessInformation process_info(temp_process_info);

  // Only the first event should be signalled
  EXPECT_EQ(WAIT_OBJECT_0, ::WaitForMultipleObjects(2, events, false,
                                                    4000));
}

