"""Results of coverage measurement."""

import os

from coverage.backward import set, sorted           # pylint: disable=W0622
from coverage.misc import format_lines, join_regex, NoSource
from coverage.parser import CodeParser


class Analysis(object):
    """The results of analyzing a code unit."""

    def __init__(self, cov, code_unit):
        self.coverage = cov
        self.code_unit = code_unit

        self.filename = self.code_unit.filename
        ext = os.path.splitext(self.filename)[1]
        source = None
        if ext == '.py':
            if not os.path.exists(self.filename):
                source = self.coverage.file_locator.get_zip_data(self.filename)
                if not source:
                    raise NoSource("No source for code: %r" % self.filename)

        self.parser = CodeParser(
            text=source, filename=self.filename,
            exclude=self.coverage._exclude_regex('exclude')
            )
        self.statements, self.excluded = self.parser.parse_source()

        # Identify missing statements.
        executed = self.coverage.data.executed_lines(self.filename)
        exec1 = self.parser.first_lines(executed)
        self.missing = sorted(set(self.statements) - set(exec1))

        if self.coverage.data.has_arcs():
            self.no_branch = self.parser.lines_matching(
                join_regex(self.coverage.config.partial_list),
                join_regex(self.coverage.config.partial_always_list)
                )
            n_branches = self.total_branches()
            mba = self.missing_branch_arcs()
            n_missing_branches = sum(
                [len(v) for k,v in mba.items() if k not in self.missing]
                )
        else:
            n_branches = n_missing_branches = 0
            self.no_branch = set()

        self.numbers = Numbers(
            n_files=1,
            n_statements=len(self.statements),
            n_excluded=len(self.excluded),
            n_missing=len(self.missing),
            n_branches=n_branches,
            n_missing_branches=n_missing_branches,
            )

    def missing_formatted(self):
        """The missing line numbers, formatted nicely.

        Returns a string like "1-2, 5-11, 13-14".

        """
        return format_lines(self.statements, self.missing)

    def has_arcs(self):
        """Were arcs measured in this result?"""
        return self.coverage.data.has_arcs()

    def arc_possibilities(self):
        """Returns a sorted list of the arcs in the code."""
        arcs = self.parser.arcs()
        return arcs

    def arcs_executed(self):
        """Returns a sorted list of the arcs actually executed in the code."""
        executed = self.coverage.data.executed_arcs(self.filename)
        m2fl = self.parser.first_line
        executed = [(m2fl(l1), m2fl(l2)) for (l1,l2) in executed]
        return sorted(executed)

    def arcs_missing(self):
        """Returns a sorted list of the arcs in the code not executed."""
        possible = self.arc_possibilities()
        executed = self.arcs_executed()
        missing = [
            p for p in possible
                if p not in executed
                    and p[0] not in self.no_branch
            ]
        return sorted(missing)

    def arcs_unpredicted(self):
        """Returns a sorted list of the executed arcs missing from the code."""
        possible = self.arc_possibilities()
        executed = self.arcs_executed()
        # Exclude arcs here which connect a line to itself.  They can occur
        # in executed data in some cases.  This is where they can cause
        # trouble, and here is where it's the least burden to remove them.
        unpredicted = [
            e for e in executed
                if e not in possible
                    and e[0] != e[1]
            ]
        return sorted(unpredicted)

    def branch_lines(self):
        """Returns a list of line numbers that have more than one exit."""
        exit_counts = self.parser.exit_counts()
        return [l1 for l1,count in exit_counts.items() if count > 1]

    def total_branches(self):
        """How many total branches are there?"""
        exit_counts = self.parser.exit_counts()
        return sum([count for count in exit_counts.values() if count > 1])

    def missing_branch_arcs(self):
        """Return arcs that weren't executed from branch lines.

        Returns {l1:[l2a,l2b,...], ...}

        """
        missing = self.arcs_missing()
        branch_lines = set(self.branch_lines())
        mba = {}
        for l1, l2 in missing:
            if l1 in branch_lines:
                if l1 not in mba:
                    mba[l1] = []
                mba[l1].append(l2)
        return mba

    def branch_stats(self):
        """Get stats about branches.

        Returns a dict mapping line numbers to a tuple:
        (total_exits, taken_exits).
        """

        exit_counts = self.parser.exit_counts()
        missing_arcs = self.missing_branch_arcs()
        stats = {}
        for lnum in self.branch_lines():
            exits = exit_counts[lnum]
            try:
                missing = len(missing_arcs[lnum])
            except KeyError:
                missing = 0
            stats[lnum] = (exits, exits - missing)
        return stats


class Numbers(object):
    """The numerical results of measuring coverage.

    This holds the basic statistics from `Analysis`, and is used to roll
    up statistics across files.

    """
    # A global to determine the precision on coverage percentages, the number
    # of decimal places.
    _precision = 0
    _near0 = 1.0              # These will change when _precision is changed.
    _near100 = 99.0

    def __init__(self, n_files=0, n_statements=0, n_excluded=0, n_missing=0,
                    n_branches=0, n_missing_branches=0
                    ):
        self.n_files = n_files
        self.n_statements = n_statements
        self.n_excluded = n_excluded
        self.n_missing = n_missing
        self.n_branches = n_branches
        self.n_missing_branches = n_missing_branches

    def set_precision(cls, precision):
        """Set the number of decimal places used to report percentages."""
        assert 0 <= precision < 10
        cls._precision = precision
        cls._near0 = 1.0 / 10**precision
        cls._near100 = 100.0 - cls._near0
    set_precision = classmethod(set_precision)

    def _get_n_executed(self):
        """Returns the number of executed statements."""
        return self.n_statements - self.n_missing
    n_executed = property(_get_n_executed)

    def _get_n_executed_branches(self):
        """Returns the number of executed branches."""
        return self.n_branches - self.n_missing_branches
    n_executed_branches = property(_get_n_executed_branches)

    def _get_pc_covered(self):
        """Returns a single percentage value for coverage."""
        if self.n_statements > 0:
            pc_cov = (100.0 * (self.n_executed + self.n_executed_branches) /
                        (self.n_statements + self.n_branches))
        else:
            pc_cov = 100.0
        return pc_cov
    pc_covered = property(_get_pc_covered)

    def _get_pc_covered_str(self):
        """Returns the percent covered, as a string, without a percent sign.

        Note that "0" is only returned when the value is truly zero, and "100"
        is only returned when the value is truly 100.  Rounding can never
        result in either "0" or "100".

        """
        pc = self.pc_covered
        if 0 < pc < self._near0:
            pc = self._near0
        elif self._near100 < pc < 100:
            pc = self._near100
        else:
            pc = round(pc, self._precision)
        return "%.*f" % (self._precision, pc)
    pc_covered_str = property(_get_pc_covered_str)

    def pc_str_width(cls):
        """How many characters wide can pc_covered_str be?"""
        width = 3   # "100"
        if cls._precision > 0:
            width += 1 + cls._precision
        return width
    pc_str_width = classmethod(pc_str_width)

    def __add__(self, other):
        nums = Numbers()
        nums.n_files = self.n_files + other.n_files
        nums.n_statements = self.n_statements + other.n_statements
        nums.n_excluded = self.n_excluded + other.n_excluded
        nums.n_missing = self.n_missing + other.n_missing
        nums.n_branches = self.n_branches + other.n_branches
        nums.n_missing_branches = (self.n_missing_branches +
                                                    other.n_missing_branches)
        return nums

    def __radd__(self, other):
        # Implementing 0+Numbers allows us to sum() a list of Numbers.
        if other == 0:
            return self
        return NotImplemented
