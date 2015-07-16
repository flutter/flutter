# Python version constants
#
# It's better to evaluate these at runtime (i.e. C compile time) using
#
#      if PY_MAJOR_VERSION >= 3:
#           do_stuff_in_Py3_0_and_later()
#      if PY_VERSION_HEX >= 0x02050000:
#           do_stuff_in_Py2_5_and_later()
#
# than using the IF/DEF statements, which are evaluated at Cython
# compile time.  This will keep your C code portable.


cdef extern from *:
    # the complete version, e.g. 0x010502B2 == 1.5.2b2
    int PY_VERSION_HEX

    # the individual sections as plain numbers
    int PY_MAJOR_VERSION
    int PY_MINOR_VERSION
    int PY_MICRO_VERSION
    int PY_RELEASE_LEVEL
    int PY_RELEASE_SERIAL

    # Note: PY_RELEASE_LEVEL is one of
    #    0xA (alpha)
    #    0xB (beta)
    #    0xC (release candidate)
    #    0xF (final)

    char PY_VERSION[]
    char PY_PATCHLEVEL_REVISION[]
