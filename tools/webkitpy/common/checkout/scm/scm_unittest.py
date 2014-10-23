# Copyright (C) 2009 Google Inc. All rights reserved.
# Copyright (C) 2009 Apple Inc. All rights reserved.
# Copyright (C) 2011 Daniel Bates (dbates@intudata.com). All rights reserved.
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

import atexit
import os
import shutil
import unittest

from webkitpy.common.system.executive import Executive, ScriptError
from webkitpy.common.system.executive_mock import MockExecutive
from webkitpy.common.system.filesystem import FileSystem
from webkitpy.common.system.filesystem_mock import MockFileSystem
from webkitpy.common.checkout.scm.detection import detect_scm_system
from webkitpy.common.checkout.scm.git import Git, AmbiguousCommitError
from webkitpy.common.checkout.scm.scm import SCM
from webkitpy.common.checkout.scm.svn import SVN


# We cache the mock SVN repo so that we don't create it again for each call to an SVNTest or GitTest test_ method.
# We store it in a global variable so that we can delete this cached repo on exit(3).
original_cwd = None
cached_svn_repo_path = None

@atexit.register
def delete_cached_svn_repo_at_exit():
    if cached_svn_repo_path:
        os.chdir(original_cwd)
        shutil.rmtree(cached_svn_repo_path)


class SCMTestBase(unittest.TestCase):
    def __init__(self, *args, **kwargs):
        super(SCMTestBase, self).__init__(*args, **kwargs)
        self.scm = None
        self.executive = None
        self.fs = None
        self.original_cwd = None

    def setUp(self):
        self.executive = Executive()
        self.fs = FileSystem()
        self.original_cwd = self.fs.getcwd()

    def tearDown(self):
        self._chdir(self.original_cwd)

    def _join(self, *comps):
        return self.fs.join(*comps)

    def _chdir(self, path):
        self.fs.chdir(path)

    def _mkdir(self, path):
        assert not self.fs.exists(path)
        self.fs.maybe_make_directory(path)

    def _mkdtemp(self, **kwargs):
        return str(self.fs.mkdtemp(**kwargs))

    def _remove(self, path):
        self.fs.remove(path)

    def _rmtree(self, path):
        self.fs.rmtree(path)

    def _run(self, *args, **kwargs):
        return self.executive.run_command(*args, **kwargs)

    def _run_silent(self, args, **kwargs):
        self.executive.run_and_throw_if_fail(args, quiet=True, **kwargs)

    def _write_text_file(self, path, contents):
        self.fs.write_text_file(path, contents)

    def _write_binary_file(self, path, contents):
        self.fs.write_binary_file(path, contents)

    def _make_diff(self, command, *args):
        # We use this wrapper to disable output decoding. diffs should be treated as
        # binary files since they may include text files of multiple differnet encodings.
        return self._run([command, "diff"] + list(args), decode_output=False)

    def _svn_diff(self, *args):
        return self._make_diff("svn", *args)

    def _git_diff(self, *args):
        return self._make_diff("git", *args)

    def _svn_add(self, path):
        self._run(["svn", "add", path])

    def _svn_commit(self, message):
        self._run(["svn", "commit", "--quiet", "--message", message])

    # This is a hot function since it's invoked by unittest before calling each test_ method in SVNTest and
    # GitTest. We create a mock SVN repo once and then perform an SVN checkout from a filesystem copy of
    # it since it's expensive to create the mock repo.
    def _set_up_svn_checkout(self):
        global cached_svn_repo_path
        global original_cwd
        if not cached_svn_repo_path:
            cached_svn_repo_path = self._set_up_svn_repo()
            original_cwd = self.original_cwd

        self.temp_directory = self._mkdtemp(suffix="svn_test")
        self.svn_repo_path = self._join(self.temp_directory, "repo")
        self.svn_repo_url = "file://%s" % self.svn_repo_path
        self.svn_checkout_path = self._join(self.temp_directory, "checkout")
        shutil.copytree(cached_svn_repo_path, self.svn_repo_path)
        self._run(['svn', 'checkout', '--quiet', self.svn_repo_url + "/trunk", self.svn_checkout_path])

    def _set_up_svn_repo(self):
        svn_repo_path = self._mkdtemp(suffix="svn_test_repo")
        svn_repo_url = "file://%s" % svn_repo_path  # Not sure this will work on windows
        # git svn complains if we don't pass --pre-1.5-compatible, not sure why:
        # Expected FS format '2'; found format '3' at /usr/local/libexec/git-core//git-svn line 1477
        self._run(['svnadmin', 'create', '--pre-1.5-compatible', svn_repo_path])

        # Create a test svn checkout
        svn_checkout_path = self._mkdtemp(suffix="svn_test_checkout")
        self._run(['svn', 'checkout', '--quiet', svn_repo_url, svn_checkout_path])

        # Create and checkout a trunk dir to match the standard svn configuration to match git-svn's expectations
        self._chdir(svn_checkout_path)
        self._mkdir('trunk')
        self._svn_add('trunk')
        # We can add tags and branches as well if we ever need to test those.
        self._svn_commit('add trunk')

        self._rmtree(svn_checkout_path)

        self._set_up_svn_test_commits(svn_repo_url + "/trunk")
        return svn_repo_path

    def _set_up_svn_test_commits(self, svn_repo_url):
        svn_checkout_path = self._mkdtemp(suffix="svn_test_checkout")
        self._run(['svn', 'checkout', '--quiet', svn_repo_url, svn_checkout_path])

        # Add some test commits
        self._chdir(svn_checkout_path)

        self._write_text_file("test_file", "test1")
        self._svn_add("test_file")
        self._svn_commit("initial commit")

        self._write_text_file("test_file", "test1test2")
        # This used to be the last commit, but doing so broke
        # GitTest.test_apply_git_patch which use the inverse diff of the last commit.
        # svn-apply fails to remove directories in Git, see:
        # https://bugs.webkit.org/show_bug.cgi?id=34871
        self._mkdir("test_dir")
        # Slash should always be the right path separator since we use cygwin on Windows.
        test_file3_path = "test_dir/test_file3"
        self._write_text_file(test_file3_path, "third file")
        self._svn_add("test_dir")
        self._svn_commit("second commit")

        self._write_text_file("test_file", "test1test2test3\n")
        self._write_text_file("test_file2", "second file")
        self._svn_add("test_file2")
        self._svn_commit("third commit")

        # This 4th commit is used to make sure that our patch file handling
        # code correctly treats patches as binary and does not attempt to
        # decode them assuming they're utf-8.
        self._write_binary_file("test_file", u"latin1 test: \u00A0\n".encode("latin-1"))
        self._write_binary_file("test_file2", u"utf-8 test: \u00A0\n".encode("utf-8"))
        self._svn_commit("fourth commit")

        # svn does not seem to update after commit as I would expect.
        self._run(['svn', 'update'])
        self._rmtree(svn_checkout_path)

    def _tear_down_svn_checkout(self):
        self._rmtree(self.temp_directory)

    def _shared_test_add_recursively(self):
        self._mkdir("added_dir")
        self._write_text_file("added_dir/added_file", "new stuff")
        self.scm.add("added_dir/added_file")
        self.assertIn("added_dir/added_file", self.scm._added_files())

    def _shared_test_delete_recursively(self):
        self._mkdir("added_dir")
        self._write_text_file("added_dir/added_file", "new stuff")
        self.scm.add("added_dir/added_file")
        self.assertIn("added_dir/added_file", self.scm._added_files())
        self.scm.delete("added_dir/added_file")
        self.assertNotIn("added_dir", self.scm._added_files())

    def _shared_test_delete_recursively_or_not(self):
        self._mkdir("added_dir")
        self._write_text_file("added_dir/added_file", "new stuff")
        self._write_text_file("added_dir/another_added_file", "more new stuff")
        self.scm.add("added_dir/added_file")
        self.scm.add("added_dir/another_added_file")
        self.assertIn("added_dir/added_file", self.scm._added_files())
        self.assertIn("added_dir/another_added_file", self.scm._added_files())
        self.scm.delete("added_dir/added_file")
        self.assertIn("added_dir/another_added_file", self.scm._added_files())

    def _shared_test_exists(self, scm, commit_function):
        self._chdir(scm.checkout_root)
        self.assertFalse(scm.exists('foo.txt'))
        self._write_text_file('foo.txt', 'some stuff')
        self.assertFalse(scm.exists('foo.txt'))
        scm.add('foo.txt')
        commit_function('adding foo')
        self.assertTrue(scm.exists('foo.txt'))
        scm.delete('foo.txt')
        commit_function('deleting foo')
        self.assertFalse(scm.exists('foo.txt'))

    def _shared_test_move(self):
        self._write_text_file('added_file', 'new stuff')
        self.scm.add('added_file')
        self.scm.move('added_file', 'moved_file')
        self.assertIn('moved_file', self.scm._added_files())

    def _shared_test_move_recursive(self):
        self._mkdir("added_dir")
        self._write_text_file('added_dir/added_file', 'new stuff')
        self._write_text_file('added_dir/another_added_file', 'more new stuff')
        self.scm.add('added_dir')
        self.scm.move('added_dir', 'moved_dir')
        self.assertIn('moved_dir/added_file', self.scm._added_files())
        self.assertIn('moved_dir/another_added_file', self.scm._added_files())


class SVNTest(SCMTestBase):
    def setUp(self):
        super(SVNTest, self).setUp()
        self._set_up_svn_checkout()
        self._chdir(self.svn_checkout_path)
        self.scm = detect_scm_system(self.svn_checkout_path)
        self.scm.svn_server_realm = None

    def tearDown(self):
        super(SVNTest, self).tearDown()
        self._tear_down_svn_checkout()

    def test_detect_scm_system_relative_url(self):
        scm = detect_scm_system(".")
        # I wanted to assert that we got the right path, but there was some
        # crazy magic with temp folder names that I couldn't figure out.
        self.assertTrue(scm.checkout_root)

    def test_detection(self):
        self.assertEqual(self.scm.display_name(), "svn")
        self.assertEqual(self.scm.supports_local_commits(), False)

    def test_add_recursively(self):
        self._shared_test_add_recursively()

    def test_delete(self):
        self._chdir(self.svn_checkout_path)
        self.scm.delete("test_file")
        self.assertIn("test_file", self.scm._deleted_files())

    def test_delete_list(self):
        self._chdir(self.svn_checkout_path)
        self.scm.delete_list(["test_file", "test_file2"])
        self.assertIn("test_file", self.scm._deleted_files())
        self.assertIn("test_file2", self.scm._deleted_files())

    def test_delete_recursively(self):
        self._shared_test_delete_recursively()

    def test_delete_recursively_or_not(self):
        self._shared_test_delete_recursively_or_not()

    def test_move(self):
        self._shared_test_move()

    def test_move_recursive(self):
        self._shared_test_move_recursive()


class GitTest(SCMTestBase):
    def setUp(self):
        super(GitTest, self).setUp()
        self._set_up_git_checkouts()

    def tearDown(self):
        super(GitTest, self).tearDown()
        self._tear_down_git_checkouts()

    def _set_up_git_checkouts(self):
        """Sets up fresh git repository with one commit. Then sets up a second git repo that tracks the first one."""

        self.untracking_checkout_path = self._mkdtemp(suffix="git_test_checkout2")
        self._run(['git', 'init', self.untracking_checkout_path])

        self._chdir(self.untracking_checkout_path)
        self._write_text_file('foo_file', 'foo')
        self._run(['git', 'add', 'foo_file'])
        self._run(['git', 'commit', '-am', 'dummy commit'])
        self.untracking_scm = detect_scm_system(self.untracking_checkout_path)

        self.tracking_git_checkout_path = self._mkdtemp(suffix="git_test_checkout")
        self._run(['git', 'clone', '--quiet', self.untracking_checkout_path, self.tracking_git_checkout_path])
        self._chdir(self.tracking_git_checkout_path)
        self.tracking_scm = detect_scm_system(self.tracking_git_checkout_path)

    def _tear_down_git_checkouts(self):
        self._run(['rm', '-rf', self.tracking_git_checkout_path])
        self._run(['rm', '-rf', self.untracking_checkout_path])

    def test_remote_branch_ref(self):
        self.assertEqual(self.tracking_scm._remote_branch_ref(), 'refs/remotes/origin/master')
        self._chdir(self.untracking_checkout_path)
        self.assertRaises(ScriptError, self.untracking_scm._remote_branch_ref)

    def test_multiple_remotes(self):
        self._run(['git', 'config', '--add', 'svn-remote.svn.fetch', 'trunk:remote1'])
        self._run(['git', 'config', '--add', 'svn-remote.svn.fetch', 'trunk:remote2'])
        self.assertEqual(self.tracking_scm._remote_branch_ref(), 'remote1')

    def test_create_patch(self):
        self._write_text_file('test_file_commit1', 'contents')
        self._run(['git', 'add', 'test_file_commit1'])
        scm = self.tracking_scm
        scm.commit_locally_with_message('message')

        patch = scm.create_patch()
        self.assertNotRegexpMatches(patch, r'Subversion Revision:')

    def test_exists(self):
        scm = self.untracking_scm
        self._shared_test_exists(scm, scm.commit_locally_with_message)

    def test_rename_files(self):
        scm = self.tracking_scm
        scm.move('foo_file', 'bar_file')
        scm.commit_locally_with_message('message')


class GitSVNTest(SCMTestBase):
    def setUp(self):
        super(GitSVNTest, self).setUp()
        self._set_up_svn_checkout()
        self._set_up_gitsvn_checkout()
        self.scm = detect_scm_system(self.git_checkout_path)
        self.scm.svn_server_realm = None

    def tearDown(self):
        super(GitSVNTest, self).tearDown()
        self._tear_down_svn_checkout()
        self._tear_down_gitsvn_checkout()

    def _set_up_gitsvn_checkout(self):
        self.git_checkout_path = self._mkdtemp(suffix="git_test_checkout")
        # --quiet doesn't make git svn silent
        self._run_silent(['git', 'svn', 'clone', '-T', 'trunk', self.svn_repo_url, self.git_checkout_path])
        self._chdir(self.git_checkout_path)
        self.git_v2 = self._run(['git', '--version']).startswith('git version 2')
        if self.git_v2:
            # The semantics of 'git svn clone -T' changed in v2 (apparently), so the branch names are different.
            # This works around it, for compatibility w/ v1.
            self._run_silent(['git', 'branch', 'trunk', 'origin/trunk'])

    def _tear_down_gitsvn_checkout(self):
        self._rmtree(self.git_checkout_path)

    def test_detection(self):
        self.assertEqual(self.scm.display_name(), "git")
        self.assertEqual(self.scm.supports_local_commits(), True)

    def test_read_git_config(self):
        key = 'test.git-config'
        value = 'git-config value'
        self._run(['git', 'config', key, value])
        self.assertEqual(self.scm.read_git_config(key), value)

    def test_local_commits(self):
        test_file = self._join(self.git_checkout_path, 'test_file')
        self._write_text_file(test_file, 'foo')
        self._run(['git', 'commit', '-a', '-m', 'local commit'])

        self.assertEqual(len(self.scm._local_commits()), 1)

    def test_discard_local_commits(self):
        test_file = self._join(self.git_checkout_path, 'test_file')
        self._write_text_file(test_file, 'foo')
        self._run(['git', 'commit', '-a', '-m', 'local commit'])

        self.assertEqual(len(self.scm._local_commits()), 1)
        self.scm._discard_local_commits()
        self.assertEqual(len(self.scm._local_commits()), 0)

    def test_delete_branch(self):
        new_branch = 'foo'

        self._run(['git', 'checkout', '-b', new_branch])
        self.assertEqual(self._run(['git', 'symbolic-ref', 'HEAD']).strip(), 'refs/heads/' + new_branch)

        self._run(['git', 'checkout', '-b', 'bar'])
        self.scm.delete_branch(new_branch)

        self.assertNotRegexpMatches(self._run(['git', 'branch']), r'foo')

    def test_rebase_in_progress(self):
        svn_test_file = self._join(self.svn_checkout_path, 'test_file')
        self._write_text_file(svn_test_file, "svn_checkout")
        self._run(['svn', 'commit', '--message', 'commit to conflict with git commit'], cwd=self.svn_checkout_path)

        git_test_file = self._join(self.git_checkout_path, 'test_file')
        self._write_text_file(git_test_file, "git_checkout")
        self._run(['git', 'commit', '-a', '-m', 'commit to be thrown away by rebase abort'])

        # Should fail due to a conflict leaving us mid-rebase.
        # we use self._run_slient because --quiet doesn't actually make git svn silent.
        self.assertRaises(ScriptError, self._run_silent, ['git', 'svn', '--quiet', 'rebase'])

        self.assertTrue(self.scm._rebase_in_progress())

        # Make sure our cleanup works.
        self.scm._discard_working_directory_changes()
        self.assertFalse(self.scm._rebase_in_progress())

        # Make sure cleanup doesn't throw when no rebase is in progress.
        self.scm._discard_working_directory_changes()

    def _local_commit(self, filename, contents, message):
        self._write_text_file(filename, contents)
        self._run(['git', 'add', filename])
        self.scm.commit_locally_with_message(message)

    def _one_local_commit(self):
        self._local_commit('test_file_commit1', 'more test content', 'another test commit')

    def _one_local_commit_plus_working_copy_changes(self):
        self._one_local_commit()
        self._write_text_file('test_file_commit2', 'still more test content')
        self._run(['git', 'add', 'test_file_commit2'])

    def _second_local_commit(self):
        self._local_commit('test_file_commit2', 'still more test content', 'yet another test commit')

    def _two_local_commits(self):
        self._one_local_commit()
        self._second_local_commit()

    def _three_local_commits(self):
        self._local_commit('test_file_commit0', 'more test content', 'another test commit')
        self._two_local_commits()

    def test_locally_commit_all_working_copy_changes(self):
        self._local_commit('test_file', 'test content', 'test commit')
        self._write_text_file('test_file', 'changed test content')
        self.assertTrue(self.scm.has_working_directory_changes())
        self.scm.commit_locally_with_message('all working copy changes')
        self.assertFalse(self.scm.has_working_directory_changes())

    def test_locally_commit_no_working_copy_changes(self):
        self._local_commit('test_file', 'test content', 'test commit')
        self._write_text_file('test_file', 'changed test content')
        self.assertTrue(self.scm.has_working_directory_changes())
        self.assertRaises(ScriptError, self.scm.commit_locally_with_message, 'no working copy changes', False)

    def _test_upstream_branch(self):
        self._run(['git', 'checkout', '-t', '-b', 'my-branch'])
        self._run(['git', 'checkout', '-t', '-b', 'my-second-branch'])
        self.assertEqual(self.scm._upstream_branch(), 'my-branch')

    def test_remote_branch_ref(self):
        remote_branch_ref = self.scm._remote_branch_ref()
        if self.git_v2:
            self.assertEqual(remote_branch_ref, 'refs/remotes/origin/trunk')
        else:
            self.assertEqual(remote_branch_ref, 'refs/remotes/trunk')

    def test_create_patch_local_plus_working_copy(self):
        self._one_local_commit_plus_working_copy_changes()
        patch = self.scm.create_patch()
        self.assertRegexpMatches(patch, r'test_file_commit1')
        self.assertRegexpMatches(patch, r'test_file_commit2')

    def test_create_patch(self):
        self._one_local_commit_plus_working_copy_changes()
        patch = self.scm.create_patch()
        self.assertRegexpMatches(patch, r'test_file_commit2')
        self.assertRegexpMatches(patch, r'test_file_commit1')
        self.assertRegexpMatches(patch, r'Subversion Revision: 5')

    def test_create_patch_after_merge(self):
        self._run(['git', 'checkout', '-b', 'dummy-branch', 'trunk~3'])
        self._one_local_commit()
        self._run(['git', 'merge', 'trunk'])

        patch = self.scm.create_patch()
        self.assertRegexpMatches(patch, r'test_file_commit1')
        self.assertRegexpMatches(patch, r'Subversion Revision: 5')

    def test_create_patch_with_changed_files(self):
        self._one_local_commit_plus_working_copy_changes()
        patch = self.scm.create_patch(changed_files=['test_file_commit2'])
        self.assertRegexpMatches(patch, r'test_file_commit2')

    def test_create_patch_with_rm_and_changed_files(self):
        self._one_local_commit_plus_working_copy_changes()
        self._remove('test_file_commit1')
        patch = self.scm.create_patch()
        patch_with_changed_files = self.scm.create_patch(changed_files=['test_file_commit1', 'test_file_commit2'])
        self.assertEqual(patch, patch_with_changed_files)

    def test_create_patch_git_commit(self):
        self._two_local_commits()
        patch = self.scm.create_patch(git_commit="HEAD^")
        self.assertRegexpMatches(patch, r'test_file_commit1')
        self.assertNotRegexpMatches(patch, r'test_file_commit2')

    def test_create_patch_git_commit_range(self):
        self._three_local_commits()
        patch = self.scm.create_patch(git_commit="HEAD~2..HEAD")
        self.assertNotRegexpMatches(patch, r'test_file_commit0')
        self.assertRegexpMatches(patch, r'test_file_commit2')
        self.assertRegexpMatches(patch, r'test_file_commit1')

    def test_create_patch_working_copy_only(self):
        self._one_local_commit_plus_working_copy_changes()
        patch = self.scm.create_patch(git_commit="HEAD....")
        self.assertNotRegexpMatches(patch, r'test_file_commit1')
        self.assertRegexpMatches(patch, r'test_file_commit2')

    def test_create_patch_multiple_local_commits(self):
        self._two_local_commits()
        patch = self.scm.create_patch()
        self.assertRegexpMatches(patch, r'test_file_commit2')
        self.assertRegexpMatches(patch, r'test_file_commit1')

    def test_create_patch_not_synced(self):
        self._run(['git', 'checkout', '-b', 'my-branch', 'trunk~3'])
        self._two_local_commits()
        patch = self.scm.create_patch()
        self.assertNotRegexpMatches(patch, r'test_file2')
        self.assertRegexpMatches(patch, r'test_file_commit2')
        self.assertRegexpMatches(patch, r'test_file_commit1')

    def test_create_binary_patch(self):
        # Create a git binary patch and check the contents.
        test_file_name = 'binary_file'
        test_file_path = self.fs.join(self.git_checkout_path, test_file_name)
        file_contents = ''.join(map(chr, range(256)))
        self._write_binary_file(test_file_path, file_contents)
        self._run(['git', 'add', test_file_name])
        patch = self.scm.create_patch()
        self.assertRegexpMatches(patch, r'\nliteral 0\n')
        self.assertRegexpMatches(patch, r'\nliteral 256\n')

        # Check if we can create a patch from a local commit.
        self._write_binary_file(test_file_path, file_contents)
        self._run(['git', 'add', test_file_name])
        self._run(['git', 'commit', '-m', 'binary diff'])

        patch_from_local_commit = self.scm.create_patch('HEAD')
        self.assertRegexpMatches(patch_from_local_commit, r'\nliteral 0\n')
        self.assertRegexpMatches(patch_from_local_commit, r'\nliteral 256\n')


    def test_changed_files_local_plus_working_copy(self):
        self._one_local_commit_plus_working_copy_changes()
        files = self.scm.changed_files()
        self.assertIn('test_file_commit1', files)
        self.assertIn('test_file_commit2', files)

        # working copy should *not* be in the list.
        files = self.scm.changed_files('trunk..')
        self.assertIn('test_file_commit1', files)
        self.assertNotIn('test_file_commit2', files)

        # working copy *should* be in the list.
        files = self.scm.changed_files('trunk....')
        self.assertIn('test_file_commit1', files)
        self.assertIn('test_file_commit2', files)

    def test_changed_files_git_commit(self):
        self._two_local_commits()
        files = self.scm.changed_files(git_commit="HEAD^")
        self.assertIn('test_file_commit1', files)
        self.assertNotIn('test_file_commit2', files)

    def test_changed_files_git_commit_range(self):
        self._three_local_commits()
        files = self.scm.changed_files(git_commit="HEAD~2..HEAD")
        self.assertNotIn('test_file_commit0', files)
        self.assertIn('test_file_commit1', files)
        self.assertIn('test_file_commit2', files)

    def test_changed_files_working_copy_only(self):
        self._one_local_commit_plus_working_copy_changes()
        files = self.scm.changed_files(git_commit="HEAD....")
        self.assertNotIn('test_file_commit1', files)
        self.assertIn('test_file_commit2', files)

    def test_changed_files_multiple_local_commits(self):
        self._two_local_commits()
        files = self.scm.changed_files()
        self.assertIn('test_file_commit2', files)
        self.assertIn('test_file_commit1', files)

    def test_changed_files_not_synced(self):
        self._run(['git', 'checkout', '-b', 'my-branch', 'trunk~3'])
        self._two_local_commits()
        files = self.scm.changed_files()
        self.assertNotIn('test_file2', files)
        self.assertIn('test_file_commit2', files)
        self.assertIn('test_file_commit1', files)

    def test_changed_files_upstream(self):
        self._run(['git', 'checkout', '-t', '-b', 'my-branch'])
        self._one_local_commit()
        self._run(['git', 'checkout', '-t', '-b', 'my-second-branch'])
        self._second_local_commit()
        self._write_text_file('test_file_commit0', 'more test content')
        self._run(['git', 'add', 'test_file_commit0'])

        # equivalent to 'git diff my-branch..HEAD, should not include working changes
        files = self.scm.changed_files(git_commit='UPSTREAM..')
        self.assertNotIn('test_file_commit1', files)
        self.assertIn('test_file_commit2', files)
        self.assertNotIn('test_file_commit0', files)

        # equivalent to 'git diff my-branch', *should* include working changes
        files = self.scm.changed_files(git_commit='UPSTREAM....')
        self.assertNotIn('test_file_commit1', files)
        self.assertIn('test_file_commit2', files)
        self.assertIn('test_file_commit0', files)

    def test_add_recursively(self):
        self._shared_test_add_recursively()

    def test_delete(self):
        self._two_local_commits()
        self.scm.delete('test_file_commit1')
        self.assertIn("test_file_commit1", self.scm._deleted_files())

    def test_delete_list(self):
        self._two_local_commits()
        self.scm.delete_list(["test_file_commit1", "test_file_commit2"])
        self.assertIn("test_file_commit1", self.scm._deleted_files())
        self.assertIn("test_file_commit2", self.scm._deleted_files())

    def test_delete_recursively(self):
        self._shared_test_delete_recursively()

    def test_delete_recursively_or_not(self):
        self._shared_test_delete_recursively_or_not()

    def test_move(self):
        self._shared_test_move()

    def test_move_recursive(self):
        self._shared_test_move_recursive()

    def test_exists(self):
        self._shared_test_exists(self.scm, self.scm.commit_locally_with_message)


class GitTestWithMock(SCMTestBase):
    def make_scm(self):
        scm = Git(cwd=".", executive=MockExecutive(), filesystem=MockFileSystem())
        scm.read_git_config = lambda *args, **kw: "MOCKKEY:MOCKVALUE"
        return scm

    def test_timestamp_of_revision(self):
        scm = self.make_scm()
        scm.find_checkout_root = lambda path: ''
        scm._run_git = lambda args: 'Date: 2013-02-08 08:05:49 +0000'
        self.assertEqual(scm.timestamp_of_revision('some-path', '12345'), '2013-02-08T08:05:49Z')

        scm._run_git = lambda args: 'Date: 2013-02-08 01:02:03 +0130'
        self.assertEqual(scm.timestamp_of_revision('some-path', '12345'), '2013-02-07T23:32:03Z')

        scm._run_git = lambda args: 'Date: 2013-02-08 01:55:21 -0800'
        self.assertEqual(scm.timestamp_of_revision('some-path', '12345'), '2013-02-08T09:55:21Z')
