# Copyright 2012, Google Inc.
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


"""Dispatch WebSocket request.
"""


import logging
import os
import re

from mod_pywebsocket import common
from mod_pywebsocket import handshake
from mod_pywebsocket import msgutil
from mod_pywebsocket import mux
from mod_pywebsocket import stream
from mod_pywebsocket import util


_SOURCE_PATH_PATTERN = re.compile(r'(?i)_wsh\.py$')
_SOURCE_SUFFIX = '_wsh.py'
_DO_EXTRA_HANDSHAKE_HANDLER_NAME = 'web_socket_do_extra_handshake'
_TRANSFER_DATA_HANDLER_NAME = 'web_socket_transfer_data'
_PASSIVE_CLOSING_HANDSHAKE_HANDLER_NAME = (
    'web_socket_passive_closing_handshake')


class DispatchException(Exception):
    """Exception in dispatching WebSocket request."""

    def __init__(self, name, status=common.HTTP_STATUS_NOT_FOUND):
        super(DispatchException, self).__init__(name)
        self.status = status


def _default_passive_closing_handshake_handler(request):
    """Default web_socket_passive_closing_handshake handler."""

    return common.STATUS_NORMAL_CLOSURE, ''


def _normalize_path(path):
    """Normalize path.

    Args:
        path: the path to normalize.

    Path is converted to the absolute path.
    The input path can use either '\\' or '/' as the separator.
    The normalized path always uses '/' regardless of the platform.
    """

    path = path.replace('\\', os.path.sep)
    path = os.path.realpath(path)
    path = path.replace('\\', '/')
    return path


def _create_path_to_resource_converter(base_dir):
    """Returns a function that converts the path of a WebSocket handler source
    file to a resource string by removing the path to the base directory from
    its head, removing _SOURCE_SUFFIX from its tail, and replacing path
    separators in it with '/'.

    Args:
        base_dir: the path to the base directory.
    """

    base_dir = _normalize_path(base_dir)

    base_len = len(base_dir)
    suffix_len = len(_SOURCE_SUFFIX)

    def converter(path):
        if not path.endswith(_SOURCE_SUFFIX):
            return None
        # _normalize_path must not be used because resolving symlink breaks
        # following path check.
        path = path.replace('\\', '/')
        if not path.startswith(base_dir):
            return None
        return path[base_len:-suffix_len]

    return converter


def _enumerate_handler_file_paths(directory):
    """Returns a generator that enumerates WebSocket Handler source file names
    in the given directory.
    """

    for root, unused_dirs, files in os.walk(directory):
        for base in files:
            path = os.path.join(root, base)
            if _SOURCE_PATH_PATTERN.search(path):
                yield path


class _HandlerSuite(object):
    """A handler suite holder class."""

    def __init__(self, do_extra_handshake, transfer_data,
                 passive_closing_handshake):
        self.do_extra_handshake = do_extra_handshake
        self.transfer_data = transfer_data
        self.passive_closing_handshake = passive_closing_handshake


def _source_handler_file(handler_definition):
    """Source a handler definition string.

    Args:
        handler_definition: a string containing Python statements that define
                            handler functions.
    """

    global_dic = {}
    try:
        exec handler_definition in global_dic
    except Exception:
        raise DispatchException('Error in sourcing handler:' +
                                util.get_stack_trace())
    passive_closing_handshake_handler = None
    try:
        passive_closing_handshake_handler = _extract_handler(
            global_dic, _PASSIVE_CLOSING_HANDSHAKE_HANDLER_NAME)
    except Exception:
        passive_closing_handshake_handler = (
            _default_passive_closing_handshake_handler)
    return _HandlerSuite(
        _extract_handler(global_dic, _DO_EXTRA_HANDSHAKE_HANDLER_NAME),
        _extract_handler(global_dic, _TRANSFER_DATA_HANDLER_NAME),
        passive_closing_handshake_handler)


def _extract_handler(dic, name):
    """Extracts a callable with the specified name from the given dictionary
    dic.
    """

    if name not in dic:
        raise DispatchException('%s is not defined.' % name)
    handler = dic[name]
    if not callable(handler):
        raise DispatchException('%s is not callable.' % name)
    return handler


class Dispatcher(object):
    """Dispatches WebSocket requests.

    This class maintains a map from resource name to handlers.
    """

    def __init__(
        self, root_dir, scan_dir=None,
        allow_handlers_outside_root_dir=True):
        """Construct an instance.

        Args:
            root_dir: The directory where handler definition files are
                      placed.
            scan_dir: The directory where handler definition files are
                      searched. scan_dir must be a directory under root_dir,
                      including root_dir itself.  If scan_dir is None,
                      root_dir is used as scan_dir. scan_dir can be useful
                      in saving scan time when root_dir contains many
                      subdirectories.
            allow_handlers_outside_root_dir: Scans handler files even if their
                      canonical path is not under root_dir.
        """

        self._logger = util.get_class_logger(self)

        self._handler_suite_map = {}
        self._source_warnings = []
        if scan_dir is None:
            scan_dir = root_dir
        if not os.path.realpath(scan_dir).startswith(
                os.path.realpath(root_dir)):
            raise DispatchException('scan_dir:%s must be a directory under '
                                    'root_dir:%s.' % (scan_dir, root_dir))
        self._source_handler_files_in_dir(
            root_dir, scan_dir, allow_handlers_outside_root_dir)

    def add_resource_path_alias(self,
                                alias_resource_path, existing_resource_path):
        """Add resource path alias.

        Once added, request to alias_resource_path would be handled by
        handler registered for existing_resource_path.

        Args:
            alias_resource_path: alias resource path
            existing_resource_path: existing resource path
        """
        try:
            handler_suite = self._handler_suite_map[existing_resource_path]
            self._handler_suite_map[alias_resource_path] = handler_suite
        except KeyError:
            raise DispatchException('No handler for: %r' %
                                    existing_resource_path)

    def source_warnings(self):
        """Return warnings in sourcing handlers."""

        return self._source_warnings

    def do_extra_handshake(self, request):
        """Do extra checking in WebSocket handshake.

        Select a handler based on request.uri and call its
        web_socket_do_extra_handshake function.

        Args:
            request: mod_python request.

        Raises:
            DispatchException: when handler was not found
            AbortedByUserException: when user handler abort connection
            HandshakeException: when opening handshake failed
        """

        handler_suite = self.get_handler_suite(request.ws_resource)
        if handler_suite is None:
            raise DispatchException('No handler for: %r' % request.ws_resource)
        do_extra_handshake_ = handler_suite.do_extra_handshake
        try:
            do_extra_handshake_(request)
        except handshake.AbortedByUserException, e:
            # Re-raise to tell the caller of this function to finish this
            # connection without sending any error.
            self._logger.debug('%s', util.get_stack_trace())
            raise
        except Exception, e:
            util.prepend_message_to_exception(
                    '%s raised exception for %s: ' % (
                            _DO_EXTRA_HANDSHAKE_HANDLER_NAME,
                            request.ws_resource),
                    e)
            raise handshake.HandshakeException(e, common.HTTP_STATUS_FORBIDDEN)

    def transfer_data(self, request):
        """Let a handler transfer_data with a WebSocket client.

        Select a handler based on request.ws_resource and call its
        web_socket_transfer_data function.

        Args:
            request: mod_python request.

        Raises:
            DispatchException: when handler was not found
            AbortedByUserException: when user handler abort connection
        """

        # TODO(tyoshino): Terminate underlying TCP connection if possible.
        try:
            if mux.use_mux(request):
                mux.start(request, self)
            else:
                handler_suite = self.get_handler_suite(request.ws_resource)
                if handler_suite is None:
                    raise DispatchException('No handler for: %r' %
                                            request.ws_resource)
                transfer_data_ = handler_suite.transfer_data
                transfer_data_(request)

            if not request.server_terminated:
                request.ws_stream.close_connection()
        # Catch non-critical exceptions the handler didn't handle.
        except handshake.AbortedByUserException, e:
            self._logger.debug('%s', util.get_stack_trace())
            raise
        except msgutil.BadOperationException, e:
            self._logger.debug('%s', e)
            request.ws_stream.close_connection(
                common.STATUS_INTERNAL_ENDPOINT_ERROR)
        except msgutil.InvalidFrameException, e:
            # InvalidFrameException must be caught before
            # ConnectionTerminatedException that catches InvalidFrameException.
            self._logger.debug('%s', e)
            request.ws_stream.close_connection(common.STATUS_PROTOCOL_ERROR)
        except msgutil.UnsupportedFrameException, e:
            self._logger.debug('%s', e)
            request.ws_stream.close_connection(common.STATUS_UNSUPPORTED_DATA)
        except stream.InvalidUTF8Exception, e:
            self._logger.debug('%s', e)
            request.ws_stream.close_connection(
                common.STATUS_INVALID_FRAME_PAYLOAD_DATA)
        except msgutil.ConnectionTerminatedException, e:
            self._logger.debug('%s', e)
        except Exception, e:
            # Any other exceptions are forwarded to the caller of this
            # function.
            util.prepend_message_to_exception(
                '%s raised exception for %s: ' % (
                    _TRANSFER_DATA_HANDLER_NAME, request.ws_resource),
                e)
            raise

    def passive_closing_handshake(self, request):
        """Prepare code and reason for responding client initiated closing
        handshake.
        """

        handler_suite = self.get_handler_suite(request.ws_resource)
        if handler_suite is None:
            return _default_passive_closing_handshake_handler(request)
        return handler_suite.passive_closing_handshake(request)

    def get_handler_suite(self, resource):
        """Retrieves two handlers (one for extra handshake processing, and one
        for data transfer) for the given request as a HandlerSuite object.
        """

        fragment = None
        if '#' in resource:
            resource, fragment = resource.split('#', 1)
        if '?' in resource:
            resource = resource.split('?', 1)[0]
        handler_suite = self._handler_suite_map.get(resource)
        if handler_suite and fragment:
            raise DispatchException('Fragment identifiers MUST NOT be used on '
                                    'WebSocket URIs',
                                    common.HTTP_STATUS_BAD_REQUEST)
        return handler_suite

    def _source_handler_files_in_dir(
        self, root_dir, scan_dir, allow_handlers_outside_root_dir):
        """Source all the handler source files in the scan_dir directory.

        The resource path is determined relative to root_dir.
        """

        # We build a map from resource to handler code assuming that there's
        # only one path from root_dir to scan_dir and it can be obtained by
        # comparing realpath of them.

        # Here we cannot use abspath. See
        # https://bugs.webkit.org/show_bug.cgi?id=31603

        convert = _create_path_to_resource_converter(root_dir)
        scan_realpath = os.path.realpath(scan_dir)
        root_realpath = os.path.realpath(root_dir)
        for path in _enumerate_handler_file_paths(scan_realpath):
            if (not allow_handlers_outside_root_dir and
                (not os.path.realpath(path).startswith(root_realpath))):
                self._logger.debug(
                    'Canonical path of %s is not under root directory' %
                    path)
                continue
            try:
                handler_suite = _source_handler_file(open(path).read())
            except DispatchException, e:
                self._source_warnings.append('%s: %s' % (path, e))
                continue
            resource = convert(path)
            if resource is None:
                self._logger.debug(
                    'Path to resource conversion on %s failed' % path)
            else:
                self._handler_suite_map[convert(path)] = handler_suite


# vi:sts=4 sw=4 et
