"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.hmacSha256Hook = exports.hmacSha512Hook = exports.aes256CtrDecryptHook = exports.aes256CtrEncryptHook = exports.aes256CbcDecryptHook = exports.aes256CbcEncryptHook = exports.signRsaSha256Hook = exports.makeHmacHook = exports.sha256Hook = exports.randomHook = exports.makeAES256Hook = void 0;
const crypto = require("crypto");
function makeAES256Hook(method, mode) {
    return function (key, iv, input, output) {
        let result;
        try {
            const cipher = crypto[method](mode, key, iv);
            cipher.setAutoPadding(false);
            result = cipher.update(input);
            const final = cipher.final();
            if (final.length > 0) {
                result = Buffer.concat([result, final]);
            }
        }
        catch (e) {
            return e;
        }
        result.copy(output);
        return result.length;
    };
}
exports.makeAES256Hook = makeAES256Hook;
function randomHook(buffer, count) {
    try {
        crypto.randomFillSync(buffer, 0, count);
    }
    catch (e) {
        return e;
    }
    return count;
}
exports.randomHook = randomHook;
function sha256Hook(input, output) {
    let result;
    try {
        result = crypto.createHash('sha256').update(input).digest();
    }
    catch (e) {
        return e;
    }
    result.copy(output);
    return result.length;
}
exports.sha256Hook = sha256Hook;
function makeHmacHook(algorithm) {
    return (key, input, output) => {
        let result;
        try {
            result = crypto.createHmac(algorithm, key).update(input).digest();
        }
        catch (e) {
            return e;
        }
        result.copy(output);
        return result.length;
    };
}
exports.makeHmacHook = makeHmacHook;
function signRsaSha256Hook(key, input, output) {
    let result;
    try {
        const signer = crypto.createSign('sha256WithRSAEncryption');
        const privateKey = Buffer.from(`-----BEGIN PRIVATE KEY-----\n${key.toString('base64')}\n-----END PRIVATE KEY-----\n`);
        result = signer.update(input).end().sign(privateKey);
    }
    catch (e) {
        return e;
    }
    result.copy(output);
    return result.length;
}
exports.signRsaSha256Hook = signRsaSha256Hook;
exports.aes256CbcEncryptHook = makeAES256Hook('createCipheriv', 'aes-256-cbc');
exports.aes256CbcDecryptHook = makeAES256Hook('createDecipheriv', 'aes-256-cbc');
exports.aes256CtrEncryptHook = makeAES256Hook('createCipheriv', 'aes-256-ctr');
exports.aes256CtrDecryptHook = makeAES256Hook('createDecipheriv', 'aes-256-ctr');
exports.hmacSha512Hook = makeHmacHook('sha512');
exports.hmacSha256Hook = makeHmacHook('sha256');
//# sourceMappingURL=crypto_callbacks.js.map