########## TestClass ##########
# These utilities are for testing purposes

cdef extern from *:
    cdef object __pyx_test_dep(object)

@cname('__pyx_TestClass')
cdef class TestClass(object):
    cdef public int value

    def __init__(self, int value):
        self.value = value

    def __str__(self):
        return 'TestClass(%d)' % self.value

    cdef cdef_method(self, int value):
        print 'Hello from cdef_method', value

    cpdef cpdef_method(self, int value):
        print 'Hello from cpdef_method', value

    def def_method(self, int value):
        print 'Hello from def_method', value

    @cname('cdef_cname')
    cdef cdef_cname_method(self, int value):
        print "Hello from cdef_cname_method", value

    @cname('cpdef_cname')
    cpdef cpdef_cname_method(self, int value):
        print "Hello from cpdef_cname_method", value

    @cname('def_cname')
    def def_cname_method(self, int value):
        print "Hello from def_cname_method", value

@cname('__pyx_test_call_other_cy_util')
cdef test_call(obj):
    print 'test_call'
    __pyx_test_dep(obj)

@cname('__pyx_TestClass_New')
cdef _testclass_new(int value):
    return TestClass(value)

########### TestDep ##########

@cname('__pyx_test_dep')
cdef test_dep(obj):
    print 'test_dep', obj

########## TestScope ##########

@cname('__pyx_testscope')
cdef object _testscope(int value):
    return "hello from cython scope, value=%d" % value

########## View.TestScope ##########

@cname('__pyx_view_testscope')
cdef object _testscope(int value):
    return "hello from cython.view scope, value=%d" % value

