"""Core control stuff for Coverage."""

import atexit, os, random, socket, sys

from coverage.annotate import AnnotateReporter
from coverage.backward import string_class
from coverage.codeunit import code_unit_factory, CodeUnit
from coverage.collector import Collector
from coverage.config import CoverageConfig
from coverage.data import CoverageData
from coverage.files import FileLocator, TreeMatcher, FnmatchMatcher
from coverage.files import PathAliases, find_python_files
from coverage.html import HtmlReporter
from coverage.misc import CoverageException, bool_or_none, join_regex
from coverage.results import Analysis, Numbers
from coverage.summary import SummaryReporter
from coverage.xmlreport import XmlReporter

class coverage(object):
    """Programmatic access to Coverage.

    To use::

        from coverage import coverage

        cov = coverage()
        cov.start()
        #.. blah blah (run your code) blah blah ..
        cov.stop()
        cov.html_report(directory='covhtml')

    """
    def __init__(self, data_file=None, data_suffix=None, cover_pylib=None,
                auto_data=False, timid=None, branch=None, config_file=True,
                source=None, omit=None, include=None):
        """
        `data_file` is the base name of the data file to use, defaulting to
        ".coverage".  `data_suffix` is appended (with a dot) to `data_file` to
        create the final file name.  If `data_suffix` is simply True, then a
        suffix is created with the machine and process identity included.

        `cover_pylib` is a boolean determining whether Python code installed
        with the Python interpreter is measured.  This includes the Python
        standard library and any packages installed with the interpreter.

        If `auto_data` is true, then any existing data file will be read when
        coverage measurement starts, and data will be saved automatically when
        measurement stops.

        If `timid` is true, then a slower and simpler trace function will be
        used.  This is important for some environments where manipulation of
        tracing functions breaks the faster trace function.

        If `branch` is true, then branch coverage will be measured in addition
        to the usual statement coverage.

        `config_file` determines what config file to read.  If it is a string,
        it is the name of the config file to read.  If it is True, then a
        standard file is read (".coveragerc").  If it is False, then no file is
        read.

        `source` is a list of file paths or package names.  Only code located
        in the trees indicated by the file paths or package names will be
        measured.

        `include` and `omit` are lists of filename patterns. Files that match
        `include` will be measured, files that match `omit` will not.  Each
        will also accept a single string argument.

        """
        from coverage import __version__

        # A record of all the warnings that have been issued.
        self._warnings = []

        # Build our configuration from a number of sources:
        # 1: defaults:
        self.config = CoverageConfig()

        # 2: from the coveragerc file:
        if config_file:
            if config_file is True:
                config_file = ".coveragerc"
            try:
                self.config.from_file(config_file)
            except ValueError:
                _, err, _ = sys.exc_info()
                raise CoverageException(
                    "Couldn't read config file %s: %s" % (config_file, err)
                    )

        # 3: from environment variables:
        self.config.from_environment('COVERAGE_OPTIONS')
        env_data_file = os.environ.get('COVERAGE_FILE')
        if env_data_file:
            self.config.data_file = env_data_file

        # 4: from constructor arguments:
        if isinstance(omit, string_class):
            omit = [omit]
        if isinstance(include, string_class):
            include = [include]
        self.config.from_args(
            data_file=data_file, cover_pylib=cover_pylib, timid=timid,
            branch=branch, parallel=bool_or_none(data_suffix),
            source=source, omit=omit, include=include
            )

        self.auto_data = auto_data
        self.atexit_registered = False

        # _exclude_re is a dict mapping exclusion list names to compiled
        # regexes.
        self._exclude_re = {}
        self._exclude_regex_stale()

        self.file_locator = FileLocator()

        # The source argument can be directories or package names.
        self.source = []
        self.source_pkgs = []
        for src in self.config.source or []:
            if os.path.exists(src):
                self.source.append(self.file_locator.canonical_filename(src))
            else:
                self.source_pkgs.append(src)

        self.omit = self._prep_patterns(self.config.omit)
        self.include = self._prep_patterns(self.config.include)

        self.collector = Collector(
            self._should_trace, timid=self.config.timid,
            branch=self.config.branch, warn=self._warn
            )

        # Suffixes are a bit tricky.  We want to use the data suffix only when
        # collecting data, not when combining data.  So we save it as
        # `self.run_suffix` now, and promote it to `self.data_suffix` if we
        # find that we are collecting data later.
        if data_suffix or self.config.parallel:
            if not isinstance(data_suffix, string_class):
                # if data_suffix=True, use .machinename.pid.random
                data_suffix = True
        else:
            data_suffix = None
        self.data_suffix = None
        self.run_suffix = data_suffix

        # Create the data file.  We do this at construction time so that the
        # data file will be written into the directory where the process
        # started rather than wherever the process eventually chdir'd to.
        self.data = CoverageData(
            basename=self.config.data_file,
            collector="coverage v%s" % __version__
            )

        # The dirs for files considered "installed with the interpreter".
        self.pylib_dirs = []
        if not self.config.cover_pylib:
            # Look at where some standard modules are located. That's the
            # indication for "installed with the interpreter". In some
            # environments (virtualenv, for example), these modules may be
            # spread across a few locations. Look at all the candidate modules
            # we've imported, and take all the different ones.
            for m in (atexit, os, random, socket):
                if hasattr(m, "__file__"):
                    m_dir = self._canonical_dir(m.__file__)
                    if m_dir not in self.pylib_dirs:
                        self.pylib_dirs.append(m_dir)

        # To avoid tracing the coverage code itself, we skip anything located
        # where we are.
        self.cover_dir = self._canonical_dir(__file__)

        # The matchers for _should_trace, created when tracing starts.
        self.source_match = None
        self.pylib_match = self.cover_match = None
        self.include_match = self.omit_match = None

        # Only _harvest_data once per measurement cycle.
        self._harvested = False

        # Set the reporting precision.
        Numbers.set_precision(self.config.precision)

        # When tearing down the coverage object, modules can become None.
        # Saving the modules as object attributes avoids problems, but it is
        # quite ad-hoc which modules need to be saved and which references
        # need to use the object attributes.
        self.socket = socket
        self.os = os
        self.random = random

    def _canonical_dir(self, f):
        """Return the canonical directory of the file `f`."""
        return os.path.split(self.file_locator.canonical_filename(f))[0]

    def _source_for_file(self, filename):
        """Return the source file for `filename`."""
        if not filename.endswith(".py"):
            if filename[-4:-1] == ".py":
                filename = filename[:-1]
        return filename

    def _should_trace(self, filename, frame):
        """Decide whether to trace execution in `filename`

        This function is called from the trace function.  As each new file name
        is encountered, this function determines whether it is traced or not.

        Returns a canonicalized filename if it should be traced, False if it
        should not.

        """
        if os is None:
            return False

        if filename.startswith('<'):
            # Lots of non-file execution is represented with artificial
            # filenames like "<string>", "<doctest readme.txt[0]>", or
            # "<exec_function>".  Don't ever trace these executions, since we
            # can't do anything with the data later anyway.
            return False

        if filename.endswith(".html"):
            # Jinja and maybe other templating systems compile templates into
            # Python code, but use the template filename as the filename in
            # the compiled code.  Of course, those filenames are useless later
            # so don't bother collecting.  TODO: How should we really separate
            # out good file extensions from bad?
            return False

        self._check_for_packages()

        # Compiled Python files have two filenames: frame.f_code.co_filename is
        # the filename at the time the .pyc was compiled.  The second name is
        # __file__, which is where the .pyc was actually loaded from.  Since
        # .pyc files can be moved after compilation (for example, by being
        # installed), we look for __file__ in the frame and prefer it to the
        # co_filename value.
        dunder_file = frame.f_globals.get('__file__')
        if dunder_file:
            filename = self._source_for_file(dunder_file)

        # Jython reports the .class file to the tracer, use the source file.
        if filename.endswith("$py.class"):
            filename = filename[:-9] + ".py"

        canonical = self.file_locator.canonical_filename(filename)

        # If the user specified source or include, then that's authoritative
        # about the outer bound of what to measure and we don't have to apply
        # any canned exclusions. If they didn't, then we have to exclude the
        # stdlib and coverage.py directories.
        if self.source_match:
            if not self.source_match.match(canonical):
                return False
        elif self.include_match:
            if not self.include_match.match(canonical):
                return False
        else:
            # If we aren't supposed to trace installed code, then check if this
            # is near the Python standard library and skip it if so.
            if self.pylib_match and self.pylib_match.match(canonical):
                return False

            # We exclude the coverage code itself, since a little of it will be
            # measured otherwise.
            if self.cover_match and self.cover_match.match(canonical):
                return False

        # Check the file against the omit pattern.
        if self.omit_match and self.omit_match.match(canonical):
            return False

        return canonical

    # To log what should_trace returns, change this to "if 1:"
    if 0:
        _real_should_trace = _should_trace
        def _should_trace(self, filename, frame):   # pylint: disable=E0102
            """A logging decorator around the real _should_trace function."""
            ret = self._real_should_trace(filename, frame)
            print("should_trace: %r -> %r" % (filename, ret))
            return ret

    def _warn(self, msg):
        """Use `msg` as a warning."""
        self._warnings.append(msg)
        sys.stderr.write("Coverage.py warning: %s\n" % msg)

    def _prep_patterns(self, patterns):
        """Prepare the file patterns for use in a `FnmatchMatcher`.

        If a pattern starts with a wildcard, it is used as a pattern
        as-is.  If it does not start with a wildcard, then it is made
        absolute with the current directory.

        If `patterns` is None, an empty list is returned.

        """
        patterns = patterns or []
        prepped = []
        for p in patterns or []:
            if p.startswith("*") or p.startswith("?"):
                prepped.append(p)
            else:
                prepped.append(self.file_locator.abs_file(p))
        return prepped

    def _check_for_packages(self):
        """Update the source_match matcher with latest imported packages."""
        # Our self.source_pkgs attribute is a list of package names we want to
        # measure.  Each time through here, we see if we've imported any of
        # them yet.  If so, we add its file to source_match, and we don't have
        # to look for that package any more.
        if self.source_pkgs:
            found = []
            for pkg in self.source_pkgs:
                try:
                    mod = sys.modules[pkg]
                except KeyError:
                    continue

                found.append(pkg)

                try:
                    pkg_file = mod.__file__
                except AttributeError:
                    self._warn("Module %s has no Python source." % pkg)
                else:
                    d, f = os.path.split(pkg_file)
                    if f.startswith('__init__.'):
                        # This is actually a package, return the directory.
                        pkg_file = d
                    else:
                        pkg_file = self._source_for_file(pkg_file)
                    pkg_file = self.file_locator.canonical_filename(pkg_file)
                    self.source.append(pkg_file)
                    self.source_match.add(pkg_file)

            for pkg in found:
                self.source_pkgs.remove(pkg)

    def use_cache(self, usecache):
        """Control the use of a data file (incorrectly called a cache).

        `usecache` is true or false, whether to read and write data on disk.

        """
        self.data.usefile(usecache)

    def load(self):
        """Load previously-collected coverage data from the data file."""
        self.collector.reset()
        self.data.read()

    def start(self):
        """Start measuring code coverage."""
        if self.run_suffix:
            # Calling start() means we're running code, so use the run_suffix
            # as the data_suffix when we eventually save the data.
            self.data_suffix = self.run_suffix
        if self.auto_data:
            self.load()
            # Save coverage data when Python exits.
            if not self.atexit_registered:
                atexit.register(self.save)
                self.atexit_registered = True

        # Create the matchers we need for _should_trace
        if self.source or self.source_pkgs:
            self.source_match = TreeMatcher(self.source)
        else:
            if self.cover_dir:
                self.cover_match = TreeMatcher([self.cover_dir])
            if self.pylib_dirs:
                self.pylib_match = TreeMatcher(self.pylib_dirs)
        if self.include:
            self.include_match = FnmatchMatcher(self.include)
        if self.omit:
            self.omit_match = FnmatchMatcher(self.omit)

        self._harvested = False
        self.collector.start()

    def stop(self):
        """Stop measuring code coverage."""
        self.collector.stop()
        self._harvest_data()

    def erase(self):
        """Erase previously-collected coverage data.

        This removes the in-memory data collected in this session as well as
        discarding the data file.

        """
        self.collector.reset()
        self.data.erase()

    def clear_exclude(self, which='exclude'):
        """Clear the exclude list."""
        setattr(self.config, which + "_list", [])
        self._exclude_regex_stale()

    def exclude(self, regex, which='exclude'):
        """Exclude source lines from execution consideration.

        A number of lists of regular expressions are maintained.  Each list
        selects lines that are treated differently during reporting.

        `which` determines which list is modified.  The "exclude" list selects
        lines that are not considered executable at all.  The "partial" list
        indicates lines with branches that are not taken.

        `regex` is a regular expression.  The regex is added to the specified
        list.  If any of the regexes in the list is found in a line, the line
        is marked for special treatment during reporting.

        """
        excl_list = getattr(self.config, which + "_list")
        excl_list.append(regex)
        self._exclude_regex_stale()

    def _exclude_regex_stale(self):
        """Drop all the compiled exclusion regexes, a list was modified."""
        self._exclude_re.clear()

    def _exclude_regex(self, which):
        """Return a compiled regex for the given exclusion list."""
        if which not in self._exclude_re:
            excl_list = getattr(self.config, which + "_list")
            self._exclude_re[which] = join_regex(excl_list)
        return self._exclude_re[which]

    def get_exclude_list(self, which='exclude'):
        """Return a list of excluded regex patterns.

        `which` indicates which list is desired.  See `exclude` for the lists
        that are available, and their meaning.

        """
        return getattr(self.config, which + "_list")

    def save(self):
        """Save the collected coverage data to the data file."""
        data_suffix = self.data_suffix
        if data_suffix is True:
            # If data_suffix was a simple true value, then make a suffix with
            # plenty of distinguishing information.  We do this here in
            # `save()` at the last minute so that the pid will be correct even
            # if the process forks.
            data_suffix = "%s.%s.%06d" % (
                self.socket.gethostname(), self.os.getpid(),
                self.random.randint(0, 99999)
                )

        self._harvest_data()
        self.data.write(suffix=data_suffix)

    def combine(self):
        """Combine together a number of similarly-named coverage data files.

        All coverage data files whose name starts with `data_file` (from the
        coverage() constructor) will be read, and combined together into the
        current measurements.

        """
        aliases = None
        if self.config.paths:
            aliases = PathAliases(self.file_locator)
            for paths in self.config.paths.values():
                result = paths[0]
                for pattern in paths[1:]:
                    aliases.add(pattern, result)
        self.data.combine_parallel_data(aliases=aliases)

    def _harvest_data(self):
        """Get the collected data and reset the collector.

        Also warn about various problems collecting data.

        """
        if not self._harvested:
            self.data.add_line_data(self.collector.get_line_data())
            self.data.add_arc_data(self.collector.get_arc_data())
            self.collector.reset()

            # If there are still entries in the source_pkgs list, then we never
            # encountered those packages.
            for pkg in self.source_pkgs:
                self._warn("Module %s was never imported." % pkg)

            # Find out if we got any data.
            summary = self.data.summary()
            if not summary:
                self._warn("No data was collected.")

            # Find files that were never executed at all.
            for src in self.source:
                for py_file in find_python_files(src):
                    self.data.touch_file(py_file)

            self._harvested = True

    # Backward compatibility with version 1.
    def analysis(self, morf):
        """Like `analysis2` but doesn't return excluded line numbers."""
        f, s, _, m, mf = self.analysis2(morf)
        return f, s, m, mf

    def analysis2(self, morf):
        """Analyze a module.

        `morf` is a module or a filename.  It will be analyzed to determine
        its coverage statistics.  The return value is a 5-tuple:

        * The filename for the module.
        * A list of line numbers of executable statements.
        * A list of line numbers of excluded statements.
        * A list of line numbers of statements not run (missing from
          execution).
        * A readable formatted string of the missing line numbers.

        The analysis uses the source file itself and the current measured
        coverage data.

        """
        analysis = self._analyze(morf)
        return (
            analysis.filename, analysis.statements, analysis.excluded,
            analysis.missing, analysis.missing_formatted()
            )

    def _analyze(self, it):
        """Analyze a single morf or code unit.

        Returns an `Analysis` object.

        """
        if not isinstance(it, CodeUnit):
            it = code_unit_factory(it, self.file_locator)[0]

        return Analysis(self, it)

    def report(self, morfs=None, show_missing=True, ignore_errors=None,
                file=None,                          # pylint: disable=W0622
                omit=None, include=None
                ):
        """Write a summary report to `file`.

        Each module in `morfs` is listed, with counts of statements, executed
        statements, missing statements, and a list of lines missed.

        `include` is a list of filename patterns.  Modules whose filenames
        match those patterns will be included in the report. Modules matching
        `omit` will not be included in the report.

        """
        self.config.from_args(
            ignore_errors=ignore_errors, omit=omit, include=include
            )
        reporter = SummaryReporter(
            self, show_missing, self.config.ignore_errors
            )
        reporter.report(morfs, outfile=file, config=self.config)

    def annotate(self, morfs=None, directory=None, ignore_errors=None,
                    omit=None, include=None):
        """Annotate a list of modules.

        Each module in `morfs` is annotated.  The source is written to a new
        file, named with a ",cover" suffix, with each line prefixed with a
        marker to indicate the coverage of the line.  Covered lines have ">",
        excluded lines have "-", and missing lines have "!".

        See `coverage.report()` for other arguments.

        """
        self.config.from_args(
            ignore_errors=ignore_errors, omit=omit, include=include
            )
        reporter = AnnotateReporter(self, self.config.ignore_errors)
        reporter.report(morfs, config=self.config, directory=directory)

    def html_report(self, morfs=None, directory=None, ignore_errors=None,
                    omit=None, include=None):
        """Generate an HTML report.

        See `coverage.report()` for other arguments.

        """
        self.config.from_args(
            ignore_errors=ignore_errors, omit=omit, include=include,
            html_dir=directory,
            )
        reporter = HtmlReporter(self, self.config.ignore_errors)
        reporter.report(morfs, config=self.config)

    def xml_report(self, morfs=None, outfile=None, ignore_errors=None,
                    omit=None, include=None):
        """Generate an XML report of coverage results.

        The report is compatible with Cobertura reports.

        Each module in `morfs` is included in the report.  `outfile` is the
        path to write the file to, "-" will write to stdout.

        See `coverage.report()` for other arguments.

        """
        self.config.from_args(
            ignore_errors=ignore_errors, omit=omit, include=include,
            xml_output=outfile,
            )
        file_to_close = None
        if self.config.xml_output:
            if self.config.xml_output == '-':
                outfile = sys.stdout
            else:
                outfile = open(self.config.xml_output, "w")
                file_to_close = outfile
        try:
            reporter = XmlReporter(self, self.config.ignore_errors)
            reporter.report(morfs, outfile=outfile, config=self.config)
        finally:
            if file_to_close:
                file_to_close.close()

    def sysinfo(self):
        """Return a list of (key, value) pairs showing internal information."""

        import coverage as covmod
        import platform, re

        try:
            implementation = platform.python_implementation()
        except AttributeError:
            implementation = "unknown"

        info = [
            ('version', covmod.__version__),
            ('coverage', covmod.__file__),
            ('cover_dir', self.cover_dir),
            ('pylib_dirs', self.pylib_dirs),
            ('tracer', self.collector.tracer_name()),
            ('data_path', self.data.filename),
            ('python', sys.version.replace('\n', '')),
            ('platform', platform.platform()),
            ('implementation', implementation),
            ('cwd', os.getcwd()),
            ('path', sys.path),
            ('environment', [
                ("%s = %s" % (k, v)) for k, v in os.environ.items()
                    if re.search("^COV|^PY", k)
                ]),
            ]
        return info


def process_startup():
    """Call this at Python startup to perhaps measure coverage.

    If the environment variable COVERAGE_PROCESS_START is defined, coverage
    measurement is started.  The value of the variable is the config file
    to use.

    There are two ways to configure your Python installation to invoke this
    function when Python starts:

    #. Create or append to sitecustomize.py to add these lines::

        import coverage
        coverage.process_startup()

    #. Create a .pth file in your Python installation containing::

        import coverage; coverage.process_startup()

    """
    cps = os.environ.get("COVERAGE_PROCESS_START")
    if cps:
        cov = coverage(config_file=cps, auto_data=True)
        if os.environ.get("COVERAGE_COVERAGE"):
            # Measuring coverage within coverage.py takes yet more trickery.
            cov.cover_dir = "Please measure coverage.py!"
        cov.start()
