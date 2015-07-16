

//////////////////// CythonFunction.proto ////////////////////
#define __Pyx_CyFunction_USED 1
#include <structmember.h>

#define __Pyx_CYFUNCTION_STATICMETHOD  0x01
#define __Pyx_CYFUNCTION_CLASSMETHOD   0x02
#define __Pyx_CYFUNCTION_CCLASS        0x04

#define __Pyx_CyFunction_GetClosure(f) \
    (((__pyx_CyFunctionObject *) (f))->func_closure)
#define __Pyx_CyFunction_GetClassObj(f) \
    (((__pyx_CyFunctionObject *) (f))->func_classobj)

#define __Pyx_CyFunction_Defaults(type, f) \
    ((type *)(((__pyx_CyFunctionObject *) (f))->defaults))
#define __Pyx_CyFunction_SetDefaultsGetter(f, g) \
    ((__pyx_CyFunctionObject *) (f))->defaults_getter = (g)


typedef struct {
    PyCFunctionObject func;
    PyObject *func_dict;
    PyObject *func_weakreflist;
    PyObject *func_name;
    PyObject *func_qualname;
    PyObject *func_doc;
    PyObject *func_globals;
    PyObject *func_code;
    PyObject *func_closure;
    PyObject *func_classobj; /* No-args super() class cell */

    /* Dynamic default args and annotations */
    void *defaults;
    int defaults_pyobjects;
    int flags;

    /* Defaults info */
    PyObject *defaults_tuple;   /* Const defaults tuple */
    PyObject *defaults_kwdict;  /* Const kwonly defaults dict */
    PyObject *(*defaults_getter)(PyObject *);
    PyObject *func_annotations; /* function annotations dict */
} __pyx_CyFunctionObject;

static PyTypeObject *__pyx_CyFunctionType = 0;

#define __Pyx_CyFunction_NewEx(ml, flags, qualname, self, module, globals, code) \
    __Pyx_CyFunction_New(__pyx_CyFunctionType, ml, flags, qualname, self, module, globals, code)

static PyObject *__Pyx_CyFunction_New(PyTypeObject *, PyMethodDef *ml,
                                      int flags, PyObject* qualname,
                                      PyObject *self,
                                      PyObject *module, PyObject *globals,
                                      PyObject* code);

static CYTHON_INLINE void *__Pyx_CyFunction_InitDefaults(PyObject *m,
                                                         size_t size,
                                                         int pyobjects);
static CYTHON_INLINE void __Pyx_CyFunction_SetDefaultsTuple(PyObject *m,
                                                            PyObject *tuple);
static CYTHON_INLINE void __Pyx_CyFunction_SetDefaultsKwDict(PyObject *m,
                                                             PyObject *dict);
static CYTHON_INLINE void __Pyx_CyFunction_SetAnnotationsDict(PyObject *m,
                                                              PyObject *dict);


static int __Pyx_CyFunction_init(void);

//////////////////// CythonFunction ////////////////////
//@substitute: naming
//@requires: CommonTypes.c::FetchCommonType
////@requires: ObjectHandling.c::PyObjectGetAttrStr

static PyObject *
__Pyx_CyFunction_get_doc(__pyx_CyFunctionObject *op, CYTHON_UNUSED void *closure)
{
    if (unlikely(op->func_doc == NULL)) {
        if (op->func.m_ml->ml_doc) {
#if PY_MAJOR_VERSION >= 3
            op->func_doc = PyUnicode_FromString(op->func.m_ml->ml_doc);
#else
            op->func_doc = PyString_FromString(op->func.m_ml->ml_doc);
#endif
            if (unlikely(op->func_doc == NULL))
                return NULL;
        } else {
            Py_INCREF(Py_None);
            return Py_None;
        }
    }
    Py_INCREF(op->func_doc);
    return op->func_doc;
}

static int
__Pyx_CyFunction_set_doc(__pyx_CyFunctionObject *op, PyObject *value)
{
    PyObject *tmp = op->func_doc;
    if (value == NULL)
        value = Py_None; /* Mark as deleted */
    Py_INCREF(value);
    op->func_doc = value;
    Py_XDECREF(tmp);
    return 0;
}

static PyObject *
__Pyx_CyFunction_get_name(__pyx_CyFunctionObject *op)
{
    if (unlikely(op->func_name == NULL)) {
#if PY_MAJOR_VERSION >= 3
        op->func_name = PyUnicode_InternFromString(op->func.m_ml->ml_name);
#else
        op->func_name = PyString_InternFromString(op->func.m_ml->ml_name);
#endif
        if (unlikely(op->func_name == NULL))
            return NULL;
    }
    Py_INCREF(op->func_name);
    return op->func_name;
}

static int
__Pyx_CyFunction_set_name(__pyx_CyFunctionObject *op, PyObject *value)
{
    PyObject *tmp;

#if PY_MAJOR_VERSION >= 3
    if (unlikely(value == NULL || !PyUnicode_Check(value))) {
#else
    if (unlikely(value == NULL || !PyString_Check(value))) {
#endif
        PyErr_SetString(PyExc_TypeError,
                        "__name__ must be set to a string object");
        return -1;
    }
    tmp = op->func_name;
    Py_INCREF(value);
    op->func_name = value;
    Py_XDECREF(tmp);
    return 0;
}

static PyObject *
__Pyx_CyFunction_get_qualname(__pyx_CyFunctionObject *op)
{
    Py_INCREF(op->func_qualname);
    return op->func_qualname;
}

static int
__Pyx_CyFunction_set_qualname(__pyx_CyFunctionObject *op, PyObject *value)
{
    PyObject *tmp;

#if PY_MAJOR_VERSION >= 3
    if (unlikely(value == NULL || !PyUnicode_Check(value))) {
#else
    if (unlikely(value == NULL || !PyString_Check(value))) {
#endif
        PyErr_SetString(PyExc_TypeError,
                        "__qualname__ must be set to a string object");
        return -1;
    }
    tmp = op->func_qualname;
    Py_INCREF(value);
    op->func_qualname = value;
    Py_XDECREF(tmp);
    return 0;
}

static PyObject *
__Pyx_CyFunction_get_self(__pyx_CyFunctionObject *m, CYTHON_UNUSED void *closure)
{
    PyObject *self;

    self = m->func_closure;
    if (self == NULL)
        self = Py_None;
    Py_INCREF(self);
    return self;
}

static PyObject *
__Pyx_CyFunction_get_dict(__pyx_CyFunctionObject *op)
{
    if (unlikely(op->func_dict == NULL)) {
        op->func_dict = PyDict_New();
        if (unlikely(op->func_dict == NULL))
            return NULL;
    }
    Py_INCREF(op->func_dict);
    return op->func_dict;
}

static int
__Pyx_CyFunction_set_dict(__pyx_CyFunctionObject *op, PyObject *value)
{
    PyObject *tmp;

    if (unlikely(value == NULL)) {
        PyErr_SetString(PyExc_TypeError,
               "function's dictionary may not be deleted");
        return -1;
    }
    if (unlikely(!PyDict_Check(value))) {
        PyErr_SetString(PyExc_TypeError,
               "setting function's dictionary to a non-dict");
        return -1;
    }
    tmp = op->func_dict;
    Py_INCREF(value);
    op->func_dict = value;
    Py_XDECREF(tmp);
    return 0;
}

static PyObject *
__Pyx_CyFunction_get_globals(__pyx_CyFunctionObject *op)
{
    Py_INCREF(op->func_globals);
    return op->func_globals;
}

static PyObject *
__Pyx_CyFunction_get_closure(CYTHON_UNUSED __pyx_CyFunctionObject *op)
{
    Py_INCREF(Py_None);
    return Py_None;
}

static PyObject *
__Pyx_CyFunction_get_code(__pyx_CyFunctionObject *op)
{
    PyObject* result = (op->func_code) ? op->func_code : Py_None;
    Py_INCREF(result);
    return result;
}

static int
__Pyx_CyFunction_init_defaults(__pyx_CyFunctionObject *op) {
    PyObject *res = op->defaults_getter((PyObject *) op);
    if (unlikely(!res))
        return -1;

    /* Cache result */
    op->defaults_tuple = PyTuple_GET_ITEM(res, 0);
    Py_INCREF(op->defaults_tuple);
    op->defaults_kwdict = PyTuple_GET_ITEM(res, 1);
    Py_INCREF(op->defaults_kwdict);
    Py_DECREF(res);
    return 0;
}

static int
__Pyx_CyFunction_set_defaults(__pyx_CyFunctionObject *op, PyObject* value) {
    PyObject* tmp;
    if (!value) {
        // del => explicit None to prevent rebuilding
        value = Py_None;
    } else if (value != Py_None && !PyTuple_Check(value)) {
        PyErr_SetString(PyExc_TypeError,
                        "__defaults__ must be set to a tuple object");
        return -1;
    }
    Py_INCREF(value);
    tmp = op->defaults_tuple;
    op->defaults_tuple = value;
    Py_XDECREF(tmp);
    return 0;
}

static PyObject *
__Pyx_CyFunction_get_defaults(__pyx_CyFunctionObject *op) {
    PyObject* result = op->defaults_tuple;
    if (unlikely(!result)) {
        if (op->defaults_getter) {
            if (__Pyx_CyFunction_init_defaults(op) < 0) return NULL;
            result = op->defaults_tuple;
        } else {
            result = Py_None;
        }
    }
    Py_INCREF(result);
    return result;
}

static int
__Pyx_CyFunction_set_kwdefaults(__pyx_CyFunctionObject *op, PyObject* value) {
    PyObject* tmp;
    if (!value) {
        // del => explicit None to prevent rebuilding
        value = Py_None;
    } else if (value != Py_None && !PyDict_Check(value)) {
        PyErr_SetString(PyExc_TypeError,
                        "__kwdefaults__ must be set to a dict object");
        return -1;
    }
    Py_INCREF(value);
    tmp = op->defaults_kwdict;
    op->defaults_kwdict = value;
    Py_XDECREF(tmp);
    return 0;
}

static PyObject *
__Pyx_CyFunction_get_kwdefaults(__pyx_CyFunctionObject *op) {
    PyObject* result = op->defaults_kwdict;
    if (unlikely(!result)) {
        if (op->defaults_getter) {
            if (__Pyx_CyFunction_init_defaults(op) < 0) return NULL;
            result = op->defaults_kwdict;
        } else {
            result = Py_None;
        }
    }
    Py_INCREF(result);
    return result;
}

static int
__Pyx_CyFunction_set_annotations(__pyx_CyFunctionObject *op, PyObject* value) {
    PyObject* tmp;
    if (!value || value == Py_None) {
        value = NULL;
    } else if (!PyDict_Check(value)) {
        PyErr_SetString(PyExc_TypeError,
                        "__annotations__ must be set to a dict object");
        return -1;
    }
    Py_XINCREF(value);
    tmp = op->func_annotations;
    op->func_annotations = value;
    Py_XDECREF(tmp);
    return 0;
}

static PyObject *
__Pyx_CyFunction_get_annotations(__pyx_CyFunctionObject *op) {
    PyObject* result = op->func_annotations;
    if (unlikely(!result)) {
        result = PyDict_New();
        if (unlikely(!result)) return NULL;
        op->func_annotations = result;
    }
    Py_INCREF(result);
    return result;
}

//#if PY_VERSION_HEX >= 0x030400C1
//static PyObject *
//__Pyx_CyFunction_get_signature(__pyx_CyFunctionObject *op) {
//    PyObject *inspect_module, *signature_class, *signature;
//    // from inspect import Signature
//    inspect_module = PyImport_ImportModuleLevelObject(PYIDENT("inspect"), NULL, NULL, NULL, 0);
//    if (unlikely(!inspect_module))
//        goto bad;
//    signature_class = __Pyx_PyObject_GetAttrStr(inspect_module, PYIDENT("Signature"));
//    Py_DECREF(inspect_module);
//    if (unlikely(!signature_class))
//        goto bad;
//    // return Signature.from_function(op)
//    signature = PyObject_CallMethodObjArgs(signature_class, PYIDENT("from_function"), op, NULL);
//    Py_DECREF(signature_class);
//    if (likely(signature))
//        return signature;
//bad:
//    // make sure we raise an AttributeError from this property on any errors
//    if (!PyErr_ExceptionMatches(PyExc_AttributeError))
//        PyErr_SetString(PyExc_AttributeError, "failed to calculate __signature__");
//    return NULL;
//}
//#endif

static PyGetSetDef __pyx_CyFunction_getsets[] = {
    {(char *) "func_doc", (getter)__Pyx_CyFunction_get_doc, (setter)__Pyx_CyFunction_set_doc, 0, 0},
    {(char *) "__doc__",  (getter)__Pyx_CyFunction_get_doc, (setter)__Pyx_CyFunction_set_doc, 0, 0},
    {(char *) "func_name", (getter)__Pyx_CyFunction_get_name, (setter)__Pyx_CyFunction_set_name, 0, 0},
    {(char *) "__name__", (getter)__Pyx_CyFunction_get_name, (setter)__Pyx_CyFunction_set_name, 0, 0},
    {(char *) "__qualname__", (getter)__Pyx_CyFunction_get_qualname, (setter)__Pyx_CyFunction_set_qualname, 0, 0},
    {(char *) "__self__", (getter)__Pyx_CyFunction_get_self, 0, 0, 0},
    {(char *) "func_dict", (getter)__Pyx_CyFunction_get_dict, (setter)__Pyx_CyFunction_set_dict, 0, 0},
    {(char *) "__dict__", (getter)__Pyx_CyFunction_get_dict, (setter)__Pyx_CyFunction_set_dict, 0, 0},
    {(char *) "func_globals", (getter)__Pyx_CyFunction_get_globals, 0, 0, 0},
    {(char *) "__globals__", (getter)__Pyx_CyFunction_get_globals, 0, 0, 0},
    {(char *) "func_closure", (getter)__Pyx_CyFunction_get_closure, 0, 0, 0},
    {(char *) "__closure__", (getter)__Pyx_CyFunction_get_closure, 0, 0, 0},
    {(char *) "func_code", (getter)__Pyx_CyFunction_get_code, 0, 0, 0},
    {(char *) "__code__", (getter)__Pyx_CyFunction_get_code, 0, 0, 0},
    {(char *) "func_defaults", (getter)__Pyx_CyFunction_get_defaults, (setter)__Pyx_CyFunction_set_defaults, 0, 0},
    {(char *) "__defaults__", (getter)__Pyx_CyFunction_get_defaults, (setter)__Pyx_CyFunction_set_defaults, 0, 0},
    {(char *) "__kwdefaults__", (getter)__Pyx_CyFunction_get_kwdefaults, (setter)__Pyx_CyFunction_set_kwdefaults, 0, 0},
    {(char *) "__annotations__", (getter)__Pyx_CyFunction_get_annotations, (setter)__Pyx_CyFunction_set_annotations, 0, 0},
//#if PY_VERSION_HEX >= 0x030400C1
//    {(char *) "__signature__", (getter)__Pyx_CyFunction_get_signature, 0, 0, 0},
//#endif
    {0, 0, 0, 0, 0}
};

#ifndef PY_WRITE_RESTRICTED /* < Py2.5 */
#define PY_WRITE_RESTRICTED WRITE_RESTRICTED
#endif

static PyMemberDef __pyx_CyFunction_members[] = {
    {(char *) "__module__", T_OBJECT, offsetof(__pyx_CyFunctionObject, func.m_module), PY_WRITE_RESTRICTED, 0},
    {0, 0, 0,  0, 0}
};

static PyObject *
__Pyx_CyFunction_reduce(__pyx_CyFunctionObject *m, CYTHON_UNUSED PyObject *args)
{
#if PY_MAJOR_VERSION >= 3
    return PyUnicode_FromString(m->func.m_ml->ml_name);
#else
    return PyString_FromString(m->func.m_ml->ml_name);
#endif
}

static PyMethodDef __pyx_CyFunction_methods[] = {
    {__Pyx_NAMESTR("__reduce__"), (PyCFunction)__Pyx_CyFunction_reduce, METH_VARARGS, 0},
    {0, 0, 0, 0}
};


static PyObject *__Pyx_CyFunction_New(PyTypeObject *type, PyMethodDef *ml, int flags, PyObject* qualname,
                                      PyObject *closure, PyObject *module, PyObject* globals, PyObject* code) {
    __pyx_CyFunctionObject *op = PyObject_GC_New(__pyx_CyFunctionObject, type);
    if (op == NULL)
        return NULL;
    op->flags = flags;
    op->func_weakreflist = NULL;
    op->func.m_ml = ml;
    op->func.m_self = (PyObject *) op;
    Py_XINCREF(closure);
    op->func_closure = closure;
    Py_XINCREF(module);
    op->func.m_module = module;
    op->func_dict = NULL;
    op->func_name = NULL;
    Py_INCREF(qualname);
    op->func_qualname = qualname;
    op->func_doc = NULL;
    op->func_classobj = NULL;
    op->func_globals = globals;
    Py_INCREF(op->func_globals);
    Py_XINCREF(code);
    op->func_code = code;
    /* Dynamic Default args */
    op->defaults_pyobjects = 0;
    op->defaults = NULL;
    op->defaults_tuple = NULL;
    op->defaults_kwdict = NULL;
    op->defaults_getter = NULL;
    op->func_annotations = NULL;
    PyObject_GC_Track(op);
    return (PyObject *) op;
}

static int
__Pyx_CyFunction_clear(__pyx_CyFunctionObject *m)
{
    Py_CLEAR(m->func_closure);
    Py_CLEAR(m->func.m_module);
    Py_CLEAR(m->func_dict);
    Py_CLEAR(m->func_name);
    Py_CLEAR(m->func_qualname);
    Py_CLEAR(m->func_doc);
    Py_CLEAR(m->func_globals);
    Py_CLEAR(m->func_code);
    Py_CLEAR(m->func_classobj);
    Py_CLEAR(m->defaults_tuple);
    Py_CLEAR(m->defaults_kwdict);
    Py_CLEAR(m->func_annotations);

    if (m->defaults) {
        PyObject **pydefaults = __Pyx_CyFunction_Defaults(PyObject *, m);
        int i;

        for (i = 0; i < m->defaults_pyobjects; i++)
            Py_XDECREF(pydefaults[i]);

        PyMem_Free(m->defaults);
        m->defaults = NULL;
    }

    return 0;
}

static void __Pyx_CyFunction_dealloc(__pyx_CyFunctionObject *m)
{
    PyObject_GC_UnTrack(m);
    if (m->func_weakreflist != NULL)
        PyObject_ClearWeakRefs((PyObject *) m);
    __Pyx_CyFunction_clear(m);
    PyObject_GC_Del(m);
}

static int __Pyx_CyFunction_traverse(__pyx_CyFunctionObject *m, visitproc visit, void *arg)
{
    Py_VISIT(m->func_closure);
    Py_VISIT(m->func.m_module);
    Py_VISIT(m->func_dict);
    Py_VISIT(m->func_name);
    Py_VISIT(m->func_qualname);
    Py_VISIT(m->func_doc);
    Py_VISIT(m->func_globals);
    Py_VISIT(m->func_code);
    Py_VISIT(m->func_classobj);
    Py_VISIT(m->defaults_tuple);
    Py_VISIT(m->defaults_kwdict);

    if (m->defaults) {
        PyObject **pydefaults = __Pyx_CyFunction_Defaults(PyObject *, m);
        int i;

        for (i = 0; i < m->defaults_pyobjects; i++)
            Py_VISIT(pydefaults[i]);
    }

    return 0;
}

static PyObject *__Pyx_CyFunction_descr_get(PyObject *func, PyObject *obj, PyObject *type)
{
    __pyx_CyFunctionObject *m = (__pyx_CyFunctionObject *) func;

    if (m->flags & __Pyx_CYFUNCTION_STATICMETHOD) {
        Py_INCREF(func);
        return func;
    }

    if (m->flags & __Pyx_CYFUNCTION_CLASSMETHOD) {
        if (type == NULL)
            type = (PyObject *)(Py_TYPE(obj));
        return PyMethod_New(func,
                            type, (PyObject *)(Py_TYPE(type)));
    }

    if (obj == Py_None)
        obj = NULL;
    return PyMethod_New(func, obj, type);
}

static PyObject*
__Pyx_CyFunction_repr(__pyx_CyFunctionObject *op)
{
#if PY_MAJOR_VERSION >= 3
    return PyUnicode_FromFormat("<cyfunction %U at %p>",
                                op->func_qualname, (void *)op);
#else
    return PyString_FromFormat("<cyfunction %s at %p>",
                               PyString_AsString(op->func_qualname), (void *)op);
#endif
}

#if CYTHON_COMPILING_IN_PYPY
/* originally copied from PyCFunction_Call() in CPython's Objects/methodobject.c */
/* PyPy does not have this function */
static PyObject * __Pyx_CyFunction_Call(PyObject *func, PyObject *arg, PyObject *kw) {
    PyCFunctionObject* f = (PyCFunctionObject*)func;
    PyCFunction meth = PyCFunction_GET_FUNCTION(func);
    PyObject *self = PyCFunction_GET_SELF(func);
    Py_ssize_t size;

    switch (PyCFunction_GET_FLAGS(func) & ~(METH_CLASS | METH_STATIC | METH_COEXIST)) {
    case METH_VARARGS:
        if (likely(kw == NULL) || PyDict_Size(kw) == 0)
            return (*meth)(self, arg);
        break;
    case METH_VARARGS | METH_KEYWORDS:
        return (*(PyCFunctionWithKeywords)meth)(self, arg, kw);
    case METH_NOARGS:
        if (likely(kw == NULL) || PyDict_Size(kw) == 0) {
            size = PyTuple_GET_SIZE(arg);
            if (size == 0)
                return (*meth)(self, NULL);
            PyErr_Format(PyExc_TypeError,
                "%.200s() takes no arguments (%zd given)",
                f->m_ml->ml_name, size);
            return NULL;
        }
        break;
    case METH_O:
        if (likely(kw == NULL) || PyDict_Size(kw) == 0) {
            size = PyTuple_GET_SIZE(arg);
            if (size == 1)
                return (*meth)(self, PyTuple_GET_ITEM(arg, 0));
            PyErr_Format(PyExc_TypeError,
                "%.200s() takes exactly one argument (%zd given)",
                f->m_ml->ml_name, size);
            return NULL;
        }
        break;
    default:
        PyErr_SetString(PyExc_SystemError, "Bad call flags in "
                        "__Pyx_CyFunction_Call. METH_OLDARGS is no "
                        "longer supported!");

        return NULL;
    }
    PyErr_Format(PyExc_TypeError, "%.200s() takes no keyword arguments",
                 f->m_ml->ml_name);
    return NULL;
}
#else
static PyObject * __Pyx_CyFunction_Call(PyObject *func, PyObject *arg, PyObject *kw) {
	return PyCFunction_Call(func, arg, kw);
}
#endif

static PyTypeObject __pyx_CyFunctionType_type = {
    PyVarObject_HEAD_INIT(0, 0)
    __Pyx_NAMESTR("cython_function_or_method"), /*tp_name*/
    sizeof(__pyx_CyFunctionObject),   /*tp_basicsize*/
    0,                                  /*tp_itemsize*/
    (destructor) __Pyx_CyFunction_dealloc, /*tp_dealloc*/
    0,                                  /*tp_print*/
    0,                                  /*tp_getattr*/
    0,                                  /*tp_setattr*/
#if PY_MAJOR_VERSION < 3
    0,                                  /*tp_compare*/
#else
    0,                                  /*reserved*/
#endif
    (reprfunc) __Pyx_CyFunction_repr,   /*tp_repr*/
    0,                                  /*tp_as_number*/
    0,                                  /*tp_as_sequence*/
    0,                                  /*tp_as_mapping*/
    0,                                  /*tp_hash*/
    __Pyx_CyFunction_Call,              /*tp_call*/
    0,                                  /*tp_str*/
    0,                                  /*tp_getattro*/
    0,                                  /*tp_setattro*/
    0,                                  /*tp_as_buffer*/
    Py_TPFLAGS_DEFAULT | Py_TPFLAGS_HAVE_GC, /* tp_flags*/
    0,                                  /*tp_doc*/
    (traverseproc) __Pyx_CyFunction_traverse,   /*tp_traverse*/
    (inquiry) __Pyx_CyFunction_clear,   /*tp_clear*/
    0,                                  /*tp_richcompare*/
    offsetof(__pyx_CyFunctionObject, func_weakreflist), /* tp_weaklistoffse */
    0,                                  /*tp_iter*/
    0,                                  /*tp_iternext*/
    __pyx_CyFunction_methods,           /*tp_methods*/
    __pyx_CyFunction_members,           /*tp_members*/
    __pyx_CyFunction_getsets,           /*tp_getset*/
    0,                                  /*tp_base*/
    0,                                  /*tp_dict*/
    __Pyx_CyFunction_descr_get,         /*tp_descr_get*/
    0,                                  /*tp_descr_set*/
    offsetof(__pyx_CyFunctionObject, func_dict),/*tp_dictoffset*/
    0,                                  /*tp_init*/
    0,                                  /*tp_alloc*/
    0,                                  /*tp_new*/
    0,                                  /*tp_free*/
    0,                                  /*tp_is_gc*/
    0,                                  /*tp_bases*/
    0,                                  /*tp_mro*/
    0,                                  /*tp_cache*/
    0,                                  /*tp_subclasses*/
    0,                                  /*tp_weaklist*/
    0,                                  /*tp_del*/
#if PY_VERSION_HEX >= 0x02060000
    0,                                  /*tp_version_tag*/
#endif
#if PY_VERSION_HEX >= 0x030400a1
    0,                                  /*tp_finalize*/
#endif
};


static int __Pyx_CyFunction_init(void) {
#if !CYTHON_COMPILING_IN_PYPY
    // avoid a useless level of call indirection
    __pyx_CyFunctionType_type.tp_call = PyCFunction_Call;
#endif
    __pyx_CyFunctionType = __Pyx_FetchCommonType(&__pyx_CyFunctionType_type);
    if (__pyx_CyFunctionType == NULL) {
        return -1;
    }
    return 0;
}

static CYTHON_INLINE void *__Pyx_CyFunction_InitDefaults(PyObject *func, size_t size, int pyobjects) {
    __pyx_CyFunctionObject *m = (__pyx_CyFunctionObject *) func;

    m->defaults = PyMem_Malloc(size);
    if (!m->defaults)
        return PyErr_NoMemory();
    memset(m->defaults, 0, size);
    m->defaults_pyobjects = pyobjects;
    return m->defaults;
}

static CYTHON_INLINE void __Pyx_CyFunction_SetDefaultsTuple(PyObject *func, PyObject *tuple) {
    __pyx_CyFunctionObject *m = (__pyx_CyFunctionObject *) func;
    m->defaults_tuple = tuple;
    Py_INCREF(tuple);
}

static CYTHON_INLINE void __Pyx_CyFunction_SetDefaultsKwDict(PyObject *func, PyObject *dict) {
    __pyx_CyFunctionObject *m = (__pyx_CyFunctionObject *) func;
    m->defaults_kwdict = dict;
    Py_INCREF(dict);
}

static CYTHON_INLINE void __Pyx_CyFunction_SetAnnotationsDict(PyObject *func, PyObject *dict) {
    __pyx_CyFunctionObject *m = (__pyx_CyFunctionObject *) func;
    m->func_annotations = dict;
    Py_INCREF(dict);
}

//////////////////// CyFunctionClassCell.proto ////////////////////
static CYTHON_INLINE void __Pyx_CyFunction_InitClassCell(PyObject *cyfunctions,
                                                         PyObject *classobj);

//////////////////// CyFunctionClassCell ////////////////////
//@requires: CythonFunction

static CYTHON_INLINE void __Pyx_CyFunction_InitClassCell(PyObject *cyfunctions, PyObject *classobj) {
    int i;

    for (i = 0; i < PyList_GET_SIZE(cyfunctions); i++) {
        __pyx_CyFunctionObject *m =
            (__pyx_CyFunctionObject *) PyList_GET_ITEM(cyfunctions, i);
        m->func_classobj = classobj;
        Py_INCREF(classobj);
    }
}

//////////////////// FusedFunction.proto ////////////////////
typedef struct {
    __pyx_CyFunctionObject func;
    PyObject *__signatures__;
    PyObject *type;
    PyObject *self;
} __pyx_FusedFunctionObject;

#define __pyx_FusedFunction_NewEx(ml, flags, qualname, self, module, globals, code)         \
        __pyx_FusedFunction_New(__pyx_FusedFunctionType, ml, flags, qualname, self, module, globals, code)
static PyObject *__pyx_FusedFunction_New(PyTypeObject *type,
                                         PyMethodDef *ml, int flags,
                                         PyObject *qualname, PyObject *self,
                                         PyObject *module, PyObject *globals,
                                         PyObject *code);

static int __pyx_FusedFunction_clear(__pyx_FusedFunctionObject *self);
static PyTypeObject *__pyx_FusedFunctionType = NULL;
static int __pyx_FusedFunction_init(void);

#define __Pyx_FusedFunction_USED

//////////////////// FusedFunction ////////////////////
//@requires: CythonFunction

static PyObject *
__pyx_FusedFunction_New(PyTypeObject *type, PyMethodDef *ml, int flags,
                        PyObject *qualname, PyObject *self,
                        PyObject *module, PyObject *globals,
                        PyObject *code)
{
    __pyx_FusedFunctionObject *fusedfunc =
        (__pyx_FusedFunctionObject *) __Pyx_CyFunction_New(type, ml, flags, qualname,
                                                           self, module, globals, code);
    if (!fusedfunc)
        return NULL;

    fusedfunc->__signatures__ = NULL;
    fusedfunc->type = NULL;
    fusedfunc->self = NULL;
    return (PyObject *) fusedfunc;
}

static void __pyx_FusedFunction_dealloc(__pyx_FusedFunctionObject *self) {
    __pyx_FusedFunction_clear(self);
    __pyx_FusedFunctionType->tp_free((PyObject *) self);
}

static int
__pyx_FusedFunction_traverse(__pyx_FusedFunctionObject *self,
                             visitproc visit,
                             void *arg)
{
    Py_VISIT(self->self);
    Py_VISIT(self->type);
    Py_VISIT(self->__signatures__);
    return __Pyx_CyFunction_traverse((__pyx_CyFunctionObject *) self, visit, arg);
}

static int
__pyx_FusedFunction_clear(__pyx_FusedFunctionObject *self)
{
    Py_CLEAR(self->self);
    Py_CLEAR(self->type);
    Py_CLEAR(self->__signatures__);
    return __Pyx_CyFunction_clear((__pyx_CyFunctionObject *) self);
}


static PyObject *
__pyx_FusedFunction_descr_get(PyObject *self, PyObject *obj, PyObject *type)
{
    __pyx_FusedFunctionObject *func, *meth;

    func = (__pyx_FusedFunctionObject *) self;

    if (func->self || func->func.flags & __Pyx_CYFUNCTION_STATICMETHOD) {
        /* Do not allow rebinding and don't do anything for static methods */
        Py_INCREF(self);
        return self;
    }

    if (obj == Py_None)
        obj = NULL;

    meth = (__pyx_FusedFunctionObject *) __pyx_FusedFunction_NewEx(
                    ((PyCFunctionObject *) func)->m_ml,
                    ((__pyx_CyFunctionObject *) func)->flags,
                    ((__pyx_CyFunctionObject *) func)->func_qualname,
                    ((__pyx_CyFunctionObject *) func)->func_closure,
                    ((PyCFunctionObject *) func)->m_module,
                    ((__pyx_CyFunctionObject *) func)->func_globals,
                    ((__pyx_CyFunctionObject *) func)->func_code);
    if (!meth)
        return NULL;

    Py_XINCREF(func->func.func_classobj);
    meth->func.func_classobj = func->func.func_classobj;

    Py_XINCREF(func->__signatures__);
    meth->__signatures__ = func->__signatures__;

    Py_XINCREF(type);
    meth->type = type;

    Py_XINCREF(func->func.defaults_tuple);
    meth->func.defaults_tuple = func->func.defaults_tuple;

    if (func->func.flags & __Pyx_CYFUNCTION_CLASSMETHOD)
        obj = type;

    Py_XINCREF(obj);
    meth->self = obj;

    return (PyObject *) meth;
}

static PyObject *
_obj_to_str(PyObject *obj)
{
    if (PyType_Check(obj))
        return PyObject_GetAttr(obj, PYIDENT("__name__"));
    else
        return PyObject_Str(obj);
}

static PyObject *
__pyx_FusedFunction_getitem(__pyx_FusedFunctionObject *self, PyObject *idx)
{
    PyObject *signature = NULL;
    PyObject *unbound_result_func;
    PyObject *result_func = NULL;

    if (self->__signatures__ == NULL) {
        PyErr_SetString(PyExc_TypeError, "Function is not fused");
        return NULL;
    }

    if (PyTuple_Check(idx)) {
        PyObject *list = PyList_New(0);
        Py_ssize_t n = PyTuple_GET_SIZE(idx);
        PyObject *string = NULL;
        PyObject *sep = NULL;
        int i;

        if (!list)
            return NULL;

        for (i = 0; i < n; i++) {
            PyObject *item = PyTuple_GET_ITEM(idx, i);

            string = _obj_to_str(item);
            if (!string || PyList_Append(list, string) < 0)
                goto __pyx_err;

            Py_DECREF(string);
        }

        sep = PyUnicode_FromString("|");
        if (sep)
            signature = PyUnicode_Join(sep, list);
__pyx_err:
;
        Py_DECREF(list);
        Py_XDECREF(sep);
    } else {
        signature = _obj_to_str(idx);
    }

    if (!signature)
        return NULL;

    unbound_result_func = PyObject_GetItem(self->__signatures__, signature);

    if (unbound_result_func) {
        if (self->self || self->type) {
            __pyx_FusedFunctionObject *unbound = (__pyx_FusedFunctionObject *) unbound_result_func;

            /* Todo: move this to InitClassCell */
            Py_CLEAR(unbound->func.func_classobj);
            Py_XINCREF(self->func.func_classobj);
            unbound->func.func_classobj = self->func.func_classobj;

            result_func = __pyx_FusedFunction_descr_get(unbound_result_func,
                                                        self->self, self->type);
        } else {
            result_func = unbound_result_func;
            Py_INCREF(result_func);
        }
    }

    Py_DECREF(signature);
    Py_XDECREF(unbound_result_func);

    return result_func;
}

static PyObject *
__pyx_FusedFunction_callfunction(PyObject *func, PyObject *args, PyObject *kw)
{
     __pyx_CyFunctionObject *cyfunc = (__pyx_CyFunctionObject *) func;
    PyObject *result;
    int static_specialized = (cyfunc->flags & __Pyx_CYFUNCTION_STATICMETHOD &&
                              !((__pyx_FusedFunctionObject *) func)->__signatures__);

    if (cyfunc->flags & __Pyx_CYFUNCTION_CCLASS && !static_specialized) {
        Py_ssize_t argc;
        PyObject *new_args;
        PyObject *self;
        PyObject *m_self;

        argc = PyTuple_GET_SIZE(args);
        new_args = PyTuple_GetSlice(args, 1, argc);

        if (!new_args)
            return NULL;

        self = PyTuple_GetItem(args, 0);

        if (!self)
            return NULL;

        m_self = cyfunc->func.m_self;
        cyfunc->func.m_self = self;
        result = __Pyx_CyFunction_Call(func, new_args, kw);
        cyfunc->func.m_self = m_self;

        Py_DECREF(new_args);
    } else {
        result = __Pyx_CyFunction_Call(func, args, kw);
    }

    return result;
}

/* Note: the 'self' from method binding is passed in in the args tuple,
         whereas PyCFunctionObject's m_self is passed in as the first
         argument to the C function. For extension methods we need
         to pass 'self' as 'm_self' and not as the first element of the
         args tuple.
*/
static PyObject *
__pyx_FusedFunction_call(PyObject *func, PyObject *args, PyObject *kw)
{
    __pyx_FusedFunctionObject *binding_func = (__pyx_FusedFunctionObject *) func;
    Py_ssize_t argc = PyTuple_GET_SIZE(args);
    PyObject *new_args = NULL;
    __pyx_FusedFunctionObject *new_func = NULL;
    PyObject *result = NULL;
    PyObject *self = NULL;
    int is_staticmethod = binding_func->func.flags & __Pyx_CYFUNCTION_STATICMETHOD;
    int is_classmethod = binding_func->func.flags & __Pyx_CYFUNCTION_CLASSMETHOD;

    if (binding_func->self) {
        /* Bound method call, put 'self' in the args tuple */
        Py_ssize_t i;
        new_args = PyTuple_New(argc + 1);
        if (!new_args)
            return NULL;

        self = binding_func->self;
        Py_INCREF(self);
        PyTuple_SET_ITEM(new_args, 0, self);

        for (i = 0; i < argc; i++) {
            PyObject *item = PyTuple_GET_ITEM(args, i);
            Py_INCREF(item);
            PyTuple_SET_ITEM(new_args, i + 1, item);
        }

        args = new_args;
    } else if (binding_func->type) {
        /* Unbound method call */
        if (argc < 1) {
            PyErr_SetString(PyExc_TypeError, "Need at least one argument, 0 given.");
            return NULL;
        }
        self = PyTuple_GET_ITEM(args, 0);
    }

    if (self && !is_classmethod && !is_staticmethod &&
            !PyObject_IsInstance(self, binding_func->type)) {
        PyErr_Format(PyExc_TypeError,
                     "First argument should be of type %.200s, got %.200s.",
                     ((PyTypeObject *) binding_func->type)->tp_name,
                     self->ob_type->tp_name);
        goto __pyx_err;
    }

    if (binding_func->__signatures__) {
        PyObject *tup = PyTuple_Pack(4, binding_func->__signatures__, args,
                                        kw == NULL ? Py_None : kw,
                                        binding_func->func.defaults_tuple);
        if (!tup)
            goto __pyx_err;

        new_func = (__pyx_FusedFunctionObject *) __pyx_FusedFunction_callfunction(func, tup, NULL);
        Py_DECREF(tup);

        if (!new_func)
            goto __pyx_err;

        Py_XINCREF(binding_func->func.func_classobj);
        Py_CLEAR(new_func->func.func_classobj);
        new_func->func.func_classobj = binding_func->func.func_classobj;

        func = (PyObject *) new_func;
    }

    result = __pyx_FusedFunction_callfunction(func, args, kw);
__pyx_err:
    Py_XDECREF(new_args);
    Py_XDECREF((PyObject *) new_func);
    return result;
}

static PyMemberDef __pyx_FusedFunction_members[] = {
    {(char *) "__signatures__",
     T_OBJECT,
     offsetof(__pyx_FusedFunctionObject, __signatures__),
     READONLY,
     __Pyx_DOCSTR(0)},
    {0, 0, 0, 0, 0},
};

static PyMappingMethods __pyx_FusedFunction_mapping_methods = {
    0,
    (binaryfunc) __pyx_FusedFunction_getitem,
    0,
};

static PyTypeObject __pyx_FusedFunctionType_type = {
    PyVarObject_HEAD_INIT(0, 0)
    __Pyx_NAMESTR("fused_cython_function"), /*tp_name*/
    sizeof(__pyx_FusedFunctionObject), /*tp_basicsize*/
    0,                                  /*tp_itemsize*/
    (destructor) __pyx_FusedFunction_dealloc, /*tp_dealloc*/
    0,                                  /*tp_print*/
    0,                                  /*tp_getattr*/
    0,                                  /*tp_setattr*/
#if PY_MAJOR_VERSION < 3
    0,                                  /*tp_compare*/
#else
    0,                                  /*reserved*/
#endif
    0,                                  /*tp_repr*/
    0,                                  /*tp_as_number*/
    0,                                  /*tp_as_sequence*/
    &__pyx_FusedFunction_mapping_methods, /*tp_as_mapping*/
    0,                                  /*tp_hash*/
    (ternaryfunc) __pyx_FusedFunction_call, /*tp_call*/
    0,                                  /*tp_str*/
    0,                                  /*tp_getattro*/
    0,                                  /*tp_setattro*/
    0,                                  /*tp_as_buffer*/
    Py_TPFLAGS_DEFAULT | Py_TPFLAGS_HAVE_GC | Py_TPFLAGS_BASETYPE, /* tp_flags*/
    0,                                  /*tp_doc*/
    (traverseproc) __pyx_FusedFunction_traverse,   /*tp_traverse*/
    (inquiry) __pyx_FusedFunction_clear,/*tp_clear*/
    0,                                  /*tp_richcompare*/
    0,                                  /*tp_weaklistoffset*/
    0,                                  /*tp_iter*/
    0,                                  /*tp_iternext*/
    0,                                  /*tp_methods*/
    __pyx_FusedFunction_members,        /*tp_members*/
    /* __doc__ is None for the fused function type, but we need it to be */
    /* a descriptor for the instance's __doc__, so rebuild descriptors in our subclass */
    __pyx_CyFunction_getsets,           /*tp_getset*/
    &__pyx_CyFunctionType_type,         /*tp_base*/
    0,                                  /*tp_dict*/
    __pyx_FusedFunction_descr_get,      /*tp_descr_get*/
    0,                                  /*tp_descr_set*/
    0,                                  /*tp_dictoffset*/
    0,                                  /*tp_init*/
    0,                                  /*tp_alloc*/
    0,                                  /*tp_new*/
    0,                                  /*tp_free*/
    0,                                  /*tp_is_gc*/
    0,                                  /*tp_bases*/
    0,                                  /*tp_mro*/
    0,                                  /*tp_cache*/
    0,                                  /*tp_subclasses*/
    0,                                  /*tp_weaklist*/
    0,                                  /*tp_del*/
#if PY_VERSION_HEX >= 0x02060000
    0,                                  /*tp_version_tag*/
#endif
#if PY_VERSION_HEX >= 0x030400a1
    0,                                  /*tp_finalize*/
#endif
};

static int __pyx_FusedFunction_init(void) {
    __pyx_FusedFunctionType = __Pyx_FetchCommonType(&__pyx_FusedFunctionType_type);
    if (__pyx_FusedFunctionType == NULL) {
        return -1;
    }
    return 0;
}

//////////////////// ClassMethod.proto ////////////////////

#include "descrobject.h"
static PyObject* __Pyx_Method_ClassMethod(PyObject *method); /*proto*/

//////////////////// ClassMethod ////////////////////

static PyObject* __Pyx_Method_ClassMethod(PyObject *method) {
#if CYTHON_COMPILING_IN_PYPY
    if (PyObject_TypeCheck(method, &PyWrapperDescr_Type)) { /* cdef classes */
        return PyClassMethod_New(method);
    }
#else
    /* It appears that PyMethodDescr_Type is not anywhere exposed in the Python/C API */
    static PyTypeObject *methoddescr_type = NULL;
    if (methoddescr_type == NULL) {
       PyObject *meth = __Pyx_GetAttrString((PyObject*)&PyList_Type, "append");
       if (!meth) return NULL;
       methoddescr_type = Py_TYPE(meth);
       Py_DECREF(meth);
    }
    if (PyObject_TypeCheck(method, methoddescr_type)) { /* cdef classes */
        PyMethodDescrObject *descr = (PyMethodDescrObject *)method;
        #if PY_VERSION_HEX < 0x03020000
        PyTypeObject *d_type = descr->d_type;
        #else
        PyTypeObject *d_type = descr->d_common.d_type;
        #endif
        return PyDescr_NewClassMethod(d_type, descr->d_method);
    }
#endif
    else if (PyMethod_Check(method)) { /* python classes */
        return PyClassMethod_New(PyMethod_GET_FUNCTION(method));
    }
    else if (PyCFunction_Check(method)) {
        return PyClassMethod_New(method);
    }
#ifdef __Pyx_CyFunction_USED
    else if (PyObject_TypeCheck(method, __pyx_CyFunctionType)) {
        return PyClassMethod_New(method);
    }
#endif
    PyErr_SetString(PyExc_TypeError,
                   "Class-level classmethod() can only be called on "
                   "a method_descriptor or instance method.");
    return NULL;
}
