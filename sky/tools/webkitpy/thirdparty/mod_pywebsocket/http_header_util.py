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


"""Utilities for parsing and formatting headers that follow the grammar defined
in HTTP RFC http://www.ietf.org/rfc/rfc2616.txt.
"""


import urlparse


_SEPARATORS = '()<>@,;:\\"/[]?={} \t'


def _is_char(c):
    """Returns true iff c is in CHAR as specified in HTTP RFC."""

    return ord(c) <= 127


def _is_ctl(c):
    """Returns true iff c is in CTL as specified in HTTP RFC."""

    return ord(c) <= 31 or ord(c) == 127


class ParsingState(object):

    def __init__(self, data):
        self.data = data
        self.head = 0


def peek(state, pos=0):
    """Peeks the character at pos from the head of data."""

    if state.head + pos >= len(state.data):
        return None

    return state.data[state.head + pos]


def consume(state, amount=1):
    """Consumes specified amount of bytes from the head and returns the
    consumed bytes. If there's not enough bytes to consume, returns None.
    """

    if state.head + amount > len(state.data):
        return None

    result = state.data[state.head:state.head + amount]
    state.head = state.head + amount
    return result


def consume_string(state, expected):
    """Given a parsing state and a expected string, consumes the string from
    the head. Returns True if consumed successfully. Otherwise, returns
    False.
    """

    pos = 0

    for c in expected:
        if c != peek(state, pos):
            return False
        pos += 1

    consume(state, pos)
    return True


def consume_lws(state):
    """Consumes a LWS from the head. Returns True if any LWS is consumed.
    Otherwise, returns False.

    LWS = [CRLF] 1*( SP | HT )
    """

    original_head = state.head

    consume_string(state, '\r\n')

    pos = 0

    while True:
        c = peek(state, pos)
        if c == ' ' or c == '\t':
            pos += 1
        else:
            if pos == 0:
                state.head = original_head
                return False
            else:
                consume(state, pos)
                return True


def consume_lwses(state):
    """Consumes *LWS from the head."""

    while consume_lws(state):
        pass


def consume_token(state):
    """Consumes a token from the head. Returns the token or None if no token
    was found.
    """

    pos = 0

    while True:
        c = peek(state, pos)
        if c is None or c in _SEPARATORS or _is_ctl(c) or not _is_char(c):
            if pos == 0:
                return None

            return consume(state, pos)
        else:
            pos += 1


def consume_token_or_quoted_string(state):
    """Consumes a token or a quoted-string, and returns the token or unquoted
    string. If no token or quoted-string was found, returns None.
    """

    original_head = state.head

    if not consume_string(state, '"'):
        return consume_token(state)

    result = []

    expect_quoted_pair = False

    while True:
        if not expect_quoted_pair and consume_lws(state):
            result.append(' ')
            continue

        c = consume(state)
        if c is None:
            # quoted-string is not enclosed with double quotation
            state.head = original_head
            return None
        elif expect_quoted_pair:
            expect_quoted_pair = False
            if _is_char(c):
                result.append(c)
            else:
                # Non CHAR character found in quoted-pair
                state.head = original_head
                return None
        elif c == '\\':
            expect_quoted_pair = True
        elif c == '"':
            return ''.join(result)
        elif _is_ctl(c):
            # Invalid character %r found in qdtext
            state.head = original_head
            return None
        else:
            result.append(c)


def quote_if_necessary(s):
    """Quotes arbitrary string into quoted-string."""

    quote = False
    if s == '':
        return '""'

    result = []
    for c in s:
        if c == '"' or c in _SEPARATORS or _is_ctl(c) or not _is_char(c):
            quote = True

        if c == '"' or _is_ctl(c):
            result.append('\\' + c)
        else:
            result.append(c)

    if quote:
        return '"' + ''.join(result) + '"'
    else:
        return ''.join(result)


def parse_uri(uri):
    """Parse absolute URI then return host, port and resource."""

    parsed = urlparse.urlsplit(uri)
    if parsed.scheme != 'wss' and parsed.scheme != 'ws':
        # |uri| must be a relative URI.
        # TODO(toyoshim): Should validate |uri|.
        return None, None, uri

    if parsed.hostname is None:
        return None, None, None

    port = None
    try:
        port = parsed.port
    except ValueError, e:
        # port property cause ValueError on invalid null port description like
        # 'ws://host:/path'.
        return None, None, None

    if port is None:
        if parsed.scheme == 'ws':
            port = 80
        else:
            port = 443

    path = parsed.path
    if not path:
        path += '/'
    if parsed.query:
        path += '?' + parsed.query
    if parsed.fragment:
        path += '#' + parsed.fragment

    return parsed.hostname, port, path


try:
    urlparse.uses_netloc.index('ws')
except ValueError, e:
    # urlparse in Python2.5.1 doesn't have 'ws' and 'wss' entries.
    urlparse.uses_netloc.append('ws')
    urlparse.uses_netloc.append('wss')


# vi:sts=4 sw=4 et
