# Copyright (C) 2010 Google Inc. All rights reserved.
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

"""Windows implementation of the Port interface."""

import errno
import os
import logging

try:
    import _winreg
except ImportError as e:
    _winreg = None
    WindowsError = Exception  # this shuts up pylint.

from webkitpy.layout_tests.breakpad.dump_reader_win import DumpReaderWin
from webkitpy.layout_tests.models import test_run_results
from webkitpy.layout_tests.port import base
from webkitpy.layout_tests.servers import crash_service


_log = logging.getLogger(__name__)


class WinPort(base.Port):
    port_name = 'win'

    # FIXME: Figure out how to unify this with base.TestConfiguration.all_systems()?
    SUPPORTED_VERSIONS = ('xp', 'win7')

    FALLBACK_PATHS = { 'win7': [ 'win' ]}
    FALLBACK_PATHS['xp'] = ['win-xp'] + FALLBACK_PATHS['win7']

    DEFAULT_BUILD_DIRECTORIES = ('build', 'out')

    BUILD_REQUIREMENTS_URL = 'http://www.chromium.org/developers/how-tos/build-instructions-windows'

    @classmethod
    def determine_full_port_name(cls, host, options, port_name):
        if port_name.endswith('win'):
            assert host.platform.is_win()
            # We don't maintain separate baselines for vista, so we pretend it is win7.
            if host.platform.os_version in ('vista', '7sp0', '7sp1', 'future'):
                version = 'win7'
            else:
                version = host.platform.os_version
            port_name = port_name + '-' + version
        return port_name

    def __init__(self, host, port_name, **kwargs):
        super(WinPort, self).__init__(host, port_name, **kwargs)
        self._version = port_name[port_name.index('win-') + len('win-'):]
        assert self._version in self.SUPPORTED_VERSIONS, "%s is not in %s" % (self._version, self.SUPPORTED_VERSIONS)
        if not self.get_option('disable_breakpad'):
            self._dump_reader = DumpReaderWin(host, self._build_path())
            self._crash_service = None
            self._crash_service_available = None

    def additional_drt_flag(self):
        flags = super(WinPort, self).additional_drt_flag()
        flags += ['--enable-direct-write']
        if not self.get_option('disable_breakpad'):
            flags += ['--enable-crash-reporter', '--crash-dumps-dir=%s' % self._dump_reader.crash_dumps_directory()]
        return flags

    def check_httpd(self):
        res = super(WinPort, self).check_httpd()
        if self.uses_apache():
            # In order to run CGI scripts on Win32 that use unix shebang lines, we need to
            # create entries in the registry that remap the extensions (.pl and .cgi) to the
            # appropriate Win32 paths. The command line arguments must match the command
            # line arguments in the shebang line exactly.
            if _winreg:
                res = self._check_reg(r'.cgi\Shell\ExecCGI\Command') and res
                res = self._check_reg(r'.pl\Shell\ExecCGI\Command') and res
            else:
                _log.warning("Could not check the registry; http may not work correctly.")

        return res

    def _check_reg(self, sub_key):
        # see comments in check_httpd(), above, for why this routine exists and what it's doing.
        try:
            # Note that we HKCR is a union of HKLM and HKCR (with the latter
            # overridding the former), so reading from HKCR ensures that we get
            # the value if it is set in either place. See als comments below.
            hkey = _winreg.OpenKey(_winreg.HKEY_CLASSES_ROOT, sub_key)
            args = _winreg.QueryValue(hkey, '').split()
            _winreg.CloseKey(hkey)

            # In order to keep multiple checkouts from stepping on each other, we simply check that an
            # existing entry points to a valid path and has the right command line.
            if len(args) == 2 and self._filesystem.exists(args[0]) and args[0].endswith('perl.exe') and args[1] == '-wT':
                return True
        except WindowsError, e:
            if e.errno != errno.ENOENT:
                raise e
            # The key simply probably doesn't exist.
            pass

        # Note that we write to HKCU so that we don't need privileged access
        # to the registry, and that will get reflected in HKCR when it is read, above.
        cmdline = self.path_from_chromium_base('third_party', 'perl', 'perl', 'bin', 'perl.exe') + ' -wT'
        hkey = _winreg.CreateKeyEx(_winreg.HKEY_CURRENT_USER, 'Software\\Classes\\' + sub_key, 0, _winreg.KEY_WRITE)
        _winreg.SetValue(hkey, '', _winreg.REG_SZ, cmdline)
        _winreg.CloseKey(hkey)
        return True

    def setup_test_run(self):
        super(WinPort, self).setup_test_run()

        if not self.get_option('disable_breakpad'):
            assert not self._crash_service, 'Already running a crash service'
            if self._crash_service_available == None:
                self._crash_service_available = self._check_crash_service_available()
            if not self._crash_service_available:
                return
            service = crash_service.CrashService(self, self._dump_reader.crash_dumps_directory())
            service.start()
            self._crash_service = service

    def clean_up_test_run(self):
        super(WinPort, self).clean_up_test_run()

        if self._crash_service:
            self._crash_service.stop()
            self._crash_service = None

    def setup_environ_for_server(self, server_name=None):
        env = super(WinPort, self).setup_environ_for_server(server_name)

        # FIXME: This is a temporary hack to get the cr-win bot online until
        # someone from the cr-win port can take a look.
        apache_envvars = ['SYSTEMDRIVE', 'SYSTEMROOT', 'TEMP', 'TMP']
        for key, value in os.environ.items():
            if key not in env and key in apache_envvars:
                env[key] = value

        # Put the cygwin directory first in the path to find cygwin1.dll.
        env["PATH"] = "%s;%s" % (self.path_from_chromium_base("third_party", "cygwin", "bin"), env["PATH"])
        # Configure the cygwin directory so that pywebsocket finds proper
        # python executable to run cgi program.
        env["CYGWIN_PATH"] = self.path_from_chromium_base("third_party", "cygwin", "bin")
        if self.get_option('register_cygwin'):
            setup_mount = self.path_from_chromium_base("third_party", "cygwin", "setup_mount.bat")
            self._executive.run_command([setup_mount])  # Paths are all absolute, so this does not require a cwd.
        return env

    def _modules_to_search_for_symbols(self):
        # FIXME: we should return the path to the ffmpeg equivalents to detect if we have the mp3 and aac codecs installed.
        # See https://bugs.webkit.org/show_bug.cgi?id=89706.
        return []

    def check_build(self, needs_http, printer):
        result = super(WinPort, self).check_build(needs_http, printer)

        self._crash_service_available = self._check_crash_service_available()
        if not self._crash_service_available:
            result = test_run_results.UNEXPECTED_ERROR_EXIT_STATUS

        if result:
            _log.error('For complete Windows build requirements, please see:')
            _log.error('')
            _log.error('    http://dev.chromium.org/developers/how-tos/build-instructions-windows')
        return result

    def operating_system(self):
        return 'win'

    def relative_test_filename(self, filename):
        path = filename[len(self.layout_tests_dir()) + 1:]
        return path.replace('\\', '/')

    def uses_apache(self):
        val = self.get_option('use_apache')
        if val is None:
            return True
        return val

    def path_to_apache(self):
        return self.path_from_chromium_base('third_party', 'apache-win32', 'bin', 'httpd.exe')

    def path_to_apache_config_file(self):
        return self._filesystem.join(self.layout_tests_dir(), 'http', 'conf', 'win-httpd.conf')

    #
    # PROTECTED ROUTINES
    #

    def _path_to_driver(self, configuration=None):
        binary_name = '%s.exe' % self.driver_name()
        return self._build_path_with_configuration(configuration, binary_name)

    def _path_to_crash_service(self):
        binary_name = 'content_shell_crash_service.exe'
        return self._build_path(binary_name)

    def _path_to_image_diff(self):
        binary_name = 'image_diff.exe'
        return self._build_path(binary_name)

    def _path_to_wdiff(self):
        return self.path_from_chromium_base('third_party', 'cygwin', 'bin', 'wdiff.exe')

    def _check_crash_service_available(self):
        """Checks whether the crash service binary is present."""
        result = self._check_file_exists(self._path_to_crash_service(), "content_shell_crash_service.exe")
        if not result:
            _log.error("    Could not find crash service, unexpected crashes won't be symbolized.")
            _log.error('    Did you build the target blink_tests?')
            _log.error('')
        return result

    def look_for_new_crash_logs(self, crashed_processes, start_time):
        if self.get_option('disable_breakpad'):
            return None
        return self._dump_reader.look_for_new_crash_logs(crashed_processes, start_time)

    def clobber_old_port_specific_results(self):
        if not self.get_option('disable_breakpad'):
            self._dump_reader.clobber_old_results()
