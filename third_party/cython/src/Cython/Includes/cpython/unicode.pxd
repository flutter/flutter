cdef extern from *:
    # Return true if the object o is a Unicode object or an instance
    # of a Unicode subtype. Changed in version 2.2: Allowed subtypes
    # to be accepted.
    bint PyUnicode_Check(object o)

    # Return true if the object o is a Unicode object, but not an
    # instance of a subtype. New in version 2.2.
    bint PyUnicode_CheckExact(object o)

    # Return the size of the object. o has to be a PyUnicodeObject
    # (not checked).
    Py_ssize_t PyUnicode_GET_SIZE(object o)

    # Return the size of the object's internal buffer in bytes. o has
    # to be a PyUnicodeObject (not checked).
    Py_ssize_t PyUnicode_GET_DATA_SIZE(object o)

    # Return a pointer to the internal Py_UNICODE buffer of the
    # object. o has to be a PyUnicodeObject (not checked).
    Py_UNICODE* PyUnicode_AS_UNICODE(object o)

    # Return a pointer to the internal buffer of the object. o has to
    # be a PyUnicodeObject (not checked).
    char* PyUnicode_AS_DATA(object o)

    # Return 1 or 0 depending on whether ch is a whitespace character.
    bint Py_UNICODE_ISSPACE(Py_UNICODE ch)

    # Return 1 or 0 depending on whether ch is a lowercase character.
    bint Py_UNICODE_ISLOWER(Py_UNICODE ch)

    # Return 1 or 0 depending on whether ch is an uppercase character.
    bint Py_UNICODE_ISUPPER(Py_UNICODE ch)

    # Return 1 or 0 depending on whether ch is a titlecase character.
    bint Py_UNICODE_ISTITLE(Py_UNICODE ch)

    # Return 1 or 0 depending on whether ch is a linebreak character.
    bint Py_UNICODE_ISLINEBREAK(Py_UNICODE ch)

    # Return 1 or 0 depending on whether ch is a decimal character.
    bint Py_UNICODE_ISDECIMAL(Py_UNICODE ch)

    # Return 1 or 0 depending on whether ch is a digit character.
    bint Py_UNICODE_ISDIGIT(Py_UNICODE ch)

    # Return 1 or 0 depending on whether ch is a numeric character.
    bint Py_UNICODE_ISNUMERIC(Py_UNICODE ch)

    # Return 1 or 0 depending on whether ch is an alphabetic character.
    bint Py_UNICODE_ISALPHA(Py_UNICODE ch)

    # Return 1 or 0 depending on whether ch is an alphanumeric character.
    bint Py_UNICODE_ISALNUM(Py_UNICODE ch)

    # Return the character ch converted to lower case.
    Py_UNICODE Py_UNICODE_TOLOWER(Py_UNICODE ch)

    # Return the character ch converted to upper case.
    Py_UNICODE Py_UNICODE_TOUPPER(Py_UNICODE ch)

    # Return the character ch converted to title case.
    Py_UNICODE Py_UNICODE_TOTITLE(Py_UNICODE ch)

    # Return the character ch converted to a decimal positive
    # integer. Return -1 if this is not possible. This macro does not
    # raise exceptions.
    int Py_UNICODE_TODECIMAL(Py_UNICODE ch)

    # Return the character ch converted to a single digit
    # integer. Return -1 if this is not possible. This macro does not
    # raise exceptions.
    int Py_UNICODE_TODIGIT(Py_UNICODE ch)

    # Return the character ch converted to a double. Return -1.0 if
    # this is not possible. This macro does not raise exceptions.
    double Py_UNICODE_TONUMERIC(Py_UNICODE ch)

    # To create Unicode objects and access their basic sequence
    # properties, use these APIs:

    # Create a Unicode Object from the Py_UNICODE buffer u of the
    # given size. u may be NULL which causes the contents to be
    # undefined. It is the user's responsibility to fill in the needed
    # data. The buffer is copied into the new object. If the buffer is
    # not NULL, the return value might be a shared object. Therefore,
    # modification of the resulting Unicode object is only allowed
    # when u is NULL.
    object PyUnicode_FromUnicode(Py_UNICODE *u, Py_ssize_t size)

    # Create a Unicode Object from the given Unicode code point ordinal.
    #
    # The ordinal must be in range(0x10000) on narrow Python builds
    # (UCS2), and range(0x110000) on wide builds (UCS4). A ValueError
    # is raised in case it is not.
    object PyUnicode_FromOrdinal(int ordinal)

    # Return a read-only pointer to the Unicode object's internal
    # Py_UNICODE buffer, NULL if unicode is not a Unicode object.
    Py_UNICODE* PyUnicode_AsUnicode(object o) except NULL

    # Return the length of the Unicode object.
    Py_ssize_t PyUnicode_GetSize(object o) except -1

    # Coerce an encoded object obj to an Unicode object and return a
    # reference with incremented refcount.
    # String and other char buffer compatible objects are decoded
    # according to the given encoding and using the error handling
    # defined by errors. Both can be NULL to have the interface use
    # the default values (see the next section for details).
    # All other objects, including Unicode objects, cause a TypeError
    # to be set.
    object PyUnicode_FromEncodedObject(object o, char *encoding, char *errors)

    # Shortcut for PyUnicode_FromEncodedObject(obj, NULL, "strict")
    # which is used throughout the interpreter whenever coercion to
    # Unicode is needed.
    object PyUnicode_FromObject(object obj)

    # If the platform supports wchar_t and provides a header file
    # wchar.h, Python can interface directly to this type using the
    # following functions. Support is optimized if Python's own
    # Py_UNICODE type is identical to the system's wchar_t.

    #ctypedef int wchar_t

    # Create a Unicode object from the wchar_t buffer w of the given
    # size. Return NULL on failure.
    #PyObject* PyUnicode_FromWideChar(wchar_t *w, Py_ssize_t size)

    #Py_ssize_t PyUnicode_AsWideChar(object o, wchar_t *w, Py_ssize_t size)

# Codecs

    # Create a Unicode object by decoding size bytes of the encoded
    # string s. encoding and errors have the same meaning as the
    # parameters of the same name in the unicode() builtin
    # function. The codec to be used is looked up using the Python
    # codec registry. Return NULL if an exception was raised by the
    # codec.
    object PyUnicode_Decode(char *s, Py_ssize_t size, char *encoding, char *errors)

    # Encode the Py_UNICODE buffer of the given size and return a
    # Python string object. encoding and errors have the same meaning
    # as the parameters of the same name in the Unicode encode()
    # method. The codec to be used is looked up using the Python codec
    # registry. Return NULL if an exception was raised by the codec.
    object PyUnicode_Encode(Py_UNICODE *s, Py_ssize_t size,
                            char *encoding, char *errors)

    # Encode a Unicode object and return the result as Python string
    # object. encoding and errors have the same meaning as the
    # parameters of the same name in the Unicode encode() method. The
    # codec to be used is looked up using the Python codec
    # registry. Return NULL if an exception was raised by the codec.
    object PyUnicode_AsEncodedString(object unicode, char *encoding, char *errors)

# These are the UTF-8 codec APIs:

    # Create a Unicode object by decoding size bytes of the UTF-8
    # encoded string s. Return NULL if an exception was raised by the
    # codec.
    object PyUnicode_DecodeUTF8(char *s, Py_ssize_t size, char *errors)

    # If consumed is NULL, behave like PyUnicode_DecodeUTF8(). If
    # consumed is not NULL, trailing incomplete UTF-8 byte sequences
    # will not be treated as an error. Those bytes will not be decoded
    # and the number of bytes that have been decoded will be stored in
    # consumed. New in version 2.4.
    object PyUnicode_DecodeUTF8Stateful(char *s, Py_ssize_t size, char *errors, Py_ssize_t *consumed)

    # Encode the Py_UNICODE buffer of the given size using UTF-8 and
    # return a Python string object. Return NULL if an exception was
    # raised by the codec.
    object PyUnicode_EncodeUTF8(Py_UNICODE *s, Py_ssize_t size, char *errors)

    # Encode a Unicode objects using UTF-8 and return the result as Python string object. Error handling is ``strict''. Return NULL if an exception was raised by the codec.
    object PyUnicode_AsUTF8String(object unicode)

# These are the UTF-16 codec APIs:

    # Decode length bytes from a UTF-16 encoded buffer string and
    # return the corresponding Unicode object. errors (if non-NULL)
    # defines the error handling. It defaults to ``strict''.
    #
    # If byteorder is non-NULL, the decoder starts decoding using the
    # given byte order:
    #
    #   *byteorder == -1: little endian
    #   *byteorder == 0:  native order
    #   *byteorder == 1:  big endian
    #
    # and then switches if the first two bytes of the input data are a
    # byte order mark (BOM) and the specified byte order is native
    # order. This BOM is not copied into the resulting Unicode
    # string. After completion, *byteorder is set to the current byte
    # order at the.
    #
    # If byteorder is NULL, the codec starts in native order mode.
    object PyUnicode_DecodeUTF16(char *s, Py_ssize_t size, char *errors, int *byteorder)

    # If consumed is NULL, behave like PyUnicode_DecodeUTF16(). If
    # consumed is not NULL, PyUnicode_DecodeUTF16Stateful() will not
    # treat trailing incomplete UTF-16 byte sequences (such as an odd
    # number of bytes or a split surrogate pair) as an error. Those
    # bytes will not be decoded and the number of bytes that have been
    # decoded will be stored in consumed. New in version 2.4.
    object PyUnicode_DecodeUTF16Stateful(char *s, Py_ssize_t size, char *errors, int *byteorder, Py_ssize_t *consumed)

    # Return a Python string object holding the UTF-16 encoded value
    # of the Unicode data in s. If byteorder is not 0, output is
    # written according to the following byte order:
    #
    #   byteorder == -1: little endian
    #   byteorder == 0:  native byte order (writes a BOM mark)
    #   byteorder == 1:  big endian
    #
    # If byteorder is 0, the output string will always start with the
    # Unicode BOM mark (U+FEFF). In the other two modes, no BOM mark
    # is prepended.
    #
    # If Py_UNICODE_WIDE is defined, a single Py_UNICODE value may get
    # represented as a surrogate pair. If it is not defined, each
    # Py_UNICODE values is interpreted as an UCS-2 character.
    object PyUnicode_EncodeUTF16(Py_UNICODE *s, Py_ssize_t size, char *errors, int byteorder)

    # Return a Python string using the UTF-16 encoding in native byte
    # order. The string always starts with a BOM mark. Error handling
    # is ``strict''. Return NULL if an exception was raised by the
    # codec.
    object PyUnicode_AsUTF16String(object unicode)

# These are the ``Unicode Escape'' codec APIs:

    # Create a Unicode object by decoding size bytes of the
    # Unicode-Escape encoded string s. Return NULL if an exception was
    # raised by the codec.
    object PyUnicode_DecodeUnicodeEscape(char *s, Py_ssize_t size, char *errors)

    # Encode the Py_UNICODE buffer of the given size using
    # Unicode-Escape and return a Python string object. Return NULL if
    # an exception was raised by the codec.
    object PyUnicode_EncodeUnicodeEscape(Py_UNICODE *s, Py_ssize_t size)

    # Encode a Unicode objects using Unicode-Escape and return the
    # result as Python string object. Error handling is
    # ``strict''. Return NULL if an exception was raised by the codec.
    object PyUnicode_AsUnicodeEscapeString(object unicode)

# These are the ``Raw Unicode Escape'' codec APIs:

    # Create a Unicode object by decoding size bytes of the
    # Raw-Unicode-Escape encoded string s. Return NULL if an exception
    # was raised by the codec.
    object PyUnicode_DecodeRawUnicodeEscape(char *s, Py_ssize_t size, char *errors)

    # Encode the Py_UNICODE buffer of the given size using
    # Raw-Unicode-Escape and return a Python string object. Return
    # NULL if an exception was raised by the codec.
    object PyUnicode_EncodeRawUnicodeEscape(Py_UNICODE *s, Py_ssize_t size, char *errors)

    # Encode a Unicode objects using Raw-Unicode-Escape and return the
    # result as Python string object. Error handling is
    # ``strict''. Return NULL if an exception was raised by the codec.
    object PyUnicode_AsRawUnicodeEscapeString(object unicode)

# These are the Latin-1 codec APIs: Latin-1 corresponds to the first 256 Unicode ordinals and only these are accepted by the codecs during encoding.

    # Create a Unicode object by decoding size bytes of the Latin-1
    # encoded string s. Return NULL if an exception was raised by the
    # codec.
    object PyUnicode_DecodeLatin1(char *s, Py_ssize_t size, char *errors)

    # Encode the Py_UNICODE buffer of the given size using Latin-1 and
    # return a Python string object. Return NULL if an exception was
    # raised by the codec.
    object PyUnicode_EncodeLatin1(Py_UNICODE *s, Py_ssize_t size, char *errors)

    # Encode a Unicode objects using Latin-1 and return the result as
    # Python string object. Error handling is ``strict''. Return NULL
    # if an exception was raised by the codec.
    object PyUnicode_AsLatin1String(object unicode)

# These are the ASCII codec APIs. Only 7-bit ASCII data is
# accepted. All other codes generate errors.

    # Create a Unicode object by decoding size bytes of the ASCII
    # encoded string s. Return NULL if an exception was raised by the
    # codec.
    object PyUnicode_DecodeASCII(char *s, Py_ssize_t size, char *errors)

    # Encode the Py_UNICODE buffer of the given size using ASCII and
    # return a Python string object. Return NULL if an exception was
    # raised by the codec.
    object PyUnicode_EncodeASCII(Py_UNICODE *s, Py_ssize_t size, char *errors)

    # Encode a Unicode objects using ASCII and return the result as
    # Python string object. Error handling is ``strict''. Return NULL
    # if an exception was raised by the codec.
    object PyUnicode_AsASCIIString(object o)

# These are the mapping codec APIs:
#
# This codec is special in that it can be used to implement many
# different codecs (and this is in fact what was done to obtain most
# of the standard codecs included in the encodings package). The codec
# uses mapping to encode and decode characters.
#
# Decoding mappings must map single string characters to single
# Unicode characters, integers (which are then interpreted as Unicode
# ordinals) or None (meaning "undefined mapping" and causing an
# error).
#
# Encoding mappings must map single Unicode characters to single
# string characters, integers (which are then interpreted as Latin-1
# ordinals) or None (meaning "undefined mapping" and causing an
# error).
#
# The mapping objects provided must only support the __getitem__
# mapping interface.
#
# If a character lookup fails with a LookupError, the character is
# copied as-is meaning that its ordinal value will be interpreted as
# Unicode or Latin-1 ordinal resp. Because of this, mappings only need
# to contain those mappings which map characters to different code
# points.

    # Create a Unicode object by decoding size bytes of the encoded
    # string s using the given mapping object. Return NULL if an
    # exception was raised by the codec. If mapping is NULL latin-1
    # decoding will be done. Else it can be a dictionary mapping byte
    # or a unicode string, which is treated as a lookup table. Byte
    # values greater that the length of the string and U+FFFE
    # "characters" are treated as "undefined mapping". Changed in
    # version 2.4: Allowed unicode string as mapping argument.
    object PyUnicode_DecodeCharmap(char *s, Py_ssize_t size, object mapping, char *errors)

    # Encode the Py_UNICODE buffer of the given size using the given
    # mapping object and return a Python string object. Return NULL if
    # an exception was raised by the codec.
    object PyUnicode_EncodeCharmap(Py_UNICODE *s, Py_ssize_t size, object mapping, char *errors)

    # Encode a Unicode objects using the given mapping object and
    # return the result as Python string object. Error handling is
    # ``strict''. Return NULL if an exception was raised by the codec.
    object PyUnicode_AsCharmapString(object o, object mapping)

# The following codec API is special in that maps Unicode to Unicode.

    # Translate a Py_UNICODE buffer of the given length by applying a
    # character mapping table to it and return the resulting Unicode
    # object. Return NULL when an exception was raised by the codec.
    #
    # The mapping table must map Unicode ordinal integers to Unicode
    # ordinal integers or None (causing deletion of the character).
    #
    # Mapping tables need only provide the __getitem__() interface;
    # dictionaries and sequences work well. Unmapped character
    # ordinals (ones which cause a LookupError) are left untouched and
    # are copied as-is.
    object PyUnicode_TranslateCharmap(Py_UNICODE *s, Py_ssize_t size,
                                      object table, char *errors)

# These are the MBCS codec APIs. They are currently only available on
# Windows and use the Win32 MBCS converters to implement the
# conversions. Note that MBCS (or DBCS) is a class of encodings, not
# just one. The target encoding is defined by the user settings on the
# machine running the codec.

    # Create a Unicode object by decoding size bytes of the MBCS
    # encoded string s. Return NULL if an exception was raised by the
    # codec.
    object PyUnicode_DecodeMBCS(char *s, Py_ssize_t size, char *errors)

    # If consumed is NULL, behave like PyUnicode_DecodeMBCS(). If
    # consumed is not NULL, PyUnicode_DecodeMBCSStateful() will not
    # decode trailing lead byte and the number of bytes that have been
    # decoded will be stored in consumed. New in version 2.5.
    # NOTE: Python 2.x uses 'int' values for 'size' and 'consumed' (changed in 3.0)
    object PyUnicode_DecodeMBCSStateful(char *s, Py_ssize_t size, char *errors, Py_ssize_t *consumed)

    # Encode the Py_UNICODE buffer of the given size using MBCS and
    # return a Python string object. Return NULL if an exception was
    # raised by the codec.
    object PyUnicode_EncodeMBCS(Py_UNICODE *s, Py_ssize_t size, char *errors)

    # Encode a Unicode objects using MBCS and return the result as
    # Python string object. Error handling is ``strict''. Return NULL
    # if an exception was raised by the codec.
    object PyUnicode_AsMBCSString(object o)
