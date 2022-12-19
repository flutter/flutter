// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/doctor_validator.dart';
import 'package:flutter_tools/src/windows/windows_version_validator.dart';

import '../src/common.dart';
import '../src/fake_process_manager.dart';

/// Example output from `systeminfo` from a Windows 10 host
const String validWindows10StdOut = r'''
Host Name:                 XXXXXXXXXXXX
OS Name:                   Microsoft Windows 10 Enterprise
OS Version:                10.0.19044 N/A Build 19044
OS Manufacturer:           Microsoft Corporation
OS Configuration:          Member Workstation
OS Build Type:             Multiprocessor Free
Registered Owner:          N/A
Registered Organization:   N/A
Product ID:                XXXXXXXXXXXX
Original Install Date:     8/4/2022, 2:51:28 PM
System Boot Time:          8/10/2022, 1:03:10 PM
System Manufacturer:       Google
System Model:              Google Compute Engine
System Type:               x64-based PC
Processor(s):              1 Processor(s) Installed.
                           [01]: AMD64 Family 23 Model 49 Stepping 0 AuthenticAMD ~2250 Mhz
BIOS Version:              Google Google, 6/29/2022
Windows Directory:         C:\\Windows
System Directory:          C:\\Windows\\system32
Boot Device:               \\Device\\HarddiskVolume2
System Locale:             en-us;English (United States)
Input Locale:              en-us;English (United States)
Time Zone:                 (UTC-08:00) Pacific Time (US & Canada)
Total Physical Memory:     32,764 MB
Available Physical Memory: 17,852 MB
Virtual Memory: Max Size:  33,788 MB
Virtual Memory: Available: 18,063 MB
Virtual Memory: In Use:    15,725 MB
Page File Location(s):     C:\\pagefile.sys
Domain:                    ad.corp.google.com
Logon Server:              \\CBF-DC-8
Hotfix(s):                 7 Hotfix(s) Installed.
                           [01]: KB5013624
                           [02]: KB5003791
                           [03]: KB5012170
                           [04]: KB5016616
                           [05]: KB5014032
                           [06]: KB5014671
                           [07]: KB5015895
Hyper-V Requirements:      A hypervisor has been detected. Features required for Hyper-V will not be displayed.
''';

const String validWindows11CnStdOut = r'''
主机名:           XXXXXXXXXXXX
OS 名称:          Microsoft Windows 11 专业版
OS 版本:          10.0.22621 暂缺 Build 22621
OS 制造商:        Microsoft Corporation
OS 配置:          独立工作站
OS 构建类型:      Multiprocessor Free
注册的所有人:     暂缺
注册的组织:       暂缺
产品 ID:          XXXXXXXXXXXX
初始安装日期:     2022/11/9, 13:33:50
系统启动时间:     2022/11/30, 13:36:47
系统制造商:       ASUS
系统型号:         System Product Name
系统类型:         x64-based PC
处理器:           安装了 1 个处理器。
                  [01]: Intel64 Family 6 Model 151 Stepping 2 GenuineIntel ~3600 Mhz
BIOS 版本:        American Megatrends Inc. 2103, 2022/9/30
Windows 目录:     C:\WINDOWS
系统目录:         C:\WINDOWS\system32
启动设备:         \Device\HarddiskVolume1
系统区域设置:     zh-cn;中文(中国)
输入法区域设置:   zh-cn;中文(中国)
时区:             (UTC+08:00) 北京，重庆，香港特别行政区，乌鲁木齐
物理内存总量:     65,277 MB
可用的物理内存:   55,333 MB
虚拟内存: 最大值: 75,005 MB
虚拟内存: 可用:   61,781 MB
虚拟内存: 使用中: 13,224 MB
页面文件位置:     C:\pagefile.sys
域:               WORKGROUP
登录服务器:       \\XXXXXXXXXXXX
修补程序:         安装了 3 个修补程序。
                  [01]: KB5020622
                  [02]: KB5019980
                  [03]: KB5019304
Hyper-V 要求:     已检测到虚拟机监控程序。将不显示 Hyper-V 所需的功能。
''';

/// Example output from `systeminfo` from version != 10
const String invalidWindowsStdOut = r'''
Host Name:                 XXXXXXXXXXXX
OS Name:                   Microsoft Windows 8.1 Enterprise
OS Version:                6.3.9600 Build 9600
OS Manufacturer:           Microsoft Corporation
OS Configuration:          Member Workstation
OS Build Type:             Multiprocessor Free
Registered Owner:          N/A
Registered Organization:   N/A
Product ID:                XXXXXXXXXXXX
Original Install Date:     8/4/2022, 2:51:28 PM
System Boot Time:          8/10/2022, 1:03:10 PM
System Manufacturer:       Google
System Model:              Google Compute Engine
System Type:               x64-based PC
Processor(s):              1 Processor(s) Installed.
                           [01]: AMD64 Family 23 Model 49 Stepping 0 AuthenticAMD ~2250 Mhz
BIOS Version:              Google Google, 6/29/2022
Windows Directory:         C:\\Windows
System Directory:          C:\\Windows\\system32
Boot Device:               \\Device\\HarddiskVolume2
System Locale:             en-us;English (United States)
Input Locale:              en-us;English (United States)
Time Zone:                 (UTC-08:00) Pacific Time (US & Canada)
Total Physical Memory:     32,764 MB
Available Physical Memory: 17,852 MB
Virtual Memory: Max Size:  33,788 MB
Virtual Memory: Available: 18,063 MB
Virtual Memory: In Use:    15,725 MB
Page File Location(s):     C:\\pagefile.sys
Domain:                    ad.corp.google.com
Logon Server:              \\CBF-DC-8
Hotfix(s):                 7 Hotfix(s) Installed.
                           [01]: KB5013624
                           [02]: KB5003791
                           [03]: KB5012170
                           [04]: KB5016616
                           [05]: KB5014032
                           [06]: KB5014671
                           [07]: KB5015895
Hyper-V Requirements:      A hypervisor has been detected. Features required for Hyper-V will not be displayed.
''';

/// The expected validation result object for
/// a passing windows version test
const ValidationResult validWindows10ValidationResult = ValidationResult(
  ValidationType.success,
  <ValidationMessage>[],
  statusInfo: 'Installed version of Windows is version 10 or higher',
);

/// The expected validation result object for
/// a failing exit code (!= 0)
const ValidationResult failedValidationResult = ValidationResult(
  ValidationType.missing,
  <ValidationMessage>[],
  statusInfo: 'Exit status from running `systeminfo` was unsuccessful',
);

/// The expected validation result object for
/// a passing windows version test
const ValidationResult invalidWindowsValidationResult = ValidationResult(
  ValidationType.missing,
  <ValidationMessage>[],
  statusInfo: 'Unable to confirm if installed Windows version is 10 or greater',
);

/// Expected return from a nonzero exitcode when
/// running systeminfo
const ValidationResult invalidExitCodeValidationResult = ValidationResult(
  ValidationType.missing,
  <ValidationMessage>[],
  statusInfo: 'Exit status from running `systeminfo` was unsuccessful',
);

void main() {
  testWithoutContext('Successfully running windows version check on windows 10',
      () async {
    final WindowsVersionValidator windowsVersionValidator =
        WindowsVersionValidator(
      processManager: FakeProcessManager.list(
        <FakeCommand>[
          const FakeCommand(
            command: <String>['systeminfo'],
            stdout: validWindows10StdOut,
          ),
        ],
      ),
    );

    final ValidationResult result = await windowsVersionValidator.validate();

    expect(result.type, validWindows10ValidationResult.type,
        reason: 'The ValidationResult type should be the same (installed)');
    expect(result.statusInfo, validWindows10ValidationResult.statusInfo,
        reason: 'The ValidationResult statusInfo messages should be the same');
  });

  testWithoutContext(
    'Successfully running windows version check on windows 11 CN',
    () async {
      final WindowsVersionValidator windowsVersionValidator =
          WindowsVersionValidator(
        processManager: FakeProcessManager.list(
          <FakeCommand>[
            const FakeCommand(
              command: <String>['systeminfo'],
              stdout: validWindows11CnStdOut,
            ),
          ],
        ),
      );

      final ValidationResult result = await windowsVersionValidator.validate();

      expect(
        result.type,
        validWindows10ValidationResult.type,
        reason: 'The ValidationResult type should be the same (installed)',
      );
      expect(
        result.statusInfo,
        validWindows10ValidationResult.statusInfo,
        reason: 'The ValidationResult statusInfo messages should be the same',
      );
    },
  );

  testWithoutContext('Failing to invoke the `systeminfo` command', () async {
    final WindowsVersionValidator windowsVersionValidator =
        WindowsVersionValidator(
      processManager: FakeProcessManager.list(
        <FakeCommand>[
          const FakeCommand(
            command: <String>['systeminfo'],
            stdout: validWindows10StdOut,
            exitCode: 1,
          ),
        ],
      ),
    );

    final ValidationResult result = await windowsVersionValidator.validate();

    expect(result.type, failedValidationResult.type,
        reason: 'The ValidationResult type should be the same (missing)');
    expect(result.statusInfo, failedValidationResult.statusInfo,
        reason: 'The ValidationResult statusInfo messages should be the same');
  });

  testWithoutContext('Identifying a windows version before 10', () async {
    final WindowsVersionValidator windowsVersionValidator =
        WindowsVersionValidator(
      processManager: FakeProcessManager.list(
        <FakeCommand>[
          const FakeCommand(
            command: <String>['systeminfo'],
            stdout: invalidWindowsStdOut,
          ),
        ],
      ),
    );

    final ValidationResult result = await windowsVersionValidator.validate();

    expect(result.type, invalidWindowsValidationResult.type,
        reason: 'The ValidationResult type should be the same (missing)');
    expect(result.statusInfo, invalidWindowsValidationResult.statusInfo,
        reason: 'The ValidationResult statusInfo messages should be the same');
  });

  testWithoutContext(
      'Running into an nonzero exit code from systeminfo command', () async {
    final WindowsVersionValidator windowsVersionValidator =
        WindowsVersionValidator(
      processManager: FakeProcessManager.list(
        <FakeCommand>[
          const FakeCommand(command: <String>['systeminfo'], exitCode: 1),
        ],
      ),
    );

    final ValidationResult result = await windowsVersionValidator.validate();

    expect(result.type, invalidExitCodeValidationResult.type,
        reason: 'The ValidationResult type should be the same (missing)');
    expect(result.statusInfo, invalidExitCodeValidationResult.statusInfo,
        reason: 'The ValidationResult statusInfo messages should be the same');
  });

  testWithoutContext('Unit testing on a regex pattern validator', () async {
    const String testStr = r'''
OS Version:                10.0.19044 N/A Build 19044
OSz Version:                10.0.19044 N/A Build 19044
OxS Version:                10.0.19044 N/A Build 19044
OS Version:                10.19044 N/A Build 19044
OS Version:                10.x.19044 N/A Build 19044
OS Version:                10.0.19044 N/A Build 19044
OS Version:                .0.19044 N/A Build 19044
OS 版本:          10.0.22621 暂缺 Build 22621
''';

    final RegExp regex = RegExp(
      kWindowsOSVersionSemVerPattern,
      multiLine: true,
    );
    final Iterable<RegExpMatch> matches = regex.allMatches(testStr);

    expect(
      matches.length,
      3,
      reason: 'There should be only two matches for the pattern provided',
    );
  });
}
