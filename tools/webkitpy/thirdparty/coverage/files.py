"""File wrangling."""

from coverage.backward import to_string
from coverage.misc import CoverageException
import fnmatch, os, re, sys

class FileLocator(object):
    """Understand how filenames work."""

    def __init__(self):
        # The absolute path to our current directory.
        self.relative_dir = self.abs_file(os.curdir) + os.sep

        # Cache of results of calling the canonical_filename() method, to
        # avoid duplicating work.
        self.canonical_filename_cache = {}

    def abs_file(self, filename):
        """Return the absolute normalized form of `filename`."""
        return os.path.normcase(os.path.abspath(os.path.realpath(filename)))

    def relative_filename(self, filename):
        """Return the relative form of `filename`.

        The filename will be relative to the current directory when the
        `FileLocator` was constructed.

        """
        if filename.startswith(self.relative_dir):
            filename = filename.replace(self.relative_dir, "")
        return filename

    def canonical_filename(self, filename):
        """Return a canonical filename for `filename`.

        An absolute path with no redundant components and normalized case.

        """
        if filename not in self.canonical_filename_cache:
            f = filename
            if os.path.isabs(f) and not os.path.exists(f):
                if self.get_zip_data(f) is None:
                    f = os.path.basename(f)
            if not os.path.isabs(f):
                for path in [os.curdir] + sys.path:
                    if path is None:
                        continue
                    g = os.path.join(path, f)
                    if os.path.exists(g):
                        f = g
                        break
            cf = self.abs_file(f)
            self.canonical_filename_cache[filename] = cf
        return self.canonical_filename_cache[filename]

    def get_zip_data(self, filename):
        """Get data from `filename` if it is a zip file path.

        Returns the string data read from the zip file, or None if no zip file
        could be found or `filename` isn't in it.  The data returned will be
        an empty string if the file is empty.

        """
        import zipimport
        markers = ['.zip'+os.sep, '.egg'+os.sep]
        for marker in markers:
            if marker in filename:
                parts = filename.split(marker)
                try:
                    zi = zipimport.zipimporter(parts[0]+marker[:-1])
                except zipimport.ZipImportError:
                    continue
                try:
                    data = zi.get_data(parts[1])
                except IOError:
                    continue
                return to_string(data)
        return None


class TreeMatcher(object):
    """A matcher for files in a tree."""
    def __init__(self, directories):
        self.dirs = directories[:]

    def __repr__(self):
        return "<TreeMatcher %r>" % self.dirs

    def add(self, directory):
        """Add another directory to the list we match for."""
        self.dirs.append(directory)

    def match(self, fpath):
        """Does `fpath` indicate a file in one of our trees?"""
        for d in self.dirs:
            if fpath.startswith(d):
                if fpath == d:
                    # This is the same file!
                    return True
                if fpath[len(d)] == os.sep:
                    # This is a file in the directory
                    return True
        return False


class FnmatchMatcher(object):
    """A matcher for files by filename pattern."""
    def __init__(self, pats):
        self.pats = pats[:]

    def __repr__(self):
        return "<FnmatchMatcher %r>" % self.pats

    def match(self, fpath):
        """Does `fpath` match one of our filename patterns?"""
        for pat in self.pats:
            if fnmatch.fnmatch(fpath, pat):
                return True
        return False


def sep(s):
    """Find the path separator used in this string, or os.sep if none."""
    sep_match = re.search(r"[\\/]", s)
    if sep_match:
        the_sep = sep_match.group(0)
    else:
        the_sep = os.sep
    return the_sep


class PathAliases(object):
    """A collection of aliases for paths.

    When combining data files from remote machines, often the paths to source
    code are different, for example, due to OS differences, or because of
    serialized checkouts on continuous integration machines.

    A `PathAliases` object tracks a list of pattern/result pairs, and can
    map a path through those aliases to produce a unified path.

    `locator` is a FileLocator that is used to canonicalize the results.

    """
    def __init__(self, locator=None):
        self.aliases = []
        self.locator = locator

    def add(self, pattern, result):
        """Add the `pattern`/`result` pair to the list of aliases.

        `pattern` is an `fnmatch`-style pattern.  `result` is a simple
        string.  When mapping paths, if a path starts with a match against
        `pattern`, then that match is replaced with `result`.  This models
        isomorphic source trees being rooted at different places on two
        different machines.

        `pattern` can't end with a wildcard component, since that would
        match an entire tree, and not just its root.

        """
        # The pattern can't end with a wildcard component.
        pattern = pattern.rstrip(r"\/")
        if pattern.endswith("*"):
            raise CoverageException("Pattern must not end with wildcards.")
        pattern_sep = sep(pattern)
        pattern += pattern_sep

        # Make a regex from the pattern.  fnmatch always adds a \Z or $ to
        # match the whole string, which we don't want.
        regex_pat = fnmatch.translate(pattern).replace(r'\Z(', '(')
        if regex_pat.endswith("$"):
            regex_pat = regex_pat[:-1]
        # We want */a/b.py to match on Windows to, so change slash to match
        # either separator.
        regex_pat = regex_pat.replace(r"\/", r"[\\/]")
        # We want case-insensitive matching, so add that flag.
        regex = re.compile("(?i)" + regex_pat)

        # Normalize the result: it must end with a path separator.
        result_sep = sep(result)
        result = result.rstrip(r"\/") + result_sep
        self.aliases.append((regex, result, pattern_sep, result_sep))

    def map(self, path):
        """Map `path` through the aliases.

        `path` is checked against all of the patterns.  The first pattern to
        match is used to replace the root of the path with the result root.
        Only one pattern is ever used.  If no patterns match, `path` is
        returned unchanged.

        The separator style in the result is made to match that of the result
        in the alias.

        """
        for regex, result, pattern_sep, result_sep in self.aliases:
            m = regex.match(path)
            if m:
                new = path.replace(m.group(0), result)
                if pattern_sep != result_sep:
                    new = new.replace(pattern_sep, result_sep)
                if self.locator:
                    new = self.locator.canonical_filename(new)
                return new
        return path


def find_python_files(dirname):
    """Yield all of the importable Python files in `dirname`, recursively."""
    for dirpath, dirnames, filenames in os.walk(dirname, topdown=True):
        if '__init__.py' not in filenames:
            # If a directory doesn't have __init__.py, then it isn't
            # importable and neither are its files
            del dirnames[:]
            continue
        for filename in filenames:
            if fnmatch.fnmatch(filename, "*.py"):
                yield os.path.join(dirpath, filename)
