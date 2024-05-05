"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.MongoCR = void 0;
const crypto = require("crypto");
const error_1 = require("../../error");
const utils_1 = require("../../utils");
const auth_provider_1 = require("./auth_provider");
class MongoCR extends auth_provider_1.AuthProvider {
    async auth(authContext) {
        const { connection, credentials } = authContext;
        if (!credentials) {
            throw new error_1.MongoMissingCredentialsError('AuthContext must provide credentials.');
        }
        const { username, password, source } = credentials;
        const { nonce } = await connection.command((0, utils_1.ns)(`${source}.$cmd`), { getnonce: 1 }, undefined);
        const hashPassword = crypto
            .createHash('md5')
            .update(`${username}:mongo:${password}`, 'utf8')
            .digest('hex');
        // Final key
        const key = crypto
            .createHash('md5')
            .update(`${nonce}${username}${hashPassword}`, 'utf8')
            .digest('hex');
        const authenticateCommand = {
            authenticate: 1,
            user: username,
            nonce,
            key
        };
        await connection.command((0, utils_1.ns)(`${source}.$cmd`), authenticateCommand, undefined);
    }
}
exports.MongoCR = MongoCR;
//# sourceMappingURL=mongocr.js.map