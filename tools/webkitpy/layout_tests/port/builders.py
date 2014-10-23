# Copyright (C) 2011 Google Inc. All rights reserved.
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

import re

from webkitpy.common.memoized import memoized


# In this dictionary, each item stores:
# * port_name -- a fully qualified port name
# * rebaseline_override_dir -- (optional) directory to put baselines in instead of where you would normally put them.
#      This is useful when we don't have bots that cover particular configurations; so, e.g., you might
#      support mac-mountainlion but not have a mac-mountainlion bot yet, so you'd want to put the mac-lion
#      results into platform/mac temporarily.
# * specifiers -- TestExpectation specifiers for that config. Valid values are found in
#      TestExpectationsParser._configuration_tokens_list

_exact_matches = {
    "WebKit XP": {"port_name": "win-xp", "specifiers": ['XP', 'Release']},
    "WebKit Win7": {"port_name": "win-win7", "specifiers": ['Win7', 'Release']},
    "WebKit Win7 (dbg)": {"port_name": "win-win7", "specifiers": ['Win7', 'Debug']},
    "WebKit Linux": {"port_name": "linux-x86_64", "specifiers": ['Linux', 'Release']},
    "WebKit Linux 32": {"port_name": "linux-x86", "specifiers": ['Linux', 'Release']},
    "WebKit Linux (dbg)": {"port_name": "linux-x86_64", "specifiers": ['Linux', 'Debug']},
    "WebKit Mac10.6": {"port_name": "mac-snowleopard", "specifiers": ['SnowLeopard', 'Release']},
    "WebKit Mac10.6 (dbg)": {"port_name": "mac-snowleopard", "specifiers": ['SnowLeopard', 'Debug']},
    "WebKit Mac10.7": {"port_name": "mac-lion", "specifiers": ['Lion', 'Release']},
    "WebKit Mac10.7 (dbg)": {"port_name": "mac-lion", "specifiers": ['Lion', 'Debug']},
    "WebKit Mac10.8": {"port_name": "mac-mountainlion", "specifiers": ['MountainLion', 'Release']},
    "WebKit Mac10.8 (retina)": {"port_name": "mac-retina", "specifiers": ['Retina', 'Release']},
    "WebKit Mac10.9": {"port_name": "mac-mavericks", "specifiers": ['Mavericks', 'Release']},
    "WebKit Android (Nexus4)": {"port_name": "android", "specifiers": ['Android', 'Release']},
}


# Mapping from port name to the deps builder of the same os:
_deps_builders = {
    "linux-x86": "WebKit Linux (deps)",
    "linux-x86_64": "WebKit Linux (deps)",
    "win-xp": "WebKit XP (deps)",
    "win-win7": "WebKit XP (deps)",
    "mac-snowleopard": "WebKit Mac10.6 (deps)",
    "mac-lion": "WebKit Mac10.6 (deps)",
    "mac-mountainlion": "WebKit Mac10.6 (deps)",
    "mac-mavericks": "WebKit Mac10.6 (deps)",
    "mac-retina": "WebKit Mac10.6 (deps)",
}


_ports_without_builders = [
]


def builder_path_from_name(builder_name):
    return re.sub(r'[\s().]', '_', builder_name)


def all_builder_names():
    return sorted(set(_exact_matches.keys()))


def all_port_names():
    return sorted(set(map(lambda x: x["port_name"], _exact_matches.values()) + _ports_without_builders))


def rebaseline_override_dir(builder_name):
    return _exact_matches[builder_name].get("rebaseline_override_dir", None)


def port_name_for_builder_name(builder_name):
    return _exact_matches[builder_name]["port_name"]


def specifiers_for_builder(builder_name):
    return _exact_matches[builder_name]["specifiers"]


def builder_name_for_port_name(target_port_name):
    debug_builder_name = None
    for builder_name, builder_info in _exact_matches.items():
        if builder_info['port_name'] == target_port_name:
            if 'dbg' in builder_name:
                debug_builder_name = builder_name
            else:
                return builder_name
    return debug_builder_name


def builder_path_for_port_name(port_name):
    builder_path_from_name(builder_name_for_port_name(port_name))


def deps_builder_name_for_port_name(target_port_name):
    return _deps_builders.get(target_port_name, None)
