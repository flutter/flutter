import * as crypto from 'crypto';

import { MongoMissingCredentialsError } from '../../error';
import { ns } from '../../utils';
import { type AuthContext, AuthProvider } from './auth_provider';

export class MongoCR extends AuthProvider {
  override async auth(authContext: AuthContext): Promise<void> {
    const { connection, credentials } = authContext;
    if (!credentials) {
      throw new MongoMissingCredentialsError('AuthContext must provide credentials.');
    }

    const { username, password, source } = credentials;

    const { nonce } = await connection.command(ns(`${source}.$cmd`), { getnonce: 1 }, undefined);

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

    await connection.command(ns(`${source}.$cmd`), authenticateCommand, undefined);
  }
}
