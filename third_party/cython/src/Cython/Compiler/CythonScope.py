from Symtab import ModuleScope
from PyrexTypes import *
from UtilityCode import CythonUtilityCode
from Errors import error
from Scanning import StringSourceDescriptor
import MemoryView

class CythonScope(ModuleScope):
    is_cython_builtin = 1
    _cythonscope_initialized = False

    def __init__(self, context):
        ModuleScope.__init__(self, u'cython', None, None)
        self.pxd_file_loaded = True
        self.populate_cython_scope()
        # The Main.Context object
        self.context = context

        for fused_type in (cy_integral_type, cy_floating_type, cy_numeric_type):
            entry = self.declare_typedef(fused_type.name,
                                         fused_type,
                                         None,
                                         cname='<error>')
            entry.in_cinclude = True

    def lookup_type(self, name):
        # This function should go away when types are all first-level objects.
        type = parse_basic_type(name)
        if type:
            return type

        return super(CythonScope, self).lookup_type(name)

    def lookup(self, name):
        entry = super(CythonScope, self).lookup(name)

        if entry is None and not self._cythonscope_initialized:
            self.load_cythonscope()
            entry = super(CythonScope, self).lookup(name)

        return entry

    def find_module(self, module_name, pos):
        error("cython.%s is not available" % module_name, pos)

    def find_submodule(self, module_name):
        entry = self.entries.get(module_name, None)
        if not entry:
            self.load_cythonscope()
            entry = self.entries.get(module_name, None)

        if entry and entry.as_module:
            return entry.as_module
        else:
            # TODO: fix find_submodule control flow so that we're not
            # expected to create a submodule here (to protect CythonScope's
            # possible immutability). Hack ourselves out of the situation
            # for now.
            raise error((StringSourceDescriptor(u"cython", u""), 0, 0),
                  "cython.%s is not available" % module_name)

    def lookup_qualified_name(self, qname):
        # ExprNode.as_cython_attribute generates qnames and we untangle it here...
        name_path = qname.split(u'.')
        scope = self
        while len(name_path) > 1:
            scope = scope.lookup_here(name_path[0]).as_module
            del name_path[0]
            if scope is None:
                return None
        else:
            return scope.lookup_here(name_path[0])

    def populate_cython_scope(self):
        # These are used to optimize isinstance in FinalOptimizePhase
        type_object = self.declare_typedef(
            'PyTypeObject',
            base_type = c_void_type,
            pos = None,
            cname = 'PyTypeObject')
        type_object.is_void = True
        type_object_type = type_object.type

        self.declare_cfunction(
            'PyObject_TypeCheck',
            CFuncType(c_bint_type, [CFuncTypeArg("o", py_object_type, None),
                                    CFuncTypeArg("t", c_ptr_type(type_object_type), None)]),
            pos = None,
            defining = 1,
            cname = 'PyObject_TypeCheck')

    def load_cythonscope(self):
        """
        Creates some entries for testing purposes and entries for
        cython.array() and for cython.view.*.
        """
        if self._cythonscope_initialized:
            return

        self._cythonscope_initialized = True
        cython_testscope_utility_code.declare_in_scope(
                                self, cython_scope=self)
        cython_test_extclass_utility_code.declare_in_scope(
                                    self, cython_scope=self)

        #
        # The view sub-scope
        #
        self.viewscope = viewscope = ModuleScope(u'view', self, None)
        self.declare_module('view', viewscope, None).as_module = viewscope
        viewscope.is_cython_builtin = True
        viewscope.pxd_file_loaded = True

        cythonview_testscope_utility_code.declare_in_scope(
                                            viewscope, cython_scope=self)

        view_utility_scope = MemoryView.view_utility_code.declare_in_scope(
                                            self.viewscope, cython_scope=self,
                                            whitelist=MemoryView.view_utility_whitelist)

        # self.entries["array"] = view_utility_scope.entries.pop("array")


def create_cython_scope(context):
    # One could in fact probably make it a singleton,
    # but not sure yet whether any code mutates it (which would kill reusing
    # it across different contexts)
    return CythonScope(context)

# Load test utilities for the cython scope

def load_testscope_utility(cy_util_name, **kwargs):
    return CythonUtilityCode.load(cy_util_name, "TestCythonScope.pyx", **kwargs)


undecorated_methods_protos = UtilityCode(proto=u"""
    /* These methods are undecorated and have therefore no prototype */
    static PyObject *__pyx_TestClass_cdef_method(
            struct __pyx_TestClass_obj *self, int value);
    static PyObject *__pyx_TestClass_cpdef_method(
            struct __pyx_TestClass_obj *self, int value, int skip_dispatch);
    static PyObject *__pyx_TestClass_def_method(
            PyObject *self, PyObject *value);
""")

cython_testscope_utility_code = load_testscope_utility("TestScope")

test_cython_utility_dep = load_testscope_utility("TestDep")

cython_test_extclass_utility_code = \
    load_testscope_utility("TestClass", name="TestClass",
                           requires=[undecorated_methods_protos,
                                     test_cython_utility_dep])

cythonview_testscope_utility_code = load_testscope_utility("View.TestScope")
