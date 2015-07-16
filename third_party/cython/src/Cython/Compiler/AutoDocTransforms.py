from Cython.Compiler.Visitor import CythonTransform
from Cython.Compiler.StringEncoding import EncodedString
from Cython.Compiler import Options
from Cython.Compiler import PyrexTypes, ExprNodes

class EmbedSignature(CythonTransform):

    def __init__(self, context):
        super(EmbedSignature, self).__init__(context)
        self.denv = None # XXX
        self.class_name = None
        self.class_node = None

    unop_precedence = 11
    binop_precedence = {
        'or': 1,
        'and': 2,
        'not': 3,
        'in': 4, 'not in': 4, 'is': 4, 'is not': 4, '<': 4, '<=': 4, '>': 4, '>=': 4, '!=': 4, '==': 4,
        '|': 5,
        '^': 6,
        '&': 7,
        '<<': 8, '>>': 8,
        '+': 9, '-': 9,
        '*': 10, '/': 10, '//': 10, '%': 10,
        # unary: '+': 11, '-': 11, '~': 11
        '**': 12}

    def _fmt_expr_node(self, node, precedence=0):
        if isinstance(node, ExprNodes.BinopNode) and not node.inplace:
            new_prec = self.binop_precedence.get(node.operator, 0)
            result = '%s %s %s' % (self._fmt_expr_node(node.operand1, new_prec),
                                   node.operator,
                                   self._fmt_expr_node(node.operand2, new_prec))
            if precedence > new_prec:
                result = '(%s)' % result
        elif isinstance(node, ExprNodes.UnopNode):
            result = '%s%s' % (node.operator,
                               self._fmt_expr_node(node.operand, self.unop_precedence))
            if precedence > self.unop_precedence:
                result = '(%s)' % result
        elif isinstance(node, ExprNodes.AttributeNode):
            result = '%s.%s' % (self._fmt_expr_node(node.obj), node.attribute)
        else:
            result = node.name
        return result

    def _fmt_arg_defv(self, arg):
        default_val = arg.default
        if not default_val:
            return None
        try:
            denv = self.denv  # XXX
            ctval = default_val.compile_time_value(self.denv)
            repr_val = repr(ctval)
            if isinstance(default_val, ExprNodes.UnicodeNode):
                if repr_val[:1] != 'u':
                    return u'u%s' % repr_val
            elif isinstance(default_val, ExprNodes.BytesNode):
                if repr_val[:1] != 'b':
                    return u'b%s' % repr_val
            elif isinstance(default_val, ExprNodes.StringNode):
                if repr_val[:1] in 'ub':
                    return repr_val[1:]
            return repr_val
        except Exception:
            try:
                return self._fmt_expr_node(default_val)
            except AttributeError, e:
                return '<???>'

    def _fmt_arg(self, arg):
        if arg.type is PyrexTypes.py_object_type or arg.is_self_arg:
            doc = arg.name
        else:
            doc = arg.type.declaration_code(arg.name, for_display=1)
        if arg.default:
            arg_defv = self._fmt_arg_defv(arg)
            if arg_defv:
                doc = doc + ('=%s' % arg_defv)
        return doc

    def _fmt_arglist(self, args,
                     npargs=0, pargs=None,
                     nkargs=0, kargs=None,
                     hide_self=False):
        arglist = []
        for arg in args:
            if not hide_self or not arg.entry.is_self_arg:
                arg_doc = self._fmt_arg(arg)
                arglist.append(arg_doc)
        if pargs:
            arglist.insert(npargs, '*%s' % pargs.name)
        elif nkargs:
            arglist.insert(npargs, '*')
        if kargs:
            arglist.append('**%s' % kargs.name)
        return arglist

    def _fmt_ret_type(self, ret):
        if ret is PyrexTypes.py_object_type:
            return None
        else:
            return ret.declaration_code("", for_display=1)

    def _fmt_signature(self, cls_name, func_name, args,
                       npargs=0, pargs=None,
                       nkargs=0, kargs=None,
                       return_type=None, hide_self=False):
        arglist = self._fmt_arglist(args,
                                    npargs, pargs,
                                    nkargs, kargs,
                                    hide_self=hide_self)
        arglist_doc = ', '.join(arglist)
        func_doc = '%s(%s)' % (func_name, arglist_doc)
        if cls_name:
            func_doc = '%s.%s' % (cls_name, func_doc)
        if return_type:
            ret_doc = self._fmt_ret_type(return_type)
            if ret_doc:
                func_doc = '%s -> %s' % (func_doc, ret_doc)
        return func_doc

    def _embed_signature(self, signature, node_doc):
        if node_doc:
            return "%s\n%s" % (signature, node_doc)
        else:
            return signature

    def __call__(self, node):
        if not Options.docstrings:
            return node
        else:
            return super(EmbedSignature, self).__call__(node)

    def visit_ClassDefNode(self, node):
        oldname = self.class_name
        oldclass = self.class_node
        self.class_node = node
        try:
            # PyClassDefNode
            self.class_name = node.name
        except AttributeError:
            # CClassDefNode
            self.class_name = node.class_name
        self.visitchildren(node)
        self.class_name = oldname
        self.class_node = oldclass
        return node

    def visit_DefNode(self, node):
        if not self.current_directives['embedsignature']:
            return node

        is_constructor = False
        hide_self = False
        if node.entry.is_special:
            is_constructor = self.class_node and node.name == '__init__'
            if not is_constructor:
                return node
            class_name, func_name = None, self.class_name
            hide_self = True
        else:
            class_name, func_name = self.class_name, node.name

        nkargs = getattr(node, 'num_kwonly_args', 0)
        npargs = len(node.args) - nkargs
        signature = self._fmt_signature(
            class_name, func_name, node.args,
            npargs, node.star_arg,
            nkargs, node.starstar_arg,
            return_type=None, hide_self=hide_self)
        if signature:
            if is_constructor:
                doc_holder = self.class_node.entry.type.scope
            else:
                doc_holder = node.entry

            if doc_holder.doc is not None:
                old_doc = doc_holder.doc
            elif not is_constructor and getattr(node, 'py_func', None) is not None:
                old_doc = node.py_func.entry.doc
            else:
                old_doc = None
            new_doc  = self._embed_signature(signature, old_doc)
            doc_holder.doc = EncodedString(new_doc)
            if not is_constructor and getattr(node, 'py_func', None) is not None:
                node.py_func.entry.doc = EncodedString(new_doc)
        return node

    def visit_CFuncDefNode(self, node):
        if not self.current_directives['embedsignature']:
            return node
        if not node.overridable: # not cpdef FOO(...):
            return node

        signature = self._fmt_signature(
            self.class_name, node.declarator.base.name,
            node.declarator.args,
            return_type=node.return_type)
        if signature:
            if node.entry.doc is not None:
                old_doc = node.entry.doc
            elif getattr(node, 'py_func', None) is not None:
                old_doc = node.py_func.entry.doc
            else:
                old_doc = None
            new_doc = self._embed_signature(signature, old_doc)
            node.entry.doc = EncodedString(new_doc)
            if hasattr(node, 'py_func') and node.py_func is not None:
                node.py_func.entry.doc = EncodedString(new_doc)
        return node

    def visit_PropertyNode(self, node):
        if not self.current_directives['embedsignature']:
            return node

        entry = node.entry
        if entry.visibility == 'public':
            # property synthesised from a cdef public attribute
            type_name = entry.type.declaration_code("", for_display=1)
            if not entry.type.is_pyobject:
                type_name = "'%s'" % type_name
            elif entry.type.is_extension_type:
                type_name = entry.type.module_name + '.' + type_name
            signature = '%s: %s' % (entry.name, type_name)
            new_doc = self._embed_signature(signature, entry.doc)
            entry.doc = EncodedString(new_doc)
        return node
