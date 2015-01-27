# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# This python script creates string literals in a C++ source file from a C++
# source template and one or more resource files.

import os
import sys
from os.path import join
import time
from optparse import OptionParser
import re
from datetime import date


def makeResources(root_dir, input_files):
    result = ''
    resources = []

    # Write each file's contents as a byte string constant.
    for resource_file in input_files:
        if root_dir and resource_file.startswith(root_dir):
            resource_file_name = resource_file[len(root_dir):]
        else:
            resource_file_name = resource_file
        resource_url = '/%s' % resource_file_name
        result += '// %s\n' % resource_file
        result += 'const char '
        resource_name = re.sub(r'(/|\.|-)', '_', resource_file_name) + '_'
        result += resource_name
        result += '[] = {\n   '
        fileHandle = open(resource_file, 'rb')
        lineCounter = 0
        for byte in fileHandle.read():
            result += r" '\x%02x'," % ord(byte)
            lineCounter += 1
            if lineCounter == 10:
                result += '\n   '
                lineCounter = 0
        if lineCounter != 0:
            result += '\n   '
        result += ' 0\n};\n\n'
        resources.append(
            (resource_url, resource_name, os.stat(resource_file).st_size))

    # Write the resource table.
    result += 'Resources::resource_map_entry Resources::builtin_resources_[] = '
    result += '{\n'
    for res in resources:
        result += '   { "%s", %s, %d },\n' % res
    result += '};\n\n'
    result += 'const intptr_t Resources::builtin_resources_count_ '
    result += '= %d;\n' % len(resources)
    return result


def makeFile(output_file, root_dir, input_files):
    cc_text = '''
// Copyright (c) %d, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

''' % date.today().year
    cc_text += '#if defined(new)\n'
    cc_text += '#undef new\n'
    cc_text += '#endif\n\n'
    cc_text += '#if defined(delete)\n'
    cc_text += '#undef delete\n'
    cc_text += '#endif\n\n'
    cc_text += '#ifndef NDEBUG\n'
    cc_text += '#define DEBUG\n'
    cc_text += '#endif\n'
    cc_text += '#include "bin/resources.h"\n\n'
    cc_text += 'namespace dart {\n'
    cc_text += 'namespace bin {\n'
    cc_text += makeResources(root_dir, input_files)
    cc_text += '}  // namespace bin\n} // namespace dart\n'
    open(output_file, 'w').write(cc_text)
    return True


def main(args):
    try:
        # Parse input.
        parser = OptionParser()
        parser.add_option("--output",
                          action="store", type="string",
                          help="output file name")
        parser.add_option("--root_prefix",
                          action="store", type="string",
                          help="root directory for resources")
        (options, args) = parser.parse_args()
        if not options.output:
            sys.stderr.write('--output not specified\n')
            return -1
        if len(args) == 0:
            sys.stderr.write('No input files specified\n')
            return -1

        files = []
        for arg in args:
            files.append(arg)

        if not makeFile(options.output, options.root_prefix, files):
            return -1

        return 0
    except Exception, inst:
        sys.stderr.write('create_resources.py exception\n')
        sys.stderr.write(str(inst))
        sys.stderr.write('\n')
        return -1

if __name__ == '__main__':
    sys.exit(main(sys.argv))
