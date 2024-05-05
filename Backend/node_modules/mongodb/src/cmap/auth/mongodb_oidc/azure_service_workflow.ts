import { MongoAzureError } from '../../../error';
import { request } from '../../../utils';
import type { MongoCredentials } from '../mongo_credentials';
import { AzureTokenCache } from './azure_token_cache';
import { ServiceWorkflow } from './service_workflow';

/** Base URL for getting Azure tokens. */
const AZURE_BASE_URL =
  'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01';

/** Azure request headers. */
const AZURE_HEADERS = Object.freeze({ Metadata: 'true', Accept: 'application/json' });

/** Invalid endpoint result error. */
const ENDPOINT_RESULT_ERROR =
  'Azure endpoint did not return a value with only access_token and expires_in properties';

/** Error for when the token audience is missing in the environment. */
const TOKEN_AUDIENCE_MISSING_ERROR =
  'TOKEN_AUDIENCE must be set in the auth mechanism properties when PROVIDER_NAME is azure.';

/**
 * The Azure access token format.
 * @internal
 */
export interface AzureAccessToken {
  access_token: string;
  expires_in: number;
}

/**
 * Device workflow implementation for Azure.
 *
 * @internal
 */
export class AzureServiceWorkflow extends ServiceWorkflow {
  cache = new AzureTokenCache();

  /**
   * Get the token from the environment.
   */
  async getToken(credentials?: MongoCredentials): Promise<string> {
    const tokenAudience = credentials?.mechanismProperties.TOKEN_AUDIENCE;
    if (!tokenAudience) {
      throw new MongoAzureError(TOKEN_AUDIENCE_MISSING_ERROR);
    }
    let token;
    const entry = this.cache.getEntry(tokenAudience);
    if (entry?.isValid()) {
      token = entry.token;
    } else {
      this.cache.deleteEntry(tokenAudience);
      const response = await getAzureTokenData(tokenAudience);
      if (!isEndpointResultValid(response)) {
        throw new MongoAzureError(ENDPOINT_RESULT_ERROR);
      }
      this.cache.addEntry(tokenAudience, response);
      token = response.access_token;
    }
    return token;
  }
}

/**
 * Hit the Azure endpoint to get the token data.
 */
async function getAzureTokenData(tokenAudience: string): Promise<AzureAccessToken> {
  const url = `${AZURE_BASE_URL}&resource=${tokenAudience}`;
  const data = await request(url, {
    json: true,
    headers: AZURE_HEADERS
  });
  return data as AzureAccessToken;
}

/**
 * Determines if a result returned from the endpoint is valid.
 * This means the result is not nullish, contains the access_token required field
 * and the expires_in required field.
 */
function isEndpointResultValid(
  token: unknown
): token is { access_token: unknown; expires_in: unknown } {
  if (token == null || typeof token !== 'object') return false;
  return 'access_token' in token && 'expires_in' in token;
}
