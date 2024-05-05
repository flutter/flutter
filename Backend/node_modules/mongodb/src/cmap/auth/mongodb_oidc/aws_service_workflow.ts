import * as fs from 'fs';

import { MongoAWSError } from '../../../error';
import { ServiceWorkflow } from './service_workflow';

/** Error for when the token is missing in the environment. */
const TOKEN_MISSING_ERROR = 'AWS_WEB_IDENTITY_TOKEN_FILE must be set in the environment.';

/**
 * Device workflow implementation for AWS.
 *
 * @internal
 */
export class AwsServiceWorkflow extends ServiceWorkflow {
  constructor() {
    super();
  }

  /**
   * Get the token from the environment.
   */
  async getToken(): Promise<string> {
    const tokenFile = process.env.AWS_WEB_IDENTITY_TOKEN_FILE;
    if (!tokenFile) {
      throw new MongoAWSError(TOKEN_MISSING_ERROR);
    }
    return fs.promises.readFile(tokenFile, 'utf8');
  }
}
