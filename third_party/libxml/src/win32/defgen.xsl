<?xml version="1.0"?>
<!-- 
	win32/defgen.xsl
	This stylesheet is used to transform doc/libxml2-api.xml into a pseudo-source,
	which can then be preprocessed to get the .DEF file for the Microsoft's linker.
	
	Use any XSLT processor to produce a file called libxml2.def.src in the win32
	subdirectory, for example, run xsltproc from the win32 subdirectory:
	
	  xsltproc -o libxml2.def.src defgen.xsl ../doc/libxml2-api.xml
	  
	Once that finishes, rest assured, the Makefile will know what to do with the
	generated file. 

	April 2003, Igor Zlatkovic <igor@zlatkovic.com>
-->
<!DOCTYPE xsl:stylesheet [ <!ENTITY nl '&#xd;&#xa;'> ]>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:strip-space elements="*"/>
	<xsl:output method="text"/>
	<xsl:template match="/">
		<xsl:text>#define LIBXML2_COMPILING_MSCCDEF&nl;</xsl:text>
		<xsl:text>#include "../include/libxml/xmlversion.h"&nl;</xsl:text>
		<xsl:text>LIBRARY libxml2&nl;</xsl:text>
		<xsl:text>EXPORTS&nl;</xsl:text>
		<xsl:for-each select="/api/symbols/*[self::variable or self::function]">
			<!-- Basic tests -->
			<xsl:if test="@file = 'c14n'">
				<xsl:text>#ifdef LIBXML_C14N_ENABLED&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="@file = 'catalog'">
				<xsl:text>#ifdef LIBXML_CATALOG_ENABLED&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="@file = 'debugXML'">
				<xsl:text>#ifdef LIBXML_DEBUG_ENABLED&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="@file = 'DOCBparser'">
				<xsl:text>#ifdef LIBXML_DOCB_ENABLED&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="(@file = 'HTMLparser') 
					or (@file = 'HTMLtree')">
				<xsl:text>#ifdef LIBXML_HTML_ENABLED&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="@file = 'nanohttp'">
				<xsl:text>#ifdef LIBXML_HTTP_ENABLED&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="@file = 'nanoftp'">
				<xsl:text>#ifdef LIBXML_FTP_ENABLED&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="(@file = 'relaxng') 
					or (@file = 'xmlschemas') 
					or (@file = 'xmlschemastypes')">
				<xsl:text>#ifdef LIBXML_SCHEMAS_ENABLED&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="@file = 'xinclude'">
				<xsl:text>#ifdef LIBXML_XINCLUDE_ENABLED&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="@file = 'xlink'">
				<xsl:text>#ifdef LIBXML_XLINK_ENABLED&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="@file = 'xmlautomata'">
				<xsl:text>#ifdef LIBXML_AUTOMATA_ENABLED&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="(@file = 'xmlregexp') 
					or (@file = 'xmlunicode')">
				<xsl:text>#ifdef LIBXML_REGEXP_ENABLED&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="(@file = 'xpath') 
					or (@file = 'xpathInternals')">
				<xsl:text>#ifdef LIBXML_XPATH_ENABLED&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="@file = 'xpointer'">
				<xsl:text>#ifdef LIBXML_XPTR_ENABLED&nl;</xsl:text>
			</xsl:if>
			<!-- Extended tests -->
			<xsl:if test="(@name = 'htmlDefaultSAXHandlerInit') 
					or (@name = 'htmlInitAutoClose') 
					or (@name = 'htmlCreateFileParserCtxt') 
					or (@name = 'inithtmlDefaultSAXHandler')
					or (@name = 'xmlIsXHTML') 
					or (@name = 'xmlIOHTTPOpenW') 
					or (@name = 'xmlRegisterHTTPPostCallbacks') 
					or (@name = 'xmlIOHTTPMatch')
					or (@name = 'xmlIOHTTPOpen') 
					or (@name = 'xmlIOHTTPRead') 
					or (@name = 'xmlIOHTTPClose')">
				<xsl:text>#ifdef LIBXML_HTML_ENABLED&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="(@name = 'docbDefaultSAXHandlerInit') 
					or (@name = 'initdocbDefaultSAXHandler')">
				<xsl:text>#ifdef LIBXML_DOCB_ENABLED&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="@name = 'xmlValidBuildContentModel'">
				<xsl:text>#ifdef LIBXML_REGEXP_ENABLED&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="(@name = 'xmlIOFTPMatch') 
					or (@name = 'xmlIOFTPOpen') 
					or (@name = 'xmlIOFTPRead') 
					or (@name = 'xmlIOFTPClose')">
				<xsl:text>#ifdef LIBXML_FTP_ENABLED&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="(@name = 'xmlTextReaderRelaxNGValidate') 
					or (@name = 'xmlTextReaderRelaxNGSetSchema')">
				<xsl:text>#ifdef LIBXML_SCHEMAS_ENABLED&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="(@name = 'xmlXPathDebugDumpObject') 
					or (@name = 'xmlXPathDebugDumpCompExpr')">
				<xsl:text>#ifdef LIBXML_DEBUG_ENABLED&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="(@name = 'xmlMallocLoc') 
					or (@name = 'xmlMallocAtomicLoc') 
					or (@name = 'xmlReallocLoc') 
					or (@name = 'xmlMemStrdupLoc')">
				<xsl:text>#ifdef DEBUG_MEMORY_LOCATION&nl;</xsl:text>
			</xsl:if>
			<!-- Symbol -->
			<xsl:choose>
				<xsl:when test="(@name = 'xmlMalloc') 
						or (@name = 'xmlMallocAtomic') 
						or (@name = 'xmlRealloc') 
						or (@name = 'xmlFree') 
						or (@name = 'xmlMemStrdup')">
					<xsl:text>#ifdef LIBXML_THREAD_ALLOC_ENABLED&nl;</xsl:text>
					<xsl:text>__</xsl:text>
					<xsl:value-of select="@name"/>
					<xsl:text>&nl;</xsl:text>
					<xsl:text>#else&nl;</xsl:text>
					<xsl:value-of select="@name"/>
					<xsl:text> DATA&nl;</xsl:text>
					<xsl:text>#endif&nl;</xsl:text>
				</xsl:when>
				<xsl:when test="(@name = 'docbDefaultSAXHandler') 
						or (@name = 'htmlDefaultSAXHandler') 
						or (@name = 'oldXMLWDcompatibility') 
						or (@name = 'xmlBufferAllocScheme') 
						or (@name = 'xmlDefaultBufferSize') 
						or (@name = 'xmlDefaultSAXHandler') 
						or (@name = 'xmlDefaultSAXLocator') 
						or (@name = 'xmlDoValidityCheckingDefaultValue') 
						or (@name = 'xmlGenericError') 
						or (@name = 'xmlGenericErrorContext') 
						or (@name = 'xmlGetWarningsDefaultValue') 
						or (@name = 'xmlIndentTreeOutput') 
						or (@name = 'xmlTreeIndentString') 
						or (@name = 'xmlKeepBlanksDefaultValue') 
						or (@name = 'xmlLineNumbersDefaultValue') 
						or (@name = 'xmlLoadExtDtdDefaultValue') 
						or (@name = 'xmlParserDebugEntities') 
						or (@name = 'xmlParserVersion') 
						or (@name = 'xmlPedanticParserDefaultValue') 
						or (@name = 'xmlSaveNoEmptyTags') 
						or (@name = 'xmlSubstituteEntitiesDefaultValue') 
						or (@name = 'xmlRegisterNodeDefaultValue') 
						or (@name = 'xmlDeregisterNodeDefaultValue')">
					<xsl:text>#ifdef LIBXML_THREAD_ENABLED&nl;</xsl:text>
					<xsl:if test="@name = 'docbDefaultSAXHandler'">
						<xsl:text>#ifdef LIBXML_DOCB_ENABLED&nl;</xsl:text>
					</xsl:if>
					<xsl:if test="@name = 'htmlDefaultSAXHandler'">
						<xsl:text>#ifdef LIBXML_HTML_ENABLED&nl;</xsl:text>
					</xsl:if>
					<xsl:text>__</xsl:text>
					<xsl:value-of select="@name"/>
					<xsl:text>&nl;</xsl:text>
					<xsl:if test="@name = 'docbDefaultSAXHandler'">
						<xsl:text>#endif&nl;</xsl:text>
					</xsl:if>
					<xsl:if test="@name = 'htmlDefaultSAXHandler'">
						<xsl:text>#endif&nl;</xsl:text>
					</xsl:if>
					<xsl:text>#else&nl;</xsl:text>
					<xsl:if test="@name = 'docbDefaultSAXHandler'">
						<xsl:text>#ifdef LIBXML_DOCB_ENABLED&nl;</xsl:text>
					</xsl:if>
					<xsl:if test="@name = 'htmlDefaultSAXHandler'">
						<xsl:text>#ifdef LIBXML_HTML_ENABLED&nl;</xsl:text>
					</xsl:if>
					<xsl:value-of select="@name"/>
					<xsl:text> DATA&nl;</xsl:text>
					<xsl:if test="@name = 'docbDefaultSAXHandler'">
						<xsl:text>#endif&nl;</xsl:text>
					</xsl:if>
					<xsl:if test="@name = 'htmlDefaultSAXHandler'">
						<xsl:text>#endif&nl;</xsl:text>
					</xsl:if>
					<xsl:text>#endif&nl;</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="@name"/>
					<xsl:if test="self::variable">
						<xsl:text> DATA</xsl:text>
					</xsl:if>
					<xsl:text>&nl;</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
			<!-- Basic tests (close) -->
			<xsl:if test="@file = 'c14n'">
				<xsl:text>#endif&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="@file = 'catalog'">
				<xsl:text>#endif&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="@file = 'debugXML'">
				<xsl:text>#endif&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="@file = 'DOCBparser'">
				<xsl:text>#endif&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="(@file = 'HTMLparser') 
					or (@file = 'HTMLtree')">
				<xsl:text>#endif&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="@file = 'nanohttp'">
				<xsl:text>#endif&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="@file = 'nanoftp'">
				<xsl:text>#endif&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="(@file = 'relaxng') 
					or (@file = 'xmlschemas') 
					or (@file = 'xmlschemastypes')">
				<xsl:text>#endif&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="@file = 'xinclude'">
				<xsl:text>#endif&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="@file = 'xlink'">
				<xsl:text>#endif&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="@file = 'xmlautomata'">
				<xsl:text>#endif&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="(@file = 'xmlregexp') 
					or (@file = 'xmlunicode')">
				<xsl:text>#endif&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="(@file = 'xpath') 
					or (@file = 'xpathInternals')">
				<xsl:text>#endif&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="@file = 'xpointer'">
				<xsl:text>#endif&nl;</xsl:text>
			</xsl:if>
			<!-- Extended tests (close) -->
			<xsl:if test="(@name = 'htmlDefaultSAXHandlerInit') 
					or (@name = 'htmlInitAutoClose') 
					or (@name = 'htmlCreateFileParserCtxt') 
					or (@name = 'inithtmlDefaultSAXHandler')
					or (@name = 'xmlIsXHTML') 
					or (@name = 'xmlIOHTTPOpenW') 
					or (@name = 'xmlRegisterHTTPPostCallbacks') 
					or (@name = 'xmlIOHTTPMatch')
					or (@name = 'xmlIOHTTPOpen') 
					or (@name = 'xmlIOHTTPRead') 
					or (@name = 'xmlIOHTTPClose')">
				<xsl:text>#endif&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="(@name = 'docbDefaultSAXHandlerInit') 
					or (@name = 'initdocbDefaultSAXHandler')">
				<xsl:text>#endif&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="@name = 'xmlValidBuildContentModel'">
				<xsl:text>#endif&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="(@name = 'xmlIOFTPMatch') 
					or (@name = 'xmlIOFTPOpen') 
					or (@name = 'xmlIOFTPRead') 
					or (@name = 'xmlIOFTPClose')">
				<xsl:text>#endif&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="(@name = 'xmlTextReaderRelaxNGValidate') 
					or (@name = 'xmlTextReaderRelaxNGSetSchema')">
				<xsl:text>#endif&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="(@name = 'xmlXPathDebugDumpObject') 
					or (@name = 'xmlXPathDebugDumpCompExpr')">
				<xsl:text>#endif&nl;</xsl:text>
			</xsl:if>
			<xsl:if test="(@name = 'xmlMallocLoc') 
					or (@name = 'xmlMallocAtomicLoc') 
					or (@name = 'xmlReallocLoc') 
					or (@name = 'xmlMemStrdupLoc')">
				<xsl:text>#endif&nl;</xsl:text>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>
</xsl:stylesheet>

