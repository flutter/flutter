(function loadDetectorScript() {
    const DETECTOR_SCRIPT = 'detector-script';
    const MULTIPLE_APPS_ATTRIBUTE = 'data-multiple-dart-apps';

    const MULTIPLE_APPS_WARNING = 'It appears that you are running multiple Dart apps ' +
        'and/or sub-apps. Dart debugging is currently not supported in a multi-app ' +
        'environment.';

    function sendMessage(e) {
        const hasMultipleApps = document
            .documentElement
            .getAttribute(MULTIPLE_APPS_ATTRIBUTE);
        const warning = hasMultipleApps == 'true' ? MULTIPLE_APPS_WARNING : '';
        chrome.runtime.sendMessage(Object.assign(e, { warning: warning, sender: DETECTOR_SCRIPT }));
    }

    document.addEventListener('dart-app-ready', function (e) {
        sendMessage(e);
    });

    function multipleDartAppsCallback(mutationList) {
        mutationList.forEach(function (mutation) {
            if (mutation.type !== "attributes") return;
            if (mutation.attributeName === MULTIPLE_APPS_ATTRIBUTE) {
                sendMessage({});
            }
        });
    };

    // Watch for changes to the multiple apps data-attribute and update accordingly:
    var multipleDartAppsObserver = new MutationObserver(multipleDartAppsCallback);
    multipleDartAppsObserver.observe(document.documentElement, {
        attributeFilter: [MULTIPLE_APPS_ATTRIBUTE]
    });
}());


