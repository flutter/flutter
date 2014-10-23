"""A simple Python template renderer, for a nano-subset of Django syntax."""

# Coincidentally named the same as http://code.activestate.com/recipes/496702/

import re, sys

class Templite(object):
    """A simple template renderer, for a nano-subset of Django syntax.

    Supported constructs are extended variable access::

        {{var.modifer.modifier|filter|filter}}

    loops::

        {% for var in list %}...{% endfor %}

    and ifs::

        {% if var %}...{% endif %}

    Comments are within curly-hash markers::

        {# This will be ignored #}

    Construct a Templite with the template text, then use `render` against a
    dictionary context to create a finished string.

    """
    def __init__(self, text, *contexts):
        """Construct a Templite with the given `text`.

        `contexts` are dictionaries of values to use for future renderings.
        These are good for filters and global values.

        """
        self.text = text
        self.context = {}
        for context in contexts:
            self.context.update(context)

        # Split the text to form a list of tokens.
        toks = re.split(r"(?s)({{.*?}}|{%.*?%}|{#.*?#})", text)

        # Parse the tokens into a nested list of operations.  Each item in the
        # list is a tuple with an opcode, and arguments.  They'll be
        # interpreted by TempliteEngine.
        #
        # When parsing an action tag with nested content (if, for), the current
        # ops list is pushed onto ops_stack, and the parsing continues in a new
        # ops list that is part of the arguments to the if or for op.
        ops = []
        ops_stack = []
        for tok in toks:
            if tok.startswith('{{'):
                # Expression: ('exp', expr)
                ops.append(('exp', tok[2:-2].strip()))
            elif tok.startswith('{#'):
                # Comment: ignore it and move on.
                continue
            elif tok.startswith('{%'):
                # Action tag: split into words and parse further.
                words = tok[2:-2].strip().split()
                if words[0] == 'if':
                    # If: ('if', (expr, body_ops))
                    if_ops = []
                    assert len(words) == 2
                    ops.append(('if', (words[1], if_ops)))
                    ops_stack.append(ops)
                    ops = if_ops
                elif words[0] == 'for':
                    # For: ('for', (varname, listexpr, body_ops))
                    assert len(words) == 4 and words[2] == 'in'
                    for_ops = []
                    ops.append(('for', (words[1], words[3], for_ops)))
                    ops_stack.append(ops)
                    ops = for_ops
                elif words[0].startswith('end'):
                    # Endsomething.  Pop the ops stack
                    ops = ops_stack.pop()
                    assert ops[-1][0] == words[0][3:]
                else:
                    raise SyntaxError("Don't understand tag %r" % words)
            else:
                ops.append(('lit', tok))

        assert not ops_stack, "Unmatched action tag: %r" % ops_stack[-1][0]
        self.ops = ops

    def render(self, context=None):
        """Render this template by applying it to `context`.

        `context` is a dictionary of values to use in this rendering.

        """
        # Make the complete context we'll use.
        ctx = dict(self.context)
        if context:
            ctx.update(context)

        # Run it through an engine, and return the result.
        engine = _TempliteEngine(ctx)
        engine.execute(self.ops)
        return "".join(engine.result)


class _TempliteEngine(object):
    """Executes Templite objects to produce strings."""
    def __init__(self, context):
        self.context = context
        self.result = []

    def execute(self, ops):
        """Execute `ops` in the engine.

        Called recursively for the bodies of if's and loops.

        """
        for op, args in ops:
            if op == 'lit':
                self.result.append(args)
            elif op == 'exp':
                try:
                    self.result.append(str(self.evaluate(args)))
                except:
                    exc_class, exc, _ = sys.exc_info()
                    new_exc = exc_class("Couldn't evaluate {{ %s }}: %s"
                                        % (args, exc))
                    raise new_exc
            elif op == 'if':
                expr, body = args
                if self.evaluate(expr):
                    self.execute(body)
            elif op == 'for':
                var, lis, body = args
                vals = self.evaluate(lis)
                for val in vals:
                    self.context[var] = val
                    self.execute(body)
            else:
                raise AssertionError("TempliteEngine doesn't grok op %r" % op)

    def evaluate(self, expr):
        """Evaluate an expression.

        `expr` can have pipes and dots to indicate data access and filtering.

        """
        if "|" in expr:
            pipes = expr.split("|")
            value = self.evaluate(pipes[0])
            for func in pipes[1:]:
                value = self.evaluate(func)(value)
        elif "." in expr:
            dots = expr.split('.')
            value = self.evaluate(dots[0])
            for dot in dots[1:]:
                try:
                    value = getattr(value, dot)
                except AttributeError:
                    value = value[dot]
                if hasattr(value, '__call__'):
                    value = value()
        else:
            value = self.context[expr]
        return value
