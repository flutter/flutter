#!/usr/bin/env python

import subprocess
import sys

import css_properties
import in_generator
import license


HEADER_TEMPLATE = """
%(license)s

#ifndef %(class_name)s_h
#define %(class_name)s_h

#include "core/css/parser/CSSParserMode.h"
#include "wtf/HashFunctions.h"
#include "wtf/HashTraits.h"
#include <string.h>

namespace WTF {
class AtomicString;
class String;
}

namespace blink {

enum CSSPropertyID {
    CSSPropertyInvalid = 0,
%(property_enums)s
};

const int firstCSSProperty = %(first_property_id)s;
const int numCSSProperties = %(properties_count)s;
const int lastCSSProperty = %(last_property_id)d;
const size_t maxCSSPropertyNameLength = %(max_name_length)d;

const char* getPropertyName(CSSPropertyID);
const WTF::AtomicString& getPropertyNameAtomicString(CSSPropertyID);
WTF::String getPropertyNameString(CSSPropertyID);
WTF::String getJSPropertyName(CSSPropertyID);
bool isInternalProperty(CSSPropertyID id);

inline CSSPropertyID convertToCSSPropertyID(int value)
{
    ASSERT((value >= firstCSSProperty && value <= lastCSSProperty) || value == CSSPropertyInvalid);
    return static_cast<CSSPropertyID>(value);
}

} // namespace blink

namespace WTF {
template<> struct DefaultHash<blink::CSSPropertyID> { typedef IntHash<unsigned> Hash; };
template<> struct HashTraits<blink::CSSPropertyID> : GenericHashTraits<blink::CSSPropertyID> {
    static const bool emptyValueIsZero = true;
    static const bool needsDestruction = false;
    static void constructDeletedValue(blink::CSSPropertyID& slot, bool) { slot = static_cast<blink::CSSPropertyID>(blink::lastCSSProperty + 1); }
    static bool isDeletedValue(blink::CSSPropertyID value) { return value == (blink::lastCSSProperty + 1); }
};
}

#endif // %(class_name)s_h
"""

GPERF_TEMPLATE = """
%%{
%(license)s

#include "config.h"
#include "%(class_name)s.h"
#include "core/css/HashTools.h"
#include <string.h>

#include "wtf/ASCIICType.h"
#include "wtf/text/AtomicString.h"
#include "wtf/text/WTFString.h"

namespace blink {
static const char propertyNameStringsPool[] = {
%(property_name_strings)s
};

static const unsigned short propertyNameStringsOffsets[] = {
%(property_name_offsets)s
};

%%}
%%struct-type
struct Property;
%%omit-struct-type
%%language=C++
%%readonly-tables
%%global-table
%%compare-strncmp
%%define class-name %(class_name)sHash
%%define lookup-function-name findPropertyImpl
%%define hash-function-name property_hash_function
%%define slot-name nameOffset
%%define word-array-name property_word_list
%%enum
%%%%
%(property_to_enum_map)s
%%%%
const Property* findProperty(register const char* str, register unsigned int len)
{
    return %(class_name)sHash::findPropertyImpl(str, len);
}

const char* getPropertyName(CSSPropertyID id)
{
    if (id < firstCSSProperty)
        return 0;
    int index = id - firstCSSProperty;
    if (index >= numCSSProperties)
        return 0;
    return propertyNameStringsPool + propertyNameStringsOffsets[index];
}

const AtomicString& getPropertyNameAtomicString(CSSPropertyID id)
{
    if (id < firstCSSProperty)
        return nullAtom;
    int index = id - firstCSSProperty;
    if (index >= numCSSProperties)
        return nullAtom;

    static AtomicString* propertyStrings = new AtomicString[numCSSProperties]; // Intentionally never destroyed.
    AtomicString& propertyString = propertyStrings[index];
    if (propertyString.isNull()) {
        const char* propertyName = propertyNameStringsPool + propertyNameStringsOffsets[index];
        propertyString = AtomicString(propertyName, strlen(propertyName), AtomicString::ConstructFromLiteral);
    }
    return propertyString;
}

String getPropertyNameString(CSSPropertyID id)
{
    // We share the StringImpl with the AtomicStrings.
    return getPropertyNameAtomicString(id).string();
}

String getJSPropertyName(CSSPropertyID id)
{
    char result[maxCSSPropertyNameLength + 1];
    const char* cssPropertyName = getPropertyName(id);
    const char* propertyNamePointer = cssPropertyName;
    if (!propertyNamePointer)
        return emptyString();

    char* resultPointer = result;
    while (char character = *propertyNamePointer++) {
        if (character == '-') {
            char nextCharacter = *propertyNamePointer++;
            if (!nextCharacter)
                break;
            character = (propertyNamePointer - 2 != cssPropertyName) ? toASCIIUpper(nextCharacter) : nextCharacter;
        }
        *resultPointer++ = character;
    }
    *resultPointer = '\\0';
    return String(result);
}

bool isInternalProperty(CSSPropertyID id)
{
    switch (id) {
        %(internal_properties)s
            return true;
        default:
            return false;
    }
}

} // namespace blink
"""


class CSSPropertyNamesWriter(css_properties.CSSProperties):
    class_name = "CSSPropertyNames"

    def __init__(self, in_file_path):
        super(CSSPropertyNamesWriter, self).__init__(in_file_path)
        self._outputs = {(self.class_name + ".h"): self.generate_header,
                         (self.class_name + ".cpp"): self.generate_implementation,
                        }

    def _enum_declaration(self, property):
        return "    %(property_id)s = %(enum_value)s," % property

    def generate_header(self):
        return HEADER_TEMPLATE % {
            'license': license.license_for_generated_cpp(),
            'class_name': self.class_name,
            'property_enums': "\n".join(map(self._enum_declaration, self._properties_list)),
            'first_property_id': self._first_enum_value,
            'properties_count': len(self._properties),
            'last_property_id': self._first_enum_value + len(self._properties) - 1,
            'max_name_length': max(map(len, self._properties)),
        }

    def generate_implementation(self):
        property_offsets = []
        current_offset = 0
        for property in self._properties_list:
            property_offsets.append(current_offset)
            current_offset += len(property["name"]) + 1

        css_name_and_enum_pairs = [(property['name'], property_id) for property_id, property in self._properties.items()]
        for name, aliased_name in self._aliases.items():
            css_name_and_enum_pairs.append((name, css_properties.css_name_to_enum(aliased_name)))

        gperf_input = GPERF_TEMPLATE % {
            'license': license.license_for_generated_cpp(),
            'class_name': self.class_name,
            'property_name_strings': '\n'.join(map(lambda property: '    "%(name)s\\0"' % property, self._properties_list)),
            'property_name_offsets': '\n'.join(map(lambda offset: '    %d,' % offset, property_offsets)),
            'property_to_enum_map': '\n'.join(map(lambda property: '%s, %s' % property, css_name_and_enum_pairs)),
            'internal_properties': '\n'.join("case %s:" % property_id for property_id, property in self._properties.items() if property['is_internal']),
        }
        # FIXME: If we could depend on Python 2.7, we would use subprocess.check_output
        gperf_args = [self.gperf_path, '--key-positions=*', '-P', '-n']
        gperf_args.extend(['-m', '50'])  # Pick best of 50 attempts.
        gperf_args.append('-D')  # Allow duplicate hashes -> More compact code.
        gperf = subprocess.Popen(gperf_args, stdin=subprocess.PIPE, stdout=subprocess.PIPE, universal_newlines=True)
        return gperf.communicate(gperf_input)[0]


if __name__ == "__main__":
    in_generator.Maker(CSSPropertyNamesWriter).main(sys.argv)
