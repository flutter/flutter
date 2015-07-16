#
# TreeFragments - parsing of strings to trees
#

import re
from StringIO import StringIO
from Scanning import PyrexScanner, StringSourceDescriptor
from Symtab import ModuleScope
import PyrexTypes
from Visitor import VisitorTransform
from Nodes import Node, StatListNode
from ExprNodes import NameNode
import Parsing
import Main
import UtilNodes

"""
Support for parsing strings into code trees.
"""

class StringParseContext(Main.Context):
    def __init__(self, name, include_directories=None):
        if include_directories is None: include_directories = []
        Main.Context.__init__(self, include_directories, {},
                              create_testscope=False)
        self.module_name = name

    def find_module(self, module_name, relative_to = None, pos = None, need_pxd = 1):
        if module_name not in (self.module_name, 'cython'):
            raise AssertionError("Not yet supporting any cimports/includes from string code snippets")
        return ModuleScope(module_name, parent_module = None, context = self)

def parse_from_strings(name, code, pxds={}, level=None, initial_pos=None,
                       context=None, allow_struct_enum_decorator=False):
    """
    Utility method to parse a (unicode) string of code. This is mostly
    used for internal Cython compiler purposes (creating code snippets
    that transforms should emit, as well as unit testing).

    code - a unicode string containing Cython (module-level) code
    name - a descriptive name for the code source (to use in error messages etc.)

    RETURNS

    The tree, i.e. a ModuleNode. The ModuleNode's scope attribute is
    set to the scope used when parsing.
    """
    if context is None:
        context = StringParseContext(name)
    # Since source files carry an encoding, it makes sense in this context
    # to use a unicode string so that code fragments don't have to bother
    # with encoding. This means that test code passed in should not have an
    # encoding header.
    assert isinstance(code, unicode), "unicode code snippets only please"
    encoding = "UTF-8"

    module_name = name
    if initial_pos is None:
        initial_pos = (name, 1, 0)
    code_source = StringSourceDescriptor(name, code)

    scope = context.find_module(module_name, pos = initial_pos, need_pxd = 0)

    buf = StringIO(code)

    scanner = PyrexScanner(buf, code_source, source_encoding = encoding,
                     scope = scope, context = context, initial_pos = initial_pos)
    ctx = Parsing.Ctx(allow_struct_enum_decorator=allow_struct_enum_decorator)

    if level is None:
        tree = Parsing.p_module(scanner, 0, module_name, ctx=ctx)
        tree.scope = scope
        tree.is_pxd = False
    else:
        tree = Parsing.p_code(scanner, level=level, ctx=ctx)

    tree.scope = scope
    return tree

class TreeCopier(VisitorTransform):
    def visit_Node(self, node):
        if node is None:
            return node
        else:
            c = node.clone_node()
            self.visitchildren(c)
            return c

class ApplyPositionAndCopy(TreeCopier):
    def __init__(self, pos):
        super(ApplyPositionAndCopy, self).__init__()
        self.pos = pos

    def visit_Node(self, node):
        copy = super(ApplyPositionAndCopy, self).visit_Node(node)
        copy.pos = self.pos
        return copy

class TemplateTransform(VisitorTransform):
    """
    Makes a copy of a template tree while doing substitutions.

    A dictionary "substitutions" should be passed in when calling
    the transform; mapping names to replacement nodes. Then replacement
    happens like this:
     - If an ExprStatNode contains a single NameNode, whose name is
       a key in the substitutions dictionary, the ExprStatNode is
       replaced with a copy of the tree given in the dictionary.
       It is the responsibility of the caller that the replacement
       node is a valid statement.
     - If a single NameNode is otherwise encountered, it is replaced
       if its name is listed in the substitutions dictionary in the
       same way. It is the responsibility of the caller to make sure
       that the replacement nodes is a valid expression.

    Also a list "temps" should be passed. Any names listed will
    be transformed into anonymous, temporary names.

    Currently supported for tempnames is:
    NameNode
    (various function and class definition nodes etc. should be added to this)

    Each replacement node gets the position of the substituted node
    recursively applied to every member node.
    """

    temp_name_counter = 0

    def __call__(self, node, substitutions, temps, pos):
        self.substitutions = substitutions
        self.pos = pos
        tempmap = {}
        temphandles = []
        for temp in temps:
            TemplateTransform.temp_name_counter += 1
            handle = UtilNodes.TempHandle(PyrexTypes.py_object_type)
            tempmap[temp] = handle
            temphandles.append(handle)
        self.tempmap = tempmap
        result = super(TemplateTransform, self).__call__(node)
        if temps:
            result = UtilNodes.TempsBlockNode(self.get_pos(node),
                                              temps=temphandles,
                                              body=result)
        return result

    def get_pos(self, node):
        if self.pos:
            return self.pos
        else:
            return node.pos

    def visit_Node(self, node):
        if node is None:
            return None
        else:
            c = node.clone_node()
            if self.pos is not None:
                c.pos = self.pos
            self.visitchildren(c)
            return c

    def try_substitution(self, node, key):
        sub = self.substitutions.get(key)
        if sub is not None:
            pos = self.pos
            if pos is None: pos = node.pos
            return ApplyPositionAndCopy(pos)(sub)
        else:
            return self.visit_Node(node) # make copy as usual

    def visit_NameNode(self, node):
        temphandle = self.tempmap.get(node.name)
        if temphandle:
            # Replace name with temporary
            return temphandle.ref(self.get_pos(node))
        else:
            return self.try_substitution(node, node.name)

    def visit_ExprStatNode(self, node):
        # If an expression-as-statement consists of only a replaceable
        # NameNode, we replace the entire statement, not only the NameNode
        if isinstance(node.expr, NameNode):
            return self.try_substitution(node, node.expr.name)
        else:
            return self.visit_Node(node)

def copy_code_tree(node):
    return TreeCopier()(node)

INDENT_RE = re.compile(ur"^ *")
def strip_common_indent(lines):
    "Strips empty lines and common indentation from the list of strings given in lines"
    # TODO: Facilitate textwrap.indent instead
    lines = [x for x in lines if x.strip() != u""]
    minindent = min([len(INDENT_RE.match(x).group(0)) for x in lines])
    lines = [x[minindent:] for x in lines]
    return lines

class TreeFragment(object):
    def __init__(self, code, name="(tree fragment)", pxds={}, temps=[], pipeline=[], level=None, initial_pos=None):
        if isinstance(code, unicode):
            def fmt(x): return u"\n".join(strip_common_indent(x.split(u"\n")))

            fmt_code = fmt(code)
            fmt_pxds = {}
            for key, value in pxds.iteritems():
                fmt_pxds[key] = fmt(value)
            mod = t = parse_from_strings(name, fmt_code, fmt_pxds, level=level, initial_pos=initial_pos)
            if level is None:
                t = t.body # Make sure a StatListNode is at the top
            if not isinstance(t, StatListNode):
                t = StatListNode(pos=mod.pos, stats=[t])
            for transform in pipeline:
                if transform is None:
                    continue
                t = transform(t)
            self.root = t
        elif isinstance(code, Node):
            if pxds != {}: raise NotImplementedError()
            self.root = code
        else:
            raise ValueError("Unrecognized code format (accepts unicode and Node)")
        self.temps = temps

    def copy(self):
        return copy_code_tree(self.root)

    def substitute(self, nodes={}, temps=[], pos = None):
        return TemplateTransform()(self.root,
                                   substitutions = nodes,
                                   temps = self.temps + temps, pos = pos)

class SetPosTransform(VisitorTransform):
    def __init__(self, pos):
        super(SetPosTransform, self).__init__()
        self.pos = pos

    def visit_Node(self, node):
        node.pos = self.pos
        self.visitchildren(node)
        return node
