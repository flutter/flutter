# Copyright (c) 2011 Google Inc. All rights reserved.
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

from webkitpy.tool.multicommandtool import AbstractDeclarativeCommand


class AddUsersToGroups(AbstractDeclarativeCommand):
    name = "add-users-to-groups"
    help_text = "Add users matching subtring to specified groups"

    # This probably belongs in bugzilla.py
    known_groups = ['canconfirm', 'editbugs']

    def execute(self, options, args, tool):
        search_string = args[0]
        # FIXME: We could allow users to specify groups on the command line.
        list_title = 'Add users matching "%s" which groups?' % search_string
        # FIXME: Need a way to specify that "none" is not allowed.
        # FIXME: We could lookup what groups the current user is able to grant from bugzilla.
        groups = tool.user.prompt_with_list(list_title, self.known_groups, can_choose_multiple=True)
        if not groups:
            print "No groups specified."
            return

        login_userid_pairs = tool.bugs.queries.fetch_login_userid_pairs_matching_substring(search_string)
        if not login_userid_pairs:
            print "No users found matching '%s'" % search_string
            return

        print "Found %s users matching %s:" % (len(login_userid_pairs), search_string)
        for (login, user_id) in login_userid_pairs:
            print "%s (%s)" % (login, user_id)

        confirm_message = "Are you sure you want add %s users to groups %s?  (This action cannot be undone using webkit-patch.)" % (len(login_userid_pairs), groups)
        if not tool.user.confirm(confirm_message):
            return

        for (login, user_id) in login_userid_pairs:
            print "Adding %s to %s" % (login, groups)
            tool.bugs.add_user_to_groups(user_id, groups)
