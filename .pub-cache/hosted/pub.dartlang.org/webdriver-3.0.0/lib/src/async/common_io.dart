import '../../sync_core.dart' as sync_core;
import '../request/sync_http_request_client.dart';
import 'web_driver.dart';

/// Returns a [sync_core.WebDriver] with the same URI + session ID.
sync_core.WebDriver createSyncWebDriver(WebDriver driver) =>
    sync_core.WebDriver(
        driver.uri,
        driver.id,
        driver.capabilities,
        SyncHttpRequestClient(driver.uri.resolve('session/${driver.id}/')),
        driver.spec);
