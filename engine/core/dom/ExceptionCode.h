/*
 *  Copyright (C) 2006, 2007 Apple Inc. All rights reserved.
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

#ifndef ExceptionCode_h
#define ExceptionCode_h

namespace blink {

    // The DOM standards use unsigned short for exception codes.
    // In our DOM implementation we use int instead, and use different
    // numerical ranges for different types of DOM exception, so that
    // an exception of any type can be expressed with a single integer.
    typedef int ExceptionCode;


    // Some of these are considered historical since they have been
    // changed or removed from the specifications.
    enum {
        IndexSizeError = 1,
        HierarchyRequestError,
        WrongDocumentError,
        InvalidCharacterError,
        NoModificationAllowedError,
        NotFoundError,
        NotSupportedError,
        InUseAttributeError, // Historical. Only used in setAttributeNode etc which have been removed from the DOM specs.

        // Introduced in DOM Level 2:
        InvalidStateError,
        SyntaxError,
        InvalidModificationError,
        NamespaceError,
        InvalidAccessError,

        // Introduced in DOM Level 3:
        TypeMismatchError, // Historical; use TypeError instead

        // XMLHttpRequest extension:
        SecurityError,

        // Others introduced in HTML5:
        NetworkError,
        AbortError,
        URLMismatchError,
        QuotaExceededError,
        TimeoutError,
        InvalidNodeTypeError,
        DataCloneError,

        // These are IDB-specific.
        UnknownError,
        ConstraintError,
        DataError,
        TransactionInactiveError,
        ReadOnlyError,
        VersionError,

        // File system
        NotReadableError,
        EncodingError,
        PathExistsError,

        // SQL
        SQLDatabaseError, // Naming conflict with DatabaseError class.

        // Web Crypto
        OperationError,
    };

    enum V8ErrorType {
        V8GeneralError = 1000,
        V8TypeError,
        V8RangeError,
        V8SyntaxError,
        V8ReferenceError,
    };

} // namespace blink

#endif // ExceptionCode_h
