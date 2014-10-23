"""Better tokenizing for coverage.py."""

import keyword, re, token, tokenize
from coverage.backward import StringIO              # pylint: disable=W0622

def phys_tokens(toks):
    """Return all physical tokens, even line continuations.

    tokenize.generate_tokens() doesn't return a token for the backslash that
    continues lines.  This wrapper provides those tokens so that we can
    re-create a faithful representation of the original source.

    Returns the same values as generate_tokens()

    """
    last_line = None
    last_lineno = -1
    last_ttype = None
    for ttype, ttext, (slineno, scol), (elineno, ecol), ltext in toks:
        if last_lineno != elineno:
            if last_line and last_line[-2:] == "\\\n":
                # We are at the beginning of a new line, and the last line
                # ended with a backslash.  We probably have to inject a
                # backslash token into the stream. Unfortunately, there's more
                # to figure out.  This code::
                #
                #   usage = """\
                #   HEY THERE
                #   """
                #
                # triggers this condition, but the token text is::
                #
                #   '"""\\\nHEY THERE\n"""'
                #
                # so we need to figure out if the backslash is already in the
                # string token or not.
                inject_backslash = True
                if last_ttype == tokenize.COMMENT:
                    # Comments like this \
                    # should never result in a new token.
                    inject_backslash = False
                elif ttype == token.STRING:
                    if "\n" in ttext and ttext.split('\n', 1)[0][-1] == '\\':
                        # It's a multiline string and the first line ends with
                        # a backslash, so we don't need to inject another.
                        inject_backslash = False
                if inject_backslash:
                    # Figure out what column the backslash is in.
                    ccol = len(last_line.split("\n")[-2]) - 1
                    # Yield the token, with a fake token type.
                    yield (
                        99999, "\\\n",
                        (slineno, ccol), (slineno, ccol+2),
                        last_line
                        )
            last_line = ltext
            last_ttype = ttype
        yield ttype, ttext, (slineno, scol), (elineno, ecol), ltext
        last_lineno = elineno


def source_token_lines(source):
    """Generate a series of lines, one for each line in `source`.

    Each line is a list of pairs, each pair is a token::

        [('key', 'def'), ('ws', ' '), ('nam', 'hello'), ('op', '('), ... ]

    Each pair has a token class, and the token text.

    If you concatenate all the token texts, and then join them with newlines,
    you should have your original `source` back, with two differences:
    trailing whitespace is not preserved, and a final line with no newline
    is indistinguishable from a final line with a newline.

    """
    ws_tokens = [token.INDENT, token.DEDENT, token.NEWLINE, tokenize.NL]
    line = []
    col = 0
    source = source.expandtabs(8).replace('\r\n', '\n')
    tokgen = tokenize.generate_tokens(StringIO(source).readline)
    for ttype, ttext, (_, scol), (_, ecol), _ in phys_tokens(tokgen):
        mark_start = True
        for part in re.split('(\n)', ttext):
            if part == '\n':
                yield line
                line = []
                col = 0
                mark_end = False
            elif part == '':
                mark_end = False
            elif ttype in ws_tokens:
                mark_end = False
            else:
                if mark_start and scol > col:
                    line.append(("ws", " " * (scol - col)))
                    mark_start = False
                tok_class = tokenize.tok_name.get(ttype, 'xx').lower()[:3]
                if ttype == token.NAME and keyword.iskeyword(ttext):
                    tok_class = "key"
                line.append((tok_class, part))
                mark_end = True
            scol = 0
        if mark_end:
            col = ecol

    if line:
        yield line
