# -*- coding: utf-8 -*-
"""
    jinja2.optimizer
    ~~~~~~~~~~~~~~~~

    The jinja optimizer is currently trying to constant fold a few expressions
    and modify the AST in place so that it should be easier to evaluate it.

    Because the AST does not contain all the scoping information and the
    compiler has to find that out, we cannot do all the optimizations we
    want.  For example loop unrolling doesn't work because unrolled loops would
    have a different scoping.

    The solution would be a second syntax tree that has the scoping rules stored.

    :copyright: (c) 2010 by the Jinja Team.
    :license: BSD.
"""
from jinja2 import nodes
from jinja2.visitor import NodeTransformer


def optimize(node, environment):
    """The context hint can be used to perform an static optimization
    based on the context given."""
    optimizer = Optimizer(environment)
    return optimizer.visit(node)


class Optimizer(NodeTransformer):

    def __init__(self, environment):
        self.environment = environment

    def visit_If(self, node):
        """Eliminate dead code."""
        # do not optimize ifs that have a block inside so that it doesn't
        # break super().
        if node.find(nodes.Block) is not None:
            return self.generic_visit(node)
        try:
            val = self.visit(node.test).as_const()
        except nodes.Impossible:
            return self.generic_visit(node)
        if val:
            body = node.body
        else:
            body = node.else_
        result = []
        for node in body:
            result.extend(self.visit_list(node))
        return result

    def fold(self, node):
        """Do constant folding."""
        node = self.generic_visit(node)
        try:
            return nodes.Const.from_untrusted(node.as_const(),
                                              lineno=node.lineno,
                                              environment=self.environment)
        except nodes.Impossible:
            return node

    visit_Add = visit_Sub = visit_Mul = visit_Div = visit_FloorDiv = \
    visit_Pow = visit_Mod = visit_And = visit_Or = visit_Pos = visit_Neg = \
    visit_Not = visit_Compare = visit_Getitem = visit_Getattr = visit_Call = \
    visit_Filter = visit_Test = visit_CondExpr = fold
    del fold
