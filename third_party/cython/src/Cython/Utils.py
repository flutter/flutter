#
#   Cython -- Things that don't belong
#            anywhere else in particular
#

import os, sys, re, codecs

modification_time = os.path.getmtime

def cached_function(f):
    cache = {}
    uncomputed = object()
    def wrapper(*args):
        res = cache.get(args, uncomputed)
        if res is uncomputed:
            res = cache[args] = f(*args)
        return res
    return wrapper

def cached_method(f):
    cache_name = '__%s_cache' % f.__name__
    def wrapper(self, *args):
        cache = getattr(self, cache_name, None)
        if cache is None:
            cache = {}
            setattr(self, cache_name, cache)
        if args in cache:
            return cache[args]
        res = cache[args] = f(self, *args)
        return res
    return wrapper

def replace_suffix(path, newsuf):
    base, _ = os.path.splitext(path)
    return base + newsuf

def open_new_file(path):
    if os.path.exists(path):
        # Make sure to create a new file here so we can
        # safely hard link the output files.
        os.unlink(path)

    # we use the ISO-8859-1 encoding here because we only write pure
    # ASCII strings or (e.g. for file names) byte encoded strings as
    # Unicode, so we need a direct mapping from the first 256 Unicode
    # characters to a byte sequence, which ISO-8859-1 provides
    return codecs.open(path, "w", encoding="ISO-8859-1")

def castrate_file(path, st):
    #  Remove junk contents from an output file after a
    #  failed compilation.
    #  Also sets access and modification times back to
    #  those specified by st (a stat struct).
    try:
        f = open_new_file(path)
    except EnvironmentError:
        pass
    else:
        f.write(
            "#error Do not use this file, it is the result of a failed Cython compilation.\n")
        f.close()
        if st:
            os.utime(path, (st.st_atime, st.st_mtime-1))

def file_newer_than(path, time):
    ftime = modification_time(path)
    return ftime > time

@cached_function
def search_include_directories(dirs, qualified_name, suffix, pos,
                               include=False, sys_path=False):
    # Search the list of include directories for the given
    # file name. If a source file position is given, first
    # searches the directory containing that file. Returns
    # None if not found, but does not report an error.
    # The 'include' option will disable package dereferencing.
    # If 'sys_path' is True, also search sys.path.
    if sys_path:
        dirs = dirs + tuple(sys.path)
    if pos:
        file_desc = pos[0]
        from Cython.Compiler.Scanning import FileSourceDescriptor
        if not isinstance(file_desc, FileSourceDescriptor):
            raise RuntimeError("Only file sources for code supported")
        if include:
            dirs = (os.path.dirname(file_desc.filename),) + dirs
        else:
            dirs = (find_root_package_dir(file_desc.filename),) + dirs

    dotted_filename = qualified_name
    if suffix:
        dotted_filename += suffix
    if not include:
        names = qualified_name.split('.')
        package_names = tuple(names[:-1])
        module_name = names[-1]
        module_filename = module_name + suffix
        package_filename = "__init__" + suffix

    for dir in dirs:
        path = os.path.join(dir, dotted_filename)
        if path_exists(path):
            return path
        if not include:
            package_dir = check_package_dir(dir, package_names)
            if package_dir is not None:
                path = os.path.join(package_dir, module_filename)
                if path_exists(path):
                    return path
                path = os.path.join(dir, package_dir, module_name,
                                    package_filename)
                if path_exists(path):
                    return path
    return None


@cached_function
def find_root_package_dir(file_path):
    dir = os.path.dirname(file_path)
    if file_path == dir:
        return dir
    elif is_package_dir(dir):
        return find_root_package_dir(dir)
    else:
        return dir

@cached_function
def check_package_dir(dir, package_names):
    for dirname in package_names:
        dir = os.path.join(dir, dirname)
        if not is_package_dir(dir):
            return None
    return dir

@cached_function
def is_package_dir(dir_path):
    for filename in ("__init__.py",
                     "__init__.pyx",
                     "__init__.pxd"):
        path = os.path.join(dir_path, filename)
        if path_exists(path):
            return 1

@cached_function
def path_exists(path):
    # try on the filesystem first
    if os.path.exists(path):
        return True
    # figure out if a PEP 302 loader is around
    try:
        loader = __loader__
        # XXX the code below assumes a 'zipimport.zipimporter' instance
        # XXX should be easy to generalize, but too lazy right now to write it
        archive_path = getattr(loader, 'archive', None)
        if archive_path:
            normpath = os.path.normpath(path)
            if normpath.startswith(archive_path):
                arcname = normpath[len(archive_path)+1:]
                try:
                    loader.get_data(arcname)
                    return True
                except IOError:
                    return False
    except NameError:
        pass
    return False

# file name encodings

def decode_filename(filename):
    if isinstance(filename, unicode):
        return filename
    try:
        filename_encoding = sys.getfilesystemencoding()
        if filename_encoding is None:
            filename_encoding = sys.getdefaultencoding()
        filename = filename.decode(filename_encoding)
    except UnicodeDecodeError:
        pass
    return filename

# support for source file encoding detection

_match_file_encoding = re.compile(u"coding[:=]\s*([-\w.]+)").search

def detect_file_encoding(source_filename):
    f = open_source_file(source_filename, encoding="UTF-8", error_handling='ignore')
    try:
        return detect_opened_file_encoding(f)
    finally:
        f.close()
    
def detect_opened_file_encoding(f):
    # PEPs 263 and 3120
    # Most of the time the first two lines fall in the first 250 chars,
    # and this bulk read/split is much faster.
    lines = f.read(250).split("\n")
    if len(lines) > 2:
        m = _match_file_encoding(lines[0]) or _match_file_encoding(lines[1])
        if m:
            return m.group(1)
        else:
            return "UTF-8"
    else:
        # Fallback to one-char-at-a-time detection.
        f.seek(0)
        chars = []
        for i in range(2):
            c = f.read(1)
            while c and c != u'\n':
                chars.append(c)
                c = f.read(1)
            encoding = _match_file_encoding(u''.join(chars))
            if encoding:
                return encoding.group(1)
    return "UTF-8"


def skip_bom(f):
    """
    Read past a BOM at the beginning of a source file.
    This could be added to the scanner, but it's *substantially* easier
    to keep it at this level.
    """
    if f.read(1) != u'\uFEFF':
        f.seek(0)


normalise_newlines = re.compile(u'\r\n?|\n').sub


class NormalisedNewlineStream(object):
    """The codecs module doesn't provide universal newline support.
    This class is used as a stream wrapper that provides this
    functionality.  The new 'io' in Py2.6+/3.x supports this out of the
    box.
    """

    def __init__(self, stream):
        # let's assume .read() doesn't change
        self.stream = stream
        self._read = stream.read
        self.close = stream.close
        self.encoding = getattr(stream, 'encoding', 'UTF-8')

    def read(self, count=-1):
        data = self._read(count)
        if u'\r' not in data:
            return data
        if data.endswith(u'\r'):
            # may be missing a '\n'
            data += self._read(1)
        return normalise_newlines(u'\n', data)

    def readlines(self):
        content = []
        data = self.read(0x1000)
        while data:
            content.append(data)
            data = self.read(0x1000)

        return u''.join(content).splitlines(True)

    def seek(self, pos):
        if pos == 0:
            self.stream.seek(0)
        else:
            raise NotImplementedError


io = None
if sys.version_info >= (2,6):
    try:
        import io
    except ImportError:
        pass


def open_source_file(source_filename, mode="r",
                     encoding=None, error_handling=None,
                     require_normalised_newlines=True):
    if encoding is None:
        # Most of the time the coding is unspecified, so be optimistic that
        # it's UTF-8.
        f = open_source_file(source_filename, encoding="UTF-8", mode=mode, error_handling='ignore')
        encoding = detect_opened_file_encoding(f)
        if (encoding == "UTF-8"
                and error_handling == 'ignore'
                and require_normalised_newlines):
            f.seek(0)
            skip_bom(f)
            return f
        else:
            f.close()
    #
    if not os.path.exists(source_filename):
        try:
            loader = __loader__
            if source_filename.startswith(loader.archive):
                return open_source_from_loader(
                    loader, source_filename,
                    encoding, error_handling,
                    require_normalised_newlines)
        except (NameError, AttributeError):
            pass
    #
    if io is not None:
        stream = io.open(source_filename, mode=mode,
                         encoding=encoding, errors=error_handling)
    else:
        # codecs module doesn't have universal newline support
        stream = codecs.open(source_filename, mode=mode,
                             encoding=encoding, errors=error_handling)
        if require_normalised_newlines:
            stream = NormalisedNewlineStream(stream)
    skip_bom(stream)
    return stream


def open_source_from_loader(loader,
                            source_filename,
                            encoding=None, error_handling=None,
                            require_normalised_newlines=True):
    nrmpath = os.path.normpath(source_filename)
    arcname = nrmpath[len(loader.archive)+1:]
    data = loader.get_data(arcname)
    if io is not None:
        return io.TextIOWrapper(io.BytesIO(data),
                                encoding=encoding,
                                errors=error_handling)
    else:
        try:
            import cStringIO as StringIO
        except ImportError:
            import StringIO
        reader = codecs.getreader(encoding)
        stream = reader(StringIO.StringIO(data))
        if require_normalised_newlines:
            stream = NormalisedNewlineStream(stream)
        return stream

def str_to_number(value):
    # note: this expects a string as input that was accepted by the
    # parser already
    if len(value) < 2:
        value = int(value, 0)
    elif value[0] == '0':
        if value[1] in 'xX':
            # hex notation ('0x1AF')
            value = int(value[2:], 16)
        elif value[1] in 'oO':
            # Py3 octal notation ('0o136')
            value = int(value[2:], 8)
        elif value[1] in 'bB':
            # Py3 binary notation ('0b101')
            value = int(value[2:], 2)
        else:
            # Py2 octal notation ('0136')
            value = int(value, 8)
    else:
        value = int(value, 0)
    return value

def long_literal(value):
    if isinstance(value, basestring):
        value = str_to_number(value)
    return not -2**31 <= value < 2**31

# all() and any() are new in 2.5
try:
    # Make sure to bind them on the module, as they will be accessed as
    # attributes
    all = all
    any = any
except NameError:
    def all(items):
        for item in items:
            if not item:
                return False
        return True

    def any(items):
        for item in items:
            if item:
                return True
        return False

@cached_function
def get_cython_cache_dir():
    """get the cython cache dir

    Priority:

    1. CYTHON_CACHE_DIR
    2. (OS X): ~/Library/Caches/Cython
       (posix not OS X): XDG_CACHE_HOME/cython if XDG_CACHE_HOME defined
    3. ~/.cython

    """
    if 'CYTHON_CACHE_DIR' in os.environ:
        return os.environ['CYTHON_CACHE_DIR']

    parent = None
    if os.name == 'posix':
        if sys.platform == 'darwin':
            parent = os.path.expanduser('~/Library/Caches')
        else:
            # this could fallback on ~/.cache
            parent = os.environ.get('XDG_CACHE_HOME')

    if parent and os.path.isdir(parent):
        return os.path.join(parent, 'cython')

    # last fallback: ~/.cython
    return os.path.expanduser(os.path.join('~', '.cython'))
