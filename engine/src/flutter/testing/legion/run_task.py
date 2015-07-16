#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""The main task entrypoint."""

import argparse
import logging
import socket
import sys
import time

#pylint: disable=relative-import
import common_lib
import rpc_server


def main():
  print ' '.join(sys.argv)
  common_lib.InitLogging()
  logging.info('Task starting')

  parser = argparse.ArgumentParser()
  parser.add_argument('--otp',
                      help='One time token used to authenticate with the host')
  parser.add_argument('--controller',
                      help='The ip address of the controller machine')
  parser.add_argument('--idle-timeout', type=int,
                      default=common_lib.DEFAULT_TIMEOUT_SECS,
                      help='The idle timeout for the rpc server in seconds')
  args, _ = parser.parse_known_args()

  logging.info(
      'Registering with registration server at %s using OTP "%s"',
      args.controller, args.otp)
  common_lib.ConnectToServer(args.controller).RegisterTask(
      args.otp, common_lib.MY_IP)

  server = rpc_server.RPCServer(args.controller, args.idle_timeout)

  server.serve_forever()
  logging.info('Server shutdown complete')
  return 0


if __name__ == '__main__':
  sys.exit(main())
