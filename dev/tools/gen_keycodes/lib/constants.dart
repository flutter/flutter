/// Mask for the 32-bit value portion of the code.
const int kValueMask = 0x000FFFFFFFF;

/// The code prefix for keys which have a Unicode representation.
const int kUnicodePlane = 0x00000000000;

/// The code prefix for keys which do not have a Unicode representation, but
/// do have a USB HID ID.
const int kHidPlane = 0x00100000000;

/// The code prefix for pseudo-keys which represent collections of key synonyms.
const int kSynonymPlane = 0x20000000000;
