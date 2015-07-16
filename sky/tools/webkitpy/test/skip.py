# Copyright (C) 2010 Apple Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1.  Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
# 2.  Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import logging

_log = logging.getLogger(__name__)


def skip_if(klass, condition, message=None, logger=None):
    """Makes all test_* methods in a given class no-ops if the given condition
    is False. Backported from Python 3.1+'s unittest.skipIf decorator."""
    if not logger:
        logger = _log
    if not condition:
        return klass
    for name in dir(klass):
        attr = getattr(klass, name)
        if not callable(attr):
            continue
        if not name.startswith('test_'):
            continue
        setattr(klass, name, _skipped_method(attr, message, logger))
    klass._printed_skipped_message = False
    return klass


def _skipped_method(method, message, logger):
    def _skip(*args):
        if method.im_class._printed_skipped_message:
            return
        method.im_class._printed_skipped_message = True
        logger.info('Skipping %s.%s: %s' % (method.__module__, method.im_class.__name__, message))
    return _skip
