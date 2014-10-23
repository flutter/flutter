# Copyright 2011, Google Inc.
# All rights reserved.
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


"""WebSocket extension for Apache HTTP Server.

mod_pywebsocket is a WebSocket extension for Apache HTTP Server
intended for testing or experimental purposes. mod_python is required.


Installation
============

0. Prepare an Apache HTTP Server for which mod_python is enabled.

1. Specify the following Apache HTTP Server directives to suit your
   configuration.

   If mod_pywebsocket is not in the Python path, specify the following.
   <websock_lib> is the directory where mod_pywebsocket is installed.

       PythonPath "sys.path+['<websock_lib>']"

   Always specify the following. <websock_handlers> is the directory where
   user-written WebSocket handlers are placed.

       PythonOption mod_pywebsocket.handler_root <websock_handlers>
       PythonHeaderParserHandler mod_pywebsocket.headerparserhandler

   To limit the search for WebSocket handlers to a directory <scan_dir>
   under <websock_handlers>, configure as follows:

       PythonOption mod_pywebsocket.handler_scan <scan_dir>

   <scan_dir> is useful in saving scan time when <websock_handlers>
   contains many non-WebSocket handler files.

   If you want to allow handlers whose canonical path is not under the root
   directory (i.e. symbolic link is in root directory but its target is not),
   configure as follows:

       PythonOption mod_pywebsocket.allow_handlers_outside_root_dir On

   Example snippet of httpd.conf:
   (mod_pywebsocket is in /websock_lib, WebSocket handlers are in
   /websock_handlers, port is 80 for ws, 443 for wss.)

       <IfModule python_module>
         PythonPath "sys.path+['/websock_lib']"
         PythonOption mod_pywebsocket.handler_root /websock_handlers
         PythonHeaderParserHandler mod_pywebsocket.headerparserhandler
       </IfModule>

2. Tune Apache parameters for serving WebSocket. We'd like to note that at
   least TimeOut directive from core features and RequestReadTimeout
   directive from mod_reqtimeout should be modified not to kill connections
   in only a few seconds of idle time.

3. Verify installation. You can use example/console.html to poke the server.


Writing WebSocket handlers
==========================

When a WebSocket request comes in, the resource name
specified in the handshake is considered as if it is a file path under
<websock_handlers> and the handler defined in
<websock_handlers>/<resource_name>_wsh.py is invoked.

For example, if the resource name is /example/chat, the handler defined in
<websock_handlers>/example/chat_wsh.py is invoked.

A WebSocket handler is composed of the following three functions:

    web_socket_do_extra_handshake(request)
    web_socket_transfer_data(request)
    web_socket_passive_closing_handshake(request)

where:
    request: mod_python request.

web_socket_do_extra_handshake is called during the handshake after the
headers are successfully parsed and WebSocket properties (ws_location,
ws_origin, and ws_resource) are added to request. A handler
can reject the request by raising an exception.

A request object has the following properties that you can use during the
extra handshake (web_socket_do_extra_handshake):
- ws_resource
- ws_origin
- ws_version
- ws_location (HyBi 00 only)
- ws_extensions (HyBi 06 and later)
- ws_deflate (HyBi 06 and later)
- ws_protocol
- ws_requested_protocols (HyBi 06 and later)

The last two are a bit tricky. See the next subsection.


Subprotocol Negotiation
-----------------------

For HyBi 06 and later, ws_protocol is always set to None when
web_socket_do_extra_handshake is called. If ws_requested_protocols is not
None, you must choose one subprotocol from this list and set it to
ws_protocol.

For HyBi 00, when web_socket_do_extra_handshake is called,
ws_protocol is set to the value given by the client in
Sec-WebSocket-Protocol header or None if
such header was not found in the opening handshake request. Finish extra
handshake with ws_protocol untouched to accept the request subprotocol.
Then, Sec-WebSocket-Protocol header will be sent to
the client in response with the same value as requested. Raise an exception
in web_socket_do_extra_handshake to reject the requested subprotocol.


Data Transfer
-------------

web_socket_transfer_data is called after the handshake completed
successfully. A handler can receive/send messages from/to the client
using request. mod_pywebsocket.msgutil module provides utilities
for data transfer.

You can receive a message by the following statement.

    message = request.ws_stream.receive_message()

This call blocks until any complete text frame arrives, and the payload data
of the incoming frame will be stored into message. When you're using IETF
HyBi 00 or later protocol, receive_message() will return None on receiving
client-initiated closing handshake. When any error occurs, receive_message()
will raise some exception.

You can send a message by the following statement.

    request.ws_stream.send_message(message)


Closing Connection
------------------

Executing the following statement or just return-ing from
web_socket_transfer_data cause connection close.

    request.ws_stream.close_connection()

close_connection will wait
for closing handshake acknowledgement coming from the client. When it
couldn't receive a valid acknowledgement, raises an exception.

web_socket_passive_closing_handshake is called after the server receives
incoming closing frame from the client peer immediately. You can specify
code and reason by return values. They are sent as a outgoing closing frame
from the server. A request object has the following properties that you can
use in web_socket_passive_closing_handshake.
- ws_close_code
- ws_close_reason


Threading
---------

A WebSocket handler must be thread-safe if the server (Apache or
standalone.py) is configured to use threads.


Configuring WebSocket Extension Processors
------------------------------------------

See extensions.py for supported WebSocket extensions. Note that they are
unstable and their APIs are subject to change substantially.

A request object has these extension processing related attributes.

- ws_requested_extensions:

  A list of common.ExtensionParameter instances representing extension
  parameters received from the client in the client's opening handshake.
  You shouldn't modify it manually.

- ws_extensions:

  A list of common.ExtensionParameter instances representing extension
  parameters to send back to the client in the server's opening handshake.
  You shouldn't touch it directly. Instead, call methods on extension
  processors.

- ws_extension_processors:

  A list of loaded extension processors. Find the processor for the
  extension you want to configure from it, and call its methods.
"""


# vi:sts=4 sw=4 et tw=72
