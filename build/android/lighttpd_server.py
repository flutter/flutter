#!/usr/bin/env python
#
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Provides a convenient wrapper for spawning a test lighttpd instance.

Usage:
  lighttpd_server PATH_TO_DOC_ROOT
"""

import codecs
import contextlib
import httplib
import os
import random
import shutil
import socket
import subprocess
import sys
import tempfile
import time

from pylib import constants
from pylib import pexpect

class LighttpdServer(object):
  """Wraps lighttpd server, providing robust startup.

  Args:
    document_root: Path to root of this server's hosted files.
    port: TCP port on the _host_ machine that the server will listen on. If
        ommitted it will attempt to use 9000, or if unavailable it will find
        a free port from 8001 - 8999.
    lighttpd_path, lighttpd_module_path: Optional paths to lighttpd binaries.
    base_config_path: If supplied this file will replace the built-in default
        lighttpd config file.
    extra_config_contents: If specified, this string will be appended to the
        base config (default built-in, or from base_config_path).
    config_path, error_log, access_log: Optional paths where the class should
        place temprary files for this session.
  """

  def __init__(self, document_root, port=None,
               lighttpd_path=None, lighttpd_module_path=None,
               base_config_path=None, extra_config_contents=None,
               config_path=None, error_log=None, access_log=None):
    self.temp_dir = tempfile.mkdtemp(prefix='lighttpd_for_chrome_android')
    self.document_root = os.path.abspath(document_root)
    self.fixed_port = port
    self.port = port or constants.LIGHTTPD_DEFAULT_PORT
    self.server_tag = 'LightTPD ' + str(random.randint(111111, 999999))
    self.lighttpd_path = lighttpd_path or '/usr/sbin/lighttpd'
    self.lighttpd_module_path = lighttpd_module_path or '/usr/lib/lighttpd'
    self.base_config_path = base_config_path
    self.extra_config_contents = extra_config_contents
    self.config_path = config_path or self._Mktmp('config')
    self.error_log = error_log or self._Mktmp('error_log')
    self.access_log = access_log or self._Mktmp('access_log')
    self.pid_file = self._Mktmp('pid_file')
    self.process = None

  def _Mktmp(self, name):
    return os.path.join(self.temp_dir, name)

  @staticmethod
  def _GetRandomPort():
    # The ports of test server is arranged in constants.py.
    return random.randint(constants.LIGHTTPD_RANDOM_PORT_FIRST,
                          constants.LIGHTTPD_RANDOM_PORT_LAST)

  def StartupHttpServer(self):
    """Starts up a http server with specified document root and port."""
    # If we want a specific port, make sure no one else is listening on it.
    if self.fixed_port:
      self._KillProcessListeningOnPort(self.fixed_port)
    while True:
      if self.base_config_path:
        # Read the config
        with codecs.open(self.base_config_path, 'r', 'utf-8') as f:
          config_contents = f.read()
      else:
        config_contents = self._GetDefaultBaseConfig()
      if self.extra_config_contents:
        config_contents += self.extra_config_contents
      # Write out the config, filling in placeholders from the members of |self|
      with codecs.open(self.config_path, 'w', 'utf-8') as f:
        f.write(config_contents % self.__dict__)
      if (not os.path.exists(self.lighttpd_path) or
          not os.access(self.lighttpd_path, os.X_OK)):
        raise EnvironmentError(
            'Could not find lighttpd at %s.\n'
            'It may need to be installed (e.g. sudo apt-get install lighttpd)'
            % self.lighttpd_path)
      self.process = pexpect.spawn(self.lighttpd_path,
                                   ['-D', '-f', self.config_path,
                                    '-m', self.lighttpd_module_path],
                                   cwd=self.temp_dir)
      client_error, server_error = self._TestServerConnection()
      if not client_error:
        assert int(open(self.pid_file, 'r').read()) == self.process.pid
        break
      self.process.close()

      if self.fixed_port or not 'in use' in server_error:
        print 'Client error:', client_error
        print 'Server error:', server_error
        return False
      self.port = self._GetRandomPort()
    return True

  def ShutdownHttpServer(self):
    """Shuts down our lighttpd processes."""
    if self.process:
      self.process.terminate()
    shutil.rmtree(self.temp_dir, ignore_errors=True)

  def _TestServerConnection(self):
    # Wait for server to start
    server_msg = ''
    for timeout in xrange(1, 5):
      client_error = None
      try:
        with contextlib.closing(httplib.HTTPConnection(
            '127.0.0.1', self.port, timeout=timeout)) as http:
          http.set_debuglevel(timeout > 3)
          http.request('HEAD', '/')
          r = http.getresponse()
          r.read()
          if (r.status == 200 and r.reason == 'OK' and
              r.getheader('Server') == self.server_tag):
            return (None, server_msg)
          client_error = ('Bad response: %s %s version %s\n  ' %
                          (r.status, r.reason, r.version) +
                          '\n  '.join([': '.join(h) for h in r.getheaders()]))
      except (httplib.HTTPException, socket.error) as client_error:
        pass  # Probably too quick connecting: try again
      # Check for server startup error messages
      ix = self.process.expect([pexpect.TIMEOUT, pexpect.EOF, '.+'],
                               timeout=timeout)
      if ix == 2:  # stdout spew from the server
        server_msg += self.process.match.group(0)
      elif ix == 1:  # EOF -- server has quit so giveup.
        client_error = client_error or 'Server exited'
        break
    return (client_error or 'Timeout', server_msg)

  @staticmethod
  def _KillProcessListeningOnPort(port):
    """Checks if there is a process listening on port number |port| and
    terminates it if found.

    Args:
      port: Port number to check.
    """
    if subprocess.call(['fuser', '-kv', '%d/tcp' % port]) == 0:
      # Give the process some time to terminate and check that it is gone.
      time.sleep(2)
      assert subprocess.call(['fuser', '-v', '%d/tcp' % port]) != 0, \
          'Unable to kill process listening on port %d.' % port

  @staticmethod
  def _GetDefaultBaseConfig():
    return """server.tag                  = "%(server_tag)s"
server.modules              = ( "mod_access",
                                "mod_accesslog",
                                "mod_alias",
                                "mod_cgi",
                                "mod_rewrite" )

# default document root required
#server.document-root = "."

# files to check for if .../ is requested
index-file.names            = ( "index.php", "index.pl", "index.cgi",
                                "index.html", "index.htm", "default.htm" )
# mimetype mapping
mimetype.assign             = (
  ".gif"          =>      "image/gif",
  ".jpg"          =>      "image/jpeg",
  ".jpeg"         =>      "image/jpeg",
  ".png"          =>      "image/png",
  ".svg"          =>      "image/svg+xml",
  ".css"          =>      "text/css",
  ".html"         =>      "text/html",
  ".htm"          =>      "text/html",
  ".xhtml"        =>      "application/xhtml+xml",
  ".xhtmlmp"      =>      "application/vnd.wap.xhtml+xml",
  ".js"           =>      "application/x-javascript",
  ".log"          =>      "text/plain",
  ".conf"         =>      "text/plain",
  ".text"         =>      "text/plain",
  ".txt"          =>      "text/plain",
  ".dtd"          =>      "text/xml",
  ".xml"          =>      "text/xml",
  ".manifest"     =>      "text/cache-manifest",
 )

# Use the "Content-Type" extended attribute to obtain mime type if possible
mimetype.use-xattr          = "enable"

##
# which extensions should not be handle via static-file transfer
#
# .php, .pl, .fcgi are most often handled by mod_fastcgi or mod_cgi
static-file.exclude-extensions = ( ".php", ".pl", ".cgi" )

server.bind = "127.0.0.1"
server.port = %(port)s

## virtual directory listings
dir-listing.activate        = "enable"
#dir-listing.encoding       = "iso-8859-2"
#dir-listing.external-css   = "style/oldstyle.css"

## enable debugging
#debug.log-request-header   = "enable"
#debug.log-response-header  = "enable"
#debug.log-request-handling = "enable"
#debug.log-file-not-found   = "enable"

#### SSL engine
#ssl.engine                 = "enable"
#ssl.pemfile                = "server.pem"

# Autogenerated test-specific config follows.

cgi.assign = ( ".cgi"  => "/usr/bin/env",
               ".pl"   => "/usr/bin/env",
               ".asis" => "/bin/cat",
               ".php"  => "/usr/bin/php-cgi" )

server.errorlog = "%(error_log)s"
accesslog.filename = "%(access_log)s"
server.upload-dirs = ( "/tmp" )
server.pid-file = "%(pid_file)s"
server.document-root = "%(document_root)s"

"""


def main(argv):
  server = LighttpdServer(*argv[1:])
  try:
    if server.StartupHttpServer():
      raw_input('Server running at http://127.0.0.1:%s -'
                ' press Enter to exit it.' % server.port)
    else:
      print 'Server exit code:', server.process.exitstatus
  finally:
    server.ShutdownHttpServer()


if __name__ == '__main__':
  sys.exit(main(sys.argv))
