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


"""Message related utilities.

Note: request.connection.write/read are used in this module, even though
mod_python document says that they should be used only in connection
handlers. Unfortunately, we have no other options. For example,
request.write/read are not suitable because they don't allow direct raw
bytes writing/reading.
"""


import Queue
import threading


# Export Exception symbols from msgutil for backward compatibility
from mod_pywebsocket._stream_base import ConnectionTerminatedException
from mod_pywebsocket._stream_base import InvalidFrameException
from mod_pywebsocket._stream_base import BadOperationException
from mod_pywebsocket._stream_base import UnsupportedFrameException


# An API for handler to send/receive WebSocket messages.
def close_connection(request):
    """Close connection.

    Args:
        request: mod_python request.
    """
    request.ws_stream.close_connection()


def send_message(request, payload_data, end=True, binary=False):
    """Send a message (or part of a message).

    Args:
        request: mod_python request.
        payload_data: unicode text or str binary to send.
        end: True to terminate a message.
             False to send payload_data as part of a message that is to be
             terminated by next or later send_message call with end=True.
        binary: send payload_data as binary frame(s).
    Raises:
        BadOperationException: when server already terminated.
    """
    request.ws_stream.send_message(payload_data, end, binary)


def receive_message(request):
    """Receive a WebSocket frame and return its payload as a text in
    unicode or a binary in str.

    Args:
        request: mod_python request.
    Raises:
        InvalidFrameException:     when client send invalid frame.
        UnsupportedFrameException: when client send unsupported frame e.g. some
                                   of reserved bit is set but no extension can
                                   recognize it.
        InvalidUTF8Exception:      when client send a text frame containing any
                                   invalid UTF-8 string.
        ConnectionTerminatedException: when the connection is closed
                                   unexpectedly.
        BadOperationException:     when client already terminated.
    """
    return request.ws_stream.receive_message()


def send_ping(request, body=''):
    request.ws_stream.send_ping(body)


class MessageReceiver(threading.Thread):
    """This class receives messages from the client.

    This class provides three ways to receive messages: blocking,
    non-blocking, and via callback. Callback has the highest precedence.

    Note: This class should not be used with the standalone server for wss
    because pyOpenSSL used by the server raises a fatal error if the socket
    is accessed from multiple threads.
    """

    def __init__(self, request, onmessage=None):
        """Construct an instance.

        Args:
            request: mod_python request.
            onmessage: a function to be called when a message is received.
                       May be None. If not None, the function is called on
                       another thread. In that case, MessageReceiver.receive
                       and MessageReceiver.receive_nowait are useless
                       because they will never return any messages.
        """

        threading.Thread.__init__(self)
        self._request = request
        self._queue = Queue.Queue()
        self._onmessage = onmessage
        self._stop_requested = False
        self.setDaemon(True)
        self.start()

    def run(self):
        try:
            while not self._stop_requested:
                message = receive_message(self._request)
                if self._onmessage:
                    self._onmessage(message)
                else:
                    self._queue.put(message)
        finally:
            close_connection(self._request)

    def receive(self):
        """ Receive a message from the channel, blocking.

        Returns:
            message as a unicode string.
        """
        return self._queue.get()

    def receive_nowait(self):
        """ Receive a message from the channel, non-blocking.

        Returns:
            message as a unicode string if available. None otherwise.
        """
        try:
            message = self._queue.get_nowait()
        except Queue.Empty:
            message = None
        return message

    def stop(self):
        """Request to stop this instance.

        The instance will be stopped after receiving the next message.
        This method may not be very useful, but there is no clean way
        in Python to forcefully stop a running thread.
        """
        self._stop_requested = True


class MessageSender(threading.Thread):
    """This class sends messages to the client.

    This class provides both synchronous and asynchronous ways to send
    messages.

    Note: This class should not be used with the standalone server for wss
    because pyOpenSSL used by the server raises a fatal error if the socket
    is accessed from multiple threads.
    """

    def __init__(self, request):
        """Construct an instance.

        Args:
            request: mod_python request.
        """
        threading.Thread.__init__(self)
        self._request = request
        self._queue = Queue.Queue()
        self.setDaemon(True)
        self.start()

    def run(self):
        while True:
            message, condition = self._queue.get()
            condition.acquire()
            send_message(self._request, message)
            condition.notify()
            condition.release()

    def send(self, message):
        """Send a message, blocking."""

        condition = threading.Condition()
        condition.acquire()
        self._queue.put((message, condition))
        condition.wait()

    def send_nowait(self, message):
        """Send a message, non-blocking."""

        self._queue.put((message, threading.Condition()))


# vi:sts=4 sw=4 et
