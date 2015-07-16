from Cython.Compiler.Visitor import VisitorTransform
from Cython.Compiler.Nodes import StatListNode

class ExtractPxdCode(VisitorTransform):
    """
    Finds nodes in a pxd file that should generate code, and
    returns them in a StatListNode.

    The result is a tuple (StatListNode, ModuleScope), i.e.
    everything that is needed from the pxd after it is processed.

    A purer approach would be to seperately compile the pxd code,
    but the result would have to be slightly more sophisticated
    than pure strings (functions + wanted interned strings +
    wanted utility code + wanted cached objects) so for now this
    approach is taken.
    """

    def __call__(self, root):
        self.funcs = []
        self.visitchildren(root)
        return (StatListNode(root.pos, stats=self.funcs), root.scope)

    def visit_FuncDefNode(self, node):
        self.funcs.append(node)
        # Do not visit children, nested funcdefnodes will
        # also be moved by this action...
        return node

    def visit_Node(self, node):
        self.visitchildren(node)
        return node
