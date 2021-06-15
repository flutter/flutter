#!/usr/bin/python -u
#
# generate a tester program for the API
#
import sys
import os
import string
try:
    import libxml2
except:
    print "libxml2 python bindings not available, skipping testapi.c generation"
    sys.exit(0)

if len(sys.argv) > 1:
    srcPref = sys.argv[1] + '/'
else:
    srcPref = ''

#
# Modules we want to skip in API test
#
skipped_modules = [ "SAX", "xlink", "threads", "globals",
  "xmlmemory", "xmlversion", "xmlexports",
  #deprecated
  "DOCBparser",
]

#
# defines for each module
#
modules_defines = {
    "HTMLparser": "LIBXML_HTML_ENABLED",
    "catalog": "LIBXML_CATALOG_ENABLED",
    "xmlreader": "LIBXML_READER_ENABLED",
    "relaxng": "LIBXML_SCHEMAS_ENABLED",
    "schemasInternals": "LIBXML_SCHEMAS_ENABLED",
    "xmlschemas": "LIBXML_SCHEMAS_ENABLED",
    "xmlschemastypes": "LIBXML_SCHEMAS_ENABLED",
    "xpath": "LIBXML_XPATH_ENABLED",
    "xpathInternals": "LIBXML_XPATH_ENABLED",
    "xinclude": "LIBXML_XINCLUDE_ENABLED",
    "xpointer": "LIBXML_XPTR_ENABLED",
    "xmlregexp" : "LIBXML_REGEXP_ENABLED",
    "xmlautomata" : "LIBXML_AUTOMATA_ENABLED",
    "xmlsave" : "LIBXML_OUTPUT_ENABLED",
    "DOCBparser" : "LIBXML_DOCB_ENABLED",
    "xmlmodule" : "LIBXML_MODULES_ENABLED",
    "pattern" : "LIBXML_PATTERN_ENABLED",
    "schematron" : "LIBXML_SCHEMATRON_ENABLED",
}

#
# defines for specific functions
#
function_defines = {
    "htmlDefaultSAXHandlerInit": "LIBXML_HTML_ENABLED",
    "xmlSAX2EndElement" : "LIBXML_SAX1_ENABLED",
    "xmlSAX2StartElement" : "LIBXML_SAX1_ENABLED",
    "xmlSAXDefaultVersion" : "LIBXML_SAX1_ENABLED",
    "UTF8Toisolat1" : "LIBXML_OUTPUT_ENABLED",
    "xmlCleanupPredefinedEntities": "LIBXML_LEGACY_ENABLED",
    "xmlInitializePredefinedEntities": "LIBXML_LEGACY_ENABLED",
    "xmlSetFeature": "LIBXML_LEGACY_ENABLED",
    "xmlGetFeature": "LIBXML_LEGACY_ENABLED",
    "xmlGetFeaturesList": "LIBXML_LEGACY_ENABLED",
    "xmlIOParseDTD": "LIBXML_VALID_ENABLED",
    "xmlParseDTD": "LIBXML_VALID_ENABLED",
    "xmlParseDoc": "LIBXML_SAX1_ENABLED",
    "xmlParseMemory": "LIBXML_SAX1_ENABLED",
    "xmlRecoverDoc": "LIBXML_SAX1_ENABLED",
    "xmlParseFile": "LIBXML_SAX1_ENABLED",
    "xmlRecoverFile": "LIBXML_SAX1_ENABLED",
    "xmlRecoverMemory": "LIBXML_SAX1_ENABLED",
    "xmlSAXParseFileWithData": "LIBXML_SAX1_ENABLED",
    "xmlSAXParseMemory": "LIBXML_SAX1_ENABLED",
    "xmlSAXUserParseMemory": "LIBXML_SAX1_ENABLED",
    "xmlSAXParseDoc": "LIBXML_SAX1_ENABLED",
    "xmlSAXParseDTD": "LIBXML_SAX1_ENABLED",
    "xmlSAXUserParseFile": "LIBXML_SAX1_ENABLED",
    "xmlParseEntity": "LIBXML_SAX1_ENABLED",
    "xmlParseExternalEntity": "LIBXML_SAX1_ENABLED",
    "xmlSAXParseMemoryWithData": "LIBXML_SAX1_ENABLED",
    "xmlParseBalancedChunkMemory": "LIBXML_SAX1_ENABLED",
    "xmlParseBalancedChunkMemoryRecover": "LIBXML_SAX1_ENABLED",
    "xmlSetupParserForBuffer": "LIBXML_SAX1_ENABLED",
    "xmlStopParser": "LIBXML_PUSH_ENABLED",
    "xmlAttrSerializeTxtContent": "LIBXML_OUTPUT_ENABLED",
    "xmlSAXParseFile": "LIBXML_SAX1_ENABLED",
    "xmlSAXParseEntity": "LIBXML_SAX1_ENABLED",
    "xmlNewTextChild": "LIBXML_TREE_ENABLED",
    "xmlNewDocRawNode": "LIBXML_TREE_ENABLED",
    "xmlNewProp": "LIBXML_TREE_ENABLED",
    "xmlReconciliateNs": "LIBXML_TREE_ENABLED",
    "xmlValidateNCName": "LIBXML_TREE_ENABLED",
    "xmlValidateNMToken": "LIBXML_TREE_ENABLED",
    "xmlValidateName": "LIBXML_TREE_ENABLED",
    "xmlNewChild": "LIBXML_TREE_ENABLED",
    "xmlValidateQName": "LIBXML_TREE_ENABLED",
    "xmlSprintfElementContent": "LIBXML_OUTPUT_ENABLED",
    "xmlValidGetPotentialChildren" : "LIBXML_VALID_ENABLED",
    "xmlValidGetValidElements" : "LIBXML_VALID_ENABLED",
    "docbDefaultSAXHandlerInit" : "LIBXML_DOCB_ENABLED",
    "xmlTextReaderPreservePattern" : "LIBXML_PATTERN_ENABLED",
}

#
# Some functions really need to be skipped for the tests.
#
skipped_functions = [
# block on I/O
"xmlFdRead", "xmlReadFd", "xmlCtxtReadFd",
"htmlFdRead", "htmlReadFd", "htmlCtxtReadFd",
"xmlReaderNewFd", "xmlReaderForFd",
"xmlIORead", "xmlReadIO", "xmlCtxtReadIO",
"htmlIORead", "htmlReadIO", "htmlCtxtReadIO",
"xmlReaderNewIO", "xmlBufferDump", "xmlNanoFTPConnect",
"xmlNanoFTPConnectTo", "xmlNanoHTTPMethod", "xmlNanoHTTPMethodRedir",
# Complex I/O APIs
"xmlCreateIOParserCtxt", "xmlParserInputBufferCreateIO",
"xmlRegisterInputCallbacks", "xmlReaderForIO",
"xmlOutputBufferCreateIO", "xmlRegisterOutputCallbacks",
"xmlSaveToIO", "xmlIOHTTPOpenW",
# library state cleanup, generate false leak informations and other
# troubles, heavillyb tested otherwise.
"xmlCleanupParser", "xmlRelaxNGCleanupTypes", "xmlSetListDoc",
"xmlSetTreeDoc", "xmlUnlinkNode",
# hard to avoid leaks in the tests
"xmlStrcat", "xmlStrncat", "xmlCatalogAddLocal", "xmlNewTextWriterDoc",
"xmlXPathNewValueTree", "xmlXPathWrapString",
# unimplemented
"xmlTextReaderReadInnerXml", "xmlTextReaderReadOuterXml",
"xmlTextReaderReadString",
# destructor
"xmlListDelete", "xmlOutputBufferClose", "xmlNanoFTPClose", "xmlNanoHTTPClose",
# deprecated
"xmlCatalogGetPublic", "xmlCatalogGetSystem", "xmlEncodeEntities",
"xmlNewGlobalNs", "xmlHandleEntity", "xmlNamespaceParseNCName",
"xmlNamespaceParseNSDef", "xmlNamespaceParseQName",
"xmlParseNamespace", "xmlParseQuotedString", "xmlParserHandleReference",
"xmlScanName",
"xmlDecodeEntities", 
# allocators
"xmlMemFree",
# verbosity
"xmlCatalogSetDebug", "xmlShellPrintXPathError", "xmlShellPrintNode",
# Internal functions, no user space should really call them
"xmlParseAttribute", "xmlParseAttributeListDecl", "xmlParseName",
"xmlParseNmtoken", "xmlParseEntityValue", "xmlParseAttValue",
"xmlParseSystemLiteral", "xmlParsePubidLiteral", "xmlParseCharData",
"xmlParseExternalID", "xmlParseComment", "xmlParsePITarget", "xmlParsePI",
"xmlParseNotationDecl", "xmlParseEntityDecl", "xmlParseDefaultDecl",
"xmlParseNotationType", "xmlParseEnumerationType", "xmlParseEnumeratedType",
"xmlParseAttributeType", "xmlParseAttributeListDecl",
"xmlParseElementMixedContentDecl", "xmlParseElementChildrenContentDecl",
"xmlParseElementContentDecl", "xmlParseElementDecl", "xmlParseMarkupDecl",
"xmlParseCharRef", "xmlParseEntityRef", "xmlParseReference",
"xmlParsePEReference", "xmlParseDocTypeDecl", "xmlParseAttribute",
"xmlParseStartTag", "xmlParseEndTag", "xmlParseCDSect", "xmlParseContent",
"xmlParseElement", "xmlParseVersionNum", "xmlParseVersionInfo",
"xmlParseEncName", "xmlParseEncodingDecl", "xmlParseSDDecl",
"xmlParseXMLDecl", "xmlParseTextDecl", "xmlParseMisc",
"xmlParseExternalSubset", "xmlParserHandlePEReference",
"xmlSkipBlankChars",
]

#
# These functions have side effects on the global state
# and hence generate errors on memory allocation tests
#
skipped_memcheck = [ "xmlLoadCatalog", "xmlAddEncodingAlias",
   "xmlSchemaInitTypes", "xmlNanoFTPProxy", "xmlNanoFTPScanProxy",
   "xmlNanoHTTPScanProxy", "xmlResetLastError", "xmlCatalogConvert",
   "xmlCatalogRemove", "xmlLoadCatalogs", "xmlCleanupCharEncodingHandlers",
   "xmlInitCharEncodingHandlers", "xmlCatalogCleanup",
   "xmlSchemaGetBuiltInType",
   "htmlParseFile", "htmlCtxtReadFile", # loads the catalogs
   "xmlTextReaderSchemaValidate", "xmlSchemaCleanupTypes", # initialize the schemas type system
   "xmlCatalogResolve", "xmlIOParseDTD" # loads the catalogs
]

#
# Extra code needed for some test cases
#
extra_pre_call = {
   "xmlSAXUserParseFile": """
#ifdef LIBXML_SAX1_ENABLED
        if (sax == (xmlSAXHandlerPtr)&xmlDefaultSAXHandler) user_data = NULL;
#endif
""",
   "xmlSAXUserParseMemory": """
#ifdef LIBXML_SAX1_ENABLED
        if (sax == (xmlSAXHandlerPtr)&xmlDefaultSAXHandler) user_data = NULL;
#endif
""",
   "xmlParseBalancedChunkMemory": """
#ifdef LIBXML_SAX1_ENABLED
        if (sax == (xmlSAXHandlerPtr)&xmlDefaultSAXHandler) user_data = NULL;
#endif
""",
   "xmlParseBalancedChunkMemoryRecover": """
#ifdef LIBXML_SAX1_ENABLED
        if (sax == (xmlSAXHandlerPtr)&xmlDefaultSAXHandler) user_data = NULL;
#endif
""",
   "xmlParserInputBufferCreateFd":
       "if (fd >= 0) fd = -1;",
}
extra_post_call = {
   "xmlAddChild": 
       "if (ret_val == NULL) { xmlFreeNode(cur) ; cur = NULL ; }",
   "xmlAddEntity":
       "if (ret_val != NULL) { xmlFreeNode(ret_val) ; ret_val = NULL; }",
   "xmlAddChildList": 
       "if (ret_val == NULL) { xmlFreeNodeList(cur) ; cur = NULL ; }",
   "xmlAddSibling":
       "if (ret_val == NULL) { xmlFreeNode(elem) ; elem = NULL ; }",
   "xmlAddNextSibling":
       "if (ret_val == NULL) { xmlFreeNode(elem) ; elem = NULL ; }",
   "xmlAddPrevSibling": 
       "if (ret_val == NULL) { xmlFreeNode(elem) ; elem = NULL ; }",
   "xmlDocSetRootElement": 
       "if (doc == NULL) { xmlFreeNode(root) ; root = NULL ; }",
   "xmlReplaceNode": 
       """if (cur != NULL) {
              xmlUnlinkNode(cur);
              xmlFreeNode(cur) ; cur = NULL ; }
          if (old != NULL) {
              xmlUnlinkNode(old);
              xmlFreeNode(old) ; old = NULL ; }
	  ret_val = NULL;""",
   "xmlTextMerge": 
       """if ((first != NULL) && (first->type != XML_TEXT_NODE)) {
              xmlUnlinkNode(second);
              xmlFreeNode(second) ; second = NULL ; }""",
   "xmlBuildQName": 
       """if ((ret_val != NULL) && (ret_val != ncname) &&
              (ret_val != prefix) && (ret_val != memory))
              xmlFree(ret_val);
	  ret_val = NULL;""",
   "xmlNewDocElementContent":
       """xmlFreeDocElementContent(doc, ret_val); ret_val = NULL;""",
   "xmlDictReference": "xmlDictFree(dict);",
   # Functions which deallocates one of their parameters
   "xmlXPathConvertBoolean": """val = NULL;""",
   "xmlXPathConvertNumber": """val = NULL;""",
   "xmlXPathConvertString": """val = NULL;""",
   "xmlSaveFileTo": """buf = NULL;""",
   "xmlSaveFormatFileTo": """buf = NULL;""",
   "xmlIOParseDTD": "input = NULL;",
   "xmlRemoveProp": "cur = NULL;",
   "xmlNewNs": "if ((node == NULL) && (ret_val != NULL)) xmlFreeNs(ret_val);",
   "xmlCopyNamespace": "if (ret_val != NULL) xmlFreeNs(ret_val);",
   "xmlCopyNamespaceList": "if (ret_val != NULL) xmlFreeNsList(ret_val);",
   "xmlNewTextWriter": "if (ret_val != NULL) out = NULL;",
   "xmlNewTextWriterPushParser": "if (ctxt != NULL) {xmlFreeDoc(ctxt->myDoc); ctxt->myDoc = NULL;} if (ret_val != NULL) ctxt = NULL;",
   "xmlNewIOInputStream": "if (ret_val != NULL) input = NULL;",
   "htmlParseChunk": "if (ctxt != NULL) {xmlFreeDoc(ctxt->myDoc); ctxt->myDoc = NULL;}",
   "htmlParseDocument": "if (ctxt != NULL) {xmlFreeDoc(ctxt->myDoc); ctxt->myDoc = NULL;}",
   "xmlParseDocument": "if (ctxt != NULL) {xmlFreeDoc(ctxt->myDoc); ctxt->myDoc = NULL;}",
   "xmlParseChunk": "if (ctxt != NULL) {xmlFreeDoc(ctxt->myDoc); ctxt->myDoc = NULL;}",
   "xmlParseExtParsedEnt": "if (ctxt != NULL) {xmlFreeDoc(ctxt->myDoc); ctxt->myDoc = NULL;}",
   "xmlDOMWrapAdoptNode": "if ((node != NULL) && (node->parent == NULL)) {xmlUnlinkNode(node);xmlFreeNode(node);node = NULL;}",
   "xmlBufferSetAllocationScheme": "if ((buf != NULL) && (scheme == XML_BUFFER_ALLOC_IMMUTABLE) && (buf->content != NULL) && (buf->content != static_buf_content)) { xmlFree(buf->content); buf->content = NULL;}"
}

modules = []

def is_skipped_module(name):
    for mod in skipped_modules:
        if mod == name:
	    return 1
    return 0

def is_skipped_function(name):
    for fun in skipped_functions:
        if fun == name:
	    return 1
    # Do not test destructors
    if string.find(name, 'Free') != -1:
        return 1
    return 0

def is_skipped_memcheck(name):
    for fun in skipped_memcheck:
        if fun == name:
	    return 1
    return 0

missing_types = {}
def add_missing_type(name, func):
    try:
        list = missing_types[name]
	list.append(func)
    except:
        missing_types[name] = [func]

generated_param_types = []
def add_generated_param_type(name):
    generated_param_types.append(name)

generated_return_types = []
def add_generated_return_type(name):
    generated_return_types.append(name)

missing_functions = {}
missing_functions_nr = 0
def add_missing_functions(name, module):
    global missing_functions_nr

    missing_functions_nr = missing_functions_nr + 1
    try:
        list = missing_functions[module]
	list.append(name)
    except:
        missing_functions[module] = [name]

#
# Provide the type generators and destructors for the parameters
#

def type_convert(str, name, info, module, function, pos):
#    res = string.replace(str, "    ", " ")
#    res = string.replace(str, "   ", " ")
#    res = string.replace(str, "  ", " ")
    res = string.replace(str, " *", "_ptr")
#    res = string.replace(str, "*", "_ptr")
    res = string.replace(res, " ", "_")
    if res == 'const_char_ptr':
        if string.find(name, "file") != -1 or \
           string.find(name, "uri") != -1 or \
           string.find(name, "URI") != -1 or \
           string.find(info, "filename") != -1 or \
           string.find(info, "URI") != -1 or \
           string.find(info, "URL") != -1:
	    if string.find(function, "Save") != -1 or \
	       string.find(function, "Create") != -1 or \
	       string.find(function, "Write") != -1 or \
	       string.find(function, "Fetch") != -1:
	        return('fileoutput')
	    return('filepath')
    if res == 'void_ptr':
        if module == 'nanoftp' and name == 'ctx':
	    return('xmlNanoFTPCtxtPtr')
        if function == 'xmlNanoFTPNewCtxt' or \
	   function == 'xmlNanoFTPConnectTo' or \
	   function == 'xmlNanoFTPOpen':
	    return('xmlNanoFTPCtxtPtr')
        if module == 'nanohttp' and name == 'ctx':
	    return('xmlNanoHTTPCtxtPtr')
	if function == 'xmlNanoHTTPMethod' or \
	   function == 'xmlNanoHTTPMethodRedir' or \
	   function == 'xmlNanoHTTPOpen' or \
	   function == 'xmlNanoHTTPOpenRedir':
	    return('xmlNanoHTTPCtxtPtr');
        if function == 'xmlIOHTTPOpen':
	    return('xmlNanoHTTPCtxtPtr')
	if string.find(name, "data") != -1:
	    return('userdata')
	if string.find(name, "user") != -1:
	    return('userdata')
    if res == 'xmlDoc_ptr':
        res = 'xmlDocPtr'
    if res == 'xmlNode_ptr':
        res = 'xmlNodePtr'
    if res == 'xmlDict_ptr':
        res = 'xmlDictPtr'
    if res == 'xmlNodePtr' and pos != 0:
        if (function == 'xmlAddChild' and pos == 2) or \
	   (function == 'xmlAddChildList' and pos == 2) or \
           (function == 'xmlAddNextSibling' and pos == 2) or \
           (function == 'xmlAddSibling' and pos == 2) or \
           (function == 'xmlDocSetRootElement' and pos == 2) or \
           (function == 'xmlReplaceNode' and pos == 2) or \
           (function == 'xmlTextMerge') or \
	   (function == 'xmlAddPrevSibling' and pos == 2):
	    return('xmlNodePtr_in');
    if res == 'const xmlBufferPtr':
        res = 'xmlBufferPtr'
    if res == 'xmlChar_ptr' and name == 'name' and \
       string.find(function, "EatName") != -1:
        return('eaten_name')
    if res == 'void_ptr*':
        res = 'void_ptr_ptr'
    if res == 'char_ptr*':
        res = 'char_ptr_ptr'
    if res == 'xmlChar_ptr*':
        res = 'xmlChar_ptr_ptr'
    if res == 'const_xmlChar_ptr*':
        res = 'const_xmlChar_ptr_ptr'
    if res == 'const_char_ptr*':
        res = 'const_char_ptr_ptr'
    if res == 'FILE_ptr' and module == 'debugXML':
        res = 'debug_FILE_ptr';
    if res == 'int' and name == 'options':
        if module == 'parser' or module == 'xmlreader':
	    res = 'parseroptions'

    return res

known_param_types = []

def is_known_param_type(name, rtype):
    global test
    for type in known_param_types:
        if type == name:
	    return 1
    for type in generated_param_types:
        if type == name:
	    return 1

    if name[-3:] == 'Ptr' or name[-4:] == '_ptr':
        if rtype[0:6] == 'const ':
	    crtype = rtype[6:]
	else:
	    crtype = rtype

        define = 0
	if modules_defines.has_key(module):
	    test.write("#ifdef %s\n" % (modules_defines[module]))
	    define = 1
        test.write("""
#define gen_nb_%s 1
static %s gen_%s(int no ATTRIBUTE_UNUSED, int nr ATTRIBUTE_UNUSED) {
    return(NULL);
}
static void des_%s(int no ATTRIBUTE_UNUSED, %s val ATTRIBUTE_UNUSED, int nr ATTRIBUTE_UNUSED) {
}
""" % (name, crtype, name, name, rtype))
        if define == 1:
	    test.write("#endif\n\n")
        add_generated_param_type(name)
        return 1

    return 0

#
# Provide the type destructors for the return values
#

known_return_types = []

def is_known_return_type(name):
    for type in known_return_types:
        if type == name:
	    return 1
    return 0

#
# Copy the beginning of the C test program result
#

try:
    input = open("testapi.c", "r")
except:
    input = open(srcPref + "testapi.c", "r")
test = open('testapi.c.new', 'w')

def compare_and_save():
    global test

    test.close()
    try:
        input = open("testapi.c", "r").read()
    except:
        input = ''
    test = open('testapi.c.new', "r").read()
    if input != test:
        try:
            os.system("rm testapi.c; mv testapi.c.new testapi.c")
        except:
	    os.system("mv testapi.c.new testapi.c")
        print("Updated testapi.c")
    else:
        print("Generated testapi.c is identical")

line = input.readline()
while line != "":
    if line == "/* CUT HERE: everything below that line is generated */\n":
        break;
    if line[0:15] == "#define gen_nb_":
        type = string.split(line[15:])[0]
	known_param_types.append(type)
    if line[0:19] == "static void desret_":
        type = string.split(line[19:], '(')[0]
	known_return_types.append(type)
    test.write(line)
    line = input.readline()
input.close()

if line == "":
    print "Could not find the CUT marker in testapi.c skipping generation"
    test.close()
    sys.exit(0)

print("Scanned testapi.c: found %d parameters types and %d return types\n" % (
      len(known_param_types), len(known_return_types)))
test.write("/* CUT HERE: everything below that line is generated */\n")


#
# Open the input API description
#
doc = libxml2.readFile(srcPref + 'doc/libxml2-api.xml', None, 0)
if doc == None:
    print "Failed to load doc/libxml2-api.xml"
    sys.exit(1)
ctxt = doc.xpathNewContext()

#
# Generate a list of all function parameters and select only
# those used in the api tests
#
argtypes = {}
args = ctxt.xpathEval("/api/symbols/function/arg")
for arg in args:
    mod = arg.xpathEval('string(../@file)')
    func = arg.xpathEval('string(../@name)')
    if (mod not in skipped_modules) and (func not in skipped_functions):
	type = arg.xpathEval('string(@type)')
	if not argtypes.has_key(type):
	    argtypes[type] = func

# similarly for return types
rettypes = {}
rets = ctxt.xpathEval("/api/symbols/function/return")
for ret in rets:
    mod = ret.xpathEval('string(../@file)')
    func = ret.xpathEval('string(../@name)')
    if (mod not in skipped_modules) and (func not in skipped_functions):
        type = ret.xpathEval('string(@type)')
	if not rettypes.has_key(type):
	    rettypes[type] = func

#
# Generate constructors and return type handling for all enums
# which are used as function parameters
#
enums = ctxt.xpathEval("/api/symbols/typedef[@type='enum']")
for enum in enums:
    module = enum.xpathEval('string(@file)')
    name = enum.xpathEval('string(@name)')
    #
    # Skip any enums which are not in our filtered lists
    #
    if (name == None) or ((name not in argtypes) and (name not in rettypes)):
        continue;
    define = 0

    if argtypes.has_key(name) and is_known_param_type(name, name) == 0:
	values = ctxt.xpathEval("/api/symbols/enum[@type='%s']" % name)
	i = 0
	vals = []
	for value in values:
	    vname = value.xpathEval('string(@name)')
	    if vname == None:
		continue;
	    i = i + 1
	    if i >= 5:
		break;
	    vals.append(vname)
	if vals == []:
	    print "Didn't find any value for enum %s" % (name)
	    continue
	if modules_defines.has_key(module):
	    test.write("#ifdef %s\n" % (modules_defines[module]))
	    define = 1
	test.write("#define gen_nb_%s %d\n" % (name, len(vals)))
	test.write("""static %s gen_%s(int no, int nr ATTRIBUTE_UNUSED) {\n""" %
	           (name, name))
	i = 1
	for value in vals:
	    test.write("    if (no == %d) return(%s);\n" % (i, value))
	    i = i + 1
	test.write("""    return(0);
}

static void des_%s(int no ATTRIBUTE_UNUSED, %s val ATTRIBUTE_UNUSED, int nr ATTRIBUTE_UNUSED) {
}

""" % (name, name));
	known_param_types.append(name)

    if (is_known_return_type(name) == 0) and (name in rettypes):
	if define == 0 and modules_defines.has_key(module):
	    test.write("#ifdef %s\n" % (modules_defines[module]))
	    define = 1
        test.write("""static void desret_%s(%s val ATTRIBUTE_UNUSED) {
}

""" % (name, name))
	known_return_types.append(name)
    if define == 1:
        test.write("#endif\n\n")

#
# Load the interfaces
# 
headers = ctxt.xpathEval("/api/files/file")
for file in headers:
    name = file.xpathEval('string(@name)')
    if (name == None) or (name == ''):
        continue

    #
    # Some module may be skipped because they don't really consists
    # of user callable APIs
    #
    if is_skipped_module(name):
        continue

    #
    # do not test deprecated APIs
    #
    desc = file.xpathEval('string(description)')
    if string.find(desc, 'DEPRECATED') != -1:
        print "Skipping deprecated interface %s" % name
	continue;

    test.write("#include <libxml/%s.h>\n" % name)
    modules.append(name)
        
#
# Generate the callers signatures
# 
for module in modules:
    test.write("static int test_%s(void);\n" % module);

#
# Generate the top caller
# 

test.write("""
/**
 * testlibxml2:
 *
 * Main entry point of the tester for the full libxml2 module,
 * it calls all the tester entry point for each module.
 *
 * Returns the number of error found
 */
static int
testlibxml2(void)
{
    int test_ret = 0;

""")

for module in modules:
    test.write("    test_ret += test_%s();\n" % module)

test.write("""
    printf("Total: %d functions, %d tests, %d errors\\n",
           function_tests, call_tests, test_ret);
    return(test_ret);
}

""")

#
# How to handle a function
# 
nb_tests = 0

def generate_test(module, node):
    global test
    global nb_tests
    nb_cond = 0
    no_gen = 0

    name = node.xpathEval('string(@name)')
    if is_skipped_function(name):
        return

    #
    # check we know how to handle the args and return values
    # and store the informations for the generation
    #
    try:
	args = node.xpathEval("arg")
    except:
        args = []
    t_args = []
    n = 0
    for arg in args:
        n = n + 1
        rtype = arg.xpathEval("string(@type)")
	if rtype == 'void':
	    break;
	info = arg.xpathEval("string(@info)")
	nam = arg.xpathEval("string(@name)")
        type = type_convert(rtype, nam, info, module, name, n)
	if is_known_param_type(type, rtype) == 0:
	    add_missing_type(type, name);
	    no_gen = 1
        if (type[-3:] == 'Ptr' or type[-4:] == '_ptr') and \
	    rtype[0:6] == 'const ':
	    crtype = rtype[6:]
	else:
	    crtype = rtype
	t_args.append((nam, type, rtype, crtype, info))
    
    try:
	rets = node.xpathEval("return")
    except:
        rets = []
    t_ret = None
    for ret in rets:
        rtype = ret.xpathEval("string(@type)")
	info = ret.xpathEval("string(@info)")
        type = type_convert(rtype, 'return', info, module, name, 0)
	if rtype == 'void':
	    break
	if is_known_return_type(type) == 0:
	    add_missing_type(type, name);
	    no_gen = 1
	t_ret = (type, rtype, info)
	break

    test.write("""
static int
test_%s(void) {
    int test_ret = 0;

""" % (name))

    if no_gen == 1:
        add_missing_functions(name, module)
	test.write("""
    /* missing type support */
    return(test_ret);
}

""")
        return

    try:
	conds = node.xpathEval("cond")
	for cond in conds:
	    test.write("#if %s\n" % (cond.get_content()))
	    nb_cond = nb_cond + 1
    except:
        pass

    define = 0
    if function_defines.has_key(name):
        test.write("#ifdef %s\n" % (function_defines[name]))
	define = 1
    
    # Declare the memory usage counter
    no_mem = is_skipped_memcheck(name)
    if no_mem == 0:
	test.write("    int mem_base;\n");

    # Declare the return value
    if t_ret != None:
        test.write("    %s ret_val;\n" % (t_ret[1]))

    # Declare the arguments
    for arg in t_args:
        (nam, type, rtype, crtype, info) = arg;
	# add declaration
	test.write("    %s %s; /* %s */\n" % (crtype, nam, info))
	test.write("    int n_%s;\n" % (nam))
    test.write("\n")

    # Cascade loop on of each argument list of values
    for arg in t_args:
        (nam, type, rtype, crtype, info) = arg;
	#
	test.write("    for (n_%s = 0;n_%s < gen_nb_%s;n_%s++) {\n" % (
	           nam, nam, type, nam))
    
    # log the memory usage
    if no_mem == 0:
	test.write("        mem_base = xmlMemBlocks();\n");

    # prepare the call
    i = 0;
    for arg in t_args:
        (nam, type, rtype, crtype, info) = arg;
	#
	test.write("        %s = gen_%s(n_%s, %d);\n" % (nam, type, nam, i))
	i = i + 1;

    # do the call, and clanup the result
    if extra_pre_call.has_key(name):
	test.write("        %s\n"% (extra_pre_call[name]))
    if t_ret != None:
	test.write("\n        ret_val = %s(" % (name))
	need = 0
	for arg in t_args:
	    (nam, type, rtype, crtype, info) = arg
	    if need:
	        test.write(", ")
	    else:
	        need = 1
	    if rtype != crtype:
	        test.write("(%s)" % rtype)
	    test.write("%s" % nam);
	test.write(");\n")
	if extra_post_call.has_key(name):
	    test.write("        %s\n"% (extra_post_call[name]))
	test.write("        desret_%s(ret_val);\n" % t_ret[0])
    else:
	test.write("\n        %s(" % (name));
	need = 0;
	for arg in t_args:
	    (nam, type, rtype, crtype, info) = arg;
	    if need:
	        test.write(", ")
	    else:
	        need = 1
	    if rtype != crtype:
	        test.write("(%s)" % rtype)
	    test.write("%s" % nam)
	test.write(");\n")
	if extra_post_call.has_key(name):
	    test.write("        %s\n"% (extra_post_call[name]))

    test.write("        call_tests++;\n");

    # Free the arguments
    i = 0;
    for arg in t_args:
        (nam, type, rtype, crtype, info) = arg;
	# This is a hack to prevent generating a destructor for the
	# 'input' argument in xmlTextReaderSetup.  There should be
	# a better, more generic way to do this!
	if string.find(info, 'destroy') == -1:
	    test.write("        des_%s(n_%s, " % (type, nam))
	    if rtype != crtype:
	        test.write("(%s)" % rtype)
	    test.write("%s, %d);\n" % (nam, i))
	i = i + 1;

    test.write("        xmlResetLastError();\n");
    # Check the memory usage
    if no_mem == 0:
	test.write("""        if (mem_base != xmlMemBlocks()) {
            printf("Leak of %%d blocks found in %s",
	           xmlMemBlocks() - mem_base);
	    test_ret++;
""" % (name));
	for arg in t_args:
	    (nam, type, rtype, crtype, info) = arg;
	    test.write("""            printf(" %%d", n_%s);\n""" % (nam))
	test.write("""            printf("\\n");\n""")
	test.write("        }\n")

    for arg in t_args:
	test.write("    }\n")

    test.write("    function_tests++;\n")
    #
    # end of conditional
    #
    while nb_cond > 0:
        test.write("#endif\n")
	nb_cond = nb_cond -1
    if define == 1:
        test.write("#endif\n")

    nb_tests = nb_tests + 1;

    test.write("""
    return(test_ret);
}

""")
    
#
# Generate all module callers
#
for module in modules:
    # gather all the functions exported by that module
    try:
	functions = ctxt.xpathEval("/api/symbols/function[@file='%s']" % (module))
    except:
        print "Failed to gather functions from module %s" % (module)
	continue;

    # iterate over all functions in the module generating the test
    i = 0
    nb_tests_old = nb_tests
    for function in functions:
        i = i + 1
        generate_test(module, function);

    # header
    test.write("""static int
test_%s(void) {
    int test_ret = 0;

    if (quiet == 0) printf("Testing %s : %d of %d functions ...\\n");
""" % (module, module, nb_tests - nb_tests_old, i))

    # iterate over all functions in the module generating the call
    for function in functions:
        name = function.xpathEval('string(@name)')
	if is_skipped_function(name):
	    continue
	test.write("    test_ret += test_%s();\n" % (name))

    # footer
    test.write("""
    if (test_ret != 0)
	printf("Module %s: %%d errors\\n", test_ret);
    return(test_ret);
}
""" % (module))

#
# Generate direct module caller
#
test.write("""static int
test_module(const char *module) {
""");
for module in modules:
    test.write("""    if (!strcmp(module, "%s")) return(test_%s());\n""" % (
        module, module))
test.write("""    return(0);
}
""");

print "Generated test for %d modules and %d functions" %(len(modules), nb_tests)

compare_and_save()

missing_list = []
for missing in missing_types.keys():
    if missing == 'va_list' or missing == '...':
        continue;

    n = len(missing_types[missing])
    missing_list.append((n, missing))

def compare_missing(a, b):
    return b[0] - a[0]

missing_list.sort(compare_missing)
print "Missing support for %d functions and %d types see missing.lst" % (missing_functions_nr, len(missing_list))
lst = open("missing.lst", "w")
lst.write("Missing support for %d types" % (len(missing_list)))
lst.write("\n")
for miss in missing_list:
    lst.write("%s: %d :" % (miss[1], miss[0]))
    i = 0
    for n in missing_types[miss[1]]:
        i = i + 1
        if i > 5:
	    lst.write(" ...")
	    break
	lst.write(" %s" % (n))
    lst.write("\n")
lst.write("\n")
lst.write("\n")
lst.write("Missing support per module");
for module in missing_functions.keys():
    lst.write("module %s:\n   %s\n" % (module, missing_functions[module]))

lst.close()


