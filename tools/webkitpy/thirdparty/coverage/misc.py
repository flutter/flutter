"""Miscellaneous stuff for Coverage."""

import inspect
from coverage.backward import md5, sorted       # pylint: disable=W0622
from coverage.backward import string_class, to_bytes


def nice_pair(pair):
    """Make a nice string representation of a pair of numbers.

    If the numbers are equal, just return the number, otherwise return the pair
    with a dash between them, indicating the range.

    """
    start, end = pair
    if start == end:
        return "%d" % start
    else:
        return "%d-%d" % (start, end)


def format_lines(statements, lines):
    """Nicely format a list of line numbers.

    Format a list of line numbers for printing by coalescing groups of lines as
    long as the lines represent consecutive statements.  This will coalesce
    even if there are gaps between statements.

    For example, if `statements` is [1,2,3,4,5,10,11,12,13,14] and
    `lines` is [1,2,5,10,11,13,14] then the result will be "1-2, 5-11, 13-14".

    """
    pairs = []
    i = 0
    j = 0
    start = None
    while i < len(statements) and j < len(lines):
        if statements[i] == lines[j]:
            if start == None:
                start = lines[j]
            end = lines[j]
            j += 1
        elif start:
            pairs.append((start, end))
            start = None
        i += 1
    if start:
        pairs.append((start, end))
    ret = ', '.join(map(nice_pair, pairs))
    return ret


def expensive(fn):
    """A decorator to cache the result of an expensive operation.

    Only applies to methods with no arguments.

    """
    attr = "_cache_" + fn.__name__
    def _wrapped(self):
        """Inner fn that checks the cache."""
        if not hasattr(self, attr):
            setattr(self, attr, fn(self))
        return getattr(self, attr)
    return _wrapped


def bool_or_none(b):
    """Return bool(b), but preserve None."""
    if b is None:
        return None
    else:
        return bool(b)


def join_regex(regexes):
    """Combine a list of regexes into one that matches any of them."""
    if len(regexes) > 1:
        return "(" + ")|(".join(regexes) + ")"
    elif regexes:
        return regexes[0]
    else:
        return ""


class Hasher(object):
    """Hashes Python data into md5."""
    def __init__(self):
        self.md5 = md5()

    def update(self, v):
        """Add `v` to the hash, recursively if needed."""
        self.md5.update(to_bytes(str(type(v))))
        if isinstance(v, string_class):
            self.md5.update(to_bytes(v))
        elif isinstance(v, (int, float)):
            self.update(str(v))
        elif isinstance(v, (tuple, list)):
            for e in v:
                self.update(e)
        elif isinstance(v, dict):
            keys = v.keys()
            for k in sorted(keys):
                self.update(k)
                self.update(v[k])
        else:
            for k in dir(v):
                if k.startswith('__'):
                    continue
                a = getattr(v, k)
                if inspect.isroutine(a):
                    continue
                self.update(k)
                self.update(a)

    def digest(self):
        """Retrieve the digest of the hash."""
        return self.md5.digest()


class CoverageException(Exception):
    """An exception specific to Coverage."""
    pass

class NoSource(CoverageException):
    """We couldn't find the source for a module."""
    pass

class NotPython(CoverageException):
    """A source file turned out not to be parsable Python."""
    pass

class ExceptionDuringRun(CoverageException):
    """An exception happened while running customer code.

    Construct it with three arguments, the values from `sys.exc_info`.

    """
    pass
