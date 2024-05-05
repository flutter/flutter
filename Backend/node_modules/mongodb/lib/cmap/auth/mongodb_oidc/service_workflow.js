"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.commandDocument = exports.ServiceWorkflow = void 0;
const bson_1 = require("bson");
const utils_1 = require("../../../utils");
const providers_1 = require("../providers");
/**
 * Common behaviour for OIDC device workflows.
 * @internal
 */
class ServiceWorkflow {
    /**
     * Execute the workflow. Looks for AWS_WEB_IDENTITY_TOKEN_FILE in the environment
     * and then attempts to read the token from that path.
     */
    async execute(connection, credentials) {
        const token = await this.getToken(credentials);
        const command = commandDocument(token);
        return connection.command((0, utils_1.ns)(credentials.source), command, undefined);
    }
    /**
     * Get the document to add for speculative authentication.
     */
    async speculativeAuth(credentials) {
        const token = await this.getToken(credentials);
        const document = commandDocument(token);
        document.db = credentials.source;
        return { speculativeAuthenticate: document };
    }
}
exports.ServiceWorkflow = ServiceWorkflow;
/**
 * Create the saslStart command document.
 */
function commandDocument(token) {
    return {
        saslStart: 1,
        mechanism: providers_1.AuthMechanism.MONGODB_OIDC,
        payload: bson_1.BSON.serialize({ jwt: token })
    };
}
exports.commandDocument = commandDocument;
//# sourceMappingURL=service_workflow.js.map