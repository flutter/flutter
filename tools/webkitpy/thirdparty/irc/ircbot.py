# Copyright (C) 1999--2002  Joel Rosdahl
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA
#
# Joel Rosdahl <joel@rosdahl.net>
#
# $Id: ircbot.py,v 1.23 2008/09/11 07:38:30 keltus Exp $

"""ircbot -- Simple IRC bot library.

This module contains a single-server IRC bot class that can be used to
write simpler bots.
"""

import sys
from UserDict import UserDict

from irclib import SimpleIRCClient
from irclib import nm_to_n, irc_lower, all_events
from irclib import parse_channel_modes, is_channel
from irclib import ServerConnectionError

class SingleServerIRCBot(SimpleIRCClient):
    """A single-server IRC bot class.

    The bot tries to reconnect if it is disconnected.

    The bot keeps track of the channels it has joined, the other
    clients that are present in the channels and which of those that
    have operator or voice modes.  The "database" is kept in the
    self.channels attribute, which is an IRCDict of Channels.
    """
    def __init__(self, server_list, nickname, realname, reconnection_interval=60):
        """Constructor for SingleServerIRCBot objects.

        Arguments:

            server_list -- A list of tuples (server, port) that
                           defines which servers the bot should try to
                           connect to.

            nickname -- The bot's nickname.

            realname -- The bot's realname.

            reconnection_interval -- How long the bot should wait
                                     before trying to reconnect.

            dcc_connections -- A list of initiated/accepted DCC
            connections.
        """

        SimpleIRCClient.__init__(self)
        self.channels = IRCDict()
        self.server_list = server_list
        if not reconnection_interval or reconnection_interval < 0:
            reconnection_interval = 2**31
        self.reconnection_interval = reconnection_interval

        self._nickname = nickname
        self._realname = realname
        for i in ["disconnect", "join", "kick", "mode",
                  "namreply", "nick", "part", "quit"]:
            self.connection.add_global_handler(i,
                                               getattr(self, "_on_" + i),
                                               -10)
    def _connected_checker(self):
        """[Internal]"""
        if not self.connection.is_connected():
            self.connection.execute_delayed(self.reconnection_interval,
                                            self._connected_checker)
            self.jump_server()

    def _connect(self):
        """[Internal]"""
        password = None
        if len(self.server_list[0]) > 2:
            password = self.server_list[0][2]
        try:
            self.connect(self.server_list[0][0],
                         self.server_list[0][1],
                         self._nickname,
                         password,
                         ircname=self._realname)
        except ServerConnectionError:
            pass

    def _on_disconnect(self, c, e):
        """[Internal]"""
        self.channels = IRCDict()
        self.connection.execute_delayed(self.reconnection_interval,
                                        self._connected_checker)

    def _on_join(self, c, e):
        """[Internal]"""
        ch = e.target()
        nick = nm_to_n(e.source())
        if nick == c.get_nickname():
            self.channels[ch] = Channel()
        self.channels[ch].add_user(nick)

    def _on_kick(self, c, e):
        """[Internal]"""
        nick = e.arguments()[0]
        channel = e.target()

        if nick == c.get_nickname():
            del self.channels[channel]
        else:
            self.channels[channel].remove_user(nick)

    def _on_mode(self, c, e):
        """[Internal]"""
        modes = parse_channel_modes(" ".join(e.arguments()))
        t = e.target()
        if is_channel(t):
            ch = self.channels[t]
            for mode in modes:
                if mode[0] == "+":
                    f = ch.set_mode
                else:
                    f = ch.clear_mode
                f(mode[1], mode[2])
        else:
            # Mode on self... XXX
            pass

    def _on_namreply(self, c, e):
        """[Internal]"""

        # e.arguments()[0] == "@" for secret channels,
        #                     "*" for private channels,
        #                     "=" for others (public channels)
        # e.arguments()[1] == channel
        # e.arguments()[2] == nick list

        ch = e.arguments()[1]
        for nick in e.arguments()[2].split():
            if nick[0] == "@":
                nick = nick[1:]
                self.channels[ch].set_mode("o", nick)
            elif nick[0] == "+":
                nick = nick[1:]
                self.channels[ch].set_mode("v", nick)
            self.channels[ch].add_user(nick)

    def _on_nick(self, c, e):
        """[Internal]"""
        before = nm_to_n(e.source())
        after = e.target()
        for ch in self.channels.values():
            if ch.has_user(before):
                ch.change_nick(before, after)

    def _on_part(self, c, e):
        """[Internal]"""
        nick = nm_to_n(e.source())
        channel = e.target()

        if nick == c.get_nickname():
            del self.channels[channel]
        else:
            self.channels[channel].remove_user(nick)

    def _on_quit(self, c, e):
        """[Internal]"""
        nick = nm_to_n(e.source())
        for ch in self.channels.values():
            if ch.has_user(nick):
                ch.remove_user(nick)

    def die(self, msg="Bye, cruel world!"):
        """Let the bot die.

        Arguments:

            msg -- Quit message.
        """

        self.connection.disconnect(msg)
        sys.exit(0)

    def disconnect(self, msg="I'll be back!"):
        """Disconnect the bot.

        The bot will try to reconnect after a while.

        Arguments:

            msg -- Quit message.
        """
        self.connection.disconnect(msg)

    def get_version(self):
        """Returns the bot version.

        Used when answering a CTCP VERSION request.
        """
        return "ircbot.py by Joel Rosdahl <joel@rosdahl.net>"

    def jump_server(self, msg="Changing servers"):
        """Connect to a new server, possibly disconnecting from the current.

        The bot will skip to next server in the server_list each time
        jump_server is called.
        """
        if self.connection.is_connected():
            self.connection.disconnect(msg)

        self.server_list.append(self.server_list.pop(0))
        self._connect()

    def on_ctcp(self, c, e):
        """Default handler for ctcp events.

        Replies to VERSION and PING requests and relays DCC requests
        to the on_dccchat method.
        """
        if e.arguments()[0] == "VERSION":
            c.ctcp_reply(nm_to_n(e.source()),
                         "VERSION " + self.get_version())
        elif e.arguments()[0] == "PING":
            if len(e.arguments()) > 1:
                c.ctcp_reply(nm_to_n(e.source()),
                             "PING " + e.arguments()[1])
        elif e.arguments()[0] == "DCC" and e.arguments()[1].split(" ", 1)[0] == "CHAT":
            self.on_dccchat(c, e)

    def on_dccchat(self, c, e):
        pass

    def start(self):
        """Start the bot."""
        self._connect()
        SimpleIRCClient.start(self)


class IRCDict:
    """A dictionary suitable for storing IRC-related things.

    Dictionary keys a and b are considered equal if and only if
    irc_lower(a) == irc_lower(b)

    Otherwise, it should behave exactly as a normal dictionary.
    """

    def __init__(self, dict=None):
        self.data = {}
        self.canon_keys = {}  # Canonical keys
        if dict is not None:
            self.update(dict)
    def __repr__(self):
        return repr(self.data)
    def __cmp__(self, dict):
        if isinstance(dict, IRCDict):
            return cmp(self.data, dict.data)
        else:
            return cmp(self.data, dict)
    def __len__(self):
        return len(self.data)
    def __getitem__(self, key):
        return self.data[self.canon_keys[irc_lower(key)]]
    def __setitem__(self, key, item):
        if key in self:
            del self[key]
        self.data[key] = item
        self.canon_keys[irc_lower(key)] = key
    def __delitem__(self, key):
        ck = irc_lower(key)
        del self.data[self.canon_keys[ck]]
        del self.canon_keys[ck]
    def __iter__(self):
        return iter(self.data)
    def __contains__(self, key):
        return self.has_key(key)
    def clear(self):
        self.data.clear()
        self.canon_keys.clear()
    def copy(self):
        if self.__class__ is UserDict:
            return UserDict(self.data)
        import copy
        return copy.copy(self)
    def keys(self):
        return self.data.keys()
    def items(self):
        return self.data.items()
    def values(self):
        return self.data.values()
    def has_key(self, key):
        return irc_lower(key) in self.canon_keys
    def update(self, dict):
        for k, v in dict.items():
            self.data[k] = v
    def get(self, key, failobj=None):
        return self.data.get(key, failobj)


class Channel:
    """A class for keeping information about an IRC channel.

    This class can be improved a lot.
    """

    def __init__(self):
        self.userdict = IRCDict()
        self.operdict = IRCDict()
        self.voiceddict = IRCDict()
        self.modes = {}

    def users(self):
        """Returns an unsorted list of the channel's users."""
        return self.userdict.keys()

    def opers(self):
        """Returns an unsorted list of the channel's operators."""
        return self.operdict.keys()

    def voiced(self):
        """Returns an unsorted list of the persons that have voice
        mode set in the channel."""
        return self.voiceddict.keys()

    def has_user(self, nick):
        """Check whether the channel has a user."""
        return nick in self.userdict

    def is_oper(self, nick):
        """Check whether a user has operator status in the channel."""
        return nick in self.operdict

    def is_voiced(self, nick):
        """Check whether a user has voice mode set in the channel."""
        return nick in self.voiceddict

    def add_user(self, nick):
        self.userdict[nick] = 1

    def remove_user(self, nick):
        for d in self.userdict, self.operdict, self.voiceddict:
            if nick in d:
                del d[nick]

    def change_nick(self, before, after):
        self.userdict[after] = 1
        del self.userdict[before]
        if before in self.operdict:
            self.operdict[after] = 1
            del self.operdict[before]
        if before in self.voiceddict:
            self.voiceddict[after] = 1
            del self.voiceddict[before]

    def set_mode(self, mode, value=None):
        """Set mode on the channel.

        Arguments:

            mode -- The mode (a single-character string).

            value -- Value
        """
        if mode == "o":
            self.operdict[value] = 1
        elif mode == "v":
            self.voiceddict[value] = 1
        else:
            self.modes[mode] = value

    def clear_mode(self, mode, value=None):
        """Clear mode on the channel.

        Arguments:

            mode -- The mode (a single-character string).

            value -- Value
        """
        try:
            if mode == "o":
                del self.operdict[value]
            elif mode == "v":
                del self.voiceddict[value]
            else:
                del self.modes[mode]
        except KeyError:
            pass

    def has_mode(self, mode):
        return mode in self.modes

    def is_moderated(self):
        return self.has_mode("m")

    def is_secret(self):
        return self.has_mode("s")

    def is_protected(self):
        return self.has_mode("p")

    def has_topic_lock(self):
        return self.has_mode("t")

    def is_invite_only(self):
        return self.has_mode("i")

    def has_allow_external_messages(self):
        return self.has_mode("n")

    def has_limit(self):
        return self.has_mode("l")

    def limit(self):
        if self.has_limit():
            return self.modes[l]
        else:
            return None

    def has_key(self):
        return self.has_mode("k")

    def key(self):
        if self.has_key():
            return self.modes["k"]
        else:
            return None
