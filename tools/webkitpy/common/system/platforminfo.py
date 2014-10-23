# Copyright (c) 2011 Google Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#     * Neither the name of Google Inc. nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import re
import sys


class PlatformInfo(object):
    """This class provides a consistent (and mockable) interpretation of
    system-specific values (like sys.platform and platform.mac_ver())
    to be used by the rest of the webkitpy code base.

    Public (static) properties:
    -- os_name
    -- os_version

    Note that 'future' is returned for os_version if the operating system is
    newer than one known to the code.
    """

    def __init__(self, sys_module, platform_module, executive):
        self._executive = executive
        self._platform_module = platform_module
        self.os_name = self._determine_os_name(sys_module.platform)
        if self.os_name == 'linux':
            self.os_version = self._determine_linux_version()
        if self.os_name == 'freebsd':
            self.os_version = platform_module.release()
        if self.os_name.startswith('mac'):
            self.os_version = self._determine_mac_version(platform_module.mac_ver()[0])
        if self.os_name.startswith('win'):
            self.os_version = self._determine_win_version(self._win_version_tuple(sys_module))
        self._is_cygwin = sys_module.platform == 'cygwin'

    def is_mac(self):
        return self.os_name == 'mac'

    def is_win(self):
        return self.os_name == 'win'

    def is_cygwin(self):
        return self._is_cygwin

    def is_linux(self):
        return self.os_name == 'linux'

    def is_freebsd(self):
        return self.os_name == 'freebsd'

    def is_highdpi(self):
        if self.is_mac():
            output = self._executive.run_command(['system_profiler', 'SPDisplaysDataType'], error_handler=self._executive.ignore_error)
            if output and 'Retina: Yes' in output:
                return True
        return False

    def display_name(self):
        # platform.platform() returns Darwin information for Mac, which is just confusing.
        if self.is_mac():
            return "Mac OS X %s" % self._platform_module.mac_ver()[0]

        # Returns strings like:
        # Linux-2.6.18-194.3.1.el5-i686-with-redhat-5.5-Final
        # Windows-2008ServerR2-6.1.7600
        return self._platform_module.platform()

    def total_bytes_memory(self):
        if self.is_mac():
            return long(self._executive.run_command(["sysctl", "-n", "hw.memsize"]))
        return None

    def terminal_width(self):
        """Returns sys.maxint if the width cannot be determined."""
        try:
            if self.is_win():
                # From http://code.activestate.com/recipes/440694-determine-size-of-console-window-on-windows/
                from ctypes import windll, create_string_buffer
                handle = windll.kernel32.GetStdHandle(-12)  # -12 == stderr
                console_screen_buffer_info = create_string_buffer(22)  # 22 == sizeof(console_screen_buffer_info)
                if windll.kernel32.GetConsoleScreenBufferInfo(handle, console_screen_buffer_info):
                    import struct
                    _, _, _, _, _, left, _, right, _, _, _ = struct.unpack("hhhhHhhhhhh", console_screen_buffer_info.raw)
                    # Note that we return 1 less than the width since writing into the rightmost column
                    # automatically performs a line feed.
                    return right - left
                return sys.maxint
            else:
                import fcntl
                import struct
                import termios
                packed = fcntl.ioctl(sys.stderr.fileno(), termios.TIOCGWINSZ, '\0' * 8)
                _, columns, _, _ = struct.unpack('HHHH', packed)
                return columns
        except:
            return sys.maxint

    def _determine_os_name(self, sys_platform):
        if sys_platform == 'darwin':
            return 'mac'
        if sys_platform.startswith('linux'):
            return 'linux'
        if sys_platform in ('win32', 'cygwin'):
            return 'win'
        if sys_platform.startswith('freebsd'):
            return 'freebsd'
        raise AssertionError('unrecognized platform string "%s"' % sys_platform)

    def _determine_mac_version(self, mac_version_string):
        release_version = int(mac_version_string.split('.')[1])
        version_strings = {
            5: 'leopard',
            6: 'snowleopard',
            7: 'lion',
            8: 'mountainlion',
            9: 'mavericks',
        }
        assert release_version >= min(version_strings.keys())
        return version_strings.get(release_version, 'future')

    def _determine_linux_version(self):
        # FIXME: we ignore whatever the real version is and pretend it's lucid for now.
        return 'lucid'

    def _determine_win_version(self, win_version_tuple):
        if win_version_tuple[:3] == (6, 1, 7600):
            return '7sp0'
        if win_version_tuple[:2] == (6, 0):
            return 'vista'
        if win_version_tuple[:2] == (5, 1):
            return 'xp'
        assert win_version_tuple[0] > 6 or win_version_tuple[1] >= 1, 'Unrecognized Windows version tuple: "%s"' % (win_version_tuple,)
        return 'future'

    def _win_version_tuple(self, sys_module):
        if hasattr(sys_module, 'getwindowsversion'):
            return sys_module.getwindowsversion()
        return self._win_version_tuple_from_cmd()

    def _win_version_tuple_from_cmd(self):
        # Note that this should only ever be called on windows, so this should always work.
        ver_output = self._executive.run_command(['cmd', '/c', 'ver'], decode_output=False)
        match_object = re.search(r'(?P<major>\d)\.(?P<minor>\d)\.(?P<build>\d+)', ver_output)
        assert match_object, 'cmd returned an unexpected version string: ' + ver_output
        return tuple(map(int, match_object.groups()))
