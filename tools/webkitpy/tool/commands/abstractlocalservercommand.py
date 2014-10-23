# Copyright (C) 2011 Google Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
# 1.  Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
# 2.  Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
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

from optparse import make_option
import threading

from webkitpy.tool.multicommandtool import AbstractDeclarativeCommand


class AbstractLocalServerCommand(AbstractDeclarativeCommand):
    server = None
    launch_path = "/"

    def __init__(self):
        options = [
            make_option("--httpd-port", action="store", type="int", default=8127, help="Port to use for the HTTP server"),
            make_option("--no-show-results", action="store_false", default=True, dest="show_results", help="Don't launch a browser with the rebaseline server"),
        ]
        AbstractDeclarativeCommand.__init__(self, options=options)

    def _prepare_config(self, options, args, tool):
        return None

    def execute(self, options, args, tool):
        config = self._prepare_config(options, args, tool)

        server_url = "http://localhost:%d%s" % (options.httpd_port, self.launch_path)
        print "Starting server at %s" % server_url
        print "Use the 'Exit' link in the UI, %squitquitquit or Ctrl-C to stop" % server_url

        if options.show_results:
            # FIXME: This seems racy.
            threading.Timer(0.1, lambda: self._tool.user.open_url(server_url)).start()

        httpd = self.server(httpd_port=options.httpd_port, config=config)  # pylint: disable=E1102
        httpd.serve_forever()
