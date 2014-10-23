# Copyright (c) 2009 Google Inc. All rights reserved.
# Copyright (c) 2009 Apple Inc. All rights reserved.
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
#
# MultiCommandTool provides a framework for writing svn-like/git-like tools
# which are called with the following format:
# tool-name [global options] command-name [command options]

import logging
import sys

from optparse import OptionParser, IndentedHelpFormatter, SUPPRESS_USAGE, make_option

from webkitpy.tool.grammar import pluralize

_log = logging.getLogger(__name__)


class TryAgain(Exception):
    pass


class Command(object):
    name = None
    show_in_main_help = False
    def __init__(self, help_text, argument_names=None, options=None, long_help=None, requires_local_commits=False):
        self.help_text = help_text
        self.long_help = long_help
        self.argument_names = argument_names
        self.required_arguments = self._parse_required_arguments(argument_names)
        self.options = options
        self.requires_local_commits = requires_local_commits
        self._tool = None
        # option_parser can be overriden by the tool using set_option_parser
        # This default parser will be used for standalone_help printing.
        self.option_parser = HelpPrintingOptionParser(usage=SUPPRESS_USAGE, add_help_option=False, option_list=self.options)

    def _exit(self, code):
        sys.exit(code)

    # This design is slightly awkward, but we need the
    # the tool to be able to create and modify the option_parser
    # before it knows what Command to run.
    def set_option_parser(self, option_parser):
        self.option_parser = option_parser
        self._add_options_to_parser()

    def _add_options_to_parser(self):
        options = self.options or []
        for option in options:
            self.option_parser.add_option(option)

    # The tool calls bind_to_tool on each Command after adding it to its list.
    def bind_to_tool(self, tool):
        # Command instances can only be bound to one tool at a time.
        if self._tool and tool != self._tool:
            raise Exception("Command already bound to tool!")
        self._tool = tool

    @staticmethod
    def _parse_required_arguments(argument_names):
        required_args = []
        if not argument_names:
            return required_args
        split_args = argument_names.split(" ")
        for argument in split_args:
            if argument[0] == '[':
                # For now our parser is rather dumb.  Do some minimal validation that
                # we haven't confused it.
                if argument[-1] != ']':
                    raise Exception("Failure to parse argument string %s.  Argument %s is missing ending ]" % (argument_names, argument))
            else:
                required_args.append(argument)
        return required_args

    def name_with_arguments(self):
        usage_string = self.name
        if self.options:
            usage_string += " [options]"
        if self.argument_names:
            usage_string += " " + self.argument_names
        return usage_string

    def parse_args(self, args):
        return self.option_parser.parse_args(args)

    def check_arguments_and_execute(self, options, args, tool=None):
        if len(args) < len(self.required_arguments):
            _log.error("%s required, %s provided.  Provided: %s  Required: %s\nSee '%s help %s' for usage." % (
                       pluralize("argument", len(self.required_arguments)),
                       pluralize("argument", len(args)),
                       "'%s'" % " ".join(args),
                       " ".join(self.required_arguments),
                       tool.name(),
                       self.name))
            return 1
        return self.execute(options, args, tool) or 0

    def standalone_help(self):
        help_text = self.name_with_arguments().ljust(len(self.name_with_arguments()) + 3) + self.help_text + "\n\n"
        if self.long_help:
            help_text += "%s\n\n" % self.long_help
        help_text += self.option_parser.format_option_help(IndentedHelpFormatter())
        return help_text

    def execute(self, options, args, tool):
        raise NotImplementedError, "subclasses must implement"

    # main() exists so that Commands can be turned into stand-alone scripts.
    # Other parts of the code will likely require modification to work stand-alone.
    def main(self, args=sys.argv):
        (options, args) = self.parse_args(args)
        # Some commands might require a dummy tool
        return self.check_arguments_and_execute(options, args)


# FIXME: This should just be rolled into Command.  help_text and argument_names do not need to be instance variables.
class AbstractDeclarativeCommand(Command):
    help_text = None
    argument_names = None
    long_help = None
    def __init__(self, options=None, **kwargs):
        Command.__init__(self, self.help_text, self.argument_names, options=options, long_help=self.long_help, **kwargs)


class HelpPrintingOptionParser(OptionParser):
    def __init__(self, epilog_method=None, *args, **kwargs):
        self.epilog_method = epilog_method
        OptionParser.__init__(self, *args, **kwargs)

    def error(self, msg):
        self.print_usage(sys.stderr)
        error_message = "%s: error: %s\n" % (self.get_prog_name(), msg)
        # This method is overriden to add this one line to the output:
        error_message += "\nType \"%s --help\" to see usage.\n" % self.get_prog_name()
        self.exit(1, error_message)

    # We override format_epilog to avoid the default formatting which would paragraph-wrap the epilog
    # and also to allow us to compute the epilog lazily instead of in the constructor (allowing it to be context sensitive).
    def format_epilog(self, epilog):
        if self.epilog_method:
            return "\n%s\n" % self.epilog_method()
        return ""


class HelpCommand(AbstractDeclarativeCommand):
    name = "help"
    help_text = "Display information about this program or its subcommands"
    argument_names = "[COMMAND]"

    def __init__(self):
        options = [
            make_option("-a", "--all-commands", action="store_true", dest="show_all_commands", help="Print all available commands"),
        ]
        AbstractDeclarativeCommand.__init__(self, options)
        self.show_all_commands = False # A hack used to pass --all-commands to _help_epilog even though it's called by the OptionParser.

    def _help_epilog(self):
        # Only show commands which are relevant to this checkout's SCM system.  Might this be confusing to some users?
        if self.show_all_commands:
            epilog = "All %prog commands:\n"
            relevant_commands = self._tool.commands[:]
        else:
            epilog = "Common %prog commands:\n"
            relevant_commands = filter(self._tool.should_show_in_main_help, self._tool.commands)
        longest_name_length = max(map(lambda command: len(command.name), relevant_commands))
        relevant_commands.sort(lambda a, b: cmp(a.name, b.name))
        command_help_texts = map(lambda command: "   %s   %s\n" % (command.name.ljust(longest_name_length), command.help_text), relevant_commands)
        epilog += "%s\n" % "".join(command_help_texts)
        epilog += "See '%prog help --all-commands' to list all commands.\n"
        epilog += "See '%prog help COMMAND' for more information on a specific command.\n"
        return epilog.replace("%prog", self._tool.name()) # Use of %prog here mimics OptionParser.expand_prog_name().

    # FIXME: This is a hack so that we don't show --all-commands as a global option:
    def _remove_help_options(self):
        for option in self.options:
            self.option_parser.remove_option(option.get_opt_string())

    def execute(self, options, args, tool):
        if args:
            command = self._tool.command_by_name(args[0])
            if command:
                print command.standalone_help()
                return 0

        self.show_all_commands = options.show_all_commands
        self._remove_help_options()
        self.option_parser.print_help()
        return 0


class MultiCommandTool(object):
    global_options = None

    def __init__(self, name=None, commands=None):
        self._name = name or OptionParser(prog=name).get_prog_name() # OptionParser has nice logic for fetching the name.
        # Allow the unit tests to disable command auto-discovery.
        self.commands = commands or [cls() for cls in self._find_all_commands() if cls.name]
        self.help_command = self.command_by_name(HelpCommand.name)
        # Require a help command, even if the manual test list doesn't include one.
        if not self.help_command:
            self.help_command = HelpCommand()
            self.commands.append(self.help_command)
        for command in self.commands:
            command.bind_to_tool(self)

    @classmethod
    def _add_all_subclasses(cls, class_to_crawl, seen_classes):
        for subclass in class_to_crawl.__subclasses__():
            if subclass not in seen_classes:
                seen_classes.add(subclass)
                cls._add_all_subclasses(subclass, seen_classes)

    @classmethod
    def _find_all_commands(cls):
        commands = set()
        cls._add_all_subclasses(Command, commands)
        return sorted(commands)

    def name(self):
        return self._name

    def _create_option_parser(self):
        usage = "Usage: %prog [options] COMMAND [ARGS]"
        return HelpPrintingOptionParser(epilog_method=self.help_command._help_epilog, prog=self.name(), usage=usage)

    @staticmethod
    def _split_command_name_from_args(args):
        # Assume the first argument which doesn't start with "-" is the command name.
        command_index = 0
        for arg in args:
            if arg[0] != "-":
                break
            command_index += 1
        else:
            return (None, args[:])

        command = args[command_index]
        return (command, args[:command_index] + args[command_index + 1:])

    def command_by_name(self, command_name):
        for command in self.commands:
            if command_name == command.name:
                return command
        return None

    def path(self):
        raise NotImplementedError, "subclasses must implement"

    def command_completed(self):
        pass

    def should_show_in_main_help(self, command):
        return command.show_in_main_help

    def should_execute_command(self, command):
        return True

    def _add_global_options(self, option_parser):
        global_options = self.global_options or []
        for option in global_options:
            option_parser.add_option(option)

    def handle_global_options(self, options):
        pass

    def main(self, argv=sys.argv):
        (command_name, args) = self._split_command_name_from_args(argv[1:])

        option_parser = self._create_option_parser()
        self._add_global_options(option_parser)

        command = self.command_by_name(command_name) or self.help_command
        if not command:
            option_parser.error("%s is not a recognized command" % command_name)

        command.set_option_parser(option_parser)
        (options, args) = command.parse_args(args)
        self.handle_global_options(options)

        (should_execute, failure_reason) = self.should_execute_command(command)
        if not should_execute:
            _log.error(failure_reason)
            return 0 # FIXME: Should this really be 0?

        while True:
            try:
                result = command.check_arguments_and_execute(options, args, self)
                break
            except TryAgain, e:
                pass

        self.command_completed()
        return result
