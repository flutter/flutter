(function loadPanelScript() {
    // Variables:
    const IFRAME_TAG = 'iframe';
    const IFRAME_CONTAINER = 'iframeContainer';
    const IFRAME_ID = 'dartDevToolsEmbed';
    const DEBUGGING_BUTTON = 'debuggingButton';
    const CHROME_DARK = 'dark';
    const DARK_COLOR = '202125';
    const LIGHT_COLOR = 'ffffff';
    const PANEL_SCRIPT = 'panel-script';
    const START_DEBUGGING = 'start-debugging';
    const DEVTOOLS_OPEN = 'devtools-open';
    const PANEL_BODY = 'panelBody';
    const PANEL_ATTRIBUTE = 'data-panel';

    const chromeTheme = chrome.devtools.panels.themeName;
    const backgroundColor = chromeTheme == CHROME_DARK ? DARK_COLOR : LIGHT_COLOR;
    const fontColor = chromeTheme == CHROME_DARK ? LIGHT_COLOR : DARK_COLOR;

    let appId = null;
    let currentDevToolsUrl = '';
    let panel = '';

    // Helper functions:
    function sendStartDebuggingRequest() {
        if (!appId) return;
        document.getElementById(DEBUGGING_BUTTON).setAttribute('disabled', true);
        chrome.runtime.sendMessage({ sender: PANEL_SCRIPT, message: START_DEBUGGING, dartAppId: appId });
    }

    window.onload = function () {
        panel = document.getElementById(PANEL_BODY).getAttribute(PANEL_ATTRIBUTE)
        document.getElementById(DEBUGGING_BUTTON).addEventListener('click', sendStartDebuggingRequest);
        // Set the background and text color of the panel to match the Chrome theme:
        document.body.style.backgroundColor = `#${backgroundColor}`;
        document.body.style.color = `#${fontColor}`;
    };

    chrome.runtime.onMessage.addListener(function (request) {
        // Only listen for messages meant for the panel:
        if (request.recipient != PANEL_SCRIPT) return;

        const devToolsUrl = request.body;
        const iframeContainer = document.getElementById(IFRAME_CONTAINER);

        if (devToolsUrl != currentDevToolsUrl) {
            currentDevToolsUrl = devToolsUrl;

            if (!devToolsUrl) {
                // Debugger has been disconnected, remove the IFRAME for Dart DevTools
                // and enable the start debugging button:
                document.getElementById(DEBUGGING_BUTTON).removeAttribute('disabled');
                const iframe = document.getElementById(IFRAME_ID);
                if (!!iframe) iframeContainer.removeChild(iframe);
            } else {
                // Debugger has benn connected, add an IFRAME for Dart DevTools:
                const iframe = document.createElement(IFRAME_TAG);
                if (panel == '') return;
                const src = `${devToolsUrl}&embed=true&page=${panel}&backgroundColor=${backgroundColor}`;
                iframe.setAttribute('src', src);
                iframe.setAttribute('scrolling', 'no');
                iframe.id = IFRAME_ID;   
                iframeContainer.appendChild(iframe);
            }
        }

    });

    chrome.devtools.inspectedWindow.eval(
        `
        function findDartAppId(frame) {
            if (frame.$dartAppId) return frame.$dartAppId;
            const frames = frame.frames;
            for (let i = 0; i < frames.length; i++) {
                return findDartAppId(frames[i]);
            }
        }
        findDartAppId(window);
        `,
        function (dartAppId) {
            appId = dartAppId;
            document.getElementById(DEBUGGING_BUTTON).removeAttribute('disabled');
            chrome.runtime.sendMessage({ sender: PANEL_SCRIPT, message: DEVTOOLS_OPEN, dartAppId: dartAppId });
        },
    );
}());