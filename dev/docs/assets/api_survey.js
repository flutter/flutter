window.ApiSurveyDocs = function(apiPages) {
  var url = window.location.href;
  var fragments = url.split('/');
  if (fragments == null || fragments.length == 0) {
    return;
  }
  var classFragment = fragments[fragments.length -1];
  if (classFragment == null) {
    return;
  }
  var apiDocClassFragments = classFragment.split('-');
  if (apiDocClassFragments.length != 2) {
    return;
  }
  var apiDocClass = apiDocClassFragments[0];
  if (url == null || apiPages.indexOf(apiDocClass) == -1) {
    return;
  }
  scriptElement = document.createElement('script');
  scriptElement.setAttribute('src', 'https://www.google.com/insights/consumersurveys/async_survey?site=sygvgfetfwmwm7isniaym3m6f4');
  document.head.appendChild(scriptElement);
}
scriptElement = document.createElement('script');
scriptElement.setAttribute('src', 'https://storage.googleapis.com/flutter-dashboard.appspot.com/api_survey/api_survey_docs.html');
document.head.appendChild(scriptElement);
