#if HAVE_GNUC_ATTRIBUTE
#ifdef __fccfg__
# undef FcBlanksCreate
extern __typeof (FcBlanksCreate) FcBlanksCreate __attribute((alias("IA__FcBlanksCreate"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcBlanksDestroy
extern __typeof (FcBlanksDestroy) FcBlanksDestroy __attribute((alias("IA__FcBlanksDestroy"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcBlanksAdd
extern __typeof (FcBlanksAdd) FcBlanksAdd __attribute((alias("IA__FcBlanksAdd"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcBlanksIsMember
extern __typeof (FcBlanksIsMember) FcBlanksIsMember __attribute((alias("IA__FcBlanksIsMember"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
#endif /* __fccfg__ */
#ifdef __fccache__
# undef FcCacheCopySet
extern __typeof (FcCacheCopySet) FcCacheCopySet __attribute((alias("IA__FcCacheCopySet"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcCacheNumSubdir
extern __typeof (FcCacheNumSubdir) FcCacheNumSubdir __attribute((alias("IA__FcCacheNumSubdir"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcCacheNumFont
extern __typeof (FcCacheNumFont) FcCacheNumFont __attribute((alias("IA__FcCacheNumFont"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcDirCacheUnlink
extern __typeof (FcDirCacheUnlink) FcDirCacheUnlink __attribute((alias("IA__FcDirCacheUnlink"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcDirCacheValid
extern __typeof (FcDirCacheValid) FcDirCacheValid __attribute((alias("IA__FcDirCacheValid"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcDirCacheClean
extern __typeof (FcDirCacheClean) FcDirCacheClean __attribute((alias("IA__FcDirCacheClean"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcCacheCreateTagFile
extern __typeof (FcCacheCreateTagFile) FcCacheCreateTagFile __attribute((alias("IA__FcCacheCreateTagFile"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcDirCacheCreateUUID
extern __typeof (FcDirCacheCreateUUID) FcDirCacheCreateUUID __attribute((alias("IA__FcDirCacheCreateUUID"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcDirCacheDeleteUUID
extern __typeof (FcDirCacheDeleteUUID) FcDirCacheDeleteUUID __attribute((alias("IA__FcDirCacheDeleteUUID"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
#endif /* __fccache__ */
#ifdef __fccfg__
# undef FcConfigHome
extern __typeof (FcConfigHome) FcConfigHome __attribute((alias("IA__FcConfigHome"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcConfigEnableHome
extern __typeof (FcConfigEnableHome) FcConfigEnableHome __attribute((alias("IA__FcConfigEnableHome"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcConfigFilename
extern __typeof (FcConfigFilename) FcConfigFilename __attribute((alias("IA__FcConfigFilename"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcConfigCreate
extern __typeof (FcConfigCreate) FcConfigCreate __attribute((alias("IA__FcConfigCreate"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcConfigReference
extern __typeof (FcConfigReference) FcConfigReference __attribute((alias("IA__FcConfigReference"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcConfigDestroy
extern __typeof (FcConfigDestroy) FcConfigDestroy __attribute((alias("IA__FcConfigDestroy"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcConfigSetCurrent
extern __typeof (FcConfigSetCurrent) FcConfigSetCurrent __attribute((alias("IA__FcConfigSetCurrent"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcConfigGetCurrent
extern __typeof (FcConfigGetCurrent) FcConfigGetCurrent __attribute((alias("IA__FcConfigGetCurrent"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcConfigUptoDate
extern __typeof (FcConfigUptoDate) FcConfigUptoDate __attribute((alias("IA__FcConfigUptoDate"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcConfigBuildFonts
extern __typeof (FcConfigBuildFonts) FcConfigBuildFonts __attribute((alias("IA__FcConfigBuildFonts"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcConfigGetFontDirs
extern __typeof (FcConfigGetFontDirs) FcConfigGetFontDirs __attribute((alias("IA__FcConfigGetFontDirs"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcConfigGetConfigDirs
extern __typeof (FcConfigGetConfigDirs) FcConfigGetConfigDirs __attribute((alias("IA__FcConfigGetConfigDirs"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcConfigGetConfigFiles
extern __typeof (FcConfigGetConfigFiles) FcConfigGetConfigFiles __attribute((alias("IA__FcConfigGetConfigFiles"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcConfigGetCache
extern __typeof (FcConfigGetCache) FcConfigGetCache __attribute((alias("IA__FcConfigGetCache"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcConfigGetBlanks
extern __typeof (FcConfigGetBlanks) FcConfigGetBlanks __attribute((alias("IA__FcConfigGetBlanks"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcConfigGetCacheDirs
extern __typeof (FcConfigGetCacheDirs) FcConfigGetCacheDirs __attribute((alias("IA__FcConfigGetCacheDirs"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcConfigGetRescanInterval
extern __typeof (FcConfigGetRescanInterval) FcConfigGetRescanInterval __attribute((alias("IA__FcConfigGetRescanInterval"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcConfigSetRescanInterval
extern __typeof (FcConfigSetRescanInterval) FcConfigSetRescanInterval __attribute((alias("IA__FcConfigSetRescanInterval"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcConfigGetFonts
extern __typeof (FcConfigGetFonts) FcConfigGetFonts __attribute((alias("IA__FcConfigGetFonts"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcConfigAppFontAddFile
extern __typeof (FcConfigAppFontAddFile) FcConfigAppFontAddFile __attribute((alias("IA__FcConfigAppFontAddFile"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcConfigAppFontAddDir
extern __typeof (FcConfigAppFontAddDir) FcConfigAppFontAddDir __attribute((alias("IA__FcConfigAppFontAddDir"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcConfigAppFontClear
extern __typeof (FcConfigAppFontClear) FcConfigAppFontClear __attribute((alias("IA__FcConfigAppFontClear"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcConfigSubstituteWithPat
extern __typeof (FcConfigSubstituteWithPat) FcConfigSubstituteWithPat __attribute((alias("IA__FcConfigSubstituteWithPat"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcConfigSubstitute
extern __typeof (FcConfigSubstitute) FcConfigSubstitute __attribute((alias("IA__FcConfigSubstitute"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcConfigGetSysRoot
extern __typeof (FcConfigGetSysRoot) FcConfigGetSysRoot __attribute((alias("IA__FcConfigGetSysRoot"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcConfigSetSysRoot
extern __typeof (FcConfigSetSysRoot) FcConfigSetSysRoot __attribute((alias("IA__FcConfigSetSysRoot"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcConfigFileInfoIterInit
extern __typeof (FcConfigFileInfoIterInit) FcConfigFileInfoIterInit __attribute((alias("IA__FcConfigFileInfoIterInit"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcConfigFileInfoIterNext
extern __typeof (FcConfigFileInfoIterNext) FcConfigFileInfoIterNext __attribute((alias("IA__FcConfigFileInfoIterNext"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcConfigFileInfoIterGet
extern __typeof (FcConfigFileInfoIterGet) FcConfigFileInfoIterGet __attribute((alias("IA__FcConfigFileInfoIterGet"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
#endif /* __fccfg__ */
#ifdef __fccharset__
# undef FcCharSetCreate
extern __typeof (FcCharSetCreate) FcCharSetCreate __attribute((alias("IA__FcCharSetCreate"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcCharSetNew
extern __typeof (FcCharSetNew) FcCharSetNew __attribute((alias("IA__FcCharSetNew"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcCharSetDestroy
extern __typeof (FcCharSetDestroy) FcCharSetDestroy __attribute((alias("IA__FcCharSetDestroy"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcCharSetAddChar
extern __typeof (FcCharSetAddChar) FcCharSetAddChar __attribute((alias("IA__FcCharSetAddChar"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcCharSetDelChar
extern __typeof (FcCharSetDelChar) FcCharSetDelChar __attribute((alias("IA__FcCharSetDelChar"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcCharSetCopy
extern __typeof (FcCharSetCopy) FcCharSetCopy __attribute((alias("IA__FcCharSetCopy"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcCharSetEqual
extern __typeof (FcCharSetEqual) FcCharSetEqual __attribute((alias("IA__FcCharSetEqual"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcCharSetIntersect
extern __typeof (FcCharSetIntersect) FcCharSetIntersect __attribute((alias("IA__FcCharSetIntersect"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcCharSetUnion
extern __typeof (FcCharSetUnion) FcCharSetUnion __attribute((alias("IA__FcCharSetUnion"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcCharSetSubtract
extern __typeof (FcCharSetSubtract) FcCharSetSubtract __attribute((alias("IA__FcCharSetSubtract"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcCharSetMerge
extern __typeof (FcCharSetMerge) FcCharSetMerge __attribute((alias("IA__FcCharSetMerge"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcCharSetHasChar
extern __typeof (FcCharSetHasChar) FcCharSetHasChar __attribute((alias("IA__FcCharSetHasChar"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcCharSetCount
extern __typeof (FcCharSetCount) FcCharSetCount __attribute((alias("IA__FcCharSetCount"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcCharSetIntersectCount
extern __typeof (FcCharSetIntersectCount) FcCharSetIntersectCount __attribute((alias("IA__FcCharSetIntersectCount"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcCharSetSubtractCount
extern __typeof (FcCharSetSubtractCount) FcCharSetSubtractCount __attribute((alias("IA__FcCharSetSubtractCount"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcCharSetIsSubset
extern __typeof (FcCharSetIsSubset) FcCharSetIsSubset __attribute((alias("IA__FcCharSetIsSubset"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcCharSetFirstPage
extern __typeof (FcCharSetFirstPage) FcCharSetFirstPage __attribute((alias("IA__FcCharSetFirstPage"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcCharSetNextPage
extern __typeof (FcCharSetNextPage) FcCharSetNextPage __attribute((alias("IA__FcCharSetNextPage"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcCharSetCoverage
extern __typeof (FcCharSetCoverage) FcCharSetCoverage __attribute((alias("IA__FcCharSetCoverage"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
#endif /* __fccharset__ */
#ifdef __fcdbg__
# undef FcValuePrint
extern __typeof (FcValuePrint) FcValuePrint __attribute((alias("IA__FcValuePrint"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternPrint
extern __typeof (FcPatternPrint) FcPatternPrint __attribute((alias("IA__FcPatternPrint"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcFontSetPrint
extern __typeof (FcFontSetPrint) FcFontSetPrint __attribute((alias("IA__FcFontSetPrint"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
#endif /* __fcdbg__ */
#ifdef __fcdefault__
# undef FcGetDefaultLangs
extern __typeof (FcGetDefaultLangs) FcGetDefaultLangs __attribute((alias("IA__FcGetDefaultLangs"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcDefaultSubstitute
extern __typeof (FcDefaultSubstitute) FcDefaultSubstitute __attribute((alias("IA__FcDefaultSubstitute"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
#endif /* __fcdefault__ */
#ifdef __fcdir__
# undef FcFileIsDir
extern __typeof (FcFileIsDir) FcFileIsDir __attribute((alias("IA__FcFileIsDir"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcFileScan
extern __typeof (FcFileScan) FcFileScan __attribute((alias("IA__FcFileScan"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcDirScan
extern __typeof (FcDirScan) FcDirScan __attribute((alias("IA__FcDirScan"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcDirSave
extern __typeof (FcDirSave) FcDirSave __attribute((alias("IA__FcDirSave"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
#endif /* __fcdir__ */
#ifdef __fccache__
# undef FcDirCacheLoad
extern __typeof (FcDirCacheLoad) FcDirCacheLoad __attribute((alias("IA__FcDirCacheLoad"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
#endif /* __fccache__ */
#ifdef __fcdir__
# undef FcDirCacheRescan
extern __typeof (FcDirCacheRescan) FcDirCacheRescan __attribute((alias("IA__FcDirCacheRescan"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcDirCacheRead
extern __typeof (FcDirCacheRead) FcDirCacheRead __attribute((alias("IA__FcDirCacheRead"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
#endif /* __fcdir__ */
#ifdef __fccache__
# undef FcDirCacheLoadFile
extern __typeof (FcDirCacheLoadFile) FcDirCacheLoadFile __attribute((alias("IA__FcDirCacheLoadFile"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcDirCacheUnload
extern __typeof (FcDirCacheUnload) FcDirCacheUnload __attribute((alias("IA__FcDirCacheUnload"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
#endif /* __fccache__ */
#ifdef __fcfreetype__
# undef FcFreeTypeQuery
extern __typeof (FcFreeTypeQuery) FcFreeTypeQuery __attribute((alias("IA__FcFreeTypeQuery"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcFreeTypeQueryAll
extern __typeof (FcFreeTypeQueryAll) FcFreeTypeQueryAll __attribute((alias("IA__FcFreeTypeQueryAll"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
#endif /* __fcfreetype__ */
#ifdef __fcfs__
# undef FcFontSetCreate
extern __typeof (FcFontSetCreate) FcFontSetCreate __attribute((alias("IA__FcFontSetCreate"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcFontSetDestroy
extern __typeof (FcFontSetDestroy) FcFontSetDestroy __attribute((alias("IA__FcFontSetDestroy"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcFontSetAdd
extern __typeof (FcFontSetAdd) FcFontSetAdd __attribute((alias("IA__FcFontSetAdd"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
#endif /* __fcfs__ */
#ifdef __fcinit__
# undef FcInitLoadConfig
extern __typeof (FcInitLoadConfig) FcInitLoadConfig __attribute((alias("IA__FcInitLoadConfig"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcInitLoadConfigAndFonts
extern __typeof (FcInitLoadConfigAndFonts) FcInitLoadConfigAndFonts __attribute((alias("IA__FcInitLoadConfigAndFonts"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcInit
extern __typeof (FcInit) FcInit __attribute((alias("IA__FcInit"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcFini
extern __typeof (FcFini) FcFini __attribute((alias("IA__FcFini"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcGetVersion
extern __typeof (FcGetVersion) FcGetVersion __attribute((alias("IA__FcGetVersion"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcInitReinitialize
extern __typeof (FcInitReinitialize) FcInitReinitialize __attribute((alias("IA__FcInitReinitialize"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcInitBringUptoDate
extern __typeof (FcInitBringUptoDate) FcInitBringUptoDate __attribute((alias("IA__FcInitBringUptoDate"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
#endif /* __fcinit__ */
#ifdef __fclang__
# undef FcGetLangs
extern __typeof (FcGetLangs) FcGetLangs __attribute((alias("IA__FcGetLangs"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcLangNormalize
extern __typeof (FcLangNormalize) FcLangNormalize __attribute((alias("IA__FcLangNormalize"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcLangGetCharSet
extern __typeof (FcLangGetCharSet) FcLangGetCharSet __attribute((alias("IA__FcLangGetCharSet"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcLangSetCreate
extern __typeof (FcLangSetCreate) FcLangSetCreate __attribute((alias("IA__FcLangSetCreate"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcLangSetDestroy
extern __typeof (FcLangSetDestroy) FcLangSetDestroy __attribute((alias("IA__FcLangSetDestroy"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcLangSetCopy
extern __typeof (FcLangSetCopy) FcLangSetCopy __attribute((alias("IA__FcLangSetCopy"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcLangSetAdd
extern __typeof (FcLangSetAdd) FcLangSetAdd __attribute((alias("IA__FcLangSetAdd"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcLangSetDel
extern __typeof (FcLangSetDel) FcLangSetDel __attribute((alias("IA__FcLangSetDel"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcLangSetHasLang
extern __typeof (FcLangSetHasLang) FcLangSetHasLang __attribute((alias("IA__FcLangSetHasLang"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcLangSetCompare
extern __typeof (FcLangSetCompare) FcLangSetCompare __attribute((alias("IA__FcLangSetCompare"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcLangSetContains
extern __typeof (FcLangSetContains) FcLangSetContains __attribute((alias("IA__FcLangSetContains"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcLangSetEqual
extern __typeof (FcLangSetEqual) FcLangSetEqual __attribute((alias("IA__FcLangSetEqual"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcLangSetHash
extern __typeof (FcLangSetHash) FcLangSetHash __attribute((alias("IA__FcLangSetHash"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcLangSetGetLangs
extern __typeof (FcLangSetGetLangs) FcLangSetGetLangs __attribute((alias("IA__FcLangSetGetLangs"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcLangSetUnion
extern __typeof (FcLangSetUnion) FcLangSetUnion __attribute((alias("IA__FcLangSetUnion"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcLangSetSubtract
extern __typeof (FcLangSetSubtract) FcLangSetSubtract __attribute((alias("IA__FcLangSetSubtract"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
#endif /* __fclang__ */
#ifdef __fclist__
# undef FcObjectSetCreate
extern __typeof (FcObjectSetCreate) FcObjectSetCreate __attribute((alias("IA__FcObjectSetCreate"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcObjectSetAdd
extern __typeof (FcObjectSetAdd) FcObjectSetAdd __attribute((alias("IA__FcObjectSetAdd"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcObjectSetDestroy
extern __typeof (FcObjectSetDestroy) FcObjectSetDestroy __attribute((alias("IA__FcObjectSetDestroy"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcObjectSetVaBuild
extern __typeof (FcObjectSetVaBuild) FcObjectSetVaBuild __attribute((alias("IA__FcObjectSetVaBuild"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcObjectSetBuild
extern __typeof (FcObjectSetBuild) FcObjectSetBuild __attribute((alias("IA__FcObjectSetBuild"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcFontSetList
extern __typeof (FcFontSetList) FcFontSetList __attribute((alias("IA__FcFontSetList"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcFontList
extern __typeof (FcFontList) FcFontList __attribute((alias("IA__FcFontList"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
#endif /* __fclist__ */
#ifdef __fcatomic__
# undef FcAtomicCreate
extern __typeof (FcAtomicCreate) FcAtomicCreate __attribute((alias("IA__FcAtomicCreate"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcAtomicLock
extern __typeof (FcAtomicLock) FcAtomicLock __attribute((alias("IA__FcAtomicLock"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcAtomicNewFile
extern __typeof (FcAtomicNewFile) FcAtomicNewFile __attribute((alias("IA__FcAtomicNewFile"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcAtomicOrigFile
extern __typeof (FcAtomicOrigFile) FcAtomicOrigFile __attribute((alias("IA__FcAtomicOrigFile"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcAtomicReplaceOrig
extern __typeof (FcAtomicReplaceOrig) FcAtomicReplaceOrig __attribute((alias("IA__FcAtomicReplaceOrig"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcAtomicDeleteNew
extern __typeof (FcAtomicDeleteNew) FcAtomicDeleteNew __attribute((alias("IA__FcAtomicDeleteNew"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcAtomicUnlock
extern __typeof (FcAtomicUnlock) FcAtomicUnlock __attribute((alias("IA__FcAtomicUnlock"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcAtomicDestroy
extern __typeof (FcAtomicDestroy) FcAtomicDestroy __attribute((alias("IA__FcAtomicDestroy"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
#endif /* __fcatomic__ */
#ifdef __fcmatch__
# undef FcFontSetMatch
extern __typeof (FcFontSetMatch) FcFontSetMatch __attribute((alias("IA__FcFontSetMatch"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcFontMatch
extern __typeof (FcFontMatch) FcFontMatch __attribute((alias("IA__FcFontMatch"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcFontRenderPrepare
extern __typeof (FcFontRenderPrepare) FcFontRenderPrepare __attribute((alias("IA__FcFontRenderPrepare"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcFontSetSort
extern __typeof (FcFontSetSort) FcFontSetSort __attribute((alias("IA__FcFontSetSort"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcFontSort
extern __typeof (FcFontSort) FcFontSort __attribute((alias("IA__FcFontSort"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcFontSetSortDestroy
extern __typeof (FcFontSetSortDestroy) FcFontSetSortDestroy __attribute((alias("IA__FcFontSetSortDestroy"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
#endif /* __fcmatch__ */
#ifdef __fcmatrix__
# undef FcMatrixCopy
extern __typeof (FcMatrixCopy) FcMatrixCopy __attribute((alias("IA__FcMatrixCopy"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcMatrixEqual
extern __typeof (FcMatrixEqual) FcMatrixEqual __attribute((alias("IA__FcMatrixEqual"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcMatrixMultiply
extern __typeof (FcMatrixMultiply) FcMatrixMultiply __attribute((alias("IA__FcMatrixMultiply"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcMatrixRotate
extern __typeof (FcMatrixRotate) FcMatrixRotate __attribute((alias("IA__FcMatrixRotate"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcMatrixScale
extern __typeof (FcMatrixScale) FcMatrixScale __attribute((alias("IA__FcMatrixScale"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcMatrixShear
extern __typeof (FcMatrixShear) FcMatrixShear __attribute((alias("IA__FcMatrixShear"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
#endif /* __fcmatrix__ */
#ifdef __fcname__
# undef FcNameRegisterObjectTypes
extern __typeof (FcNameRegisterObjectTypes) FcNameRegisterObjectTypes __attribute((alias("IA__FcNameRegisterObjectTypes"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcNameUnregisterObjectTypes
extern __typeof (FcNameUnregisterObjectTypes) FcNameUnregisterObjectTypes __attribute((alias("IA__FcNameUnregisterObjectTypes"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcNameGetObjectType
extern __typeof (FcNameGetObjectType) FcNameGetObjectType __attribute((alias("IA__FcNameGetObjectType"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcNameRegisterConstants
extern __typeof (FcNameRegisterConstants) FcNameRegisterConstants __attribute((alias("IA__FcNameRegisterConstants"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcNameUnregisterConstants
extern __typeof (FcNameUnregisterConstants) FcNameUnregisterConstants __attribute((alias("IA__FcNameUnregisterConstants"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcNameGetConstant
extern __typeof (FcNameGetConstant) FcNameGetConstant __attribute((alias("IA__FcNameGetConstant"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcNameConstant
extern __typeof (FcNameConstant) FcNameConstant __attribute((alias("IA__FcNameConstant"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcNameParse
extern __typeof (FcNameParse) FcNameParse __attribute((alias("IA__FcNameParse"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcNameUnparse
extern __typeof (FcNameUnparse) FcNameUnparse __attribute((alias("IA__FcNameUnparse"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
#endif /* __fcname__ */
#ifdef __fcpat__
# undef FcPatternCreate
extern __typeof (FcPatternCreate) FcPatternCreate __attribute((alias("IA__FcPatternCreate"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternDuplicate
extern __typeof (FcPatternDuplicate) FcPatternDuplicate __attribute((alias("IA__FcPatternDuplicate"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternReference
extern __typeof (FcPatternReference) FcPatternReference __attribute((alias("IA__FcPatternReference"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternFilter
extern __typeof (FcPatternFilter) FcPatternFilter __attribute((alias("IA__FcPatternFilter"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcValueDestroy
extern __typeof (FcValueDestroy) FcValueDestroy __attribute((alias("IA__FcValueDestroy"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcValueEqual
extern __typeof (FcValueEqual) FcValueEqual __attribute((alias("IA__FcValueEqual"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcValueSave
extern __typeof (FcValueSave) FcValueSave __attribute((alias("IA__FcValueSave"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternDestroy
extern __typeof (FcPatternDestroy) FcPatternDestroy __attribute((alias("IA__FcPatternDestroy"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternObjectCount
extern __typeof (FcPatternObjectCount) FcPatternObjectCount __attribute((alias("IA__FcPatternObjectCount"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternEqual
extern __typeof (FcPatternEqual) FcPatternEqual __attribute((alias("IA__FcPatternEqual"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternEqualSubset
extern __typeof (FcPatternEqualSubset) FcPatternEqualSubset __attribute((alias("IA__FcPatternEqualSubset"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternHash
extern __typeof (FcPatternHash) FcPatternHash __attribute((alias("IA__FcPatternHash"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternAdd
extern __typeof (FcPatternAdd) FcPatternAdd __attribute((alias("IA__FcPatternAdd"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternAddWeak
extern __typeof (FcPatternAddWeak) FcPatternAddWeak __attribute((alias("IA__FcPatternAddWeak"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternGet
extern __typeof (FcPatternGet) FcPatternGet __attribute((alias("IA__FcPatternGet"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternGetWithBinding
extern __typeof (FcPatternGetWithBinding) FcPatternGetWithBinding __attribute((alias("IA__FcPatternGetWithBinding"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternDel
extern __typeof (FcPatternDel) FcPatternDel __attribute((alias("IA__FcPatternDel"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternRemove
extern __typeof (FcPatternRemove) FcPatternRemove __attribute((alias("IA__FcPatternRemove"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternAddInteger
extern __typeof (FcPatternAddInteger) FcPatternAddInteger __attribute((alias("IA__FcPatternAddInteger"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternAddDouble
extern __typeof (FcPatternAddDouble) FcPatternAddDouble __attribute((alias("IA__FcPatternAddDouble"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternAddString
extern __typeof (FcPatternAddString) FcPatternAddString __attribute((alias("IA__FcPatternAddString"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternAddMatrix
extern __typeof (FcPatternAddMatrix) FcPatternAddMatrix __attribute((alias("IA__FcPatternAddMatrix"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternAddCharSet
extern __typeof (FcPatternAddCharSet) FcPatternAddCharSet __attribute((alias("IA__FcPatternAddCharSet"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternAddBool
extern __typeof (FcPatternAddBool) FcPatternAddBool __attribute((alias("IA__FcPatternAddBool"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternAddLangSet
extern __typeof (FcPatternAddLangSet) FcPatternAddLangSet __attribute((alias("IA__FcPatternAddLangSet"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternAddRange
extern __typeof (FcPatternAddRange) FcPatternAddRange __attribute((alias("IA__FcPatternAddRange"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternGetInteger
extern __typeof (FcPatternGetInteger) FcPatternGetInteger __attribute((alias("IA__FcPatternGetInteger"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternGetDouble
extern __typeof (FcPatternGetDouble) FcPatternGetDouble __attribute((alias("IA__FcPatternGetDouble"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternGetString
extern __typeof (FcPatternGetString) FcPatternGetString __attribute((alias("IA__FcPatternGetString"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternGetMatrix
extern __typeof (FcPatternGetMatrix) FcPatternGetMatrix __attribute((alias("IA__FcPatternGetMatrix"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternGetCharSet
extern __typeof (FcPatternGetCharSet) FcPatternGetCharSet __attribute((alias("IA__FcPatternGetCharSet"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternGetBool
extern __typeof (FcPatternGetBool) FcPatternGetBool __attribute((alias("IA__FcPatternGetBool"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternGetLangSet
extern __typeof (FcPatternGetLangSet) FcPatternGetLangSet __attribute((alias("IA__FcPatternGetLangSet"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternGetRange
extern __typeof (FcPatternGetRange) FcPatternGetRange __attribute((alias("IA__FcPatternGetRange"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternVaBuild
extern __typeof (FcPatternVaBuild) FcPatternVaBuild __attribute((alias("IA__FcPatternVaBuild"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternBuild
extern __typeof (FcPatternBuild) FcPatternBuild __attribute((alias("IA__FcPatternBuild"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
#endif /* __fcpat__ */
#ifdef __fcformat__
# undef FcPatternFormat
extern __typeof (FcPatternFormat) FcPatternFormat __attribute((alias("IA__FcPatternFormat"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
#endif /* __fcformat__ */
#ifdef __fcrange__
# undef FcRangeCreateDouble
extern __typeof (FcRangeCreateDouble) FcRangeCreateDouble __attribute((alias("IA__FcRangeCreateDouble"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcRangeCreateInteger
extern __typeof (FcRangeCreateInteger) FcRangeCreateInteger __attribute((alias("IA__FcRangeCreateInteger"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcRangeDestroy
extern __typeof (FcRangeDestroy) FcRangeDestroy __attribute((alias("IA__FcRangeDestroy"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcRangeCopy
extern __typeof (FcRangeCopy) FcRangeCopy __attribute((alias("IA__FcRangeCopy"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcRangeGetDouble
extern __typeof (FcRangeGetDouble) FcRangeGetDouble __attribute((alias("IA__FcRangeGetDouble"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
#endif /* __fcrange__ */
#ifdef __fcpat__
# undef FcPatternIterStart
extern __typeof (FcPatternIterStart) FcPatternIterStart __attribute((alias("IA__FcPatternIterStart"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternIterNext
extern __typeof (FcPatternIterNext) FcPatternIterNext __attribute((alias("IA__FcPatternIterNext"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternIterEqual
extern __typeof (FcPatternIterEqual) FcPatternIterEqual __attribute((alias("IA__FcPatternIterEqual"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternFindIter
extern __typeof (FcPatternFindIter) FcPatternFindIter __attribute((alias("IA__FcPatternFindIter"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternIterIsValid
extern __typeof (FcPatternIterIsValid) FcPatternIterIsValid __attribute((alias("IA__FcPatternIterIsValid"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternIterGetObject
extern __typeof (FcPatternIterGetObject) FcPatternIterGetObject __attribute((alias("IA__FcPatternIterGetObject"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternIterValueCount
extern __typeof (FcPatternIterValueCount) FcPatternIterValueCount __attribute((alias("IA__FcPatternIterValueCount"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternIterGetValue
extern __typeof (FcPatternIterGetValue) FcPatternIterGetValue __attribute((alias("IA__FcPatternIterGetValue"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
#endif /* __fcpat__ */
#ifdef __fcweight__
# undef FcWeightFromOpenType
extern __typeof (FcWeightFromOpenType) FcWeightFromOpenType __attribute((alias("IA__FcWeightFromOpenType"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcWeightFromOpenTypeDouble
extern __typeof (FcWeightFromOpenTypeDouble) FcWeightFromOpenTypeDouble __attribute((alias("IA__FcWeightFromOpenTypeDouble"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcWeightToOpenType
extern __typeof (FcWeightToOpenType) FcWeightToOpenType __attribute((alias("IA__FcWeightToOpenType"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcWeightToOpenTypeDouble
extern __typeof (FcWeightToOpenTypeDouble) FcWeightToOpenTypeDouble __attribute((alias("IA__FcWeightToOpenTypeDouble"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
#endif /* __fcweight__ */
#ifdef __fcstr__
# undef FcStrCopy
extern __typeof (FcStrCopy) FcStrCopy __attribute((alias("IA__FcStrCopy"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcStrCopyFilename
extern __typeof (FcStrCopyFilename) FcStrCopyFilename __attribute((alias("IA__FcStrCopyFilename"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcStrPlus
extern __typeof (FcStrPlus) FcStrPlus __attribute((alias("IA__FcStrPlus"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcStrFree
extern __typeof (FcStrFree) FcStrFree __attribute((alias("IA__FcStrFree"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcStrDowncase
extern __typeof (FcStrDowncase) FcStrDowncase __attribute((alias("IA__FcStrDowncase"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcStrCmpIgnoreCase
extern __typeof (FcStrCmpIgnoreCase) FcStrCmpIgnoreCase __attribute((alias("IA__FcStrCmpIgnoreCase"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcStrCmp
extern __typeof (FcStrCmp) FcStrCmp __attribute((alias("IA__FcStrCmp"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcStrStrIgnoreCase
extern __typeof (FcStrStrIgnoreCase) FcStrStrIgnoreCase __attribute((alias("IA__FcStrStrIgnoreCase"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcStrStr
extern __typeof (FcStrStr) FcStrStr __attribute((alias("IA__FcStrStr"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcUtf8ToUcs4
extern __typeof (FcUtf8ToUcs4) FcUtf8ToUcs4 __attribute((alias("IA__FcUtf8ToUcs4"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcUtf8Len
extern __typeof (FcUtf8Len) FcUtf8Len __attribute((alias("IA__FcUtf8Len"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcUcs4ToUtf8
extern __typeof (FcUcs4ToUtf8) FcUcs4ToUtf8 __attribute((alias("IA__FcUcs4ToUtf8"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcUtf16ToUcs4
extern __typeof (FcUtf16ToUcs4) FcUtf16ToUcs4 __attribute((alias("IA__FcUtf16ToUcs4"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcUtf16Len
extern __typeof (FcUtf16Len) FcUtf16Len __attribute((alias("IA__FcUtf16Len"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcStrBuildFilename
extern __typeof (FcStrBuildFilename) FcStrBuildFilename __attribute((alias("IA__FcStrBuildFilename"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcStrDirname
extern __typeof (FcStrDirname) FcStrDirname __attribute((alias("IA__FcStrDirname"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcStrBasename
extern __typeof (FcStrBasename) FcStrBasename __attribute((alias("IA__FcStrBasename"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcStrSetCreate
extern __typeof (FcStrSetCreate) FcStrSetCreate __attribute((alias("IA__FcStrSetCreate"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcStrSetMember
extern __typeof (FcStrSetMember) FcStrSetMember __attribute((alias("IA__FcStrSetMember"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcStrSetEqual
extern __typeof (FcStrSetEqual) FcStrSetEqual __attribute((alias("IA__FcStrSetEqual"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcStrSetAdd
extern __typeof (FcStrSetAdd) FcStrSetAdd __attribute((alias("IA__FcStrSetAdd"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcStrSetAddFilename
extern __typeof (FcStrSetAddFilename) FcStrSetAddFilename __attribute((alias("IA__FcStrSetAddFilename"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcStrSetDel
extern __typeof (FcStrSetDel) FcStrSetDel __attribute((alias("IA__FcStrSetDel"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcStrSetDestroy
extern __typeof (FcStrSetDestroy) FcStrSetDestroy __attribute((alias("IA__FcStrSetDestroy"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcStrListCreate
extern __typeof (FcStrListCreate) FcStrListCreate __attribute((alias("IA__FcStrListCreate"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcStrListFirst
extern __typeof (FcStrListFirst) FcStrListFirst __attribute((alias("IA__FcStrListFirst"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcStrListNext
extern __typeof (FcStrListNext) FcStrListNext __attribute((alias("IA__FcStrListNext"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcStrListDone
extern __typeof (FcStrListDone) FcStrListDone __attribute((alias("IA__FcStrListDone"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
#endif /* __fcstr__ */
#ifdef __fcxml__
# undef FcConfigParseAndLoad
extern __typeof (FcConfigParseAndLoad) FcConfigParseAndLoad __attribute((alias("IA__FcConfigParseAndLoad"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcConfigParseAndLoadFromMemory
extern __typeof (FcConfigParseAndLoadFromMemory) FcConfigParseAndLoadFromMemory __attribute((alias("IA__FcConfigParseAndLoadFromMemory"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
#endif /* __fcxml__ */
#ifdef __fccfg__
# undef FcConfigGetRescanInverval
extern __typeof (FcConfigGetRescanInverval) FcConfigGetRescanInverval __attribute((alias("IA__FcConfigGetRescanInverval"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcConfigSetRescanInverval
extern __typeof (FcConfigSetRescanInverval) FcConfigSetRescanInverval __attribute((alias("IA__FcConfigSetRescanInverval"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
#endif /*  */
#endif /* HAVE_GNUC_ATTRIBUTE */
