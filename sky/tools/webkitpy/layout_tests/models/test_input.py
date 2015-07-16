# Copyright (C) 2010 Google Inc. All rights reserved.
# Copyright (C) 2010 Gabor Rapcsanyi (rgabor@inf.u-szeged.hu), University of Szeged
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


class TestInput(object):
    """Groups information about a test for easy passing of data."""

    def __init__(self, test_name, timeout=None, requires_lock=None, reference_files=None, should_run_pixel_tests=None, should_add_missing_baselines=True):
        # TestInput objects are normally constructed by the manager and passed
        # to the workers, but these some fields are set lazily in the workers where possible
        # because they require us to look at the filesystem and we want to be able to do that in parallel.
        self.test_name = test_name
        self.timeout = timeout  # in msecs; should rename this for consistency
        self.requires_lock = requires_lock
        self.reference_files = reference_files
        self.should_run_pixel_tests = should_run_pixel_tests
        self.should_add_missing_baselines = should_add_missing_baselines

    def __repr__(self):
        return "TestInput('%s', timeout=%s, requires_lock=%s, reference_files=%s, should_run_pixel_tests=%s, should_add_missing_baselines%s)" % (self.test_name, self.timeout, self.requires_lock, self.reference_files, self.should_run_pixel_tests, self.should_add_missing_baselines)
