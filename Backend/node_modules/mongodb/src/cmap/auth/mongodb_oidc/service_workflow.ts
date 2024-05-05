import { BSON, type Document } from 'bson';

import { ns } from '../../../utils';
import type { Connection } from '../../connection';
import type { MongoCredentials } from '../mongo_credentials';
import type { Workflow } from '../mongodb_oidc';
import { AuthMechanism } from '../providers';

/**
 * Common behaviour for OIDC device workflows.
 * @internal
 */
export abstract class ServiceWorkflow implements Workflow {
  /**
   * Execute the workflow. Looks for AWS_WEB_IDENTITY_TOKEN_FILE in the environment
   * and then attempts to read the token from that path.
   */
  async execute(connection: Connection, credentials: MongoCredentials): Promise<Document> {
    const token = await this.getToken(credentials);
    const command = commandDocument(token);
    return connection.command(ns(credentials.source), command, undefined);
  }

  /**
   * Get the document to add for speculative authentication.
   */
  async speculativeAuth(credentials: MongoCredentials): Promise<Document> {
    const token = await this.getToken(credentials);
    const document = commandDocument(token);
    document.db = credentials.source;
    return { speculativeAuthenticate: document };
  }

  /**
   * Get the token from the environment or endpoint.
   */
  abstract getToken(credentials: MongoCredentials): Promise<string>;
}

/**
 * Create the saslStart command document.
 */
export function commandDocument(token: string): Document {
  return {
    saslStart: 1,
    mechanism: AuthMechanism.MONGODB_OIDC,
    payload: BSON.serialize({ jwt: token })
  };
}
