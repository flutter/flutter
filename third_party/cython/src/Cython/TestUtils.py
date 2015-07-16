import Cython.Compiler.Errors as Errors
from Cython.CodeWriter import CodeWriter
from Cython.Compiler.TreeFragment import TreeFragment, strip_common_indent
from Cython.Compiler.Visitor import TreeVisitor, VisitorTransform
from Cython.Compiler import TreePath

import unittest
import os, sys
import tempfile


class NodeTypeWriter(TreeVisitor):
    def __init__(self):
        super(NodeTypeWriter, self).__init__()
        self._indents = 0
        self.result = []

    def visit_Node(self, node):
        if not self.access_path:
            name = u"(root)"
        else:
            tip = self.access_path[-1]
            if tip[2] is not None:
                name = u"%s[%d]" % tip[1:3]
            else:
                name = tip[1]

        self.result.append(u"  " * self._indents +
                           u"%s: %s" % (name, node.__class__.__name__))
        self._indents += 1
        self.visitchildren(node)
        self._indents -= 1


def treetypes(root):
    """Returns a string representing the tree by class names.
    There's a leading and trailing whitespace so that it can be
    compared by simple string comparison while still making test
    cases look ok."""
    w = NodeTypeWriter()
    w.visit(root)
    return u"\n".join([u""] + w.result + [u""])


class CythonTest(unittest.TestCase):

    def setUp(self):
        self.listing_file = Errors.listing_file
        self.echo_file = Errors.echo_file
        Errors.listing_file = Errors.echo_file = None

    def tearDown(self):
        Errors.listing_file = self.listing_file
        Errors.echo_file = self.echo_file

    def assertLines(self, expected, result):
        "Checks that the given strings or lists of strings are equal line by line"
        if not isinstance(expected, list): expected = expected.split(u"\n")
        if not isinstance(result, list): result = result.split(u"\n")
        for idx, (expected_line, result_line) in enumerate(zip(expected, result)):
            self.assertEqual(expected_line, result_line, "Line %d:\nExp: %s\nGot: %s" % (idx, expected_line, result_line))
        self.assertEqual(len(expected), len(result),
            "Unmatched lines. Got:\n%s\nExpected:\n%s" % ("\n".join(expected), u"\n".join(result)))

    def codeToLines(self, tree):
        writer = CodeWriter()
        writer.write(tree)
        return writer.result.lines

    def codeToString(self, tree):
        return "\n".join(self.codeToLines(tree))

    def assertCode(self, expected, result_tree):
        result_lines = self.codeToLines(result_tree)

        expected_lines = strip_common_indent(expected.split("\n"))

        for idx, (line, expected_line) in enumerate(zip(result_lines, expected_lines)):
            self.assertEqual(expected_line, line, "Line %d:\nGot: %s\nExp: %s" % (idx, line, expected_line))
        self.assertEqual(len(result_lines), len(expected_lines),
            "Unmatched lines. Got:\n%s\nExpected:\n%s" % ("\n".join(result_lines), expected))

    def assertNodeExists(self, path, result_tree):
        self.assertNotEqual(TreePath.find_first(result_tree, path), None,
                            "Path '%s' not found in result tree" % path)

    def fragment(self, code, pxds={}, pipeline=[]):
        "Simply create a tree fragment using the name of the test-case in parse errors."
        name = self.id()
        if name.startswith("__main__."): name = name[len("__main__."):]
        name = name.replace(".", "_")
        return TreeFragment(code, name, pxds, pipeline=pipeline)

    def treetypes(self, root):
        return treetypes(root)

    def should_fail(self, func, exc_type=Exception):
        """Calls "func" and fails if it doesn't raise the right exception
        (any exception by default). Also returns the exception in question.
        """
        try:
            func()
            self.fail("Expected an exception of type %r" % exc_type)
        except exc_type, e:
            self.assert_(isinstance(e, exc_type))
            return e

    def should_not_fail(self, func):
        """Calls func and succeeds if and only if no exception is raised
        (i.e. converts exception raising into a failed testcase). Returns
        the return value of func."""
        try:
            return func()
        except:
            self.fail(str(sys.exc_info()[1]))


class TransformTest(CythonTest):
    """
    Utility base class for transform unit tests. It is based around constructing
    test trees (either explicitly or by parsing a Cython code string); running
    the transform, serialize it using a customized Cython serializer (with
    special markup for nodes that cannot be represented in Cython),
    and do a string-comparison line-by-line of the result.

    To create a test case:
     - Call run_pipeline. The pipeline should at least contain the transform you
       are testing; pyx should be either a string (passed to the parser to
       create a post-parse tree) or a node representing input to pipeline.
       The result will be a transformed result.

     - Check that the tree is correct. If wanted, assertCode can be used, which
       takes a code string as expected, and a ModuleNode in result_tree
       (it serializes the ModuleNode to a string and compares line-by-line).

    All code strings are first stripped for whitespace lines and then common
    indentation.

    Plans: One could have a pxd dictionary parameter to run_pipeline.
    """

    def run_pipeline(self, pipeline, pyx, pxds={}):
        tree = self.fragment(pyx, pxds).root
        # Run pipeline
        for T in pipeline:
            tree = T(tree)
        return tree


class TreeAssertVisitor(VisitorTransform):
    # actually, a TreeVisitor would be enough, but this needs to run
    # as part of the compiler pipeline

    def visit_CompilerDirectivesNode(self, node):
        directives = node.directives
        if 'test_assert_path_exists' in directives:
            for path in directives['test_assert_path_exists']:
                if TreePath.find_first(node, path) is None:
                    Errors.error(
                        node.pos,
                        "Expected path '%s' not found in result tree" % path)
        if 'test_fail_if_path_exists' in directives:
            for path in directives['test_fail_if_path_exists']:
                if TreePath.find_first(node, path) is not None:
                    Errors.error(
                        node.pos,
                        "Unexpected path '%s' found in result tree" %  path)
        self.visitchildren(node)
        return node

    visit_Node = VisitorTransform.recurse_to_children


def unpack_source_tree(tree_file, dir=None):
    if dir is None:
        dir = tempfile.mkdtemp()
    header = []
    cur_file = None
    f = open(tree_file)
    try:
        lines = f.readlines()
    finally:
        f.close()
    del f
    try:
        for line in lines:
            if line[:5] == '#####':
                filename = line.strip().strip('#').strip().replace('/', os.path.sep)
                path = os.path.join(dir, filename)
                if not os.path.exists(os.path.dirname(path)):
                    os.makedirs(os.path.dirname(path))
                if cur_file is not None:
                    f, cur_file = cur_file, None
                    f.close()
                cur_file = open(path, 'w')
            elif cur_file is not None:
                cur_file.write(line)
            elif line.strip() and not line.lstrip().startswith('#'):
                if line.strip() not in ('"""', "'''"):
                    header.append(line)
    finally:
        if cur_file is not None:
            cur_file.close()
    return dir, ''.join(header)
