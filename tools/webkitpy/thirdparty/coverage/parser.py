"""Code parsing for Coverage."""

import opcode, re, sys, token, tokenize

from coverage.backward import set, sorted, StringIO # pylint: disable=W0622
from coverage.backward import open_source
from coverage.bytecode import ByteCodes, CodeObjects
from coverage.misc import nice_pair, expensive, join_regex
from coverage.misc import CoverageException, NoSource, NotPython


class CodeParser(object):
    """Parse code to find executable lines, excluded lines, etc."""

    def __init__(self, text=None, filename=None, exclude=None):
        """
        Source can be provided as `text`, the text itself, or `filename`, from
        which the text will be read.  Excluded lines are those that match
        `exclude`, a regex.

        """
        assert text or filename, "CodeParser needs either text or filename"
        self.filename = filename or "<code>"
        self.text = text
        if not self.text:
            try:
                sourcef = open_source(self.filename)
                try:
                    self.text = sourcef.read()
                finally:
                    sourcef.close()
            except IOError:
                _, err, _ = sys.exc_info()
                raise NoSource(
                    "No source for code: %r: %s" % (self.filename, err)
                    )

        self.exclude = exclude

        self.show_tokens = False

        # The text lines of the parsed code.
        self.lines = self.text.split('\n')

        # The line numbers of excluded lines of code.
        self.excluded = set()

        # The line numbers of docstring lines.
        self.docstrings = set()

        # The line numbers of class definitions.
        self.classdefs = set()

        # A dict mapping line numbers to (lo,hi) for multi-line statements.
        self.multiline = {}

        # The line numbers that start statements.
        self.statement_starts = set()

        # Lazily-created ByteParser
        self._byte_parser = None

    def _get_byte_parser(self):
        """Create a ByteParser on demand."""
        if not self._byte_parser:
            self._byte_parser = \
                            ByteParser(text=self.text, filename=self.filename)
        return self._byte_parser
    byte_parser = property(_get_byte_parser)

    def lines_matching(self, *regexes):
        """Find the lines matching one of a list of regexes.

        Returns a set of line numbers, the lines that contain a match for one
        of the regexes in `regexes`.  The entire line needn't match, just a
        part of it.

        """
        regex_c = re.compile(join_regex(regexes))
        matches = set()
        for i, ltext in enumerate(self.lines):
            if regex_c.search(ltext):
                matches.add(i+1)
        return matches

    def _raw_parse(self):
        """Parse the source to find the interesting facts about its lines.

        A handful of member fields are updated.

        """
        # Find lines which match an exclusion pattern.
        if self.exclude:
            self.excluded = self.lines_matching(self.exclude)

        # Tokenize, to find excluded suites, to find docstrings, and to find
        # multi-line statements.
        indent = 0
        exclude_indent = 0
        excluding = False
        prev_toktype = token.INDENT
        first_line = None
        empty = True

        tokgen = tokenize.generate_tokens(StringIO(self.text).readline)
        for toktype, ttext, (slineno, _), (elineno, _), ltext in tokgen:
            if self.show_tokens:                # pragma: no cover
                print("%10s %5s %-20r %r" % (
                    tokenize.tok_name.get(toktype, toktype),
                    nice_pair((slineno, elineno)), ttext, ltext
                    ))
            if toktype == token.INDENT:
                indent += 1
            elif toktype == token.DEDENT:
                indent -= 1
            elif toktype == token.NAME and ttext == 'class':
                # Class definitions look like branches in the byte code, so
                # we need to exclude them.  The simplest way is to note the
                # lines with the 'class' keyword.
                self.classdefs.add(slineno)
            elif toktype == token.OP and ttext == ':':
                if not excluding and elineno in self.excluded:
                    # Start excluding a suite.  We trigger off of the colon
                    # token so that the #pragma comment will be recognized on
                    # the same line as the colon.
                    exclude_indent = indent
                    excluding = True
            elif toktype == token.STRING and prev_toktype == token.INDENT:
                # Strings that are first on an indented line are docstrings.
                # (a trick from trace.py in the stdlib.) This works for
                # 99.9999% of cases.  For the rest (!) see:
                # http://stackoverflow.com/questions/1769332/x/1769794#1769794
                for i in range(slineno, elineno+1):
                    self.docstrings.add(i)
            elif toktype == token.NEWLINE:
                if first_line is not None and elineno != first_line:
                    # We're at the end of a line, and we've ended on a
                    # different line than the first line of the statement,
                    # so record a multi-line range.
                    rng = (first_line, elineno)
                    for l in range(first_line, elineno+1):
                        self.multiline[l] = rng
                first_line = None

            if ttext.strip() and toktype != tokenize.COMMENT:
                # A non-whitespace token.
                empty = False
                if first_line is None:
                    # The token is not whitespace, and is the first in a
                    # statement.
                    first_line = slineno
                    # Check whether to end an excluded suite.
                    if excluding and indent <= exclude_indent:
                        excluding = False
                    if excluding:
                        self.excluded.add(elineno)

            prev_toktype = toktype

        # Find the starts of the executable statements.
        if not empty:
            self.statement_starts.update(self.byte_parser._find_statements())

    def first_line(self, line):
        """Return the first line number of the statement including `line`."""
        rng = self.multiline.get(line)
        if rng:
            first_line = rng[0]
        else:
            first_line = line
        return first_line

    def first_lines(self, lines, ignore=None):
        """Map the line numbers in `lines` to the correct first line of the
        statement.

        Skip any line mentioned in `ignore`.

        Returns a sorted list of the first lines.

        """
        ignore = ignore or []
        lset = set()
        for l in lines:
            if l in ignore:
                continue
            new_l = self.first_line(l)
            if new_l not in ignore:
                lset.add(new_l)
        return sorted(lset)

    def parse_source(self):
        """Parse source text to find executable lines, excluded lines, etc.

        Return values are 1) a sorted list of executable line numbers, and
        2) a sorted list of excluded line numbers.

        Reported line numbers are normalized to the first line of multi-line
        statements.

        """
        self._raw_parse()

        excluded_lines = self.first_lines(self.excluded)
        ignore = excluded_lines + list(self.docstrings)
        lines = self.first_lines(self.statement_starts, ignore)

        return lines, excluded_lines

    def arcs(self):
        """Get information about the arcs available in the code.

        Returns a sorted list of line number pairs.  Line numbers have been
        normalized to the first line of multiline statements.

        """
        all_arcs = []
        for l1, l2 in self.byte_parser._all_arcs():
            fl1 = self.first_line(l1)
            fl2 = self.first_line(l2)
            if fl1 != fl2:
                all_arcs.append((fl1, fl2))
        return sorted(all_arcs)
    arcs = expensive(arcs)

    def exit_counts(self):
        """Get a mapping from line numbers to count of exits from that line.

        Excluded lines are excluded.

        """
        excluded_lines = self.first_lines(self.excluded)
        exit_counts = {}
        for l1, l2 in self.arcs():
            if l1 < 0:
                # Don't ever report -1 as a line number
                continue
            if l1 in excluded_lines:
                # Don't report excluded lines as line numbers.
                continue
            if l2 in excluded_lines:
                # Arcs to excluded lines shouldn't count.
                continue
            if l1 not in exit_counts:
                exit_counts[l1] = 0
            exit_counts[l1] += 1

        # Class definitions have one extra exit, so remove one for each:
        for l in self.classdefs:
            # Ensure key is there: classdefs can include excluded lines.
            if l in exit_counts:
                exit_counts[l] -= 1

        return exit_counts
    exit_counts = expensive(exit_counts)


## Opcodes that guide the ByteParser.

def _opcode(name):
    """Return the opcode by name from the opcode module."""
    return opcode.opmap[name]

def _opcode_set(*names):
    """Return a set of opcodes by the names in `names`."""
    s = set()
    for name in names:
        try:
            s.add(_opcode(name))
        except KeyError:
            pass
    return s

# Opcodes that leave the code object.
OPS_CODE_END = _opcode_set('RETURN_VALUE')

# Opcodes that unconditionally end the code chunk.
OPS_CHUNK_END = _opcode_set(
    'JUMP_ABSOLUTE', 'JUMP_FORWARD', 'RETURN_VALUE', 'RAISE_VARARGS',
    'BREAK_LOOP', 'CONTINUE_LOOP',
    )

# Opcodes that unconditionally begin a new code chunk.  By starting new chunks
# with unconditional jump instructions, we neatly deal with jumps to jumps
# properly.
OPS_CHUNK_BEGIN = _opcode_set('JUMP_ABSOLUTE', 'JUMP_FORWARD')

# Opcodes that push a block on the block stack.
OPS_PUSH_BLOCK = _opcode_set(
    'SETUP_LOOP', 'SETUP_EXCEPT', 'SETUP_FINALLY', 'SETUP_WITH'
    )

# Block types for exception handling.
OPS_EXCEPT_BLOCKS = _opcode_set('SETUP_EXCEPT', 'SETUP_FINALLY')

# Opcodes that pop a block from the block stack.
OPS_POP_BLOCK = _opcode_set('POP_BLOCK')

# Opcodes that have a jump destination, but aren't really a jump.
OPS_NO_JUMP = OPS_PUSH_BLOCK

# Individual opcodes we need below.
OP_BREAK_LOOP = _opcode('BREAK_LOOP')
OP_END_FINALLY = _opcode('END_FINALLY')
OP_COMPARE_OP = _opcode('COMPARE_OP')
COMPARE_EXCEPTION = 10  # just have to get this const from the code.
OP_LOAD_CONST = _opcode('LOAD_CONST')
OP_RETURN_VALUE = _opcode('RETURN_VALUE')


class ByteParser(object):
    """Parse byte codes to understand the structure of code."""

    def __init__(self, code=None, text=None, filename=None):
        if code:
            self.code = code
            self.text = text
        else:
            if not text:
                assert filename, "If no code or text, need a filename"
                sourcef = open_source(filename)
                try:
                    text = sourcef.read()
                finally:
                    sourcef.close()
            self.text = text

            try:
                # Python 2.3 and 2.4 don't like partial last lines, so be sure
                # the text ends nicely for them.
                self.code = compile(text + '\n', filename, "exec")
            except SyntaxError:
                _, synerr, _ = sys.exc_info()
                raise NotPython(
                    "Couldn't parse '%s' as Python source: '%s' at line %d" %
                        (filename, synerr.msg, synerr.lineno)
                    )

        # Alternative Python implementations don't always provide all the
        # attributes on code objects that we need to do the analysis.
        for attr in ['co_lnotab', 'co_firstlineno', 'co_consts', 'co_code']:
            if not hasattr(self.code, attr):
                raise CoverageException(
                    "This implementation of Python doesn't support code "
                    "analysis.\n"
                    "Run coverage.py under CPython for this command."
                    )

    def child_parsers(self):
        """Iterate over all the code objects nested within this one.

        The iteration includes `self` as its first value.

        """
        children = CodeObjects(self.code)
        return [ByteParser(code=c, text=self.text) for c in children]

    # Getting numbers from the lnotab value changed in Py3.0.
    if sys.version_info >= (3, 0):
        def _lnotab_increments(self, lnotab):
            """Return a list of ints from the lnotab bytes in 3.x"""
            return list(lnotab)
    else:
        def _lnotab_increments(self, lnotab):
            """Return a list of ints from the lnotab string in 2.x"""
            return [ord(c) for c in lnotab]

    def _bytes_lines(self):
        """Map byte offsets to line numbers in `code`.

        Uses co_lnotab described in Python/compile.c to map byte offsets to
        line numbers.  Returns a list: [(b0, l0), (b1, l1), ...]

        """
        # Adapted from dis.py in the standard library.
        byte_increments = self._lnotab_increments(self.code.co_lnotab[0::2])
        line_increments = self._lnotab_increments(self.code.co_lnotab[1::2])

        bytes_lines = []
        last_line_num = None
        line_num = self.code.co_firstlineno
        byte_num = 0
        for byte_incr, line_incr in zip(byte_increments, line_increments):
            if byte_incr:
                if line_num != last_line_num:
                    bytes_lines.append((byte_num, line_num))
                    last_line_num = line_num
                byte_num += byte_incr
            line_num += line_incr
        if line_num != last_line_num:
            bytes_lines.append((byte_num, line_num))
        return bytes_lines

    def _find_statements(self):
        """Find the statements in `self.code`.

        Return a set of line numbers that start statements.  Recurses into all
        code objects reachable from `self.code`.

        """
        stmts = set()
        for bp in self.child_parsers():
            # Get all of the lineno information from this code.
            for _, l in bp._bytes_lines():
                stmts.add(l)
        return stmts

    def _split_into_chunks(self):
        """Split the code object into a list of `Chunk` objects.

        Each chunk is only entered at its first instruction, though there can
        be many exits from a chunk.

        Returns a list of `Chunk` objects.

        """

        # The list of chunks so far, and the one we're working on.
        chunks = []
        chunk = None
        bytes_lines_map = dict(self._bytes_lines())

        # The block stack: loops and try blocks get pushed here for the
        # implicit jumps that can occur.
        # Each entry is a tuple: (block type, destination)
        block_stack = []

        # Some op codes are followed by branches that should be ignored.  This
        # is a count of how many ignores are left.
        ignore_branch = 0

        # We have to handle the last two bytecodes specially.
        ult = penult = None

        for bc in ByteCodes(self.code.co_code):
            # Maybe have to start a new chunk
            if bc.offset in bytes_lines_map:
                # Start a new chunk for each source line number.
                if chunk:
                    chunk.exits.add(bc.offset)
                chunk = Chunk(bc.offset, bytes_lines_map[bc.offset])
                chunks.append(chunk)
            elif bc.op in OPS_CHUNK_BEGIN:
                # Jumps deserve their own unnumbered chunk.  This fixes
                # problems with jumps to jumps getting confused.
                if chunk:
                    chunk.exits.add(bc.offset)
                chunk = Chunk(bc.offset)
                chunks.append(chunk)

            if not chunk:
                chunk = Chunk(bc.offset)
                chunks.append(chunk)

            # Look at the opcode
            if bc.jump_to >= 0 and bc.op not in OPS_NO_JUMP:
                if ignore_branch:
                    # Someone earlier wanted us to ignore this branch.
                    ignore_branch -= 1
                else:
                    # The opcode has a jump, it's an exit for this chunk.
                    chunk.exits.add(bc.jump_to)

            if bc.op in OPS_CODE_END:
                # The opcode can exit the code object.
                chunk.exits.add(-self.code.co_firstlineno)
            if bc.op in OPS_PUSH_BLOCK:
                # The opcode adds a block to the block_stack.
                block_stack.append((bc.op, bc.jump_to))
            if bc.op in OPS_POP_BLOCK:
                # The opcode pops a block from the block stack.
                block_stack.pop()
            if bc.op in OPS_CHUNK_END:
                # This opcode forces the end of the chunk.
                if bc.op == OP_BREAK_LOOP:
                    # A break is implicit: jump where the top of the
                    # block_stack points.
                    chunk.exits.add(block_stack[-1][1])
                chunk = None
            if bc.op == OP_END_FINALLY:
                if block_stack:
                    # A break that goes through a finally will jump to whatever
                    # block is on top of the stack.
                    chunk.exits.add(block_stack[-1][1])
                # For the finally clause we need to find the closest exception
                # block, and use its jump target as an exit.
                for iblock in range(len(block_stack)-1, -1, -1):
                    if block_stack[iblock][0] in OPS_EXCEPT_BLOCKS:
                        chunk.exits.add(block_stack[iblock][1])
                        break
            if bc.op == OP_COMPARE_OP and bc.arg == COMPARE_EXCEPTION:
                # This is an except clause.  We want to overlook the next
                # branch, so that except's don't count as branches.
                ignore_branch += 1

            penult = ult
            ult = bc

        if chunks:
            # The last two bytecodes could be a dummy "return None" that
            # shouldn't be counted as real code. Every Python code object seems
            # to end with a return, and a "return None" is inserted if there
            # isn't an explicit return in the source.
            if ult and penult:
                if penult.op == OP_LOAD_CONST and ult.op == OP_RETURN_VALUE:
                    if self.code.co_consts[penult.arg] is None:
                        # This is "return None", but is it dummy?  A real line
                        # would be a last chunk all by itself.
                        if chunks[-1].byte != penult.offset:
                            ex = -self.code.co_firstlineno
                            # Split the last chunk
                            last_chunk = chunks[-1]
                            last_chunk.exits.remove(ex)
                            last_chunk.exits.add(penult.offset)
                            chunk = Chunk(penult.offset)
                            chunk.exits.add(ex)
                            chunks.append(chunk)

            # Give all the chunks a length.
            chunks[-1].length = bc.next_offset - chunks[-1].byte
            for i in range(len(chunks)-1):
                chunks[i].length = chunks[i+1].byte - chunks[i].byte

        return chunks

    def _arcs(self):
        """Find the executable arcs in the code.

        Returns a set of pairs, (from,to).  From and to are integer line
        numbers.  If from is < 0, then the arc is an entrance into the code
        object.  If to is < 0, the arc is an exit from the code object.

        """
        chunks = self._split_into_chunks()

        # A map from byte offsets to chunks jumped into.
        byte_chunks = dict([(c.byte, c) for c in chunks])

        # Build a map from byte offsets to actual lines reached.
        byte_lines = {}
        bytes_to_add = set([c.byte for c in chunks])

        while bytes_to_add:
            byte_to_add = bytes_to_add.pop()
            if byte_to_add in byte_lines or byte_to_add < 0:
                continue

            # Which lines does this chunk lead to?
            bytes_considered = set()
            bytes_to_consider = [byte_to_add]
            lines = set()

            while bytes_to_consider:
                byte = bytes_to_consider.pop()
                bytes_considered.add(byte)

                # Find chunk for byte
                try:
                    ch = byte_chunks[byte]
                except KeyError:
                    for ch in chunks:
                        if ch.byte <= byte < ch.byte+ch.length:
                            break
                    else:
                        # No chunk for this byte!
                        raise Exception("Couldn't find chunk @ %d" % byte)
                    byte_chunks[byte] = ch

                if ch.line:
                    lines.add(ch.line)
                else:
                    for ex in ch.exits:
                        if ex < 0:
                            lines.add(ex)
                        elif ex not in bytes_considered:
                            bytes_to_consider.append(ex)

                bytes_to_add.update(ch.exits)

            byte_lines[byte_to_add] = lines

        # Figure out for each chunk where the exits go.
        arcs = set()
        for chunk in chunks:
            if chunk.line:
                for ex in chunk.exits:
                    if ex < 0:
                        exit_lines = [ex]
                    else:
                        exit_lines = byte_lines[ex]
                    for exit_line in exit_lines:
                        if chunk.line != exit_line:
                            arcs.add((chunk.line, exit_line))
        for line in byte_lines[0]:
            arcs.add((-1, line))

        return arcs

    def _all_chunks(self):
        """Returns a list of `Chunk` objects for this code and its children.

        See `_split_into_chunks` for details.

        """
        chunks = []
        for bp in self.child_parsers():
            chunks.extend(bp._split_into_chunks())

        return chunks

    def _all_arcs(self):
        """Get the set of all arcs in this code object and its children.

        See `_arcs` for details.

        """
        arcs = set()
        for bp in self.child_parsers():
            arcs.update(bp._arcs())

        return arcs


class Chunk(object):
    """A sequence of bytecodes with a single entrance.

    To analyze byte code, we have to divide it into chunks, sequences of byte
    codes such that each basic block has only one entrance, the first
    instruction in the block.

    This is almost the CS concept of `basic block`_, except that we're willing
    to have many exits from a chunk, and "basic block" is a more cumbersome
    term.

    .. _basic block: http://en.wikipedia.org/wiki/Basic_block

    An exit < 0 means the chunk can leave the code (return).  The exit is
    the negative of the starting line number of the code block.

    """
    def __init__(self, byte, line=0):
        self.byte = byte
        self.line = line
        self.length = 0
        self.exits = set()

    def __repr__(self):
        return "<%d+%d @%d %r>" % (
            self.byte, self.length, self.line, list(self.exits)
            )
