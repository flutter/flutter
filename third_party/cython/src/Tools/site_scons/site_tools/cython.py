"""
Tool to run Cython files (.pyx) into .c and .cpp.

TODO:
 - Add support for dynamically selecting in-process Cython
   through CYTHONINPROCESS variable.
 - Have a CYTHONCPP option which turns on C++ in flags and
   changes output extension at the same time

VARIABLES:
 - CYTHON - The path to the "cython" command line tool.
 - CYTHONFLAGS - Flags to pass to the "cython" command line tool.

AUTHORS:
 - David Cournapeau
 - Dag Sverre Seljebotn

"""
import SCons
from SCons.Builder import Builder
from SCons.Action import Action

#def cython_action(target, source, env):
#    print target, source, env
#    from Cython.Compiler.Main import compile as cython_compile
#    res = cython_compile(str(source[0]))

cythonAction = Action("$CYTHONCOM")

def create_builder(env):
    try:
        cython = env['BUILDERS']['Cython']
    except KeyError:
        cython = SCons.Builder.Builder(
                  action = cythonAction,
                  emitter = {},
                  suffix = cython_suffix_emitter,
                  single_source = 1)
        env['BUILDERS']['Cython'] = cython

    return cython

def cython_suffix_emitter(env, source):
    return "$CYTHONCFILESUFFIX"

def generate(env):
    env["CYTHON"] = "cython"
    env["CYTHONCOM"] = "$CYTHON $CYTHONFLAGS -o $TARGET $SOURCE"
    env["CYTHONCFILESUFFIX"] = ".c"

    c_file, cxx_file = SCons.Tool.createCFileBuilders(env)

    c_file.suffix['.pyx'] = cython_suffix_emitter
    c_file.add_action('.pyx', cythonAction)

    c_file.suffix['.py'] = cython_suffix_emitter
    c_file.add_action('.py', cythonAction)

    create_builder(env)

def exists(env):
    try:
#        import Cython
        return True
    except ImportError:
        return False
