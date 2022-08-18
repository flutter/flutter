// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:io';

import '../doctor_validator.dart';

class WindowsVersionValidator extends DoctorValidator {
  const WindowsVersionValidator() : super('Windows Version');
  @override
  Future<ValidationResult> validate() async {
//     const String x = r'''
// Host Name:                 WINDOWS-EY1
// OS Name:                   Microsoft Windows 10 Enterprise
// OS Version:                10.0.19044 N/A Build 19044
// OS Manufacturer:           Microsoft Corporation
// OS Configuration:          Member Workstation
// OS Build Type:             Multiprocessor Free
// Registered Owner:          N/A
// Registered Organization:   N/A
// Product ID:                00329-00000-00003-AA898
// Original Install Date:     8/4/2022, 2:51:28 PM
// System Boot Time:          8/10/2022, 1:03:10 PM
// System Manufacturer:       Google
// System Model:              Google Compute Engine
// System Type:               x64-based PC
// Processor(s):              1 Processor(s) Installed.
//                            [01]: AMD64 Family 23 Model 49 Stepping 0 AuthenticAMD ~2250 Mhz
// BIOS Version:              Google Google, 6/29/2022
// Windows Directory:         C:\\Windows
// System Directory:          C:\\Windows\\system32
// Boot Device:               \\Device\\HarddiskVolume2
// System Locale:             en-us;English (United States)
// Input Locale:              en-us;English (United States)
// Time Zone:                 (UTC-08:00) Pacific Time (US & Canada)
// Total Physical Memory:     32,764 MB
// Available Physical Memory: 17,852 MB
// Virtual Memory: Max Size:  33,788 MB
// Virtual Memory: Available: 18,063 MB
// Virtual Memory: In Use:    15,725 MB
// Page File Location(s):     C:\\pagefile.sys
// Domain:                    ad.corp.google.com
// Logon Server:              \\CBF-DC-8
// Hotfix(s):                 7 Hotfix(s) Installed.
//                            [01]: KB5013624
//                            [02]: KB5003791
//                            [03]: KB5012170
//                            [04]: KB5016616
//                            [05]: KB5014032
//                            [06]: KB5014671
//                            [07]: KB5015895
// Network Card(s):           1 NIC(s) Installed.
//                            [01]: Google VirtIO Ethernet Adapter
//                                  Connection Name: Ethernet
//                                  DHCP Enabled:    Yes
//                                  DHCP Server:     169.254.169.254
//                                  IP address(es)
//                                  [01]: 192.168.27.102
//                                  [02]: fe80::c16e:110a:e337:d32d
// Hyper-V Requirements:      A hypervisor has been detected. Features required for Hyper-V will not be displayed.
//   ''';

    final ProcessResult result = await Process.run('systeminfo', <String>[]);
    final String resultStdout = result.stdout as String;

    // Define the major versions that are not supported
    const List<String> unsupportedVersions = <String>[
      '7',
      '8',
    ];

    final List<String> elements = resultStdout.split('\n');

    // Regular expression pattern for identifying
    // semantic versioned strings
    // (ie. 10.5.4123)
    final RegExp regex = RegExp(r'^([0-9]+)\.([0-9]+)\.([0-9]+)$');

    // Define the list that will contain the matches;
    // if ran successfully, this list should have only
    // one item
    final List<String> versionList = <String>[];

    // Use two booleans to identify when you have found
    // the word 'version' and a version number that matches
    // the regex pattern above; only once both are found do
    // we report back a valid version
    bool versionText = false;
    bool versionSemver = false;
    String? version;
    for (int i = 0; i < elements.length; i++) {
      final String curLine = elements.elementAt(i);
      final List<String> lineElems = curLine.split(' ');

      for (int j = 0; j < lineElems.length; j++) {
        final String elem = lineElems.elementAt(j);
        final bool match = regex.hasMatch(lineElems.elementAt(j));

        if (match) {
          versionSemver = true;
          version = elem;
        }

        if (elem.toLowerCase().contains('version')) {
          versionText = true;
        }
      }

      // Once both booleans are true, add
      // the version to the list that will contain
      // at most, one element if ran as anticipated
      if (versionText && versionSemver && version != null) {
        versionList.add(version);
      }

      // Reset the boolean values for the next line
      versionText = false;
      versionSemver = false;
      version = null;
    }

    ValidationType windowsVersionStatus = ValidationType.missing;
    if (versionList.length == 1 &&
        unsupportedVersions
            .contains(versionList.elementAt(0).split('.').elementAt(0))) {
    } else if (versionList.length == 1) {
      windowsVersionStatus = ValidationType.installed;
    }

    return ValidationResult(
      windowsVersionStatus,
      const <ValidationMessage>[],
      statusInfo: 'Installed version of Windows is version 10 or higher',
    );
  }
}
