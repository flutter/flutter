"""SCons.Tool.pyext

Tool-specific initialization for python extensions builder.

AUTHORS:
 - David Cournapeau
 - Dag Sverre Seljebotn

"""

#
# __COPYRIGHT__
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
# KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

__revision__ = "__FILE__ __REVISION__ __DATE__ __DEVELOPER__"

import sys

import SCons
from SCons.Tool import SourceFileScanner, ProgramScanner

#  Create common python builders

def createPythonObjectBuilder(env):
    """This is a utility function that creates the PythonObject Builder in an
    Environment if it is not there already.

    If it is already there, we return the existing one.
    """

    try:
        pyobj = env['BUILDERS']['PythonObject']
    except KeyError:
        pyobj = SCons.Builder.Builder(action = {},
                                      emitter = {},
                                      prefix = '$PYEXTOBJPREFIX',
                                      suffix = '$PYEXTOBJSUFFIX',
                                      src_builder = ['CFile', 'CXXFile'],
                                      source_scanner = SourceFileScanner,
                                      single_source = 1)
        env['BUILDERS']['PythonObject'] = pyobj

    return pyobj

def createPythonExtensionBuilder(env):
    """This is a utility function that creates the PythonExtension Builder in
    an Environment if it is not there already.

    If it is already there, we return the existing one.
    """

    try:
        pyext = env['BUILDERS']['PythonExtension']
    except KeyError:
        import SCons.Action
        import SCons.Defaults
        action = SCons.Action.Action("$PYEXTLINKCOM", "$PYEXTLINKCOMSTR")
        action_list = [ SCons.Defaults.SharedCheck,
                        action]
        pyext = SCons.Builder.Builder(action = action_list,
                                      emitter = "$SHLIBEMITTER",
                                      prefix = '$PYEXTPREFIX',
                                      suffix = '$PYEXTSUFFIX',
                                      target_scanner = ProgramScanner,
                                      src_suffix = '$PYEXTOBJSUFFIX',
                                      src_builder = 'PythonObject')
        env['BUILDERS']['PythonExtension'] = pyext

    return pyext

def pyext_coms(platform):
    """Return PYEXTCCCOM, PYEXTCXXCOM and PYEXTLINKCOM for the given
    platform."""
    if platform == 'win32':
        pyext_cccom = "$PYEXTCC /Fo$TARGET /c $PYEXTCCSHARED "\
                      "$PYEXTCFLAGS $PYEXTCCFLAGS $_CCCOMCOM "\
                      "$_PYEXTCPPINCFLAGS $SOURCES"
        pyext_cxxcom = "$PYEXTCXX /Fo$TARGET /c $PYEXTCSHARED "\
                       "$PYEXTCXXFLAGS $PYEXTCCFLAGS $_CCCOMCOM "\
                       "$_PYEXTCPPINCFLAGS $SOURCES"
        pyext_linkcom = '${TEMPFILE("$PYEXTLINK $PYEXTLINKFLAGS '\
                        '/OUT:$TARGET.windows $( $_LIBDIRFLAGS $) '\
                        '$_LIBFLAGS $_PYEXTRUNTIME $SOURCES.windows")}'
    else:
        pyext_cccom = "$PYEXTCC -o $TARGET -c $PYEXTCCSHARED "\
                      "$PYEXTCFLAGS $PYEXTCCFLAGS $_CCCOMCOM "\
                      "$_PYEXTCPPINCFLAGS $SOURCES"
        pyext_cxxcom = "$PYEXTCXX -o $TARGET -c $PYEXTCSHARED "\
                       "$PYEXTCXXFLAGS $PYEXTCCFLAGS $_CCCOMCOM "\
                       "$_PYEXTCPPINCFLAGS $SOURCES"
        pyext_linkcom = "$PYEXTLINK -o $TARGET $PYEXTLINKFLAGS "\
                        "$SOURCES $_LIBDIRFLAGS $_LIBFLAGS $_PYEXTRUNTIME"

    if platform == 'darwin':
        pyext_linkcom += ' $_FRAMEWORKPATH $_FRAMEWORKS $FRAMEWORKSFLAGS'

    return pyext_cccom, pyext_cxxcom, pyext_linkcom

def set_basic_vars(env):
    # Set construction variables which are independant on whether we are using
    # distutils or not.
    env['PYEXTCPPPATH'] = SCons.Util.CLVar('$PYEXTINCPATH')

    env['_PYEXTCPPINCFLAGS'] = '$( ${_concat(INCPREFIX, PYEXTCPPPATH, '\
                               'INCSUFFIX, __env__, RDirs, TARGET, SOURCE)} $)'
    env['PYEXTOBJSUFFIX'] = '$SHOBJSUFFIX'
    env['PYEXTOBJPREFIX'] = '$SHOBJPREFIX'

    env['PYEXTRUNTIME']   = SCons.Util.CLVar("")
    # XXX: this should be handled with different flags
    env['_PYEXTRUNTIME']  = '$( ${_concat(LIBLINKPREFIX, PYEXTRUNTIME, '\
                          'LIBLINKSUFFIX, __env__)} $)'
    # XXX: This won't work in all cases (using mingw, for example). To make
    # this work, we need to know whether PYEXTCC accepts /c and /Fo or -c -o.
    # This is difficult with the current way tools work in scons.
    pycc, pycxx, pylink = pyext_coms(sys.platform)
                            
    env['PYEXTLINKFLAGSEND'] = SCons.Util.CLVar('$LINKFLAGSEND')

    env['PYEXTCCCOM'] = pycc
    env['PYEXTCXXCOM'] = pycxx
    env['PYEXTLINKCOM'] = pylink

def _set_configuration_nodistutils(env):
    # Set env variables to sensible values when not using distutils
    def_cfg = {'PYEXTCC' : '$SHCC',
               'PYEXTCFLAGS' : '$SHCFLAGS',
               'PYEXTCCFLAGS' : '$SHCCFLAGS',
               'PYEXTCXX' : '$SHCXX',
               'PYEXTCXXFLAGS' : '$SHCXXFLAGS',
               'PYEXTLINK' : '$LDMODULE',
               'PYEXTSUFFIX' : '$LDMODULESUFFIX',
               'PYEXTPREFIX' : ''}

    if sys.platform == 'darwin':
        def_cfg['PYEXTSUFFIX'] = '.so'

    for k, v in def_cfg.items():
        ifnotset(env, k, v)

    ifnotset(env, 'PYEXT_ALLOW_UNDEFINED', 
             SCons.Util.CLVar('$ALLOW_UNDEFINED'))
    ifnotset(env, 'PYEXTLINKFLAGS', SCons.Util.CLVar('$LDMODULEFLAGS'))

    env.AppendUnique(PYEXTLINKFLAGS = env['PYEXT_ALLOW_UNDEFINED'])

def ifnotset(env, name, value):
    if not env.has_key(name):
        env[name] = value

def set_configuration(env, use_distutils):
    """Set construction variables which are platform dependants.

    If use_distutils == True, use distutils configuration. Otherwise, use
    'sensible' default.

    Any variable already defined is untouched."""

    # We define commands as strings so that we can either execute them using
    # eval (same python for scons and distutils) or by executing them through
    # the shell.
    dist_cfg = {'PYEXTCC': ("sysconfig.get_config_var('CC')", False), 
                'PYEXTCFLAGS': ("sysconfig.get_config_var('CFLAGS')", True), 
                'PYEXTCCSHARED': ("sysconfig.get_config_var('CCSHARED')", False), 
                'PYEXTLINKFLAGS': ("sysconfig.get_config_var('LDFLAGS')", True), 
                'PYEXTLINK': ("sysconfig.get_config_var('LDSHARED')", False), 
                'PYEXTINCPATH': ("sysconfig.get_python_inc()", False), 
                'PYEXTSUFFIX': ("sysconfig.get_config_var('SO')", False)}

    from distutils import sysconfig

    # We set the python path even when not using distutils, because we rarely
    # want to change this, even if not using distutils
    ifnotset(env, 'PYEXTINCPATH', sysconfig.get_python_inc())

    if use_distutils:
        for k, (v, should_split) in dist_cfg.items():
            val = eval(v)
            if should_split:
                val = val.split()
            ifnotset(env, k, val)
    else:
        _set_configuration_nodistutils(env)

def generate(env):
    """Add Builders and construction variables for python extensions to an
    Environment."""

    if not env.has_key('PYEXT_USE_DISTUTILS'):
        env['PYEXT_USE_DISTUTILS'] = False

    # This sets all constructions variables used for pyext builders. 
    set_basic_vars(env)

    set_configuration(env, env['PYEXT_USE_DISTUTILS'])

    # Create the PythonObject builder
    pyobj = createPythonObjectBuilder(env)
    action = SCons.Action.Action("$PYEXTCCCOM", "$PYEXTCCCOMSTR")
    pyobj.add_emitter('.c', SCons.Defaults.SharedObjectEmitter)
    pyobj.add_action('.c', action)

    action = SCons.Action.Action("$PYEXTCXXCOM", "$PYEXTCXXCOMSTR")
    pyobj.add_emitter('$CXXFILESUFFIX', SCons.Defaults.SharedObjectEmitter)
    pyobj.add_action('$CXXFILESUFFIX', action)

    # Create the PythonExtension builder
    createPythonExtensionBuilder(env)

def exists(env):
    try:
        # This is not quite right: if someone defines all variables by himself,
        # it would work without distutils
        from distutils import sysconfig
        return True
    except ImportError:
        return False
