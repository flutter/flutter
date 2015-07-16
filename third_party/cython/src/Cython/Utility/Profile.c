/////////////// Profile.proto ///////////////
//@substitute: naming

// Note that cPython ignores PyTrace_EXCEPTION,
// but maybe some other profilers don't.

#ifndef CYTHON_PROFILE
  #define CYTHON_PROFILE 1
#endif

#ifndef CYTHON_TRACE
  #define CYTHON_TRACE 0
#endif

#if CYTHON_TRACE
  #undef CYTHON_PROFILE_REUSE_FRAME
#endif

#ifndef CYTHON_PROFILE_REUSE_FRAME
  #define CYTHON_PROFILE_REUSE_FRAME 0
#endif

#if CYTHON_PROFILE || CYTHON_TRACE

  #include "compile.h"
  #include "frameobject.h"
  #include "traceback.h"

  #if CYTHON_PROFILE_REUSE_FRAME
    #define CYTHON_FRAME_MODIFIER static
    #define CYTHON_FRAME_DEL
  #else
    #define CYTHON_FRAME_MODIFIER
    #define CYTHON_FRAME_DEL Py_CLEAR($frame_cname)
  #endif

  #define __Pyx_TraceDeclarations                                     \
  static PyCodeObject *$frame_code_cname = NULL;                      \
  CYTHON_FRAME_MODIFIER PyFrameObject *$frame_cname = NULL;           \
  int __Pyx_use_tracing = 0;

  #define __Pyx_TraceCall(funcname, srcfile, firstlineno)                            \
  if (unlikely(PyThreadState_GET()->use_tracing &&                                   \
          (PyThreadState_GET()->c_profilefunc || (CYTHON_TRACE && PyThreadState_GET()->c_tracefunc)))) {      \
      __Pyx_use_tracing = __Pyx_TraceSetupAndCall(&$frame_code_cname, &$frame_cname, funcname, srcfile, firstlineno);  \
  }

  #define __Pyx_TraceException()                                                           \
  if (unlikely(__Pyx_use_tracing) && PyThreadState_GET()->use_tracing &&                   \
          (PyThreadState_GET()->c_profilefunc || (CYTHON_TRACE && PyThreadState_GET()->c_tracefunc))) {  \
      PyThreadState* tstate = PyThreadState_GET();                                         \
      tstate->use_tracing = 0;                                                             \
      PyObject *exc_info = __Pyx_GetExceptionTuple();                                      \
      if (exc_info) {                                                                      \
          if (CYTHON_TRACE && tstate->c_tracefunc)                                         \
              tstate->c_tracefunc(                                                         \
                  tstate->c_traceobj, $frame_cname, PyTrace_EXCEPTION, exc_info);          \
          tstate->c_profilefunc(                                                           \
              tstate->c_profileobj, $frame_cname, PyTrace_EXCEPTION, exc_info);            \
          Py_DECREF(exc_info);                                                             \
      }                                                                                    \
      tstate->use_tracing = 1;                                                             \
  }

  #define __Pyx_TraceReturn(result)                                                  \
  if (unlikely(__Pyx_use_tracing) && PyThreadState_GET()->use_tracing) {             \
      PyThreadState* tstate = PyThreadState_GET();                                   \
      tstate->use_tracing = 0;                                                        \
      if (CYTHON_TRACE && tstate->c_tracefunc)                                       \
          tstate->c_tracefunc(                                                       \
              tstate->c_traceobj, $frame_cname, PyTrace_RETURN, (PyObject*)result);  \
      if (tstate->c_profilefunc)                                                     \
          tstate->c_profilefunc(                                                     \
              tstate->c_profileobj, $frame_cname, PyTrace_RETURN, (PyObject*)result);  \
      CYTHON_FRAME_DEL;                                                              \
      tstate->use_tracing = 1;                                                       \
  }

  static PyCodeObject *__Pyx_createFrameCodeObject(const char *funcname, const char *srcfile, int firstlineno); /*proto*/
  static int __Pyx_TraceSetupAndCall(PyCodeObject** code, PyFrameObject** frame, const char *funcname, const char *srcfile, int firstlineno); /*proto*/

#else

  #define __Pyx_TraceDeclarations
  #define __Pyx_TraceCall(funcname, srcfile, firstlineno)
  #define __Pyx_TraceException()
  #define __Pyx_TraceReturn(result)

#endif /* CYTHON_PROFILE */

#if CYTHON_TRACE
  #define __Pyx_TraceLine(lineno)                                                          \
  if (unlikely(__Pyx_use_tracing) && unlikely(PyThreadState_GET()->use_tracing && PyThreadState_GET()->c_tracefunc)) {    \
      PyThreadState* tstate = PyThreadState_GET();                                         \
      $frame_cname->f_lineno = lineno;                                                     \
      tstate->use_tracing = 0;                                                             \
      tstate->c_tracefunc(tstate->c_traceobj, $frame_cname, PyTrace_LINE, NULL);           \
      tstate->use_tracing = 1;                                                             \
  }
#else
  #define __Pyx_TraceLine(lineno)
#endif

/////////////// Profile ///////////////
//@substitute: naming

#if CYTHON_PROFILE

static int __Pyx_TraceSetupAndCall(PyCodeObject** code,
                                   PyFrameObject** frame,
                                   const char *funcname,
                                   const char *srcfile,
                                   int firstlineno) {
    int retval;
    PyThreadState* tstate = PyThreadState_GET();
    if (*frame == NULL || !CYTHON_PROFILE_REUSE_FRAME) {
        if (*code == NULL) {
            *code = __Pyx_createFrameCodeObject(funcname, srcfile, firstlineno);
            if (*code == NULL) return 0;
        }
        *frame = PyFrame_New(
            tstate,                          /*PyThreadState *tstate*/
            *code,                           /*PyCodeObject *code*/
            $moddict_cname,                  /*PyObject *globals*/
            0                                /*PyObject *locals*/
        );
        if (*frame == NULL) return 0;
        if (CYTHON_TRACE && (*frame)->f_trace == NULL) {
            // this enables "f_lineno" lookup, at least in CPython ...
            Py_INCREF(Py_None);
            (*frame)->f_trace = Py_None;
        }
#if PY_VERSION_HEX < 0x030400B1
    } else {
        (*frame)->f_tstate = tstate;
#endif
    }
    (*frame)->f_lineno = firstlineno;
    tstate->use_tracing = 0;
    #if CYTHON_TRACE
    if (tstate->c_tracefunc)
        tstate->c_tracefunc(tstate->c_traceobj, *frame, PyTrace_CALL, NULL);
    if (!tstate->c_profilefunc)
        retval = 1;
    else
    #endif
        retval = tstate->c_profilefunc(tstate->c_profileobj, *frame, PyTrace_CALL, NULL) == 0;
    tstate->use_tracing = (tstate->c_profilefunc ||
                           (CYTHON_TRACE && tstate->c_tracefunc));
    return tstate->use_tracing && retval;
}

static PyCodeObject *__Pyx_createFrameCodeObject(const char *funcname, const char *srcfile, int firstlineno) {
    PyObject *py_srcfile = 0;
    PyObject *py_funcname = 0;
    PyCodeObject *py_code = 0;

    #if PY_MAJOR_VERSION < 3
    py_funcname = PyString_FromString(funcname);
    py_srcfile = PyString_FromString(srcfile);
    #else
    py_funcname = PyUnicode_FromString(funcname);
    py_srcfile = PyUnicode_FromString(srcfile);
    #endif
    if (!py_funcname | !py_srcfile) goto bad;

    py_code = PyCode_New(
        0,                /*int argcount,*/
        #if PY_MAJOR_VERSION >= 3
        0,                /*int kwonlyargcount,*/
        #endif
        0,                /*int nlocals,*/
        0,                /*int stacksize,*/
        0,                /*int flags,*/
        $empty_bytes,     /*PyObject *code,*/
        $empty_tuple,     /*PyObject *consts,*/
        $empty_tuple,     /*PyObject *names,*/
        $empty_tuple,     /*PyObject *varnames,*/
        $empty_tuple,     /*PyObject *freevars,*/
        $empty_tuple,     /*PyObject *cellvars,*/
        py_srcfile,       /*PyObject *filename,*/
        py_funcname,      /*PyObject *name,*/
        firstlineno,      /*int firstlineno,*/
        $empty_bytes      /*PyObject *lnotab*/
    );

bad:
    Py_XDECREF(py_srcfile);
    Py_XDECREF(py_funcname);

    return py_code;
}

#endif /* CYTHON_PROFILE */
