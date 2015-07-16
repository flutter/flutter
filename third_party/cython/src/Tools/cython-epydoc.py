#! /usr/bin/env python

# --------------------------------------------------------------------

import re
from epydoc import docstringparser as dsp

CYTHON_SIGNATURE_RE = re.compile(
    # Class name (for builtin methods)
    r'^\s*((?P<class>\w+)\.)?' +
    # The function name
    r'(?P<func>\w+)' +
    # The parameters
    r'\(((?P<self>(?:self|cls|mcs)),?)?(?P<params>.*)\)' +
    # The return value (optional)
    r'(\s*(->)\s*(?P<return>\w+(?:\s*\w+)))?' +
    # The end marker
    r'\s*(?:\n|$)')

parse_signature = dsp.parse_function_signature

def parse_function_signature(func_doc, doc_source,
                             docformat, parse_errors):
    PYTHON_SIGNATURE_RE = dsp._SIGNATURE_RE
    assert PYTHON_SIGNATURE_RE is not CYTHON_SIGNATURE_RE
    try:
        dsp._SIGNATURE_RE = CYTHON_SIGNATURE_RE
        found = parse_signature(func_doc, doc_source,
                                docformat, parse_errors)
        dsp._SIGNATURE_RE = PYTHON_SIGNATURE_RE
        if not found:
            found = parse_signature(func_doc, doc_source,
                                    docformat, parse_errors)
        return found
    finally:
        dsp._SIGNATURE_RE = PYTHON_SIGNATURE_RE

dsp.parse_function_signature = parse_function_signature

# --------------------------------------------------------------------

from epydoc.cli import cli
cli()

# --------------------------------------------------------------------
