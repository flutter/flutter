#
#   Module parse tree node
#

import cython
cython.declare(Naming=object, Options=object, PyrexTypes=object, TypeSlots=object,
               error=object, warning=object, py_object_type=object, UtilityCode=object,
               EncodedString=object)

import os
import operator
from PyrexTypes import CPtrType
import Future

import Annotate
import Code
import Naming
import Nodes
import Options
import TypeSlots
import Version
import PyrexTypes

from Errors import error, warning
from PyrexTypes import py_object_type
from Cython.Utils import open_new_file, replace_suffix, decode_filename
from Code import UtilityCode
from StringEncoding import EncodedString



def check_c_declarations_pxd(module_node):
    module_node.scope.check_c_classes_pxd()
    return module_node

def check_c_declarations(module_node):
    module_node.scope.check_c_classes()
    module_node.scope.check_c_functions()
    return module_node

class ModuleNode(Nodes.Node, Nodes.BlockNode):
    #  doc       string or None
    #  body      StatListNode
    #
    #  referenced_modules   [ModuleScope]
    #  full_module_name     string
    #
    #  scope                The module scope.
    #  compilation_source   A CompilationSource (see Main)
    #  directives           Top-level compiler directives

    child_attrs = ["body"]
    directives = None

    def merge_in(self, tree, scope, merge_scope=False):
        # Merges in the contents of another tree, and possibly scope. With the
        # current implementation below, this must be done right prior
        # to code generation.
        #
        # Note: This way of doing it seems strange -- I believe the
        # right concept is to split ModuleNode into a ModuleNode and a
        # CodeGenerator, and tell that CodeGenerator to generate code
        # from multiple sources.
        assert isinstance(self.body, Nodes.StatListNode)
        if isinstance(tree, Nodes.StatListNode):
            self.body.stats.extend(tree.stats)
        else:
            self.body.stats.append(tree)

        self.scope.utility_code_list.extend(scope.utility_code_list)

        def extend_if_not_in(L1, L2):
            for x in L2:
                if x not in L1:
                    L1.append(x)

        extend_if_not_in(self.scope.include_files, scope.include_files)
        extend_if_not_in(self.scope.included_files, scope.included_files)
        extend_if_not_in(self.scope.python_include_files,
                         scope.python_include_files)

        if merge_scope:
            # Ensure that we don't generate import code for these entries!
            for entry in scope.c_class_entries:
                entry.type.module_name = self.full_module_name
                entry.type.scope.directives["internal"] = True

            self.scope.merge_in(scope)

    def analyse_declarations(self, env):
        if not Options.docstrings:
            env.doc = self.doc = None
        elif Options.embed_pos_in_docstring:
            env.doc = EncodedString(u'File: %s (starting at line %s)' % Nodes.relative_position(self.pos))
            if not self.doc is None:
                env.doc = EncodedString(env.doc + u'\n' + self.doc)
                env.doc.encoding = self.doc.encoding
        else:
            env.doc = self.doc
        env.directives = self.directives
        self.body.analyse_declarations(env)

    def process_implementation(self, options, result):
        env = self.scope
        env.return_type = PyrexTypes.c_void_type
        self.referenced_modules = []
        self.find_referenced_modules(env, self.referenced_modules, {})
        self.sort_cdef_classes(env)
        self.generate_c_code(env, options, result)
        self.generate_h_code(env, options, result)
        self.generate_api_code(env, result)

    def has_imported_c_functions(self):
        for module in self.referenced_modules:
            for entry in module.cfunc_entries:
                if entry.defined_in_pxd:
                    return 1
        return 0

    def generate_h_code(self, env, options, result):
        def h_entries(entries, api=0, pxd=0):
            return [entry for entry in entries
                    if ((entry.visibility == 'public') or
                        (api and entry.api) or
                        (pxd and entry.defined_in_pxd))]
        h_types = h_entries(env.type_entries, api=1)
        h_vars = h_entries(env.var_entries)
        h_funcs = h_entries(env.cfunc_entries)
        h_extension_types = h_entries(env.c_class_entries)
        if (h_types or  h_vars or h_funcs or h_extension_types):
            result.h_file = replace_suffix(result.c_file, ".h")
            h_code = Code.CCodeWriter()
            Code.GlobalState(h_code, self)
            if options.generate_pxi:
                result.i_file = replace_suffix(result.c_file, ".pxi")
                i_code = Code.PyrexCodeWriter(result.i_file)
            else:
                i_code = None

            h_guard = Naming.h_guard_prefix + self.api_name(env)
            h_code.put_h_guard(h_guard)
            h_code.putln("")
            self.generate_type_header_code(h_types, h_code)
            if options.capi_reexport_cincludes:
                self.generate_includes(env, [], h_code)
            h_code.putln("")
            api_guard = Naming.api_guard_prefix + self.api_name(env)
            h_code.putln("#ifndef %s" % api_guard)
            h_code.putln("")
            self.generate_extern_c_macro_definition(h_code)
            if h_extension_types:
                h_code.putln("")
                for entry in h_extension_types:
                    self.generate_cclass_header_code(entry.type, h_code)
                    if i_code:
                        self.generate_cclass_include_code(entry.type, i_code)
            if h_funcs:
                h_code.putln("")
                for entry in h_funcs:
                    self.generate_public_declaration(entry, h_code, i_code)
            if h_vars:
                h_code.putln("")
                for entry in h_vars:
                    self.generate_public_declaration(entry, h_code, i_code)
            h_code.putln("")
            h_code.putln("#endif /* !%s */" % api_guard)
            h_code.putln("")
            h_code.putln("#if PY_MAJOR_VERSION < 3")
            h_code.putln("PyMODINIT_FUNC init%s(void);" % env.module_name)
            h_code.putln("#else")
            h_code.putln("PyMODINIT_FUNC PyInit_%s(void);" % env.module_name)
            h_code.putln("#endif")
            h_code.putln("")
            h_code.putln("#endif /* !%s */" % h_guard)

            f = open_new_file(result.h_file)
            try:
                h_code.copyto(f)
            finally:
                f.close()

    def generate_public_declaration(self, entry, h_code, i_code):
        h_code.putln("%s %s;" % (
            Naming.extern_c_macro,
            entry.type.declaration_code(
                entry.cname, dll_linkage = "DL_IMPORT")))
        if i_code:
            i_code.putln("cdef extern %s" %
                entry.type.declaration_code(entry.cname, pyrex = 1))

    def api_name(self, env):
        return env.qualified_name.replace(".", "__")

    def generate_api_code(self, env, result):
        def api_entries(entries, pxd=0):
            return [entry for entry in entries
                    if entry.api or (pxd and entry.defined_in_pxd)]
        api_vars = api_entries(env.var_entries)
        api_funcs = api_entries(env.cfunc_entries)
        api_extension_types = api_entries(env.c_class_entries)
        if api_vars or api_funcs or api_extension_types:
            result.api_file = replace_suffix(result.c_file, "_api.h")
            h_code = Code.CCodeWriter()
            Code.GlobalState(h_code, self)
            api_guard = Naming.api_guard_prefix + self.api_name(env)
            h_code.put_h_guard(api_guard)
            h_code.putln('#include "Python.h"')
            if result.h_file:
                h_code.putln('#include "%s"' % os.path.basename(result.h_file))
            if api_extension_types:
                h_code.putln("")
                for entry in api_extension_types:
                    type = entry.type
                    h_code.putln("static PyTypeObject *%s = 0;" % type.typeptr_cname)
                    h_code.putln("#define %s (*%s)" % (
                        type.typeobj_cname, type.typeptr_cname))
            if api_funcs:
                h_code.putln("")
                for entry in api_funcs:
                    type = CPtrType(entry.type)
                    cname = env.mangle(Naming.func_prefix, entry.name)
                    h_code.putln("static %s = 0;" % type.declaration_code(cname))
                    h_code.putln("#define %s %s" % (entry.name, cname))
            if api_vars:
                h_code.putln("")
                for entry in api_vars:
                    type = CPtrType(entry.type)
                    cname = env.mangle(Naming.varptr_prefix, entry.name)
                    h_code.putln("static %s = 0;" %  type.declaration_code(cname))
                    h_code.putln("#define %s (*%s)" % (entry.name, cname))
            h_code.put(UtilityCode.load_as_string("PyIdentifierFromString", "ImportExport.c")[0])
            h_code.put(UtilityCode.load_as_string("ModuleImport", "ImportExport.c")[1])
            if api_vars:
                h_code.put(UtilityCode.load_as_string("VoidPtrImport", "ImportExport.c")[1])
            if api_funcs:
                h_code.put(UtilityCode.load_as_string("FunctionImport", "ImportExport.c")[1])
            if api_extension_types:
                h_code.put(UtilityCode.load_as_string("TypeImport", "ImportExport.c")[1])
            h_code.putln("")
            h_code.putln("static int import_%s(void) {" % self.api_name(env))
            h_code.putln("PyObject *module = 0;")
            h_code.putln('module = __Pyx_ImportModule("%s");' % env.qualified_name)
            h_code.putln("if (!module) goto bad;")
            for entry in api_funcs:
                cname = env.mangle(Naming.func_prefix, entry.name)
                sig = entry.type.signature_string()
                h_code.putln(
                    'if (__Pyx_ImportFunction(module, "%s", (void (**)(void))&%s, "%s") < 0) goto bad;'
                    % (entry.name, cname, sig))
            for entry in api_vars:
                cname = env.mangle(Naming.varptr_prefix, entry.name)
                sig = entry.type.declaration_code("")
                h_code.putln(
                    'if (__Pyx_ImportVoidPtr(module, "%s", (void **)&%s, "%s") < 0) goto bad;'
                    % (entry.name, cname, sig))
            h_code.putln("Py_DECREF(module); module = 0;")
            for entry in api_extension_types:
                self.generate_type_import_call(
                    entry.type, h_code,
                    "if (!%s) goto bad;" % entry.type.typeptr_cname)
            h_code.putln("return 0;")
            h_code.putln("bad:")
            h_code.putln("Py_XDECREF(module);")
            h_code.putln("return -1;")
            h_code.putln("}")
            h_code.putln("")
            h_code.putln("#endif /* !%s */" % api_guard)

            f = open_new_file(result.api_file)
            try:
                h_code.copyto(f)
            finally:
                f.close()

    def generate_cclass_header_code(self, type, h_code):
        h_code.putln("%s %s %s;" % (
            Naming.extern_c_macro,
            PyrexTypes.public_decl("PyTypeObject", "DL_IMPORT"),
            type.typeobj_cname))

    def generate_cclass_include_code(self, type, i_code):
        i_code.putln("cdef extern class %s.%s:" % (
            type.module_name, type.name))
        i_code.indent()
        var_entries = type.scope.var_entries
        if var_entries:
            for entry in var_entries:
                i_code.putln("cdef %s" %
                    entry.type.declaration_code(entry.cname, pyrex = 1))
        else:
            i_code.putln("pass")
        i_code.dedent()

    def generate_c_code(self, env, options, result):
        modules = self.referenced_modules

        if Options.annotate or options.annotate:
            emit_linenums = False
            rootwriter = Annotate.AnnotationCCodeWriter()
        else:
            emit_linenums = options.emit_linenums
            rootwriter = Code.CCodeWriter(emit_linenums=emit_linenums, c_line_in_traceback=options.c_line_in_traceback)
        globalstate = Code.GlobalState(rootwriter, self, emit_linenums, options.common_utility_include_dir)
        globalstate.initialize_main_c_code()
        h_code = globalstate['h_code']

        self.generate_module_preamble(env, modules, h_code)

        globalstate.module_pos = self.pos
        globalstate.directives = self.directives

        globalstate.use_utility_code(refnanny_utility_code)

        code = globalstate['before_global_var']
        code.putln('#define __Pyx_MODULE_NAME "%s"' % self.full_module_name)
        code.putln("int %s%s = 0;" % (Naming.module_is_main, self.full_module_name.replace('.', '__')))
        code.putln("")
        code.putln("/* Implementation of '%s' */" % env.qualified_name)

        code = globalstate['all_the_rest']

        self.generate_cached_builtins_decls(env, code)
        self.generate_lambda_definitions(env, code)
        # generate normal variable and function definitions
        self.generate_variable_definitions(env, code)
        self.body.generate_function_definitions(env, code)
        code.mark_pos(None)
        self.generate_typeobj_definitions(env, code)
        self.generate_method_table(env, code)
        if env.has_import_star:
            self.generate_import_star(env, code)
        self.generate_pymoduledef_struct(env, code)

        # init_globals is inserted before this
        self.generate_module_init_func(modules[:-1], env, globalstate['init_module'])
        self.generate_module_cleanup_func(env, globalstate['cleanup_module'])
        if Options.embed:
            self.generate_main_method(env, globalstate['main_method'])
        self.generate_filename_table(globalstate['filename_table'])

        self.generate_declarations_for_modules(env, modules, globalstate)
        h_code.write('\n')

        for utilcode in env.utility_code_list[:]:
            globalstate.use_utility_code(utilcode)
        globalstate.finalize_main_c_code()

        f = open_new_file(result.c_file)
        try:
            rootwriter.copyto(f)
        finally:
            f.close()
        result.c_file_generated = 1
        if options.gdb_debug:
            self._serialize_lineno_map(env, rootwriter)
        if Options.annotate or options.annotate:
            self._generate_annotations(rootwriter, result)

    def _generate_annotations(self, rootwriter, result):
        self.annotate(rootwriter)
        rootwriter.save_annotation(result.main_source_file, result.c_file)

        # if we included files, additionally generate one annotation file for each
        if not self.scope.included_files:
            return

        search_include_file = self.scope.context.search_include_directories
        target_dir = os.path.abspath(os.path.dirname(result.c_file))
        for included_file in self.scope.included_files:
            target_file = os.path.abspath(os.path.join(target_dir, included_file))
            target_file_dir = os.path.dirname(target_file)
            if not target_file_dir.startswith(target_dir):
                # any other directories may not be writable => avoid trying
                continue
            source_file = search_include_file(included_file, "", self.pos, include=True)
            if not source_file:
                continue
            if target_file_dir != target_dir and not os.path.exists(target_file_dir):
                try:
                    os.makedirs(target_file_dir)
                except OSError, e:
                    import errno
                    if e.errno != errno.EEXIST:
                        raise
            rootwriter.save_annotation(source_file, target_file)

    def _serialize_lineno_map(self, env, ccodewriter):
        tb = env.context.gdb_debug_outputwriter
        markers = ccodewriter.buffer.allmarkers()

        d = {}
        for c_lineno, cython_lineno in enumerate(markers):
            if cython_lineno > 0:
                d.setdefault(cython_lineno, []).append(c_lineno + 1)

        tb.start('LineNumberMapping')
        for cython_lineno, c_linenos in sorted(d.iteritems()):
                attrs = {
                    'c_linenos': ' '.join(map(str, c_linenos)),
                    'cython_lineno': str(cython_lineno),
                }
                tb.start('LineNumber', attrs)
                tb.end('LineNumber')
        tb.end('LineNumberMapping')
        tb.serialize()

    def find_referenced_modules(self, env, module_list, modules_seen):
        if env not in modules_seen:
            modules_seen[env] = 1
            for imported_module in env.cimported_modules:
                self.find_referenced_modules(imported_module, module_list, modules_seen)
            module_list.append(env)

    def sort_types_by_inheritance(self, type_dict, type_order, getkey):
        # copy the types into a list moving each parent type before
        # its first child
        type_list = []
        for i, key in enumerate(type_order):
            new_entry = type_dict[key]

            # collect all base classes to check for children
            hierarchy = set()
            base = new_entry
            while base:
                base_type = base.type.base_type
                if not base_type:
                    break
                base_key = getkey(base_type)
                hierarchy.add(base_key)
                base = type_dict.get(base_key)
            new_entry.base_keys = hierarchy

            # find the first (sub-)subclass and insert before that
            for j in range(i):
                entry = type_list[j]
                if key in entry.base_keys:
                    type_list.insert(j, new_entry)
                    break
            else:
                type_list.append(new_entry)
        return type_list

    def sort_type_hierarchy(self, module_list, env):
        # poor developer's OrderedDict
        vtab_dict, vtab_dict_order = {}, []
        vtabslot_dict, vtabslot_dict_order = {}, []

        for module in module_list:
            for entry in module.c_class_entries:
                if entry.used and not entry.in_cinclude:
                    type = entry.type
                    key = type.vtabstruct_cname
                    if not key:
                        continue
                    if key in vtab_dict:
                        # FIXME: this should *never* happen, but apparently it does
                        # for Cython generated utility code
                        from Cython.Compiler.UtilityCode import NonManglingModuleScope
                        assert isinstance(entry.scope, NonManglingModuleScope), str(entry.scope)
                        assert isinstance(vtab_dict[key].scope, NonManglingModuleScope), str(vtab_dict[key].scope)
                    else:
                        vtab_dict[key] = entry
                        vtab_dict_order.append(key)
            all_defined_here = module is env
            for entry in module.type_entries:
                if entry.used and (all_defined_here or entry.defined_in_pxd):
                    type = entry.type
                    if type.is_extension_type and not entry.in_cinclude:
                        type = entry.type
                        key = type.objstruct_cname
                        assert key not in vtabslot_dict, key
                        vtabslot_dict[key] = entry
                        vtabslot_dict_order.append(key)

        def vtabstruct_cname(entry_type):
            return entry_type.vtabstruct_cname
        vtab_list = self.sort_types_by_inheritance(
            vtab_dict, vtab_dict_order, vtabstruct_cname)

        def objstruct_cname(entry_type):
            return entry_type.objstruct_cname
        vtabslot_list = self.sort_types_by_inheritance(
            vtabslot_dict, vtabslot_dict_order, objstruct_cname)

        return (vtab_list, vtabslot_list)

    def sort_cdef_classes(self, env):
        key_func = operator.attrgetter('objstruct_cname')
        entry_dict, entry_order = {}, []
        for entry in env.c_class_entries:
            key = key_func(entry.type)
            assert key not in entry_dict, key
            entry_dict[key] = entry
            entry_order.append(key)
        env.c_class_entries[:] = self.sort_types_by_inheritance(
            entry_dict, entry_order, key_func)

    def generate_type_definitions(self, env, modules, vtab_list, vtabslot_list, code):
        # TODO: Why are these separated out?
        for entry in vtabslot_list:
            self.generate_objstruct_predeclaration(entry.type, code)
        vtabslot_entries = set(vtabslot_list)
        for module in modules:
            definition = module is env
            if definition:
                type_entries = module.type_entries
            else:
                type_entries = []
                for entry in module.type_entries:
                    if entry.defined_in_pxd:
                        type_entries.append(entry)
            type_entries = [t for t in type_entries if t not in vtabslot_entries]
            self.generate_type_header_code(type_entries, code)
        for entry in vtabslot_list:
            self.generate_objstruct_definition(entry.type, code)
            self.generate_typeobj_predeclaration(entry, code)
        for entry in vtab_list:
            self.generate_typeobj_predeclaration(entry, code)
            self.generate_exttype_vtable_struct(entry, code)
            self.generate_exttype_vtabptr_declaration(entry, code)
            self.generate_exttype_final_methods_declaration(entry, code)

    def generate_declarations_for_modules(self, env, modules, globalstate):
        typecode = globalstate['type_declarations']
        typecode.putln("")
        typecode.putln("/*--- Type declarations ---*/")
        # This is to work around the fact that array.h isn't part of the C-API,
        # but we need to declare it earlier than utility code.
        if 'cpython.array' in [m.qualified_name for m in modules]:
            typecode.putln('#ifndef _ARRAYARRAY_H')
            typecode.putln('struct arrayobject;')
            typecode.putln('typedef struct arrayobject arrayobject;')
            typecode.putln('#endif')
        vtab_list, vtabslot_list = self.sort_type_hierarchy(modules, env)
        self.generate_type_definitions(
            env, modules, vtab_list, vtabslot_list, typecode)
        modulecode = globalstate['module_declarations']
        for module in modules:
            defined_here = module is env
            modulecode.putln("")
            modulecode.putln("/* Module declarations from '%s' */" % module.qualified_name)
            self.generate_c_class_declarations(module, modulecode, defined_here)
            self.generate_cvariable_declarations(module, modulecode, defined_here)
            self.generate_cfunction_declarations(module, modulecode, defined_here)

    def generate_module_preamble(self, env, cimported_modules, code):
        code.putln("/* Generated by Cython %s */" % Version.watermark)
        code.putln("")
        code.putln("#define PY_SSIZE_T_CLEAN")

        # sizeof(PyLongObject.ob_digit[0]) may have been determined dynamically
        # at compile time in CPython, in which case we can't know the correct
        # storage size for an installed system.  We can rely on it only if
        # pyconfig.h defines it statically, i.e. if it was set by "configure".
        # Once we include "Python.h", it will come up with its own idea about
        # a suitable value, which may or may not match the real one.
        code.putln("#ifndef CYTHON_USE_PYLONG_INTERNALS")
        code.putln("#ifdef PYLONG_BITS_IN_DIGIT")
        # assume it's an incorrect left-over
        code.putln("#define CYTHON_USE_PYLONG_INTERNALS 0")
        code.putln("#else")
        code.putln('#include "pyconfig.h"')
        code.putln("#ifdef PYLONG_BITS_IN_DIGIT")
        code.putln("#define CYTHON_USE_PYLONG_INTERNALS 1")
        code.putln("#else")
        code.putln("#define CYTHON_USE_PYLONG_INTERNALS 0")
        code.putln("#endif")
        code.putln("#endif")
        code.putln("#endif")

        for filename in env.python_include_files:
            code.putln('#include "%s"' % filename)
        code.putln("#ifndef Py_PYTHON_H")
        code.putln("    #error Python headers needed to compile C extensions, please install development version of Python.")
        code.putln("#elif PY_VERSION_HEX < 0x02040000")
        code.putln("    #error Cython requires Python 2.4+.")
        code.putln("#else")
        code.globalstate["end"].putln("#endif /* Py_PYTHON_H */")

        from Cython import __version__
        code.putln('#define CYTHON_ABI "%s"' % __version__.replace('.', '_'))

        code.put(UtilityCode.load_as_string("CModulePreamble", "ModuleSetupCode.c")[1])

        code.put("""
#if PY_MAJOR_VERSION >= 3
  #define __Pyx_PyNumber_Divide(x,y)         PyNumber_TrueDivide(x,y)
  #define __Pyx_PyNumber_InPlaceDivide(x,y)  PyNumber_InPlaceTrueDivide(x,y)
#else
""")
        if Future.division in env.context.future_directives:
            code.putln("  #define __Pyx_PyNumber_Divide(x,y)         PyNumber_TrueDivide(x,y)")
            code.putln("  #define __Pyx_PyNumber_InPlaceDivide(x,y)  PyNumber_InPlaceTrueDivide(x,y)")
        else:
            code.putln("  #define __Pyx_PyNumber_Divide(x,y)         PyNumber_Divide(x,y)")
            code.putln("  #define __Pyx_PyNumber_InPlaceDivide(x,y)  PyNumber_InPlaceDivide(x,y)")
        code.putln("#endif")

        code.putln("")
        self.generate_extern_c_macro_definition(code)
        code.putln("")

        code.putln("#if defined(WIN32) || defined(MS_WINDOWS)")
        code.putln("#define _USE_MATH_DEFINES")
        code.putln("#endif")
        code.putln("#include <math.h>")

        code.putln("#define %s" % Naming.h_guard_prefix + self.api_name(env))
        code.putln("#define %s" % Naming.api_guard_prefix + self.api_name(env))
        self.generate_includes(env, cimported_modules, code)
        code.putln("")
        code.putln("#ifdef PYREX_WITHOUT_ASSERTIONS")
        code.putln("#define CYTHON_WITHOUT_ASSERTIONS")
        code.putln("#endif")
        code.putln("")

        if env.directives['ccomplex']:
            code.putln("")
            code.putln("#if !defined(CYTHON_CCOMPLEX)")
            code.putln("#define CYTHON_CCOMPLEX 1")
            code.putln("#endif")
            code.putln("")
        code.put(UtilityCode.load_as_string("UtilityFunctionPredeclarations", "ModuleSetupCode.c")[0])

        c_string_type = env.directives['c_string_type']
        c_string_encoding = env.directives['c_string_encoding']
        if c_string_type not in ('bytes', 'bytearray') and not c_string_encoding:
            error(self.pos, "a default encoding must be provided if c_string_type is not a byte type")
        code.putln('#define __PYX_DEFAULT_STRING_ENCODING_IS_ASCII %s' % int(c_string_encoding == 'ascii'))
        if c_string_encoding == 'default':
            code.putln('#define __PYX_DEFAULT_STRING_ENCODING_IS_DEFAULT 1')
        else:
            code.putln('#define __PYX_DEFAULT_STRING_ENCODING_IS_DEFAULT 0')
            code.putln('#define __PYX_DEFAULT_STRING_ENCODING "%s"' % c_string_encoding)
        if c_string_type == 'bytearray':
            c_string_func_name = 'ByteArray'
        else:
            c_string_func_name = c_string_type.title()
        code.putln('#define __Pyx_PyObject_FromString __Pyx_Py%s_FromString' % c_string_func_name)
        code.putln('#define __Pyx_PyObject_FromStringAndSize __Pyx_Py%s_FromStringAndSize' % c_string_func_name)
        code.put(UtilityCode.load_as_string("TypeConversions", "TypeConversion.c")[0])

        # These utility functions are assumed to exist and used elsewhere.
        PyrexTypes.c_long_type.create_to_py_utility_code(env)
        PyrexTypes.c_long_type.create_from_py_utility_code(env)
        PyrexTypes.c_int_type.create_from_py_utility_code(env)

        code.put(Nodes.branch_prediction_macros)
        code.putln('')
        code.putln('static PyObject *%s;' % env.module_cname)
        code.putln('static PyObject *%s;' % env.module_dict_cname)
        code.putln('static PyObject *%s;' % Naming.builtins_cname)
        code.putln('static PyObject *%s;' % Naming.empty_tuple)
        code.putln('static PyObject *%s;' % Naming.empty_bytes)
        if Options.pre_import is not None:
            code.putln('static PyObject *%s;' % Naming.preimport_cname)
        code.putln('static int %s;' % Naming.lineno_cname)
        code.putln('static int %s = 0;' % Naming.clineno_cname)
        code.putln('static const char * %s= %s;' % (Naming.cfilenm_cname, Naming.file_c_macro))
        code.putln('static const char *%s;' % Naming.filename_cname)

    def generate_extern_c_macro_definition(self, code):
        name = Naming.extern_c_macro
        code.putln("#ifndef %s" % name)
        code.putln("  #ifdef __cplusplus")
        code.putln('    #define %s extern "C"' % name)
        code.putln("  #else")
        code.putln("    #define %s extern" % name)
        code.putln("  #endif")
        code.putln("#endif")

    def generate_includes(self, env, cimported_modules, code):
        includes = []
        for filename in env.include_files:
            byte_decoded_filenname = str(filename)
            if byte_decoded_filenname[0] == '<' and byte_decoded_filenname[-1] == '>':
                code.putln('#include %s' % byte_decoded_filenname)
            else:
                code.putln('#include "%s"' % byte_decoded_filenname)

        code.putln_openmp("#include <omp.h>")

    def generate_filename_table(self, code):
        code.putln("")
        code.putln("static const char *%s[] = {" % Naming.filetable_cname)
        if code.globalstate.filename_list:
            for source_desc in code.globalstate.filename_list:
                filename = os.path.basename(source_desc.get_filenametable_entry())
                escaped_filename = filename.replace("\\", "\\\\").replace('"', r'\"')
                code.putln('"%s",' % escaped_filename)
        else:
            # Some C compilers don't like an empty array
            code.putln("0")
        code.putln("};")

    def generate_type_predeclarations(self, env, code):
        pass

    def generate_type_header_code(self, type_entries, code):
        # Generate definitions of structs/unions/enums/typedefs/objstructs.
        #self.generate_gcc33_hack(env, code) # Is this still needed?
        # Forward declarations
        for entry in type_entries:
            if not entry.in_cinclude:
                #print "generate_type_header_code:", entry.name, repr(entry.type) ###
                type = entry.type
                if type.is_typedef: # Must test this first!
                    pass
                elif type.is_struct_or_union or type.is_cpp_class:
                    self.generate_struct_union_predeclaration(entry, code)
                elif type.is_extension_type:
                    self.generate_objstruct_predeclaration(type, code)
        # Actual declarations
        for entry in type_entries:
            if not entry.in_cinclude:
                #print "generate_type_header_code:", entry.name, repr(entry.type) ###
                type = entry.type
                if type.is_typedef: # Must test this first!
                    self.generate_typedef(entry, code)
                elif type.is_enum:
                    self.generate_enum_definition(entry, code)
                elif type.is_struct_or_union:
                    self.generate_struct_union_definition(entry, code)
                elif type.is_cpp_class:
                    self.generate_cpp_class_definition(entry, code)
                elif type.is_extension_type:
                    self.generate_objstruct_definition(type, code)

    def generate_gcc33_hack(self, env, code):
        # Workaround for spurious warning generation in gcc 3.3
        code.putln("")
        for entry in env.c_class_entries:
            type = entry.type
            if not type.typedef_flag:
                name = type.objstruct_cname
                if name.startswith("__pyx_"):
                    tail = name[6:]
                else:
                    tail = name
                code.putln("typedef struct %s __pyx_gcc33_%s;" % (
                    name, tail))

    def generate_typedef(self, entry, code):
        base_type = entry.type.typedef_base_type
        if base_type.is_numeric:
            try:
                writer = code.globalstate['numeric_typedefs']
            except KeyError:
                writer = code
        else:
            writer = code
        writer.mark_pos(entry.pos)
        writer.putln("typedef %s;" % base_type.declaration_code(entry.cname))

    def sue_predeclaration(self, type, kind, name):
        if type.typedef_flag:
            return "%s %s;\ntypedef %s %s %s;" % (
                kind, name,
                kind, name, name)
        else:
            return "%s %s;" % (kind, name)

    def generate_struct_union_predeclaration(self, entry, code):
        type = entry.type
        if type.is_cpp_class and type.templates:
            code.putln("template <typename %s>" % ", typename ".join([T.declaration_code("") for T in type.templates]))
        code.putln(self.sue_predeclaration(type, type.kind, type.cname))

    def sue_header_footer(self, type, kind, name):
        header = "%s %s {" % (kind, name)
        footer = "};"
        return header, footer

    def generate_struct_union_definition(self, entry, code):
        code.mark_pos(entry.pos)
        type = entry.type
        scope = type.scope
        if scope:
            kind = type.kind
            packed = type.is_struct and type.packed
            if packed:
                kind = "%s %s" % (type.kind, "__Pyx_PACKED")
                code.globalstate.use_utility_code(packed_struct_utility_code)
            header, footer = \
                self.sue_header_footer(type, kind, type.cname)
            if packed:
                code.putln("#if defined(__SUNPRO_C)")
                code.putln("  #pragma pack(1)")
                code.putln("#elif !defined(__GNUC__)")
                code.putln("  #pragma pack(push, 1)")
                code.putln("#endif")
            code.putln(header)
            var_entries = scope.var_entries
            if not var_entries:
                error(entry.pos,
                    "Empty struct or union definition not allowed outside a"
                    " 'cdef extern from' block")
            for attr in var_entries:
                code.putln(
                    "%s;" %
                        attr.type.declaration_code(attr.cname))
            code.putln(footer)
            if packed:
                code.putln("#if defined(__SUNPRO_C)")
                code.putln("  #pragma pack()")
                code.putln("#elif !defined(__GNUC__)")
                code.putln("  #pragma pack(pop)")
                code.putln("#endif")

    def generate_cpp_class_definition(self, entry, code):
        code.mark_pos(entry.pos)
        type = entry.type
        scope = type.scope
        if scope:
            if type.templates:
                code.putln("template <class %s>" % ", class ".join([T.declaration_code("") for T in type.templates]))
            # Just let everything be public.
            code.put("struct %s" % type.cname)
            if type.base_classes:
                base_class_decl = ", public ".join(
                    [base_class.declaration_code("") for base_class in type.base_classes])
                code.put(" : public %s" % base_class_decl)
            code.putln(" {")
            has_virtual_methods = False
            has_destructor = False
            for attr in scope.var_entries:
                if attr.type.is_cfunction and attr.name != "<init>":
                    code.put("virtual ")
                    has_virtual_methods = True
                if attr.cname[0] == '~':
                    has_destructor = True
                code.putln(
                    "%s;" %
                        attr.type.declaration_code(attr.cname))
            if has_virtual_methods and not has_destructor:
                code.put("virtual ~%s() { }" % type.cname)
            code.putln("};")

    def generate_enum_definition(self, entry, code):
        code.mark_pos(entry.pos)
        type = entry.type
        name = entry.cname or entry.name or ""
        header, footer = \
            self.sue_header_footer(type, "enum", name)
        code.putln(header)
        enum_values = entry.enum_values
        if not enum_values:
            error(entry.pos,
                "Empty enum definition not allowed outside a"
                " 'cdef extern from' block")
        else:
            last_entry = enum_values[-1]
            # this does not really generate code, just builds the result value
            for value_entry in enum_values:
                if value_entry.value_node is not None:
                    value_entry.value_node.generate_evaluation_code(code)

            for value_entry in enum_values:
                if value_entry.value_node is None:
                    value_code = value_entry.cname
                else:
                    value_code = ("%s = %s" % (
                        value_entry.cname,
                        value_entry.value_node.result()))
                if value_entry is not last_entry:
                    value_code += ","
                code.putln(value_code)
        code.putln(footer)
        if entry.type.typedef_flag:
            # Not pre-declared.
            code.putln("typedef enum %s %s;" % (name, name))

    def generate_typeobj_predeclaration(self, entry, code):
        code.putln("")
        name = entry.type.typeobj_cname
        if name:
            if entry.visibility == 'extern' and not entry.in_cinclude:
                code.putln("%s %s %s;" % (
                    Naming.extern_c_macro,
                    PyrexTypes.public_decl("PyTypeObject", "DL_IMPORT"),
                    name))
            elif entry.visibility == 'public':
                code.putln("%s %s %s;" % (
                    Naming.extern_c_macro,
                    PyrexTypes.public_decl("PyTypeObject", "DL_EXPORT"),
                    name))
            # ??? Do we really need the rest of this? ???
            #else:
            #    code.putln("static PyTypeObject %s;" % name)

    def generate_exttype_vtable_struct(self, entry, code):
        if not entry.used:
            return

        code.mark_pos(entry.pos)
        # Generate struct declaration for an extension type's vtable.
        type = entry.type
        scope = type.scope

        self.specialize_fused_types(scope)

        if type.vtabstruct_cname:
            code.putln("")
            code.putln(
                "struct %s {" %
                    type.vtabstruct_cname)
            if type.base_type and type.base_type.vtabstruct_cname:
                code.putln("struct %s %s;" % (
                    type.base_type.vtabstruct_cname,
                    Naming.obj_base_cname))
            for method_entry in scope.cfunc_entries:
                if not method_entry.is_inherited:
                    code.putln(
                        "%s;" % method_entry.type.declaration_code("(*%s)" % method_entry.cname))
            code.putln(
                "};")

    def generate_exttype_vtabptr_declaration(self, entry, code):
        if not entry.used:
            return

        code.mark_pos(entry.pos)
        # Generate declaration of pointer to an extension type's vtable.
        type = entry.type
        if type.vtabptr_cname:
            code.putln("static struct %s *%s;" % (
                type.vtabstruct_cname,
                type.vtabptr_cname))

    def generate_exttype_final_methods_declaration(self, entry, code):
        if not entry.used:
            return

        code.mark_pos(entry.pos)
        # Generate final methods prototypes
        type = entry.type
        for method_entry in entry.type.scope.cfunc_entries:
            if not method_entry.is_inherited and method_entry.final_func_cname:
                declaration = method_entry.type.declaration_code(
                    method_entry.final_func_cname)
                modifiers = code.build_function_modifiers(method_entry.func_modifiers)
                code.putln("static %s%s;" % (modifiers, declaration))

    def generate_objstruct_predeclaration(self, type, code):
        if not type.scope:
            return
        code.putln(self.sue_predeclaration(type, "struct", type.objstruct_cname))

    def generate_objstruct_definition(self, type, code):
        code.mark_pos(type.pos)
        # Generate object struct definition for an
        # extension type.
        if not type.scope:
            return # Forward declared but never defined
        header, footer = \
            self.sue_header_footer(type, "struct", type.objstruct_cname)
        code.putln(header)
        base_type = type.base_type
        if base_type:
            basestruct_cname = base_type.objstruct_cname
            if basestruct_cname == "PyTypeObject":
                # User-defined subclasses of type are heap allocated.
                basestruct_cname = "PyHeapTypeObject"
            code.putln(
                "%s%s %s;" % (
                    ("struct ", "")[base_type.typedef_flag],
                    basestruct_cname,
                    Naming.obj_base_cname))
        else:
            code.putln(
                "PyObject_HEAD")
        if type.vtabslot_cname and not (type.base_type and type.base_type.vtabslot_cname):
            code.putln(
                "struct %s *%s;" % (
                    type.vtabstruct_cname,
                    type.vtabslot_cname))
        for attr in type.scope.var_entries:
            if attr.is_declared_generic:
                attr_type = py_object_type
            else:
                attr_type = attr.type
            code.putln(
                "%s;" %
                    attr_type.declaration_code(attr.cname))
        code.putln(footer)
        if type.objtypedef_cname is not None:
            # Only for exposing public typedef name.
            code.putln("typedef struct %s %s;" % (type.objstruct_cname, type.objtypedef_cname))

    def generate_c_class_declarations(self, env, code, definition):
        for entry in env.c_class_entries:
            if definition or entry.defined_in_pxd:
                code.putln("static PyTypeObject *%s = 0;" %
                    entry.type.typeptr_cname)

    def generate_cvariable_declarations(self, env, code, definition):
        if env.is_cython_builtin:
            return
        for entry in env.var_entries:
            if (entry.in_cinclude or entry.in_closure or
                (entry.visibility == 'private' and
                 not (entry.defined_in_pxd or entry.used))):
                continue

            storage_class = None
            dll_linkage = None
            cname = None
            init = None

            if entry.visibility == 'extern':
                storage_class = Naming.extern_c_macro
                dll_linkage = "DL_IMPORT"
            elif entry.visibility == 'public':
                storage_class = Naming.extern_c_macro
                if definition:
                    dll_linkage = "DL_EXPORT"
                else:
                    dll_linkage = "DL_IMPORT"
            elif entry.visibility == 'private':
                storage_class = "static"
                dll_linkage = None
                if entry.init is not None:
                    init =  entry.type.literal_code(entry.init)
            type = entry.type
            cname = entry.cname

            if entry.defined_in_pxd and not definition:
                storage_class = "static"
                dll_linkage = None
                type = CPtrType(type)
                cname = env.mangle(Naming.varptr_prefix, entry.name)
                init = 0

            if storage_class:
                code.put("%s " % storage_class)
            code.put(type.declaration_code(
                cname, dll_linkage = dll_linkage))
            if init is not None:
                code.put_safe(" = %s" % init)
            code.putln(";")
            if entry.cname != cname:
                code.putln("#define %s (*%s)" % (entry.cname, cname))

    def generate_cfunction_declarations(self, env, code, definition):
        for entry in env.cfunc_entries:
            if entry.used or (entry.visibility == 'public' or entry.api):
                generate_cfunction_declaration(entry, env, code, definition)

    def generate_variable_definitions(self, env, code):
        for entry in env.var_entries:
            if (not entry.in_cinclude and
                entry.visibility == "public"):
                code.put(entry.type.declaration_code(entry.cname))
                if entry.init is not None:
                    init =  entry.type.literal_code(entry.init)
                    code.put_safe(" = %s" % init)
                code.putln(";")

    def generate_typeobj_definitions(self, env, code):
        full_module_name = env.qualified_name
        for entry in env.c_class_entries:
            #print "generate_typeobj_definitions:", entry.name
            #print "...visibility =", entry.visibility
            if entry.visibility != 'extern':
                type = entry.type
                scope = type.scope
                if scope: # could be None if there was an error
                    self.generate_exttype_vtable(scope, code)
                    self.generate_new_function(scope, code, entry)
                    self.generate_dealloc_function(scope, code)
                    if scope.needs_gc():
                        self.generate_traverse_function(scope, code, entry)
                        if scope.needs_tp_clear():
                            self.generate_clear_function(scope, code, entry)
                    if scope.defines_any(["__getitem__"]):
                        self.generate_getitem_int_function(scope, code)
                    if scope.defines_any(["__setitem__", "__delitem__"]):
                        self.generate_ass_subscript_function(scope, code)
                    if scope.defines_any(["__getslice__", "__setslice__", "__delslice__"]):
                        warning(self.pos, "__getslice__, __setslice__, and __delslice__ are not supported by Python 3, use __getitem__, __setitem__, and __delitem__ instead", 1)
                        code.putln("#if PY_MAJOR_VERSION >= 3")
                        code.putln("#error __getslice__, __setslice__, and __delslice__ not supported in Python 3.")
                        code.putln("#endif")
                    if scope.defines_any(["__setslice__", "__delslice__"]):
                        self.generate_ass_slice_function(scope, code)
                    if scope.defines_any(["__getattr__","__getattribute__"]):
                        self.generate_getattro_function(scope, code)
                    if scope.defines_any(["__setattr__", "__delattr__"]):
                        self.generate_setattro_function(scope, code)
                    if scope.defines_any(["__get__"]):
                        self.generate_descr_get_function(scope, code)
                    if scope.defines_any(["__set__", "__delete__"]):
                        self.generate_descr_set_function(scope, code)
                    self.generate_property_accessors(scope, code)
                    self.generate_method_table(scope, code)
                    self.generate_getset_table(scope, code)
                    self.generate_typeobj_definition(full_module_name, entry, code)

    def generate_exttype_vtable(self, scope, code):
        # Generate the definition of an extension type's vtable.
        type = scope.parent_type
        if type.vtable_cname:
            code.putln("static struct %s %s;" % (
                type.vtabstruct_cname,
                type.vtable_cname))

    def generate_self_cast(self, scope, code):
        type = scope.parent_type
        code.putln(
            "%s = (%s)o;" % (
                type.declaration_code("p"),
                type.declaration_code("")))

    def generate_new_function(self, scope, code, cclass_entry):
        tp_slot = TypeSlots.ConstructorSlot("tp_new", '__new__')
        slot_func = scope.mangle_internal("tp_new")
        type = scope.parent_type
        base_type = type.base_type

        have_entries, (py_attrs, py_buffers, memoryview_slices) = \
                        scope.get_refcounted_entries()
        is_final_type = scope.parent_type.is_final_type
        if scope.is_internal:
            # internal classes (should) never need None inits, normal zeroing will do
            py_attrs = []
        cpp_class_attrs = [entry for entry in scope.var_entries
                           if entry.type.is_cpp_class]

        new_func_entry = scope.lookup_here("__new__")
        if base_type or (new_func_entry and new_func_entry.is_special
                         and not new_func_entry.trivial_signature):
            unused_marker = ''
        else:
            unused_marker = 'CYTHON_UNUSED '

        if base_type:
            freelist_size = 0  # not currently supported
        else:
            freelist_size = scope.directives.get('freelist', 0)
        freelist_name = scope.mangle_internal(Naming.freelist_name)
        freecount_name = scope.mangle_internal(Naming.freecount_name)

        decls = code.globalstate['decls']
        decls.putln("static PyObject *%s(PyTypeObject *t, PyObject *a, PyObject *k); /*proto*/" %
                    slot_func)
        code.putln("")
        if freelist_size:
            code.putln("static %s[%d];" % (
                scope.parent_type.declaration_code(freelist_name),
                freelist_size))
            code.putln("static int %s = 0;" % freecount_name)
            code.putln("")
        code.putln(
            "static PyObject *%s(PyTypeObject *t, %sPyObject *a, %sPyObject *k) {"
                % (slot_func, unused_marker, unused_marker))

        need_self_cast = (type.vtabslot_cname or
                          (py_buffers or memoryview_slices or py_attrs) or
                          cpp_class_attrs)
        if need_self_cast:
            code.putln("%s;" % scope.parent_type.declaration_code("p"))
        if base_type:
            tp_new = TypeSlots.get_base_slot_function(scope, tp_slot)
            if tp_new is None:
                tp_new = "%s->tp_new" % base_type.typeptr_cname
            code.putln("PyObject *o = %s(t, a, k);" % tp_new)
        else:
            code.putln("PyObject *o;")
            if freelist_size:
                code.globalstate.use_utility_code(
                    UtilityCode.load_cached("IncludeStringH", "StringTools.c"))
                if is_final_type:
                    type_safety_check = ''
                else:
                    type_safety_check = ' & ((t->tp_flags & (Py_TPFLAGS_IS_ABSTRACT | Py_TPFLAGS_HEAPTYPE)) == 0)'
                obj_struct = type.declaration_code("", deref=True)
                code.putln("if (CYTHON_COMPILING_IN_CPYTHON && likely((%s > 0) & (t->tp_basicsize == sizeof(%s))%s)) {" % (
                    freecount_name, obj_struct, type_safety_check))
                code.putln("o = (PyObject*)%s[--%s];" % (
                    freelist_name, freecount_name))
                code.putln("memset(o, 0, sizeof(%s));" % obj_struct)
                code.putln("(void) PyObject_INIT(o, t);")
                if scope.needs_gc():
                    code.putln("PyObject_GC_Track(o);")
                code.putln("} else {")
            if not is_final_type:
                code.putln("if (likely((t->tp_flags & Py_TPFLAGS_IS_ABSTRACT) == 0)) {")
            code.putln("o = (*t->tp_alloc)(t, 0);")
            if not is_final_type:
                code.putln("} else {")
                code.putln("o = (PyObject *) PyBaseObject_Type.tp_new(t, %s, 0);" % Naming.empty_tuple)
                code.putln("}")
        code.putln("if (unlikely(!o)) return 0;")
        if freelist_size and not base_type:
            code.putln('}')
        if need_self_cast:
            code.putln("p = %s;" % type.cast_code("o"))
        #if need_self_cast:
        #    self.generate_self_cast(scope, code)
        if type.vtabslot_cname:
            vtab_base_type = type
            while vtab_base_type.base_type and vtab_base_type.base_type.vtabstruct_cname:
                vtab_base_type = vtab_base_type.base_type
            if vtab_base_type is not type:
                struct_type_cast = "(struct %s*)" % vtab_base_type.vtabstruct_cname
            else:
                struct_type_cast = ""
            code.putln("p->%s = %s%s;" % (
                type.vtabslot_cname,
                struct_type_cast, type.vtabptr_cname))

        for entry in cpp_class_attrs:
            code.putln("new((void*)&(p->%s)) %s();" %
                       (entry.cname, entry.type.declaration_code("")))

        for entry in py_attrs:
            code.put_init_var_to_py_none(entry, "p->%s", nanny=False)

        for entry in memoryview_slices:
            code.putln("p->%s.data = NULL;" % entry.cname)
            code.putln("p->%s.memview = NULL;" % entry.cname)

        for entry in py_buffers:
            code.putln("p->%s.obj = NULL;" % entry.cname)

        if cclass_entry.cname == '__pyx_memoryviewslice':
            code.putln("p->from_slice.memview = NULL;")

        if new_func_entry and new_func_entry.is_special:
            if new_func_entry.trivial_signature:
                cinit_args = "o, %s, NULL" % Naming.empty_tuple
            else:
                cinit_args = "o, a, k"
            code.putln(
                "if (unlikely(%s(%s) < 0)) {" %
                    (new_func_entry.func_cname, cinit_args))
            code.put_decref_clear("o", py_object_type, nanny=False)
            code.putln(
                "}")
        code.putln(
            "return o;")
        code.putln(
            "}")

    def generate_dealloc_function(self, scope, code):
        tp_slot = TypeSlots.ConstructorSlot("tp_dealloc", '__dealloc__')
        slot_func = scope.mangle_internal("tp_dealloc")
        base_type = scope.parent_type.base_type
        if tp_slot.slot_code(scope) != slot_func:
            return  # never used

        slot_func_cname = scope.mangle_internal("tp_dealloc")
        code.putln("")
        code.putln(
            "static void %s(PyObject *o) {" % slot_func_cname)

        is_final_type = scope.parent_type.is_final_type
        needs_gc = scope.needs_gc()

        weakref_slot = scope.lookup_here("__weakref__")
        if weakref_slot not in scope.var_entries:
            weakref_slot = None

        _, (py_attrs, _, memoryview_slices) = scope.get_refcounted_entries()
        cpp_class_attrs = [entry for entry in scope.var_entries
                           if entry.type.is_cpp_class]

        if py_attrs or cpp_class_attrs or memoryview_slices or weakref_slot:
            self.generate_self_cast(scope, code)

        if not is_final_type:
            # in Py3.4+, call tp_finalize() as early as possible
            code.putln("#if PY_VERSION_HEX >= 0x030400a1")
            if needs_gc:
                finalised_check = '!_PyGC_FINALIZED(o)'
            else:
                finalised_check = (
                    '(!PyType_IS_GC(Py_TYPE(o)) || !_PyGC_FINALIZED(o))')
            code.putln("if (unlikely(Py_TYPE(o)->tp_finalize) && %s) {" %
                       finalised_check)
            # if instance was resurrected by finaliser, return
            code.putln("if (PyObject_CallFinalizerFromDealloc(o)) return;")
            code.putln("}")
            code.putln("#endif")

        if needs_gc:
            # We must mark this object as (gc) untracked while tearing
            # it down, lest the garbage collection is invoked while
            # running this destructor.
            code.putln("PyObject_GC_UnTrack(o);")

        # call the user's __dealloc__
        self.generate_usr_dealloc_call(scope, code)

        if weakref_slot:
            code.putln("if (p->__weakref__) PyObject_ClearWeakRefs(o);")

        for entry in cpp_class_attrs:
            code.putln("__Pyx_call_destructor(&p->%s);" % entry.cname)

        for entry in py_attrs:
            code.put_xdecref_clear("p->%s" % entry.cname, entry.type, nanny=False,
                                   clear_before_decref=True)

        for entry in memoryview_slices:
            code.put_xdecref_memoryviewslice("p->%s" % entry.cname,
                                             have_gil=True)

        if base_type:
            if needs_gc:
                # The base class deallocator probably expects this to be tracked,
                # so undo the untracking above.
                if base_type.scope and base_type.scope.needs_gc():
                    code.putln("PyObject_GC_Track(o);")
                else:
                    code.putln("#if CYTHON_COMPILING_IN_CPYTHON")
                    code.putln("if (PyType_IS_GC(Py_TYPE(o)->tp_base))")
                    code.putln("#endif")
                    code.putln("PyObject_GC_Track(o);")

            tp_dealloc = TypeSlots.get_base_slot_function(scope, tp_slot)
            if tp_dealloc is not None:
                code.putln("%s(o);" % tp_dealloc)
            elif base_type.is_builtin_type:
                code.putln("%s->tp_dealloc(o);" % base_type.typeptr_cname)
            else:
                # This is an externally defined type.  Calling through the
                # cimported base type pointer directly interacts badly with
                # the module cleanup, which may already have cleared it.
                # In that case, fall back to traversing the type hierarchy.
                base_cname = base_type.typeptr_cname
                code.putln("if (likely(%s)) %s->tp_dealloc(o); "
                           "else __Pyx_call_next_tp_dealloc(o, %s);" % (
                               base_cname, base_cname, slot_func_cname))
                code.globalstate.use_utility_code(
                    UtilityCode.load_cached("CallNextTpDealloc", "ExtensionTypes.c"))
        else:
            freelist_size = scope.directives.get('freelist', 0)
            if freelist_size:
                freelist_name = scope.mangle_internal(Naming.freelist_name)
                freecount_name = scope.mangle_internal(Naming.freecount_name)

                if is_final_type:
                    type_safety_check = ''
                else:
                    type_safety_check = (
                        ' & ((Py_TYPE(o)->tp_flags & (Py_TPFLAGS_IS_ABSTRACT | Py_TPFLAGS_HEAPTYPE)) == 0)')

                type = scope.parent_type
                code.putln("if (CYTHON_COMPILING_IN_CPYTHON && ((%s < %d) & (Py_TYPE(o)->tp_basicsize == sizeof(%s))%s)) {" % (
                    freecount_name, freelist_size, type.declaration_code("", deref=True),
                    type_safety_check))
                code.putln("%s[%s++] = %s;" % (
                    freelist_name, freecount_name, type.cast_code("o")))
                code.putln("} else {")
            code.putln("(*Py_TYPE(o)->tp_free)(o);")
            if freelist_size:
                code.putln("}")
        code.putln(
            "}")

    def generate_usr_dealloc_call(self, scope, code):
        entry = scope.lookup_here("__dealloc__")
        if not entry:
            return

        code.putln("{")
        code.putln("PyObject *etype, *eval, *etb;")
        code.putln("PyErr_Fetch(&etype, &eval, &etb);")
        code.putln("++Py_REFCNT(o);")
        code.putln("%s(o);" % entry.func_cname)
        code.putln("--Py_REFCNT(o);")
        code.putln("PyErr_Restore(etype, eval, etb);")
        code.putln("}")

    def generate_traverse_function(self, scope, code, cclass_entry):
        tp_slot = TypeSlots.GCDependentSlot("tp_traverse")
        slot_func = scope.mangle_internal("tp_traverse")
        base_type = scope.parent_type.base_type
        if tp_slot.slot_code(scope) != slot_func:
            return # never used
        code.putln("")
        code.putln(
            "static int %s(PyObject *o, visitproc v, void *a) {"
                % slot_func)

        have_entries, (py_attrs, py_buffers, memoryview_slices) = (
            scope.get_refcounted_entries(include_gc_simple=False))

        if base_type or py_attrs:
            code.putln("int e;")

        if py_attrs or py_buffers:
            self.generate_self_cast(scope, code)

        if base_type:
            # want to call it explicitly if possible so inlining can be performed
            static_call = TypeSlots.get_base_slot_function(scope, tp_slot)
            if static_call:
                code.putln("e = %s(o, v, a); if (e) return e;" % static_call)
            elif base_type.is_builtin_type:
                base_cname = base_type.typeptr_cname
                code.putln("if (!%s->tp_traverse); else { e = %s->tp_traverse(o,v,a); if (e) return e; }" % (
                    base_cname, base_cname))
            else:
                # This is an externally defined type.  Calling through the
                # cimported base type pointer directly interacts badly with
                # the module cleanup, which may already have cleared it.
                # In that case, fall back to traversing the type hierarchy.
                base_cname = base_type.typeptr_cname
                code.putln("e = ((likely(%s)) ? ((%s->tp_traverse) ? %s->tp_traverse(o, v, a) : 0) : __Pyx_call_next_tp_traverse(o, v, a, %s)); if (e) return e;" % (
                    base_cname, base_cname, base_cname, slot_func))
                code.globalstate.use_utility_code(
                    UtilityCode.load_cached("CallNextTpTraverse", "ExtensionTypes.c"))

        for entry in py_attrs:
            var_code = "p->%s" % entry.cname
            code.putln(
                    "if (%s) {"
                        % var_code)
            if entry.type.is_extension_type:
                var_code = "((PyObject*)%s)" % var_code
            code.putln(
                        "e = (*v)(%s, a); if (e) return e;"
                            % var_code)
            code.putln(
                    "}")

        # Traverse buffer exporting objects.
        # Note: not traversing memoryview attributes of memoryview slices!
        # When triggered by the GC, it would cause multiple visits (gc_refs
        # subtractions which is not matched by its reference count!)
        for entry in py_buffers:
            cname = entry.cname + ".obj"
            code.putln("if (p->%s) {" % cname)
            code.putln(    "e = (*v)(p->%s, a); if (e) return e;" % cname)
            code.putln("}")

        code.putln(
                "return 0;")
        code.putln(
            "}")

    def generate_clear_function(self, scope, code, cclass_entry):
        tp_slot = TypeSlots.GCDependentSlot("tp_clear")
        slot_func = scope.mangle_internal("tp_clear")
        base_type = scope.parent_type.base_type
        if tp_slot.slot_code(scope) != slot_func:
            return # never used

        have_entries, (py_attrs, py_buffers, memoryview_slices) = (
            scope.get_refcounted_entries(include_gc_simple=False))

        if py_attrs or py_buffers or base_type:
            unused = ''
        else:
            unused = 'CYTHON_UNUSED '

        code.putln("")
        code.putln("static int %s(%sPyObject *o) {" % (slot_func, unused))

        if py_attrs and Options.clear_to_none:
            code.putln("PyObject* tmp;")

        if py_attrs or py_buffers:
            self.generate_self_cast(scope, code)

        if base_type:
            # want to call it explicitly if possible so inlining can be performed
            static_call = TypeSlots.get_base_slot_function(scope, tp_slot)
            if static_call:
                code.putln("%s(o);" % static_call)
            elif base_type.is_builtin_type:
                base_cname = base_type.typeptr_cname
                code.putln("if (!%s->tp_clear); else %s->tp_clear(o);" % (
                    base_cname, base_cname))
            else:
                # This is an externally defined type.  Calling through the
                # cimported base type pointer directly interacts badly with
                # the module cleanup, which may already have cleared it.
                # In that case, fall back to traversing the type hierarchy.
                base_cname = base_type.typeptr_cname
                code.putln("if (likely(%s)) { if (%s->tp_clear) %s->tp_clear(o); } else __Pyx_call_next_tp_clear(o, %s);" % (
                    base_cname, base_cname, base_cname, slot_func))
                code.globalstate.use_utility_code(
                    UtilityCode.load_cached("CallNextTpClear", "ExtensionTypes.c"))

        if Options.clear_to_none:
            for entry in py_attrs:
                name = "p->%s" % entry.cname
                code.putln("tmp = ((PyObject*)%s);" % name)
                if entry.is_declared_generic:
                    code.put_init_to_py_none(name, py_object_type, nanny=False)
                else:
                    code.put_init_to_py_none(name, entry.type, nanny=False)
                code.putln("Py_XDECREF(tmp);")
        else:
            for entry in py_attrs:
                code.putln("Py_CLEAR(p->%s);" % entry.cname)

        for entry in py_buffers:
            # Note: shouldn't this call __Pyx_ReleaseBuffer ??
            code.putln("Py_CLEAR(p->%s.obj);" % entry.cname)

        if cclass_entry.cname == '__pyx_memoryviewslice':
            code.putln("__PYX_XDEC_MEMVIEW(&p->from_slice, 1);")

        code.putln(
            "return 0;")
        code.putln(
            "}")

    def generate_getitem_int_function(self, scope, code):
        # This function is put into the sq_item slot when
        # a __getitem__ method is present. It converts its
        # argument to a Python integer and calls mp_subscript.
        code.putln(
            "static PyObject *%s(PyObject *o, Py_ssize_t i) {" %
                scope.mangle_internal("sq_item"))
        code.putln(
                "PyObject *r;")
        code.putln(
                "PyObject *x = PyInt_FromSsize_t(i); if(!x) return 0;")
        code.putln(
                "r = Py_TYPE(o)->tp_as_mapping->mp_subscript(o, x);")
        code.putln(
                "Py_DECREF(x);")
        code.putln(
                "return r;")
        code.putln(
            "}")

    def generate_ass_subscript_function(self, scope, code):
        # Setting and deleting an item are both done through
        # the ass_subscript method, so we dispatch to user's __setitem__
        # or __delitem__, or raise an exception.
        base_type = scope.parent_type.base_type
        set_entry = scope.lookup_here("__setitem__")
        del_entry = scope.lookup_here("__delitem__")
        code.putln("")
        code.putln(
            "static int %s(PyObject *o, PyObject *i, PyObject *v) {" %
                scope.mangle_internal("mp_ass_subscript"))
        code.putln(
                "if (v) {")
        if set_entry:
            code.putln(
                    "return %s(o, i, v);" %
                        set_entry.func_cname)
        else:
            self.generate_guarded_basetype_call(
                base_type, "tp_as_mapping", "mp_ass_subscript", "o, i, v", code)
            code.putln(
                    "PyErr_Format(PyExc_NotImplementedError,")
            code.putln(
                    '  "Subscript assignment not supported by %.200s", Py_TYPE(o)->tp_name);')
            code.putln(
                    "return -1;")
        code.putln(
                "}")
        code.putln(
                "else {")
        if del_entry:
            code.putln(
                    "return %s(o, i);" %
                        del_entry.func_cname)
        else:
            self.generate_guarded_basetype_call(
                base_type, "tp_as_mapping", "mp_ass_subscript", "o, i, v", code)
            code.putln(
                    "PyErr_Format(PyExc_NotImplementedError,")
            code.putln(
                    '  "Subscript deletion not supported by %.200s", Py_TYPE(o)->tp_name);')
            code.putln(
                    "return -1;")
        code.putln(
                "}")
        code.putln(
            "}")

    def generate_guarded_basetype_call(
            self, base_type, substructure, slot, args, code):
        if base_type:
            base_tpname = base_type.typeptr_cname
            if substructure:
                code.putln(
                    "if (%s->%s && %s->%s->%s)" % (
                        base_tpname, substructure, base_tpname, substructure, slot))
                code.putln(
                    "  return %s->%s->%s(%s);" % (
                        base_tpname, substructure, slot, args))
            else:
                code.putln(
                    "if (%s->%s)" % (
                        base_tpname, slot))
                code.putln(
                    "  return %s->%s(%s);" % (
                        base_tpname, slot, args))

    def generate_ass_slice_function(self, scope, code):
        # Setting and deleting a slice are both done through
        # the ass_slice method, so we dispatch to user's __setslice__
        # or __delslice__, or raise an exception.
        base_type = scope.parent_type.base_type
        set_entry = scope.lookup_here("__setslice__")
        del_entry = scope.lookup_here("__delslice__")
        code.putln("")
        code.putln(
            "static int %s(PyObject *o, Py_ssize_t i, Py_ssize_t j, PyObject *v) {" %
                scope.mangle_internal("sq_ass_slice"))
        code.putln(
                "if (v) {")
        if set_entry:
            code.putln(
                    "return %s(o, i, j, v);" %
                        set_entry.func_cname)
        else:
            self.generate_guarded_basetype_call(
                base_type, "tp_as_sequence", "sq_ass_slice", "o, i, j, v", code)
            code.putln(
                    "PyErr_Format(PyExc_NotImplementedError,")
            code.putln(
                    '  "2-element slice assignment not supported by %.200s", Py_TYPE(o)->tp_name);')
            code.putln(
                    "return -1;")
        code.putln(
                "}")
        code.putln(
                "else {")
        if del_entry:
            code.putln(
                    "return %s(o, i, j);" %
                        del_entry.func_cname)
        else:
            self.generate_guarded_basetype_call(
                base_type, "tp_as_sequence", "sq_ass_slice", "o, i, j, v", code)
            code.putln(
                    "PyErr_Format(PyExc_NotImplementedError,")
            code.putln(
                    '  "2-element slice deletion not supported by %.200s", Py_TYPE(o)->tp_name);')
            code.putln(
                    "return -1;")
        code.putln(
                "}")
        code.putln(
            "}")

    def generate_getattro_function(self, scope, code):
        # First try to get the attribute using __getattribute__, if defined, or
        # PyObject_GenericGetAttr.
        #
        # If that raises an AttributeError, call the __getattr__ if defined.
        #
        # In both cases, defined can be in this class, or any base class.
        def lookup_here_or_base(n,type=None):
            # Recursive lookup
            if type is None:
                type = scope.parent_type
            r = type.scope.lookup_here(n)
            if r is None and \
               type.base_type is not None:
                return lookup_here_or_base(n,type.base_type)
            else:
                return r
        getattr_entry = lookup_here_or_base("__getattr__")
        getattribute_entry = lookup_here_or_base("__getattribute__")
        code.putln("")
        code.putln(
            "static PyObject *%s(PyObject *o, PyObject *n) {"
                % scope.mangle_internal("tp_getattro"))
        if getattribute_entry is not None:
            code.putln(
                "PyObject *v = %s(o, n);" %
                    getattribute_entry.func_cname)
        else:
            code.putln(
                "PyObject *v = PyObject_GenericGetAttr(o, n);")
        if getattr_entry is not None:
            code.putln(
                "if (!v && PyErr_ExceptionMatches(PyExc_AttributeError)) {")
            code.putln(
                "PyErr_Clear();")
            code.putln(
                "v = %s(o, n);" %
                    getattr_entry.func_cname)
            code.putln(
                "}")
        code.putln(
            "return v;")
        code.putln(
            "}")

    def generate_setattro_function(self, scope, code):
        # Setting and deleting an attribute are both done through
        # the setattro method, so we dispatch to user's __setattr__
        # or __delattr__ or fall back on PyObject_GenericSetAttr.
        base_type = scope.parent_type.base_type
        set_entry = scope.lookup_here("__setattr__")
        del_entry = scope.lookup_here("__delattr__")
        code.putln("")
        code.putln(
            "static int %s(PyObject *o, PyObject *n, PyObject *v) {" %
                scope.mangle_internal("tp_setattro"))
        code.putln(
                "if (v) {")
        if set_entry:
            code.putln(
                    "return %s(o, n, v);" %
                        set_entry.func_cname)
        else:
            self.generate_guarded_basetype_call(
                base_type, None, "tp_setattro", "o, n, v", code)
            code.putln(
                    "return PyObject_GenericSetAttr(o, n, v);")
        code.putln(
                "}")
        code.putln(
                "else {")
        if del_entry:
            code.putln(
                    "return %s(o, n);" %
                        del_entry.func_cname)
        else:
            self.generate_guarded_basetype_call(
                base_type, None, "tp_setattro", "o, n, v", code)
            code.putln(
                    "return PyObject_GenericSetAttr(o, n, 0);")
        code.putln(
                "}")
        code.putln(
            "}")

    def generate_descr_get_function(self, scope, code):
        # The __get__ function of a descriptor object can be
        # called with NULL for the second or third arguments
        # under some circumstances, so we replace them with
        # None in that case.
        user_get_entry = scope.lookup_here("__get__")
        code.putln("")
        code.putln(
            "static PyObject *%s(PyObject *o, PyObject *i, PyObject *c) {" %
                scope.mangle_internal("tp_descr_get"))
        code.putln(
            "PyObject *r = 0;")
        code.putln(
            "if (!i) i = Py_None;")
        code.putln(
            "if (!c) c = Py_None;")
        #code.put_incref("i", py_object_type)
        #code.put_incref("c", py_object_type)
        code.putln(
            "r = %s(o, i, c);" %
                user_get_entry.func_cname)
        #code.put_decref("i", py_object_type)
        #code.put_decref("c", py_object_type)
        code.putln(
            "return r;")
        code.putln(
            "}")

    def generate_descr_set_function(self, scope, code):
        # Setting and deleting are both done through the __set__
        # method of a descriptor, so we dispatch to user's __set__
        # or __delete__ or raise an exception.
        base_type = scope.parent_type.base_type
        user_set_entry = scope.lookup_here("__set__")
        user_del_entry = scope.lookup_here("__delete__")
        code.putln("")
        code.putln(
            "static int %s(PyObject *o, PyObject *i, PyObject *v) {" %
                scope.mangle_internal("tp_descr_set"))
        code.putln(
                "if (v) {")
        if user_set_entry:
            code.putln(
                    "return %s(o, i, v);" %
                        user_set_entry.func_cname)
        else:
            self.generate_guarded_basetype_call(
                base_type, None, "tp_descr_set", "o, i, v", code)
            code.putln(
                    'PyErr_SetString(PyExc_NotImplementedError, "__set__");')
            code.putln(
                    "return -1;")
        code.putln(
                "}")
        code.putln(
                "else {")
        if user_del_entry:
            code.putln(
                    "return %s(o, i);" %
                        user_del_entry.func_cname)
        else:
            self.generate_guarded_basetype_call(
                base_type, None, "tp_descr_set", "o, i, v", code)
            code.putln(
                    'PyErr_SetString(PyExc_NotImplementedError, "__delete__");')
            code.putln(
                    "return -1;")
        code.putln(
                "}")
        code.putln(
            "}")

    def generate_property_accessors(self, cclass_scope, code):
        for entry in cclass_scope.property_entries:
            property_scope = entry.scope
            if property_scope.defines_any(["__get__"]):
                self.generate_property_get_function(entry, code)
            if property_scope.defines_any(["__set__", "__del__"]):
                self.generate_property_set_function(entry, code)

    def generate_property_get_function(self, property_entry, code):
        property_scope = property_entry.scope
        property_entry.getter_cname = property_scope.parent_scope.mangle(
            Naming.prop_get_prefix, property_entry.name)
        get_entry = property_scope.lookup_here("__get__")
        code.putln("")
        code.putln(
            "static PyObject *%s(PyObject *o, CYTHON_UNUSED void *x) {" %
                property_entry.getter_cname)
        code.putln(
                "return %s(o);" %
                    get_entry.func_cname)
        code.putln(
            "}")

    def generate_property_set_function(self, property_entry, code):
        property_scope = property_entry.scope
        property_entry.setter_cname = property_scope.parent_scope.mangle(
            Naming.prop_set_prefix, property_entry.name)
        set_entry = property_scope.lookup_here("__set__")
        del_entry = property_scope.lookup_here("__del__")
        code.putln("")
        code.putln(
            "static int %s(PyObject *o, PyObject *v, CYTHON_UNUSED void *x) {" %
                property_entry.setter_cname)
        code.putln(
                "if (v) {")
        if set_entry:
            code.putln(
                    "return %s(o, v);" %
                        set_entry.func_cname)
        else:
            code.putln(
                    'PyErr_SetString(PyExc_NotImplementedError, "__set__");')
            code.putln(
                    "return -1;")
        code.putln(
                "}")
        code.putln(
                "else {")
        if del_entry:
            code.putln(
                    "return %s(o);" %
                        del_entry.func_cname)
        else:
            code.putln(
                    'PyErr_SetString(PyExc_NotImplementedError, "__del__");')
            code.putln(
                    "return -1;")
        code.putln(
                "}")
        code.putln(
            "}")

    def generate_typeobj_definition(self, modname, entry, code):
        type = entry.type
        scope = type.scope
        for suite in TypeSlots.substructures:
            suite.generate_substructure(scope, code)
        code.putln("")
        if entry.visibility == 'public':
            header = "DL_EXPORT(PyTypeObject) %s = {"
        else:
            header = "static PyTypeObject %s = {"
        #code.putln(header % scope.parent_type.typeobj_cname)
        code.putln(header % type.typeobj_cname)
        code.putln(
            "PyVarObject_HEAD_INIT(0, 0)")
        code.putln(
            '__Pyx_NAMESTR("%s.%s"), /*tp_name*/' % (
                self.full_module_name, scope.class_name))
        if type.typedef_flag:
            objstruct = type.objstruct_cname
        else:
            objstruct = "struct %s" % type.objstruct_cname
        code.putln(
            "sizeof(%s), /*tp_basicsize*/" %
                objstruct)
        code.putln(
            "0, /*tp_itemsize*/")
        for slot in TypeSlots.slot_table:
            slot.generate(scope, code)
        code.putln(
            "};")

    def generate_method_table(self, env, code):
        if env.is_c_class_scope and not env.pyfunc_entries:
            return
        code.putln("")
        code.putln(
            "static PyMethodDef %s[] = {" %
                env.method_table_cname)
        for entry in env.pyfunc_entries:
            if not entry.fused_cfunction:
                code.put_pymethoddef(entry, ",")
        code.putln(
                "{0, 0, 0, 0}")
        code.putln(
            "};")

    def generate_getset_table(self, env, code):
        if env.property_entries:
            code.putln("")
            code.putln(
                "static struct PyGetSetDef %s[] = {" %
                    env.getset_table_cname)
            for entry in env.property_entries:
                if entry.doc:
                    doc_code = "__Pyx_DOCSTR(%s)" % code.get_string_const(entry.doc)
                else:
                    doc_code = "0"
                code.putln(
                    '{(char *)"%s", %s, %s, %s, 0},' % (
                        entry.name,
                        entry.getter_cname or "0",
                        entry.setter_cname or "0",
                        doc_code))
            code.putln(
                    "{0, 0, 0, 0, 0}")
            code.putln(
                "};")

    def generate_import_star(self, env, code):
        env.use_utility_code(streq_utility_code)
        code.putln()
        code.putln("static char* %s_type_names[] = {" % Naming.import_star)
        for name, entry in sorted(env.entries.items()):
            if entry.is_type:
                code.putln('"%s",' % name)
        code.putln("0")
        code.putln("};")
        code.putln()
        code.enter_cfunc_scope() # as we need labels
        code.putln("static int %s(PyObject *o, PyObject* py_name, char *name) {" % Naming.import_star_set)
        code.putln("char** type_name = %s_type_names;" % Naming.import_star)
        code.putln("while (*type_name) {")
        code.putln("if (__Pyx_StrEq(name, *type_name)) {")
        code.putln('PyErr_Format(PyExc_TypeError, "Cannot overwrite C type %s", name);')
        code.putln('goto bad;')
        code.putln("}")
        code.putln("type_name++;")
        code.putln("}")
        old_error_label = code.new_error_label()
        code.putln("if (0);") # so the first one can be "else if"
        for name, entry in env.entries.items():
            if entry.is_cglobal and entry.used:
                code.putln('else if (__Pyx_StrEq(name, "%s")) {' % name)
                if entry.type.is_pyobject:
                    if entry.type.is_extension_type or entry.type.is_builtin_type:
                        code.putln("if (!(%s)) %s;" % (
                            entry.type.type_test_code("o"),
                            code.error_goto(entry.pos)))
                    code.putln("Py_INCREF(o);")
                    code.put_decref(entry.cname, entry.type, nanny=False)
                    code.putln("%s = %s;" % (
                        entry.cname,
                        PyrexTypes.typecast(entry.type, py_object_type, "o")))
                elif entry.type.from_py_function:
                    rhs = "%s(o)" % entry.type.from_py_function
                    if entry.type.is_enum:
                        rhs = PyrexTypes.typecast(entry.type, PyrexTypes.c_long_type, rhs)
                    code.putln("%s = %s; if (%s) %s;" % (
                        entry.cname,
                        rhs,
                        entry.type.error_condition(entry.cname),
                        code.error_goto(entry.pos)))
                else:
                    code.putln('PyErr_Format(PyExc_TypeError, "Cannot convert Python object %s to %s");' % (name, entry.type))
                    code.putln(code.error_goto(entry.pos))
                code.putln("}")
        code.putln("else {")
        code.putln("if (PyObject_SetAttr(%s, py_name, o) < 0) goto bad;" % Naming.module_cname)
        code.putln("}")
        code.putln("return 0;")
        if code.label_used(code.error_label):
            code.put_label(code.error_label)
            # This helps locate the offending name.
            code.put_add_traceback(self.full_module_name)
        code.error_label = old_error_label
        code.putln("bad:")
        code.putln("return -1;")
        code.putln("}")
        code.putln(import_star_utility_code)
        code.exit_cfunc_scope() # done with labels

    def generate_module_init_func(self, imported_modules, env, code):
        code.enter_cfunc_scope()
        code.putln("")
        header2 = "PyMODINIT_FUNC init%s(void)" % env.module_name
        header3 = "PyMODINIT_FUNC PyInit_%s(void)" % env.module_name
        code.putln("#if PY_MAJOR_VERSION < 3")
        code.putln("%s; /*proto*/" % header2)
        code.putln(header2)
        code.putln("#else")
        code.putln("%s; /*proto*/" % header3)
        code.putln(header3)
        code.putln("#endif")
        code.putln("{")
        tempdecl_code = code.insertion_point()

        code.put_declare_refcount_context()
        code.putln("#if CYTHON_REFNANNY")
        code.putln("__Pyx_RefNanny = __Pyx_RefNannyImportAPI(\"refnanny\");")
        code.putln("if (!__Pyx_RefNanny) {")
        code.putln("  PyErr_Clear();")
        code.putln("  __Pyx_RefNanny = __Pyx_RefNannyImportAPI(\"Cython.Runtime.refnanny\");")
        code.putln("  if (!__Pyx_RefNanny)")
        code.putln("      Py_FatalError(\"failed to import 'refnanny' module\");")
        code.putln("}")
        code.putln("#endif")
        code.put_setup_refcount_context(header3)

        env.use_utility_code(UtilityCode.load("CheckBinaryVersion", "ModuleSetupCode.c"))
        code.putln("if ( __Pyx_check_binary_version() < 0) %s" % code.error_goto(self.pos))

        code.putln("%s = PyTuple_New(0); %s" % (Naming.empty_tuple, code.error_goto_if_null(Naming.empty_tuple, self.pos)))
        code.putln("%s = PyBytes_FromStringAndSize(\"\", 0); %s" % (Naming.empty_bytes, code.error_goto_if_null(Naming.empty_bytes, self.pos)))

        code.putln("#ifdef __Pyx_CyFunction_USED")
        code.putln("if (__Pyx_CyFunction_init() < 0) %s" % code.error_goto(self.pos))
        code.putln("#endif")

        code.putln("#ifdef __Pyx_FusedFunction_USED")
        code.putln("if (__pyx_FusedFunction_init() < 0) %s" % code.error_goto(self.pos))
        code.putln("#endif")

        code.putln("#ifdef __Pyx_Generator_USED")
        code.putln("if (__pyx_Generator_init() < 0) %s" % code.error_goto(self.pos))
        code.putln("#endif")

        code.putln("/*--- Library function declarations ---*/")
        env.generate_library_function_declarations(code)

        code.putln("/*--- Threads initialization code ---*/")
        code.putln("#if defined(__PYX_FORCE_INIT_THREADS) && __PYX_FORCE_INIT_THREADS")
        code.putln("#ifdef WITH_THREAD /* Python build with threading support? */")
        code.putln("PyEval_InitThreads();")
        code.putln("#endif")
        code.putln("#endif")

        code.putln("/*--- Module creation code ---*/")
        self.generate_module_creation_code(env, code)

        code.putln("/*--- Initialize various global constants etc. ---*/")
        code.putln(code.error_goto_if_neg("__Pyx_InitGlobals()", self.pos))

        code.putln("#if PY_MAJOR_VERSION < 3 && (__PYX_DEFAULT_STRING_ENCODING_IS_ASCII || __PYX_DEFAULT_STRING_ENCODING_IS_DEFAULT)")
        code.putln("if (__Pyx_init_sys_getdefaultencoding_params() < 0) %s" % code.error_goto(self.pos))
        code.putln("#endif")

        __main__name = code.globalstate.get_py_string_const(
            EncodedString("__main__"), identifier=True)
        code.putln("if (%s%s) {" % (Naming.module_is_main, self.full_module_name.replace('.', '__')))
        code.putln(
            'if (__Pyx_SetAttrString(%s, "__name__", %s) < 0) %s;' % (
                env.module_cname,
                __main__name.cname,
                code.error_goto(self.pos)))
        code.putln("}")

        # set up __file__ and __path__, then add the module to sys.modules
        self.generate_module_import_setup(env, code)

        if Options.cache_builtins:
            code.putln("/*--- Builtin init code ---*/")
            code.putln(code.error_goto_if_neg("__Pyx_InitCachedBuiltins()", self.pos))

        code.putln("/*--- Constants init code ---*/")
        code.putln(code.error_goto_if_neg("__Pyx_InitCachedConstants()", self.pos))

        code.putln("/*--- Global init code ---*/")
        self.generate_global_init_code(env, code)

        code.putln("/*--- Variable export code ---*/")
        self.generate_c_variable_export_code(env, code)

        code.putln("/*--- Function export code ---*/")
        self.generate_c_function_export_code(env, code)

        code.putln("/*--- Type init code ---*/")
        self.generate_type_init_code(env, code)

        code.putln("/*--- Type import code ---*/")
        for module in imported_modules:
            self.generate_type_import_code_for_module(module, env, code)

        code.putln("/*--- Variable import code ---*/")
        for module in imported_modules:
            self.generate_c_variable_import_code_for_module(module, env, code)

        code.putln("/*--- Function import code ---*/")
        for module in imported_modules:
            self.specialize_fused_types(module)
            self.generate_c_function_import_code_for_module(module, env, code)

        code.putln("/*--- Execution code ---*/")
        code.mark_pos(None)

        self.body.generate_execution_code(code)

        if Options.generate_cleanup_code:
            code.globalstate.use_utility_code(
                UtilityCode.load_cached("RegisterModuleCleanup", "ModuleSetupCode.c"))
            code.putln("if (__Pyx_RegisterCleanup()) %s;" % code.error_goto(self.pos))

        code.put_goto(code.return_label)
        code.put_label(code.error_label)
        for cname, type in code.funcstate.all_managed_temps():
            code.put_xdecref(cname, type)
        code.putln('if (%s) {' % env.module_cname)
        code.put_add_traceback("init %s" % env.qualified_name)
        env.use_utility_code(Nodes.traceback_utility_code)
        code.put_decref_clear(env.module_cname, py_object_type, nanny=False)
        code.putln('} else if (!PyErr_Occurred()) {')
        code.putln('PyErr_SetString(PyExc_ImportError, "init %s");' % env.qualified_name)
        code.putln('}')
        code.put_label(code.return_label)

        code.put_finish_refcount_context()

        code.putln("#if PY_MAJOR_VERSION < 3")
        code.putln("return;")
        code.putln("#else")
        code.putln("return %s;" % env.module_cname)
        code.putln("#endif")
        code.putln('}')

        tempdecl_code.put_temp_declarations(code.funcstate)

        code.exit_cfunc_scope()

    def generate_module_import_setup(self, env, code):
        module_path = env.directives['set_initial_path']
        if module_path == 'SOURCEFILE':
            module_path = self.pos[0].filename

        if module_path:
            code.putln('if (__Pyx_SetAttrString(%s, "__file__", %s) < 0) %s;' % (
                env.module_cname,
                code.globalstate.get_py_string_const(
                    EncodedString(decode_filename(module_path))).cname,
                code.error_goto(self.pos)))

            if env.is_package:
                # set __path__ to mark the module as package
                temp = code.funcstate.allocate_temp(py_object_type, True)
                code.putln('%s = Py_BuildValue("[O]", %s); %s' % (
                    temp,
                    code.globalstate.get_py_string_const(
                        EncodedString(decode_filename(
                            os.path.dirname(module_path)))).cname,
                    code.error_goto_if_null(temp, self.pos)))
                code.put_gotref(temp)
                code.putln(
                    'if (__Pyx_SetAttrString(%s, "__path__", %s) < 0) %s;' % (
                        env.module_cname, temp, code.error_goto(self.pos)))
                code.put_decref_clear(temp, py_object_type)
                code.funcstate.release_temp(temp)

        elif env.is_package:
            # packages require __path__, so all we can do is try to figure
            # out the module path at runtime by rerunning the import lookup
            package_name, _ = self.full_module_name.rsplit('.', 1)
            if '.' in package_name:
                parent_name = '"%s"' % (package_name.rsplit('.', 1)[0],)
            else:
                parent_name = 'NULL'
            code.globalstate.use_utility_code(UtilityCode.load(
                "SetPackagePathFromImportLib", "ImportExport.c"))
            code.putln(code.error_goto_if_neg(
                '__Pyx_SetPackagePathFromImportLib(%s, %s)' % (
                    parent_name,
                    code.globalstate.get_py_string_const(
                        EncodedString(env.module_name)).cname),
                self.pos))

        # CPython may not have put us into sys.modules yet, but relative imports and reimports require it
        fq_module_name = self.full_module_name
        if fq_module_name.endswith('.__init__'):
            fq_module_name = fq_module_name[:-len('.__init__')]
        code.putln("#if PY_MAJOR_VERSION >= 3")
        code.putln("{")
        code.putln("PyObject *modules = PyImport_GetModuleDict(); %s" %
                   code.error_goto_if_null("modules", self.pos))
        code.putln('if (!PyDict_GetItemString(modules, "%s")) {' % fq_module_name)
        code.putln(code.error_goto_if_neg('PyDict_SetItemString(modules, "%s", %s)' % (
            fq_module_name, env.module_cname), self.pos))
        code.putln("}")
        code.putln("}")
        code.putln("#endif")

    def generate_module_cleanup_func(self, env, code):
        if not Options.generate_cleanup_code:
            return

        code.putln('static void %s(CYTHON_UNUSED PyObject *self) {' %
                   Naming.cleanup_cname)
        if Options.generate_cleanup_code >= 2:
            code.putln("/*--- Global cleanup code ---*/")
            rev_entries = list(env.var_entries)
            rev_entries.reverse()
            for entry in rev_entries:
                if entry.visibility != 'extern':
                    if entry.type.is_pyobject and entry.used:
                        code.put_xdecref_clear(
                            entry.cname, entry.type,
                            clear_before_decref=True,
                            nanny=False)
        code.putln("__Pyx_CleanupGlobals();")
        if Options.generate_cleanup_code >= 3:
            code.putln("/*--- Type import cleanup code ---*/")
            for ext_type in sorted(env.types_imported, key=operator.attrgetter('typeptr_cname')):
                code.put_xdecref_clear(
                    ext_type.typeptr_cname, ext_type,
                    clear_before_decref=True,
                    nanny=False)
        if Options.cache_builtins:
            code.putln("/*--- Builtin cleanup code ---*/")
            for entry in env.cached_builtins:
                code.put_xdecref_clear(
                    entry.cname, PyrexTypes.py_object_type,
                    clear_before_decref=True,
                    nanny=False)
        code.putln("/*--- Intern cleanup code ---*/")
        code.put_decref_clear(Naming.empty_tuple,
                              PyrexTypes.py_object_type,
                              clear_before_decref=True,
                              nanny=False)
        for entry in env.c_class_entries:
            cclass_type = entry.type
            if cclass_type.is_external or cclass_type.base_type:
                continue
            if cclass_type.scope.directives.get('freelist', 0):
                scope = cclass_type.scope
                freelist_name = scope.mangle_internal(Naming.freelist_name)
                freecount_name = scope.mangle_internal(Naming.freecount_name)
                code.putln("while (%s > 0) {" % freecount_name)
                code.putln("PyObject* o = (PyObject*)%s[--%s];" % (
                    freelist_name, freecount_name))
                code.putln("(*Py_TYPE(o)->tp_free)(o);")
                code.putln("}")
#        for entry in env.pynum_entries:
#            code.put_decref_clear(entry.cname,
#                                  PyrexTypes.py_object_type,
#                                  nanny=False)
#        for entry in env.all_pystring_entries:
#            if entry.is_interned:
#                code.put_decref_clear(entry.pystring_cname,
#                                      PyrexTypes.py_object_type,
#                                      nanny=False)
#        for entry in env.default_entries:
#            if entry.type.is_pyobject and entry.used:
#                code.putln("Py_DECREF(%s); %s = 0;" % (
#                    code.entry_as_pyobject(entry), entry.cname))
        code.putln('#if CYTHON_COMPILING_IN_PYPY')
        code.putln('Py_CLEAR(%s);' % Naming.builtins_cname)
        code.putln('#endif')
        code.put_decref_clear(env.module_dict_cname, py_object_type,
                              nanny=False, clear_before_decref=True)

    def generate_main_method(self, env, code):
        module_is_main = "%s%s" % (Naming.module_is_main, self.full_module_name.replace('.', '__'))
        if Options.embed == "main":
            wmain = "wmain"
        else:
            wmain = Options.embed
        code.globalstate.use_utility_code(
            main_method.specialize(
                module_name = env.module_name,
                module_is_main = module_is_main,
                main_method = Options.embed,
                wmain_method = wmain))

    def generate_pymoduledef_struct(self, env, code):
        if env.doc:
            doc = "__Pyx_DOCSTR(%s)" % code.get_string_const(env.doc)
        else:
            doc = "0"
        if Options.generate_cleanup_code:
            cleanup_func = "(freefunc)%s" % Naming.cleanup_cname
        else:
            cleanup_func = 'NULL'

        code.putln("")
        code.putln("#if PY_MAJOR_VERSION >= 3")
        code.putln("static struct PyModuleDef %s = {" % Naming.pymoduledef_cname)
        code.putln("#if PY_VERSION_HEX < 0x03020000")
        # fix C compiler warnings due to missing initialisers
        code.putln("  { PyObject_HEAD_INIT(NULL) NULL, 0, NULL },")
        code.putln("#else")
        code.putln("  PyModuleDef_HEAD_INIT,")
        code.putln("#endif")
        code.putln('  __Pyx_NAMESTR("%s"),' % env.module_name)
        code.putln("  %s, /* m_doc */" % doc)
        code.putln("  -1, /* m_size */")
        code.putln("  %s /* m_methods */," % env.method_table_cname)
        code.putln("  NULL, /* m_reload */")
        code.putln("  NULL, /* m_traverse */")
        code.putln("  NULL, /* m_clear */")
        code.putln("  %s /* m_free */" % cleanup_func)
        code.putln("};")
        code.putln("#endif")

    def generate_module_creation_code(self, env, code):
        # Generate code to create the module object and
        # install the builtins.
        if env.doc:
            doc = "__Pyx_DOCSTR(%s)" % code.get_string_const(env.doc)
        else:
            doc = "0"
        code.putln("#if PY_MAJOR_VERSION < 3")
        code.putln(
            '%s = Py_InitModule4(__Pyx_NAMESTR("%s"), %s, %s, 0, PYTHON_API_VERSION); Py_XINCREF(%s);' % (
                env.module_cname,
                env.module_name,
                env.method_table_cname,
                doc,
                env.module_cname))
        code.putln("#else")
        code.putln(
            "%s = PyModule_Create(&%s);" % (
                env.module_cname,
                Naming.pymoduledef_cname))
        code.putln("#endif")
        code.putln(code.error_goto_if_null(env.module_cname, self.pos))
        code.putln(
            "%s = PyModule_GetDict(%s); %s" % (
                env.module_dict_cname, env.module_cname,
                code.error_goto_if_null(env.module_dict_cname, self.pos)))
        code.put_incref(env.module_dict_cname, py_object_type, nanny=False)

        code.putln(
            '%s = PyImport_AddModule(__Pyx_NAMESTR(__Pyx_BUILTIN_MODULE_NAME)); %s' % (
                Naming.builtins_cname,
                code.error_goto_if_null(Naming.builtins_cname, self.pos)))
        code.putln('#if CYTHON_COMPILING_IN_PYPY')
        code.putln('Py_INCREF(%s);' % Naming.builtins_cname)
        code.putln('#endif')
        code.putln(
            'if (__Pyx_SetAttrString(%s, "__builtins__", %s) < 0) %s;' % (
                env.module_cname,
                Naming.builtins_cname,
                code.error_goto(self.pos)))
        if Options.pre_import is not None:
            code.putln(
                '%s = PyImport_AddModule(__Pyx_NAMESTR("%s")); %s' % (
                    Naming.preimport_cname,
                    Options.pre_import,
                    code.error_goto_if_null(Naming.preimport_cname, self.pos)))

    def generate_global_init_code(self, env, code):
        # Generate code to initialise global PyObject *
        # variables to None.
        for entry in env.var_entries:
            if entry.visibility != 'extern':
                if entry.used:
                    entry.type.global_init_code(entry, code)

    def generate_c_variable_export_code(self, env, code):
        # Generate code to create PyCFunction wrappers for exported C functions.
        entries = []
        for entry in env.var_entries:
            if (entry.api
                or entry.defined_in_pxd
                or (Options.cimport_from_pyx and not entry.visibility == 'extern')):
                entries.append(entry)
        if entries:
            env.use_utility_code(UtilityCode.load_cached("VoidPtrExport", "ImportExport.c"))
            for entry in entries:
                signature = entry.type.declaration_code("")
                name = code.intern_identifier(entry.name)
                code.putln('if (__Pyx_ExportVoidPtr(%s, (void *)&%s, "%s") < 0) %s' % (
                    name, entry.cname, signature,
                    code.error_goto(self.pos)))

    def generate_c_function_export_code(self, env, code):
        # Generate code to create PyCFunction wrappers for exported C functions.
        entries = []
        for entry in env.cfunc_entries:
            if (entry.api
                or entry.defined_in_pxd
                or (Options.cimport_from_pyx and not entry.visibility == 'extern')):
                entries.append(entry)
        if entries:
            env.use_utility_code(
                UtilityCode.load_cached("FunctionExport", "ImportExport.c"))
            for entry in entries:
                signature = entry.type.signature_string()
                code.putln('if (__Pyx_ExportFunction("%s", (void (*)(void))%s, "%s") < 0) %s' % (
                    entry.name,
                    entry.cname,
                    signature,
                    code.error_goto(self.pos)))

    def generate_type_import_code_for_module(self, module, env, code):
        # Generate type import code for all exported extension types in
        # an imported module.
        #if module.c_class_entries:
        for entry in module.c_class_entries:
            if entry.defined_in_pxd:
                self.generate_type_import_code(env, entry.type, entry.pos, code)

    def specialize_fused_types(self, pxd_env):
        """
        If fused c(p)def functions are defined in an imported pxd, but not
        used in this implementation file, we still have fused entries and
        not specialized ones. This method replaces any fused entries with their
        specialized ones.
        """
        for entry in pxd_env.cfunc_entries[:]:
            if entry.type.is_fused:
                # This call modifies the cfunc_entries in-place
                entry.type.get_all_specialized_function_types()

    def generate_c_variable_import_code_for_module(self, module, env, code):
        # Generate import code for all exported C functions in a cimported module.
        entries = []
        for entry in module.var_entries:
            if entry.defined_in_pxd:
                entries.append(entry)
        if entries:
            env.use_utility_code(
                UtilityCode.load_cached("ModuleImport", "ImportExport.c"))
            env.use_utility_code(
                UtilityCode.load_cached("VoidPtrImport", "ImportExport.c"))
            temp = code.funcstate.allocate_temp(py_object_type, manage_ref=True)
            code.putln(
                '%s = __Pyx_ImportModule("%s"); if (!%s) %s' % (
                    temp,
                    module.qualified_name,
                    temp,
                    code.error_goto(self.pos)))
            for entry in entries:
                if env is module:
                    cname = entry.cname
                else:
                    cname = module.mangle(Naming.varptr_prefix, entry.name)
                signature = entry.type.declaration_code("")
                code.putln(
                    'if (__Pyx_ImportVoidPtr(%s, "%s", (void **)&%s, "%s") < 0) %s' % (
                        temp, entry.name, cname, signature,
                        code.error_goto(self.pos)))
            code.putln("Py_DECREF(%s); %s = 0;" % (temp, temp))

    def generate_c_function_import_code_for_module(self, module, env, code):
        # Generate import code for all exported C functions in a cimported module.
        entries = []
        for entry in module.cfunc_entries:
            if entry.defined_in_pxd and entry.used:
                entries.append(entry)
        if entries:
            env.use_utility_code(
                UtilityCode.load_cached("ModuleImport", "ImportExport.c"))
            env.use_utility_code(
                UtilityCode.load_cached("FunctionImport", "ImportExport.c"))
            temp = code.funcstate.allocate_temp(py_object_type, manage_ref=True)
            code.putln(
                '%s = __Pyx_ImportModule("%s"); if (!%s) %s' % (
                    temp,
                    module.qualified_name,
                    temp,
                    code.error_goto(self.pos)))
            for entry in entries:
                code.putln(
                    'if (__Pyx_ImportFunction(%s, "%s", (void (**)(void))&%s, "%s") < 0) %s' % (
                        temp,
                        entry.name,
                        entry.cname,
                        entry.type.signature_string(),
                        code.error_goto(self.pos)))
            code.putln("Py_DECREF(%s); %s = 0;" % (temp, temp))

    def generate_type_init_code(self, env, code):
        # Generate type import code for extern extension types
        # and type ready code for non-extern ones.
        for entry in env.c_class_entries:
            if entry.visibility == 'extern' and not entry.utility_code_definition:
                self.generate_type_import_code(env, entry.type, entry.pos, code)
            else:
                self.generate_base_type_import_code(env, entry, code)
                self.generate_exttype_vtable_init_code(entry, code)
                self.generate_type_ready_code(env, entry, code)
                self.generate_typeptr_assignment_code(entry, code)

    def generate_base_type_import_code(self, env, entry, code):
        base_type = entry.type.base_type
        if (base_type and base_type.module_name != env.qualified_name and not
               base_type.is_builtin_type and not entry.utility_code_definition):
            self.generate_type_import_code(env, base_type, self.pos, code)

    def generate_type_import_code(self, env, type, pos, code):
        # If not already done, generate code to import the typeobject of an
        # extension type defined in another module, and extract its C method
        # table pointer if any.
        if type in env.types_imported:
            return
        env.use_utility_code(UtilityCode.load_cached("TypeImport", "ImportExport.c"))
        self.generate_type_import_call(type, code,
                                       code.error_goto_if_null(type.typeptr_cname, pos))
        if type.vtabptr_cname:
            code.globalstate.use_utility_code(
                UtilityCode.load_cached('GetVTable', 'ImportExport.c'))
            code.putln("%s = (struct %s*)__Pyx_GetVtable(%s->tp_dict); %s" % (
                type.vtabptr_cname,
                type.vtabstruct_cname,
                type.typeptr_cname,
                code.error_goto_if_null(type.vtabptr_cname, pos)))
        env.types_imported.add(type)

    py3_type_name_map = {'str' : 'bytes', 'unicode' : 'str'}

    def generate_type_import_call(self, type, code, error_code):
        if type.typedef_flag:
            objstruct = type.objstruct_cname
        else:
            objstruct = "struct %s" % type.objstruct_cname
        sizeof_objstruct = objstruct
        module_name = type.module_name
        condition = replacement = None
        if module_name not in ('__builtin__', 'builtins'):
            module_name = '"%s"' % module_name
        else:
            module_name = '__Pyx_BUILTIN_MODULE_NAME'
            if type.name in Code.non_portable_builtins_map:
                condition, replacement = Code.non_portable_builtins_map[type.name]
            if objstruct in Code.basicsize_builtins_map:
                # Some builtin types have a tp_basicsize which differs from sizeof(...):
                sizeof_objstruct = Code.basicsize_builtins_map[objstruct]

        code.put('%s = __Pyx_ImportType(%s,' % (
            type.typeptr_cname,
            module_name))

        if condition and replacement:
            code.putln("")  # start in new line
            code.putln("#if %s" % condition)
            code.putln('"%s",' % replacement)
            code.putln("#else")
            code.putln('"%s",' % type.name)
            code.putln("#endif")
        else:
            code.put(' "%s", ' % type.name)

        if sizeof_objstruct != objstruct:
            if not condition:
                code.putln("")  # start in new line
            code.putln("#if CYTHON_COMPILING_IN_PYPY")
            code.putln('sizeof(%s),' % objstruct)
            code.putln("#else")
            code.putln('sizeof(%s),' % sizeof_objstruct)
            code.putln("#endif")
        else:
            code.put('sizeof(%s), ' % objstruct)

        code.putln('%i); %s' % (
            not type.is_external or type.is_subclassed,
            error_code))

    def generate_type_ready_code(self, env, entry, code):
        # Generate a call to PyType_Ready for an extension
        # type defined in this module.
        type = entry.type
        typeobj_cname = type.typeobj_cname
        scope = type.scope
        if scope: # could be None if there was an error
            if entry.visibility != 'extern':
                for slot in TypeSlots.slot_table:
                    slot.generate_dynamic_init_code(scope, code)
                code.putln(
                    "if (PyType_Ready(&%s) < 0) %s" % (
                        typeobj_cname,
                        code.error_goto(entry.pos)))
                # Don't inherit tp_print from builtin types, restoring the
                # behavior of using tp_repr or tp_str instead.
                code.putln("%s.tp_print = 0;" % typeobj_cname)
                # Fix special method docstrings. This is a bit of a hack, but
                # unless we let PyType_Ready create the slot wrappers we have
                # a significant performance hit. (See trac #561.)
                for func in entry.type.scope.pyfunc_entries:
                    is_buffer = func.name in ('__getbuffer__',
                                               '__releasebuffer__')
                    if (func.is_special and Options.docstrings and
                            func.wrapperbase_cname and not is_buffer):
                        slot = TypeSlots.method_name_to_slot[func.name]
                        preprocessor_guard = slot.preprocessor_guard_code()
                        if preprocessor_guard:
                            code.putln(preprocessor_guard)
                        code.putln('#if CYTHON_COMPILING_IN_CPYTHON')
                        code.putln("{")
                        code.putln(
                            'PyObject *wrapper = __Pyx_GetAttrString((PyObject *)&%s, "%s"); %s' % (
                                typeobj_cname,
                                func.name,
                                code.error_goto_if_null('wrapper', entry.pos)))
                        code.putln(
                            "if (Py_TYPE(wrapper) == &PyWrapperDescr_Type) {")
                        code.putln(
                            "%s = *((PyWrapperDescrObject *)wrapper)->d_base;" % (
                                func.wrapperbase_cname))
                        code.putln(
                            "%s.doc = %s;" % (func.wrapperbase_cname, func.doc_cname))
                        code.putln(
                            "((PyWrapperDescrObject *)wrapper)->d_base = &%s;" % (
                                func.wrapperbase_cname))
                        code.putln("}")
                        code.putln("}")
                        code.putln('#endif')
                        if preprocessor_guard:
                            code.putln('#endif')
                if type.vtable_cname:
                    code.putln(
                        "if (__Pyx_SetVtable(%s.tp_dict, %s) < 0) %s" % (
                            typeobj_cname,
                            type.vtabptr_cname,
                            code.error_goto(entry.pos)))
                    code.globalstate.use_utility_code(
                        UtilityCode.load_cached('SetVTable', 'ImportExport.c'))
                if not type.scope.is_internal and not type.scope.directives['internal']:
                    # scope.is_internal is set for types defined by
                    # Cython (such as closures), the 'internal'
                    # directive is set by users
                    code.putln(
                        'if (__Pyx_SetAttrString(%s, "%s", (PyObject *)&%s) < 0) %s' % (
                            Naming.module_cname,
                            scope.class_name,
                            typeobj_cname,
                            code.error_goto(entry.pos)))
                weakref_entry = scope.lookup_here("__weakref__")
                if weakref_entry:
                    if weakref_entry.type is py_object_type:
                        tp_weaklistoffset = "%s.tp_weaklistoffset" % typeobj_cname
                        if type.typedef_flag:
                            objstruct = type.objstruct_cname
                        else:
                            objstruct = "struct %s" % type.objstruct_cname
                        code.putln("if (%s == 0) %s = offsetof(%s, %s);" % (
                            tp_weaklistoffset,
                            tp_weaklistoffset,
                            objstruct,
                            weakref_entry.cname))
                    else:
                        error(weakref_entry.pos, "__weakref__ slot must be of type 'object'")

    def generate_exttype_vtable_init_code(self, entry, code):
        # Generate code to initialise the C method table of an
        # extension type.
        type = entry.type
        if type.vtable_cname:
            code.putln(
                "%s = &%s;" % (
                    type.vtabptr_cname,
                    type.vtable_cname))
            if type.base_type and type.base_type.vtabptr_cname:
                code.putln(
                    "%s.%s = *%s;" % (
                        type.vtable_cname,
                        Naming.obj_base_cname,
                        type.base_type.vtabptr_cname))

            c_method_entries = [
                entry for entry in type.scope.cfunc_entries
                if entry.func_cname ]
            if c_method_entries:
                for meth_entry in c_method_entries:
                    cast = meth_entry.type.signature_cast_string()
                    code.putln(
                        "%s.%s = %s%s;" % (
                            type.vtable_cname,
                            meth_entry.cname,
                            cast,
                            meth_entry.func_cname))

    def generate_typeptr_assignment_code(self, entry, code):
        # Generate code to initialise the typeptr of an extension
        # type defined in this module to point to its type object.
        type = entry.type
        if type.typeobj_cname:
            code.putln(
                "%s = &%s;" % (
                    type.typeptr_cname, type.typeobj_cname))

def generate_cfunction_declaration(entry, env, code, definition):
    from_cy_utility = entry.used and entry.utility_code_definition
    if entry.used and entry.inline_func_in_pxd or (not entry.in_cinclude and (definition
            or entry.defined_in_pxd or entry.visibility == 'extern' or from_cy_utility)):
        if entry.visibility == 'extern':
            storage_class = Naming.extern_c_macro
            dll_linkage = "DL_IMPORT"
        elif entry.visibility == 'public':
            storage_class = Naming.extern_c_macro
            dll_linkage = "DL_EXPORT"
        elif entry.visibility == 'private':
            storage_class = "static"
            dll_linkage = None
        else:
            storage_class = "static"
            dll_linkage = None
        type = entry.type

        if entry.defined_in_pxd and not definition:
            storage_class = "static"
            dll_linkage = None
            type = CPtrType(type)

        header = type.declaration_code(
            entry.cname, dll_linkage = dll_linkage)
        modifiers = code.build_function_modifiers(entry.func_modifiers)
        code.putln("%s %s%s; /*proto*/" % (
            storage_class,
            modifiers,
            header))

#------------------------------------------------------------------------------------
#
#  Runtime support code
#
#------------------------------------------------------------------------------------

streq_utility_code = UtilityCode(
proto = """
static CYTHON_INLINE int __Pyx_StrEq(const char *, const char *); /*proto*/
""",
impl = """
static CYTHON_INLINE int __Pyx_StrEq(const char *s1, const char *s2) {
     while (*s1 != '\\0' && *s1 == *s2) { s1++; s2++; }
     return *s1 == *s2;
}
""")

#------------------------------------------------------------------------------------

import_star_utility_code = """

/* import_all_from is an unexposed function from ceval.c */

static int
__Pyx_import_all_from(PyObject *locals, PyObject *v)
{
    PyObject *all = __Pyx_GetAttrString(v, "__all__");
    PyObject *dict, *name, *value;
    int skip_leading_underscores = 0;
    int pos, err;

    if (all == NULL) {
        if (!PyErr_ExceptionMatches(PyExc_AttributeError))
            return -1; /* Unexpected error */
        PyErr_Clear();
        dict = __Pyx_GetAttrString(v, "__dict__");
        if (dict == NULL) {
            if (!PyErr_ExceptionMatches(PyExc_AttributeError))
                return -1;
            PyErr_SetString(PyExc_ImportError,
            "from-import-* object has no __dict__ and no __all__");
            return -1;
        }
#if PY_MAJOR_VERSION < 3
        all = PyObject_CallMethod(dict, (char *)"keys", NULL);
#else
        all = PyMapping_Keys(dict);
#endif
        Py_DECREF(dict);
        if (all == NULL)
            return -1;
        skip_leading_underscores = 1;
    }

    for (pos = 0, err = 0; ; pos++) {
        name = PySequence_GetItem(all, pos);
        if (name == NULL) {
            if (!PyErr_ExceptionMatches(PyExc_IndexError))
                err = -1;
            else
                PyErr_Clear();
            break;
        }
        if (skip_leading_underscores &&
#if PY_MAJOR_VERSION < 3
            PyString_Check(name) &&
            PyString_AS_STRING(name)[0] == '_')
#else
            PyUnicode_Check(name) &&
            PyUnicode_AS_UNICODE(name)[0] == '_')
#endif
        {
            Py_DECREF(name);
            continue;
        }
        value = PyObject_GetAttr(v, name);
        if (value == NULL)
            err = -1;
        else if (PyDict_CheckExact(locals))
            err = PyDict_SetItem(locals, name, value);
        else
            err = PyObject_SetItem(locals, name, value);
        Py_DECREF(name);
        Py_XDECREF(value);
        if (err != 0)
            break;
    }
    Py_DECREF(all);
    return err;
}


static int %(IMPORT_STAR)s(PyObject* m) {

    int i;
    int ret = -1;
    char* s;
    PyObject *locals = 0;
    PyObject *list = 0;
#if PY_MAJOR_VERSION >= 3
    PyObject *utf8_name = 0;
#endif
    PyObject *name;
    PyObject *item;

    locals = PyDict_New();              if (!locals) goto bad;
    if (__Pyx_import_all_from(locals, m) < 0) goto bad;
    list = PyDict_Items(locals);        if (!list) goto bad;

    for(i=0; i<PyList_GET_SIZE(list); i++) {
        name = PyTuple_GET_ITEM(PyList_GET_ITEM(list, i), 0);
        item = PyTuple_GET_ITEM(PyList_GET_ITEM(list, i), 1);
#if PY_MAJOR_VERSION >= 3
        utf8_name = PyUnicode_AsUTF8String(name);
        if (!utf8_name) goto bad;
        s = PyBytes_AS_STRING(utf8_name);
        if (%(IMPORT_STAR_SET)s(item, name, s) < 0) goto bad;
        Py_DECREF(utf8_name); utf8_name = 0;
#else
        s = PyString_AsString(name);
        if (!s) goto bad;
        if (%(IMPORT_STAR_SET)s(item, name, s) < 0) goto bad;
#endif
    }
    ret = 0;

bad:
    Py_XDECREF(locals);
    Py_XDECREF(list);
#if PY_MAJOR_VERSION >= 3
    Py_XDECREF(utf8_name);
#endif
    return ret;
}
""" % {'IMPORT_STAR'     : Naming.import_star,
       'IMPORT_STAR_SET' : Naming.import_star_set }

refnanny_utility_code = UtilityCode.load_cached("Refnanny", "ModuleSetupCode.c")

main_method = UtilityCode.load("MainFunction", "Embed.c")

packed_struct_utility_code = UtilityCode(proto="""
#if defined(__GNUC__)
#define __Pyx_PACKED __attribute__((__packed__))
#else
#define __Pyx_PACKED
#endif
""", impl="", proto_block='utility_code_proto_before_types')

capsule_utility_code = UtilityCode.load("Capsule")
