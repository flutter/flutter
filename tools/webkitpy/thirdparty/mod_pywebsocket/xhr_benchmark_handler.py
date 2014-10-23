# Copyright 2014 Google Inc. All rights reserved.
#
# Use of this source code is governed by a BSD-style
# license that can be found in the COPYING file or at
# https://developers.google.com/open-source/licenses/bsd


from mod_pywebsocket import util


class XHRBenchmarkHandler(object):
    def __init__(self, headers, rfile, wfile):
        self._logger = util.get_class_logger(self)

        self.headers = headers
        self.rfile = rfile
        self.wfile = wfile

    def do_send(self):
        content_length = int(self.headers.getheader('Content-Length'))

        self._logger.debug('Requested to receive %s bytes', content_length)

        RECEIVE_BLOCK_SIZE = 1024 * 1024

        bytes_to_receive = content_length
        while bytes_to_receive > 0:
            bytes_to_receive_in_this_loop = bytes_to_receive
            if bytes_to_receive_in_this_loop > RECEIVE_BLOCK_SIZE:
                bytes_to_receive_in_this_loop = RECEIVE_BLOCK_SIZE
            received_data = self.rfile.read(bytes_to_receive_in_this_loop)
            for c in received_data:
                if c != 'a':
                    self._logger.debug('Request body verification failed')
                    return
            bytes_to_receive -= len(received_data)
        if bytes_to_receive < 0:
            self._logger.debug('Received %d more bytes than expected' %
                               (-bytes_to_receive))
            return

        # Return the number of received bytes back to the client.
        response_body = '%d' % content_length
        self.wfile.write(
            'HTTP/1.1 200 OK\r\n'
            'Content-Type: text/html\r\n'
            'Content-Length: %d\r\n'
            '\r\n%s' % (len(response_body), response_body))
        self.wfile.flush()

    def do_receive(self):
        content_length = int(self.headers.getheader('Content-Length'))
        request_body = self.rfile.read(content_length)

        request_array = request_body.split(' ')
        if len(request_array) < 2:
            self._logger.debug('Malformed request body: %r', request_body)
            return

        # Parse the size parameter.
        bytes_to_send = request_array[0]
        try:
            bytes_to_send = int(bytes_to_send)
        except ValueError, e:
            self._logger.debug('Malformed size parameter: %r', bytes_to_send)
            return
        self._logger.debug('Requested to send %s bytes', bytes_to_send)

        # Parse the transfer encoding parameter.
        chunked_mode = False
        mode_parameter = request_array[1]
        if mode_parameter == 'chunked':
            self._logger.debug('Requested chunked transfer encoding')
            chunked_mode = True
        elif mode_parameter != 'none':
            self._logger.debug('Invalid mode parameter: %r', mode_parameter)
            return

        # Write a header
        response_header = (
            'HTTP/1.1 200 OK\r\n'
            'Content-Type: application/octet-stream\r\n')
        if chunked_mode:
            response_header += 'Transfer-Encoding: chunked\r\n\r\n'
        else:
            response_header += (
                'Content-Length: %d\r\n\r\n' % bytes_to_send)
        self.wfile.write(response_header)
        self.wfile.flush()

        # Write a body
        SEND_BLOCK_SIZE = 1024 * 1024

        while bytes_to_send > 0:
            bytes_to_send_in_this_loop = bytes_to_send
            if bytes_to_send_in_this_loop > SEND_BLOCK_SIZE:
                bytes_to_send_in_this_loop = SEND_BLOCK_SIZE

            if chunked_mode:
                self.wfile.write('%x\r\n' % bytes_to_send_in_this_loop)
            self.wfile.write('a' * bytes_to_send_in_this_loop)
            if chunked_mode:
                self.wfile.write('\r\n')
            self.wfile.flush()

            bytes_to_send -= bytes_to_send_in_this_loop

        if chunked_mode:
            self.wfile.write('0\r\n\r\n')
            self.wfile.flush()
