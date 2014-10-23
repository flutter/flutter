"""Code unit (module) handling for Coverage."""

import glob, os

from coverage.backward import open_source, string_class, StringIO
from coverage.misc import CoverageException


def code_unit_factory(morfs, file_locator):
    """Construct a list of CodeUnits from polymorphic inputs.

    `morfs` is a module or a filename, or a list of same.

    `file_locator` is a FileLocator that can help resolve filenames.

    Returns a list of CodeUnit objects.

    """
    # Be sure we have a list.
    if not isinstance(morfs, (list, tuple)):
        morfs = [morfs]

    # On Windows, the shell doesn't expand wildcards.  Do it here.
    globbed = []
    for morf in morfs:
        if isinstance(morf, string_class) and ('?' in morf or '*' in morf):
            globbed.extend(glob.glob(morf))
        else:
            globbed.append(morf)
    morfs = globbed

    code_units = [CodeUnit(morf, file_locator) for morf in morfs]

    return code_units


class CodeUnit(object):
    """Code unit: a filename or module.

    Instance attributes:

    `name` is a human-readable name for this code unit.
    `filename` is the os path from which we can read the source.
    `relative` is a boolean.

    """
    def __init__(self, morf, file_locator):
        self.file_locator = file_locator

        if hasattr(morf, '__file__'):
            f = morf.__file__
        else:
            f = morf
        # .pyc files should always refer to a .py instead.
        if f.endswith('.pyc'):
            f = f[:-1]
        self.filename = self.file_locator.canonical_filename(f)

        if hasattr(morf, '__name__'):
            n = modname = morf.__name__
            self.relative = True
        else:
            n = os.path.splitext(morf)[0]
            rel = self.file_locator.relative_filename(n)
            if os.path.isabs(n):
                self.relative = (rel != n)
            else:
                self.relative = True
            n = rel
            modname = None
        self.name = n
        self.modname = modname

    def __repr__(self):
        return "<CodeUnit name=%r filename=%r>" % (self.name, self.filename)

    # Annoying comparison operators. Py3k wants __lt__ etc, and Py2k needs all
    # of them defined.

    def __lt__(self, other): return self.name <  other.name
    def __le__(self, other): return self.name <= other.name
    def __eq__(self, other): return self.name == other.name
    def __ne__(self, other): return self.name != other.name
    def __gt__(self, other): return self.name >  other.name
    def __ge__(self, other): return self.name >= other.name

    def flat_rootname(self):
        """A base for a flat filename to correspond to this code unit.

        Useful for writing files about the code where you want all the files in
        the same directory, but need to differentiate same-named files from
        different directories.

        For example, the file a/b/c.py might return 'a_b_c'

        """
        if self.modname:
            return self.modname.replace('.', '_')
        else:
            root = os.path.splitdrive(self.name)[1]
            return root.replace('\\', '_').replace('/', '_').replace('.', '_')

    def source_file(self):
        """Return an open file for reading the source of the code unit."""
        if os.path.exists(self.filename):
            # A regular text file: open it.
            return open_source(self.filename)

        # Maybe it's in a zip file?
        source = self.file_locator.get_zip_data(self.filename)
        if source is not None:
            return StringIO(source)

        # Couldn't find source.
        raise CoverageException(
            "No source for code %r." % self.filename
            )
