# Copyright (C) 2013 Google Inc. All rights reserved.
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

import json
import optparse

from webkitpy.layout_tests.port import Port


def main(host, argv):
    parser = optparse.OptionParser(usage='%prog [times_ms.json]')
    parser.add_option('-f', '--forward', action='store', type='int',
                      help='group times by first N directories of test')
    parser.add_option('-b', '--backward', action='store', type='int',
                     help='group times by last N directories of test')
    parser.add_option('--fastest', action='store', type='float',
                      help='print a list of tests that will take N % of the time')

    epilog = """
       You can print out aggregate times per directory using the -f and -b
       flags. The value passed to each flag indicates the "depth" of the flag,
       similar to positive and negative arguments to python arrays.

       For example, given fast/forms/week/week-input-type.html, -f 1
       truncates to 'fast', -f 2 and -b 2 truncates to 'fast/forms', and -b 1
       truncates to fast/forms/week . -f 0 truncates to '', which can be used
       to produce a single total time for the run."""
    parser.epilog = '\n'.join(s.lstrip() for s in epilog.splitlines())

    options, args = parser.parse_args(argv)

    port = host.port_factory.get()
    if args and args[0]:
        times_ms_path = args[0]
    else:
        times_ms_path = host.filesystem.join(port.results_directory(), 'times_ms.json')

    times_trie = json.loads(host.filesystem.read_text_file(times_ms_path))

    times = convert_trie_to_flat_paths(times_trie)

    if options.fastest:
        if options.forward is None and options.backward is None:
            options.forward = 0
        print_fastest(host, port, options, times)
    else:
        print_times(host, options, times)


def print_times(host, options, times):
    by_key = times_by_key(times, options.forward, options.backward)
    for key in sorted(by_key):
        if key:
            host.print_("%s %d" % (key, by_key[key]))
        else:
            host.print_("%d" % by_key[key])


def print_fastest(host, port, options, times):
    total = times_by_key(times, 0, None)['']
    by_key = times_by_key(times, options.forward, options.backward)
    keys_by_time = sorted(by_key, key=lambda k: (by_key[k], k))

    tests_by_key = {}
    for test_name in sorted(times):
        key = key_for(test_name, options.forward, options.backward)
        if key in sorted(tests_by_key):
            tests_by_key[key].append(test_name)
        else:
            tests_by_key[key] = [test_name]

    fast_tests_by_key = {}
    total_so_far = 0
    per_key = total * options.fastest / (len(keys_by_time) * 100.0)
    budget = 0
    while keys_by_time:
        budget += per_key
        key = keys_by_time.pop(0)
        tests_by_time = sorted(tests_by_key[key], key=lambda t: (times[t], t))
        fast_tests_by_key[key] = []
        while tests_by_time and total_so_far <= budget:
            test = tests_by_time.pop(0)
            test_time = times[test]
             # Make sure test time > 0 so we don't include tests that are skipped.
            if test_time and total_so_far + test_time <= budget:
                fast_tests_by_key[key].append(test)
                total_so_far += test_time

    for k in sorted(fast_tests_by_key):
        for t in fast_tests_by_key[k]:
            host.print_("%s %d" % (t, times[t]))
    return


def key_for(path, forward, backward):
    sep = Port.TEST_PATH_SEPARATOR
    if forward is not None:
        return sep.join(path.split(sep)[:-1][:forward])
    if backward is not None:
        return sep.join(path.split(sep)[:-backward])
    return path


def times_by_key(times, forward, backward):
    by_key = {}
    for test_name in times:
        key = key_for(test_name, forward, backward)
        if key in by_key:
            by_key[key] += times[test_name]
        else:
            by_key[key] = times[test_name]
    return by_key


def convert_trie_to_flat_paths(trie, prefix=None):
    result = {}
    for name, data in trie.iteritems():
        if prefix:
            name = prefix + "/" + name
        if isinstance(data, int):
            result[name] = data
        else:
            result.update(convert_trie_to_flat_paths(data, name))

    return result
