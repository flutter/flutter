/* Configure script for libxml, specific for Windows with Scripting Host.
 * 
 * This script will configure the libxml build process and create necessary files.
 * Run it with an 'help', or an invalid option and it will tell you what options
 * it accepts.
 *
 * March 2002, Igor Zlatkovic <igor@zlatkovic.com>
 */

/* The source directory, relative to the one where this file resides. */
var srcDirXml = "..";
var srcDirUtils = "..";
/* Base name of what we are building. */
var baseName = "libxml2";
/* Configure file which contains the version and the output file where
   we can store our build configuration. */
var configFile = srcDirXml + "\\configure.in";
var versionFile = ".\\config.msvc";
/* Input and output files regarding the libxml features. */
var optsFileIn = srcDirXml + "\\include\\libxml\\xmlversion.h.in";
var optsFile = srcDirXml + "\\include\\libxml\\xmlversion.h";
/* Version strings for the binary distribution. Will be filled later 
   in the code. */
var verMajor;
var verMinor;
var verMicro;
var verMicroSuffix;
var verCvs;
var useCvsVer = true;
/* Libxml features. */
var withTrio = false;
var withThreads = "native";
var withFtp = true;
var withHttp = true;
var withHtml = true;
var withC14n = true;
var withCatalog = true;
var withDocb = true;
var withXpath = true;
var withXptr = true;
var withXinclude = true;
var withIconv = true;
var withIcu = false;
var withIso8859x = false;
var withZlib = false;
var withLzma = false;
var withDebug = true;
var withMemDebug = false;
var withRunDebug = false;
var withSchemas = true;
var withSchematron = true;
var withRegExps = true;
var withModules = true;
var withTree = true;
var withReader = true;
var withWriter = true;
var withWalker = true;
var withPattern = true;
var withPush = true;
var withValid = true;
var withSax1 = true;
var withLegacy = true;
var withOutput = true;
var withPython = false;
/* Win32 build options. */
var dirSep = "\\";
var compiler = "msvc";
var cruntime = "/MD";
var dynruntime = true;
var vcmanifest = false;
var buildDebug = 0;
var buildStatic = 0;
var buildPrefix = ".";
var buildBinPrefix = "";
var buildIncPrefix = "";
var buildLibPrefix = "";
var buildSoPrefix = "";
var buildInclude = ".";
var buildLib = ".";
/* Local stuff */
var error = 0;

/* Helper function, transforms the option variable into the 'Enabled'
   or 'Disabled' string. */
function boolToStr(opt)
{
	if (opt == false)
		return "no";
	else if (opt == true)
		return "yes";
	error = 1;
	return "*** undefined ***";
}

/* Helper function, transforms the argument string into a boolean
   value. */
function strToBool(opt)
{
	if (opt == 0 || opt == "no")
		return false;
	else if (opt == 1 || opt == "yes")
		return true;
	error = 1;
	return false;
}

/* Displays the details about how to use this script. */
function usage()
{
	var txt;
	txt = "Usage:\n";
	txt += "  cscript " + WScript.ScriptName + " <options>\n";
	txt += "  cscript " + WScript.ScriptName + " help\n\n";
	txt += "Options can be specified in the form <option>=<value>, where the value is\n";
	txt += "either 'yes' or 'no', if not stated otherwise.\n\n";
	txt += "\nXML processor options, default value given in parentheses:\n\n";
	txt += "  trio:       Enable TRIO string manipulator (" + (withTrio? "yes" : "no")  + ")\n";
	txt += "  threads:    Enable thread safety [no|ctls|native|posix] (" + (withThreads)  + ") \n";
	txt += "  ftp:        Enable FTP client (" + (withFtp? "yes" : "no")  + ")\n";
	txt += "  http:       Enable HTTP client (" + (withHttp? "yes" : "no")  + ")\n";
	txt += "  html:       Enable HTML processor (" + (withHtml? "yes" : "no")  + ")\n";
	txt += "  c14n:       Enable C14N support (" + (withC14n? "yes" : "no")  + ")\n";
	txt += "  catalog:    Enable catalog support (" + (withCatalog? "yes" : "no")  + ")\n";
	txt += "  docb:       Enable DocBook support (" + (withDocb? "yes" : "no")  + ")\n";
	txt += "  xpath:      Enable XPath support (" + (withXpath? "yes" : "no")  + ")\n";
	txt += "  xptr:       Enable XPointer support (" + (withXptr? "yes" : "no")  + ")\n";
	txt += "  xinclude:   Enable XInclude support (" + (withXinclude? "yes" : "no")  + ")\n";
	txt += "  iconv:      Enable iconv support (" + (withIconv? "yes" : "no")  + ")\n";
	txt += "  icu:        Enable icu support (" + (withIcu? "yes" : "no")  + ")\n";
	txt += "  iso8859x:   Enable ISO8859X support (" + (withIso8859x? "yes" : "no")  + ")\n";
	txt += "  zlib:       Enable zlib support (" + (withZlib? "yes" : "no")  + ")\n";
	txt += "  lzma:       Enable lzma support (" + (withLzma? "yes" : "no")  + ")\n";
	txt += "  xml_debug:  Enable XML debbugging module (" + (withDebug? "yes" : "no")  + ")\n";
	txt += "  mem_debug:  Enable memory debugger (" + (withMemDebug? "yes" : "no")  + ")\n";
	txt += "  run_debug:  Enable memory debugger (" + (withRunDebug? "yes" : "no")  + ")\n";
	txt += "  regexps:    Enable regular expressions (" + (withRegExps? "yes" : "no") + ")\n";
	txt += "  modules:    Enable module support (" + (withModules? "yes" : "no") + ")\n";
	txt += "  tree:       Enable tree api (" + (withTree? "yes" : "no") + ")\n";
	txt += "  reader:     Enable xmlReader api (" + (withReader? "yes" : "no") + ")\n";
	txt += "  writer:     Enable xmlWriter api (" + (withWriter? "yes" : "no") + ")\n";
	txt += "  walker:     Enable xmlDocWalker api (" + (withWalker? "yes" : "no") + ")\n";
	txt += "  pattern:    Enable xmlPattern api (" + (withPattern? "yes" : "no")  + ")\n";
	txt += "  push:       Enable push api (" + (withPush? "yes" : "no") + ")\n";
	txt += "  valid:      Enable DTD validation support (" + (withValid? "yes" : "no") + ")\n";
	txt += "  sax1:       Enable SAX1 api (" + (withSax1? "yes" : "no") + ")\n";
	txt += "  legacy:     Enable Deprecated api's (" + (withLegacy? "yes" : "no") + ")\n";
	txt += "  output:     Enable serialization support (" + (withOutput? "yes" : "no") + ")\n";
	txt += "  schemas:    Enable XML Schema support (" + (withSchemas? "yes" : "no")  + ")\n";
	txt += "  schematron: Enable Schematron support (" + (withSchematron? "yes" : "no")  + ")\n";
	txt += "  python:     Build Python bindings (" + (withPython? "yes" : "no")  + ")\n";
	txt += "\nWin32 build options, default value given in parentheses:\n\n";
	txt += "  compiler:   Compiler to be used [msvc|mingw|bcb] (" + compiler + ")\n";
	txt += "  cruntime:   C-runtime compiler option (only msvc) (" + cruntime + ")\n";
	txt += "  dynruntime: Use the dynamic RTL (only bcb) (" + dynruntime + ")\n";
	txt += "  vcmanifest: Embed VC manifest (only msvc) (" + (vcmanifest? "yes" : "no") + ")\n";
	txt += "  debug:      Build unoptimised debug executables (" + (buildDebug? "yes" : "no")  + ")\n";
	txt += "  static:     Link xmllint statically to libxml2 (" + (buildStatic? "yes" : "no")  + ")\n";
	txt += "              Note: automatically enabled if cruntime is not /MD or /MDd\n";
	txt += "  prefix:     Base directory for the installation (" + buildPrefix + ")\n";
	txt += "  bindir:     Directory where xmllint and friends should be installed\n";
	txt += "              (" + buildBinPrefix + ")\n";
	txt += "  incdir:     Directory where headers should be installed\n";
	txt += "              (" + buildIncPrefix + ")\n";
	txt += "  libdir:     Directory where static and import libraries should be\n";
	txt += "              installed (" + buildLibPrefix + ")\n";
	txt += "  sodir:      Directory where shared libraries should be installed\n"; 
	txt += "              (" + buildSoPrefix + ")\n";
	txt += "  include:    Additional search path for the compiler, particularily\n";
	txt += "              where iconv headers can be found (" + buildInclude + ")\n";
	txt += "  lib:        Additional search path for the linker, particularily\n";
	txt += "              where iconv library can be found (" + buildLib + ")\n";
	WScript.Echo(txt);
}

/* Discovers the version we are working with by reading the apropriate
   configuration file. Despite its name, this also writes the configuration
   file included by our makefile. */
function discoverVersion()
{
	var fso, cf, vf, ln, s, iDot, iSlash;
	fso = new ActiveXObject("Scripting.FileSystemObject");
	verCvs = "";
	if (useCvsVer && fso.FileExists("..\\CVS\\Entries")) {
		cf = fso.OpenTextFile("..\\CVS\\Entries", 1);
		while (cf.AtEndOfStream != true) {
			ln = cf.ReadLine();
			s = new String(ln);
			if (s.search(/^\/ChangeLog\//) != -1) {
				iDot = s.indexOf(".");
				iSlash = s.indexOf("/", iDot);
				verCvs = "CVS" + s.substring(iDot + 1, iSlash);
				break;
			}
		}
		cf.Close();
	}
	cf = fso.OpenTextFile(configFile, 1);
	if (compiler == "msvc")
		versionFile = ".\\config.msvc";
	else if (compiler == "mingw")
		versionFile = ".\\config.mingw";
	else if (compiler == "bcb")
		versionFile = ".\\config.bcb";
	vf = fso.CreateTextFile(versionFile, true);
	vf.WriteLine("# " + versionFile);
	vf.WriteLine("# This file is generated automatically by " + WScript.ScriptName + ".");
	vf.WriteBlankLines(1);
	while (cf.AtEndOfStream != true) {
		ln = cf.ReadLine();
		s = new String(ln);
		if (s.search(/^LIBXML_MAJOR_VERSION=/) != -1) {
			vf.WriteLine(s);
			verMajor = s.substring(s.indexOf("=") + 1, s.length)
		} else if(s.search(/^LIBXML_MINOR_VERSION=/) != -1) {
			vf.WriteLine(s);
			verMinor = s.substring(s.indexOf("=") + 1, s.length)
		} else if(s.search(/^LIBXML_MICRO_VERSION=/) != -1) {
			vf.WriteLine(s);
			verMicro = s.substring(s.indexOf("=") + 1, s.length)
		} else if(s.search(/^LIBXML_MICRO_VERSION_SUFFIX=/) != -1) {
			vf.WriteLine(s);
			verMicroSuffix = s.substring(s.indexOf("=") + 1, s.length)
		}
	}
	cf.Close();
	vf.WriteLine("XML_SRCDIR=" + srcDirXml);
	vf.WriteLine("UTILS_SRCDIR=" + srcDirUtils);
	vf.WriteLine("WITH_TRIO=" + (withTrio? "1" : "0"));
	vf.WriteLine("WITH_THREADS=" + withThreads);
	vf.WriteLine("WITH_FTP=" + (withFtp? "1" : "0"));
	vf.WriteLine("WITH_HTTP=" + (withHttp? "1" : "0"));
	vf.WriteLine("WITH_HTML=" + (withHtml? "1" : "0"));
	vf.WriteLine("WITH_C14N=" + (withC14n? "1" : "0"));
	vf.WriteLine("WITH_CATALOG=" + (withCatalog? "1" : "0"));
	vf.WriteLine("WITH_DOCB=" + (withDocb? "1" : "0"));
	vf.WriteLine("WITH_XPATH=" + (withXpath? "1" : "0"));
	vf.WriteLine("WITH_XPTR=" + (withXptr? "1" : "0"));
	vf.WriteLine("WITH_XINCLUDE=" + (withXinclude? "1" : "0"));
	vf.WriteLine("WITH_ICONV=" + (withIconv? "1" : "0"));
	vf.WriteLine("WITH_ICU=" + (withIcu? "1" : "0"));
	vf.WriteLine("WITH_ISO8859X=" + (withIso8859x? "1" : "0"));
	vf.WriteLine("WITH_ZLIB=" + (withZlib? "1" : "0"));
	vf.WriteLine("WITH_LZMA=" + (withLzma? "1" : "0"));
	vf.WriteLine("WITH_DEBUG=" + (withDebug? "1" : "0"));
	vf.WriteLine("WITH_MEM_DEBUG=" + (withMemDebug? "1" : "0"));
	vf.WriteLine("WITH_RUN_DEBUG=" + (withRunDebug? "1" : "0"));
	vf.WriteLine("WITH_SCHEMAS=" + (withSchemas? "1" : "0"));
	vf.WriteLine("WITH_SCHEMATRON=" + (withSchematron? "1" : "0"));
	vf.WriteLine("WITH_REGEXPS=" + (withRegExps? "1" : "0"));
	vf.WriteLine("WITH_MODULES=" + (withModules? "1" : "0"));
	vf.WriteLine("WITH_TREE=" + (withTree? "1" : "0"));
	vf.WriteLine("WITH_READER=" + (withReader? "1" : "0"));
	vf.WriteLine("WITH_WRITER=" + (withWriter? "1" : "0"));
	vf.WriteLine("WITH_WALKER=" + (withWalker? "1" : "0"));
	vf.WriteLine("WITH_PATTERN=" + (withPattern? "1" : "0"));
	vf.WriteLine("WITH_PUSH=" + (withPush? "1" : "0"));
	vf.WriteLine("WITH_VALID=" + (withValid? "1" : "0"));
	vf.WriteLine("WITH_SAX1=" + (withSax1? "1" : "0"));
	vf.WriteLine("WITH_LEGACY=" + (withLegacy? "1" : "0"));
	vf.WriteLine("WITH_OUTPUT=" + (withOutput? "1" : "0"));
	vf.WriteLine("WITH_PYTHON=" + (withPython? "1" : "0"));
	vf.WriteLine("DEBUG=" + (buildDebug? "1" : "0"));
	vf.WriteLine("STATIC=" + (buildStatic? "1" : "0"));
	vf.WriteLine("PREFIX=" + buildPrefix);
	vf.WriteLine("BINPREFIX=" + buildBinPrefix);
	vf.WriteLine("INCPREFIX=" + buildIncPrefix);
	vf.WriteLine("LIBPREFIX=" + buildLibPrefix);
	vf.WriteLine("SOPREFIX=" + buildSoPrefix);
	if (compiler == "msvc") {
		vf.WriteLine("INCLUDE=$(INCLUDE);" + buildInclude);
		vf.WriteLine("LIB=$(LIB);" + buildLib);
		vf.WriteLine("CRUNTIME=" + cruntime);
		vf.WriteLine("VCMANIFEST=" + (vcmanifest? "1" : "0"));
	} else if (compiler == "mingw") {
		vf.WriteLine("INCLUDE+= -I" + buildInclude);
		vf.WriteLine("LIB+= -L" + buildLib);
	} else if (compiler == "bcb") {
		vf.WriteLine("INCLUDE=" + buildInclude);
		vf.WriteLine("LIB=" + buildLib);
		vf.WriteLine("DYNRUNTIME=" + (dynruntime? "1" : "0"));
	}
	vf.Close();
}

/* Configures libxml. This one will generate xmlversion.h from xmlversion.h.in
   taking what the user passed on the command line into account. */
function configureLibxml()
{
	var fso, ofi, of, ln, s;
	fso = new ActiveXObject("Scripting.FileSystemObject");
	ofi = fso.OpenTextFile(optsFileIn, 1);
	of = fso.CreateTextFile(optsFile, true);
	while (ofi.AtEndOfStream != true) {
		ln = ofi.ReadLine();
		s = new String(ln);
		if (s.search(/\@VERSION\@/) != -1) {
			of.WriteLine(s.replace(/\@VERSION\@/, 
				verMajor + "." + verMinor + "." + verMicro + verMicroSuffix));
		} else if (s.search(/\@LIBXML_VERSION_NUMBER\@/) != -1) {
			of.WriteLine(s.replace(/\@LIBXML_VERSION_NUMBER\@/, 
				verMajor*10000 + verMinor*100 + verMicro*1));
		} else if (s.search(/\@LIBXML_VERSION_EXTRA\@/) != -1) {
			of.WriteLine(s.replace(/\@LIBXML_VERSION_EXTRA\@/, verCvs));
		} else if (s.search(/\@WITH_TRIO\@/) != -1) {
			of.WriteLine(s.replace(/\@WITH_TRIO\@/, withTrio? "1" : "0"));
		} else if (s.search(/\@WITH_THREADS\@/) != -1) {
			of.WriteLine(s.replace(/\@WITH_THREADS\@/, withThreads == "no"? "0" : "1"));
		} else if (s.search(/\@WITH_THREAD_ALLOC\@/) != -1) {
			of.WriteLine(s.replace(/\@WITH_THREAD_ALLOC\@/, "0"));
		} else if (s.search(/\@WITH_FTP\@/) != -1) {
			of.WriteLine(s.replace(/\@WITH_FTP\@/, withFtp? "1" : "0"));
		} else if (s.search(/\@WITH_HTTP\@/) != -1) {
			of.WriteLine(s.replace(/\@WITH_HTTP\@/, withHttp? "1" : "0"));
		} else if (s.search(/\@WITH_HTML\@/) != -1) {
			of.WriteLine(s.replace(/\@WITH_HTML\@/, withHtml? "1" : "0"));
		} else if (s.search(/\@WITH_C14N\@/) != -1) {
			of.WriteLine(s.replace(/\@WITH_C14N\@/, withC14n? "1" : "0"));
		} else if (s.search(/\@WITH_CATALOG\@/) != -1) {
			of.WriteLine(s.replace(/\@WITH_CATALOG\@/, withCatalog? "1" : "0"));
		} else if (s.search(/\@WITH_DOCB\@/) != -1) {
			of.WriteLine(s.replace(/\@WITH_DOCB\@/, withDocb? "1" : "0"));
		} else if (s.search(/\@WITH_XPATH\@/) != -1) {
			of.WriteLine(s.replace(/\@WITH_XPATH\@/, withXpath? "1" : "0"));
		} else if (s.search(/\@WITH_XPTR\@/) != -1) {
			of.WriteLine(s.replace(/\@WITH_XPTR\@/, withXptr? "1" : "0"));
		} else if (s.search(/\@WITH_XINCLUDE\@/) != -1) {
			of.WriteLine(s.replace(/\@WITH_XINCLUDE\@/, withXinclude? "1" : "0"));
		} else if (s.search(/\@WITH_ICONV\@/) != -1) {
			of.WriteLine(s.replace(/\@WITH_ICONV\@/, withIconv? "1" : "0"));
		} else if (s.search(/\@WITH_ICU\@/) != -1) {
			of.WriteLine(s.replace(/\@WITH_ICU\@/, withIcu? "1" : "0"));
		} else if (s.search(/\@WITH_ISO8859X\@/) != -1) {
			of.WriteLine(s.replace(/\@WITH_ISO8859X\@/, withIso8859x? "1" : "0"));
		} else if (s.search(/\@WITH_ZLIB\@/) != -1) {
			of.WriteLine(s.replace(/\@WITH_ZLIB\@/, withZlib? "1" : "0"));
		} else if (s.search(/\@WITH_LZMA\@/) != -1) {
			of.WriteLine(s.replace(/\@WITH_LZMA\@/, withLzma? "1" : "0"));
		} else if (s.search(/\@WITH_DEBUG\@/) != -1) {
			of.WriteLine(s.replace(/\@WITH_DEBUG\@/, withDebug? "1" : "0"));
		} else if (s.search(/\@WITH_MEM_DEBUG\@/) != -1) {
			of.WriteLine(s.replace(/\@WITH_MEM_DEBUG\@/, withMemDebug? "1" : "0"));
		} else if (s.search(/\@WITH_RUN_DEBUG\@/) != -1) {
			of.WriteLine(s.replace(/\@WITH_RUN_DEBUG\@/, withRunDebug? "1" : "0"));
		} else if (s.search(/\@WITH_SCHEMAS\@/) != -1) {
			of.WriteLine(s.replace(/\@WITH_SCHEMAS\@/, withSchemas? "1" : "0"));
		} else if (s.search(/\@WITH_SCHEMATRON\@/) != -1) {
			of.WriteLine(s.replace(/\@WITH_SCHEMATRON\@/, withSchematron? "1" : "0"));
		} else if (s.search(/\@WITH_REGEXPS\@/) != -1) {
			of.WriteLine(s.replace(/\@WITH_REGEXPS\@/, withRegExps? "1" : "0"));
		} else if (s.search(/\@WITH_MODULES\@/) != -1) {
			of.WriteLine(s.replace(/\@WITH_MODULES\@/, withModules? "1" : "0"));
		} else if (s.search(/\@MODULE_EXTENSION\@/) != -1) {
			of.WriteLine(s.replace(/\@MODULE_EXTENSION\@/, ".dll"));
		} else if (s.search(/\@WITH_TREE\@/) != -1) {
			of.WriteLine(s.replace(/\@WITH_TREE\@/, withTree? "1" : "0"));
		} else if (s.search(/\@WITH_READER\@/) != -1) {
			of.WriteLine(s.replace(/\@WITH_READER\@/, withReader? "1" : "0"));
		} else if (s.search(/\@WITH_WRITER\@/) != -1) {
			of.WriteLine(s.replace(/\@WITH_WRITER\@/, withWriter? "1" : "0"));
		} else if (s.search(/\@WITH_WALKER\@/) != -1) {
			of.WriteLine(s.replace(/\@WITH_WALKER\@/, withWalker? "1" : "0"));
		} else if (s.search(/\@WITH_PATTERN\@/) != -1) {
			of.WriteLine(s.replace(/\@WITH_PATTERN\@/, withPattern? "1" : "0"));
		} else if (s.search(/\@WITH_PUSH\@/) != -1) {
			of.WriteLine(s.replace(/\@WITH_PUSH\@/, withPush? "1" : "0"));
		} else if (s.search(/\@WITH_VALID\@/) != -1) {
			of.WriteLine(s.replace(/\@WITH_VALID\@/, withValid? "1" : "0"));
		} else if (s.search(/\@WITH_SAX1\@/) != -1) {
			of.WriteLine(s.replace(/\@WITH_SAX1\@/, withSax1? "1" : "0"));
		} else if (s.search(/\@WITH_LEGACY\@/) != -1) {
			of.WriteLine(s.replace(/\@WITH_LEGACY\@/, withLegacy? "1" : "0"));
		} else if (s.search(/\@WITH_OUTPUT\@/) != -1) {
			of.WriteLine(s.replace(/\@WITH_OUTPUT\@/, withOutput? "1" : "0"));
		} else
			of.WriteLine(ln);
	}
	ofi.Close();
	of.Close();
}
/* Configures Python bindings. Otherwise identical to the above */
function configureLibxmlPy()
{
	var pyOptsFileIn = srcDirXml + "\\python\\setup.py.in";
	var pyOptsFile = srcDirXml + "\\python\\setup.py";
	var fso, ofi, of, ln, s;
	fso = new ActiveXObject("Scripting.FileSystemObject");
	ofi = fso.OpenTextFile(pyOptsFileIn, 1);
	of = fso.CreateTextFile(pyOptsFile, true);
	while (ofi.AtEndOfStream != true) {
		ln = ofi.ReadLine();
		s = new String(ln);
		if (s.search(/\@LIBXML_VERSION\@/) != -1) {
			of.WriteLine(s.replace(/\@LIBXML_VERSION\@/, 
				verMajor + "." + verMinor + "." + verMicro));
		} else if (s.search(/\@prefix\@/) != -1) {
			of.WriteLine(s.replace(/\@prefix\@/, buildPrefix));
		} else if (s.search(/\@WITH_THREADS\@/) != -1) {
			of.WriteLine(s.replace(/\@WITH_THREADS\@/, withThreads == "no"? "0" : "1"));
		} else
			of.WriteLine(ln);
	}
	ofi.Close();
	of.Close();
}

/* Creates the readme file for the binary distribution of 'bname', for the
   version 'ver' in the file 'file'. This one is called from the Makefile when
   generating a binary distribution. The parameters are passed by make. */
function genReadme(bname, ver, file)
{
	var fso, f;
	fso = new ActiveXObject("Scripting.FileSystemObject");
	f = fso.CreateTextFile(file, true);
	f.WriteLine("  " + bname + " " + ver);
	f.WriteLine("  --------------");
	f.WriteBlankLines(1);
	f.WriteLine("  This is " + bname + ", version " + ver + ", binary package for the native Win32/IA32");
	f.WriteLine("platform.");
	f.WriteBlankLines(1);
	f.WriteLine("  The files in this package do not require any special installation");
	f.WriteLine("steps. Extract the contents of the archive whereever you wish and");
	f.WriteLine("make sure that your tools which use " + bname + " can find it.");
	f.WriteBlankLines(1);
	f.WriteLine("  For example, if you want to run the supplied utilities from the command");
	f.WriteLine("line, you can, if you wish, add the 'bin' subdirectory to the PATH");
	f.WriteLine("environment variable.");
	f.WriteLine("  If you want to make programmes in C which use " + bname + ", you'll");
	f.WriteLine("likely know how to use the contents of this package. If you don't, please");
	f.WriteLine("refer to your compiler's documentation."); 
	f.WriteBlankLines(1);
	f.WriteLine("  If there is something you cannot keep for yourself, such as a problem,");
	f.WriteLine("a cheer of joy, a comment or a suggestion, feel free to contact me using");
	f.WriteLine("the address below.");
	f.WriteBlankLines(1);
	f.WriteLine("                              Igor Zlatkovic (igor@zlatkovic.com)");
	f.Close();
}


/*
 * main(),
 * Execution begins here.
 */

// Parse the command-line arguments.
for (i = 0; (i < WScript.Arguments.length) && (error == 0); i++) {
	var arg, opt;
	arg = WScript.Arguments(i);
	opt = arg.substring(0, arg.indexOf("="));
	if (opt.length == 0)
		opt = arg.substring(0, arg.indexOf(":"));
	if (opt.length > 0) {
		if (opt == "trio")
			withTrio = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "threads")
			withThreads = arg.substring(opt.length + 1, arg.length);
		else if (opt == "ftp")
			withFtp = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "http")
			withHttp = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "html")
			withHtml = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "c14n")
			withC14n = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "catalog")
			withCatalog = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "docb")
			withDocb = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "xpath")
			withXpath = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "xptr")
			withXptr = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "xinclude")
			withXinclude = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "iconv")
			withIconv = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "icu")
			withIcu = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "iso8859x")
			withIso8859x = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "zlib")
			withZlib = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "lzma")
			withLzma = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "xml_debug")
			withDebug = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "mem_debug")
			withMemDebug = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "run_debug")
			withRunDebug = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "schemas")
			withSchemas = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "schematron")
			withSchematron = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "regexps")
			withRegExps = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "modules")
			withModules = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "tree")
			withTree = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "reader")
			withReader = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "writer")
			withWriter = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "walker")
			withWalker = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "pattern")
			withPattern = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "push")
			withPush = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "valid")
			withValid = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "sax1")
			withSax1 = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "legacy")
			withLegacy = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "output")
			withOutput = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "python")
			withPython = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "compiler")
			compiler = arg.substring(opt.length + 1, arg.length);
		else if (opt == "cruntime")
			cruntime = arg.substring(opt.length + 1, arg.length);
		else if (opt == "dynruntime")
			dynruntime = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "vcmanifest")
			vcmanifest = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "debug")
			buildDebug = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "static")
			buildStatic = strToBool(arg.substring(opt.length + 1, arg.length));
		else if (opt == "prefix")
			buildPrefix = arg.substring(opt.length + 1, arg.length);
		else if (opt == "incdir")
			buildIncPrefix = arg.substring(opt.length + 1, arg.length);
		else if (opt == "bindir")
			buildBinPrefix = arg.substring(opt.length + 1, arg.length);
		else if (opt == "libdir")
			buildLibPrefix = arg.substring(opt.length + 1, arg.length);
		else if (opt == "sodir")
			buildSoPrefix = arg.substring(opt.length + 1, arg.length);
		else if (opt == "incdir")
			buildIncPrefix = arg.substring(opt.length + 1, arg.length);
		else if (opt == "include")
			buildInclude = arg.substring(opt.length + 1, arg.length);
		else if (opt == "lib")
			buildLib = arg.substring(opt.length + 1, arg.length);
		else if (opt == "release")
			useCvsVer = false;
		else
			error = 1;
	} else if (i == 0) {
		if (arg == "genreadme") {
			// This command comes from the Makefile and will not be checked
			// for errors, because Makefile will always supply right the parameters.
			genReadme(WScript.Arguments(1), WScript.Arguments(2), WScript.Arguments(3));
			WScript.Quit(0);
		} else if (arg == "help") {
			usage();
			WScript.Quit(0);
		}

	} else {
		error = 1;
	}
}


// If we fail here, it is because the user supplied an unrecognised argument.
if (error != 0) {
	usage();
	WScript.Quit(error);
}

// if user choses to link the c-runtime library statically into libxml2
// with /MT and friends, then we need to enable static linking for xmllint
if (cruntime == "/MT" || cruntime == "/MTd" ||
		cruntime == "/ML" || cruntime == "/MLd") {
	buildStatic = 1;
}

dirSep = "\\";
if (buildBinPrefix == "")
	buildBinPrefix = "$(PREFIX)" + dirSep + "bin";
if (buildIncPrefix == "")
	buildIncPrefix = "$(PREFIX)" + dirSep + "include";
if (buildLibPrefix == "")
	buildLibPrefix = "$(PREFIX)" + dirSep + "lib";
if (buildSoPrefix == "")
	buildSoPrefix = "$(PREFIX)" + dirSep + "bin";

// Discover the version.
discoverVersion();
if (error != 0) {
	WScript.Echo("Version discovery failed, aborting.");
	WScript.Quit(error);
}

var outVerString = baseName + " version: " + verMajor + "." + verMinor + "." + verMicro;
if (verMicroSuffix && verMicroSuffix != "")
	outVerString += "-" + verMicroSuffix;
if (verCvs && verCvs != "")
	outVerString += "-" + verCvs;
WScript.Echo(outVerString);

// Configure libxml.
configureLibxml();
if (error != 0) {
	WScript.Echo("Configuration failed, aborting.");
	WScript.Quit(error);
}

if (withPython == true) {
	configureLibxmlPy();
	if (error != 0) {
		WScript.Echo("Configuration failed, aborting.");
		WScript.Quit(error);
	}

}

// Create the makefile.
var fso = new ActiveXObject("Scripting.FileSystemObject");
var makefile = ".\\Makefile.msvc";
if (compiler == "mingw")
	makefile = ".\\Makefile.mingw";
else if (compiler == "bcb")
	makefile = ".\\Makefile.bcb";
var new_makefile = ".\\Makefile";
var f = fso.FileExists(new_makefile);
if (f) {
       var t = fso.GetFile(new_makefile);
       t.Attributes =0;
}
fso.CopyFile(makefile, new_makefile, true);
WScript.Echo("Created Makefile.");
// Create the config.h.
var confighsrc = "..\\include\\win32config.h";
var configh = "..\\config.h";
var f = fso.FileExists(configh);
if (f) {
	var t = fso.GetFile(configh);
	t.Attributes =0;
}
fso.CopyFile(confighsrc, configh, true);
WScript.Echo("Created config.h.");


// Display the final configuration. 
var txtOut = "\nXML processor configuration\n";
txtOut += "---------------------------\n";
txtOut += "              Trio: " + boolToStr(withTrio) + "\n";
txtOut += "     Thread safety: " + withThreads + "\n";
txtOut += "        FTP client: " + boolToStr(withFtp) + "\n";
txtOut += "       HTTP client: " + boolToStr(withHttp) + "\n";
txtOut += "    HTML processor: " + boolToStr(withHtml) + "\n";
txtOut += "      C14N support: " + boolToStr(withC14n) + "\n";
txtOut += "   Catalog support: " + boolToStr(withCatalog) + "\n";
txtOut += "   DocBook support: " + boolToStr(withDocb) + "\n";
txtOut += "     XPath support: " + boolToStr(withXpath) + "\n";
txtOut += "  XPointer support: " + boolToStr(withXptr) + "\n";
txtOut += "  XInclude support: " + boolToStr(withXinclude) + "\n";
txtOut += "     iconv support: " + boolToStr(withIconv) + "\n";
txtOut += "     icu   support: " + boolToStr(withIcu) + "\n";
txtOut += "  iso8859x support: " + boolToStr(withIso8859x) + "\n";
txtOut += "      zlib support: " + boolToStr(withZlib) + "\n";
txtOut += "      lzma support: " + boolToStr(withLzma) + "\n";
txtOut += "  Debugging module: " + boolToStr(withDebug) + "\n";
txtOut += "  Memory debugging: " + boolToStr(withMemDebug) + "\n";
txtOut += " Runtime debugging: " + boolToStr(withRunDebug) + "\n";
txtOut += "    Regexp support: " + boolToStr(withRegExps) + "\n";
txtOut += "    Module support: " + boolToStr(withModules) + "\n";
txtOut += "      Tree support: " + boolToStr(withTree) + "\n";
txtOut += "    Reader support: " + boolToStr(withReader) + "\n";
txtOut += "    Writer support: " + boolToStr(withWriter) + "\n";
txtOut += "    Walker support: " + boolToStr(withWalker) + "\n";
txtOut += "   Pattern support: " + boolToStr(withPattern) + "\n";
txtOut += "      Push support: " + boolToStr(withPush) + "\n";
txtOut += "Validation support: " + boolToStr(withValid) + "\n";
txtOut += "      SAX1 support: " + boolToStr(withSax1) + "\n";
txtOut += "    Legacy support: " + boolToStr(withLegacy) + "\n";
txtOut += "    Output support: " + boolToStr(withOutput) + "\n";
txtOut += "XML Schema support: " + boolToStr(withSchemas) + "\n";
txtOut += "Schematron support: " + boolToStr(withSchematron) + "\n";
txtOut += "   Python bindings: " + boolToStr(withPython) + "\n";
txtOut += "\n";
txtOut += "Win32 build configuration\n";
txtOut += "-------------------------\n";
txtOut += "          Compiler: " + compiler + "\n";
if (compiler == "msvc") {
	txtOut += "  C-Runtime option: " + cruntime + "\n";
	txtOut += "    Embed Manifest: " + boolToStr(vcmanifest) + "\n";
} else if (compiler == "bcb")
	txtOut += "   Use dynamic RTL: " + dynruntime + "\n";
txtOut += "     Debug symbols: " + boolToStr(buildDebug) + "\n";
txtOut += "    Static xmllint: " + boolToStr(buildStatic) + "\n";
txtOut += "    Install prefix: " + buildPrefix + "\n";
txtOut += "      Put tools in: " + buildBinPrefix + "\n";
txtOut += "    Put headers in: " + buildIncPrefix + "\n";
txtOut += "Put static libs in: " + buildLibPrefix + "\n";
txtOut += "Put shared libs in: " + buildSoPrefix + "\n";
txtOut += "      Include path: " + buildInclude + "\n";
txtOut += "          Lib path: " + buildLib + "\n";
WScript.Echo(txtOut);

//

