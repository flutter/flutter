#
#   C naming conventions
#
#
#   Prefixes for generating C names.
#   Collected here to facilitate ensuring uniqueness.
#

pyrex_prefix    = "__pyx_"


codewriter_temp_prefix = pyrex_prefix + "t_"

temp_prefix       = u"__cyt_"

builtin_prefix    = pyrex_prefix + "builtin_"
arg_prefix        = pyrex_prefix + "arg_"
funcdoc_prefix    = pyrex_prefix + "doc_"
enum_prefix       = pyrex_prefix + "e_"
func_prefix       = pyrex_prefix + "f_"
pyfunc_prefix     = pyrex_prefix + "pf_"
pywrap_prefix     = pyrex_prefix + "pw_"
genbody_prefix    = pyrex_prefix + "gb_"
gstab_prefix      = pyrex_prefix + "getsets_"
prop_get_prefix   = pyrex_prefix + "getprop_"
const_prefix      = pyrex_prefix + "k_"
py_const_prefix   = pyrex_prefix + "kp_"
label_prefix      = pyrex_prefix + "L"
pymethdef_prefix  = pyrex_prefix + "mdef_"
methtab_prefix    = pyrex_prefix + "methods_"
memtab_prefix     = pyrex_prefix + "members_"
objstruct_prefix  = pyrex_prefix + "obj_"
typeptr_prefix    = pyrex_prefix + "ptype_"
prop_set_prefix   = pyrex_prefix + "setprop_"
type_prefix       = pyrex_prefix + "t_"
typeobj_prefix    = pyrex_prefix + "type_"
var_prefix        = pyrex_prefix + "v_"
varptr_prefix     = pyrex_prefix + "vp_"
wrapperbase_prefix= pyrex_prefix + "wrapperbase_"
pybuffernd_prefix   = pyrex_prefix + "pybuffernd_"
pybufferstruct_prefix  = pyrex_prefix + "pybuffer_"
vtable_prefix     = pyrex_prefix + "vtable_"
vtabptr_prefix    = pyrex_prefix + "vtabptr_"
vtabstruct_prefix = pyrex_prefix + "vtabstruct_"
opt_arg_prefix    = pyrex_prefix + "opt_args_"
convert_func_prefix = pyrex_prefix + "convert_"
closure_scope_prefix = pyrex_prefix + "scope_"
closure_class_prefix = pyrex_prefix + "scope_struct_"
lambda_func_prefix = pyrex_prefix + "lambda_"
module_is_main   = pyrex_prefix + "module_is_main_"
defaults_struct_prefix = pyrex_prefix + "defaults"
dynamic_args_cname = pyrex_prefix + "dynamic_args"

interned_prefixes = {
    'str': pyrex_prefix + "n_",
    'int': pyrex_prefix + "int_",
    'float': pyrex_prefix + "float_",
    'tuple': pyrex_prefix + "tuple_",
    'codeobj': pyrex_prefix + "codeobj_",
    'slice': pyrex_prefix + "slice_",
    'ustring': pyrex_prefix + "ustring_",
}

args_cname       = pyrex_prefix + "args"
generator_cname  = pyrex_prefix + "generator"
sent_value_cname = pyrex_prefix + "sent_value"
pykwdlist_cname  = pyrex_prefix + "pyargnames"
obj_base_cname   = pyrex_prefix + "base"
builtins_cname   = pyrex_prefix + "b"
preimport_cname  = pyrex_prefix + "i"
moddict_cname    = pyrex_prefix + "d"
dummy_cname      = pyrex_prefix + "dummy"
filename_cname   = pyrex_prefix + "filename"
modulename_cname = pyrex_prefix + "modulename"
filetable_cname  = pyrex_prefix + "f"
intern_tab_cname = pyrex_prefix + "intern_tab"
kwds_cname       = pyrex_prefix + "kwds"
lineno_cname     = pyrex_prefix + "lineno"
clineno_cname    = pyrex_prefix + "clineno"
cfilenm_cname    = pyrex_prefix + "cfilenm"
module_cname     = pyrex_prefix + "m"
moddoc_cname     = pyrex_prefix + "mdoc"
methtable_cname  = pyrex_prefix + "methods"
retval_cname     = pyrex_prefix + "r"
reqd_kwds_cname  = pyrex_prefix + "reqd_kwds"
self_cname       = pyrex_prefix + "self"
stringtab_cname  = pyrex_prefix + "string_tab"
vtabslot_cname   = pyrex_prefix + "vtab"
c_api_tab_cname  = pyrex_prefix + "c_api_tab"
gilstate_cname   = pyrex_prefix + "state"
skip_dispatch_cname = pyrex_prefix + "skip_dispatch"
empty_tuple      = pyrex_prefix + "empty_tuple"
empty_bytes      = pyrex_prefix + "empty_bytes"
print_function   = pyrex_prefix + "print"
print_function_kwargs   = pyrex_prefix + "print_kwargs"
cleanup_cname    = pyrex_prefix + "module_cleanup"
pymoduledef_cname = pyrex_prefix + "moduledef"
optional_args_cname = pyrex_prefix + "optional_args"
import_star      = pyrex_prefix + "import_star"
import_star_set  = pyrex_prefix + "import_star_set"
outer_scope_cname= pyrex_prefix + "outer_scope"
cur_scope_cname  = pyrex_prefix + "cur_scope"
enc_scope_cname  = pyrex_prefix + "enc_scope"
frame_cname      = pyrex_prefix + "frame"
frame_code_cname = pyrex_prefix + "frame_code"
binding_cfunc    = pyrex_prefix + "binding_PyCFunctionType"
fused_func_prefix = pyrex_prefix + 'fuse_'
quick_temp_cname = pyrex_prefix + "temp" # temp variable for quick'n'dirty temping

global_code_object_cache_find = pyrex_prefix + 'find_code_object'
global_code_object_cache_insert = pyrex_prefix + 'insert_code_object'

genexpr_id_ref = 'genexpr'
freelist_name  = 'freelist'
freecount_name = 'freecount'

line_c_macro = "__LINE__"

file_c_macro = "__FILE__"

extern_c_macro  = pyrex_prefix.upper() + "EXTERN_C"

exc_type_name   = pyrex_prefix + "exc_type"
exc_value_name  = pyrex_prefix + "exc_value"
exc_tb_name     = pyrex_prefix + "exc_tb"
exc_lineno_name = pyrex_prefix + "exc_lineno"

parallel_exc_type = pyrex_prefix + "parallel_exc_type"
parallel_exc_value = pyrex_prefix + "parallel_exc_value"
parallel_exc_tb = pyrex_prefix + "parallel_exc_tb"
parallel_filename = pyrex_prefix + "parallel_filename"
parallel_lineno = pyrex_prefix + "parallel_lineno"
parallel_clineno = pyrex_prefix + "parallel_clineno"
parallel_why = pyrex_prefix + "parallel_why"

exc_vars = (exc_type_name, exc_value_name, exc_tb_name)

api_name        = pyrex_prefix + "capi__"

h_guard_prefix   = "__PYX_HAVE__"
api_guard_prefix = "__PYX_HAVE_API__"
api_func_guard   = "__PYX_HAVE_API_FUNC_"

PYX_NAN          = "__PYX_NAN()"

def py_version_hex(major, minor=0, micro=0, release_level=0, release_serial=0):
    return (major << 24) | (minor << 16) | (micro << 8) | (release_level << 4) | (release_serial)
