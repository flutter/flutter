# Copyright (C) 2013 Google, Inc.
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Library General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public License
# along with this library; see the file COPYING.LIB.  If not, write to
# the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301, USA.

# This implementaiton of SuperFastHash is based on the Python implementation
# by Victor Perron at <https://github.com/vperron/python-superfasthash>.
# We've modified Victor's version to output hash values that match WTFString,
# which involves using a specific seed and some different constants.

class uint32_t(long):
    def __rshift__(self, other):
        return uint32_t(long.__rshift__(self, other) & ((1L << 32) - 1))

    def __lshift__(self, other):
        return uint32_t(long.__lshift__(self, other) & ((1L << 32) - 1))

    def __add__(self, other):
        return uint32_t(long.__add__(self, other) & ((1L << 32) - 1))

    def __xor__(self, other):
        return uint32_t(long.__xor__(self, other) & ((1L << 32) - 1))


def hash(string):
    """
    Stream-adapted SuperFastHash algorithm from Paul Hsieh,
    http://www.azillionmonkeys.com/qed/hash.html
    LGPLv2.1
    Python version with no dependencies.
    Victor Perron <victor@iso3103.net>
    """

    if not string:
        return 0

    result = uint32_t(0x9E3779B9L)
    length = len(string)
    remainder = length & 1
    length >>= 1

    i = 0
    while length > 0:
        length -= 1
        result += ord(string[i])
        temp = (ord(string[i + 1]) << 11) ^ result
        result = (result << 16) ^ temp
        i += 2
        result += (result >> 11)

    if remainder == 1:
        result += ord(string[i])
        result ^= (result << 11)
        result += (result >> 17)

    # Force "avalanching" of final 127 bits
    result ^= (result << 3)
    result += (result >> 5)
    result ^= (result << 2)
    result += (result >> 15)
    result ^= (result << 10)

    # Save 8 bits for StringImpl to use as flags.
    result &= 0xffffff

    # This avoids ever returning a hash code of 0, since that is used to
    # signal "hash not computed yet".
    assert result != 0

    return result
