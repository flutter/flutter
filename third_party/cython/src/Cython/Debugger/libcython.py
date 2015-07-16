"""
GDB extension that adds Cython support.
"""

from __future__ import with_statement

import sys
import textwrap
import traceback
import functools
import itertools
import collections

import gdb

try:
    from lxml import etree
    have_lxml = True
except ImportError:
    have_lxml = False
    try:
        # Python 2.5
        from xml.etree import cElementTree as etree
    except ImportError:
        try:
            # Python 2.5
            from xml.etree import ElementTree as etree
        except ImportError:
            try:
                # normal cElementTree install
                import cElementTree as etree
            except ImportError:
                # normal ElementTree install
                import elementtree.ElementTree as etree

try:
    import pygments.lexers
    import pygments.formatters
except ImportError:
    pygments = None
    sys.stderr.write("Install pygments for colorized source code.\n")

if hasattr(gdb, 'string_to_argv'):
    from gdb import string_to_argv
else:
    from shlex import split as string_to_argv

from Cython.Debugger import libpython

# C or Python type
CObject = 'CObject'
PythonObject = 'PythonObject'

_data_types = dict(CObject=CObject, PythonObject=PythonObject)
_filesystemencoding = sys.getfilesystemencoding() or 'UTF-8'

# decorators

def dont_suppress_errors(function):
    "*sigh*, readline"
    @functools.wraps(function)
    def wrapper(*args, **kwargs):
        try:
            return function(*args, **kwargs)
        except Exception:
            traceback.print_exc()
            raise

    return wrapper

def default_selected_gdb_frame(err=True):
    def decorator(function):
        @functools.wraps(function)
        def wrapper(self, frame=None, *args, **kwargs):
            try:
                frame = frame or gdb.selected_frame()
            except RuntimeError:
                raise gdb.GdbError("No frame is currently selected.")

            if err and frame.name() is None:
                raise NoFunctionNameInFrameError()

            return function(self, frame, *args, **kwargs)
        return wrapper
    return decorator

def require_cython_frame(function):
    @functools.wraps(function)
    @require_running_program
    def wrapper(self, *args, **kwargs):
        frame = kwargs.get('frame') or gdb.selected_frame()
        if not self.is_cython_function(frame):
            raise gdb.GdbError('Selected frame does not correspond with a '
                               'Cython function we know about.')
        return function(self, *args, **kwargs)
    return wrapper

def dispatch_on_frame(c_command, python_command=None):
    def decorator(function):
        @functools.wraps(function)
        def wrapper(self, *args, **kwargs):
            is_cy = self.is_cython_function()
            is_py = self.is_python_function()

            if is_cy or (is_py and not python_command):
                function(self, *args, **kwargs)
            elif is_py:
                gdb.execute(python_command)
            elif self.is_relevant_function():
                gdb.execute(c_command)
            else:
                raise gdb.GdbError("Not a function cygdb knows about. "
                                   "Use the normal GDB commands instead.")

        return wrapper
    return decorator

def require_running_program(function):
    @functools.wraps(function)
    def wrapper(*args, **kwargs):
        try:
            gdb.selected_frame()
        except RuntimeError:
            raise gdb.GdbError("No frame is currently selected.")

        return function(*args, **kwargs)
    return wrapper


def gdb_function_value_to_unicode(function):
    @functools.wraps(function)
    def wrapper(self, string, *args, **kwargs):
        if isinstance(string, gdb.Value):
            string = string.string()

        return function(self, string, *args, **kwargs)
    return wrapper


# Classes that represent the debug information
# Don't rename the parameters of these classes, they come directly from the XML

class CythonModule(object):
    def __init__(self, module_name, filename, c_filename):
        self.name = module_name
        self.filename = filename
        self.c_filename = c_filename
        self.globals = {}
        # {cython_lineno: min(c_linenos)}
        self.lineno_cy2c = {}
        # {c_lineno: cython_lineno}
        self.lineno_c2cy = {}
        self.functions = {}

class CythonVariable(object):

    def __init__(self, name, cname, qualified_name, type, lineno):
        self.name = name
        self.cname = cname
        self.qualified_name = qualified_name
        self.type = type
        self.lineno = int(lineno)

class CythonFunction(CythonVariable):
    def __init__(self,
                 module,
                 name,
                 cname,
                 pf_cname,
                 qualified_name,
                 lineno,
                 type=CObject,
                 is_initmodule_function="False"):
        super(CythonFunction, self).__init__(name,
                                             cname,
                                             qualified_name,
                                             type,
                                             lineno)
        self.module = module
        self.pf_cname = pf_cname
        self.is_initmodule_function = is_initmodule_function == "True"
        self.locals = {}
        self.arguments = []
        self.step_into_functions = set()


# General purpose classes

class CythonBase(object):

    @default_selected_gdb_frame(err=False)
    def is_cython_function(self, frame):
        return frame.name() in self.cy.functions_by_cname

    @default_selected_gdb_frame(err=False)
    def is_python_function(self, frame):
        """
        Tells if a frame is associated with a Python function.
        If we can't read the Python frame information, don't regard it as such.
        """
        if frame.name() == 'PyEval_EvalFrameEx':
            pyframe = libpython.Frame(frame).get_pyop()
            return pyframe and not pyframe.is_optimized_out()
        return False

    @default_selected_gdb_frame()
    def get_c_function_name(self, frame):
        return frame.name()

    @default_selected_gdb_frame()
    def get_c_lineno(self, frame):
        return frame.find_sal().line

    @default_selected_gdb_frame()
    def get_cython_function(self, frame):
        result = self.cy.functions_by_cname.get(frame.name())
        if result is None:
            raise NoCythonFunctionInFrameError()

        return result

    @default_selected_gdb_frame()
    def get_cython_lineno(self, frame):
        """
        Get the current Cython line number. Returns 0 if there is no
        correspondence between the C and Cython code.
        """
        cyfunc = self.get_cython_function(frame)
        return cyfunc.module.lineno_c2cy.get(self.get_c_lineno(frame), 0)

    @default_selected_gdb_frame()
    def get_source_desc(self, frame):
        filename = lineno = lexer = None
        if self.is_cython_function(frame):
            filename = self.get_cython_function(frame).module.filename
            lineno = self.get_cython_lineno(frame)
            if pygments:
                lexer = pygments.lexers.CythonLexer(stripall=False)
        elif self.is_python_function(frame):
            pyframeobject = libpython.Frame(frame).get_pyop()

            if not pyframeobject:
                raise gdb.GdbError(
                            'Unable to read information on python frame')

            filename = pyframeobject.filename()
            lineno = pyframeobject.current_line_num()

            if pygments:
                lexer = pygments.lexers.PythonLexer(stripall=False)
        else:
            symbol_and_line_obj = frame.find_sal()
            if not symbol_and_line_obj or not symbol_and_line_obj.symtab:
                filename = None
                lineno = 0
            else:
                filename = symbol_and_line_obj.symtab.fullname()
                lineno = symbol_and_line_obj.line
                if pygments:
                    lexer = pygments.lexers.CLexer(stripall=False)

        return SourceFileDescriptor(filename, lexer), lineno

    @default_selected_gdb_frame()
    def get_source_line(self, frame):
        source_desc, lineno = self.get_source_desc()
        return source_desc.get_source(lineno)

    @default_selected_gdb_frame()
    def is_relevant_function(self, frame):
        """
        returns whether we care about a frame on the user-level when debugging
        Cython code
        """
        name = frame.name()
        older_frame = frame.older()
        if self.is_cython_function(frame) or self.is_python_function(frame):
            return True
        elif older_frame and self.is_cython_function(older_frame):
            # check for direct C function call from a Cython function
            cython_func = self.get_cython_function(older_frame)
            return name in cython_func.step_into_functions

        return False

    @default_selected_gdb_frame(err=False)
    def print_stackframe(self, frame, index, is_c=False):
        """
        Print a C, Cython or Python stack frame and the line of source code
        if available.
        """
        # do this to prevent the require_cython_frame decorator from
        # raising GdbError when calling self.cy.cy_cvalue.invoke()
        selected_frame = gdb.selected_frame()
        frame.select()

        try:
            source_desc, lineno = self.get_source_desc(frame)
        except NoFunctionNameInFrameError:
            print '#%-2d Unknown Frame (compile with -g)' % index
            return

        if not is_c and self.is_python_function(frame):
            pyframe = libpython.Frame(frame).get_pyop()
            if pyframe is None or pyframe.is_optimized_out():
                # print this python function as a C function
                return self.print_stackframe(frame, index, is_c=True)

            func_name = pyframe.co_name
            func_cname = 'PyEval_EvalFrameEx'
            func_args = []
        elif self.is_cython_function(frame):
            cyfunc = self.get_cython_function(frame)
            f = lambda arg: self.cy.cy_cvalue.invoke(arg, frame=frame)

            func_name = cyfunc.name
            func_cname = cyfunc.cname
            func_args = [] # [(arg, f(arg)) for arg in cyfunc.arguments]
        else:
            source_desc, lineno = self.get_source_desc(frame)
            func_name = frame.name()
            func_cname = func_name
            func_args = []

        try:
            gdb_value = gdb.parse_and_eval(func_cname)
        except RuntimeError:
            func_address = 0
        else:
            # Seriously? Why is the address not an int?
            func_address = int(str(gdb_value.address).split()[0], 0)

        a = ', '.join('%s=%s' % (name, val) for name, val in func_args)
        print '#%-2d 0x%016x in %s(%s)' % (index, func_address, func_name, a),

        if source_desc.filename is not None:
            print 'at %s:%s' % (source_desc.filename, lineno),

        print

        try:
            print '    ' + source_desc.get_source(lineno)
        except gdb.GdbError:
            pass

        selected_frame.select()

    def get_remote_cython_globals_dict(self):
        m = gdb.parse_and_eval('__pyx_m')

        try:
            PyModuleObject = gdb.lookup_type('PyModuleObject')
        except RuntimeError:
            raise gdb.GdbError(textwrap.dedent("""\
                Unable to lookup type PyModuleObject, did you compile python
                with debugging support (-g)?"""))

        m = m.cast(PyModuleObject.pointer())
        return m['md_dict']


    def get_cython_globals_dict(self):
        """
        Get the Cython globals dict where the remote names are turned into
        local strings.
        """
        remote_dict = self.get_remote_cython_globals_dict()
        pyobject_dict = libpython.PyObjectPtr.from_pyobject_ptr(remote_dict)

        result = {}
        seen = set()
        for k, v in pyobject_dict.iteritems():
            result[k.proxyval(seen)] = v

        return result

    def print_gdb_value(self, name, value, max_name_length=None, prefix=''):
        if libpython.pretty_printer_lookup(value):
            typename = ''
        else:
            typename = '(%s) ' % (value.type,)

        if max_name_length is None:
            print '%s%s = %s%s' % (prefix, name, typename, value)
        else:
            print '%s%-*s = %s%s' % (prefix, max_name_length, name, typename,
                                     value)

    def is_initialized(self, cython_func, local_name):
        cyvar = cython_func.locals[local_name]
        cur_lineno = self.get_cython_lineno()

        if '->' in cyvar.cname:
            # Closed over free variable
            if cur_lineno > cython_func.lineno:
                if cyvar.type == PythonObject:
                    return long(gdb.parse_and_eval(cyvar.cname))
                return True
            return False

        return cur_lineno > cyvar.lineno


class SourceFileDescriptor(object):
    def __init__(self, filename, lexer, formatter=None):
        self.filename = filename
        self.lexer = lexer
        self.formatter = formatter

    def valid(self):
        return self.filename is not None

    def lex(self, code):
        if pygments and self.lexer and parameters.colorize_code:
            bg = parameters.terminal_background.value
            if self.formatter is None:
                formatter = pygments.formatters.TerminalFormatter(bg=bg)
            else:
                formatter = self.formatter

            return pygments.highlight(code, self.lexer, formatter)

        return code

    def _get_source(self, start, stop, lex_source, mark_line, lex_entire):
        with open(self.filename) as f:
            # to provide "correct" colouring, the entire code needs to be
            # lexed. However, this makes a lot of things terribly slow, so
            # we decide not to. Besides, it's unlikely to matter.

            if lex_source and lex_entire:
                f = self.lex(f.read()).splitlines()

            slice = itertools.islice(f, start - 1, stop - 1)

            for idx, line in enumerate(slice):
                if start + idx == mark_line:
                    prefix = '>'
                else:
                    prefix = ' '

                if lex_source and not lex_entire:
                    line = self.lex(line)

                yield '%s %4d    %s' % (prefix, start + idx, line.rstrip())

    def get_source(self, start, stop=None, lex_source=True, mark_line=0,
                   lex_entire=False):
        exc = gdb.GdbError('Unable to retrieve source code')

        if not self.filename:
            raise exc

        start = max(start, 1)
        if stop is None:
            stop = start + 1

        try:
            return '\n'.join(
                self._get_source(start, stop, lex_source, mark_line, lex_entire))
        except IOError:
            raise exc


# Errors

class CyGDBError(gdb.GdbError):
    """
    Base class for Cython-command related erorrs
    """

    def __init__(self, *args):
        args = args or (self.msg,)
        super(CyGDBError, self).__init__(*args)

class NoCythonFunctionInFrameError(CyGDBError):
    """
    raised when the user requests the current cython function, which is
    unavailable
    """
    msg = "Current function is a function cygdb doesn't know about"

class NoFunctionNameInFrameError(NoCythonFunctionInFrameError):
    """
    raised when the name of the C function could not be determined
    in the current C stack frame
    """
    msg = ('C function name could not be determined in the current C stack '
           'frame')


# Parameters

class CythonParameter(gdb.Parameter):
    """
    Base class for cython parameters
    """

    def __init__(self, name, command_class, parameter_class, default=None):
        self.show_doc = self.set_doc = self.__class__.__doc__
        super(CythonParameter, self).__init__(name, command_class,
                                              parameter_class)
        if default is not None:
            self.value = default

    def __nonzero__(self):
        return bool(self.value)

    __bool__ = __nonzero__ # python 3

class CompleteUnqualifiedFunctionNames(CythonParameter):
    """
    Have 'cy break' complete unqualified function or method names.
    """

class ColorizeSourceCode(CythonParameter):
    """
    Tell cygdb whether to colorize source code.
    """

class TerminalBackground(CythonParameter):
    """
    Tell cygdb about the user's terminal background (light or dark).
    """

class CythonParameters(object):
    """
    Simple container class that might get more functionality in the distant
    future (mostly to remind us that we're dealing with parameters).
    """

    def __init__(self):
        self.complete_unqualified = CompleteUnqualifiedFunctionNames(
            'cy_complete_unqualified',
            gdb.COMMAND_BREAKPOINTS,
            gdb.PARAM_BOOLEAN,
            True)
        self.colorize_code = ColorizeSourceCode(
            'cy_colorize_code',
            gdb.COMMAND_FILES,
            gdb.PARAM_BOOLEAN,
            True)
        self.terminal_background = TerminalBackground(
            'cy_terminal_background_color',
            gdb.COMMAND_FILES,
            gdb.PARAM_STRING,
            "dark")

parameters = CythonParameters()


# Commands

class CythonCommand(gdb.Command, CythonBase):
    """
    Base class for Cython commands
    """

    command_class = gdb.COMMAND_NONE

    @classmethod
    def _register(cls, clsname, args, kwargs):
        if not hasattr(cls, 'completer_class'):
            return cls(clsname, cls.command_class, *args, **kwargs)
        else:
            return cls(clsname, cls.command_class, cls.completer_class,
                       *args, **kwargs)

    @classmethod
    def register(cls, *args, **kwargs):
        alias = getattr(cls, 'alias', None)
        if alias:
            cls._register(cls.alias, args, kwargs)

        return cls._register(cls.name, args, kwargs)


class CyCy(CythonCommand):
    """
    Invoke a Cython command. Available commands are:

        cy import
        cy break
        cy step
        cy next
        cy run
        cy cont
        cy finish
        cy up
        cy down
        cy select
        cy bt / cy backtrace
        cy list
        cy print
        cy set
        cy locals
        cy globals
        cy exec
    """

    name = 'cy'
    command_class = gdb.COMMAND_NONE
    completer_class = gdb.COMPLETE_COMMAND

    def __init__(self, name, command_class, completer_class):
        # keep the signature 2.5 compatible (i.e. do not use f(*a, k=v)
        super(CythonCommand, self).__init__(name, command_class,
                                            completer_class, prefix=True)

        commands = dict(
            # GDB commands
            import_ = CyImport.register(),
            break_ = CyBreak.register(),
            step = CyStep.register(),
            next = CyNext.register(),
            run = CyRun.register(),
            cont = CyCont.register(),
            finish = CyFinish.register(),
            up = CyUp.register(),
            down = CyDown.register(),
            select = CySelect.register(),
            bt = CyBacktrace.register(),
            list = CyList.register(),
            print_ = CyPrint.register(),
            locals = CyLocals.register(),
            globals = CyGlobals.register(),
            exec_ = libpython.FixGdbCommand('cy exec', '-cy-exec'),
            _exec = CyExec.register(),
            set = CySet.register(),

            # GDB functions
            cy_cname = CyCName('cy_cname'),
            cy_cvalue = CyCValue('cy_cvalue'),
            cy_lineno = CyLine('cy_lineno'),
            cy_eval = CyEval('cy_eval'),
        )

        for command_name, command in commands.iteritems():
            command.cy = self
            setattr(self, command_name, command)

        self.cy = self

        # Cython module namespace
        self.cython_namespace = {}

        # maps (unique) qualified function names (e.g.
        # cythonmodule.ClassName.method_name) to the CythonFunction object
        self.functions_by_qualified_name = {}

        # unique cnames of Cython functions
        self.functions_by_cname = {}

        # map function names like method_name to a list of all such
        # CythonFunction objects
        self.functions_by_name = collections.defaultdict(list)


class CyImport(CythonCommand):
    """
    Import debug information outputted by the Cython compiler
    Example: cy import FILE...
    """

    name = 'cy import'
    command_class = gdb.COMMAND_STATUS
    completer_class = gdb.COMPLETE_FILENAME

    def invoke(self, args, from_tty):
        args = args.encode(_filesystemencoding)
        for arg in string_to_argv(args):
            try:
                f = open(arg)
            except OSError, e:
                raise gdb.GdbError('Unable to open file %r: %s' %
                                                (args, e.args[1]))

            t = etree.parse(f)

            for module in t.getroot():
                cython_module = CythonModule(**module.attrib)
                self.cy.cython_namespace[cython_module.name] = cython_module

                for variable in module.find('Globals'):
                    d = variable.attrib
                    cython_module.globals[d['name']] = CythonVariable(**d)

                for function in module.find('Functions'):
                    cython_function = CythonFunction(module=cython_module,
                                                     **function.attrib)

                    # update the global function mappings
                    name = cython_function.name
                    qname = cython_function.qualified_name

                    self.cy.functions_by_name[name].append(cython_function)
                    self.cy.functions_by_qualified_name[
                        cython_function.qualified_name] = cython_function
                    self.cy.functions_by_cname[
                        cython_function.cname] = cython_function

                    d = cython_module.functions[qname] = cython_function

                    for local in function.find('Locals'):
                        d = local.attrib
                        cython_function.locals[d['name']] = CythonVariable(**d)

                    for step_into_func in function.find('StepIntoFunctions'):
                        d = step_into_func.attrib
                        cython_function.step_into_functions.add(d['name'])

                    cython_function.arguments.extend(
                        funcarg.tag for funcarg in function.find('Arguments'))

                for marker in module.find('LineNumberMapping'):
                    cython_lineno = int(marker.attrib['cython_lineno'])
                    c_linenos = map(int, marker.attrib['c_linenos'].split())
                    cython_module.lineno_cy2c[cython_lineno] = min(c_linenos)
                    for c_lineno in c_linenos:
                        cython_module.lineno_c2cy[c_lineno] = cython_lineno


class CyBreak(CythonCommand):
    """
    Set a breakpoint for Cython code using Cython qualified name notation, e.g.:

        cy break cython_modulename.ClassName.method_name...

    or normal notation:

        cy break function_or_method_name...

    or for a line number:

        cy break cython_module:lineno...

    Set a Python breakpoint:
        Break on any function or method named 'func' in module 'modname'

            cy break -p modname.func...

        Break on any function or method named 'func'

            cy break -p func...
    """

    name = 'cy break'
    command_class = gdb.COMMAND_BREAKPOINTS

    def _break_pyx(self, name):
        modulename, _, lineno = name.partition(':')
        lineno = int(lineno)
        if modulename:
            cython_module = self.cy.cython_namespace[modulename]
        else:
            cython_module = self.get_cython_function().module

        if lineno in cython_module.lineno_cy2c:
            c_lineno = cython_module.lineno_cy2c[lineno]
            breakpoint = '%s:%s' % (cython_module.c_filename, c_lineno)
            gdb.execute('break ' + breakpoint)
        else:
            raise gdb.GdbError("Not a valid line number. "
                               "Does it contain actual code?")

    def _break_funcname(self, funcname):
        func = self.cy.functions_by_qualified_name.get(funcname)

        if func and func.is_initmodule_function:
            func = None

        break_funcs = [func]

        if not func:
            funcs = self.cy.functions_by_name.get(funcname) or []
            funcs = [f for f in funcs if not f.is_initmodule_function]

            if not funcs:
                gdb.execute('break ' + funcname)
                return

            if len(funcs) > 1:
                # multiple functions, let the user pick one
                print 'There are multiple such functions:'
                for idx, func in enumerate(funcs):
                    print '%3d) %s' % (idx, func.qualified_name)

                while True:
                    try:
                        result = raw_input(
                            "Select a function, press 'a' for all "
                            "functions or press 'q' or '^D' to quit: ")
                    except EOFError:
                        return
                    else:
                        if result.lower() == 'q':
                            return
                        elif result.lower() == 'a':
                            break_funcs = funcs
                            break
                        elif (result.isdigit() and
                            0 <= int(result) < len(funcs)):
                            break_funcs = [funcs[int(result)]]
                            break
                        else:
                            print 'Not understood...'
            else:
                break_funcs = [funcs[0]]

        for func in break_funcs:
            gdb.execute('break %s' % func.cname)
            if func.pf_cname:
                gdb.execute('break %s' % func.pf_cname)

    def invoke(self, function_names, from_tty):
        argv = string_to_argv(function_names.encode('UTF-8'))
        if function_names.startswith('-p'):
            argv = argv[1:]
            python_breakpoints = True
        else:
            python_breakpoints = False

        for funcname in argv:
            if python_breakpoints:
                gdb.execute('py-break %s' % funcname)
            elif ':' in funcname:
                self._break_pyx(funcname)
            else:
                self._break_funcname(funcname)

    @dont_suppress_errors
    def complete(self, text, word):
        # Filter init-module functions (breakpoints can be set using
        # modulename:linenumber).
        names =  [n for n, L in self.cy.functions_by_name.iteritems()
                        if any(not f.is_initmodule_function for f in L)]
        qnames = [n for n, f in self.cy.functions_by_qualified_name.iteritems()
                        if not f.is_initmodule_function]

        if parameters.complete_unqualified:
            all_names = itertools.chain(qnames, names)
        else:
            all_names = qnames

        words = text.strip().split()
        if not words or '.' not in words[-1]:
            # complete unqualified
            seen = set(text[:-len(word)].split())
            return [n for n in all_names
                          if n.startswith(word) and n not in seen]

        # complete qualified name
        lastword = words[-1]
        compl = [n for n in qnames if n.startswith(lastword)]

        if len(lastword) > len(word):
            # readline sees something (e.g. a '.') as a word boundary, so don't
            # "recomplete" this prefix
            strip_prefix_length = len(lastword) - len(word)
            compl = [n[strip_prefix_length:] for n in compl]

        return compl


class CythonInfo(CythonBase, libpython.PythonInfo):
    """
    Implementation of the interface dictated by libpython.LanguageInfo.
    """

    def lineno(self, frame):
        # Take care of the Python and Cython levels. We need to care for both
        # as we can't simply dispath to 'py-step', since that would work for
        # stepping through Python code, but it would not step back into Cython-
        # related code. The C level should be dispatched to the 'step' command.
        if self.is_cython_function(frame):
            return self.get_cython_lineno(frame)
        return super(CythonInfo, self).lineno(frame)

    def get_source_line(self, frame):
        try:
            line = super(CythonInfo, self).get_source_line(frame)
        except gdb.GdbError:
            return None
        else:
            return line.strip() or None

    def exc_info(self, frame):
        if self.is_python_function:
            return super(CythonInfo, self).exc_info(frame)

    def runtime_break_functions(self):
        if self.is_cython_function():
            return self.get_cython_function().step_into_functions
        return ()

    def static_break_functions(self):
        result = ['PyEval_EvalFrameEx']
        result.extend(self.cy.functions_by_cname)
        return result


class CythonExecutionControlCommand(CythonCommand,
                                    libpython.ExecutionControlCommandBase):

    @classmethod
    def register(cls):
        return cls(cls.name, cython_info)


class CyStep(CythonExecutionControlCommand, libpython.PythonStepperMixin):
    "Step through Cython, Python or C code."

    name = 'cy -step'
    stepinto = True

    def invoke(self, args, from_tty):
        if self.is_python_function():
            self.python_step(self.stepinto)
        elif not self.is_cython_function():
            if self.stepinto:
                command = 'step'
            else:
                command = 'next'

            self.finish_executing(gdb.execute(command, to_string=True))
        else:
            self.step(stepinto=self.stepinto)


class CyNext(CyStep):
    "Step-over Cython, Python or C code."

    name = 'cy -next'
    stepinto = False


class CyRun(CythonExecutionControlCommand):
    """
    Run a Cython program. This is like the 'run' command, except that it
    displays Cython or Python source lines as well
    """

    name = 'cy run'

    invoke = CythonExecutionControlCommand.run


class CyCont(CythonExecutionControlCommand):
    """
    Continue a Cython program. This is like the 'run' command, except that it
    displays Cython or Python source lines as well.
    """

    name = 'cy cont'
    invoke = CythonExecutionControlCommand.cont


class CyFinish(CythonExecutionControlCommand):
    """
    Execute until the function returns.
    """
    name = 'cy finish'

    invoke = CythonExecutionControlCommand.finish


class CyUp(CythonCommand):
    """
    Go up a Cython, Python or relevant C frame.
    """
    name = 'cy up'
    _command = 'up'

    def invoke(self, *args):
        try:
            gdb.execute(self._command, to_string=True)
            while not self.is_relevant_function(gdb.selected_frame()):
                gdb.execute(self._command, to_string=True)
        except RuntimeError, e:
            raise gdb.GdbError(*e.args)

        frame = gdb.selected_frame()
        index = 0
        while frame:
            frame = frame.older()
            index += 1

        self.print_stackframe(index=index - 1)


class CyDown(CyUp):
    """
    Go down a Cython, Python or relevant C frame.
    """

    name = 'cy down'
    _command = 'down'


class CySelect(CythonCommand):
    """
    Select a frame. Use frame numbers as listed in `cy backtrace`.
    This command is useful because `cy backtrace` prints a reversed backtrace.
    """

    name = 'cy select'

    def invoke(self, stackno, from_tty):
        try:
            stackno = int(stackno)
        except ValueError:
            raise gdb.GdbError("Not a valid number: %r" % (stackno,))

        frame = gdb.selected_frame()
        while frame.newer():
            frame = frame.newer()

        stackdepth = libpython.stackdepth(frame)

        try:
            gdb.execute('select %d' % (stackdepth - stackno - 1,))
        except RuntimeError, e:
            raise gdb.GdbError(*e.args)


class CyBacktrace(CythonCommand):
    'Print the Cython stack'

    name = 'cy bt'
    alias = 'cy backtrace'
    command_class = gdb.COMMAND_STACK
    completer_class = gdb.COMPLETE_NONE

    @require_running_program
    def invoke(self, args, from_tty):
        # get the first frame
        frame = gdb.selected_frame()
        while frame.older():
            frame = frame.older()

        print_all = args == '-a'

        index = 0
        while frame:
            try:
                is_relevant = self.is_relevant_function(frame)
            except CyGDBError:
                is_relevant = False

            if print_all or is_relevant:
                self.print_stackframe(frame, index)

            index += 1
            frame = frame.newer()


class CyList(CythonCommand):
    """
    List Cython source code. To disable to customize colouring see the cy_*
    parameters.
    """

    name = 'cy list'
    command_class = gdb.COMMAND_FILES
    completer_class = gdb.COMPLETE_NONE

    # @dispatch_on_frame(c_command='list')
    def invoke(self, _, from_tty):
        sd, lineno = self.get_source_desc()
        source = sd.get_source(lineno - 5, lineno + 5, mark_line=lineno,
                               lex_entire=True)
        print source


class CyPrint(CythonCommand):
    """
    Print a Cython variable using 'cy-print x' or 'cy-print module.function.x'
    """

    name = 'cy print'
    command_class = gdb.COMMAND_DATA

    def invoke(self, name, from_tty, max_name_length=None):
        if self.is_python_function():
            return gdb.execute('py-print ' + name)
        elif self.is_cython_function():
            value = self.cy.cy_cvalue.invoke(name.lstrip('*'))
            for c in name:
                if c == '*':
                    value = value.dereference()
                else:
                    break

            self.print_gdb_value(name, value, max_name_length)
        else:
            gdb.execute('print ' + name)

    def complete(self):
        if self.is_cython_function():
            f = self.get_cython_function()
            return list(itertools.chain(f.locals, f.globals))
        else:
            return []


sortkey = lambda (name, value): name.lower()

class CyLocals(CythonCommand):
    """
    List the locals from the current Cython frame.
    """

    name = 'cy locals'
    command_class = gdb.COMMAND_STACK
    completer_class = gdb.COMPLETE_NONE

    @dispatch_on_frame(c_command='info locals', python_command='py-locals')
    def invoke(self, args, from_tty):
        cython_function = self.get_cython_function()

        if cython_function.is_initmodule_function:
            self.cy.globals.invoke(args, from_tty)
            return

        local_cython_vars = cython_function.locals
        max_name_length = len(max(local_cython_vars, key=len))
        for name, cyvar in sorted(local_cython_vars.iteritems(), key=sortkey):
            if self.is_initialized(self.get_cython_function(), cyvar.name):
                value = gdb.parse_and_eval(cyvar.cname)
                if not value.is_optimized_out:
                    self.print_gdb_value(cyvar.name, value,
                                         max_name_length, '')


class CyGlobals(CyLocals):
    """
    List the globals from the current Cython module.
    """

    name = 'cy globals'
    command_class = gdb.COMMAND_STACK
    completer_class = gdb.COMPLETE_NONE

    @dispatch_on_frame(c_command='info variables', python_command='py-globals')
    def invoke(self, args, from_tty):
        global_python_dict = self.get_cython_globals_dict()
        module_globals = self.get_cython_function().module.globals

        max_globals_len = 0
        max_globals_dict_len = 0
        if module_globals:
            max_globals_len = len(max(module_globals, key=len))
        if global_python_dict:
            max_globals_dict_len = len(max(global_python_dict))

        max_name_length = max(max_globals_len, max_globals_dict_len)

        seen = set()
        print 'Python globals:'
        for k, v in sorted(global_python_dict.iteritems(), key=sortkey):
            v = v.get_truncated_repr(libpython.MAX_OUTPUT_LEN)
            seen.add(k)
            print '    %-*s = %s' % (max_name_length, k, v)

        print 'C globals:'
        for name, cyvar in sorted(module_globals.iteritems(), key=sortkey):
            if name not in seen:
                try:
                    value = gdb.parse_and_eval(cyvar.cname)
                except RuntimeError:
                    pass
                else:
                    if not value.is_optimized_out:
                        self.print_gdb_value(cyvar.name, value,
                                             max_name_length, '    ')



class EvaluateOrExecuteCodeMixin(object):
    """
    Evaluate or execute Python code in a Cython or Python frame. The 'evalcode'
    method evaluations Python code, prints a traceback if an exception went
    uncaught, and returns any return value as a gdb.Value (NULL on exception).
    """

    def _fill_locals_dict(self, executor, local_dict_pointer):
        "Fill a remotely allocated dict with values from the Cython C stack"
        cython_func = self.get_cython_function()

        for name, cyvar in cython_func.locals.iteritems():
            if (cyvar.type == PythonObject and
                self.is_initialized(cython_func, name)):

                try:
                    val = gdb.parse_and_eval(cyvar.cname)
                except RuntimeError:
                    continue
                else:
                    if val.is_optimized_out:
                        continue

                pystringp = executor.alloc_pystring(name)
                code = '''
                    (PyObject *) PyDict_SetItem(
                        (PyObject *) %d,
                        (PyObject *) %d,
                        (PyObject *) %s)
                ''' % (local_dict_pointer, pystringp, cyvar.cname)

                try:
                    if gdb.parse_and_eval(code) < 0:
                        gdb.parse_and_eval('PyErr_Print()')
                        raise gdb.GdbError("Unable to execute Python code.")
                finally:
                    # PyDict_SetItem doesn't steal our reference
                    executor.xdecref(pystringp)

    def _find_first_cython_or_python_frame(self):
        frame = gdb.selected_frame()
        while frame:
            if (self.is_cython_function(frame) or
                self.is_python_function(frame)):
                frame.select()
                return frame

            frame = frame.older()

        raise gdb.GdbError("There is no Cython or Python frame on the stack.")


    def _evalcode_cython(self, executor, code, input_type):
        with libpython.FetchAndRestoreError():
            # get the dict of Cython globals and construct a dict in the
            # inferior with Cython locals
            global_dict = gdb.parse_and_eval(
                '(PyObject *) PyModule_GetDict(__pyx_m)')
            local_dict = gdb.parse_and_eval('(PyObject *) PyDict_New()')

            try:
                self._fill_locals_dict(executor,
                                       libpython.pointervalue(local_dict))
                result = executor.evalcode(code, input_type, global_dict,
                                           local_dict)
            finally:
                executor.xdecref(libpython.pointervalue(local_dict))

        return result

    def evalcode(self, code, input_type):
        """
        Evaluate `code` in a Python or Cython stack frame using the given
        `input_type`.
        """
        frame = self._find_first_cython_or_python_frame()
        executor = libpython.PythonCodeExecutor()
        if self.is_python_function(frame):
            return libpython._evalcode_python(executor, code, input_type)
        return self._evalcode_cython(executor, code, input_type)


class CyExec(CythonCommand, libpython.PyExec, EvaluateOrExecuteCodeMixin):
    """
    Execute Python code in the nearest Python or Cython frame.
    """

    name = '-cy-exec'
    command_class = gdb.COMMAND_STACK
    completer_class = gdb.COMPLETE_NONE

    def invoke(self, expr, from_tty):
        expr, input_type = self.readcode(expr)
        executor = libpython.PythonCodeExecutor()
        executor.xdecref(self.evalcode(expr, executor.Py_single_input))


class CySet(CythonCommand):
    """
    Set a Cython variable to a certain value

        cy set my_cython_c_variable = 10
        cy set my_cython_py_variable = $cy_eval("{'doner': 'kebab'}")

    This is equivalent to

        set $cy_value("my_cython_variable") = 10
    """

    name = 'cy set'
    command_class = gdb.COMMAND_DATA
    completer_class = gdb.COMPLETE_NONE

    @require_cython_frame
    def invoke(self, expr, from_tty):
        name_and_expr = expr.split('=', 1)
        if len(name_and_expr) != 2:
            raise gdb.GdbError("Invalid expression. Use 'cy set var = expr'.")

        varname, expr = name_and_expr
        cname = self.cy.cy_cname.invoke(varname.strip())
        gdb.execute("set %s = %s" % (cname, expr))


# Functions

class CyCName(gdb.Function, CythonBase):
    """
    Get the C name of a Cython variable in the current context.
    Examples:

        print $cy_cname("function")
        print $cy_cname("Class.method")
        print $cy_cname("module.function")
    """

    @require_cython_frame
    @gdb_function_value_to_unicode
    def invoke(self, cyname, frame=None):
        frame = frame or gdb.selected_frame()
        cname = None

        if self.is_cython_function(frame):
            cython_function = self.get_cython_function(frame)
            if cyname in cython_function.locals:
                cname = cython_function.locals[cyname].cname
            elif cyname in cython_function.module.globals:
                cname = cython_function.module.globals[cyname].cname
            else:
                qname = '%s.%s' % (cython_function.module.name, cyname)
                if qname in cython_function.module.functions:
                    cname = cython_function.module.functions[qname].cname

        if not cname:
            cname = self.cy.functions_by_qualified_name.get(cyname)

        if not cname:
            raise gdb.GdbError('No such Cython variable: %s' % cyname)

        return cname


class CyCValue(CyCName):
    """
    Get the value of a Cython variable.
    """

    @require_cython_frame
    @gdb_function_value_to_unicode
    def invoke(self, cyname, frame=None):
        globals_dict = self.get_cython_globals_dict()
        cython_function = self.get_cython_function(frame)

        if self.is_initialized(cython_function, cyname):
            cname = super(CyCValue, self).invoke(cyname, frame=frame)
            return gdb.parse_and_eval(cname)
        elif cyname in globals_dict:
            return globals_dict[cyname]._gdbval
        else:
            raise gdb.GdbError("Variable %s is not initialized." % cyname)


class CyLine(gdb.Function, CythonBase):
    """
    Get the current Cython line.
    """

    @require_cython_frame
    def invoke(self):
        return self.get_cython_lineno()


class CyEval(gdb.Function, CythonBase, EvaluateOrExecuteCodeMixin):
    """
    Evaluate Python code in the nearest Python or Cython frame and return
    """

    @gdb_function_value_to_unicode
    def invoke(self, python_expression):
        input_type = libpython.PythonCodeExecutor.Py_eval_input
        return self.evalcode(python_expression, input_type)


cython_info = CythonInfo()
cy = CyCy.register()
cython_info.cy = cy

def register_defines():
    libpython.source_gdb_script(textwrap.dedent("""\
        define cy step
        cy -step
        end

        define cy next
        cy -next
        end

        document cy step
        %s
        end

        document cy next
        %s
        end
    """) % (CyStep.__doc__, CyNext.__doc__))

register_defines()
