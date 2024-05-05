"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.get = void 0;
const http = require("http");
const timers_1 = require("timers");
const errors_1 = require("../errors");
/**
 * @internal
 */
function get(url, options = {}) {
    return new Promise((resolve, reject) => {
        /* eslint-disable prefer-const */
        let timeoutId;
        const request = http
            .get(url, options, response => {
            response.setEncoding('utf8');
            let body = '';
            response.on('data', chunk => (body += chunk));
            response.on('end', () => {
                (0, timers_1.clearTimeout)(timeoutId);
                resolve({ status: response.statusCode, body });
            });
        })
            .on('error', error => {
            (0, timers_1.clearTimeout)(timeoutId);
            reject(error);
        })
            .end();
        timeoutId = (0, timers_1.setTimeout)(() => {
            request.destroy(new errors_1.MongoCryptKMSRequestNetworkTimeoutError(`request timed out after 10 seconds`));
        }, 10000);
    });
}
exports.get = get;
//# sourceMappingURL=utils.js.map