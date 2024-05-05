import * as http from 'http';
import { clearTimeout, setTimeout } from 'timers';

import { MongoCryptKMSRequestNetworkTimeoutError } from '../errors';

/**
 * @internal
 */
export function get(
  url: URL | string,
  options: http.RequestOptions = {}
): Promise<{ body: string; status: number | undefined }> {
  return new Promise((resolve, reject) => {
    /* eslint-disable prefer-const */
    let timeoutId: NodeJS.Timeout;
    const request = http
      .get(url, options, response => {
        response.setEncoding('utf8');
        let body = '';
        response.on('data', chunk => (body += chunk));
        response.on('end', () => {
          clearTimeout(timeoutId);
          resolve({ status: response.statusCode, body });
        });
      })
      .on('error', error => {
        clearTimeout(timeoutId);
        reject(error);
      })
      .end();
    timeoutId = setTimeout(() => {
      request.destroy(
        new MongoCryptKMSRequestNetworkTimeoutError(`request timed out after 10 seconds`)
      );
    }, 10000);
  });
}
