"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getMongoDBClientEncryption = exports.aws4 = exports.getSocks = exports.getSnappy = exports.getGcpMetadata = exports.getAwsCredentialProvider = exports.getZstdLibrary = exports.ZStandard = exports.getKerberos = exports.Kerberos = void 0;
const error_1 = require("./error");
function makeErrorModule(error) {
    const props = error ? { kModuleError: error } : {};
    return new Proxy(props, {
        get: (_, key) => {
            if (key === 'kModuleError') {
                return error;
            }
            throw error;
        },
        set: () => {
            throw error;
        }
    });
}
exports.Kerberos = makeErrorModule(new error_1.MongoMissingDependencyError('Optional module `kerberos` not found. Please install it to enable kerberos authentication'));
function getKerberos() {
    try {
        // Ensure you always wrap an optional require in the try block NODE-3199
        exports.Kerberos = require('kerberos');
        return exports.Kerberos;
    }
    catch {
        return exports.Kerberos;
    }
}
exports.getKerberos = getKerberos;
exports.ZStandard = makeErrorModule(new error_1.MongoMissingDependencyError('Optional module `@mongodb-js/zstd` not found. Please install it to enable zstd compression'));
function getZstdLibrary() {
    try {
        exports.ZStandard = require('@mongodb-js/zstd');
        return exports.ZStandard;
    }
    catch {
        return exports.ZStandard;
    }
}
exports.getZstdLibrary = getZstdLibrary;
function getAwsCredentialProvider() {
    try {
        // Ensure you always wrap an optional require in the try block NODE-3199
        const credentialProvider = require('@aws-sdk/credential-providers');
        return credentialProvider;
    }
    catch {
        return makeErrorModule(new error_1.MongoMissingDependencyError('Optional module `@aws-sdk/credential-providers` not found.' +
            ' Please install it to enable getting aws credentials via the official sdk.'));
    }
}
exports.getAwsCredentialProvider = getAwsCredentialProvider;
function getGcpMetadata() {
    try {
        // Ensure you always wrap an optional require in the try block NODE-3199
        const credentialProvider = require('gcp-metadata');
        return credentialProvider;
    }
    catch {
        return makeErrorModule(new error_1.MongoMissingDependencyError('Optional module `gcp-metadata` not found.' +
            ' Please install it to enable getting gcp credentials via the official sdk.'));
    }
}
exports.getGcpMetadata = getGcpMetadata;
function getSnappy() {
    try {
        // Ensure you always wrap an optional require in the try block NODE-3199
        const value = require('snappy');
        return value;
    }
    catch (cause) {
        const kModuleError = new error_1.MongoMissingDependencyError('Optional module `snappy` not found. Please install it to enable snappy compression', { cause });
        return { kModuleError };
    }
}
exports.getSnappy = getSnappy;
function getSocks() {
    try {
        // Ensure you always wrap an optional require in the try block NODE-3199
        const value = require('socks');
        return value;
    }
    catch (cause) {
        const kModuleError = new error_1.MongoMissingDependencyError('Optional module `socks` not found. Please install it to connections over a SOCKS5 proxy', { cause });
        return { kModuleError };
    }
}
exports.getSocks = getSocks;
exports.aws4 = makeErrorModule(new error_1.MongoMissingDependencyError('Optional module `aws4` not found. Please install it to enable AWS authentication'));
try {
    // Ensure you always wrap an optional require in the try block NODE-3199
    exports.aws4 = require('aws4');
}
catch { } // eslint-disable-line
/** A utility function to get the instance of mongodb-client-encryption, if it exists. */
function getMongoDBClientEncryption() {
    let mongodbClientEncryption = null;
    try {
        // NOTE(NODE-3199): Ensure you always wrap an optional require literally in the try block
        // Cannot be moved to helper utility function, bundlers search and replace the actual require call
        // in a way that makes this line throw at bundle time, not runtime, catching here will make bundling succeed
        mongodbClientEncryption = require('mongodb-client-encryption');
    }
    catch (cause) {
        const kModuleError = new error_1.MongoMissingDependencyError('Optional module `mongodb-client-encryption` not found. Please install it to use auto encryption or ClientEncryption.', { cause });
        return { kModuleError };
    }
    return mongodbClientEncryption;
}
exports.getMongoDBClientEncryption = getMongoDBClientEncryption;
//# sourceMappingURL=deps.js.map