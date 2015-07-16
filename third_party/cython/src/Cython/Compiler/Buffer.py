from Cython.Compiler.Visitor import CythonTransform
from Cython.Compiler.ModuleNode import ModuleNode
from Cython.Compiler.Errors import CompileError
from Cython.Compiler.UtilityCode import CythonUtilityCode
from Cython.Compiler.Code import UtilityCode, TempitaUtilityCode

from Cython.Compiler import Options
from Cython.Compiler import Interpreter
from Cython.Compiler import PyrexTypes
from Cython.Compiler import Naming
from Cython.Compiler import Symtab


def dedent(text, reindent=0):
    from textwrap import dedent
    text = dedent(text)
    if reindent > 0:
        indent = " " * reindent
        text = '\n'.join([indent + x for x in text.split('\n')])
    return text

class IntroduceBufferAuxiliaryVars(CythonTransform):

    #
    # Entry point
    #

    buffers_exists = False
    using_memoryview = False

    def __call__(self, node):
        assert isinstance(node, ModuleNode)
        self.max_ndim = 0
        result = super(IntroduceBufferAuxiliaryVars, self).__call__(node)
        if self.buffers_exists:
            use_bufstruct_declare_code(node.scope)
            use_py2_buffer_functions(node.scope)
            node.scope.use_utility_code(empty_bufstruct_utility)

        return result


    #
    # Basic operations for transforms
    #
    def handle_scope(self, node, scope):
        # For all buffers, insert extra variables in the scope.
        # The variables are also accessible from the buffer_info
        # on the buffer entry
        bufvars = [entry for name, entry
                   in scope.entries.iteritems()
                   if entry.type.is_buffer]
        if len(bufvars) > 0:
            bufvars.sort(key=lambda entry: entry.name)
            self.buffers_exists = True

        memviewslicevars = [entry for name, entry
                in scope.entries.iteritems()
                if entry.type.is_memoryviewslice]
        if len(memviewslicevars) > 0:
            self.buffers_exists = True


        for (name, entry) in scope.entries.iteritems():
            if name == 'memoryview' and isinstance(entry.utility_code_definition, CythonUtilityCode):
                self.using_memoryview = True
                break


        if isinstance(node, ModuleNode) and len(bufvars) > 0:
            # for now...note that pos is wrong
            raise CompileError(node.pos, "Buffer vars not allowed in module scope")
        for entry in bufvars:
            if entry.type.dtype.is_ptr:
                raise CompileError(node.pos, "Buffers with pointer types not yet supported.")

            name = entry.name
            buftype = entry.type
            if buftype.ndim > Options.buffer_max_dims:
                raise CompileError(node.pos,
                        "Buffer ndims exceeds Options.buffer_max_dims = %d" % Options.buffer_max_dims)
            if buftype.ndim > self.max_ndim:
                self.max_ndim = buftype.ndim

            # Declare auxiliary vars
            def decvar(type, prefix):
                cname = scope.mangle(prefix, name)
                aux_var = scope.declare_var(name=None, cname=cname,
                                            type=type, pos=node.pos)
                if entry.is_arg:
                    aux_var.used = True # otherwise, NameNode will mark whether it is used

                return aux_var

            auxvars = ((PyrexTypes.c_pyx_buffer_nd_type, Naming.pybuffernd_prefix),
                       (PyrexTypes.c_pyx_buffer_type, Naming.pybufferstruct_prefix))
            pybuffernd, rcbuffer = [decvar(type, prefix) for (type, prefix) in auxvars]

            entry.buffer_aux = Symtab.BufferAux(pybuffernd, rcbuffer)

        scope.buffer_entries = bufvars
        self.scope = scope

    def visit_ModuleNode(self, node):
        self.handle_scope(node, node.scope)
        self.visitchildren(node)
        return node

    def visit_FuncDefNode(self, node):
        self.handle_scope(node, node.local_scope)
        self.visitchildren(node)
        return node

#
# Analysis
#
buffer_options = ("dtype", "ndim", "mode", "negative_indices", "cast") # ordered!
buffer_defaults = {"ndim": 1, "mode": "full", "negative_indices": True, "cast": False}
buffer_positional_options_count = 1 # anything beyond this needs keyword argument

ERR_BUF_OPTION_UNKNOWN = '"%s" is not a buffer option'
ERR_BUF_TOO_MANY = 'Too many buffer options'
ERR_BUF_DUP = '"%s" buffer option already supplied'
ERR_BUF_MISSING = '"%s" missing'
ERR_BUF_MODE = 'Only allowed buffer modes are: "c", "fortran", "full", "strided" (as a compile-time string)'
ERR_BUF_NDIM = 'ndim must be a non-negative integer'
ERR_BUF_DTYPE = 'dtype must be "object", numeric type or a struct'
ERR_BUF_BOOL = '"%s" must be a boolean'

def analyse_buffer_options(globalpos, env, posargs, dictargs, defaults=None, need_complete=True):
    """
    Must be called during type analysis, as analyse is called
    on the dtype argument.

    posargs and dictargs should consist of a list and a dict
    of tuples (value, pos). Defaults should be a dict of values.

    Returns a dict containing all the options a buffer can have and
    its value (with the positions stripped).
    """
    if defaults is None:
        defaults = buffer_defaults

    posargs, dictargs = Interpreter.interpret_compiletime_options(posargs, dictargs, type_env=env, type_args = (0,'dtype'))

    if len(posargs) > buffer_positional_options_count:
        raise CompileError(posargs[-1][1], ERR_BUF_TOO_MANY)

    options = {}
    for name, (value, pos) in dictargs.iteritems():
        if not name in buffer_options:
            raise CompileError(pos, ERR_BUF_OPTION_UNKNOWN % name)
        options[name] = value

    for name, (value, pos) in zip(buffer_options, posargs):
        if not name in buffer_options:
            raise CompileError(pos, ERR_BUF_OPTION_UNKNOWN % name)
        if name in options:
            raise CompileError(pos, ERR_BUF_DUP % name)
        options[name] = value

    # Check that they are all there and copy defaults
    for name in buffer_options:
        if not name in options:
            try:
                options[name] = defaults[name]
            except KeyError:
                if need_complete:
                    raise CompileError(globalpos, ERR_BUF_MISSING % name)

    dtype = options.get("dtype")
    if dtype and dtype.is_extension_type:
        raise CompileError(globalpos, ERR_BUF_DTYPE)

    ndim = options.get("ndim")
    if ndim and (not isinstance(ndim, int) or ndim < 0):
        raise CompileError(globalpos, ERR_BUF_NDIM)

    mode = options.get("mode")
    if mode and not (mode in ('full', 'strided', 'c', 'fortran')):
        raise CompileError(globalpos, ERR_BUF_MODE)

    def assert_bool(name):
        x = options.get(name)
        if not isinstance(x, bool):
            raise CompileError(globalpos, ERR_BUF_BOOL % name)

    assert_bool('negative_indices')
    assert_bool('cast')

    return options


#
# Code generation
#

class BufferEntry(object):
    def __init__(self, entry):
        self.entry = entry
        self.type = entry.type
        self.cname = entry.buffer_aux.buflocal_nd_var.cname
        self.buf_ptr = "%s.rcbuffer->pybuffer.buf" % self.cname
        self.buf_ptr_type = self.entry.type.buffer_ptr_type

    def get_buf_suboffsetvars(self):
        return self._for_all_ndim("%s.diminfo[%d].suboffsets")

    def get_buf_stridevars(self):
        return self._for_all_ndim("%s.diminfo[%d].strides")

    def get_buf_shapevars(self):
        return self._for_all_ndim("%s.diminfo[%d].shape")

    def _for_all_ndim(self, s):
        return [s % (self.cname, i) for i in range(self.type.ndim)]

    def generate_buffer_lookup_code(self, code, index_cnames):
        # Create buffer lookup and return it
        # This is done via utility macros/inline functions, which vary
        # according to the access mode used.
        params = []
        nd = self.type.ndim
        mode = self.type.mode
        if mode == 'full':
            for i, s, o in zip(index_cnames,
                               self.get_buf_stridevars(),
                               self.get_buf_suboffsetvars()):
                params.append(i)
                params.append(s)
                params.append(o)
            funcname = "__Pyx_BufPtrFull%dd" % nd
            funcgen = buf_lookup_full_code
        else:
            if mode == 'strided':
                funcname = "__Pyx_BufPtrStrided%dd" % nd
                funcgen = buf_lookup_strided_code
            elif mode == 'c':
                funcname = "__Pyx_BufPtrCContig%dd" % nd
                funcgen = buf_lookup_c_code
            elif mode == 'fortran':
                funcname = "__Pyx_BufPtrFortranContig%dd" % nd
                funcgen = buf_lookup_fortran_code
            else:
                assert False
            for i, s in zip(index_cnames, self.get_buf_stridevars()):
                params.append(i)
                params.append(s)

        # Make sure the utility code is available
        if funcname not in code.globalstate.utility_codes:
            code.globalstate.utility_codes.add(funcname)
            protocode = code.globalstate['utility_code_proto']
            defcode = code.globalstate['utility_code_def']
            funcgen(protocode, defcode, name=funcname, nd=nd)

        buf_ptr_type_code = self.buf_ptr_type.declaration_code("")
        ptrcode = "%s(%s, %s, %s)" % (funcname, buf_ptr_type_code, self.buf_ptr,
                                      ", ".join(params))
        return ptrcode


def get_flags(buffer_aux, buffer_type):
    flags = 'PyBUF_FORMAT'
    mode = buffer_type.mode
    if mode == 'full':
        flags += '| PyBUF_INDIRECT'
    elif mode == 'strided':
        flags += '| PyBUF_STRIDES'
    elif mode == 'c':
        flags += '| PyBUF_C_CONTIGUOUS'
    elif mode == 'fortran':
        flags += '| PyBUF_F_CONTIGUOUS'
    else:
        assert False
    if buffer_aux.writable_needed: flags += "| PyBUF_WRITABLE"
    return flags

def used_buffer_aux_vars(entry):
    buffer_aux = entry.buffer_aux
    buffer_aux.buflocal_nd_var.used = True
    buffer_aux.rcbuf_var.used = True

def put_unpack_buffer_aux_into_scope(buf_entry, code):
    # Generate code to copy the needed struct info into local
    # variables.
    buffer_aux, mode = buf_entry.buffer_aux, buf_entry.type.mode
    pybuffernd_struct = buffer_aux.buflocal_nd_var.cname

    fldnames = ['strides', 'shape']
    if mode == 'full':
        fldnames.append('suboffsets')

    ln = []
    for i in range(buf_entry.type.ndim):
        for fldname in fldnames:
            ln.append("%s.diminfo[%d].%s = %s.rcbuffer->pybuffer.%s[%d];" % \
                    (pybuffernd_struct, i, fldname,
                     pybuffernd_struct, fldname, i))
    code.putln(' '.join(ln))

def put_init_vars(entry, code):
    bufaux = entry.buffer_aux
    pybuffernd_struct = bufaux.buflocal_nd_var.cname
    pybuffer_struct = bufaux.rcbuf_var.cname
    # init pybuffer_struct
    code.putln("%s.pybuffer.buf = NULL;" % pybuffer_struct)
    code.putln("%s.refcount = 0;" % pybuffer_struct)
    # init the buffer object
    # code.put_init_var_to_py_none(entry)
    # init the pybuffernd_struct
    code.putln("%s.data = NULL;" % pybuffernd_struct)
    code.putln("%s.rcbuffer = &%s;" % (pybuffernd_struct, pybuffer_struct))

def put_acquire_arg_buffer(entry, code, pos):
    code.globalstate.use_utility_code(acquire_utility_code)
    buffer_aux = entry.buffer_aux
    getbuffer = get_getbuffer_call(code, entry.cname, buffer_aux, entry.type)

    # Acquire any new buffer
    code.putln("{")
    code.putln("__Pyx_BufFmt_StackElem __pyx_stack[%d];" % entry.type.dtype.struct_nesting_depth())
    code.putln(code.error_goto_if("%s == -1" % getbuffer, pos))
    code.putln("}")
    # An exception raised in arg parsing cannot be catched, so no
    # need to care about the buffer then.
    put_unpack_buffer_aux_into_scope(entry, code)

def put_release_buffer_code(code, entry):
    code.globalstate.use_utility_code(acquire_utility_code)
    code.putln("__Pyx_SafeReleaseBuffer(&%s.rcbuffer->pybuffer);" % entry.buffer_aux.buflocal_nd_var.cname)

def get_getbuffer_call(code, obj_cname, buffer_aux, buffer_type):
    ndim = buffer_type.ndim
    cast = int(buffer_type.cast)
    flags = get_flags(buffer_aux, buffer_type)
    pybuffernd_struct = buffer_aux.buflocal_nd_var.cname

    dtype_typeinfo = get_type_information_cname(code, buffer_type.dtype)

    return ("__Pyx_GetBufferAndValidate(&%(pybuffernd_struct)s.rcbuffer->pybuffer, "
            "(PyObject*)%(obj_cname)s, &%(dtype_typeinfo)s, %(flags)s, %(ndim)d, "
            "%(cast)d, __pyx_stack)" % locals())

def put_assign_to_buffer(lhs_cname, rhs_cname, buf_entry,
                         is_initialized, pos, code):
    """
    Generate code for reassigning a buffer variables. This only deals with getting
    the buffer auxiliary structure and variables set up correctly, the assignment
    itself and refcounting is the responsibility of the caller.

    However, the assignment operation may throw an exception so that the reassignment
    never happens.

    Depending on the circumstances there are two possible outcomes:
    - Old buffer released, new acquired, rhs assigned to lhs
    - Old buffer released, new acquired which fails, reaqcuire old lhs buffer
      (which may or may not succeed).
    """

    buffer_aux, buffer_type = buf_entry.buffer_aux, buf_entry.type
    code.globalstate.use_utility_code(acquire_utility_code)
    pybuffernd_struct = buffer_aux.buflocal_nd_var.cname
    flags = get_flags(buffer_aux, buffer_type)

    code.putln("{")  # Set up necesarry stack for getbuffer
    code.putln("__Pyx_BufFmt_StackElem __pyx_stack[%d];" % buffer_type.dtype.struct_nesting_depth())

    getbuffer = get_getbuffer_call(code, "%s", buffer_aux, buffer_type) # fill in object below

    if is_initialized:
        # Release any existing buffer
        code.putln('__Pyx_SafeReleaseBuffer(&%s.rcbuffer->pybuffer);' % pybuffernd_struct)
        # Acquire
        retcode_cname = code.funcstate.allocate_temp(PyrexTypes.c_int_type, manage_ref=False)
        code.putln("%s = %s;" % (retcode_cname, getbuffer % rhs_cname))
        code.putln('if (%s) {' % (code.unlikely("%s < 0" % retcode_cname)))
        # If acquisition failed, attempt to reacquire the old buffer
        # before raising the exception. A failure of reacquisition
        # will cause the reacquisition exception to be reported, one
        # can consider working around this later.
        type, value, tb = [code.funcstate.allocate_temp(PyrexTypes.py_object_type, manage_ref=False)
                           for i in range(3)]
        code.putln('PyErr_Fetch(&%s, &%s, &%s);' % (type, value, tb))
        code.putln('if (%s) {' % code.unlikely("%s == -1" % (getbuffer % lhs_cname)))
        code.putln('Py_XDECREF(%s); Py_XDECREF(%s); Py_XDECREF(%s);' % (type, value, tb)) # Do not refnanny these!
        code.globalstate.use_utility_code(raise_buffer_fallback_code)
        code.putln('__Pyx_RaiseBufferFallbackError();')
        code.putln('} else {')
        code.putln('PyErr_Restore(%s, %s, %s);' % (type, value, tb))
        for t in (type, value, tb):
            code.funcstate.release_temp(t)
        code.putln('}')
        code.putln('}')
        # Unpack indices
        put_unpack_buffer_aux_into_scope(buf_entry, code)
        code.putln(code.error_goto_if_neg(retcode_cname, pos))
        code.funcstate.release_temp(retcode_cname)
    else:
        # Our entry had no previous value, so set to None when acquisition fails.
        # In this case, auxiliary vars should be set up right in initialization to a zero-buffer,
        # so it suffices to set the buf field to NULL.
        code.putln('if (%s) {' % code.unlikely("%s == -1" % (getbuffer % rhs_cname)))
        code.putln('%s = %s; __Pyx_INCREF(Py_None); %s.rcbuffer->pybuffer.buf = NULL;' %
                   (lhs_cname,
                    PyrexTypes.typecast(buffer_type, PyrexTypes.py_object_type, "Py_None"),
                    pybuffernd_struct))
        code.putln(code.error_goto(pos))
        code.put('} else {')
        # Unpack indices
        put_unpack_buffer_aux_into_scope(buf_entry, code)
        code.putln('}')

    code.putln("}") # Release stack

def put_buffer_lookup_code(entry, index_signeds, index_cnames, directives,
                           pos, code, negative_indices, in_nogil_context):
    """
    Generates code to process indices and calculate an offset into
    a buffer. Returns a C string which gives a pointer which can be
    read from or written to at will (it is an expression so caller should
    store it in a temporary if it is used more than once).

    As the bounds checking can have any number of combinations of unsigned
    arguments, smart optimizations etc. we insert it directly in the function
    body. The lookup however is delegated to a inline function that is instantiated
    once per ndim (lookup with suboffsets tend to get quite complicated).

    entry is a BufferEntry
    """
    negative_indices = directives['wraparound'] and negative_indices

    if directives['boundscheck']:
        # Check bounds and fix negative indices.
        # We allocate a temporary which is initialized to -1, meaning OK (!).
        # If an error occurs, the temp is set to the dimension index the
        # error is occuring at.
        tmp_cname = code.funcstate.allocate_temp(PyrexTypes.c_int_type, manage_ref=False)
        code.putln("%s = -1;" % tmp_cname)
        for dim, (signed, cname, shape) in enumerate(zip(index_signeds, index_cnames,
                                                         entry.get_buf_shapevars())):
            if signed != 0:
                # not unsigned, deal with negative index
                code.putln("if (%s < 0) {" % cname)
                if negative_indices:
                    code.putln("%s += %s;" % (cname, shape))
                    code.putln("if (%s) %s = %d;" % (
                        code.unlikely("%s < 0" % cname), tmp_cname, dim))
                else:
                    code.putln("%s = %d;" % (tmp_cname, dim))
                code.put("} else ")
            # check bounds in positive direction
            if signed != 0:
                cast = ""
            else:
                cast = "(size_t)"
            code.putln("if (%s) %s = %d;" % (
                code.unlikely("%s >= %s%s" % (cname, cast, shape)),
                              tmp_cname, dim))

        if in_nogil_context:
            code.globalstate.use_utility_code(raise_indexerror_nogil)
            func = '__Pyx_RaiseBufferIndexErrorNogil'
        else:
            code.globalstate.use_utility_code(raise_indexerror_code)
            func = '__Pyx_RaiseBufferIndexError'

        code.putln("if (%s) {" % code.unlikely("%s != -1" % tmp_cname))
        code.putln('%s(%s);' % (func, tmp_cname))
        code.putln(code.error_goto(pos))
        code.putln('}')
        code.funcstate.release_temp(tmp_cname)
    elif negative_indices:
        # Only fix negative indices.
        for signed, cname, shape in zip(index_signeds, index_cnames,
                                        entry.get_buf_shapevars()):
            if signed != 0:
                code.putln("if (%s < 0) %s += %s;" % (cname, cname, shape))

    return entry.generate_buffer_lookup_code(code, index_cnames)


def use_bufstruct_declare_code(env):
    env.use_utility_code(buffer_struct_declare_code)


def get_empty_bufstruct_code(max_ndim):
    code = dedent("""
        static Py_ssize_t __Pyx_zeros[] = {%s};
        static Py_ssize_t __Pyx_minusones[] = {%s};
    """) % (", ".join(["0"] * max_ndim), ", ".join(["-1"] * max_ndim))
    return UtilityCode(proto=code)

empty_bufstruct_utility = get_empty_bufstruct_code(Options.buffer_max_dims)

def buf_lookup_full_code(proto, defin, name, nd):
    """
    Generates a buffer lookup function for the right number
    of dimensions. The function gives back a void* at the right location.
    """
    # _i_ndex, _s_tride, sub_o_ffset
    macroargs = ", ".join(["i%d, s%d, o%d" % (i, i, i) for i in range(nd)])
    proto.putln("#define %s(type, buf, %s) (type)(%s_imp(buf, %s))" % (name, macroargs, name, macroargs))

    funcargs = ", ".join(["Py_ssize_t i%d, Py_ssize_t s%d, Py_ssize_t o%d" % (i, i, i) for i in range(nd)])
    proto.putln("static CYTHON_INLINE void* %s_imp(void* buf, %s);" % (name, funcargs))
    defin.putln(dedent("""
        static CYTHON_INLINE void* %s_imp(void* buf, %s) {
          char* ptr = (char*)buf;
        """) % (name, funcargs) + "".join([dedent("""\
          ptr += s%d * i%d;
          if (o%d >= 0) ptr = *((char**)ptr) + o%d;
        """) % (i, i, i, i) for i in range(nd)]
        ) + "\nreturn ptr;\n}")

def buf_lookup_strided_code(proto, defin, name, nd):
    """
    Generates a buffer lookup function for the right number
    of dimensions. The function gives back a void* at the right location.
    """
    # _i_ndex, _s_tride
    args = ", ".join(["i%d, s%d" % (i, i) for i in range(nd)])
    offset = " + ".join(["i%d * s%d" % (i, i) for i in range(nd)])
    proto.putln("#define %s(type, buf, %s) (type)((char*)buf + %s)" % (name, args, offset))

def buf_lookup_c_code(proto, defin, name, nd):
    """
    Similar to strided lookup, but can assume that the last dimension
    doesn't need a multiplication as long as.
    Still we keep the same signature for now.
    """
    if nd == 1:
        proto.putln("#define %s(type, buf, i0, s0) ((type)buf + i0)" % name)
    else:
        args = ", ".join(["i%d, s%d" % (i, i) for i in range(nd)])
        offset = " + ".join(["i%d * s%d" % (i, i) for i in range(nd - 1)])
        proto.putln("#define %s(type, buf, %s) ((type)((char*)buf + %s) + i%d)" % (name, args, offset, nd - 1))

def buf_lookup_fortran_code(proto, defin, name, nd):
    """
    Like C lookup, but the first index is optimized instead.
    """
    if nd == 1:
        proto.putln("#define %s(type, buf, i0, s0) ((type)buf + i0)" % name)
    else:
        args = ", ".join(["i%d, s%d" % (i, i) for i in range(nd)])
        offset = " + ".join(["i%d * s%d" % (i, i) for i in range(1, nd)])
        proto.putln("#define %s(type, buf, %s) ((type)((char*)buf + %s) + i%d)" % (name, args, offset, 0))


def use_py2_buffer_functions(env):
    env.use_utility_code(GetAndReleaseBufferUtilityCode())

class GetAndReleaseBufferUtilityCode(object):
    # Emulation of PyObject_GetBuffer and PyBuffer_Release for Python 2.
    # For >= 2.6 we do double mode -- use the new buffer interface on objects
    # which has the right tp_flags set, but emulation otherwise.

    requires = None
    is_cython_utility = False

    def __init__(self):
        pass

    def __eq__(self, other):
        return isinstance(other, GetAndReleaseBufferUtilityCode)

    def __hash__(self):
        return 24342342

    def get_tree(self): pass

    def put_code(self, output):
        code = output['utility_code_def']
        proto_code = output['utility_code_proto']
        env = output.module_node.scope
        cython_scope = env.context.cython_scope
        
        # Search all types for __getbuffer__ overloads
        types = []
        visited_scopes = set()
        def find_buffer_types(scope):
            if scope in visited_scopes:
                return
            visited_scopes.add(scope)
            for m in scope.cimported_modules:
                find_buffer_types(m)
            for e in scope.type_entries:
                if isinstance(e.utility_code_definition, CythonUtilityCode):
                    continue
                t = e.type
                if t.is_extension_type:
                    if scope is cython_scope and not e.used:
                        continue
                    release = get = None
                    for x in t.scope.pyfunc_entries:
                        if x.name == u"__getbuffer__": get = x.func_cname
                        elif x.name == u"__releasebuffer__": release = x.func_cname
                    if get:
                        types.append((t.typeptr_cname, get, release))

        find_buffer_types(env)

        util_code = TempitaUtilityCode.load(
            "GetAndReleaseBuffer", from_file="Buffer.c",
            context=dict(types=types))

        proto = util_code.format_code(util_code.proto)
        impl = util_code.format_code(
            util_code.inject_string_constants(util_code.impl, output)[1])

        proto_code.putln(proto)
        code.putln(impl)


def mangle_dtype_name(dtype):
    # Use prefixes to seperate user defined types from builtins
    # (consider "typedef float unsigned_int")
    if dtype.is_pyobject:
        return "object"
    elif dtype.is_ptr:
        return "ptr"
    else:
        if dtype.is_typedef or dtype.is_struct_or_union:
            prefix = "nn_"
        else:
            prefix = ""
        type_decl = dtype.declaration_code("")
        type_decl = type_decl.replace(" ", "_")
        return prefix + type_decl.replace("[", "_").replace("]", "_")

def get_type_information_cname(code, dtype, maxdepth=None):
    """
    Output the run-time type information (__Pyx_TypeInfo) for given dtype,
    and return the name of the type info struct.

    Structs with two floats of the same size are encoded as complex numbers.
    One can seperate between complex numbers declared as struct or with native
    encoding by inspecting to see if the fields field of the type is
    filled in.
    """
    namesuffix = mangle_dtype_name(dtype)
    name = "__Pyx_TypeInfo_%s" % namesuffix
    structinfo_name = "__Pyx_StructFields_%s" % namesuffix

    if dtype.is_error: return "<error>"

    # It's critical that walking the type info doesn't use more stack
    # depth than dtype.struct_nesting_depth() returns, so use an assertion for this
    if maxdepth is None: maxdepth = dtype.struct_nesting_depth()
    if maxdepth <= 0:
        assert False

    if name not in code.globalstate.utility_codes:
        code.globalstate.utility_codes.add(name)
        typecode = code.globalstate['typeinfo']

        arraysizes = []
        if dtype.is_array:
            while dtype.is_array:
                arraysizes.append(dtype.size)
                dtype = dtype.base_type

        complex_possible = dtype.is_struct_or_union and dtype.can_be_complex()

        declcode = dtype.declaration_code("")
        if dtype.is_simple_buffer_dtype():
            structinfo_name = "NULL"
        elif dtype.is_struct:
            fields = dtype.scope.var_entries
            # Must pre-call all used types in order not to recurse utility code
            # writing.
            assert len(fields) > 0
            types = [get_type_information_cname(code, f.type, maxdepth - 1)
                     for f in fields]
            typecode.putln("static __Pyx_StructField %s[] = {" % structinfo_name, safe=True)
            for f, typeinfo in zip(fields, types):
                typecode.putln('  {&%s, "%s", offsetof(%s, %s)},' %
                           (typeinfo, f.name, dtype.declaration_code(""), f.cname), safe=True)
            typecode.putln('  {NULL, NULL, 0}', safe=True)
            typecode.putln("};", safe=True)
        else:
            assert False

        rep = str(dtype)

        flags = "0"
        is_unsigned = "0"
        if dtype is PyrexTypes.c_char_type:
            is_unsigned = "IS_UNSIGNED(%s)" % declcode
            typegroup = "'H'"
        elif dtype.is_int:
            is_unsigned = "IS_UNSIGNED(%s)" % declcode
            typegroup = "%s ? 'U' : 'I'" % is_unsigned
        elif complex_possible or dtype.is_complex:
            typegroup = "'C'"
        elif dtype.is_float:
            typegroup = "'R'"
        elif dtype.is_struct:
            typegroup = "'S'"
            if dtype.packed:
                flags = "__PYX_BUF_FLAGS_PACKED_STRUCT"
        elif dtype.is_pyobject:
            typegroup = "'O'"
        else:
            assert False, dtype

        typeinfo = ('static __Pyx_TypeInfo %s = '
                        '{ "%s", %s, sizeof(%s), { %s }, %s, %s, %s, %s };')
        tup = (name, rep, structinfo_name, declcode,
               ', '.join([str(x) for x in arraysizes]) or '0', len(arraysizes),
               typegroup, is_unsigned, flags)
        typecode.putln(typeinfo % tup, safe=True)

    return name

def load_buffer_utility(util_code_name, context=None, **kwargs):
    if context is None:
        return UtilityCode.load(util_code_name, "Buffer.c", **kwargs)
    else:
        return TempitaUtilityCode.load(util_code_name, "Buffer.c", context=context, **kwargs)

context = dict(max_dims=str(Options.buffer_max_dims))
buffer_struct_declare_code = load_buffer_utility("BufferStructDeclare",
                                                 context=context)


# Utility function to set the right exception
# The caller should immediately goto_error
raise_indexerror_code = load_buffer_utility("BufferIndexError")
raise_indexerror_nogil = load_buffer_utility("BufferIndexErrorNogil")

raise_buffer_fallback_code = load_buffer_utility("BufferFallbackError")
buffer_structs_code = load_buffer_utility(
        "BufferFormatStructs", proto_block='utility_code_proto_before_types')
acquire_utility_code = load_buffer_utility("BufferFormatCheck",
                                           context=context,
                                           requires=[buffer_structs_code])

# See utility code BufferFormatFromTypeInfo
_typeinfo_to_format_code = load_buffer_utility("TypeInfoToFormat", context={},
                                               requires=[buffer_structs_code])
typeinfo_compare_code = load_buffer_utility("TypeInfoCompare", context={},
                                            requires=[buffer_structs_code])
