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


"""WebSocket opening handshake processor. This class try to apply available
opening handshake processors for each protocol version until a connection is
successfully established.
"""


import logging

from mod_pywebsocket import common
from mod_pywebsocket.handshake import hybi00
from mod_pywebsocket.handshake import hybi
# Export AbortedByUserException, HandshakeException, and VersionException
# symbol from this module.
from mod_pywebsocket.handshake._base import AbortedByUserException
from mod_pywebsocket.handshake._base import HandshakeException
from mod_pywebsocket.handshake._base import VersionException


_LOGGER = logging.getLogger(__name__)


def do_handshake(request, dispatcher, allowDraft75=False, strict=False):
    """Performs WebSocket handshake.

    Args:
        request: mod_python request.
        dispatcher: Dispatcher (dispatch.Dispatcher).
        allowDraft75: obsolete argument. ignored.
        strict: obsolete argument. ignored.

    Handshaker will add attributes such as ws_resource in performing
    handshake.
    """

    _LOGGER.debug('Client\'s opening handshake resource: %r', request.uri)
    # To print mimetools.Message as escaped one-line string, we converts
    # headers_in to dict object. Without conversion, if we use %r, it just
    # prints the type and address, and if we use %s, it prints the original
    # header string as multiple lines.
    #
    # Both mimetools.Message and MpTable_Type of mod_python can be
    # converted to dict.
    #
    # mimetools.Message.__str__ returns the original header string.
    # dict(mimetools.Message object) returns the map from header names to
    # header values. While MpTable_Type doesn't have such __str__ but just
    # __repr__ which formats itself as well as dictionary object.
    _LOGGER.debug(
        'Client\'s opening handshake headers: %r', dict(request.headers_in))

    handshakers = []
    handshakers.append(
        ('RFC 6455', hybi.Handshaker(request, dispatcher)))
    handshakers.append(
        ('HyBi 00', hybi00.Handshaker(request, dispatcher)))

    for name, handshaker in handshakers:
        _LOGGER.debug('Trying protocol version %s', name)
        try:
            handshaker.do_handshake()
            _LOGGER.info('Established (%s protocol)', name)
            return
        except HandshakeException, e:
            _LOGGER.debug(
                'Failed to complete opening handshake as %s protocol: %r',
                name, e)
            if e.status:
                raise e
        except AbortedByUserException, e:
            raise
        except VersionException, e:
            raise

    # TODO(toyoshim): Add a test to cover the case all handshakers fail.
    raise HandshakeException(
        'Failed to complete opening handshake for all available protocols',
        status=common.HTTP_STATUS_BAD_REQUEST)


# vi:sts=4 sw=4 et
