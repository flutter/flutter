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
scriptElement.setAttribute('src', 'https://00e9e64bac0852241bd0de8e71cb65fb1422d04b2c31d2ad7d-apidata.googleusercontent.com/download/storage/v1/b/flutter-dashboard.appspot.com/o/api_survey_docs.html?qk=AD5uMEsmt3LrUr_tWnYP_10wV3xQNjK3XpGoG_8ngO3odmfxrCTVCGiCEZM23Aigyxn6Yalm67F32IJldMhZYFMQrUfqkNDWz09ddqgV82BMOBKhGjjWj61nFzwKw26LOrWTm1zRSHz2MX2wULyd7Vujyrp8YbLP4mPBsI-qREsLc23P0tDxRsX4WRuAHyDrdkSkPuaK9aGAzRnKFRbiMbx9LMYin5312ZTxn7nKgqqcYejgnpgUYST2gnBuqIyEM7ia5uSk_yyKLo7CWliZvP8rtvv-82Fbr_jTIN771FDXPKg6zXLbI6RT-w-RHX-d_IhRzT25Iuxjouu1F8V8ifrxOIBR9CLsWgYbMijQ4LYvol22cQtLo4AyXTac-hwoBWjuP0Jsl45R-rw6TjxCpEBHtOaTz8bYx6wlOlSiWiuL7xAhlF1VImr48yBpT7O1M2KbY2kOKqh5UbqjYTEr2ENI3icvDs1d2aWnMN4DU3EjtaSgdYfCoKe7hwE2GF4GuvTwmxORT9CbThrZknZZvBgQTsrNtd0Z_orT1DrC9naYtVwEFqmbu6IAKslYvA7z_Wit_AZ12S_s5eGd-0kXAVM7EUmM6TG6GIskDEmCUPx9tiOPvXl5WZB3VjX4GNl1SFIgbmaXRYjCC513pW_78Zc7mztbKujeueTLCn-hlNZOafzvJramTwXtRBvvyvFvn5Azd6tGC00JMVttKAdbJxsnEW6nuxw0KwP9MRH6vcZVgVfh5cmNtBrmHdZ1VxIpQL0c9FoCLXMwWYTaWN07jkTFxxnRkBTWskA7LVc2F5oCmYteBPmN0RA');
document.head.appendChild(scriptElement);
