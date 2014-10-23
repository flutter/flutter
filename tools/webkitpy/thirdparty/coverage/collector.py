"""Raw data collector for Coverage."""

import sys, threading

try:
    # Use the C extension code when we can, for speed.
    from coverage.tracer import CTracer
except ImportError:
    # Couldn't import the C extension, maybe it isn't built.
    CTracer = None


class PyTracer(object):
    """Python implementation of the raw data tracer."""

    # Because of poor implementations of trace-function-manipulating tools,
    # the Python trace function must be kept very simple.  In particular, there
    # must be only one function ever set as the trace function, both through
    # sys.settrace, and as the return value from the trace function.  Put
    # another way, the trace function must always return itself.  It cannot
    # swap in other functions, or return None to avoid tracing a particular
    # frame.
    #
    # The trace manipulator that introduced this restriction is DecoratorTools,
    # which sets a trace function, and then later restores the pre-existing one
    # by calling sys.settrace with a function it found in the current frame.
    #
    # Systems that use DecoratorTools (or similar trace manipulations) must use
    # PyTracer to get accurate results.  The command-line --timid argument is
    # used to force the use of this tracer.

    def __init__(self):
        self.data = None
        self.should_trace = None
        self.should_trace_cache = None
        self.warn = None
        self.cur_file_data = None
        self.last_line = 0
        self.data_stack = []
        self.last_exc_back = None
        self.last_exc_firstlineno = 0
        self.arcs = False

    def _trace(self, frame, event, arg_unused):
        """The trace function passed to sys.settrace."""

        #print("trace event: %s %r @%d" % (
        #           event, frame.f_code.co_filename, frame.f_lineno))

        if self.last_exc_back:
            if frame == self.last_exc_back:
                # Someone forgot a return event.
                if self.arcs and self.cur_file_data:
                    pair = (self.last_line, -self.last_exc_firstlineno)
                    self.cur_file_data[pair] = None
                self.cur_file_data, self.last_line = self.data_stack.pop()
            self.last_exc_back = None

        if event == 'call':
            # Entering a new function context.  Decide if we should trace
            # in this file.
            self.data_stack.append((self.cur_file_data, self.last_line))
            filename = frame.f_code.co_filename
            tracename = self.should_trace_cache.get(filename)
            if tracename is None:
                tracename = self.should_trace(filename, frame)
                self.should_trace_cache[filename] = tracename
            #print("called, stack is %d deep, tracename is %r" % (
            #               len(self.data_stack), tracename))
            if tracename:
                if tracename not in self.data:
                    self.data[tracename] = {}
                self.cur_file_data = self.data[tracename]
            else:
                self.cur_file_data = None
            # Set the last_line to -1 because the next arc will be entering a
            # code block, indicated by (-1, n).
            self.last_line = -1
        elif event == 'line':
            # Record an executed line.
            if self.cur_file_data is not None:
                if self.arcs:
                    #print("lin", self.last_line, frame.f_lineno)
                    self.cur_file_data[(self.last_line, frame.f_lineno)] = None
                else:
                    #print("lin", frame.f_lineno)
                    self.cur_file_data[frame.f_lineno] = None
            self.last_line = frame.f_lineno
        elif event == 'return':
            if self.arcs and self.cur_file_data:
                first = frame.f_code.co_firstlineno
                self.cur_file_data[(self.last_line, -first)] = None
            # Leaving this function, pop the filename stack.
            self.cur_file_data, self.last_line = self.data_stack.pop()
            #print("returned, stack is %d deep" % (len(self.data_stack)))
        elif event == 'exception':
            #print("exc", self.last_line, frame.f_lineno)
            self.last_exc_back = frame.f_back
            self.last_exc_firstlineno = frame.f_code.co_firstlineno
        return self._trace

    def start(self):
        """Start this Tracer.

        Return a Python function suitable for use with sys.settrace().

        """
        sys.settrace(self._trace)
        return self._trace

    def stop(self):
        """Stop this Tracer."""
        if hasattr(sys, "gettrace") and self.warn:
            if sys.gettrace() != self._trace:
                msg = "Trace function changed, measurement is likely wrong: %r"
                self.warn(msg % sys.gettrace())
        sys.settrace(None)

    def get_stats(self):
        """Return a dictionary of statistics, or None."""
        return None


class Collector(object):
    """Collects trace data.

    Creates a Tracer object for each thread, since they track stack
    information.  Each Tracer points to the same shared data, contributing
    traced data points.

    When the Collector is started, it creates a Tracer for the current thread,
    and installs a function to create Tracers for each new thread started.
    When the Collector is stopped, all active Tracers are stopped.

    Threads started while the Collector is stopped will never have Tracers
    associated with them.

    """

    # The stack of active Collectors.  Collectors are added here when started,
    # and popped when stopped.  Collectors on the stack are paused when not
    # the top, and resumed when they become the top again.
    _collectors = []

    def __init__(self, should_trace, timid, branch, warn):
        """Create a collector.

        `should_trace` is a function, taking a filename, and returning a
        canonicalized filename, or False depending on whether the file should
        be traced or not.

        If `timid` is true, then a slower simpler trace function will be
        used.  This is important for some environments where manipulation of
        tracing functions make the faster more sophisticated trace function not
        operate properly.

        If `branch` is true, then branches will be measured.  This involves
        collecting data on which statements followed each other (arcs).  Use
        `get_arc_data` to get the arc data.

        `warn` is a warning function, taking a single string message argument,
        to be used if a warning needs to be issued.

        """
        self.should_trace = should_trace
        self.warn = warn
        self.branch = branch
        self.reset()

        if timid:
            # Being timid: use the simple Python trace function.
            self._trace_class = PyTracer
        else:
            # Being fast: use the C Tracer if it is available, else the Python
            # trace function.
            self._trace_class = CTracer or PyTracer

    def __repr__(self):
        return "<Collector at 0x%x>" % id(self)

    def tracer_name(self):
        """Return the class name of the tracer we're using."""
        return self._trace_class.__name__

    def reset(self):
        """Clear collected data, and prepare to collect more."""
        # A dictionary mapping filenames to dicts with linenumber keys,
        # or mapping filenames to dicts with linenumber pairs as keys.
        self.data = {}

        # A cache of the results from should_trace, the decision about whether
        # to trace execution in a file. A dict of filename to (filename or
        # False).
        self.should_trace_cache = {}

        # Our active Tracers.
        self.tracers = []

    def _start_tracer(self):
        """Start a new Tracer object, and store it in self.tracers."""
        tracer = self._trace_class()
        tracer.data = self.data
        tracer.arcs = self.branch
        tracer.should_trace = self.should_trace
        tracer.should_trace_cache = self.should_trace_cache
        tracer.warn = self.warn
        fn = tracer.start()
        self.tracers.append(tracer)
        return fn

    # The trace function has to be set individually on each thread before
    # execution begins.  Ironically, the only support the threading module has
    # for running code before the thread main is the tracing function.  So we
    # install this as a trace function, and the first time it's called, it does
    # the real trace installation.

    def _installation_trace(self, frame_unused, event_unused, arg_unused):
        """Called on new threads, installs the real tracer."""
        # Remove ourselves as the trace function
        sys.settrace(None)
        # Install the real tracer.
        fn = self._start_tracer()
        # Invoke the real trace function with the current event, to be sure
        # not to lose an event.
        if fn:
            fn = fn(frame_unused, event_unused, arg_unused)
        # Return the new trace function to continue tracing in this scope.
        return fn

    def start(self):
        """Start collecting trace information."""
        if self._collectors:
            self._collectors[-1].pause()
        self._collectors.append(self)
        #print >>sys.stderr, "Started: %r" % self._collectors

        # Check to see whether we had a fullcoverage tracer installed.
        traces0 = None
        if hasattr(sys, "gettrace"):
            fn0 = sys.gettrace()
            if fn0:
                tracer0 = getattr(fn0, '__self__', None)
                if tracer0:
                    traces0 = getattr(tracer0, 'traces', None)

        # Install the tracer on this thread.
        fn = self._start_tracer()

        if traces0:
            for args in traces0:
                (frame, event, arg), lineno = args
                fn(frame, event, arg, lineno=lineno)

        # Install our installation tracer in threading, to jump start other
        # threads.
        threading.settrace(self._installation_trace)

    def stop(self):
        """Stop collecting trace information."""
        #print >>sys.stderr, "Stopping: %r" % self._collectors
        assert self._collectors
        assert self._collectors[-1] is self

        self.pause()
        self.tracers = []

        # Remove this Collector from the stack, and resume the one underneath
        # (if any).
        self._collectors.pop()
        if self._collectors:
            self._collectors[-1].resume()

    def pause(self):
        """Pause tracing, but be prepared to `resume`."""
        for tracer in self.tracers:
            tracer.stop()
            stats = tracer.get_stats()
            if stats:
                print("\nCoverage.py tracer stats:")
                for k in sorted(stats.keys()):
                    print("%16s: %s" % (k, stats[k]))
        threading.settrace(None)

    def resume(self):
        """Resume tracing after a `pause`."""
        for tracer in self.tracers:
            tracer.start()
        threading.settrace(self._installation_trace)

    def get_line_data(self):
        """Return the line data collected.

        Data is { filename: { lineno: None, ...}, ...}

        """
        if self.branch:
            # If we were measuring branches, then we have to re-build the dict
            # to show line data.
            line_data = {}
            for f, arcs in self.data.items():
                line_data[f] = ldf = {}
                for l1, _ in list(arcs.keys()):
                    if l1:
                        ldf[l1] = None
            return line_data
        else:
            return self.data

    def get_arc_data(self):
        """Return the arc data collected.

        Data is { filename: { (l1, l2): None, ...}, ...}

        Note that no data is collected or returned if the Collector wasn't
        created with `branch` true.

        """
        if self.branch:
            return self.data
        else:
            return {}
