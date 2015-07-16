# Copyright (C) 2011 Google Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1.  Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
# 2.  Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import unittest

from webkitpy.common.system.crashlogs import CrashLogs
from webkitpy.common.system.filesystem_mock import MockFileSystem
from webkitpy.common.system.systemhost import SystemHost
from webkitpy.common.system.systemhost_mock import MockSystemHost


def make_mock_crash_report_darwin(process_name, pid):
    return """Process:         {process_name} [{pid}]
Path:            /Volumes/Data/slave/snowleopard-intel-release-tests/build/WebKitBuild/Release/{process_name}
Identifier:      {process_name}
Version:         ??? (???)
Code Type:       X86-64 (Native)
Parent Process:  Python [2578]

Date/Time:       2011-12-07 13:27:34.816 -0800
OS Version:      Mac OS X 10.6.8 (10K549)
Report Version:  6

Interval Since Last Report:          1660 sec
Crashes Since Last Report:           1
Per-App Crashes Since Last Report:   1
Anonymous UUID:                      507D4EEB-9D70-4E2E-B322-2D2F0ABFEDC0

Exception Type:  EXC_BREAKPOINT (SIGTRAP)
Exception Codes: 0x0000000000000002, 0x0000000000000000
Crashed Thread:  0

Dyld Error Message:
  Library not loaded: /Volumes/Data/WebKit-BuildSlave/snowleopard-intel-release/build/WebKitBuild/Release/WebCore.framework/Versions/A/WebCore
  Referenced from: /Volumes/Data/slave/snowleopard-intel-release/build/WebKitBuild/Release/WebKit.framework/Versions/A/WebKit
  Reason: image not found

Binary Images:
    0x7fff5fc00000 -     0x7fff5fc3be0f  dyld 132.1 (???) <29DECB19-0193-2575-D838-CF743F0400B2> /usr/lib/dyld

System Profile:
Model: Xserve3,1, BootROM XS31.0081.B04, 8 processors, Quad-Core Intel Xeon, 2.26 GHz, 6 GB, SMC 1.43f4
Graphics: NVIDIA GeForce GT 120, NVIDIA GeForce GT 120, PCIe, 256 MB
Memory Module: global_name
Network Service: Ethernet 2, Ethernet, en1
PCI Card: NVIDIA GeForce GT 120, sppci_displaycontroller, MXM-Slot
Serial ATA Device: OPTIARC DVD RW AD-5670S
""".format(process_name=process_name, pid=pid)

class CrashLogsTest(unittest.TestCase):
    def test_find_log_darwin(self):
        if not SystemHost().platform.is_mac():
            return

        older_mock_crash_report = make_mock_crash_report_darwin('DumpRenderTree', 28528)
        mock_crash_report = make_mock_crash_report_darwin('DumpRenderTree', 28530)
        newer_mock_crash_report = make_mock_crash_report_darwin('DumpRenderTree', 28529)
        other_process_mock_crash_report = make_mock_crash_report_darwin('FooProcess', 28527)
        misformatted_mock_crash_report = 'Junk that should not appear in a crash report' + make_mock_crash_report_darwin('DumpRenderTree', 28526)[200:]
        files = {}
        files['/Users/mock/Library/Logs/DiagnosticReports/DumpRenderTree_2011-06-13-150718_quadzen.crash'] = older_mock_crash_report
        files['/Users/mock/Library/Logs/DiagnosticReports/DumpRenderTree_2011-06-13-150719_quadzen.crash'] = mock_crash_report
        files['/Users/mock/Library/Logs/DiagnosticReports/DumpRenderTree_2011-06-13-150720_quadzen.crash'] = newer_mock_crash_report
        files['/Users/mock/Library/Logs/DiagnosticReports/DumpRenderTree_2011-06-13-150721_quadzen.crash'] = None
        files['/Users/mock/Library/Logs/DiagnosticReports/DumpRenderTree_2011-06-13-150722_quadzen.crash'] = other_process_mock_crash_report
        files['/Users/mock/Library/Logs/DiagnosticReports/DumpRenderTree_2011-06-13-150723_quadzen.crash'] = misformatted_mock_crash_report
        filesystem = MockFileSystem(files)
        crash_logs = CrashLogs(MockSystemHost(filesystem=filesystem))
        log = crash_logs.find_newest_log("DumpRenderTree")
        self.assertMultiLineEqual(log, newer_mock_crash_report)
        log = crash_logs.find_newest_log("DumpRenderTree", 28529)
        self.assertMultiLineEqual(log, newer_mock_crash_report)
        log = crash_logs.find_newest_log("DumpRenderTree", 28530)
        self.assertMultiLineEqual(log, mock_crash_report)
        log = crash_logs.find_newest_log("DumpRenderTree", 28531)
        self.assertIsNone(log)
        log = crash_logs.find_newest_log("DumpRenderTree", newer_than=1.0)
        self.assertIsNone(log)

        def bad_read(path):
            raise IOError('IOError: No such file or directory')

        def bad_mtime(path):
            raise OSError('OSError: No such file or directory')

        filesystem.read_text_file = bad_read
        log = crash_logs.find_newest_log("DumpRenderTree", 28531, include_errors=True)
        self.assertIn('IOError: No such file or directory', log)

        filesystem = MockFileSystem(files)
        crash_logs = CrashLogs(MockSystemHost(filesystem=filesystem))
        filesystem.mtime = bad_mtime
        log = crash_logs.find_newest_log("DumpRenderTree", newer_than=1.0, include_errors=True)
        self.assertIn('OSError: No such file or directory', log)
