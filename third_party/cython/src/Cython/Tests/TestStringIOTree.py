import unittest

from Cython import StringIOTree as stringtree

code = """
cdef int spam                   # line 1

cdef ham():
    a = 1
    b = 2
    c = 3
    d = 4

def eggs():
    pass

cpdef bacon():
    print spam
    print 'scotch'
    print 'tea?'
    print 'or coffee?'          # line 16
"""

linemap = dict(enumerate(code.splitlines()))

class TestStringIOTree(unittest.TestCase):

    def setUp(self):
        self.tree = stringtree.StringIOTree()

    def test_markers(self):
        assert not self.tree.allmarkers()

    def test_insertion(self):
        self.write_lines((1, 2, 3))
        line_4_to_6_insertion_point = self.tree.insertion_point()
        self.write_lines((7, 8))
        line_9_to_13_insertion_point = self.tree.insertion_point()
        self.write_lines((14, 15, 16))

        line_4_insertion_point = line_4_to_6_insertion_point.insertion_point()
        self.write_lines((5, 6), tree=line_4_to_6_insertion_point)

        line_9_to_12_insertion_point = (
            line_9_to_13_insertion_point.insertion_point())
        self.write_line(13, tree=line_9_to_13_insertion_point)

        self.write_line(4, tree=line_4_insertion_point)
        self.write_line(9, tree=line_9_to_12_insertion_point)
        line_10_insertion_point = line_9_to_12_insertion_point.insertion_point()
        self.write_line(11, tree=line_9_to_12_insertion_point)
        self.write_line(10, tree=line_10_insertion_point)
        self.write_line(12, tree=line_9_to_12_insertion_point)

        self.assertEqual(self.tree.allmarkers(), range(1, 17))
        self.assertEqual(code.strip(), self.tree.getvalue().strip())


    def write_lines(self, linenos, tree=None):
        for lineno in linenos:
            self.write_line(lineno, tree=tree)

    def write_line(self, lineno, tree=None):
        if tree is None:
            tree = self.tree
        tree.markers.append(lineno)
        tree.write(linemap[lineno] + '\n')
