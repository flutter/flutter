import unittest

from Cython.Compiler import PyrexTypes as pt
from Cython.Compiler.ExprNodes import NameNode
from Cython.Compiler.PyrexTypes import CFuncTypeArg

def cfunctype(*arg_types):
    return pt.CFuncType(pt.c_int_type,
        [ CFuncTypeArg("name", arg_type, None) for arg_type in arg_types ])

def cppclasstype(name, base_classes):
    return pt.CppClassType(name, None, 'CPP_'+name, base_classes)

class SignatureMatcherTest(unittest.TestCase):
    """
    Test the signature matching algorithm for overloaded signatures.
    """
    def assertMatches(self, expected_type, arg_types, functions):
        args = [ NameNode(None, type=arg_type) for arg_type in arg_types ]
        match = pt.best_match(args, functions)
        if expected_type is not None:
            self.assertNotEqual(None, match)
        self.assertEqual(expected_type, match.type)

    def test_cpp_reference_single_arg(self):
        function_types = [
            cfunctype(pt.CReferenceType(pt.c_int_type)),
            cfunctype(pt.CReferenceType(pt.c_long_type)),
            cfunctype(pt.CReferenceType(pt.c_double_type)),
            ]

        functions = [ NameNode(None, type=t) for t in function_types ]
        self.assertMatches(function_types[0], [pt.c_int_type], functions)
        self.assertMatches(function_types[1], [pt.c_long_type], functions)
        self.assertMatches(function_types[2], [pt.c_double_type], functions)

    def test_cpp_reference_two_args(self):
        function_types = [
            cfunctype(
                pt.CReferenceType(pt.c_int_type), pt.CReferenceType(pt.c_long_type)),
            cfunctype(
                pt.CReferenceType(pt.c_long_type), pt.CReferenceType(pt.c_long_type)),
            ]

        functions = [ NameNode(None, type=t) for t in function_types ]
        self.assertMatches(function_types[0], [pt.c_int_type, pt.c_long_type], functions)
        self.assertMatches(function_types[1], [pt.c_long_type, pt.c_long_type], functions)
        self.assertMatches(function_types[1], [pt.c_long_type, pt.c_int_type], functions)

    def test_cpp_reference_cpp_class(self):
        classes = [ cppclasstype("Test%d"%i, []) for i in range(2) ]
        function_types = [
            cfunctype(pt.CReferenceType(classes[0])),
            cfunctype(pt.CReferenceType(classes[1])),
            ]

        functions = [ NameNode(None, type=t) for t in function_types ]
        self.assertMatches(function_types[0], [classes[0]], functions)
        self.assertMatches(function_types[1], [classes[1]], functions)

    def test_cpp_reference_cpp_class_and_int(self):
        classes = [ cppclasstype("Test%d"%i, []) for i in range(2) ]
        function_types = [
            cfunctype(pt.CReferenceType(classes[0]), pt.c_int_type),
            cfunctype(pt.CReferenceType(classes[0]), pt.c_long_type),
            cfunctype(pt.CReferenceType(classes[1]), pt.c_int_type),
            cfunctype(pt.CReferenceType(classes[1]), pt.c_long_type),
            ]

        functions = [ NameNode(None, type=t) for t in function_types ]
        self.assertMatches(function_types[0], [classes[0], pt.c_int_type], functions)
        self.assertMatches(function_types[1], [classes[0], pt.c_long_type], functions)
        self.assertMatches(function_types[2], [classes[1], pt.c_int_type], functions)
        self.assertMatches(function_types[3], [classes[1], pt.c_long_type], functions)
