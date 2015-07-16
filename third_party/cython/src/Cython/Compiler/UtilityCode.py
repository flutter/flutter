from TreeFragment import parse_from_strings, StringParseContext
import Symtab
import Naming
import Code

class NonManglingModuleScope(Symtab.ModuleScope):

    def __init__(self, prefix, *args, **kw):
        self.prefix = prefix
        self.cython_scope = None
        Symtab.ModuleScope.__init__(self, *args, **kw)

    def add_imported_entry(self, name, entry, pos):
        entry.used = True
        return super(NonManglingModuleScope, self).add_imported_entry(
                                                        name, entry, pos)

    def mangle(self, prefix, name=None):
        if name:
            if prefix in (Naming.typeobj_prefix, Naming.func_prefix, Naming.var_prefix, Naming.pyfunc_prefix):
                # Functions, classes etc. gets a manually defined prefix easily
                # manually callable instead (the one passed to CythonUtilityCode)
                prefix = self.prefix
            return "%s%s" % (prefix, name)
        else:
            return Symtab.ModuleScope.mangle(self, prefix)

class CythonUtilityCodeContext(StringParseContext):
    scope = None

    def find_module(self, module_name, relative_to = None, pos = None,
                    need_pxd = 1):

        if module_name != self.module_name:
            if module_name not in self.modules:
                raise AssertionError("Only the cython cimport is supported.")
            else:
                return self.modules[module_name]

        if self.scope is None:
            self.scope = NonManglingModuleScope(self.prefix,
                                                module_name,
                                                parent_module=None,
                                                context=self)

        return self.scope


class CythonUtilityCode(Code.UtilityCodeBase):
    """
    Utility code written in the Cython language itself.

    The @cname decorator can set the cname for a function, method of cdef class.
    Functions decorated with @cname('c_func_name') get the given cname.

    For cdef classes the rules are as follows:
        obj struct      -> <cname>_obj
        obj type ptr    -> <cname>_type
        methods         -> <class_cname>_<method_cname>

    For methods the cname decorator is optional, but without the decorator the
    methods will not be prototyped. See Cython.Compiler.CythonScope and
    tests/run/cythonscope.pyx for examples.
    """

    is_cython_utility = True

    def __init__(self, impl, name="__pyxutil", prefix="", requires=None,
                 file=None, from_scope=None, context=None):
        # 1) We need to delay the parsing/processing, so that all modules can be
        #    imported without import loops
        # 2) The same utility code object can be used for multiple source files;
        #    while the generated node trees can be altered in the compilation of a
        #    single file.
        # Hence, delay any processing until later.
        if context is not None:
            impl = Code.sub_tempita(impl, context, file, name)
        self.impl = impl
        self.name = name
        self.file = file
        self.prefix = prefix
        self.requires = requires or []
        self.from_scope = from_scope

    def get_tree(self, entries_only=False, cython_scope=None):
        from AnalysedTreeTransforms import AutoTestDictTransform
        # The AutoTestDictTransform creates the statement "__test__ = {}",
        # which when copied into the main ModuleNode overwrites
        # any __test__ in user code; not desired
        excludes = [AutoTestDictTransform]

        import Pipeline, ParseTreeTransforms
        context = CythonUtilityCodeContext(self.name)
        context.prefix = self.prefix
        context.cython_scope = cython_scope
        #context = StringParseContext(self.name)
        tree = parse_from_strings(self.name, self.impl, context=context,
                                  allow_struct_enum_decorator=True)
        pipeline = Pipeline.create_pipeline(context, 'pyx', exclude_classes=excludes)

        if entries_only:
            p = []
            for t in pipeline:
                p.append(t)
                if isinstance(p, ParseTreeTransforms.AnalyseDeclarationsTransform):
                    break

            pipeline = p

        transform = ParseTreeTransforms.CnameDirectivesTransform(context)
        # InterpretCompilerDirectives already does a cdef declarator check
        #before = ParseTreeTransforms.DecoratorTransform
        before = ParseTreeTransforms.InterpretCompilerDirectives
        pipeline = Pipeline.insert_into_pipeline(pipeline, transform,
                                                 before=before)

        if self.from_scope:
            def scope_transform(module_node):
                module_node.scope.merge_in(self.from_scope)
                return module_node

            transform = ParseTreeTransforms.AnalyseDeclarationsTransform
            pipeline = Pipeline.insert_into_pipeline(pipeline, scope_transform,
                                                     before=transform)

        (err, tree) = Pipeline.run_pipeline(pipeline, tree, printtree=False)
        assert not err, err
        return tree

    def put_code(self, output):
        pass

    @classmethod
    def load_as_string(cls, util_code_name, from_file=None, **kwargs):
        """
        Load a utility code as a string. Returns (proto, implementation)
        """
        util = cls.load(util_code_name, from_file, **kwargs)
        return util.proto, util.impl # keep line numbers => no lstrip()

    def declare_in_scope(self, dest_scope, used=False, cython_scope=None,
                         whitelist=None):
        """
        Declare all entries from the utility code in dest_scope. Code will only
        be included for used entries. If module_name is given, declare the
        type entries with that name.
        """
        tree = self.get_tree(entries_only=True, cython_scope=cython_scope)

        entries = tree.scope.entries
        entries.pop('__name__')
        entries.pop('__file__')
        entries.pop('__builtins__')
        entries.pop('__doc__')

        for name, entry in entries.iteritems():
            entry.utility_code_definition = self
            entry.used = used

        original_scope = tree.scope
        dest_scope.merge_in(original_scope, merge_unused=True,
                            whitelist=whitelist)
        tree.scope = dest_scope

        for dep in self.requires:
            if dep.is_cython_utility:
                dep.declare_in_scope(dest_scope)

        return original_scope

def declare_declarations_in_scope(declaration_string, env, private_type=True,
                                  *args, **kwargs):
    """
    Declare some declarations given as Cython code in declaration_string
    in scope env.
    """
    CythonUtilityCode(declaration_string, *args, **kwargs).declare_in_scope(env)
