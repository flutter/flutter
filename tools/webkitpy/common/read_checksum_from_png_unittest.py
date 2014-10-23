# Copyright (C) 2011 Google Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1.  Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
# 2.  Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import StringIO
import unittest

from webkitpy.common import read_checksum_from_png


class ReadChecksumFromPngTest(unittest.TestCase):
    def test_read_checksum(self):
        # Test a file with the comment.
        filehandle = StringIO.StringIO('''\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x03 \x00\x00\x02X\x08\x02\x00\x00\x00\x15\x14\x15'\x00\x00\x00)tEXtchecksum\x003c4134fe2739880353f91c5b84cadbaaC\xb8?\xec\x00\x00\x16\xfeIDATx\x9c\xed\xdd[\x8cU\xe5\xc1\xff\xf15T\x18\x0ea,)\xa6\x80XZ<\x10\n\xd6H\xc4V\x88}\xb5\xa9\xd6r\xd5\x0bki0\xa6\xb5ih\xd2\xde\x98PHz\xd1\x02=\\q#\x01\x8b\xa5rJ\x8b\x88i\xacM\xc5h\x8cbMk(\x1ez@!\x0c\xd5\xd2\xc2\xb44\x1c\x848\x1dF(\xeb\x7f\xb1\xff\xd9\xef~g\xd6\xde3\xe0o\x10\xec\xe7sa6{\xd6z\xd6\xb3\xd7\xf3\xa8_7\xdbM[Y\x96\x05\x00\x009\xc3\xde\xeb\t\x00\x00\xbc\xdf\x08,\x00\x800\x81\x05\x00\x10&\xb0\x00\x00\xc2\x04\x16\x00@\x98\xc0\x02\x00\x08\x13X\x00\x00a\x02\x0b\x00 Lx01\x00\x84\t,\x00\x800\x81\x05\x00\x10\xd64\xb0\xda\x9a\xdb\xb6m\xdb\xb4i\xd3\xfa\x9fr\xf3\xcd7\x0f\xe5T\x07\xe5\xd4\xa9''')
        checksum = read_checksum_from_png.read_checksum(filehandle)
        self.assertEqual('3c4134fe2739880353f91c5b84cadbaa', checksum)

        # Test a file without the comment.
        filehandle = StringIO.StringIO('''\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x03 \x00\x00\x02X\x08\x02\x00\x00\x00\x15\x14\x15'\x00\x00\x16\xfeIDATx\x9c\xed\xdd[\x8cU\xe5\xc1\xff\xf15T\x18\x0ea,)\xa6\x80XZ<\x10\n\xd6H\xc4V\x88}\xb5\xa9\xd6r\xd5\x0bki0\xa6\xb5ih\xd2\xde\x98PHz\xd1\x02=\\q#\x01\x8b\xa5rJ\x8b\x88i\xacM\xc5h\x8cbMk(\x1ez@!\x0c\xd5\xd2\xc2\xb44\x1c\x848\x1dF(\xeb\x7f\xb1\xff\xd9\xef~g\xd6\xde3\xe0o\x10\xec\xe7sa6{\xd6z\xd6\xb3\xd7\xf3\xa8_7\xdbM[Y\x96\x05\x00\x009\xc3\xde\xeb\t\x00\x00\xbc\xdf\x08,\x00\x800\x81\x05\x00\x10&\xb0\x00\x00\xc2\x04\x16\x00@\x98\xc0\x02\x00\x08\x13X\x00\x00a\x02\x0b\x00 Lx01\x00\x84\t,\x00\x800\x81\x05\x00\x10\xd64\xb0\xda\x9a\xdb\xb6m\xdb\xb4i\xd3\xfa\x9fr\xf3\xcd7\x0f\xe5T\x07\xe5\xd4\xa9S\x8b\x17/\x1e?~\xfc\xf8\xf1\xe3\xef\xbf\xff\xfe\xf7z:M5\xbb\x87\x17\xcbUZ\x8f|V\xd7\xbd\x10\xb6\xcd{b\x88\xf6j\xb3\x9b?\x14\x9b\xa1>\xe6\xf9\xd9\xcf\x00\x17\x93''')
        checksum = read_checksum_from_png.read_checksum(filehandle)
        self.assertIsNone(checksum)
