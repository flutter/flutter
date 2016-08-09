# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""An option parser which handles the first arg as a command.

Add other nice functionality such as printing a list of commands
and an example in usage.
"""

import optparse
import sys


class CommandOptionParser(optparse.OptionParser):
  """Wrapper class for OptionParser to help with listing commands."""

  def __init__(self, *args, **kwargs):
    """Creates a CommandOptionParser.

    Args:
      commands_dict: A dictionary mapping command strings to an object defining
          - add_options_func: Adds options to the option parser
          - run_command_func: Runs the command itself.
      example: An example command.
      everything else: Passed to optparse.OptionParser contructor.
    """
    self.commands_dict = kwargs.pop('commands_dict', {})
    self.example = kwargs.pop('example', '')
    if not 'usage' in kwargs:
      kwargs['usage'] = 'Usage: %prog <command> [options]'
    optparse.OptionParser.__init__(self, *args, **kwargs)

  #override
  def get_usage(self):
    normal_usage = optparse.OptionParser.get_usage(self)
    command_list = self.get_command_list()
    example = self.get_example()
    return self.expand_prog_name(normal_usage + example + command_list)

  #override
  def get_command_list(self):
    if self.commands_dict.keys():
      return '\nCommands:\n  %s\n' % '\n  '.join(
          sorted(self.commands_dict.keys()))
    return ''

  def get_example(self):
    if self.example:
      return '\nExample:\n  %s\n' % self.example
    return ''


def ParseAndExecute(option_parser, argv=None):
  """Parses options/args from argv and runs the specified command.

  Args:
    option_parser: A CommandOptionParser object.
    argv: Command line arguments. If None, automatically draw from sys.argv.

  Returns:
    An exit code.
  """
  if not argv:
    argv = sys.argv

    if len(argv) < 2 or argv[1] not in option_parser.commands_dict:
      # Parse args first, if this is '--help', optparse will print help and exit
      option_parser.parse_args(argv)
      option_parser.error('Invalid command.')

    cmd = option_parser.commands_dict[argv[1]]
    cmd.add_options_func(option_parser)
    options, args = option_parser.parse_args(argv)
    return cmd.run_command_func(argv[1], options, args, option_parser)
