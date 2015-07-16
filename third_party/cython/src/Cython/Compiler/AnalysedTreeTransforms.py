from Visitor import ScopeTrackingTransform
from Nodes import StatListNode, SingleAssignmentNode, CFuncDefNode, DefNode
from ExprNodes import DictNode, DictItemNode, NameNode, UnicodeNode
from PyrexTypes import py_object_type
from StringEncoding import EncodedString
import Symtab

class AutoTestDictTransform(ScopeTrackingTransform):
    # Handles autotestdict directive

    blacklist = ['__cinit__', '__dealloc__', '__richcmp__',
                 '__nonzero__', '__bool__',
                 '__len__', '__contains__']

    def visit_ModuleNode(self, node):
        if node.is_pxd:
            return node
        self.scope_type = 'module'
        self.scope_node = node

        if not self.current_directives['autotestdict']:
            return node
        self.all_docstrings = self.current_directives['autotestdict.all']
        self.cdef_docstrings = self.all_docstrings or self.current_directives['autotestdict.cdef']

        assert isinstance(node.body, StatListNode)

        # First see if __test__ is already created
        if u'__test__' in node.scope.entries:
            # Do nothing
            return node

        pos = node.pos

        self.tests = []
        self.testspos = node.pos

        test_dict_entry = node.scope.declare_var(EncodedString(u'__test__'),
                                                 py_object_type,
                                                 pos,
                                                 visibility='public')
        create_test_dict_assignment = SingleAssignmentNode(pos,
            lhs=NameNode(pos, name=EncodedString(u'__test__'),
                         entry=test_dict_entry),
            rhs=DictNode(pos, key_value_pairs=self.tests))
        self.visitchildren(node)
        node.body.stats.append(create_test_dict_assignment)
        return node

    def add_test(self, testpos, path, doctest):
        pos = self.testspos
        keystr = u'%s (line %d)' % (path, testpos[1])
        key = UnicodeNode(pos, value=EncodedString(keystr))
        value = UnicodeNode(pos, value=doctest)
        self.tests.append(DictItemNode(pos, key=key, value=value))

    def visit_ExprNode(self, node):
        # expressions cannot contain functions and lambda expressions
        # do not have a docstring
        return node

    def visit_FuncDefNode(self, node):
        if not node.doc or (isinstance(node, DefNode) and node.fused_py_func):
            return node
        if not self.cdef_docstrings:
            if isinstance(node, CFuncDefNode) and not node.py_func:
                return node
        if not self.all_docstrings and '>>>' not in node.doc:
            return node

        pos = self.testspos
        if self.scope_type == 'module':
            path = node.entry.name
        elif self.scope_type in ('pyclass', 'cclass'):
            if isinstance(node, CFuncDefNode):
                if node.py_func is not None:
                    name = node.py_func.name
                else:
                    name = node.entry.name
            else:
                name = node.name
            if self.scope_type == 'cclass' and name in self.blacklist:
                return node
            if self.scope_type == 'pyclass':
                class_name = self.scope_node.name
            else:
                class_name = self.scope_node.class_name
            if isinstance(node.entry.scope, Symtab.PropertyScope):
                property_method_name = node.entry.scope.name
                path = "%s.%s.%s" % (class_name, node.entry.scope.name,
                                     node.entry.name)
            else:
                path = "%s.%s" % (class_name, node.entry.name)
        else:
            assert False
        self.add_test(node.pos, path, node.doc)
        return node
