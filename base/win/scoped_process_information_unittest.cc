// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <windows.h>

#include <string>

#include "base/command_line.h"
#include "base/process/kill.h"
#include "base/process/process.h"
#include "base/test/multiprocess_test.h"
#include "base/win/scoped_process_information.h"
#include "testing/multiprocess_func_list.h"

namespace {

const DWORD kProcessId = 4321;
const DWORD kThreadId = 1234;
const HANDLE kProcessHandle = reinterpret_cast<HANDLE>(7651);
const HANDLE kThreadHandle = reinterpret_cast<HANDLE>(1567);

void MockCreateProcess(base::win::ScopedProcessInformation* process_info) {
  PROCESS_INFORMATION process_information = {};
  process_information.dwProcessId = kProcessId;
  process_information.dwThreadId = kThreadId;
  process_information.hProcess = kProcessHandle;
  process_information.hThread = kThreadHandle;
  process_info->Set(process_information);
}

}  // namespace

class ScopedProcessInformationTest : public base::MultiProcessTest {
 protected:
  void DoCreateProcess(const std::string& main_id,
                       PROCESS_INFORMATION* process_handle);
};

MULTIPROCESS_TEST_MAIN(ReturnSeven) {
  return 7;
}

MULTIPROCESS_TEST_MAIN(ReturnNine) {
  return 9;
}

void ScopedProcessInformationTest::DoCreateProcess(
    const std::string& main_id, PROCESS_INFORMATION* process_handle) {
  std::wstring cmd_line = MakeCmdLine(main_id).GetCommandLineString();
  STARTUPINFO startup_info = {};
  startup_info.cb = sizeof(startup_info);

  EXPECT_TRUE(::CreateProcess(NULL, &cmd_line[0],
                              NULL, NULL, false, 0, NULL, NULL,
                              &startup_info, process_handle));
}

TEST_F(ScopedProcessInformationTest, InitiallyInvalid) {
  base::win::ScopedProcessInformation process_info;
  ASSERT_FALSE(process_info.IsValid());
}

TEST_F(ScopedProcessInformationTest, Receive) {
  base::win::ScopedProcessInformation process_info;
  MockCreateProcess(&process_info);

  EXPECT_TRUE(process_info.IsValid());
  EXPECT_EQ(kProcessId, process_info.process_id());
  EXPECT_EQ(kThreadId, process_info.thread_id());
  EXPECT_EQ(kProcessHandle, process_info.process_handle());
  EXPECT_EQ(kThreadHandle, process_info.thread_handle());
  process_info.Take();
}

TEST_F(ScopedProcessInformationTest, TakeProcess) {
  base::win::ScopedProcessInformation process_info;
  MockCreateProcess(&process_info);

  HANDLE process = process_info.TakeProcessHandle();
  EXPECT_EQ(kProcessHandle, process);
  EXPECT_EQ(NULL, process_info.process_handle());
  EXPECT_EQ(0, process_info.process_id());
  EXPECT_TRUE(process_info.IsValid());
  process_info.Take();
}

TEST_F(ScopedProcessInformationTest, TakeThread) {
  base::win::ScopedProcessInformation process_info;
  MockCreateProcess(&process_info);

  HANDLE thread = process_info.TakeThreadHandle();
  EXPECT_EQ(kThreadHandle, thread);
  EXPECT_EQ(NULL, process_info.thread_handle());
  EXPECT_EQ(0, process_info.thread_id());
  EXPECT_TRUE(process_info.IsValid());
  process_info.Take();
}

TEST_F(ScopedProcessInformationTest, TakeBoth) {
  base::win::ScopedProcessInformation process_info;
  MockCreateProcess(&process_info);

  process_info.TakeProcessHandle();
  process_info.TakeThreadHandle();
  EXPECT_FALSE(process_info.IsValid());
  process_info.Take();
}

TEST_F(ScopedProcessInformationTest, TakeWholeStruct) {
  base::win::ScopedProcessInformation process_info;
  MockCreateProcess(&process_info);

  PROCESS_INFORMATION to_discard = process_info.Take();
  EXPECT_EQ(kProcessId, to_discard.dwProcessId);
  EXPECT_EQ(kThreadId, to_discard.dwThreadId);
  EXPECT_EQ(kProcessHandle, to_discard.hProcess);
  EXPECT_EQ(kThreadHandle, to_discard.hThread);
  EXPECT_FALSE(process_info.IsValid());
}

TEST_F(ScopedProcessInformationTest, Duplicate) {
  PROCESS_INFORMATION temp_process_information;
  DoCreateProcess("ReturnSeven", &temp_process_information);
  base::win::ScopedProcessInformation process_info;
  process_info.Set(temp_process_information);

  base::win::ScopedProcessInformation duplicate;
  duplicate.DuplicateFrom(process_info);

  ASSERT_TRUE(process_info.IsValid());
  ASSERT_NE(0u, process_info.process_id());
  ASSERT_EQ(duplicate.process_id(), process_info.process_id());
  ASSERT_NE(0u, process_info.thread_id());
  ASSERT_EQ(duplicate.thread_id(), process_info.thread_id());

  // Validate that we have separate handles that are good.
  int exit_code = 0;
  base::Process process(process_info.TakeProcessHandle());
  ASSERT_TRUE(process.WaitForExit(&exit_code));
  ASSERT_EQ(7, exit_code);

  exit_code = 0;
  base::Process dup_process(duplicate.TakeProcessHandle());
  ASSERT_TRUE(dup_process.WaitForExit(&exit_code));
  ASSERT_EQ(7, exit_code);

  ASSERT_TRUE(::CloseHandle(process_info.TakeThreadHandle()));
  ASSERT_TRUE(::CloseHandle(duplicate.TakeThreadHandle()));
}

TEST_F(ScopedProcessInformationTest, Set) {
  base::win::ScopedProcessInformation base_process_info;
  MockCreateProcess(&base_process_info);

  PROCESS_INFORMATION base_struct = base_process_info.Take();

  base::win::ScopedProcessInformation process_info;
  process_info.Set(base_struct);

  EXPECT_EQ(kProcessId, process_info.process_id());
  EXPECT_EQ(kThreadId, process_info.thread_id());
  EXPECT_EQ(kProcessHandle, process_info.process_handle());
  EXPECT_EQ(kThreadHandle, process_info.thread_handle());
  base_struct = process_info.Take();
}
