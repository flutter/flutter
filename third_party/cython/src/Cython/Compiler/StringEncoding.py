#
#   Cython -- encoding related tools
#

import re
import sys

if sys.version_info[0] >= 3:
    _unicode, _str, _bytes = str, str, bytes
    IS_PYTHON3 = True
else:
    _unicode, _str, _bytes = unicode, str, str
    IS_PYTHON3 = False

empty_bytes = _bytes()
empty_unicode = _unicode()

join_bytes = empty_bytes.join

class UnicodeLiteralBuilder(object):
    """Assemble a unicode string.
    """
    def __init__(self):
        self.chars = []

    def append(self, characters):
        if isinstance(characters, _bytes):
            # this came from a Py2 string literal in the parser code
            characters = characters.decode("ASCII")
        assert isinstance(characters, _unicode), str(type(characters))
        self.chars.append(characters)

    if sys.maxunicode == 65535:
        def append_charval(self, char_number):
            if char_number > 65535:
                # wide Unicode character on narrow platform => replace
                # by surrogate pair
                char_number -= 0x10000
                self.chars.append( unichr((char_number // 1024) + 0xD800) )
                self.chars.append( unichr((char_number  % 1024) + 0xDC00) )
            else:
                self.chars.append( unichr(char_number) )
    else:
        def append_charval(self, char_number):
            self.chars.append( unichr(char_number) )

    def append_uescape(self, char_number, escape_string):
        self.append_charval(char_number)

    def getstring(self):
        return EncodedString(u''.join(self.chars))

    def getstrings(self):
        return (None, self.getstring())


class BytesLiteralBuilder(object):
    """Assemble a byte string or char value.
    """
    def __init__(self, target_encoding):
        self.chars = []
        self.target_encoding = target_encoding

    def append(self, characters):
        if isinstance(characters, _unicode):
            characters = characters.encode(self.target_encoding)
        assert isinstance(characters, _bytes), str(type(characters))
        self.chars.append(characters)

    def append_charval(self, char_number):
        self.chars.append( unichr(char_number).encode('ISO-8859-1') )

    def append_uescape(self, char_number, escape_string):
        self.append(escape_string)

    def getstring(self):
        # this *must* return a byte string!
        s = BytesLiteral(join_bytes(self.chars))
        s.encoding = self.target_encoding
        return s

    def getchar(self):
        # this *must* return a byte string!
        return self.getstring()

    def getstrings(self):
        return (self.getstring(), None)

class StrLiteralBuilder(object):
    """Assemble both a bytes and a unicode representation of a string.
    """
    def __init__(self, target_encoding):
        self._bytes   = BytesLiteralBuilder(target_encoding)
        self._unicode = UnicodeLiteralBuilder()

    def append(self, characters):
        self._bytes.append(characters)
        self._unicode.append(characters)

    def append_charval(self, char_number):
        self._bytes.append_charval(char_number)
        self._unicode.append_charval(char_number)

    def append_uescape(self, char_number, escape_string):
        self._bytes.append(escape_string)
        self._unicode.append_charval(char_number)

    def getstrings(self):
        return (self._bytes.getstring(), self._unicode.getstring())


class EncodedString(_unicode):
    # unicode string subclass to keep track of the original encoding.
    # 'encoding' is None for unicode strings and the source encoding
    # otherwise
    encoding = None

    def __deepcopy__(self, memo):
        return self

    def byteencode(self):
        assert self.encoding is not None
        return self.encode(self.encoding)

    def utf8encode(self):
        assert self.encoding is None
        return self.encode("UTF-8")

    @property
    def is_unicode(self):
        return self.encoding is None

    def contains_surrogates(self):
        return string_contains_surrogates(self)


def string_contains_surrogates(ustring):
    """
    Check if the unicode string contains surrogate code points
    on a CPython platform with wide (UCS-4) or narrow (UTF-16)
    Unicode, i.e. characters that would be spelled as two
    separate code units on a narrow platform.
    """
    for c in map(ord, ustring):
        if c > 65535:  # can only happen on wide platforms
            return True
        if 0xD800 <= c <= 0xDFFF:
            return True
    return False


class BytesLiteral(_bytes):
    # bytes subclass that is compatible with EncodedString
    encoding = None

    def __deepcopy__(self, memo):
        return self

    def byteencode(self):
        if IS_PYTHON3:
            return _bytes(self)
        else:
            # fake-recode the string to make it a plain bytes object
            return self.decode('ISO-8859-1').encode('ISO-8859-1')

    def utf8encode(self):
        assert False, "this is not a unicode string: %r" % self

    def __str__(self):
        """Fake-decode the byte string to unicode to support %
        formatting of unicode strings.
        """
        return self.decode('ISO-8859-1')

    is_unicode = False


char_from_escape_sequence = {
    r'\a' : u'\a',
    r'\b' : u'\b',
    r'\f' : u'\f',
    r'\n' : u'\n',
    r'\r' : u'\r',
    r'\t' : u'\t',
    r'\v' : u'\v',
    }.get

_c_special = ('\\', '??', '"') + tuple(map(chr, range(32)))


def _to_escape_sequence(s):
    if s in '\n\r\t':
        return repr(s)[1:-1]
    elif s == '"':
        return r'\"'
    elif s == '\\':
        return r'\\'
    else:
        # within a character sequence, oct passes much better than hex
        return ''.join(['\\%03o' % ord(c) for c in s])


def _build_specials_replacer():
    subexps = []
    replacements = {}
    for special in _c_special:
        regexp = ''.join(['[%s]' % c.replace('\\', '\\\\') for c in special])
        subexps.append(regexp)
        replacements[special.encode('ASCII')] = _to_escape_sequence(special).encode('ASCII')
    sub = re.compile(('(%s)' % '|'.join(subexps)).encode('ASCII')).sub
    def replace_specials(m):
        return replacements[m.group(1)]
    def replace(s):
        return sub(replace_specials, s)
    return replace

_replace_specials = _build_specials_replacer()


def escape_char(c):
    if IS_PYTHON3:
        c = c.decode('ISO-8859-1')
    if c in '\n\r\t\\':
        return repr(c)[1:-1]
    elif c == "'":
        return "\\'"
    n = ord(c)
    if n < 32 or n > 127:
        # hex works well for characters
        return "\\x%02X" % n
    else:
        return c

def escape_byte_string(s):
    """Escape a byte string so that it can be written into C code.
    Note that this returns a Unicode string instead which, when
    encoded as ISO-8859-1, will result in the correct byte sequence
    being written.
    """
    s = _replace_specials(s)
    try:
        return s.decode("ASCII") # trial decoding: plain ASCII => done
    except UnicodeDecodeError:
        pass
    if IS_PYTHON3:
        s_new = bytearray()
        append, extend = s_new.append, s_new.extend
        for b in s:
            if b >= 128:
                extend(('\\%3o' % b).encode('ASCII'))
            else:
                append(b)
        return s_new.decode('ISO-8859-1')
    else:
        l = []
        append = l.append
        for c in s:
            o = ord(c)
            if o >= 128:
                append('\\%3o' % o)
            else:
                append(c)
        return join_bytes(l).decode('ISO-8859-1')

def split_string_literal(s, limit=2000):
    # MSVC can't handle long string literals.
    if len(s) < limit:
        return s
    else:
        start = 0
        chunks = []
        while start < len(s):
            end = start + limit
            if len(s) > end-4 and '\\' in s[end-4:end]:
                end -= 4 - s[end-4:end].find('\\') # just before the backslash
                while s[end-1] == '\\':
                    end -= 1
                    if end == start:
                        # must have been a long line of backslashes
                        end = start + limit - (limit % 2) - 4
                        break
            chunks.append(s[start:end])
            start = end
        return '""'.join(chunks)

def encode_pyunicode_string(s):
    """Create Py_UNICODE[] representation of a given unicode string.
    """
    s = map(ord, s) + [0]

    if sys.maxunicode >= 0x10000:  # Wide build or Py3.3
        utf16, utf32 = [], s
        for code_point in s:
            if code_point >= 0x10000:  # outside of BMP
                high, low = divmod(code_point - 0x10000, 1024)
                utf16.append(high + 0xD800)
                utf16.append(low + 0xDC00)
            else:
                utf16.append(code_point)
    else:
        utf16, utf32 = s, []
        for code_unit in s:
            if 0xDC00 <= code_unit <= 0xDFFF and utf32 and 0xD800 <= utf32[-1] <= 0xDBFF:
                high, low = utf32[-1], code_unit
                utf32[-1] = ((high & 0x3FF) << 10) + (low & 0x3FF) + 0x10000
            else:
                utf32.append(code_unit)

    if utf16 == utf32:
        utf16 = []
    return ",".join(map(unicode, utf16)), ",".join(map(unicode, utf32))
