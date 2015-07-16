"""Build a Pyrex file from .pyx source to .so loadable module using
the installed distutils infrastructure. Call:

out_fname = pyx_to_dll("foo.pyx")
"""
import os
import sys

from distutils.dist import Distribution
from distutils.errors import DistutilsArgError, DistutilsError, CCompilerError
from distutils.extension import Extension
from distutils.util import grok_environment_error
try:
    from Cython.Distutils import build_ext
    HAS_CYTHON = True
except ImportError:
    HAS_CYTHON = False

DEBUG = 0

_reloads={}

def pyx_to_dll(filename, ext = None, force_rebuild = 0,
               build_in_temp=False, pyxbuild_dir=None, setup_args={},
               reload_support=False, inplace=False):
    """Compile a PYX file to a DLL and return the name of the generated .so 
       or .dll ."""
    assert os.path.exists(filename), "Could not find %s" % os.path.abspath(filename)

    path, name = os.path.split(os.path.abspath(filename))

    if not ext:
        modname, extension = os.path.splitext(name)
        assert extension in (".pyx", ".py"), extension
        if not HAS_CYTHON:
            filename = filename[:-len(extension)] + '.c'
        ext = Extension(name=modname, sources=[filename])

    if not pyxbuild_dir:
        pyxbuild_dir = os.path.join(path, "_pyxbld")

    package_base_dir = path
    for package_name in ext.name.split('.')[-2::-1]:
        package_base_dir, pname = os.path.split(package_base_dir)
        if pname != package_name:
            # something is wrong - package path doesn't match file path
            package_base_dir = None
            break

    script_args=setup_args.get("script_args",[])
    if DEBUG or "--verbose" in script_args:
        quiet = "--verbose"
    else:
        quiet = "--quiet"
    args = [quiet, "build_ext"]
    if force_rebuild:
        args.append("--force")
    if inplace and package_base_dir:
        args.extend(['--build-lib', package_base_dir])
        if ext.name == '__init__' or ext.name.endswith('.__init__'):
            # package => provide __path__ early
            if not hasattr(ext, 'cython_directives'):
                ext.cython_directives = {'set_initial_path' : 'SOURCEFILE'}
            elif 'set_initial_path' not in ext.cython_directives:
                ext.cython_directives['set_initial_path'] = 'SOURCEFILE'

    if HAS_CYTHON and build_in_temp:
        args.append("--pyrex-c-in-temp")
    sargs = setup_args.copy()
    sargs.update(
        {"script_name": None,
         "script_args": args + script_args} )
    dist = Distribution(sargs)
    if not dist.ext_modules:
        dist.ext_modules = []
    dist.ext_modules.append(ext)
    if HAS_CYTHON:
        dist.cmdclass = {'build_ext': build_ext}
    build = dist.get_command_obj('build')
    build.build_base = pyxbuild_dir

    config_files = dist.find_config_files()
    try: config_files.remove('setup.cfg')
    except ValueError: pass
    dist.parse_config_files(config_files)

    cfgfiles = dist.find_config_files()
    try: cfgfiles.remove('setup.cfg')
    except ValueError: pass
    dist.parse_config_files(cfgfiles)
    try:
        ok = dist.parse_command_line()
    except DistutilsArgError:
        raise

    if DEBUG:
        print("options (after parsing command line):")
        dist.dump_option_dicts()
    assert ok


    try:
        obj_build_ext = dist.get_command_obj("build_ext")
        dist.run_commands()
        so_path = obj_build_ext.get_outputs()[0]
        if obj_build_ext.inplace:
            # Python distutils get_outputs()[ returns a wrong so_path 
            # when --inplace ; see http://bugs.python.org/issue5977
            # workaround:
            so_path = os.path.join(os.path.dirname(filename),
                                   os.path.basename(so_path))
        if reload_support:
            org_path = so_path
            timestamp = os.path.getmtime(org_path)
            global _reloads
            last_timestamp, last_path, count = _reloads.get(org_path, (None,None,0) )
            if last_timestamp == timestamp:
                so_path = last_path
            else:
                basename = os.path.basename(org_path)
                while count < 100:
                    count += 1
                    r_path = os.path.join(obj_build_ext.build_lib,
                                          basename + '.reload%s'%count)
                    try:
                        import shutil # late import / reload_support is: debugging
                        try:
                            # Try to unlink first --- if the .so file
                            # is mmapped by another process,
                            # overwriting its contents corrupts the
                            # loaded image (on Linux) and crashes the
                            # other process. On Windows, unlinking an
                            # open file just fails.
                            if os.path.isfile(r_path):
                                os.unlink(r_path)
                        except OSError:
                            continue
                        shutil.copy2(org_path, r_path)
                        so_path = r_path
                    except IOError:
                        continue
                    break
                else:
                    # used up all 100 slots 
                    raise ImportError("reload count for %s reached maximum"%org_path)
                _reloads[org_path]=(timestamp, so_path, count)
        return so_path
    except KeyboardInterrupt:
        sys.exit(1)
    except (IOError, os.error):
        exc = sys.exc_info()[1]
        error = grok_environment_error(exc)

        if DEBUG:
            sys.stderr.write(error + "\n")
        raise

if __name__=="__main__":
    pyx_to_dll("dummy.pyx")
    import test

