#=======================================================================
#
#     Python Lexical Analyser
#
#     Regular Expressions
#
#=======================================================================

import types
from sys import maxint as maxint

import Errors

#
#     Constants
#

BOL = 'bol'
EOL = 'eol'
EOF = 'eof'

nl_code = ord('\n')

#
#     Helper functions
#

def chars_to_ranges(s):
    """
    Return a list of character codes consisting of pairs
    [code1a, code1b, code2a, code2b,...] which cover all
    the characters in |s|.
    """
    char_list = list(s)
    char_list.sort()
    i = 0
    n = len(char_list)
    result = []
    while i < n:
        code1 = ord(char_list[i])
        code2 = code1 + 1
        i = i + 1
        while i < n and code2 >= ord(char_list[i]):
            code2 = code2 + 1
            i = i + 1
        result.append(code1)
        result.append(code2)
    return result

def uppercase_range(code1, code2):
    """
    If the range of characters from code1 to code2-1 includes any
    lower case letters, return the corresponding upper case range.
    """
    code3 = max(code1, ord('a'))
    code4 = min(code2, ord('z') + 1)
    if code3 < code4:
        d = ord('A') - ord('a')
        return (code3 + d, code4 + d)
    else:
        return None

def lowercase_range(code1, code2):
    """
    If the range of characters from code1 to code2-1 includes any
    upper case letters, return the corresponding lower case range.
    """
    code3 = max(code1, ord('A'))
    code4 = min(code2, ord('Z') + 1)
    if code3 < code4:
        d = ord('a') - ord('A')
        return (code3 + d, code4 + d)
    else:
        return None

def CodeRanges(code_list):
    """
    Given a list of codes as returned by chars_to_ranges, return
    an RE which will match a character in any of the ranges.
    """
    re_list = []
    for i in xrange(0, len(code_list), 2):
        re_list.append(CodeRange(code_list[i], code_list[i + 1]))
    return Alt(*re_list)

def CodeRange(code1, code2):
    """
    CodeRange(code1, code2) is an RE which matches any character
    with a code |c| in the range |code1| <= |c| < |code2|.
    """
    if code1 <= nl_code < code2:
        return Alt(RawCodeRange(code1, nl_code),
                             RawNewline,
                             RawCodeRange(nl_code + 1, code2))
    else:
        return RawCodeRange(code1, code2)

#
#     Abstract classes
#

class RE(object):
    """RE is the base class for regular expression constructors.
    The following operators are defined on REs:

         re1 + re2         is an RE which matches |re1| followed by |re2|
         re1 | re2         is an RE which matches either |re1| or |re2|
    """

    nullable = 1 # True if this RE can match 0 input symbols
    match_nl = 1 # True if this RE can match a string ending with '\n'
    str = None     # Set to a string to override the class's __str__ result

    def build_machine(self, machine, initial_state, final_state,
                                        match_bol, nocase):
        """
        This method should add states to |machine| to implement this
        RE, starting at |initial_state| and ending at |final_state|.
        If |match_bol| is true, the RE must be able to match at the
        beginning of a line. If nocase is true, upper and lower case
        letters should be treated as equivalent.
        """
        raise NotImplementedError("%s.build_machine not implemented" %
            self.__class__.__name__)

    def build_opt(self, m, initial_state, c):
        """
        Given a state |s| of machine |m|, return a new state
        reachable from |s| on character |c| or epsilon.
        """
        s = m.new_state()
        initial_state.link_to(s)
        initial_state.add_transition(c, s)
        return s

    def __add__(self, other):
        return Seq(self, other)

    def __or__(self, other):
        return Alt(self, other)

    def __str__(self):
        if self.str:
            return self.str
        else:
            return self.calc_str()

    def check_re(self, num, value):
        if not isinstance(value, RE):
            self.wrong_type(num, value, "Plex.RE instance")

    def check_string(self, num, value):
        if type(value) != type(''):
            self.wrong_type(num, value, "string")

    def check_char(self, num, value):
        self.check_string(num, value)
        if len(value) != 1:
            raise Errors.PlexValueError("Invalid value for argument %d of Plex.%s."
                "Expected a string of length 1, got: %s" % (
                    num, self.__class__.__name__, repr(value)))

    def wrong_type(self, num, value, expected):
        if type(value) == types.InstanceType:
                got = "%s.%s instance" % (
                    value.__class__.__module__, value.__class__.__name__)
        else:
            got = type(value).__name__
        raise Errors.PlexTypeError("Invalid type for argument %d of Plex.%s "
                                        "(expected %s, got %s" % (
                                            num, self.__class__.__name__, expected, got))

#
#     Primitive RE constructors
#     -------------------------
#
#     These are the basic REs from which all others are built.
#

## class Char(RE):
##     """
##     Char(c) is an RE which matches the character |c|.
##     """

##     nullable = 0

##     def __init__(self, char):
##         self.char = char
##         self.match_nl = char == '\n'

##     def build_machine(self, m, initial_state, final_state, match_bol, nocase):
##         c = self.char
##         if match_bol and c != BOL:
##             s1 = self.build_opt(m, initial_state, BOL)
##         else:
##             s1 = initial_state
##         if c == '\n' or c == EOF:
##             s1 = self.build_opt(m, s1, EOL)
##         if len(c) == 1:
##             code = ord(self.char)
##             s1.add_transition((code, code+1), final_state)
##             if nocase and is_letter_code(code):
##                 code2 = other_case_code(code)
##                 s1.add_transition((code2, code2+1), final_state)
##         else:
##             s1.add_transition(c, final_state)

##     def calc_str(self):
##         return "Char(%s)" % repr(self.char)

def Char(c):
    """
    Char(c) is an RE which matches the character |c|.
    """
    if len(c) == 1:
        result = CodeRange(ord(c), ord(c) + 1)
    else:
        result = SpecialSymbol(c)
    result.str = "Char(%s)" % repr(c)
    return result

class RawCodeRange(RE):
    """
    RawCodeRange(code1, code2) is a low-level RE which matches any character
    with a code |c| in the range |code1| <= |c| < |code2|, where the range
    does not include newline. For internal use only.
    """
    nullable = 0
    match_nl = 0
    range = None                     # (code, code)
    uppercase_range = None # (code, code) or None
    lowercase_range = None # (code, code) or None

    def __init__(self, code1, code2):
        self.range = (code1, code2)
        self.uppercase_range = uppercase_range(code1, code2)
        self.lowercase_range = lowercase_range(code1, code2)

    def build_machine(self, m, initial_state, final_state, match_bol, nocase):
        if match_bol:
            initial_state = self.build_opt(m, initial_state, BOL)
        initial_state.add_transition(self.range, final_state)
        if nocase:
            if self.uppercase_range:
                initial_state.add_transition(self.uppercase_range, final_state)
            if self.lowercase_range:
                initial_state.add_transition(self.lowercase_range, final_state)

    def calc_str(self):
        return "CodeRange(%d,%d)" % (self.code1, self.code2)

class _RawNewline(RE):
    """
    RawNewline is a low-level RE which matches a newline character.
    For internal use only.
    """
    nullable = 0
    match_nl = 1

    def build_machine(self, m, initial_state, final_state, match_bol, nocase):
        if match_bol:
            initial_state = self.build_opt(m, initial_state, BOL)
        s = self.build_opt(m, initial_state, EOL)
        s.add_transition((nl_code, nl_code + 1), final_state)

RawNewline = _RawNewline()


class SpecialSymbol(RE):
    """
    SpecialSymbol(sym) is an RE which matches the special input
    symbol |sym|, which is one of BOL, EOL or EOF.
    """
    nullable = 0
    match_nl = 0
    sym = None

    def __init__(self, sym):
        self.sym = sym

    def build_machine(self, m, initial_state, final_state, match_bol, nocase):
        # Sequences 'bol bol' and 'bol eof' are impossible, so only need
        # to allow for bol if sym is eol
        if match_bol and self.sym == EOL:
            initial_state = self.build_opt(m, initial_state, BOL)
        initial_state.add_transition(self.sym, final_state)


class Seq(RE):
    """Seq(re1, re2, re3...) is an RE which matches |re1| followed by
    |re2| followed by |re3|..."""

    def __init__(self, *re_list):
        nullable = 1
        for i in xrange(len(re_list)):
            re = re_list[i]
            self.check_re(i, re)
            nullable = nullable and re.nullable
        self.re_list = re_list
        self.nullable = nullable
        i = len(re_list)
        match_nl = 0
        while i:
            i = i - 1
            re = re_list[i]
            if re.match_nl:
                match_nl = 1
                break
            if not re.nullable:
                break
        self.match_nl = match_nl

    def build_machine(self, m, initial_state, final_state, match_bol, nocase):
        re_list = self.re_list
        if len(re_list) == 0:
            initial_state.link_to(final_state)
        else:
            s1 = initial_state
            n = len(re_list)
            for i in xrange(n):
                if i < n - 1:
                    s2 = m.new_state()
                else:
                    s2 = final_state
                re = re_list[i]
                re.build_machine(m, s1, s2, match_bol, nocase)
                s1 = s2
                match_bol = re.match_nl or (match_bol and re.nullable)

    def calc_str(self):
        return "Seq(%s)" % ','.join(map(str, self.re_list))


class Alt(RE):
    """Alt(re1, re2, re3...) is an RE which matches either |re1| or
    |re2| or |re3|..."""

    def __init__(self, *re_list):
        self.re_list = re_list
        nullable = 0
        match_nl = 0
        nullable_res = []
        non_nullable_res = []
        i = 1
        for re in re_list:
            self.check_re(i, re)
            if re.nullable:
                nullable_res.append(re)
                nullable = 1
            else:
                non_nullable_res.append(re)
            if re.match_nl:
                match_nl = 1
            i = i + 1
        self.nullable_res = nullable_res
        self.non_nullable_res = non_nullable_res
        self.nullable = nullable
        self.match_nl = match_nl

    def build_machine(self, m, initial_state, final_state, match_bol, nocase):
        for re in self.nullable_res:
            re.build_machine(m, initial_state, final_state, match_bol, nocase)
        if self.non_nullable_res:
            if match_bol:
                initial_state = self.build_opt(m, initial_state, BOL)
            for re in self.non_nullable_res:
                re.build_machine(m, initial_state, final_state, 0, nocase)

    def calc_str(self):
        return "Alt(%s)" % ','.join(map(str, self.re_list))


class Rep1(RE):
    """Rep1(re) is an RE which matches one or more repetitions of |re|."""

    def __init__(self, re):
        self.check_re(1, re)
        self.re = re
        self.nullable = re.nullable
        self.match_nl = re.match_nl

    def build_machine(self, m, initial_state, final_state, match_bol, nocase):
        s1 = m.new_state()
        s2 = m.new_state()
        initial_state.link_to(s1)
        self.re.build_machine(m, s1, s2, match_bol or self.re.match_nl, nocase)
        s2.link_to(s1)
        s2.link_to(final_state)

    def calc_str(self):
        return "Rep1(%s)" % self.re


class SwitchCase(RE):
    """
    SwitchCase(re, nocase) is an RE which matches the same strings as RE,
    but treating upper and lower case letters according to |nocase|. If
    |nocase| is true, case is ignored, otherwise it is not.
    """
    re = None
    nocase = None

    def __init__(self, re, nocase):
        self.re = re
        self.nocase = nocase
        self.nullable = re.nullable
        self.match_nl = re.match_nl

    def build_machine(self, m, initial_state, final_state, match_bol, nocase):
        self.re.build_machine(m, initial_state, final_state, match_bol,
                                                    self.nocase)

    def calc_str(self):
        if self.nocase:
            name = "NoCase"
        else:
            name = "Case"
        return "%s(%s)" % (name, self.re)

#
#     Composite RE constructors
#     -------------------------
#
#     These REs are defined in terms of the primitive REs.
#

Empty = Seq()
Empty.__doc__ = \
    """
    Empty is an RE which matches the empty string.
    """
Empty.str = "Empty"

def Str1(s):
    """
    Str1(s) is an RE which matches the literal string |s|.
    """
    result = Seq(*tuple(map(Char, s)))
    result.str = "Str(%s)" % repr(s)
    return result

def Str(*strs):
    """
    Str(s) is an RE which matches the literal string |s|.
    Str(s1, s2, s3, ...) is an RE which matches any of |s1| or |s2| or |s3|...
    """
    if len(strs) == 1:
        return Str1(strs[0])
    else:
        result = Alt(*tuple(map(Str1, strs)))
        result.str = "Str(%s)" % ','.join(map(repr, strs))
        return result

def Any(s):
    """
    Any(s) is an RE which matches any character in the string |s|.
    """
    #result = apply(Alt, tuple(map(Char, s)))
    result = CodeRanges(chars_to_ranges(s))
    result.str = "Any(%s)" % repr(s)
    return result

def AnyBut(s):
    """
    AnyBut(s) is an RE which matches any character (including
    newline) which is not in the string |s|.
    """
    ranges = chars_to_ranges(s)
    ranges.insert(0, -maxint)
    ranges.append(maxint)
    result = CodeRanges(ranges)
    result.str = "AnyBut(%s)" % repr(s)
    return result

AnyChar = AnyBut("")
AnyChar.__doc__ = \
    """
    AnyChar is an RE which matches any single character (including a newline).
    """
AnyChar.str = "AnyChar"

def Range(s1, s2 = None):
    """
    Range(c1, c2) is an RE which matches any single character in the range
    |c1| to |c2| inclusive.
    Range(s) where |s| is a string of even length is an RE which matches
    any single character in the ranges |s[0]| to |s[1]|, |s[2]| to |s[3]|,...
    """
    if s2:
        result = CodeRange(ord(s1), ord(s2) + 1)
        result.str = "Range(%s,%s)" % (s1, s2)
    else:
        ranges = []
        for i in range(0, len(s1), 2):
            ranges.append(CodeRange(ord(s1[i]), ord(s1[i+1]) + 1))
        result = Alt(*ranges)
        result.str = "Range(%s)" % repr(s1)
    return result

def Opt(re):
    """
    Opt(re) is an RE which matches either |re| or the empty string.
    """
    result = Alt(re, Empty)
    result.str = "Opt(%s)" % re
    return result

def Rep(re):
    """
    Rep(re) is an RE which matches zero or more repetitions of |re|.
    """
    result = Opt(Rep1(re))
    result.str = "Rep(%s)" % re
    return result

def NoCase(re):
    """
    NoCase(re) is an RE which matches the same strings as RE, but treating
    upper and lower case letters as equivalent.
    """
    return SwitchCase(re, nocase = 1)

def Case(re):
    """
    Case(re) is an RE which matches the same strings as RE, but treating
    upper and lower case letters as distinct, i.e. it cancels the effect
    of any enclosing NoCase().
    """
    return SwitchCase(re, nocase = 0)

#
#     RE Constants
#

Bol = Char(BOL)
Bol.__doc__ = \
    """
    Bol is an RE which matches the beginning of a line.
    """
Bol.str = "Bol"

Eol = Char(EOL)
Eol.__doc__ = \
    """
    Eol is an RE which matches the end of a line.
    """
Eol.str = "Eol"

Eof = Char(EOF)
Eof.__doc__ = \
    """
    Eof is an RE which matches the end of the file.
    """
Eof.str = "Eof"

