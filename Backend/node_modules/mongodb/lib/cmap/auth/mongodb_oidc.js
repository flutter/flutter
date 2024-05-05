"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.MongoDBOIDC = exports.OIDC_WORKFLOWS = void 0;
const error_1 = require("../../error");
const auth_provider_1 = require("./auth_provider");
const aws_service_workflow_1 = require("./mongodb_oidc/aws_service_workflow");
const azure_service_workflow_1 = require("./mongodb_oidc/azure_service_workflow");
const callback_workflow_1 = require("./mongodb_oidc/callback_workflow");
/** Error when credentials are missing. */
const MISSING_CREDENTIALS_ERROR = 'AuthContext must provide credentials.';
/** @internal */
exports.OIDC_WORKFLOWS = new Map();
exports.OIDC_WORKFLOWS.set('callback', new callback_workflow_1.CallbackWorkflow());
exports.OIDC_WORKFLOWS.set('aws', new aws_service_workflow_1.AwsServiceWorkflow());
exports.OIDC_WORKFLOWS.set('azure', new azure_service_workflow_1.AzureServiceWorkflow());
/**
 * OIDC auth provider.
 * @experimental
 */
class MongoDBOIDC extends auth_provider_1.AuthProvider {
    /**
     * Instantiate the auth provider.
     */
    constructor() {
        super();
    }
    /**
     * Authenticate using OIDC
     */
    async auth(authContext) {
        const { connection, reauthenticating, response } = authContext;
        const credentials = getCredentials(authContext);
        const workflow = getWorkflow(credentials);
        await workflow.execute(connection, credentials, reauthenticating, response);
    }
    /**
     * Add the speculative auth for the initial handshake.
     */
    async prepare(handshakeDoc, authContext) {
        const credentials = getCredentials(authContext);
        const workflow = getWorkflow(credentials);
        const result = await workflow.speculativeAuth(credentials);
        return { ...handshakeDoc, ...result };
    }
}
exports.MongoDBOIDC = MongoDBOIDC;
/**
 * Get credentials from the auth context, throwing if they do not exist.
 */
function getCredentials(authContext) {
    const { credentials } = authContext;
    if (!credentials) {
        throw new error_1.MongoMissingCredentialsError(MISSING_CREDENTIALS_ERROR);
    }
    return credentials;
}
/**
 * Gets either a device workflow or callback workflow.
 */
function getWorkflow(credentials) {
    const providerName = credentials.mechanismProperties.PROVIDER_NAME;
    const workflow = exports.OIDC_WORKFLOWS.get(providerName || 'callback');
    if (!workflow) {
        throw new error_1.MongoInvalidArgumentError(`Could not load workflow for provider ${credentials.mechanismProperties.PROVIDER_NAME}`);
    }
    return workflow;
}
//# sourceMappingURL=mongodb_oidc.js.map