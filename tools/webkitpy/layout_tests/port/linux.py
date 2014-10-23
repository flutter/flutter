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

import logging
import re

from webkitpy.common.webkit_finder import WebKitFinder
from webkitpy.layout_tests.breakpad.dump_reader_multipart import DumpReaderLinux
from webkitpy.layout_tests.models import test_run_results
from webkitpy.layout_tests.port import base
from webkitpy.layout_tests.port import win
from webkitpy.layout_tests.port import config


_log = logging.getLogger(__name__)


class LinuxPort(base.Port):
    port_name = 'linux'

    SUPPORTED_VERSIONS = ('x86', 'x86_64')

    FALLBACK_PATHS = { 'x86_64': [ 'linux' ] + win.WinPort.latest_platform_fallback_path() }
    FALLBACK_PATHS['x86'] = ['linux-x86'] + FALLBACK_PATHS['x86_64']

    DEFAULT_BUILD_DIRECTORIES = ('out',)

    BUILD_REQUIREMENTS_URL = 'https://code.google.com/p/chromium/wiki/LinuxBuildInstructions'

    @classmethod
    def _determine_driver_path_statically(cls, host, options):
        config_object = config.Config(host.executive, host.filesystem)
        build_directory = getattr(options, 'build_directory', None)
        finder = WebKitFinder(host.filesystem)
        webkit_base = finder.webkit_base()
        chromium_base = finder.chromium_base()
        driver_name = getattr(options, 'driver_name', None)
        if driver_name is None:
            driver_name = cls.CONTENT_SHELL_NAME
        if hasattr(options, 'configuration') and options.configuration:
            configuration = options.configuration
        else:
            configuration = config_object.default_configuration()
        return cls._static_build_path(host.filesystem, build_directory, chromium_base, configuration, [driver_name])

    @staticmethod
    def _determine_architecture(filesystem, executive, driver_path):
        file_output = ''
        if filesystem.isfile(driver_path):
            # The --dereference flag tells file to follow symlinks
            file_output = executive.run_command(['file', '--brief', '--dereference', driver_path], return_stderr=True)

        if re.match(r'ELF 32-bit LSB\s+executable', file_output):
            return 'x86'
        if re.match(r'ELF 64-bit LSB\s+executable', file_output):
            return 'x86_64'
        if file_output:
            _log.warning('Could not determine architecture from "file" output: %s' % file_output)

        # We don't know what the architecture is; default to 'x86' because
        # maybe we're rebaselining and the binary doesn't actually exist,
        # or something else weird is going on. It's okay to do this because
        # if we actually try to use the binary, check_build() should fail.
        return 'x86_64'

    @classmethod
    def determine_full_port_name(cls, host, options, port_name):
        if port_name.endswith('linux'):
            return port_name + '-' + cls._determine_architecture(host.filesystem, host.executive, cls._determine_driver_path_statically(host, options))
        return port_name

    def __init__(self, host, port_name, **kwargs):
        super(LinuxPort, self).__init__(host, port_name, **kwargs)
        (base, arch) = port_name.rsplit('-', 1)
        assert base == 'linux'
        assert arch in self.SUPPORTED_VERSIONS
        assert port_name in ('linux', 'linux-x86', 'linux-x86_64')
        self._version = 'lucid'  # We only support lucid right now.
        self._architecture = arch
        if not self.get_option('disable_breakpad'):
            self._dump_reader = DumpReaderLinux(host, self._build_path())

    def default_baseline_search_path(self):
        port_names = self.FALLBACK_PATHS[self._architecture]
        return map(self._webkit_baseline_path, port_names)

    def _modules_to_search_for_symbols(self):
        return [self._build_path('libffmpegsumo.so')]

    def check_build(self, needs_http, printer):
        result = super(LinuxPort, self).check_build(needs_http, printer)

        if result:
            _log.error('For complete Linux build requirements, please see:')
            _log.error('')
            _log.error('    http://code.google.com/p/chromium/wiki/LinuxBuildInstructions')
        return result

    def look_for_new_crash_logs(self, crashed_processes, start_time):
        if self.get_option('disable_breakpad'):
            return None
        return self._dump_reader.look_for_new_crash_logs(crashed_processes, start_time)

    def clobber_old_port_specific_results(self):
        if not self.get_option('disable_breakpad'):
            self._dump_reader.clobber_old_results()

    def operating_system(self):
        return 'linux'

    #
    # PROTECTED METHODS
    #

    def _check_apache_install(self):
        result = self._check_file_exists(self.path_to_apache(), "apache2")
        result = self._check_file_exists(self.path_to_apache_config_file(), "apache2 config file") and result
        if not result:
            _log.error('    Please install using: "sudo apt-get install apache2 libapache2-mod-php5"')
            _log.error('')
        return result

    def _wdiff_missing_message(self):
        return 'wdiff is not installed; please install using "sudo apt-get install wdiff"'

    def path_to_apache(self):
        # The Apache binary path can vary depending on OS and distribution
        # See http://wiki.apache.org/httpd/DistrosDefaultLayout
        for path in ["/usr/sbin/httpd", "/usr/sbin/apache2"]:
            if self._filesystem.exists(path):
                return path
        _log.error("Could not find apache. Not installed or unknown path.")
        return None

    def _path_to_driver(self, configuration=None):
        binary_name = self.driver_name()
        return self._build_path_with_configuration(configuration, binary_name)

    def _path_to_helper(self):
        return None
