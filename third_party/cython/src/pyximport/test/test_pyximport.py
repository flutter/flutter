import pyximport; pyximport.install(reload_support=True)
import os, sys
import time, shutil
import tempfile

def make_tempdir():
    tempdir = os.path.join(tempfile.gettempdir(), "pyrex_temp")
    if os.path.exists(tempdir):
        remove_tempdir(tempdir)

    os.mkdir(tempdir)
    return tempdir

def remove_tempdir(tempdir):
    shutil.rmtree(tempdir, 0, on_remove_file_error)

def on_remove_file_error(func, path, excinfo):
    print "Sorry! Could not remove a temp file:", path
    print "Extra information."
    print func, excinfo
    print "You may want to delete this yourself when you get a chance."

def test():
    pyximport._test_files = []
    tempdir = make_tempdir()
    sys.path.append(tempdir)
    filename = os.path.join(tempdir, "dummy.pyx")
    open(filename, "w").write("print 'Hello world from the Pyrex install hook'")
    import dummy
    reload(dummy)

    depend_filename = os.path.join(tempdir, "dummy.pyxdep")
    depend_file = open(depend_filename, "w")
    depend_file.write("*.txt\nfoo.bar")
    depend_file.close()

    build_filename = os.path.join(tempdir, "dummy.pyxbld")
    build_file = open(build_filename, "w")
    build_file.write("""
from distutils.extension import Extension
def make_ext(name, filename):
    return Extension(name=name, sources=[filename]) 
""")
    build_file.close()

    open(os.path.join(tempdir, "foo.bar"), "w").write(" ")
    open(os.path.join(tempdir, "1.txt"), "w").write(" ")
    open(os.path.join(tempdir, "abc.txt"), "w").write(" ")
    reload(dummy)
    assert len(pyximport._test_files)==1, pyximport._test_files
    reload(dummy)

    time.sleep(1) # sleep a second to get safer mtimes
    open(os.path.join(tempdir, "abc.txt"), "w").write(" ")
    print "Here goes the reolad"
    reload(dummy)
    assert len(pyximport._test_files) == 1, pyximport._test_files

    reload(dummy)
    assert len(pyximport._test_files) ==0, pyximport._test_files
    remove_tempdir(tempdir)

if __name__=="__main__":
    test()

