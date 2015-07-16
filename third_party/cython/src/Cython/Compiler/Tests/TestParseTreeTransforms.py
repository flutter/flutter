import os

from Cython.Compiler import CmdLine
from Cython.TestUtils import TransformTest
from Cython.Compiler.ParseTreeTransforms import *
from Cython.Compiler.Nodes import *
from Cython.Compiler import Main, Symtab


class TestNormalizeTree(TransformTest):
    def test_parserbehaviour_is_what_we_coded_for(self):
        t = self.fragment(u"if x: y").root
        self.assertLines(u"""
(root): StatListNode
  stats[0]: IfStatNode
    if_clauses[0]: IfClauseNode
      condition: NameNode
      body: ExprStatNode
        expr: NameNode
""", self.treetypes(t))

    def test_wrap_singlestat(self):
        t = self.run_pipeline([NormalizeTree(None)], u"if x: y")
        self.assertLines(u"""
(root): StatListNode
  stats[0]: IfStatNode
    if_clauses[0]: IfClauseNode
      condition: NameNode
      body: StatListNode
        stats[0]: ExprStatNode
          expr: NameNode
""", self.treetypes(t))

    def test_wrap_multistat(self):
        t = self.run_pipeline([NormalizeTree(None)], u"""
            if z:
                x
                y
        """)
        self.assertLines(u"""
(root): StatListNode
  stats[0]: IfStatNode
    if_clauses[0]: IfClauseNode
      condition: NameNode
      body: StatListNode
        stats[0]: ExprStatNode
          expr: NameNode
        stats[1]: ExprStatNode
          expr: NameNode
""", self.treetypes(t))

    def test_statinexpr(self):
        t = self.run_pipeline([NormalizeTree(None)], u"""
            a, b = x, y
        """)
        self.assertLines(u"""
(root): StatListNode
  stats[0]: SingleAssignmentNode
    lhs: TupleNode
      args[0]: NameNode
      args[1]: NameNode
    rhs: TupleNode
      args[0]: NameNode
      args[1]: NameNode
""", self.treetypes(t))

    def test_wrap_offagain(self):
        t = self.run_pipeline([NormalizeTree(None)], u"""
            x
            y
            if z:
                x
        """)
        self.assertLines(u"""
(root): StatListNode
  stats[0]: ExprStatNode
    expr: NameNode
  stats[1]: ExprStatNode
    expr: NameNode
  stats[2]: IfStatNode
    if_clauses[0]: IfClauseNode
      condition: NameNode
      body: StatListNode
        stats[0]: ExprStatNode
          expr: NameNode
""", self.treetypes(t))


    def test_pass_eliminated(self):
        t = self.run_pipeline([NormalizeTree(None)], u"pass")
        self.assert_(len(t.stats) == 0)

class TestWithTransform(object): # (TransformTest): # Disabled!

    def test_simplified(self):
        t = self.run_pipeline([WithTransform(None)], u"""
        with x:
            y = z ** 3
        """)

        self.assertCode(u"""

        $0_0 = x
        $0_2 = $0_0.__exit__
        $0_0.__enter__()
        $0_1 = True
        try:
            try:
                $1_0 = None
                y = z ** 3
            except:
                $0_1 = False
                if (not $0_2($1_0)):
                    raise
        finally:
            if $0_1:
                $0_2(None, None, None)

        """, t)

    def test_basic(self):
        t = self.run_pipeline([WithTransform(None)], u"""
        with x as y:
            y = z ** 3
        """)
        self.assertCode(u"""

        $0_0 = x
        $0_2 = $0_0.__exit__
        $0_3 = $0_0.__enter__()
        $0_1 = True
        try:
            try:
                $1_0 = None
                y = $0_3
                y = z ** 3
            except:
                $0_1 = False
                if (not $0_2($1_0)):
                    raise
        finally:
            if $0_1:
                $0_2(None, None, None)

        """, t)


class TestInterpretCompilerDirectives(TransformTest):
    """
    This class tests the parallel directives AST-rewriting and importing.
    """

    # Test the parallel directives (c)importing

    import_code = u"""
        cimport cython.parallel
        cimport cython.parallel as par
        from cython cimport parallel as par2
        from cython cimport parallel

        from cython.parallel cimport threadid as tid
        from cython.parallel cimport threadavailable as tavail
        from cython.parallel cimport prange
    """

    expected_directives_dict = {
        u'cython.parallel': u'cython.parallel',
        u'par': u'cython.parallel',
        u'par2': u'cython.parallel',
        u'parallel': u'cython.parallel',

        u"tid": u"cython.parallel.threadid",
        u"tavail": u"cython.parallel.threadavailable",
        u"prange": u"cython.parallel.prange",
    }


    def setUp(self):
        super(TestInterpretCompilerDirectives, self).setUp()

        compilation_options = Main.CompilationOptions(Main.default_options)
        ctx = compilation_options.create_context()

        transform = InterpretCompilerDirectives(ctx, ctx.compiler_directives)
        transform.module_scope = Symtab.ModuleScope('__main__', None, ctx)
        self.pipeline = [transform]

        self.debug_exception_on_error = DebugFlags.debug_exception_on_error

    def tearDown(self):
        DebugFlags.debug_exception_on_error = self.debug_exception_on_error

    def test_parallel_directives_cimports(self):
        self.run_pipeline(self.pipeline, self.import_code)
        parallel_directives = self.pipeline[0].parallel_directives
        self.assertEqual(parallel_directives, self.expected_directives_dict)

    def test_parallel_directives_imports(self):
        self.run_pipeline(self.pipeline,
                          self.import_code.replace(u'cimport', u'import'))
        parallel_directives = self.pipeline[0].parallel_directives
        self.assertEqual(parallel_directives, self.expected_directives_dict)


# TODO: Re-enable once they're more robust.
if sys.version_info[:2] >= (2, 5) and False:
    from Cython.Debugger import DebugWriter
    from Cython.Debugger.Tests.TestLibCython import DebuggerTestCase
else:
    # skip test, don't let it inherit unittest.TestCase
    DebuggerTestCase = object

class TestDebugTransform(DebuggerTestCase):

    def elem_hasattrs(self, elem, attrs):
        # we shall supporteth python 2.3 !
        return all([attr in elem.attrib for attr in attrs])

    def test_debug_info(self):
        try:
            assert os.path.exists(self.debug_dest)

            t = DebugWriter.etree.parse(self.debug_dest)
            # the xpath of the standard ElementTree is primitive, don't use
            # anything fancy
            L = list(t.find('/Module/Globals'))
            # assertTrue is retarded, use the normal assert statement
            assert L
            xml_globals = dict(
                            [(e.attrib['name'], e.attrib['type']) for e in L])
            self.assertEqual(len(L), len(xml_globals))

            L = list(t.find('/Module/Functions'))
            assert L
            xml_funcs = dict([(e.attrib['qualified_name'], e) for e in L])
            self.assertEqual(len(L), len(xml_funcs))

            # test globals
            self.assertEqual('CObject', xml_globals.get('c_var'))
            self.assertEqual('PythonObject', xml_globals.get('python_var'))

            # test functions
            funcnames = ('codefile.spam', 'codefile.ham', 'codefile.eggs',
                         'codefile.closure', 'codefile.inner')
            required_xml_attrs = 'name', 'cname', 'qualified_name'
            assert all([f in xml_funcs for f in funcnames])
            spam, ham, eggs = [xml_funcs[funcname] for funcname in funcnames]

            self.assertEqual(spam.attrib['name'], 'spam')
            self.assertNotEqual('spam', spam.attrib['cname'])
            assert self.elem_hasattrs(spam, required_xml_attrs)

            # test locals of functions
            spam_locals = list(spam.find('Locals'))
            assert spam_locals
            spam_locals.sort(key=lambda e: e.attrib['name'])
            names = [e.attrib['name'] for e in spam_locals]
            self.assertEqual(list('abcd'), names)
            assert self.elem_hasattrs(spam_locals[0], required_xml_attrs)

            # test arguments of functions
            spam_arguments = list(spam.find('Arguments'))
            assert spam_arguments
            self.assertEqual(1, len(list(spam_arguments)))

            # test step-into functions
            step_into = spam.find('StepIntoFunctions')
            spam_stepinto = [x.attrib['name'] for x in step_into]
            assert spam_stepinto
            self.assertEqual(2, len(spam_stepinto))
            assert 'puts' in spam_stepinto
            assert 'some_c_function' in spam_stepinto
        except:
            f = open(self.debug_dest)
            try:
                print(f.read())
            finally:
                f.close()
            raise



if __name__ == "__main__":
    import unittest
    unittest.main()
