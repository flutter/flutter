"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AzureServiceWorkflow = void 0;
const error_1 = require("../../../error");
const utils_1 = require("../../../utils");
const azure_token_cache_1 = require("./azure_token_cache");
const service_workflow_1 = require("./service_workflow");
/** Base URL for getting Azure tokens. */
const AZURE_BASE_URL = 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01';
/** Azure request headers. */
const AZURE_HEADERS = Object.freeze({ Metadata: 'true', Accept: 'application/json' });
/** Invalid endpoint result error. */
const ENDPOINT_RESULT_ERROR = 'Azure endpoint did not return a value with only access_token and expires_in properties';
/** Error for when the token audience is missing in the environment. */
const TOKEN_AUDIENCE_MISSING_ERROR = 'TOKEN_AUDIENCE must be set in the auth mechanism properties when PROVIDER_NAME is azure.';
/**
 * Device workflow implementation for Azure.
 *
 * @internal
 */
class AzureServiceWorkflow extends service_workflow_1.ServiceWorkflow {
    constructor() {
        super(...arguments);
        this.cache = new azure_token_cache_1.AzureTokenCache();
    }
    /**
     * Get the token from the environment.
     */
    async getToken(credentials) {
        const tokenAudience = credentials?.mechanismProperties.TOKEN_AUDIENCE;
        if (!tokenAudience) {
            throw new error_1.MongoAzureError(TOKEN_AUDIENCE_MISSING_ERROR);
        }
        let token;
        const entry = this.cache.getEntry(tokenAudience);
        if (entry?.isValid()) {
            token = entry.token;
        }
        else {
            this.cache.deleteEntry(tokenAudience);
            const response = await getAzureTokenData(tokenAudience);
            if (!isEndpointResultValid(response)) {
                throw new error_1.MongoAzureError(ENDPOINT_RESULT_ERROR);
            }
            this.cache.addEntry(tokenAudience, response);
            token = response.access_token;
        }
        return token;
    }
}
exports.AzureServiceWorkflow = AzureServiceWorkflow;
/**
 * Hit the Azure endpoint to get the token data.
 */
async function getAzureTokenData(tokenAudience) {
    const url = `${AZURE_BASE_URL}&resource=${tokenAudience}`;
    const data = await (0, utils_1.request)(url, {
        json: true,
        headers: AZURE_HEADERS
    });
    return data;
}
/**
 * Determines if a result returned from the endpoint is valid.
 * This means the result is not nullish, contains the access_token required field
 * and the expires_in required field.
 */
function isEndpointResultValid(token) {
    if (token == null || typeof token !== 'object')
        return false;
    return 'access_token' in token && 'expires_in' in token;
}
//# sourceMappingURL=azure_service_workflow.js.map