from __future__ import with_statement

import os
import sys
import errno

try:
  from lxml import etree
  have_lxml = True
except ImportError:
    have_lxml = False
    try:
        # Python 2.5
        from xml.etree import cElementTree as etree
    except ImportError:
        try:
            # Python 2.5
            from xml.etree import ElementTree as etree
        except ImportError:
            try:
                # normal cElementTree install
                import cElementTree as etree
            except ImportError:
                try:
                    # normal ElementTree install
                    import elementtree.ElementTree as etree
                except ImportError:
                    etree = None

from Cython.Compiler import Errors


class CythonDebugWriter(object):
    """
    Class to output debugging information for cygdb

    It writes debug information to cython_debug/cython_debug_info_<modulename>
    in the build directory.
    """

    def __init__(self, output_dir):
        if etree is None:
            raise Errors.NoElementTreeInstalledException()

        self.output_dir = os.path.join(output_dir, 'cython_debug')
        self.tb = etree.TreeBuilder()
        # set by Cython.Compiler.ParseTreeTransforms.DebugTransform
        self.module_name = None
        self.start('cython_debug', attrs=dict(version='1.0'))

    def start(self, name, attrs=None):
        self.tb.start(name, attrs or {})

    def end(self, name):
        self.tb.end(name)

    def serialize(self):
        self.tb.end('Module')
        self.tb.end('cython_debug')
        xml_root_element = self.tb.close()

        try:
            os.makedirs(self.output_dir)
        except OSError, e:
            if e.errno != errno.EEXIST:
                raise

        et = etree.ElementTree(xml_root_element)
        kw = {}
        if have_lxml:
            kw['pretty_print'] = True

        fn = "cython_debug_info_" + self.module_name
        et.write(os.path.join(self.output_dir, fn), encoding="UTF-8", **kw)

        interpreter_path = os.path.join(self.output_dir, 'interpreter')
        with open(interpreter_path, 'w') as f:
            f.write(sys.executable)
