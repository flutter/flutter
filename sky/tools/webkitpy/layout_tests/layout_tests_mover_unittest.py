# Copyright (C) 2013 Google Inc. All rights reserved.
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
import unittest

from webkitpy.common.host_mock import MockHost
from webkitpy.common.checkout.scm.scm_mock import MockSCM
from webkitpy.common.system.filesystem_mock import MockFileSystem
from webkitpy.layout_tests.layout_tests_mover import testsMover
from webkitpy.layout_tests.port import base


class MockPort(base.Port):

    def __init__(self, **kwargs):
        # This sets up a mock FileSystem and SCM using that FileSystem.
        host = MockHost()
        super(MockPort, self).__init__(host, host.port_factory.all_port_names()[0], **kwargs)

        host.filesystem.maybe_make_directory(self._absolute_path('platform'))
        host.filesystem.maybe_make_directory(self._absolute_path('existing_directory'))
        host.filesystem.write_text_file(self._absolute_path('existing_file.txt'), '')
        host.filesystem.write_text_file(self._absolute_path('TestExpectations'), """
crbug.com/42 [ Debug ] origin/path/test.html [ Pass Timeout Failure ]
crbug.com/42 [ Win ] origin/path [ Slow ]
crbug.com/42 [ Release ] origin [ Crash ]
""")
        host.filesystem.write_text_file(self._absolute_path('existing_directory_with_contents', 'test.html'), '')
        host.filesystem.write_text_file(self._absolute_path('origin', 'path', 'test.html'), """
<script src="local_script.js">
<script src="../../unmoved/remote_script.js">
<script src='../../unmoved/remote_script_single_quotes.js'>
<script href="../../unmoved/remote_script.js">
<script href='../../unmoved/remote_script_single_quotes.js'>
<script href="">
""")
        host.filesystem.write_text_file(self._absolute_path('origin', 'path', 'test.css'), """
url('../../unmoved/url_function.js')
url("../../unmoved/url_function_double_quotes.js")
url(../../unmoved/url_function_no_quotes.js)
url('')
url()
""")
        host.filesystem.write_text_file(self._absolute_path('origin', 'path', 'test.js'), """
importScripts('../../unmoved/import_scripts_function.js')
importScripts("../../unmoved/import_scripts_function_double_quotes.js")
importScripts('')
""")
        host.filesystem.write_text_file(self._absolute_path('unmoved', 'test.html'), """
<script src="local_script.js">
<script src="../origin/path/remote_script.js">
""")

    def _absolute_path(self, *paths):
        return self.host.scm().absolute_path('tests', *paths)

    def layout_tests_dir(self):
        return self._absolute_path()


class testsMoverTest(unittest.TestCase):

    def setUp(self):
        port = MockPort()
        self._port = port
        self._filesystem = self._port.host.filesystem
        self._mover = testsMover(port=self._port)

    def test_non_existent_origin_raises(self):
        self.assertRaises(Exception, self._mover.move, 'non_existent', 'destination')

    def test_origin_outside_layout_tests_directory_raises(self):
        self.assertRaises(Exception, self._mover.move, '../outside', 'destination')

    def test_file_destination_raises(self):
        self.assertRaises(Exception, self._mover.move, 'origin/path', 'existing_file.txt')

    def test_destination_outside_layout_tests_directory_raises(self):
        self.assertRaises(Exception, self._mover.move, 'origin/path', '../outside')

    def test_basic_operation(self):
        self._mover.move('origin/path', 'destination')
        self.assertFalse(self._filesystem.exists(self._port._absolute_path('origin/path')))
        self.assertTrue(self._filesystem.isfile(self._port._absolute_path('destination/test.html')))

    def test_move_to_existing_directory(self):
        self._mover.move('origin/path', 'existing_directory')
        self.assertFalse(self._filesystem.exists(self._port._absolute_path('origin', 'path')))
        self.assertTrue(self._filesystem.isfile(self._port._absolute_path('existing_directory', 'test.html')))

    def test_collision_in_existing_directory_raises(self):
        self.assertRaises(Exception, self._mover.move, 'origin/path', 'existing_directory_with_contents')

    def test_move_to_layout_tests_root(self):
        self._mover.move('origin/path', '')
        self.assertFalse(self._filesystem.exists(self._port._absolute_path('origin', 'path')))
        self.assertTrue(self._filesystem.isfile(self._port._absolute_path('test.html')))

    def test_moved_reference_in_moved_file_not_updated(self):
        self._mover.move('origin/path', 'destination')
        self.assertTrue('src="local_script.js"' in self._filesystem.read_text_file(self._port._absolute_path('destination', 'test.html')))

    def test_unmoved_reference_in_unmoved_file_not_updated(self):
        self._mover.move('origin/path', 'destination')
        self.assertTrue('src="local_script.js"' in self._filesystem.read_text_file(self._port._absolute_path('unmoved', 'test.html')))

    def test_moved_reference_in_unmoved_file_is_updated(self):
        self._mover.move('origin/path', 'destination')
        self.assertTrue('src="../destination/remote_script.js"' in self._filesystem.read_text_file(self._port._absolute_path('unmoved', 'test.html')))

    def test_unmoved_reference_in_moved_file_is_updated(self):
        self._mover.move('origin/path', 'destination')
        self.assertTrue('src="../unmoved/remote_script.js"' in self._filesystem.read_text_file(self._port._absolute_path('destination', 'test.html')))

    def test_references_in_html_file_are_updated(self):
        self._mover.move('origin/path', 'destination')
        self.assertTrue('src="../unmoved/remote_script.js"' in self._filesystem.read_text_file(self._port._absolute_path('destination', 'test.html')))
        self.assertTrue('src=\'../unmoved/remote_script_single_quotes.js\'' in self._filesystem.read_text_file(self._port._absolute_path('destination', 'test.html')))
        self.assertTrue('href="../unmoved/remote_script.js"' in self._filesystem.read_text_file(self._port._absolute_path('destination', 'test.html')))
        self.assertTrue('href=\'../unmoved/remote_script_single_quotes.js\'' in self._filesystem.read_text_file(self._port._absolute_path('destination', 'test.html')))
        self.assertTrue('href=""' in self._filesystem.read_text_file(self._port._absolute_path('destination', 'test.html')))

    def test_references_in_css_file_are_updated(self):
        self._mover.move('origin/path', 'destination')
        self.assertTrue('url(\'../unmoved/url_function.js\')' in self._filesystem.read_text_file(self._port._absolute_path('destination', 'test.css')))
        self.assertTrue('url("../unmoved/url_function_double_quotes.js")' in self._filesystem.read_text_file(self._port._absolute_path('destination', 'test.css')))
        self.assertTrue('url(../unmoved/url_function_no_quotes.js)' in self._filesystem.read_text_file(self._port._absolute_path('destination', 'test.css')))
        self.assertTrue('url(\'\')' in self._filesystem.read_text_file(self._port._absolute_path('destination', 'test.css')))
        self.assertTrue('url()' in self._filesystem.read_text_file(self._port._absolute_path('destination', 'test.css')))

    def test_references_in_javascript_file_are_updated(self):
        self._mover.move('origin/path', 'destination')
        self.assertTrue('importScripts(\'../unmoved/import_scripts_function.js\')' in self._filesystem.read_text_file(self._port._absolute_path('destination', 'test.js')))
        self.assertTrue('importScripts("../unmoved/import_scripts_function_double_quotes.js")' in self._filesystem.read_text_file(self._port._absolute_path('destination', 'test.js')))
        self.assertTrue('importScripts(\'\')' in self._filesystem.read_text_file(self._port._absolute_path('destination', 'test.js')))

    def test_expectation_is_updated(self):
        self._mover.move('origin/path', 'destination')
        self.assertFalse('origin/path/test.html' in self._filesystem.read_text_file(self._port._absolute_path('TestExpectations')))
        self.assertTrue('crbug.com/42 [ Debug ] destination/test.html [ Pass Timeout Failure ]'
                        in self._filesystem.read_text_file(self._port._absolute_path('TestExpectations')))

    def test_directory_expectation_is_updated(self):
        self._mover.move('origin/path', 'destination')
        self.assertFalse('origin/path' in self._filesystem.read_text_file(self._port._absolute_path('TestExpectations')))
        self.assertTrue('crbug.com/42 [ Win ] destination [ Slow ]' in self._filesystem.read_text_file(self._port._absolute_path('TestExpectations')))

    def test_expectation_is_added_when_subdirectory_moved(self):
        self._mover.move('origin/path', 'destination')
        self.assertTrue('crbug.com/42 [ Release ] origin [ Crash ]' in self._filesystem.read_text_file(self._port._absolute_path('TestExpectations')))
        self.assertTrue('crbug.com/42 [ Release ] destination [ Crash ]' in self._filesystem.read_text_file(self._port._absolute_path('TestExpectations')))
