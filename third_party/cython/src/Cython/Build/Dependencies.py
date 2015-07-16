import cython
from Cython import __version__

import re, os, sys, time
try:
    from glob import iglob
except ImportError:
    # Py2.4
    from glob import glob as iglob

try:
    import gzip
    gzip_open = gzip.open
    gzip_ext = '.gz'
except ImportError:
    gzip_open = open
    gzip_ext = ''
import shutil
import subprocess

try:
    import hashlib
except ImportError:
    import md5 as hashlib

try:
    from io import open as io_open
except ImportError:
    from codecs import open as io_open

try:
    from os.path import relpath as _relpath
except ImportError:
    # Py<2.6
    def _relpath(path, start=os.path.curdir):
        if not path:
            raise ValueError("no path specified")
        start_list = os.path.abspath(start).split(os.path.sep)
        path_list = os.path.abspath(path).split(os.path.sep)
        i = len(os.path.commonprefix([start_list, path_list]))
        rel_list = [os.path.pardir] * (len(start_list)-i) + path_list[i:]
        if not rel_list:
            return os.path.curdir
        return os.path.join(*rel_list)


from distutils.extension import Extension

from Cython import Utils
from Cython.Utils import cached_function, cached_method, path_exists, find_root_package_dir
from Cython.Compiler.Main import Context, CompilationOptions, default_options

join_path = cached_function(os.path.join)

if sys.version_info[0] < 3:
    # stupid Py2 distutils enforces str type in list of sources
    _fs_encoding = sys.getfilesystemencoding()
    if _fs_encoding is None:
        _fs_encoding = sys.getdefaultencoding()
    def encode_filename_in_py2(filename):
        if isinstance(filename, unicode):
            return filename.encode(_fs_encoding)
        return filename
else:
    def encode_filename_in_py2(filename):
        return filename
    basestring = str

def extended_iglob(pattern):
    if '**/' in pattern:
        seen = set()
        first, rest = pattern.split('**/', 1)
        if first:
            first = iglob(first+'/')
        else:
            first = ['']
        for root in first:
            for path in extended_iglob(join_path(root, rest)):
                if path not in seen:
                    seen.add(path)
                    yield path
            for path in extended_iglob(join_path(root, '*', '**/' + rest)):
                if path not in seen:
                    seen.add(path)
                    yield path
    else:
        for path in iglob(pattern):
            yield path

@cached_function
def file_hash(filename):
    path = os.path.normpath(filename.encode("UTF-8"))
    m = hashlib.md5(str(len(path)) + ":")
    m.update(path)
    f = open(filename, 'rb')
    try:
        data = f.read(65000)
        while data:
            m.update(data)
            data = f.read(65000)
    finally:
        f.close()
    return m.hexdigest()

def parse_list(s):
    """
    >>> parse_list("a b c")
    ['a', 'b', 'c']
    >>> parse_list("[a, b, c]")
    ['a', 'b', 'c']
    >>> parse_list('a " " b')
    ['a', ' ', 'b']
    >>> parse_list('[a, ",a", "a,", ",", ]')
    ['a', ',a', 'a,', ',']
    """
    if s[0] == '[' and s[-1] == ']':
        s = s[1:-1]
        delimiter = ','
    else:
        delimiter = ' '
    s, literals = strip_string_literals(s)
    def unquote(literal):
        literal = literal.strip()
        if literal[0] in "'\"":
            return literals[literal[1:-1]]
        else:
            return literal
    return [unquote(item) for item in s.split(delimiter) if item.strip()]

transitive_str = object()
transitive_list = object()

distutils_settings = {
    'name':                 str,
    'sources':              list,
    'define_macros':        list,
    'undef_macros':         list,
    'libraries':            transitive_list,
    'library_dirs':         transitive_list,
    'runtime_library_dirs': transitive_list,
    'include_dirs':         transitive_list,
    'extra_objects':        list,
    'extra_compile_args':   transitive_list,
    'extra_link_args':      transitive_list,
    'export_symbols':       list,
    'depends':              transitive_list,
    'language':             transitive_str,
}

@cython.locals(start=long, end=long)
def line_iter(source):
    if isinstance(source, basestring):
        start = 0
        while True:
            end = source.find('\n', start)
            if end == -1:
                yield source[start:]
                return
            yield source[start:end]
            start = end+1
    else:
        for line in source:
            yield line

class DistutilsInfo(object):

    def __init__(self, source=None, exn=None):
        self.values = {}
        if source is not None:
            for line in line_iter(source):
                line = line.strip()
                if line != '' and line[0] != '#':
                    break
                line = line[1:].strip()
                if line[:10] == 'distutils:':
                    line = line[10:]
                    ix = line.index('=')
                    key = str(line[:ix].strip())
                    value = line[ix+1:].strip()
                    type = distutils_settings[key]
                    if type in (list, transitive_list):
                        value = parse_list(value)
                        if key == 'define_macros':
                            value = [tuple(macro.split('=')) for macro in value]
                    self.values[key] = value
        elif exn is not None:
            for key in distutils_settings:
                if key in ('name', 'sources'):
                    continue
                value = getattr(exn, key, None)
                if value:
                    self.values[key] = value

    def merge(self, other):
        if other is None:
            return self
        for key, value in other.values.items():
            type = distutils_settings[key]
            if type is transitive_str and key not in self.values:
                self.values[key] = value
            elif type is transitive_list:
                if key in self.values:
                    all = self.values[key]
                    for v in value:
                        if v not in all:
                            all.append(v)
                else:
                    self.values[key] = value
        return self

    def subs(self, aliases):
        if aliases is None:
            return self
        resolved = DistutilsInfo()
        for key, value in self.values.items():
            type = distutils_settings[key]
            if type in [list, transitive_list]:
                new_value_list = []
                for v in value:
                    if v in aliases:
                        v = aliases[v]
                    if isinstance(v, list):
                        new_value_list += v
                    else:
                        new_value_list.append(v)
                value = new_value_list
            else:
                if value in aliases:
                    value = aliases[value]
            resolved.values[key] = value
        return resolved

    def apply(self, extension):
        for key, value in self.values.items():
            type = distutils_settings[key]
            if type in [list, transitive_list]:
                getattr(extension, key).extend(value)
            else:
                setattr(extension, key, value)

@cython.locals(start=long, q=long, single_q=long, double_q=long, hash_mark=long,
               end=long, k=long, counter=long, quote_len=long)
def strip_string_literals(code, prefix='__Pyx_L'):
    """
    Normalizes every string literal to be of the form '__Pyx_Lxxx',
    returning the normalized code and a mapping of labels to
    string literals.
    """
    new_code = []
    literals = {}
    counter = 0
    start = q = 0
    in_quote = False
    hash_mark = single_q = double_q = -1
    code_len = len(code)

    while True:
        if hash_mark < q:
            hash_mark = code.find('#', q)
        if single_q < q:
            single_q = code.find("'", q)
        if double_q < q:
            double_q = code.find('"', q)
        q = min(single_q, double_q)
        if q == -1: q = max(single_q, double_q)

        # We're done.
        if q == -1 and hash_mark == -1:
            new_code.append(code[start:])
            break

        # Try to close the quote.
        elif in_quote:
            if code[q-1] == u'\\':
                k = 2
                while q >= k and code[q-k] == u'\\':
                    k += 1
                if k % 2 == 0:
                    q += 1
                    continue
            if code[q] == quote_type and (quote_len == 1 or (code_len > q + 2 and quote_type == code[q+1] == code[q+2])):
                counter += 1
                label = "%s%s_" % (prefix, counter)
                literals[label] = code[start+quote_len:q]
                full_quote = code[q:q+quote_len]
                new_code.append(full_quote)
                new_code.append(label)
                new_code.append(full_quote)
                q += quote_len
                in_quote = False
                start = q
            else:
                q += 1

        # Process comment.
        elif -1 != hash_mark and (hash_mark < q or q == -1):
            new_code.append(code[start:hash_mark+1])
            end = code.find('\n', hash_mark)
            counter += 1
            label = "%s%s_" % (prefix, counter)
            if end == -1:
                end_or_none = None
            else:
                end_or_none = end
            literals[label] = code[hash_mark+1:end_or_none]
            new_code.append(label)
            if end == -1:
                break
            start = q = end

        # Open the quote.
        else:
            if code_len >= q+3 and (code[q] == code[q+1] == code[q+2]):
                quote_len = 3
            else:
                quote_len = 1
            in_quote = True
            quote_type = code[q]
            new_code.append(code[start:q])
            start = q
            q += quote_len

    return "".join(new_code), literals


dependancy_regex = re.compile(r"(?:^from +([0-9a-zA-Z_.]+) +cimport)|"
                              r"(?:^cimport +([0-9a-zA-Z_.]+)\b)|"
                              r"(?:^cdef +extern +from +['\"]([^'\"]+)['\"])|"
                              r"(?:^include +['\"]([^'\"]+)['\"])", re.M)

def normalize_existing(base_path, rel_paths):
    return normalize_existing0(os.path.dirname(base_path), tuple(set(rel_paths)))

@cached_function
def normalize_existing0(base_dir, rel_paths):
    normalized = []
    for rel in rel_paths:
        path = join_path(base_dir, rel)
        if path_exists(path):
            normalized.append(os.path.normpath(path))
        else:
            normalized.append(rel)
    return normalized

def resolve_depends(depends, include_dirs):
    include_dirs = tuple(include_dirs)
    resolved = []
    for depend in depends:
        path = resolve_depend(depend, include_dirs)
        if path is not None:
            resolved.append(path)
    return resolved

@cached_function
def resolve_depend(depend, include_dirs):
    if depend[0] == '<' and depend[-1] == '>':
        return None
    for dir in include_dirs:
        path = join_path(dir, depend)
        if path_exists(path):
            return os.path.normpath(path)
    return None

@cached_function
def package(filename):
    dir = os.path.dirname(os.path.abspath(str(filename)))
    if dir != filename and path_exists(join_path(dir, '__init__.py')):
        return package(dir) + (os.path.basename(dir),)
    else:
        return ()

@cached_function
def fully_qualified_name(filename):
    module = os.path.splitext(os.path.basename(filename))[0]
    return '.'.join(package(filename) + (module,))


@cached_function
def parse_dependencies(source_filename):
    # Actual parsing is way to slow, so we use regular expressions.
    # The only catch is that we must strip comments and string
    # literals ahead of time.
    fh = Utils.open_source_file(source_filename, "rU", error_handling='ignore')
    try:
        source = fh.read()
    finally:
        fh.close()
    distutils_info = DistutilsInfo(source)
    source, literals = strip_string_literals(source)
    source = source.replace('\\\n', ' ').replace('\t', ' ')

    # TODO: pure mode
    cimports = []
    includes = []
    externs  = []
    for m in dependancy_regex.finditer(source):
        cimport_from, cimport, extern, include = m.groups()
        if cimport_from:
            cimports.append(cimport_from)
        elif cimport:
            cimports.append(cimport)
        elif extern:
            externs.append(literals[extern])
        else:
            includes.append(literals[include])
    return cimports, includes, externs, distutils_info


class DependencyTree(object):

    def __init__(self, context, quiet=False):
        self.context = context
        self.quiet = quiet
        self._transitive_cache = {}

    def parse_dependencies(self, source_filename):
        return parse_dependencies(source_filename)

    @cached_method
    def included_files(self, filename):
        # This is messy because included files are textually included, resolving
        # cimports (but not includes) relative to the including file.
        all = set()
        for include in self.parse_dependencies(filename)[1]:
            include_path = join_path(os.path.dirname(filename), include)
            if not path_exists(include_path):
                include_path = self.context.find_include_file(include, None)
            if include_path:
                if '.' + os.path.sep in include_path:
                    include_path = os.path.normpath(include_path)
                all.add(include_path)
                all.update(self.included_files(include_path))
            elif not self.quiet:
                print("Unable to locate '%s' referenced from '%s'" % (filename, include))
        return all

    @cached_method
    def cimports_and_externs(self, filename):
        # This is really ugly. Nested cimports are resolved with respect to the
        # includer, but includes are resolved with respect to the includee.
        cimports, includes, externs = self.parse_dependencies(filename)[:3]
        cimports = set(cimports)
        externs = set(externs)
        for include in self.included_files(filename):
            included_cimports, included_externs = self.cimports_and_externs(include)
            cimports.update(included_cimports)
            externs.update(included_externs)
        return tuple(cimports), normalize_existing(filename, externs)

    def cimports(self, filename):
        return self.cimports_and_externs(filename)[0]

    def package(self, filename):
        return package(filename)

    def fully_qualified_name(self, filename):
        return fully_qualified_name(filename)

    @cached_method
    def find_pxd(self, module, filename=None):
        is_relative = module[0] == '.'
        if is_relative and not filename:
            raise NotImplementedError("New relative imports.")
        if filename is not None:
            module_path = module.split('.')
            if is_relative:
                module_path.pop(0)  # just explicitly relative
            package_path = list(self.package(filename))
            while module_path and not module_path[0]:
                try:
                    package_path.pop()
                except IndexError:
                    return None   # FIXME: error?
                module_path.pop(0)
            relative = '.'.join(package_path + module_path)
            pxd = self.context.find_pxd_file(relative, None)
            if pxd:
                return pxd
        if is_relative:
            return None   # FIXME: error?
        return self.context.find_pxd_file(module, None)

    @cached_method
    def cimported_files(self, filename):
        if filename[-4:] == '.pyx' and path_exists(filename[:-4] + '.pxd'):
            pxd_list = [filename[:-4] + '.pxd']
        else:
            pxd_list = []
        for module in self.cimports(filename):
            if module[:7] == 'cython.' or module == 'cython':
                continue
            pxd_file = self.find_pxd(module, filename)
            if pxd_file is not None:
                pxd_list.append(pxd_file)
            elif not self.quiet:
                print("missing cimport in module '%s': %s" % (module, filename))
        return tuple(pxd_list)

    @cached_method
    def immediate_dependencies(self, filename):
        all = set([filename])
        all.update(self.cimported_files(filename))
        all.update(self.included_files(filename))
        return all

    def all_dependencies(self, filename):
        return self.transitive_merge(filename, self.immediate_dependencies, set.union)

    @cached_method
    def timestamp(self, filename):
        return os.path.getmtime(filename)

    def extract_timestamp(self, filename):
        return self.timestamp(filename), filename

    def newest_dependency(self, filename):
        return max([self.extract_timestamp(f) for f in self.all_dependencies(filename)])

    def transitive_fingerprint(self, filename, extra=None):
        try:
            m = hashlib.md5(__version__)
            m.update(file_hash(filename))
            for x in sorted(self.all_dependencies(filename)):
                if os.path.splitext(x)[1] not in ('.c', '.cpp', '.h'):
                    m.update(file_hash(x))
            if extra is not None:
                m.update(str(extra))
            return m.hexdigest()
        except IOError:
            return None

    def distutils_info0(self, filename):
        info = self.parse_dependencies(filename)[3]
        externs = self.cimports_and_externs(filename)[1]
        if externs:
            if 'depends' in info.values:
                info.values['depends'] = list(set(info.values['depends']).union(externs))
            else:
                info.values['depends'] = list(externs)
        return info

    def distutils_info(self, filename, aliases=None, base=None):
        return (self.transitive_merge(filename, self.distutils_info0, DistutilsInfo.merge)
            .subs(aliases)
            .merge(base))

    def transitive_merge(self, node, extract, merge):
        try:
            seen = self._transitive_cache[extract, merge]
        except KeyError:
            seen = self._transitive_cache[extract, merge] = {}
        return self.transitive_merge_helper(
            node, extract, merge, seen, {}, self.cimported_files)[0]

    def transitive_merge_helper(self, node, extract, merge, seen, stack, outgoing):
        if node in seen:
            return seen[node], None
        deps = extract(node)
        if node in stack:
            return deps, node
        try:
            stack[node] = len(stack)
            loop = None
            for next in outgoing(node):
                sub_deps, sub_loop = self.transitive_merge_helper(next, extract, merge, seen, stack, outgoing)
                if sub_loop is not None:
                    if loop is not None and stack[loop] < stack[sub_loop]:
                        pass
                    else:
                        loop = sub_loop
                deps = merge(deps, sub_deps)
            if loop == node:
                loop = None
            if loop is None:
                seen[node] = deps
            return deps, loop
        finally:
            del stack[node]

_dep_tree = None
def create_dependency_tree(ctx=None, quiet=False):
    global _dep_tree
    if _dep_tree is None:
        if ctx is None:
            ctx = Context(["."], CompilationOptions(default_options))
        _dep_tree = DependencyTree(ctx, quiet=quiet)
    return _dep_tree

# This may be useful for advanced users?
def create_extension_list(patterns, exclude=[], ctx=None, aliases=None, quiet=False, exclude_failures=False):
    if not isinstance(patterns, (list, tuple)):
        patterns = [patterns]
    explicit_modules = set([m.name for m in patterns if isinstance(m, Extension)])
    seen = set()
    deps = create_dependency_tree(ctx, quiet=quiet)
    to_exclude = set()
    if not isinstance(exclude, list):
        exclude = [exclude]
    for pattern in exclude:
        to_exclude.update(map(os.path.abspath, extended_iglob(pattern)))
    module_list = []
    for pattern in patterns:
        if isinstance(pattern, str):
            filepattern = pattern
            template = None
            name = '*'
            base = None
            exn_type = Extension
        elif isinstance(pattern, Extension):
            filepattern = pattern.sources[0]
            if os.path.splitext(filepattern)[1] not in ('.py', '.pyx'):
                # ignore non-cython modules
                module_list.append(pattern)
                continue
            template = pattern
            name = template.name
            base = DistutilsInfo(exn=template)
            exn_type = template.__class__
        else:
            raise TypeError(pattern)
        for file in extended_iglob(filepattern):
            if os.path.abspath(file) in to_exclude:
                continue
            pkg = deps.package(file)
            if '*' in name:
                module_name = deps.fully_qualified_name(file)
                if module_name in explicit_modules:
                    continue
            else:
                module_name = name
            if module_name not in seen:
                try:
                    kwds = deps.distutils_info(file, aliases, base).values
                except Exception:
                    if exclude_failures:
                        continue
                    raise
                if base is not None:
                    for key, value in base.values.items():
                        if key not in kwds:
                            kwds[key] = value
                sources = [file]
                if template is not None:
                    sources += template.sources[1:]
                if 'sources' in kwds:
                    # allow users to add .c files etc.
                    for source in kwds['sources']:
                        source = encode_filename_in_py2(source)
                        if source not in sources:
                            sources.append(source)
                    del kwds['sources']
                if 'depends' in kwds:
                    depends = resolve_depends(kwds['depends'], (kwds.get('include_dirs') or []) + [find_root_package_dir(file)])
                    if template is not None:
                        # Always include everything from the template.
                        depends = list(set(template.depends).union(set(depends)))
                    kwds['depends'] = depends
                module_list.append(exn_type(
                        name=module_name,
                        sources=sources,
                        **kwds))
                m = module_list[-1]
                seen.add(name)
    return module_list

# This is the user-exposed entry point.
def cythonize(module_list, exclude=[], nthreads=0, aliases=None, quiet=False, force=False,
              exclude_failures=False, **options):
    """
    Compile a set of source modules into C/C++ files and return a list of distutils
    Extension objects for them.

    As module list, pass either a glob pattern, a list of glob patterns or a list of
    Extension objects.  The latter allows you to configure the extensions separately
    through the normal distutils options.

    When using glob patterns, you can exclude certain module names explicitly
    by passing them into the 'exclude' option.

    For parallel compilation, set the 'nthreads' option to the number of
    concurrent builds.

    For a broad 'try to compile' mode that ignores compilation failures and
    simply excludes the failed extensions, pass 'exclude_failures=True'. Note
    that this only really makes sense for compiling .py files which can also
    be used without compilation.

    Additional compilation options can be passed as keyword arguments.
    """
    if 'include_path' not in options:
        options['include_path'] = ['.']
    if 'common_utility_include_dir' in options:
        if options.get('cache'):
            raise NotImplementedError("common_utility_include_dir does not yet work with caching")
        if not os.path.exists(options['common_utility_include_dir']):
            os.makedirs(options['common_utility_include_dir'])
    c_options = CompilationOptions(**options)
    cpp_options = CompilationOptions(**options); cpp_options.cplus = True
    ctx = c_options.create_context()
    options = c_options
    module_list = create_extension_list(
        module_list,
        exclude=exclude,
        ctx=ctx,
        quiet=quiet,
        exclude_failures=exclude_failures,
        aliases=aliases)
    deps = create_dependency_tree(ctx, quiet=quiet)
    build_dir = getattr(options, 'build_dir', None)
    modules_by_cfile = {}
    to_compile = []
    for m in module_list:
        if build_dir:
            root = os.path.realpath(os.path.abspath(find_root_package_dir(m.sources[0])))
            def copy_to_build_dir(filepath, root=root):
                filepath_abs = os.path.realpath(os.path.abspath(filepath))
                if os.path.isabs(filepath):
                    filepath = filepath_abs
                if filepath_abs.startswith(root):
                    mod_dir = os.path.join(build_dir,
                            os.path.dirname(_relpath(filepath, root)))
                    if not os.path.isdir(mod_dir):
                        os.makedirs(mod_dir)
                    shutil.copy(filepath, mod_dir)
            for dep in m.depends:
                copy_to_build_dir(dep)

        new_sources = []
        for source in m.sources:
            base, ext = os.path.splitext(source)
            if ext in ('.pyx', '.py'):
                if m.language == 'c++':
                    c_file = base + '.cpp'
                    options = cpp_options
                else:
                    c_file = base + '.c'
                    options = c_options

                # setup for out of place build directory if enabled
                if build_dir:
                    c_file = os.path.join(build_dir, c_file)
                    dir = os.path.dirname(c_file)
                    if not os.path.isdir(dir):
                        os.makedirs(dir)

                if os.path.exists(c_file):
                    c_timestamp = os.path.getmtime(c_file)
                else:
                    c_timestamp = -1

                # Priority goes first to modified files, second to direct
                # dependents, and finally to indirect dependents.
                if c_timestamp < deps.timestamp(source):
                    dep_timestamp, dep = deps.timestamp(source), source
                    priority = 0
                else:
                    dep_timestamp, dep = deps.newest_dependency(source)
                    priority = 2 - (dep in deps.immediate_dependencies(source))
                if force or c_timestamp < dep_timestamp:
                    if not quiet:
                        if source == dep:
                            print("Compiling %s because it changed." % source)
                        else:
                            print("Compiling %s because it depends on %s." % (source, dep))
                    if not force and hasattr(options, 'cache'):
                        extra = m.language
                        fingerprint = deps.transitive_fingerprint(source, extra)
                    else:
                        fingerprint = None
                    to_compile.append((priority, source, c_file, fingerprint, quiet,
                                       options, not exclude_failures))
                new_sources.append(c_file)
                if c_file not in modules_by_cfile:
                    modules_by_cfile[c_file] = [m]
                else:
                    modules_by_cfile[c_file].append(m)
            else:
                new_sources.append(source)
                if build_dir:
                    copy_to_build_dir(source)
        m.sources = new_sources
    if hasattr(options, 'cache'):
        if not os.path.exists(options.cache):
            os.makedirs(options.cache)
    to_compile.sort()
    if nthreads:
        # Requires multiprocessing (or Python >= 2.6)
        try:
            import multiprocessing
            pool = multiprocessing.Pool(nthreads)
        except (ImportError, OSError):
            print("multiprocessing required for parallel cythonization")
            nthreads = 0
        else:
            pool.map(cythonize_one_helper, to_compile)
    if not nthreads:
        for args in to_compile:
            cythonize_one(*args[1:])
    if exclude_failures:
        failed_modules = set()
        for c_file, modules in modules_by_cfile.iteritems():
            if not os.path.exists(c_file):
                failed_modules.update(modules)
            elif os.path.getsize(c_file) < 200:
                f = io_open(c_file, 'r', encoding='iso8859-1')
                try:
                    if f.read(len('#error ')) == '#error ':
                        # dead compilation result
                        failed_modules.update(modules)
                finally:
                    f.close()
        if failed_modules:
            for module in failed_modules:
                module_list.remove(module)
            print("Failed compilations: %s" % ', '.join(sorted([
                module.name for module in failed_modules])))
    if hasattr(options, 'cache'):
        cleanup_cache(options.cache, getattr(options, 'cache_size', 1024 * 1024 * 100))
    # cythonize() is often followed by the (non-Python-buffered)
    # compiler output, flush now to avoid interleaving output.
    sys.stdout.flush()
    return module_list


if os.environ.get('XML_RESULTS'):
    compile_result_dir = os.environ['XML_RESULTS']
    def record_results(func):
        def with_record(*args):
            t = time.time()
            success = True
            try:
                try:
                    func(*args)
                except:
                    success = False
            finally:
                t = time.time() - t
                module = fully_qualified_name(args[0])
                name = "cythonize." + module
                failures = 1 - success
                if success:
                    failure_item = ""
                else:
                    failure_item = "failure"
                output = open(os.path.join(compile_result_dir, name + ".xml"), "w")
                output.write("""
                    <?xml version="1.0" ?>
                    <testsuite name="%(name)s" errors="0" failures="%(failures)s" tests="1" time="%(t)s">
                    <testcase classname="%(name)s" name="cythonize">
                    %(failure_item)s
                    </testcase>
                    </testsuite>
                """.strip() % locals())
                output.close()
        return with_record
else:
    record_results = lambda x: x

# TODO: Share context? Issue: pyx processing leaks into pxd module
@record_results
def cythonize_one(pyx_file, c_file, fingerprint, quiet, options=None, raise_on_failure=True):
    from Cython.Compiler.Main import compile, default_options
    from Cython.Compiler.Errors import CompileError, PyrexError

    if fingerprint:
        if not os.path.exists(options.cache):
            try:
                os.mkdir(options.cache)
            except:
                if not os.path.exists(options.cache):
                    raise
        # Cython-generated c files are highly compressible.
        # (E.g. a compression ratio of about 10 for Sage).
        fingerprint_file = join_path(
            options.cache, "%s-%s%s" % (os.path.basename(c_file), fingerprint, gzip_ext))
        if os.path.exists(fingerprint_file):
            if not quiet:
                print("Found compiled %s in cache" % pyx_file)
            os.utime(fingerprint_file, None)
            g = gzip_open(fingerprint_file, 'rb')
            try:
                f = open(c_file, 'wb')
                try:
                    shutil.copyfileobj(g, f)
                finally:
                    f.close()
            finally:
                g.close()
            return
    if not quiet:
        print("Cythonizing %s" % pyx_file)
    if options is None:
        options = CompilationOptions(default_options)
    options.output_file = c_file

    any_failures = 0
    try:
        result = compile([pyx_file], options)
        if result.num_errors > 0:
            any_failures = 1
    except (EnvironmentError, PyrexError), e:
        sys.stderr.write('%s\n' % e)
        any_failures = 1
        # XXX
        import traceback
        traceback.print_exc()
    except Exception:
        if raise_on_failure:
            raise
        import traceback
        traceback.print_exc()
        any_failures = 1
    if any_failures:
        if raise_on_failure:
            raise CompileError(None, pyx_file)
        elif os.path.exists(c_file):
            os.remove(c_file)
    elif fingerprint:
        f = open(c_file, 'rb')
        try:
            g = gzip_open(fingerprint_file, 'wb')
            try:
                shutil.copyfileobj(f, g)
            finally:
                g.close()
        finally:
            f.close()

def cythonize_one_helper(m):
    import traceback
    try:
        return cythonize_one(*m[1:])
    except Exception:
        traceback.print_exc()
        raise

def cleanup_cache(cache, target_size, ratio=.85):
    try:
        p = subprocess.Popen(['du', '-s', '-k', os.path.abspath(cache)], stdout=subprocess.PIPE)
        res = p.wait()
        if res == 0:
            total_size = 1024 * int(p.stdout.read().strip().split()[0])
            if total_size < target_size:
                return
    except (OSError, ValueError):
        pass
    total_size = 0
    all = []
    for file in os.listdir(cache):
        path = join_path(cache, file)
        s = os.stat(path)
        total_size += s.st_size
        all.append((s.st_atime, s.st_size, path))
    if total_size > target_size:
        for time, size, file in reversed(sorted(all)):
            os.unlink(file)
            total_size -= size
            if total_size < target_size * ratio:
                break
