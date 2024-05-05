"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.resolveBSONOptions = exports.pluckBSONSerializeOptions = exports.UUID = exports.Timestamp = exports.serialize = exports.ObjectId = exports.MinKey = exports.MaxKey = exports.Long = exports.Int32 = exports.EJSON = exports.Double = exports.deserialize = exports.Decimal128 = exports.DBRef = exports.Code = exports.calculateObjectSize = exports.BSONType = exports.BSONSymbol = exports.BSONRegExp = exports.BSON = exports.Binary = void 0;
var bson_1 = require("bson");
Object.defineProperty(exports, "Binary", { enumerable: true, get: function () { return bson_1.Binary; } });
Object.defineProperty(exports, "BSON", { enumerable: true, get: function () { return bson_1.BSON; } });
Object.defineProperty(exports, "BSONRegExp", { enumerable: true, get: function () { return bson_1.BSONRegExp; } });
Object.defineProperty(exports, "BSONSymbol", { enumerable: true, get: function () { return bson_1.BSONSymbol; } });
Object.defineProperty(exports, "BSONType", { enumerable: true, get: function () { return bson_1.BSONType; } });
Object.defineProperty(exports, "calculateObjectSize", { enumerable: true, get: function () { return bson_1.calculateObjectSize; } });
Object.defineProperty(exports, "Code", { enumerable: true, get: function () { return bson_1.Code; } });
Object.defineProperty(exports, "DBRef", { enumerable: true, get: function () { return bson_1.DBRef; } });
Object.defineProperty(exports, "Decimal128", { enumerable: true, get: function () { return bson_1.Decimal128; } });
Object.defineProperty(exports, "deserialize", { enumerable: true, get: function () { return bson_1.deserialize; } });
Object.defineProperty(exports, "Double", { enumerable: true, get: function () { return bson_1.Double; } });
Object.defineProperty(exports, "EJSON", { enumerable: true, get: function () { return bson_1.EJSON; } });
Object.defineProperty(exports, "Int32", { enumerable: true, get: function () { return bson_1.Int32; } });
Object.defineProperty(exports, "Long", { enumerable: true, get: function () { return bson_1.Long; } });
Object.defineProperty(exports, "MaxKey", { enumerable: true, get: function () { return bson_1.MaxKey; } });
Object.defineProperty(exports, "MinKey", { enumerable: true, get: function () { return bson_1.MinKey; } });
Object.defineProperty(exports, "ObjectId", { enumerable: true, get: function () { return bson_1.ObjectId; } });
Object.defineProperty(exports, "serialize", { enumerable: true, get: function () { return bson_1.serialize; } });
Object.defineProperty(exports, "Timestamp", { enumerable: true, get: function () { return bson_1.Timestamp; } });
Object.defineProperty(exports, "UUID", { enumerable: true, get: function () { return bson_1.UUID; } });
function pluckBSONSerializeOptions(options) {
    const { fieldsAsRaw, useBigInt64, promoteValues, promoteBuffers, promoteLongs, serializeFunctions, ignoreUndefined, bsonRegExp, raw, enableUtf8Validation } = options;
    return {
        fieldsAsRaw,
        useBigInt64,
        promoteValues,
        promoteBuffers,
        promoteLongs,
        serializeFunctions,
        ignoreUndefined,
        bsonRegExp,
        raw,
        enableUtf8Validation
    };
}
exports.pluckBSONSerializeOptions = pluckBSONSerializeOptions;
/**
 * Merge the given BSONSerializeOptions, preferring options over the parent's options, and
 * substituting defaults for values not set.
 *
 * @internal
 */
function resolveBSONOptions(options, parent) {
    const parentOptions = parent?.bsonOptions;
    return {
        raw: options?.raw ?? parentOptions?.raw ?? false,
        useBigInt64: options?.useBigInt64 ?? parentOptions?.useBigInt64 ?? false,
        promoteLongs: options?.promoteLongs ?? parentOptions?.promoteLongs ?? true,
        promoteValues: options?.promoteValues ?? parentOptions?.promoteValues ?? true,
        promoteBuffers: options?.promoteBuffers ?? parentOptions?.promoteBuffers ?? false,
        ignoreUndefined: options?.ignoreUndefined ?? parentOptions?.ignoreUndefined ?? false,
        bsonRegExp: options?.bsonRegExp ?? parentOptions?.bsonRegExp ?? false,
        serializeFunctions: options?.serializeFunctions ?? parentOptions?.serializeFunctions ?? false,
        fieldsAsRaw: options?.fieldsAsRaw ?? parentOptions?.fieldsAsRaw ?? {},
        enableUtf8Validation: options?.enableUtf8Validation ?? parentOptions?.enableUtf8Validation ?? true
    };
}
exports.resolveBSONOptions = resolveBSONOptions;
//# sourceMappingURL=bson.js.map