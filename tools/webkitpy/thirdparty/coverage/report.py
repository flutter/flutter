"""Reporter foundation for Coverage."""

import fnmatch, os
from coverage.codeunit import code_unit_factory
from coverage.misc import CoverageException, NoSource, NotPython

class Reporter(object):
    """A base class for all reporters."""

    def __init__(self, coverage, ignore_errors=False):
        """Create a reporter.

        `coverage` is the coverage instance. `ignore_errors` controls how
        skittish the reporter will be during file processing.

        """
        self.coverage = coverage
        self.ignore_errors = ignore_errors

        # The code units to report on.  Set by find_code_units.
        self.code_units = []

        # The directory into which to place the report, used by some derived
        # classes.
        self.directory = None

    def find_code_units(self, morfs, config):
        """Find the code units we'll report on.

        `morfs` is a list of modules or filenames. `config` is a
        CoverageConfig instance.

        """
        morfs = morfs or self.coverage.data.measured_files()
        file_locator = self.coverage.file_locator
        self.code_units = code_unit_factory(morfs, file_locator)

        if config.include:
            patterns = [file_locator.abs_file(p) for p in config.include]
            filtered = []
            for cu in self.code_units:
                for pattern in patterns:
                    if fnmatch.fnmatch(cu.filename, pattern):
                        filtered.append(cu)
                        break
            self.code_units = filtered

        if config.omit:
            patterns = [file_locator.abs_file(p) for p in config.omit]
            filtered = []
            for cu in self.code_units:
                for pattern in patterns:
                    if fnmatch.fnmatch(cu.filename, pattern):
                        break
                else:
                    filtered.append(cu)
            self.code_units = filtered

        self.code_units.sort()

    def report_files(self, report_fn, morfs, config, directory=None):
        """Run a reporting function on a number of morfs.

        `report_fn` is called for each relative morf in `morfs`.  It is called
        as::

            report_fn(code_unit, analysis)

        where `code_unit` is the `CodeUnit` for the morf, and `analysis` is
        the `Analysis` for the morf.

        `config` is a CoverageConfig instance.

        """
        self.find_code_units(morfs, config)

        if not self.code_units:
            raise CoverageException("No data to report.")

        self.directory = directory
        if self.directory and not os.path.exists(self.directory):
            os.makedirs(self.directory)

        for cu in self.code_units:
            try:
                report_fn(cu, self.coverage._analyze(cu))
            except (NoSource, NotPython):
                if not self.ignore_errors:
                    raise
