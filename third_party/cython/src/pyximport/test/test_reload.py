# reload seems to work for Python 2.3 but not 2.2. 
import time, os, sys
import test_pyximport

# debugging the 2.2 problem
if 1:
    from distutils import sysconfig
    try:
        sysconfig.set_python_build()
    except AttributeError:
        pass
    import pyxbuild
    print pyxbuild.distutils.sysconfig == sysconfig

def test():
    tempdir = test_pyximport.make_tempdir()
    sys.path.append(tempdir)
    hello_file = os.path.join(tempdir, "hello.pyx")
    open(hello_file, "w").write("x = 1; print x; before = 'before'\n")
    import hello
        assert hello.x == 1

    time.sleep(1) # sleep to make sure that new "hello.pyx" has later
              # timestamp than object file.

    open(hello_file, "w").write("x = 2; print x; after = 'after'\n")
    reload(hello)
    assert hello.x == 2, "Reload should work on Python 2.3 but not 2.2"
    test_pyximport.remove_tempdir(tempdir)

if __name__=="__main__":
    test()

