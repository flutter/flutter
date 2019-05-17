#if HAVE_GNUC_ATTRIBUTE
#ifdef __fcfreetype__
# undef FcFreeTypeCharIndex
extern __typeof (FcFreeTypeCharIndex) FcFreeTypeCharIndex __attribute((alias("IA__FcFreeTypeCharIndex"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcFreeTypeCharSetAndSpacing
extern __typeof (FcFreeTypeCharSetAndSpacing) FcFreeTypeCharSetAndSpacing __attribute((alias("IA__FcFreeTypeCharSetAndSpacing"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcFreeTypeCharSet
extern __typeof (FcFreeTypeCharSet) FcFreeTypeCharSet __attribute((alias("IA__FcFreeTypeCharSet"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
#endif /* __fcfreetype__ */
#ifdef __fcpat__
# undef FcPatternGetFTFace
extern __typeof (FcPatternGetFTFace) FcPatternGetFTFace __attribute((alias("IA__FcPatternGetFTFace"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
# undef FcPatternAddFTFace
extern __typeof (FcPatternAddFTFace) FcPatternAddFTFace __attribute((alias("IA__FcPatternAddFTFace"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
#endif /* __fcpat__ */
#ifdef __fcfreetype__
# undef FcFreeTypeQueryFace
extern __typeof (FcFreeTypeQueryFace) FcFreeTypeQueryFace __attribute((alias("IA__FcFreeTypeQueryFace"))) FC_ATTRIBUTE_VISIBILITY_EXPORT;
#endif /*  */
#endif /* HAVE_GNUC_ATTRIBUTE */
