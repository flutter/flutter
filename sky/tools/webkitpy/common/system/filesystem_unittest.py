# vim: set fileencoding=utf-8 :
# Copyright (C) 2010 Google Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#    * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#    * Neither the name of Google Inc. nor the names of its
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

# NOTE: The fileencoding comment on the first line of the file is
# important; without it, Python will choke while trying to parse the file,
# since it includes non-ASCII characters.

import os
import stat
import sys
import tempfile
import unittest

from webkitpy.common.system.filesystem import FileSystem


class GenericFileSystemTests(object):
    """Tests that should pass on either a real or mock filesystem."""
    # pylint gets confused about this being a mixin: pylint: disable=E1101
    def setup_generic_test_dir(self):
        fs = self.fs
        self.generic_test_dir = str(self.fs.mkdtemp())
        self.orig_cwd = fs.getcwd()
        fs.chdir(self.generic_test_dir)
        fs.write_text_file('foo.txt', 'foo')
        fs.write_text_file('foobar', 'foobar')
        fs.maybe_make_directory('foodir')
        fs.write_text_file(fs.join('foodir', 'baz'), 'baz')
        fs.chdir(self.orig_cwd)

    def teardown_generic_test_dir(self):
        self.fs.rmtree(self.generic_test_dir)
        self.fs.chdir(self.orig_cwd)
        self.generic_test_dir = None

    def test_glob__trailing_asterisk(self):
        self.fs.chdir(self.generic_test_dir)
        self.assertEqual(set(self.fs.glob('fo*')), set(['foo.txt', 'foobar', 'foodir']))

    def test_glob__leading_asterisk(self):
        self.fs.chdir(self.generic_test_dir)
        self.assertEqual(set(self.fs.glob('*xt')), set(['foo.txt']))

    def test_glob__middle_asterisk(self):
        self.fs.chdir(self.generic_test_dir)
        self.assertEqual(set(self.fs.glob('f*r')), set(['foobar', 'foodir']))

    def test_glob__period_is_escaped(self):
        self.fs.chdir(self.generic_test_dir)
        self.assertEqual(set(self.fs.glob('foo.*')), set(['foo.txt']))

    def test_relpath_unix(self):
        if sys.platform == 'win32':
            return
        self.assertEqual(self.fs.relpath('aaa/bbb'), 'aaa/bbb')
        self.assertEqual(self.fs.relpath('aaa/bbb/'), 'aaa/bbb')
        self.assertEqual(self.fs.relpath('aaa/bbb/.'), 'aaa/bbb')
        self.assertEqual(self.fs.relpath('aaa/./bbb'), 'aaa/bbb')
        self.assertEqual(self.fs.relpath('aaa/../bbb/'), 'bbb')
        self.assertEqual(self.fs.relpath('aaa/bbb', 'aaa/bbb'), '.')
        self.assertEqual(self.fs.relpath('aaa/bbb/ccc', 'aaa/bbb'), 'ccc')
        self.assertEqual(self.fs.relpath('aaa/./ccc', 'aaa/bbb'), '../ccc')
        self.assertEqual(self.fs.relpath('aaa/../ccc', 'aaa/bbb'), '../../ccc')
        self.assertEqual(self.fs.relpath('aaa/bbb', 'aaa/ccc'), '../bbb')
        self.assertEqual(self.fs.relpath('aaa/bbb', 'ccc/ddd'), '../../aaa/bbb')
        self.assertEqual(self.fs.relpath('aaa/bbb', 'aaa/b'), '../bbb')
        self.assertEqual(self.fs.relpath('aaa/bbb', 'a/bbb'), '../../aaa/bbb')

    def test_relpath_win32(self):
        if sys.platform != 'win32':
            return
        self.assertEqual(self.fs.relpath('aaa\\bbb'), 'aaa\\bbb')
        self.assertEqual(self.fs.relpath('aaa\\bbb\\'), 'aaa\\bbb')
        self.assertEqual(self.fs.relpath('aaa\\bbb\\.'), 'aaa\\bbb')
        self.assertEqual(self.fs.relpath('aaa\\.\\bbb'), 'aaa\\bbb')
        self.assertEqual(self.fs.relpath('aaa\\..\\bbb\\'), 'bbb')
        self.assertEqual(self.fs.relpath('aaa\\bbb', 'aaa\\bbb'), '.')
        self.assertEqual(self.fs.relpath('aaa\\bbb\\ccc', 'aaa\\bbb'), 'ccc')
        self.assertEqual(self.fs.relpath('aaa\\.\\ccc', 'aaa\\bbb'), '..\\ccc')
        self.assertEqual(self.fs.relpath('aaa\\..\\ccc', 'aaa\\bbb'), '..\\..\\ccc')
        self.assertEqual(self.fs.relpath('aaa\\bbb', 'aaa\\ccc'), '..\\bbb')
        self.assertEqual(self.fs.relpath('aaa\\bbb', 'ccc\\ddd'), '..\\..\\aaa\\bbb')
        self.assertEqual(self.fs.relpath('aaa\\bbb', 'aaa\\b'), '..\\bbb')
        self.assertEqual(self.fs.relpath('aaa\\bbb', 'a\\bbb'), '..\\..\\aaa\\bbb')

    def test_rmtree(self):
        self.fs.chdir(self.generic_test_dir)
        self.fs.rmtree('foo')
        self.assertTrue(self.fs.exists('foodir'))
        self.assertTrue(self.fs.exists(self.fs.join('foodir', 'baz')))
        self.fs.rmtree('foodir')
        self.assertFalse(self.fs.exists('foodir'))
        self.assertFalse(self.fs.exists(self.fs.join('foodir', 'baz')))

    def test_copytree(self):
        self.fs.chdir(self.generic_test_dir)
        self.fs.copytree('foodir/', 'bardir/')
        self.assertTrue(self.fs.exists('bardir'))
        self.assertTrue(self.fs.exists(self.fs.join('bardir', 'baz')))

    def test_move(self):
        self.fs.chdir(self.generic_test_dir)
        self.fs.move('foo.txt', 'bar.txt')
        self.assertFalse(self.fs.exists('foo.txt'))
        self.assertTrue(self.fs.exists('bar.txt'))
        self.fs.move('foodir', 'bardir')
        self.assertFalse(self.fs.exists('foodir'))
        self.assertFalse(self.fs.exists(self.fs.join('foodir', 'baz')))
        self.assertTrue(self.fs.exists('bardir'))
        self.assertTrue(self.fs.exists(self.fs.join('bardir', 'baz')))

class RealFileSystemTest(unittest.TestCase, GenericFileSystemTests):
    def setUp(self):
        self.fs = FileSystem()
        self.setup_generic_test_dir()

        self._this_dir = os.path.dirname(os.path.abspath(__file__))
        self._missing_file = os.path.join(self._this_dir, 'missing_file.py')
        self._this_file = os.path.join(self._this_dir, 'filesystem_unittest.py')

    def tearDown(self):
        self.teardown_generic_test_dir()
        self.fs = None

    def test_chdir(self):
        fs = FileSystem()
        cwd = fs.getcwd()
        newdir = '/'
        if sys.platform == 'win32':
            newdir = 'c:\\'
        fs.chdir(newdir)
        self.assertEqual(fs.getcwd(), newdir)
        fs.chdir(cwd)

    def test_chdir__notexists(self):
        fs = FileSystem()
        newdir = '/dirdoesnotexist'
        if sys.platform == 'win32':
            newdir = 'c:\\dirdoesnotexist'
        self.assertRaises(OSError, fs.chdir, newdir)

    def test_exists__true(self):
        fs = FileSystem()
        self.assertTrue(fs.exists(self._this_file))

    def test_exists__false(self):
        fs = FileSystem()
        self.assertFalse(fs.exists(self._missing_file))

    def test_getcwd(self):
        fs = FileSystem()
        self.assertTrue(fs.exists(fs.getcwd()))

    def test_isdir__true(self):
        fs = FileSystem()
        self.assertTrue(fs.isdir(self._this_dir))

    def test_isdir__false(self):
        fs = FileSystem()
        self.assertFalse(fs.isdir(self._this_file))

    def test_join(self):
        fs = FileSystem()
        self.assertEqual(fs.join('foo', 'bar'),
                         os.path.join('foo', 'bar'))

    def test_listdir(self):
        fs = FileSystem()
        with fs.mkdtemp(prefix='filesystem_unittest_') as d:
            self.assertEqual(fs.listdir(d), [])
            new_file = os.path.join(d, 'foo')
            fs.write_text_file(new_file, u'foo')
            self.assertEqual(fs.listdir(d), ['foo'])
            os.remove(new_file)

    def test_walk(self):
        fs = FileSystem()
        with fs.mkdtemp(prefix='filesystem_unittest_') as d:
            self.assertEqual(list(fs.walk(d)), [(d, [], [])])
            new_file = os.path.join(d, 'foo')
            fs.write_text_file(new_file, u'foo')
            self.assertEqual(list(fs.walk(d)), [(d, [], ['foo'])])
            os.remove(new_file)

    def test_maybe_make_directory__success(self):
        fs = FileSystem()

        with fs.mkdtemp(prefix='filesystem_unittest_') as base_path:
            sub_path = os.path.join(base_path, "newdir")
            self.assertFalse(os.path.exists(sub_path))
            self.assertFalse(fs.isdir(sub_path))

            fs.maybe_make_directory(sub_path)
            self.assertTrue(os.path.exists(sub_path))
            self.assertTrue(fs.isdir(sub_path))

            # Make sure we can re-create it.
            fs.maybe_make_directory(sub_path)
            self.assertTrue(os.path.exists(sub_path))
            self.assertTrue(fs.isdir(sub_path))

            # Clean up.
            os.rmdir(sub_path)

        self.assertFalse(os.path.exists(base_path))
        self.assertFalse(fs.isdir(base_path))

    def test_maybe_make_directory__failure(self):
        # FIXME: os.chmod() doesn't work on Windows to set directories
        # as readonly, so we skip this test for now.
        if sys.platform in ('win32', 'cygwin'):
            return

        fs = FileSystem()
        with fs.mkdtemp(prefix='filesystem_unittest_') as d:
            # Remove write permissions on the parent directory.
            os.chmod(d, stat.S_IRUSR)

            # Now try to create a sub directory - should fail.
            sub_dir = fs.join(d, 'subdir')
            self.assertRaises(OSError, fs.maybe_make_directory, sub_dir)

            # Clean up in case the test failed and we did create the
            # directory.
            if os.path.exists(sub_dir):
                os.rmdir(sub_dir)

    def test_read_and_write_text_file(self):
        fs = FileSystem()
        text_path = None

        unicode_text_string = u'\u016An\u012Dc\u014Dde\u033D'
        hex_equivalent = '\xC5\xAA\x6E\xC4\xAD\x63\xC5\x8D\x64\x65\xCC\xBD'
        try:
            text_path = tempfile.mktemp(prefix='tree_unittest_')
            file = fs.open_text_file_for_writing(text_path)
            file.write(unicode_text_string)
            file.close()

            file = fs.open_text_file_for_reading(text_path)
            read_text = file.read()
            file.close()

            self.assertEqual(read_text, unicode_text_string)
        finally:
            if text_path and fs.isfile(text_path):
                os.remove(text_path)

    def test_read_and_write_file(self):
        fs = FileSystem()
        text_path = None
        binary_path = None

        unicode_text_string = u'\u016An\u012Dc\u014Dde\u033D'
        hex_equivalent = '\xC5\xAA\x6E\xC4\xAD\x63\xC5\x8D\x64\x65\xCC\xBD'
        try:
            text_path = tempfile.mktemp(prefix='tree_unittest_')
            binary_path = tempfile.mktemp(prefix='tree_unittest_')
            fs.write_text_file(text_path, unicode_text_string)
            contents = fs.read_binary_file(text_path)
            self.assertEqual(contents, hex_equivalent)

            fs.write_binary_file(binary_path, hex_equivalent)
            text_contents = fs.read_text_file(binary_path)
            self.assertEqual(text_contents, unicode_text_string)
        finally:
            if text_path and fs.isfile(text_path):
                os.remove(text_path)
            if binary_path and fs.isfile(binary_path):
                os.remove(binary_path)

    def test_read_binary_file__missing(self):
        fs = FileSystem()
        self.assertRaises(IOError, fs.read_binary_file, self._missing_file)

    def test_read_text_file__missing(self):
        fs = FileSystem()
        self.assertRaises(IOError, fs.read_text_file, self._missing_file)

    def test_remove_file_with_retry(self):
        RealFileSystemTest._remove_failures = 2

        def remove_with_exception(filename):
            RealFileSystemTest._remove_failures -= 1
            if RealFileSystemTest._remove_failures >= 0:
                try:
                    raise WindowsError
                except NameError:
                    raise FileSystem._WindowsError

        fs = FileSystem()
        self.assertTrue(fs.remove('filename', remove_with_exception))
        self.assertEqual(-1, RealFileSystemTest._remove_failures)

    def test_sep(self):
        fs = FileSystem()

        self.assertEqual(fs.sep, os.sep)
        self.assertEqual(fs.join("foo", "bar"),
                          os.path.join("foo", "bar"))
