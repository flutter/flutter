#
#   Cython Top Level
#

import os, sys, re, codecs
if sys.version_info[:2] < (2, 4):
    sys.stderr.write("Sorry, Cython requires Python 2.4 or later\n")
    sys.exit(1)

import Errors
# Do not import Parsing here, import it when needed, because Parsing imports
# Nodes, which globally needs debug command line options initialized to set a
# conditional metaclass. These options are processed by CmdLine called from
# main() in this file.
# import Parsing
import Version
from Scanning import PyrexScanner, FileSourceDescriptor
from Errors import PyrexError, CompileError, error, warning
from Symtab import ModuleScope
from Cython import Utils
import Options

module_name_pattern = re.compile(r"[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)*$")

verbose = 0

class CompilationData(object):
    #  Bundles the information that is passed from transform to transform.
    #  (For now, this is only)

    #  While Context contains every pxd ever loaded, path information etc.,
    #  this only contains the data related to a single compilation pass
    #
    #  pyx                   ModuleNode              Main code tree of this compilation.
    #  pxds                  {string : ModuleNode}   Trees for the pxds used in the pyx.
    #  codewriter            CCodeWriter             Where to output final code.
    #  options               CompilationOptions
    #  result                CompilationResult
    pass

class Context(object):
    #  This class encapsulates the context needed for compiling
    #  one or more Cython implementation files along with their
    #  associated and imported declaration files. It includes
    #  the root of the module import namespace and the list
    #  of directories to search for include files.
    #
    #  modules               {string : ModuleScope}
    #  include_directories   [string]
    #  future_directives     [object]
    #  language_level        int     currently 2 or 3 for Python 2/3

    cython_scope = None

    def __init__(self, include_directories, compiler_directives, cpp=False,
                 language_level=2, options=None, create_testscope=True):
        # cython_scope is a hack, set to False by subclasses, in order to break
        # an infinite loop.
        # Better code organization would fix it.

        import Builtin, CythonScope
        self.modules = {"__builtin__" : Builtin.builtin_scope}
        self.cython_scope = CythonScope.create_cython_scope(self)
        self.modules["cython"] = self.cython_scope
        self.include_directories = include_directories
        self.future_directives = set()
        self.compiler_directives = compiler_directives
        self.cpp = cpp
        self.options = options

        self.pxds = {} # full name -> node tree

        standard_include_path = os.path.abspath(os.path.normpath(
            os.path.join(os.path.dirname(__file__), os.path.pardir, 'Includes')))
        self.include_directories = include_directories + [standard_include_path]

        self.set_language_level(language_level)

        self.gdb_debug_outputwriter = None

    def set_language_level(self, level):
        self.language_level = level
        if level >= 3:
            from Future import print_function, unicode_literals, absolute_import
            self.future_directives.update([print_function, unicode_literals, absolute_import])
            self.modules['builtins'] = self.modules['__builtin__']

    # pipeline creation functions can now be found in Pipeline.py

    def process_pxd(self, source_desc, scope, module_name):
        import Pipeline
        if isinstance(source_desc, FileSourceDescriptor) and source_desc._file_type == 'pyx':
            source = CompilationSource(source_desc, module_name, os.getcwd())
            result_sink = create_default_resultobj(source, self.options)
            pipeline = Pipeline.create_pyx_as_pxd_pipeline(self, result_sink)
            result = Pipeline.run_pipeline(pipeline, source)
        else:
            pipeline = Pipeline.create_pxd_pipeline(self, scope, module_name)
            result = Pipeline.run_pipeline(pipeline, source_desc)
        return result

    def nonfatal_error(self, exc):
        return Errors.report_error(exc)

    def find_module(self, module_name,
            relative_to = None, pos = None, need_pxd = 1, check_module_name = True):
        # Finds and returns the module scope corresponding to
        # the given relative or absolute module name. If this
        # is the first time the module has been requested, finds
        # the corresponding .pxd file and process it.
        # If relative_to is not None, it must be a module scope,
        # and the module will first be searched for relative to
        # that module, provided its name is not a dotted name.
        debug_find_module = 0
        if debug_find_module:
            print("Context.find_module: module_name = %s, relative_to = %s, pos = %s, need_pxd = %s" % (
                    module_name, relative_to, pos, need_pxd))

        scope = None
        pxd_pathname = None
        if check_module_name and not module_name_pattern.match(module_name):
            if pos is None:
                pos = (module_name, 0, 0)
            raise CompileError(pos,
                "'%s' is not a valid module name" % module_name)
        if "." not in module_name and relative_to:
            if debug_find_module:
                print("...trying relative import")
            scope = relative_to.lookup_submodule(module_name)
            if not scope:
                qualified_name = relative_to.qualify_name(module_name)
                pxd_pathname = self.find_pxd_file(qualified_name, pos)
                if pxd_pathname:
                    scope = relative_to.find_submodule(module_name)
        if not scope:
            if debug_find_module:
                print("...trying absolute import")
            scope = self
            for name in module_name.split("."):
                scope = scope.find_submodule(name)
        if debug_find_module:
            print("...scope =", scope)
        if not scope.pxd_file_loaded:
            if debug_find_module:
                print("...pxd not loaded")
            scope.pxd_file_loaded = 1
            if not pxd_pathname:
                if debug_find_module:
                    print("...looking for pxd file")
                pxd_pathname = self.find_pxd_file(module_name, pos)
                if debug_find_module:
                    print("......found ", pxd_pathname)
                if not pxd_pathname and need_pxd:
                    package_pathname = self.search_include_directories(module_name, ".py", pos)
                    if package_pathname and package_pathname.endswith('__init__.py'):
                        pass
                    else:
                        error(pos, "'%s.pxd' not found" % module_name)
            if pxd_pathname:
                try:
                    if debug_find_module:
                        print("Context.find_module: Parsing %s" % pxd_pathname)
                    rel_path = module_name.replace('.', os.sep) + os.path.splitext(pxd_pathname)[1]
                    if not pxd_pathname.endswith(rel_path):
                        rel_path = pxd_pathname # safety measure to prevent printing incorrect paths
                    source_desc = FileSourceDescriptor(pxd_pathname, rel_path)
                    err, result = self.process_pxd(source_desc, scope, module_name)
                    if err:
                        raise err
                    (pxd_codenodes, pxd_scope) = result
                    self.pxds[module_name] = (pxd_codenodes, pxd_scope)
                except CompileError:
                    pass
        return scope

    def find_pxd_file(self, qualified_name, pos):
        # Search include path for the .pxd file corresponding to the
        # given fully-qualified module name.
        # Will find either a dotted filename or a file in a
        # package directory. If a source file position is given,
        # the directory containing the source file is searched first
        # for a dotted filename, and its containing package root
        # directory is searched first for a non-dotted filename.
        pxd = self.search_include_directories(qualified_name, ".pxd", pos, sys_path=True)
        if pxd is None: # XXX Keep this until Includes/Deprecated is removed
            if (qualified_name.startswith('python') or
                qualified_name in ('stdlib', 'stdio', 'stl')):
                standard_include_path = os.path.abspath(os.path.normpath(
                        os.path.join(os.path.dirname(__file__), os.path.pardir, 'Includes')))
                deprecated_include_path = os.path.join(standard_include_path, 'Deprecated')
                self.include_directories.append(deprecated_include_path)
                try:
                    pxd = self.search_include_directories(qualified_name, ".pxd", pos)
                finally:
                    self.include_directories.pop()
                if pxd:
                    name = qualified_name
                    if name.startswith('python'):
                        warning(pos, "'%s' is deprecated, use 'cpython'" % name, 1)
                    elif name in ('stdlib', 'stdio'):
                        warning(pos, "'%s' is deprecated, use 'libc.%s'" % (name, name), 1)
                    elif name in ('stl'):
                        warning(pos, "'%s' is deprecated, use 'libcpp.*.*'" % name, 1)
        if pxd is None and Options.cimport_from_pyx:
            return self.find_pyx_file(qualified_name, pos)
        return pxd

    def find_pyx_file(self, qualified_name, pos):
        # Search include path for the .pyx file corresponding to the
        # given fully-qualified module name, as for find_pxd_file().
        return self.search_include_directories(qualified_name, ".pyx", pos)

    def find_include_file(self, filename, pos):
        # Search list of include directories for filename.
        # Reports an error and returns None if not found.
        path = self.search_include_directories(filename, "", pos,
                                               include=True)
        if not path:
            error(pos, "'%s' not found" % filename)
        return path

    def search_include_directories(self, qualified_name, suffix, pos,
                                   include=False, sys_path=False):
        return Utils.search_include_directories(
            tuple(self.include_directories), qualified_name, suffix, pos, include, sys_path)

    def find_root_package_dir(self, file_path):
        return Utils.find_root_package_dir(file_path)

    def check_package_dir(self, dir, package_names):
        return Utils.check_package_dir(dir, tuple(package_names))

    def c_file_out_of_date(self, source_path):
        c_path = Utils.replace_suffix(source_path, ".c")
        if not os.path.exists(c_path):
            return 1
        c_time = Utils.modification_time(c_path)
        if Utils.file_newer_than(source_path, c_time):
            return 1
        pos = [source_path]
        pxd_path = Utils.replace_suffix(source_path, ".pxd")
        if os.path.exists(pxd_path) and Utils.file_newer_than(pxd_path, c_time):
            return 1
        for kind, name in self.read_dependency_file(source_path):
            if kind == "cimport":
                dep_path = self.find_pxd_file(name, pos)
            elif kind == "include":
                dep_path = self.search_include_directories(name, pos)
            else:
                continue
            if dep_path and Utils.file_newer_than(dep_path, c_time):
                return 1
        return 0

    def find_cimported_module_names(self, source_path):
        return [ name for kind, name in self.read_dependency_file(source_path)
                 if kind == "cimport" ]

    def is_package_dir(self, dir_path):
        return Utils.is_package_dir(dir_path)

    def read_dependency_file(self, source_path):
        dep_path = Utils.replace_suffix(source_path, ".dep")
        if os.path.exists(dep_path):
            f = open(dep_path, "rU")
            chunks = [ line.strip().split(" ", 1)
                       for line in f.readlines()
                       if " " in line.strip() ]
            f.close()
            return chunks
        else:
            return ()

    def lookup_submodule(self, name):
        # Look up a top-level module. Returns None if not found.
        return self.modules.get(name, None)

    def find_submodule(self, name):
        # Find a top-level module, creating a new one if needed.
        scope = self.lookup_submodule(name)
        if not scope:
            scope = ModuleScope(name,
                parent_module = None, context = self)
            self.modules[name] = scope
        return scope

    def parse(self, source_desc, scope, pxd, full_module_name):
        if not isinstance(source_desc, FileSourceDescriptor):
            raise RuntimeError("Only file sources for code supported")
        source_filename = source_desc.filename
        scope.cpp = self.cpp
        # Parse the given source file and return a parse tree.
        num_errors = Errors.num_errors
        try:
            f = Utils.open_source_file(source_filename, "rU")
            try:
                import Parsing
                s = PyrexScanner(f, source_desc, source_encoding = f.encoding,
                                 scope = scope, context = self)
                tree = Parsing.p_module(s, pxd, full_module_name)
            finally:
                f.close()
        except UnicodeDecodeError, e:
            #import traceback
            #traceback.print_exc()
            line = 1
            column = 0
            msg = e.args[-1]
            position = e.args[2]
            encoding = e.args[0]

            f = open(source_filename, "rb")
            try:
                byte_data = f.read()
            finally:
                f.close()

            # FIXME: make this at least a little less inefficient
            for idx, c in enumerate(byte_data):
                if c in (ord('\n'), '\n'):
                    line += 1
                    column = 0
                if idx == position:
                    break

                column += 1

            error((source_desc, line, column),
                  "Decoding error, missing or incorrect coding=<encoding-name> "
                  "at top of source (cannot decode with encoding %r: %s)" % (encoding, msg))

        if Errors.num_errors > num_errors:
            raise CompileError()
        return tree

    def extract_module_name(self, path, options):
        # Find fully_qualified module name from the full pathname
        # of a source file.
        dir, filename = os.path.split(path)
        module_name, _ = os.path.splitext(filename)
        if "." in module_name:
            return module_name
        names = [module_name]
        while self.is_package_dir(dir):
            parent, package_name = os.path.split(dir)
            if parent == dir:
                break
            names.append(package_name)
            dir = parent
        names.reverse()
        return ".".join(names)

    def setup_errors(self, options, result):
        Errors.reset() # clear any remaining error state
        if options.use_listing_file:
            result.listing_file = Utils.replace_suffix(source, ".lis")
            path = result.listing_file
        else:
            path = None
        Errors.open_listing_file(path=path,
                                 echo_to_stderr=options.errors_to_stderr)

    def teardown_errors(self, err, options, result):
        source_desc = result.compilation_source.source_desc
        if not isinstance(source_desc, FileSourceDescriptor):
            raise RuntimeError("Only file sources for code supported")
        Errors.close_listing_file()
        result.num_errors = Errors.num_errors
        if result.num_errors > 0:
            err = True
        if err and result.c_file:
            try:
                Utils.castrate_file(result.c_file, os.stat(source_desc.filename))
            except EnvironmentError:
                pass
            result.c_file = None

def create_default_resultobj(compilation_source, options):
    result = CompilationResult()
    result.main_source_file = compilation_source.source_desc.filename
    result.compilation_source = compilation_source
    source_desc = compilation_source.source_desc
    if options.output_file:
        result.c_file = os.path.join(compilation_source.cwd, options.output_file)
    else:
        if options.cplus:
            c_suffix = ".cpp"
        else:
            c_suffix = ".c"
        result.c_file = Utils.replace_suffix(source_desc.filename, c_suffix)
    return result

def run_pipeline(source, options, full_module_name=None, context=None):
    import Pipeline

    source_ext = os.path.splitext(source)[1]
    options.configure_language_defaults(source_ext[1:]) # py/pyx
    if context is None:
        context = options.create_context()

    # Set up source object
    cwd = os.getcwd()
    abs_path = os.path.abspath(source)
    full_module_name = full_module_name or context.extract_module_name(source, options)

    if options.relative_path_in_code_position_comments:
        rel_path = full_module_name.replace('.', os.sep) + source_ext
        if not abs_path.endswith(rel_path):
            rel_path = source # safety measure to prevent printing incorrect paths
    else:
        rel_path = abs_path
    source_desc = FileSourceDescriptor(abs_path, rel_path)
    source = CompilationSource(source_desc, full_module_name, cwd)

    # Set up result object
    result = create_default_resultobj(source, options)

    if options.annotate is None:
        # By default, decide based on whether an html file already exists.
        html_filename = os.path.splitext(result.c_file)[0] + ".html"
        if os.path.exists(html_filename):
            line = codecs.open(html_filename, "r", encoding="UTF-8").readline()
            if line.startswith(u'<!-- Generated by Cython'):
                options.annotate = True

    # Get pipeline
    if source_ext.lower() == '.py' or not source_ext:
        pipeline = Pipeline.create_py_pipeline(context, options, result)
    else:
        pipeline = Pipeline.create_pyx_pipeline(context, options, result)

    context.setup_errors(options, result)
    err, enddata = Pipeline.run_pipeline(pipeline, source)
    context.teardown_errors(err, options, result)
    return result


#------------------------------------------------------------------------
#
#  Main Python entry points
#
#------------------------------------------------------------------------

class CompilationSource(object):
    """
    Contains the data necesarry to start up a compilation pipeline for
    a single compilation unit.
    """
    def __init__(self, source_desc, full_module_name, cwd):
        self.source_desc = source_desc
        self.full_module_name = full_module_name
        self.cwd = cwd

class CompilationOptions(object):
    """
    Options to the Cython compiler:

    show_version      boolean   Display version number
    use_listing_file  boolean   Generate a .lis file
    errors_to_stderr  boolean   Echo errors to stderr when using .lis
    include_path      [string]  Directories to search for include files
    output_file       string    Name of generated .c file
    generate_pxi      boolean   Generate .pxi file for public declarations
    capi_reexport_cincludes  
                      boolean   Add cincluded headers to any auto-generated 
                                header files.
    timestamps        boolean   Only compile changed source files.
    verbose           boolean   Always print source names being compiled
    compiler_directives  dict      Overrides for pragma options (see Options.py)
    evaluate_tree_assertions boolean  Test support: evaluate parse tree assertions
    language_level    integer   The Python language level: 2 or 3

    cplus             boolean   Compile as c++ code
    """

    def __init__(self, defaults = None, **kw):
        self.include_path = []
        if defaults:
            if isinstance(defaults, CompilationOptions):
                defaults = defaults.__dict__
        else:
            defaults = default_options

        options = dict(defaults)
        options.update(kw)

        directives = dict(options['compiler_directives']) # copy mutable field
        options['compiler_directives'] = directives
        if 'language_level' in directives and 'language_level' not in kw:
            options['language_level'] = int(directives['language_level'])
        if 'cache' in options:
            if options['cache'] is True:
                options['cache'] = os.path.expanduser("~/.cycache")
            elif options['cache'] in (False, None):
                del options['cache']

        self.__dict__.update(options)

    def configure_language_defaults(self, source_extension):
        if source_extension == 'py':
            if self.compiler_directives.get('binding') is None:
                self.compiler_directives['binding'] = True

    def create_context(self):
        return Context(self.include_path, self.compiler_directives,
                       self.cplus, self.language_level, options=self)


class CompilationResult(object):
    """
    Results from the Cython compiler:

    c_file           string or None   The generated C source file
    h_file           string or None   The generated C header file
    i_file           string or None   The generated .pxi file
    api_file         string or None   The generated C API .h file
    listing_file     string or None   File of error messages
    object_file      string or None   Result of compiling the C file
    extension_file   string or None   Result of linking the object file
    num_errors       integer          Number of compilation errors
    compilation_source CompilationSource
    """

    def __init__(self):
        self.c_file = None
        self.h_file = None
        self.i_file = None
        self.api_file = None
        self.listing_file = None
        self.object_file = None
        self.extension_file = None
        self.main_source_file = None


class CompilationResultSet(dict):
    """
    Results from compiling multiple Pyrex source files. A mapping
    from source file paths to CompilationResult instances. Also
    has the following attributes:

    num_errors   integer   Total number of compilation errors
    """

    num_errors = 0

    def add(self, source, result):
        self[source] = result
        self.num_errors += result.num_errors


def compile_single(source, options, full_module_name = None):
    """
    compile_single(source, options, full_module_name)

    Compile the given Pyrex implementation file and return a CompilationResult.
    Always compiles a single file; does not perform timestamp checking or
    recursion.
    """
    return run_pipeline(source, options, full_module_name)


def compile_multiple(sources, options):
    """
    compile_multiple(sources, options)

    Compiles the given sequence of Pyrex implementation files and returns
    a CompilationResultSet. Performs timestamp checking and/or recursion
    if these are specified in the options.
    """
    # run_pipeline creates the context
    # context = options.create_context()
    sources = [os.path.abspath(source) for source in sources]
    processed = set()
    results = CompilationResultSet()
    timestamps = options.timestamps
    verbose = options.verbose
    context = None
    for source in sources:
        if source not in processed:
            if context is None:
                context = options.create_context()
            if not timestamps or context.c_file_out_of_date(source):
                if verbose:
                    sys.stderr.write("Compiling %s\n" % source)

                result = run_pipeline(source, options, context=context)
                results.add(source, result)
                # Compiling multiple sources in one context doesn't quite
                # work properly yet.
                context = None
            processed.add(source)
    return results

def compile(source, options = None, full_module_name = None, **kwds):
    """
    compile(source [, options], [, <option> = <value>]...)

    Compile one or more Pyrex implementation files, with optional timestamp
    checking and recursing on dependecies. The source argument may be a string
    or a sequence of strings If it is a string and no recursion or timestamp
    checking is requested, a CompilationResult is returned, otherwise a
    CompilationResultSet is returned.
    """
    options = CompilationOptions(defaults = options, **kwds)
    if isinstance(source, basestring) and not options.timestamps:
        return compile_single(source, options, full_module_name)
    else:
        return compile_multiple(source, options)

#------------------------------------------------------------------------
#
#  Main command-line entry point
#
#------------------------------------------------------------------------
def setuptools_main():
    return main(command_line = 1)

def main(command_line = 0):
    args = sys.argv[1:]
    any_failures = 0
    if command_line:
        from CmdLine import parse_command_line
        options, sources = parse_command_line(args)
    else:
        options = CompilationOptions(default_options)
        sources = args

    if options.show_version:
        sys.stderr.write("Cython version %s\n" % Version.version)
    if options.working_path!="":
        os.chdir(options.working_path)
    try:
        result = compile(sources, options)
        if result.num_errors > 0:
            any_failures = 1
    except (EnvironmentError, PyrexError), e:
        sys.stderr.write(str(e) + '\n')
        any_failures = 1
    if any_failures:
        sys.exit(1)



#------------------------------------------------------------------------
#
#  Set the default options depending on the platform
#
#------------------------------------------------------------------------

default_options = dict(
    show_version = 0,
    use_listing_file = 0,
    errors_to_stderr = 1,
    cplus = 0,
    output_file = None,
    annotate = None,
    generate_pxi = 0,
    capi_reexport_cincludes = 0,
    working_path = "",
    timestamps = None,
    verbose = 0,
    quiet = 0,
    compiler_directives = {},
    evaluate_tree_assertions = False,
    emit_linenums = False,
    relative_path_in_code_position_comments = True,
    c_line_in_traceback = True,
    language_level = 2,
    gdb_debug = False,
    compile_time_env = None,
    common_utility_include_dir = None,
)
