# Copyright (C) 2012 Google Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#    * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#    * Neither the name of Google Inc. nor the names of its
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

import unittest

from webkitpy.tool.servers.reflectionhandler import ReflectionHandler


class TestReflectionHandler(ReflectionHandler):
    STATIC_FILE_DIRECTORY = "/"

    def __init__(self):
        self.static_files_served = set()
        self.errors_sent = set()
        self.functions_run = set()

    def _serve_static_file(self, name):
        self.static_files_served.add(name)

    def send_error(self, code, description):
        self.errors_sent.add(code)

    def function_one(self):
        self.functions_run.add("function_one")

    def some_html(self):
        self.functions_run.add("some_html")


class WriteConvertingLogger(object):
    def __init__(self):
        self.data = ''

    def write(self, data):
        # If data is still in ASCII, this will throw an exception.
        self.data = str(data)


class TestReflectionHandlerServeXML(ReflectionHandler):
    def __init__(self):
        self.requestline = False
        self.client_address = '127.0.0.1'
        self.request_version = '1'
        self.wfile = WriteConvertingLogger()

    def serve_xml(self, data):
        self._serve_xml(data)

    def log_message(self, _format, *_args):
        pass


class ReflectionHandlerTest(unittest.TestCase):
    def assert_handler_response(self, requests, expected_static_files, expected_errors, expected_functions):
        handler = TestReflectionHandler()
        for request in requests:
            handler.path = request
            handler._handle_request()
        self.assertEqual(handler.static_files_served, expected_static_files)
        self.assertEqual(handler.errors_sent, expected_errors)
        self.assertEqual(handler.functions_run, expected_functions)

    def test_static_content_or_function_switch(self):
        self.assert_handler_response(["/test.js"], set(["test.js"]), set(), set())
        self.assert_handler_response(["/test.js", "/test.css", "/test.html"], set(["test.js", "test.html", "test.css"]), set(), set())
        self.assert_handler_response(["/test.js", "/test.exe", "/testhtml"], set(["test.js"]), set([404]), set())
        self.assert_handler_response(["/test.html", "/function.one"], set(["test.html"]), set(), set(['function_one']))
        self.assert_handler_response(["/some.html"], set(["some.html"]), set(), set())

    def test_svn_log_non_ascii(self):
        xmlChangelog = u'<?xml version="1.0"?>\n<log>\n<logentry revision="1">\n<msg>Patch from John Do\xe9.</msg>\n</logentry>\n</log>'
        handler = TestReflectionHandlerServeXML()
        handler.serve_xml(xmlChangelog)
        self.assertEqual(handler.wfile.data, xmlChangelog.encode('utf-8'))
