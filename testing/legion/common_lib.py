# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Common library methods used by both coordinator and task machines."""

import argparse
import logging
import os
import socket

LOGGING_LEVELS = ['DEBUG', 'INFO', 'WARNING', 'WARN', 'ERROR']
MY_IP = socket.gethostbyname(socket.gethostname())
SERVER_ADDRESS = ''
SERVER_PORT = 31710
DEFAULT_TIMEOUT_SECS = 20 * 60  # 30 minutes
THIS_DIR = os.path.dirname(os.path.abspath(__file__))
SWARMING_DIR = os.path.join(THIS_DIR, '..', '..', 'tools', 'swarming_client')


def InitLogging():
  """Initialize the logging module.

  Raises:
    argparse.ArgumentError if the --verbosity arg is incorrect.
  """
  parser = argparse.ArgumentParser()
  logging_action = parser.add_argument('--verbosity', default='INFO')
  args, _ = parser.parse_known_args()
  if args.verbosity not in LOGGING_LEVELS:
    raise argparse.ArgumentError(
        logging_action, 'Only levels %s supported' % str(LOGGING_LEVELS))
  logging.basicConfig(
      format='%(asctime)s %(filename)s:%(lineno)s %(levelname)s] %(message)s',
      datefmt='%H:%M:%S', level=args.verbosity)


def GetOutputDir():
  """Get the isolated output directory specified on the command line."""
  parser = argparse.ArgumentParser()
  parser.add_argument('--output-dir')
  args, _ = parser.parse_known_args()
  return args.output_dir
