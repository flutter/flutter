from Cython.TestUtils import CythonTest
from Cython.Compiler.TreeFragment import *
from Cython.Compiler.Nodes import *
from Cython.Compiler.UtilNodes import *
import Cython.Compiler.Naming as Naming

class TestTreeFragments(CythonTest):

    def test_basic(self):
        F = self.fragment(u"x = 4")
        T = F.copy()
        self.assertCode(u"x = 4", T)

    def test_copy_is_taken(self):
        F = self.fragment(u"if True: x = 4")
        T1 = F.root
        T2 = F.copy()
        self.assertEqual("x", T2.stats[0].if_clauses[0].body.lhs.name)
        T2.stats[0].if_clauses[0].body.lhs.name = "other"
        self.assertEqual("x", T1.stats[0].if_clauses[0].body.lhs.name)

    def test_substitutions_are_copied(self):
        T = self.fragment(u"y + y").substitute({"y": NameNode(pos=None, name="x")})
        self.assertEqual("x", T.stats[0].expr.operand1.name)
        self.assertEqual("x", T.stats[0].expr.operand2.name)
        self.assert_(T.stats[0].expr.operand1 is not T.stats[0].expr.operand2)

    def test_substitution(self):
        F = self.fragment(u"x = 4")
        y = NameNode(pos=None, name=u"y")
        T = F.substitute({"x" : y})
        self.assertCode(u"y = 4", T)

    def test_exprstat(self):
        F = self.fragment(u"PASS")
        pass_stat = PassStatNode(pos=None)
        T = F.substitute({"PASS" : pass_stat})
        self.assert_(isinstance(T.stats[0], PassStatNode), T)

    def test_pos_is_transferred(self):
        F = self.fragment(u"""
        x = y
        x = u * v ** w
        """)
        T = F.substitute({"v" : NameNode(pos=None, name="a")})
        v = F.root.stats[1].rhs.operand2.operand1
        a = T.stats[1].rhs.operand2.operand1
        self.assertEquals(v.pos, a.pos)

    def test_temps(self):
        TemplateTransform.temp_name_counter = 0
        F = self.fragment(u"""
            TMP
            x = TMP
        """)
        T = F.substitute(temps=[u"TMP"])
        s = T.body.stats
        self.assert_(isinstance(s[0].expr, TempRefNode))
        self.assert_(isinstance(s[1].rhs, TempRefNode))
        self.assert_(s[0].expr.handle is s[1].rhs.handle)

if __name__ == "__main__":
    import unittest
    unittest.main()
