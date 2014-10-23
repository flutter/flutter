"""Source file annotation for Coverage."""

import os, re

from coverage.report import Reporter

class AnnotateReporter(Reporter):
    """Generate annotated source files showing line coverage.

    This reporter creates annotated copies of the measured source files. Each
    .py file is copied as a .py,cover file, with a left-hand margin annotating
    each line::

        > def h(x):
        -     if 0:   #pragma: no cover
        -         pass
        >     if x == 1:
        !         a = 1
        >     else:
        >         a = 2

        > h(2)

    Executed lines use '>', lines not executed use '!', lines excluded from
    consideration use '-'.

    """

    def __init__(self, coverage, ignore_errors=False):
        super(AnnotateReporter, self).__init__(coverage, ignore_errors)
        self.directory = None

    blank_re = re.compile(r"\s*(#|$)")
    else_re = re.compile(r"\s*else\s*:\s*(#|$)")

    def report(self, morfs, config, directory=None):
        """Run the report.

        See `coverage.report()` for arguments.

        """
        self.report_files(self.annotate_file, morfs, config, directory)

    def annotate_file(self, cu, analysis):
        """Annotate a single file.

        `cu` is the CodeUnit for the file to annotate.

        """
        if not cu.relative:
            return

        filename = cu.filename
        source = cu.source_file()
        if self.directory:
            dest_file = os.path.join(self.directory, cu.flat_rootname())
            dest_file += ".py,cover"
        else:
            dest_file = filename + ",cover"
        dest = open(dest_file, 'w')

        statements = analysis.statements
        missing = analysis.missing
        excluded = analysis.excluded

        lineno = 0
        i = 0
        j = 0
        covered = True
        while True:
            line = source.readline()
            if line == '':
                break
            lineno += 1
            while i < len(statements) and statements[i] < lineno:
                i += 1
            while j < len(missing) and missing[j] < lineno:
                j += 1
            if i < len(statements) and statements[i] == lineno:
                covered = j >= len(missing) or missing[j] > lineno
            if self.blank_re.match(line):
                dest.write('  ')
            elif self.else_re.match(line):
                # Special logic for lines containing only 'else:'.
                if i >= len(statements) and j >= len(missing):
                    dest.write('! ')
                elif i >= len(statements) or j >= len(missing):
                    dest.write('> ')
                elif statements[i] == missing[j]:
                    dest.write('! ')
                else:
                    dest.write('> ')
            elif lineno in excluded:
                dest.write('- ')
            elif covered:
                dest.write('> ')
            else:
                dest.write('! ')
            dest.write(line)
        source.close()
        dest.close()
