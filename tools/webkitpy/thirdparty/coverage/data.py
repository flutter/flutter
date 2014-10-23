"""Coverage data for Coverage."""

import os

from coverage.backward import pickle, sorted        # pylint: disable=W0622
from coverage.files import PathAliases


class CoverageData(object):
    """Manages collected coverage data, including file storage.

    The data file format is a pickled dict, with these keys:

        * collector: a string identifying the collecting software

        * lines: a dict mapping filenames to sorted lists of line numbers
          executed:
            { 'file1': [17,23,45],  'file2': [1,2,3], ... }

        * arcs: a dict mapping filenames to sorted lists of line number pairs:
            { 'file1': [(17,23), (17,25), (25,26)], ... }

    """

    def __init__(self, basename=None, collector=None):
        """Create a CoverageData.

        `basename` is the name of the file to use for storing data.

        `collector` is a string describing the coverage measurement software.

        """
        self.collector = collector or 'unknown'

        self.use_file = True

        # Construct the filename that will be used for data file storage, if we
        # ever do any file storage.
        self.filename = basename or ".coverage"
        self.filename = os.path.abspath(self.filename)

        # A map from canonical Python source file name to a dictionary in
        # which there's an entry for each line number that has been
        # executed:
        #
        #   {
        #       'filename1.py': { 12: None, 47: None, ... },
        #       ...
        #       }
        #
        self.lines = {}

        # A map from canonical Python source file name to a dictionary with an
        # entry for each pair of line numbers forming an arc:
        #
        #   {
        #       'filename1.py': { (12,14): None, (47,48): None, ... },
        #       ...
        #       }
        #
        self.arcs = {}

        self.os = os
        self.sorted = sorted
        self.pickle = pickle

    def usefile(self, use_file=True):
        """Set whether or not to use a disk file for data."""
        self.use_file = use_file

    def read(self):
        """Read coverage data from the coverage data file (if it exists)."""
        if self.use_file:
            self.lines, self.arcs = self._read_file(self.filename)
        else:
            self.lines, self.arcs = {}, {}

    def write(self, suffix=None):
        """Write the collected coverage data to a file.

        `suffix` is a suffix to append to the base file name. This can be used
        for multiple or parallel execution, so that many coverage data files
        can exist simultaneously.  A dot will be used to join the base name and
        the suffix.

        """
        if self.use_file:
            filename = self.filename
            if suffix:
                filename += "." + suffix
            self.write_file(filename)

    def erase(self):
        """Erase the data, both in this object, and from its file storage."""
        if self.use_file:
            if self.filename and os.path.exists(self.filename):
                os.remove(self.filename)
        self.lines = {}
        self.arcs = {}

    def line_data(self):
        """Return the map from filenames to lists of line numbers executed."""
        return dict(
            [(f, self.sorted(lmap.keys())) for f, lmap in self.lines.items()]
            )

    def arc_data(self):
        """Return the map from filenames to lists of line number pairs."""
        return dict(
            [(f, self.sorted(amap.keys())) for f, amap in self.arcs.items()]
            )

    def write_file(self, filename):
        """Write the coverage data to `filename`."""

        # Create the file data.
        data = {}

        data['lines'] = self.line_data()
        arcs = self.arc_data()
        if arcs:
            data['arcs'] = arcs

        if self.collector:
            data['collector'] = self.collector

        # Write the pickle to the file.
        fdata = open(filename, 'wb')
        try:
            self.pickle.dump(data, fdata, 2)
        finally:
            fdata.close()

    def read_file(self, filename):
        """Read the coverage data from `filename`."""
        self.lines, self.arcs = self._read_file(filename)

    def raw_data(self, filename):
        """Return the raw pickled data from `filename`."""
        fdata = open(filename, 'rb')
        try:
            data = pickle.load(fdata)
        finally:
            fdata.close()
        return data

    def _read_file(self, filename):
        """Return the stored coverage data from the given file.

        Returns two values, suitable for assigning to `self.lines` and
        `self.arcs`.

        """
        lines = {}
        arcs = {}
        try:
            data = self.raw_data(filename)
            if isinstance(data, dict):
                # Unpack the 'lines' item.
                lines = dict([
                    (f, dict.fromkeys(linenos, None))
                        for f, linenos in data.get('lines', {}).items()
                    ])
                # Unpack the 'arcs' item.
                arcs = dict([
                    (f, dict.fromkeys(arcpairs, None))
                        for f, arcpairs in data.get('arcs', {}).items()
                    ])
        except Exception:
            pass
        return lines, arcs

    def combine_parallel_data(self, aliases=None):
        """Combine a number of data files together.

        Treat `self.filename` as a file prefix, and combine the data from all
        of the data files starting with that prefix plus a dot.

        If `aliases` is provided, it's a `PathAliases` object that is used to
        re-map paths to match the local machine's.

        """
        aliases = aliases or PathAliases()
        data_dir, local = os.path.split(self.filename)
        localdot = local + '.'
        for f in os.listdir(data_dir or '.'):
            if f.startswith(localdot):
                full_path = os.path.join(data_dir, f)
                new_lines, new_arcs = self._read_file(full_path)
                for filename, file_data in new_lines.items():
                    filename = aliases.map(filename)
                    self.lines.setdefault(filename, {}).update(file_data)
                for filename, file_data in new_arcs.items():
                    filename = aliases.map(filename)
                    self.arcs.setdefault(filename, {}).update(file_data)
                if f != local:
                    os.remove(full_path)

    def add_line_data(self, line_data):
        """Add executed line data.

        `line_data` is { filename: { lineno: None, ... }, ...}

        """
        for filename, linenos in line_data.items():
            self.lines.setdefault(filename, {}).update(linenos)

    def add_arc_data(self, arc_data):
        """Add measured arc data.

        `arc_data` is { filename: { (l1,l2): None, ... }, ...}

        """
        for filename, arcs in arc_data.items():
            self.arcs.setdefault(filename, {}).update(arcs)

    def touch_file(self, filename):
        """Ensure that `filename` appears in the data, empty if needed."""
        self.lines.setdefault(filename, {})

    def measured_files(self):
        """A list of all files that had been measured."""
        return list(self.lines.keys())

    def executed_lines(self, filename):
        """A map containing all the line numbers executed in `filename`.

        If `filename` hasn't been collected at all (because it wasn't executed)
        then return an empty map.

        """
        return self.lines.get(filename) or {}

    def executed_arcs(self, filename):
        """A map containing all the arcs executed in `filename`."""
        return self.arcs.get(filename) or {}

    def add_to_hash(self, filename, hasher):
        """Contribute `filename`'s data to the Md5Hash `hasher`."""
        hasher.update(self.executed_lines(filename))
        hasher.update(self.executed_arcs(filename))

    def summary(self, fullpath=False):
        """Return a dict summarizing the coverage data.

        Keys are based on the filenames, and values are the number of executed
        lines.  If `fullpath` is true, then the keys are the full pathnames of
        the files, otherwise they are the basenames of the files.

        """
        summ = {}
        if fullpath:
            filename_fn = lambda f: f
        else:
            filename_fn = self.os.path.basename
        for filename, lines in self.lines.items():
            summ[filename_fn(filename)] = len(lines)
        return summ

    def has_arcs(self):
        """Does this data have arcs?"""
        return bool(self.arcs)


if __name__ == '__main__':
    # Ad-hoc: show the raw data in a data file.
    import pprint, sys
    covdata = CoverageData()
    if sys.argv[1:]:
        fname = sys.argv[1]
    else:
        fname = covdata.filename
    pprint.pprint(covdata.raw_data(fname))
