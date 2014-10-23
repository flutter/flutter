"""Bytecode manipulation for coverage.py"""

import opcode, sys, types

class ByteCode(object):
    """A single bytecode."""
    def __init__(self):
        # The offset of this bytecode in the code object.
        self.offset = -1

        # The opcode, defined in the `opcode` module.
        self.op = -1

        # The argument, a small integer, whose meaning depends on the opcode.
        self.arg = -1

        # The offset in the code object of the next bytecode.
        self.next_offset = -1

        # The offset to jump to.
        self.jump_to = -1


class ByteCodes(object):
    """Iterator over byte codes in `code`.

    Returns `ByteCode` objects.

    """
    def __init__(self, code):
        self.code = code
        self.offset = 0

    if sys.version_info >= (3, 0):
        def __getitem__(self, i):
            return self.code[i]
    else:
        def __getitem__(self, i):
            return ord(self.code[i])

    def __iter__(self):
        return self

    def __next__(self):
        if self.offset >= len(self.code):
            raise StopIteration

        bc = ByteCode()
        bc.op = self[self.offset]
        bc.offset = self.offset

        next_offset = self.offset+1
        if bc.op >= opcode.HAVE_ARGUMENT:
            bc.arg = self[self.offset+1] + 256*self[self.offset+2]
            next_offset += 2

            label = -1
            if bc.op in opcode.hasjrel:
                label = next_offset + bc.arg
            elif bc.op in opcode.hasjabs:
                label = bc.arg
            bc.jump_to = label

        bc.next_offset = self.offset = next_offset
        return bc

    next = __next__     # Py2k uses an old-style non-dunder name.


class CodeObjects(object):
    """Iterate over all the code objects in `code`."""
    def __init__(self, code):
        self.stack = [code]

    def __iter__(self):
        return self

    def __next__(self):
        if self.stack:
            # We're going to return the code object on the stack, but first
            # push its children for later returning.
            code = self.stack.pop()
            for c in code.co_consts:
                if isinstance(c, types.CodeType):
                    self.stack.append(c)
            return code

        raise StopIteration

    next = __next__
