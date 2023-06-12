import '../../async_core.dart' as async_core;
import '../request/async_io_request_client.dart';
import 'web_driver.dart';
import 'web_element.dart';

/// Returns an [async_core.WebDriver] with the same URI + session ID.
async_core.WebDriver createAsyncWebDriver(WebDriver driver) =>
    async_core.WebDriver(
        driver.uri,
        driver.id,
        driver.capabilities,
        AsyncIoRequestClient(driver.uri.resolve('session/${driver.id}/')),
        driver.spec);

/// Returns an [async_core.WebElement] based on a current [WebElement].
async_core.WebElement createAsyncWebElement(WebElement element) =>
    createAsyncWebDriver(element.driver).getElement(element.id);
