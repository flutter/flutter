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

import BaseHTTPServer

import cgi
import codecs
import datetime
import fnmatch
import json
import mimetypes
import os.path
import shutil
import threading
import time
import urlparse
import wsgiref.handlers
import BaseHTTPServer


class ReflectionHandler(BaseHTTPServer.BaseHTTPRequestHandler):
    STATIC_FILE_EXTENSIONS = ['.js', '.css', '.html']
    # Subclasses should override.
    STATIC_FILE_DIRECTORY = None

    # Setting this flag to True causes the server to send
    #   Access-Control-Allow-Origin: *
    # with every response.
    allow_cross_origin_requests = False

    def do_GET(self):
        self._handle_request()

    def do_POST(self):
        self._handle_request()

    def do_HEAD(self):
        self._handle_request()

    def read_entity_body(self):
        length = int(self.headers.getheader('content-length'))
        return self.rfile.read(length)

    def _read_entity_body_as_json(self):
        return json.loads(self.read_entity_body())

    def _handle_request(self):
        if "?" in self.path:
            path, query_string = self.path.split("?", 1)
            self.query = cgi.parse_qs(query_string)
        else:
            path = self.path
            self.query = {}
        function_or_file_name = path[1:] or "index.html"

        _, extension = os.path.splitext(function_or_file_name)
        if extension in self.STATIC_FILE_EXTENSIONS:
            self._serve_static_file(function_or_file_name)
            return

        function_name = function_or_file_name.replace(".", "_")
        if not hasattr(self, function_name):
            self.send_error(404, "Unknown function %s" % function_name)
            return
        if function_name[0] == "_":
            self.send_error(401, "Not allowed to invoke private or protected methods")
            return
        function = getattr(self, function_name)
        function()

    def _serve_static_file(self, static_path):
        self._serve_file(os.path.join(self.STATIC_FILE_DIRECTORY, static_path))

    def quitquitquit(self):
        self._serve_text("Server quit.\n")
        # Shutdown has to happen on another thread from the server's thread,
        # otherwise there's a deadlock
        threading.Thread(target=lambda: self.server.shutdown()).start()

    def _send_access_control_header(self):
        if self.allow_cross_origin_requests:
            self.send_header('Access-Control-Allow-Origin', '*')

    def _serve_text(self, text):
        self.send_response(200)
        self._send_access_control_header()
        self.send_header("Content-type", "text/plain")
        self.end_headers()
        self.wfile.write(text)

    def _serve_json(self, json_object):
        self.send_response(200)
        self._send_access_control_header()
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        json.dump(json_object, self.wfile)

    def _serve_file(self, file_path, cacheable_seconds=0, headers_only=False):
        if not os.path.exists(file_path):
            self.send_error(404, "File not found")
            return
        with codecs.open(file_path, "rb") as static_file:
            self.send_response(200)
            self._send_access_control_header()
            self.send_header("Content-Length", os.path.getsize(file_path))
            mime_type, encoding = mimetypes.guess_type(file_path)
            if mime_type:
                self.send_header("Content-type", mime_type)

            if cacheable_seconds:
                expires_time = (datetime.datetime.now() +
                    datetime.timedelta(0, cacheable_seconds))
                expires_formatted = wsgiref.handlers.format_date_time(
                    time.mktime(expires_time.timetuple()))
                self.send_header("Expires", expires_formatted)
            self.end_headers()

            if not headers_only:
                shutil.copyfileobj(static_file, self.wfile)

    def _serve_xml(self, xml):
        self.send_response(200)
        self._send_access_control_header()
        self.send_header("Content-type", "text/xml")
        self.end_headers()
        xml = xml.encode('utf-8')
        self.wfile.write(xml)
