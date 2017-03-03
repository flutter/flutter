# Copyright 2017 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This is a wrapper arround flutter.bat, which checks if the terminal supports
# ANSI codes to work around https://github.com/dart-lang/sdk/issues/28614.

Add-Type -MemberDefinition @"
[DllImport("kernel32.dll", SetLastError=true)]
public static extern bool SetConsoleMode(IntPtr hConsoleHandle, int mode);
[DllImport("kernel32.dll", SetLastError=true)]
public static extern IntPtr GetStdHandle(int handle);
[DllImport("kernel32.dll", SetLastError=true)]
public static extern bool GetConsoleMode(IntPtr handle, out int mode);
"@ -Namespace Win32 -Name NativeMethods

If (Test-Path Env:\FLUTTER_ANSI_TERMINAL) { Remove-Item Env:\FLUTTER_ANSI_TERMINAL }
$stdout = [Win32.NativeMethods]::GetStdHandle(-11) # STD_OUTPUT_HANDLE
If ($stdout -ne -1) {
    $mode = 0
    If ([Win32.NativeMethods]::GetConsoleMode($stdout, [ref]$mode)) {
        $mode = $mode -bor 4 # ENABLE_VIRTUAL_TERMINAL_PROCESSING
        If ([Win32.NativeMethods]::SetConsoleMode($stdout, $mode)) {
            $env:FLUTTER_ANSI_TERMINAL = "true"
        }
    }
}

flutter.bat $args
exit $LastExitCode
