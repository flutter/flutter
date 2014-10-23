# Copyright (c) 2013 Google Inc. All rights reserved.
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

import logging
from optparse import make_option
import time
import traceback

from webkitpy.common.config.irc import update_wait_seconds
from webkitpy.tool.bot.commitannouncer import CommitAnnouncer, CommitAnnouncerThread
from webkitpy.tool.multicommandtool import AbstractDeclarativeCommand

_log = logging.getLogger(__name__)


class CommitAnnouncerCommand(AbstractDeclarativeCommand):
    name = "commit-announcer"
    help_text = "Start an IRC bot for announcing new git commits."
    show_in_main_help = True

    def __init__(self):
        options = [
            make_option("--irc-password", default=None, help="Specify IRC password to use."),
        ]
        AbstractDeclarativeCommand.__init__(self, options)

    def execute(self, options, args, tool):
        bot_thread = CommitAnnouncerThread(tool, options.irc_password)
        bot_thread.start()
        _log.info("Bot started")
        try:
            while bot_thread.is_alive():
                bot_thread.bot.post_new_commits()
                time.sleep(update_wait_seconds)
        except KeyboardInterrupt:
            _log.error("Terminated by keyboard interrupt")
        except Exception, e:
            _log.error("Unexpected error:")
            _log.error(traceback.format_exc())

        if bot_thread.is_alive():
            _log.info("Disconnecting bot")
            bot_thread.stop()
        else:
            _log.info("Bot offline")
        _log.info("Done")
