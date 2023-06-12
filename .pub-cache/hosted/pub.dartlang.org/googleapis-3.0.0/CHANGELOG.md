## 3.0.0

### API updates

- `adsense` - added v2 API
- `apikeys` - new!
- `baremetalsolution` - new!
- `chromepolicy` - new!
- `datamigration` - new!
- `documentai` - new!
- `essentialcontacts` - new!
- `genomics` - **REMOVED** - use the `lifesciences` API in `googleapis_beta`.
- `gkehub` - new!
- `mybusinesslodging` - new!
- `mybusinessplaceactions` - new!
- `ondemandscanning` - new!
- `orgpolicy` - new!
- `policysimulator` - new!
- `recaptchaenterprise` - new!
- `remotebuildexecution` - **REMOVED** - not a valid API.

## 2.0.0

- APIs are now null-safe and require Dart 2.12.
- Now requires `package:_discoveryapis_commons` v1.

### API updates

- `cloudresourcemanager` - added v3
- `mybusinessaccountmanagement` - added v1
- `webrisk` - added v1

## 1.0.0

### BREAKING changes to API shape

* `USER_AGENT` has been removed from each library. All libraries within the
  package share a common user-agent value.
* API classes have been renamed to use more standard casing.
  For example: `FirebasedynamiclinksApi` to `FirebaseDynamicLinksApi`.
* Resource classes have been renamed to drop the `Api` suffix.
  For example: `ManagedShortLinksResourceApi` to `ManagedShortLinksResource`.

### API updates

- `apigateway` - new
- `artifactregistry` - new
- `assuredworkloads` - new
- `billingbudgets` - new
- `chromemanagement` - new
- `chromeuxreport` - new
- `cloudchannel` - new
- `datafusion` - new
- `dialogflow` - added v3 API
- `eventarc` - new
- `firebasehosting` - new
- `firebaseml` - new
- `gameservices` - new
- `gmailpostmastertools` - new
- `jobs` - dropped v2, added v3 API
- `localservices` - new
- `memcache` - new
- `notebooks` - new
- `playablelocations` - new
- `pubsublite` - new
- `realtimebidding` - new
- `retail` - new
- `servicecontrol` - added v2 API
- `servicedirectory` - new
- `smartdevicemanagement` - new
- `sts` - new
- `trafficdirector` - new
- `vectortile` - new
- `workflowexecutions` - new
- `workflows` - new
- `youtubeAnalytics` - dropped v1 API

## 0.56.1
 * [api-add] oauth2:v2 (appears to have been unintentionally missing from 0.55.0)

## 0.56.0
 * [api-new] networkmanagement:v1
 * [api-new] recommender:v1
 * [api-removed] androidpublisher:v2
 * [api-removed] appsactivity:v1
 * [api-removed] oauth2:v2
 * [api-removed] plus:v1

## 0.55.0
 * [api-new] accessapproval:v1
 * [api-new] admob:v1
 * [api-new] apigee:v1
 * [api-new] bigqueryreservation:v1
 * [api-new] binaryauthorization:v1
 * [api-new] dfareporting:v3.4
 * [api-new] displayvideo:v1
 * [api-new] domainsrdap:v1
 * [api-new] doubleclickbidmanager:v1.1
 * [api-new] healthcare:v1
 * [api-new] homegraph:v1
 * [api-new] osconfig:v1
 * [api-new] policytroubleshooter:v1
 * [api-new] secretmanager:v1
 * [api-new] managedidentities:v1
 * [api-new] translate:v3
 * [api-new] verifiedaccess:v1
 * [api-removed] appstate:v1
 * [api-removed] fusiontables:v1
 * [api-removed] fusiontables:v2
 * [api-removed] mirror:v1
 * [api-removed] plusDomains:v1
 * [api-removed] servicebroker:v1
 * [api-removed] surveys:v2
 * [api-removed] urlshortener:v1
 * [api-removed] dfareporting:v3.3
 * [api-removed] doubleclickbidmanager:v1
 * [api-removed] translate:v2

## 0.54.0

 * [api-new] accesscontextmanager:v1
 * [api-new] cloudasset:v1
 * [api-new] cloudscheduler:v1
 * [api-new] cloudtasks:v2
 * [api-new] dfareporting:v3.3
 * [api-new] docs:v1
 * [api-new] fcm:v1
 * [api-new] file:v1
 * [api-new] remotebuildexecution:v2
 * [api-new] run:v1
 * [api-new] securitycenter:v1
 * [api-new] servicenetworking:v1
 * [api-new] websecurityscanner:v1
 * [api-removed] dfareporting:v3.2

## 0.53.0

 * [api-new] bigtableadmin:v2
 * [api-new] cloudidentity:v1
 * [api-new] cloudsearch:v1
 * [api-new] content:v2_1
 * [api-new] driveactivity:v2
 * [api-new] iap:v1
 * [api-new] libraryagent:v1
 * [api-new] pagespeedonline:v5
 * [api-new] redis:v1
 * [api-removed] adexchangeseller:v1_1
 * [api-removed] adexchangeseller:v2_0
 * [api-removed] cloudtrace:v1
 * [api-removed] content:v2
 * [api-removed] content:v2sandbox
 * [api-removed] dfareporting:v2_8
 * [api-removed] dfareporting:v3_0
 * [api-removed] dfareporting:v3_1
 * [api-removed] firebaseremoteconfig:v1
 * [api-removed] partners:v2
 * [api-removed] serviceuser:v1

## 0.52.0+1

* Regenerate package with widened constraint for `package:http`.

## 0.52.0

* [api-new] dfareporting:v3_1
* [api-new] dfareporting:v3_2
* [api-new] dlp:v2
* [api-new] cloudprofiler:v2
* [api-new] firestore:v1
* [api-new] serviceusage:v1
* [api-new] tpu:v1
* [api-new] youtubeanalytics:v2
* [api-new] dialogflow:v2
* [api-new] pagespeedonline:v4
* [api-new] indexing:v3
* [api-new] jobs:v2
* [api-new] jobs:v3
* [api-new] videointelligence:v1
* [api-new] cloudresourcemanager:v2
* [api-new] texttospeech:v1
* [api-new] iamcredentials:v1
* [api-new] chat:v1
* [api-new] composer:v1
* [api-new] androidpublisher:v3
* [api-new] servicebroker:v1
* [api] adsense:v1_4
* [api] spanner:v1
* [api] poly:v1
* [api] vision:v1
* [api] vault:v1
* [api] gmail:v1
* [api] logging:v2
* [api] cloudbilling:v1
* [api] container:v1
* [api] ml:v1
* [api] sourcerepo:v1
* [api] dataproc:v1
* [api] iam:v1
* [api] androiddeviceprovisioning:v1
* [api] firebaserules:v1
* [api] serviceconsumermanagement:v1
* [api] cloudiot:v1
* [api] monitoring:v3
* [api] books:v1
* [api] cloudfunctions:v1
* [api] servicecontrol:v1
* [api] drive:v2
* [api] drive:v3
* [api] content:v2
* [api] content:v2sandbox
* [api] clouddebugger:v2
* [api] testing:v1
* [api] cloudbuild:v1
* [api] serviceuser:v1
* [api] cloudresourcemanager:v1
* [api] servicemanagement:v1
* [api] genomics:v1
* [api] script:v1
* [api] admin:directory_v1
* [api] groupssettings:v1
* [api] pubsub:v1
* [api] datastore:v1
* [api] classroom:v1
* [api] analytics:v3
* [api] androidmanagement:v1
* [api] androidpublisher:v2
* [api] cloudkms:v1
* [api] bigquery:v2
* [api] civicinfo:v2
* [api] appengine:v1
* [api] compute:v1
* [api-breaking] dns:v1
* [api-breaking] serviceconsumermanagement:v1
* [api-breaking] cloudiot:v1
* [api-breaking] script:v1
* [api-breaking] androidenterprise:v1
* [api-breaking] civicinfo:v2
* [api-removed] firebaseremoteconfig:v1
* [api-removed] prediction:v1_6

## 0.51.1

* Support Dart 2 stable.

## 0.51.0

* [api-new] cloudresourcemanager:v2
* [api-new] dfareporting:v3_1
* [api-new] dlp:v2
* [api-new] jobs:v2
* [api-new] servicebroker:v1
* [api-new] tpu:v1
* [api-new] videointelligence:v1
* [api] adexchangebuyer:v1_4
* [api] admin:directory_v1
* [api] analytics:v3
* [api] androiddeviceprovisioning:v1
* [api] androidenterprise:v1
* [api] androidmanagement:v1
* [api] androidpublisher:v2
* [api] appengine:v1
* [api] bigquerydatatransfer:v1
* [api] bigquery:v2
* [api] cloudbilling:v1
* [api] cloudbuild:v1
* [api] cloudfunctions:v1
* [api] cloudiot:v1
* [api] cloudkms:v1
* [api] compute:v1
* [api] container:v1
* [api] content:v2
* [api] content:v2sandbox
* [api] customsearch:v1
* [api] dataproc:v1
* [api] datastore:v1
* [api] deploymentmanager:v2
* [api] dns:v1
* [api] firebasedynamiclinks:v1
* [api] genomics:v1
* [api] identitytoolkit:v3
* [api] logging:v2
* [api] manufacturers:v1
* [api] ml:v1
* [api] monitoring:v3
* [api] oslogin:v1
* [api] partners:v2
* [api] people:v1
* [api] poly:v1
* [api] servicemanagement:v1
* [api] serviceuser:v1
* [api] sheets:v4
* [api] slides:v1
* [api] sourcerepo:v1
* [api] speech:v1
* [api] testing:v1
* [api] vault:v1
* [api] vision:v1
* [api] youtube:v3
* [api-breaking] analytics:v3
* [api-breaking] androidpublisher:v2
* [api-breaking] bigquery:v2
* [api-breaking] classroom:v1
* [api-breaking] cloudiot:v1
* [api-breaking] deploymentmanager:v2
* [api-breaking] manufacturers:v1
* [api-breaking] serviceconsumermanagement:v1
* [api-breaking] servicemanagement:v1
* [api-breaking] serviceuser:v1
* [api-breaking] sourcerepo:v1
* [api-breaking] speech:v1
* [api-breaking] surveys:v2
* [api-breaking] youtube:v3
* [api-removed] cloudresourcemanager:v2beta1
* [api-removed] serviceusage:v1

## 0.50.4

* Re-generated with updated code generator to support the dataWrapper feature
  (used by the Translate v2 API).

## 0.50.3

* Re-generated with updated code generator to support Dart 2.

## 0.50.2

* Re-generated with updated code generator to support Dart 2.

## 0.50.1

* Re-generated with updated code generator to support Dart 2.

## 0.50.0

* [api-new] serviceusage:v1
* [api] androidenterprise:v1
* [api] androidmanagement:v1
* [api] appengine:v1
* [api] bigquery:v2
* [api] calendar:v3
* [api] cloudiot:v1
* [api] compute:v1
* [api] doubleclickbidmanager:v1
* [api] gmail:v1
* [api] iam:v1
* [api] manufacturers:v1
* [api] ml:v1
* [api] monitoring:v3
* [api] poly:v1
* [api] safebrowsing:v4
* [api] serviceconsumermanagement:v1
* [api] servicemanagement:v1
* [api] sheets:v4
* [api] slides:v1
* [api] spanner:v1
* [api] testing:v1
* [api] youtube:v3
* [api-breaking] bigquery:v2
* [api-breaking] bigquery:v2
* [api-breaking] cloudiot:v1
* [api-breaking] manufacturers:v1
* [api-breaking] ml:v1
* [api-breaking] servicemanagement:v1

## 0.49.0

* [api] analytics:v3
* [api] androidenterprise:v1
* [api] androidmanagement:v1
* [api] appengine:v1
* [api] books:v1
* [api] compute:v1
* [api] content:v2
* [api] content:v2sandbox
* [api] drive:v2
* [api] drive:v3
* [api] firebasedynamiclinks:v1
* [api] iam:v1
* [api] logging:v2
* [api] ml:v1
* [api] pagespeedonline:v1
* [api] pagespeedonline:v2
* [api] pubsub:v1
* [api] safebrowsing:v4
* [api] script:v1
* [api] sheets:v4
* [api] slides:v1
* [api] speech:v1
* [api] vision:v1
* [api-breaking] appsactivity:v1
* [api-breaking] cloudiot:v1
* [api-breaking] cloudkms:v1
* [api-breaking] firebaserules:v1
* [api-breaking] games:v1
* [api-breaking] ml:v1
* [api-breaking] oslogin:v1
* [api-breaking] partners:v2
* [api-breaking] serviceconsumermanagement:v1
* [api-breaking] servicemanagement:v1
* [api-breaking] serviceuser:v1
* [api-breaking] speech:v1

## 0.48.0

* [api] classroom:v1
* [api] content:v2
* [api] content:v2sandbox
* [api] androiddeviceprovisioning:v1
* [api] monitoring:v3
* [api] storage:v1
* [api] androidpublisher:v2
* [api] androidmanagement:v1
* [api] cloudtrace:v2
* [api] youtubereporting:v1
* [api] servicecontrol:v1
* [api] cloudbuild:v1
* [api] calendar:v3
* [api] slides:v1
* [api] bigquery:v2
* [api] ml:v1
* [api] sheets:v4
* [api] testing:v1
* [api] safebrowsing:v4
* [api] androidenterprise:v1
* [api] admin:reports_v1
* [api] admin:directory_v1
* [api-breaking] cloudtrace:v2
* [api-breaking] youtubereporting:v1
* [api-breaking] iam:v1
* [api-breaking] speech:v1
* [api-breaking] youtube:v3
* [api-removed] consumersurveys:v2

## 0.47.1

* [api-new] oslogin:v1
* [api-new] poly:v1
* [api-new] serviceconsumermanagement:v1
* [api] admin:directory_v1
* [api] androidenterprise:v1
* [api] androidmanagement:v1
* [api] appengine:v1
* [api] cloudbuild:v1
* [api] content:v2
* [api] content:v2sandbox
* [api] fusiontables:v2
* [api] ml:v1
* [api] monitoring:v3
* [api] pubsub:v1
* [api] slides:v1
* [api] speech:v1
* [api] youtube:v3

## 0.47.0

* [api-new] dfareporting:v3_0
* [api] analyticsreporting:v4
* [api] androidenterprise:v1
* [api] bigquerydatatransfer:v1
* [api] bigquery:v2
* [api] classroom:v1
* [api] cloudbuild:v1
* [api] cloudfunctions:v1
* [api] drive:v2
* [api] drive:v3
* [api] firebasedynamiclinks:v1
* [api] firebaseremoteconfig:v1
* [api] language:v1
* [api] logging:v2
* [api] ml:v1
* [api] tagmanager:v1
* [api] tagmanager:v2
* [api-breaking] androidpublisher:v2
* [api-breaking] appengine:v1
* [api-breaking] bigquerydatatransfer:v1
* [api-breaking] content:v2
* [api-breaking] content:v2sandbox
* [api-breaking] monitoring:v3
* [api-breaking] script:v1
* [api-breaking] servicemanagement:v1
* [api-breaking] serviceuser:v1
* [api-breaking] storage:v1
* [api-breaking] tagmanager:v1
* [api-removed] playmoviespartner:v1

## 0.46.0

* [api] admin:directory_v1
* [api] bigquery:v2
* [api] cloudfunctions:v1
* [api] cloudtrace:v2
* [api] compute:v1
* [api] datastore:v1
* [api] firebasedynamiclinks:v1
* [api] firebaserules:v1
* [api] manufacturers:v1
* [api] monitoring:v3
* [api] partners:v2
* [api] slides:v1
* [api] speech:v1
* [api-breaking] cloudtrace:v2
* [api-breaking] manufacturers:v1
* [api-breaking] servicecontrol:v1

## 0.45.0
* [api-new] cloudiot:v1
* [api-new] testing:v1
* [api] admin:directory_v1
* [api] androidenterprise:v1
* [api] androidmanagement:v1
* [api] appengine:v1
* [api] bigquerydatatransfer:v1
* [api] bigquery:v2
* [api] classroom:v1
* [api] cloudfunctions:v1
* [api] compute:v1
* [api] container:v1
* [api] content:v2
* [api] content:v2sandbox
* [api] firebaserules:v1
* [api] fitness:v1
* [api] identitytoolkit:v3
* [api] language:v1
* [api] ml:v1
* [api] people:v1
* [api] servicecontrol:v1
* [api] servicemanagement:v1
* [api] serviceuser:v1
* [api] sheets:v4
* [api] sourcerepo:v1
* [api] spanner:v1
* [api] streetviewpublish:v1
* [api] tagmanager:v2
* [api] vault:v1
* [api] youtube:v3
* [api-breaking] adexperiencereport:v1
* [api-breaking] admin:directory_v1
* [api-breaking] bigquerydatatransfer:v1
* [api-breaking] cloudtrace:v2
* [api-breaking] gmail:v1
* [api-breaking] servicecontrol:v1
* [api-breaking] serviceuser:v1
* [api-breaking] sourcerepo:v1
* [api-breaking] spanner:v1
* [api-breaking] storage:v1
* [api-breaking] youtube:v3

## 0.44.0
* [api-new] firebaseremoteconfig:v1
* [api] androiddeviceprovisioning:v1
* [api] androidenterprise:v1
* [api] androidmanagement:v1
* [api] appengine:v1
* [api] bigquerydatatransfer:v1
* [api] bigquery:v2
* [api] cloudkms:v1
* [api] cloudtrace:v2
* [api] container:v1
* [api] content:v2
* [api] dfareporting:v2_8
* [api] drive:v2
* [api] drive:v3
* [api] firebasedynamiclinks:v1
* [api] gmail:v1
* [api] identitytoolkit:v3
* [api] logging:v2
* [api] monitoring:v3
* [api] people:v1
* [api] servicecontrol:v1
* [api] storage:v1
* [api-breaking] bigquerydatatransfer:v1
* [api-breaking] bigquerydatatransfer:v1
* [api-breaking] cloudkms:v1
* [api-breaking] cloudtrace:v2
* [api-breaking] ml:v1
* [api-breaking] script:v1
* [api-breaking] servicemanagement:v1
* [api-breaking] spanner:v1

## 0.43.0
* [api] adexperiencereport:v1
* [api] analytics:v3
* [api] androidmanagement:v1
* [api] androidpublisher:v2
* [api] bigquerydatatransfer:v1
* [api] bigquery:v2
* [api] classroom:v1
* [api] cloudbilling:v1
* [api] cloudkms:v1
* [api] compute:v1
* [api] content:v2
* [api] datastore:v1
* [api] deploymentmanager:v2
* [api] firebasedynamiclinks:v1
* [api] logging:v2
* [api] manufacturers:v1
* [api] ml:v1
* [api] servicemanagement:v1
* [api] serviceuser:v1
* [api] spanner:v1
* [api-breaking] adexperiencereport:v1
* [api-breaking] androiddeviceprovisioning:v1
* [api-breaking] iam:v1
* [api-breaking] monitoring:v3
* [api-breaking] script:v1
* [api-breaking] servicemanagement:v1

## 0.42.0

* [api-new] androiddeviceprovisioning:v1
* [api-new] streetviewpublish:v1
* [api-new] playcustomapp:v1
* [api-new] vault:v1
* [api-new] androidmanagement:v1
* [api-removed] dataproc:v1beta2
* [api-removed] tracing:v2

## 0.41.0

* [api-new] dataproc:v1beta2
* [api-new] cloudtrace:v2
* [api-new] adexperiencereport:v1
* [api-new] cloudresourcemanager:v2beta1
* [api-removed] cloudtrace:v1
* [api-removed] tracing:v2

## 0.40.0

* [api] appengine:v1
* [api] bigquerydatatransfer:v1
* [api] classroom:v1
* [api] cloudkms:v1
* [api] compute:v1
* [api] content:v2
* [api] firebasedynamiclinks:v1
* [api] firebaserules:v1
* [api] ml:v1
* [api] partners:v2
* [api] servicemanagement:v1
* [api] serviceuser:v1
* [api] sheets:v4
* [api] slides:v1
* [api] sourcerepo:v1
* [api] storage:v1
* [api] translate:v2
* [api-breaking] bigquerydatatransfer:v1
* [api-breaking] customsearch:v1
* [api-breaking] customsearch:v1
* [api-breaking] dataproc:v1
* [api-removed] dfareporting:v2_6
* [api-removed] dfareporting:v2_7

## 0.39.0

* [api-new] dfareporting:v2_8
* [api-new] tagmanager:v2
* [api-new] speech:v1
* [api-new] bigquerydatatransfer:v1
* [api] classroom:v1
* [api] content:v2
* [api] cloudkms:v1
* [api] container:v1
* [api] sourcerepo:v1
* [api] serviceuser:v1
* [api] storage:v1
* [api] compute:v1
* [api] drive:v3
* [api] drive:v2
* [api] tracing:v2
* [api] adexchangebuyer:v1_4
* [api] servicemanagement:v1
* [api] cloudbuild:v1
* [api] iam:v1
* [api] sheets:v4
* [api] logging:v2
* [api] doubleclickbidmanager:v1
* [api] androidenterprise:v1
* [api] admin:directory_v1
* [api] script:v1
* [api] people:v1
* [api-breaking] container:v1
* [api-breaking] container:v1
* [api-breaking] monitoring:v3
* [api-breaking] tracing:v2
* [api-breaking] tracing:v2

## 0.38.0

* [api-new] tracing:v2
* [api] books:v1
* [api] compute:v1
* [api] container:v1
* [api] drive:v2
* [api] drive:v3
* [api] iam:v1
* [api] identitytoolkit:v3
* [api] logging:v2
* [api] servicemanagement:v1
* [api] serviceuser:v1
* [api] storage:v1
* [api-breaking] cloudfunctions:v1
* [api-breaking] cloudresourcemanager:v1
* [api-breaking] compute:v1
* [api-breaking] consumersurveys:v2
* [api-breaking] content:v2
* [api-breaking] servicemanagement:v1
* [api-breaking] storagetransfer:v1
* [api-breaking] surveys:v2
* [api-removed] tracingv1

## 0.37.0

* [api-new] cloudfunctions:v1
* [api-new] cloudkms:v1
* [api-new] ml:v1
* [api] admin:directory_v1
* [api] analytics:v3
* [api] appengine:v1
* [api] calendar:v3
* [api] cloudresourcemanager:v1
* [api] compute:v1
* [api] dataproc:v1
* [api] firebasedynamiclinks:v1
* [api] firebaserules:v1
* [api] identitytoolkit:v3
* [api] licensing:v1
* [api] manufacturers:v1
* [api] partners:v2
* [api] people:v1
* [api] reseller:v1
* [api] safebrowsing:v4
* [api] servicemanagement:v1
* [api] serviceuser:v1
* [api] sheets:v4
* [api] slides:v1
* [api] storage:v1
* [api] vision:v1
* [api-breaking] classroom:v1

## 0.36.0

* [api-new] sourcerepo:v1
* [api-new] tracing:v1
* [api-new] spanner:v1
* [api] adexchangebuyer
* [api] androidpublisher
* [api] bigquery
* [api] cloudresourcemanager
* [api] dataproc
* [api] drive
* [api] people
* [api] reseller
* [api] servicemanagement
* [api] serviceuser
* [api] slides
* [api] vision
* [api-breaking] serviceuser
* [api-breaking] people
* [api-removed] dfareporting

## 0.35.0

[api-new] serviceuser:v1
[api-new] searchconsole:v1
[api-breaking] androidenterprise
[api-breaking] container
[api-breaking] genomics
[api-breaking] people
[api-breaking] script
[api] cloudbuild: changes
[api] container
[api] content
[api] dataproc
[api] deploymentmanager
[api] drive
[api] gmail
[api] iam
[api] identitytoolkit
[api] people
[api] servicecontrol
[api] sheets
[api] slides
[api] youtube

## 0.34.0

* [api] adexchangebuyer:v1_4: schema changes
* [api] directory:v1: schema ehanges
* [api] directory:v1: schema changes
* [api] androidpublisher:v2: new resource, schema changes
* [api] bigquery:v2: schema changes
* [api] classroom:v1: new methods
* [api] cloudbuild:v1: schema changes
* [api] compute:v1: schema changes
* [api] servicemanagement:v1: schema changes
* [api] sheets:v1: schema changes
* [api-breaking] androidenterprise:v1: resource removal
* [api-breaking] kgsearch:v1: schema changes
* [api-breaking] playmoviespartner:v1: resource removal

## 0.33.0

* [api-new] language:v1
* [api-new] slides:v1
* [api-breaking] appengine:v1: resource removal
* [api-breaking] firebasedynamiclinks:v1: schema changes
* [api-breaking] youtube-analytics:v1: removal of resources
* [api-removal] dfareporting:v2_4
* [api] analyticsreporting:v4: schema changes
* [api] androidenterprise:v1: schema changes
* [api] books:v1: schema changes
* [api] cloudbuild:v1: schema/method changes
* [api] cloudresourcemanager:v1: schema/method changes
* [api] compute:v1: new resources
* [api] deploymentmanager:v2: schema changes
* [api] drive:v2: schema changes
* [api] drive:v3: schema changes
* [api] gmail:v1: schema changes
* [api] identitytoolkit:v3: schema changes
* [api] logging:v2: new resource
* [api] servicemanagement:v1: schema changes
* [api] sheets:v4: schema changes
* [api] storage:v1: schema changes
* [api] youtube:v3: schema changes

## 0.32.0

* [api-new] dfareporting:v2_7
* [api-new] firebasedynamicclicks:v1
* [api-new] logging:v2
* [api-new] manufactures:v1
* [api-new] runtimeconfig:v1
* [api-new] surveys:v2
* [api-breaking] bigquery:v2: method changes
* [api-breaking] civicinfo:v2: method changes
* [api-breaking] doubleclickmanager:v1: resource changes
* [api-breaking] identitytoolkit:v3: schema changes
* [api-breaking] storage:v1: schema/method changes
* [api-breaking] youtube:v3: schema/method changes
* [api-removal] dfareporting:v2_2
* [api-removal] dfareporting:v2_3
* [api-removal] freebase:v1
* [api] adexchangebuyer:v1_4: method/schema changes
* [api] admin:directory_v1: schema changes
* [api] analytics:v3: schema changes
* [api] androidenterprise:v1: method/schema changes
* [api] androidpublisher:v2: added resource
* [api] appengine:v1: schema changes
* [api] appsactivity:v1: schema changes
* [api] books:v1: schema changes
* [api] classroom:v1: method/schema changes
* [api] cloudbuild:v1: method/schema changes
* [api] cloudresourcemanager:v1: added resource
* [api] compute:v1: added resources, method changes
* [api] consumersurveys:v2: schema changes
* [api] content:v2sandbox: schema changes
* [api] content:v2: schema changes
* [api] dataproc:v1: schema changes
* [api] deploymentmanager:v2: schema changes
* [api] drive:v2: schema changes
* [api] drive:v3: schema changes
* [api] fitness:v1: schema changes
* [api] freebase:v1
* [api] genomics:v1: schema changes
* [api] iam:v1: added resource
* [api] pubsub:v1: added resource
* [api] servicecontrol:v1: schema changes
* [api] servicemanagement:v1: schema changes
* [api] sheets:v4: schema/method changes

## 0.31.0

* [api-new] datastore:v1
* [api] analytics:v3: schema changes
* [api] bigquery:v2: schema changes
* [api] civicinfo:v2: method changes
* [api] classroom:v1: schema changes
* [api] cloudbuild:v1: schema changes
* [api] computeengine:v1: schema changes
* [api] content:v2: schema changes
* [api] genomics:v1: method change
* [api] identitytoolkit:v3: schema changes
* [api] servicecontrol:v1: schema changes
* [api] storage:v1: schema changes
* [api-breaking] servicemanagement:v1: schema changes
* [api-breaking] clouddebugger:v2: removed scope

## 0.30.1

* [api-new] appengine:v1
* [api-new] dfareporting:v2.6
* [api-new] servicecontrol:v1
* [api-new] servicemanagement:v1
* [api] adexchangebuyer:v1.4: method and schema changes
* [api] admin:directory_v1: schema changes
* [api] androidenterprise:v1: new resources, schema changes
* [api] bigquery:v2: schema changes
* [api] cloudbuild:v1: schema changes
* [api] compute:v1: new methods, schema changes
* [api] fitness:v1: schema changes
* [api] identitytoolkit:v3: schema changes
* [api] script:v1: schema changes
* [api] sheets:v4: new method

## 0.30.0

* [api-new] cloudbuild:v1
* [api] androidenterprise:v1: new resource
* [api] bigquery:v2: method changes
* [api] books:v1: new resource
* [api] civicinfo:v2: schema changes
* [api] gmail:v1: new resource
* [api] qpxexpress:v1: schema changes
* [api-removal] appengine:v1

## 0.29.0

* [api] acceleratedmobilepageurl:v1: schema changes
* [api] adexchangebuyer:v1.4: schema changes
* [api] bigquery:v2: schema changes
* [api] books:v2: schema/method changes
* [api] cloudresourcemanager:v1: new resource
* [api] compute:v1: schema/method changes
* [api] content:v2: schema changes
* [api] deploymentmanager:v2: schema changes
* [api] fitness:v1: schema changes
* [api] genomics:v1: schema changes
* [api] gmail:v1: method changes
* [api] youtube:v3: schema changes
* [api-removal] coordinate:v1

## 0.28.0

* [api-new] acceleratedmobilepageurl:v1
* [api] bigquery:v2: schema changes
* [api] compute:v1: new resource
* [api] consumersurveys:v2: new resource
* [api] content:v2: schema changes
* [api] drive:v2 schema/method changes
* [api] drive:v3 schema/method changes
* [api] games:v1: schema/method changes
* [api] groupsettings:v1: schema changes
* [api] identitytoolkit:v3: schema changes
* [api] safebrowsing:v4: schema changes
* [api] youtube:v3: schema changes
* [api-removal] cloudbuild:v1
* [api-removal] cloudlatencytest:v1

## 0.27.0

* [api-new] analyticsreporting:v4
* [api-new] cloudbuild:v1
* [api-new] dfareporting:v2.5
* [api-new] firebaserules:v1
* [api-new] safebrowsing:v4
* [api-new] sheets:v4
* [api-new] vision:v1
* [api] androidenterprise:v1: schema changes
* [api] androidpublisher:v2: schema/resource changes
* [api] civicinfo:v2: scope changes
* [api] cloudtrace:v1: scope changes
* [api] consumersurveys:v2: schema changes
* [api] genomics:v1: schema changes
* [api] idenditytoolkit:v3: schema changes
* [api] playmoviespartner:v1: schemas/resource changes
* [api] youtube:v3: schema changes
* [api-breaking] adexchangebuyer:v1_4: schema/resource changes
* [api-breaking] admin:directory_v1: schema changes
* [api-breaking] bigquery:v2: schema changes
* [api-breaking] classroom:v1:  schema/resource changes
* [api-breaking] dataproc:v1: schema/scope/resource changes
* [api-removal] dfareporting:v1.3
* [api-removal] dfareporting:v2.0
* [api-removal] dfareporting:v2.1
* [api-removal] reseller:v1sandbox

## 0.26.0

* [api-new] consumersurveys:v2
* [api] adexchangebuyer:v1_4: schema changes
* [api] books:v2: schema/method changes
* [api] compute:v1: schema/meethod changes
* [api] container:v1: new resource, schema changes
* [api] deploymentmanager:v2: schema changes
* [api] drive:v2: schema changes
* [api] drive:v3: schema changes
* [api] gamesmanagement:v1management: schema changes
* [api] games:v1: schema changes
* [api] genomics:v1: new resources
* [api] youtube:v3: schema changes
* [api-breaking] idenditytoolkit:v3: schema changes
* [api-breaking] bigquery:v2: schema changes

## 0.25.0

* [api-new] monitoring:v3
* [api] adexchangebuyer:v1_3: schema changes
* [api] adexchangebuyer:v1_4: schema changes, new resources
* [api] androidenterprise:v1: schema changes
* [api] androidpublisher:v2: schema changes
* [api] bigquery:v2: schema changes
* [api] container:v1: schema changes
* [api] genomics:v1: schema changes
* [api] groupssettings:v1: schema changes
* [api] idenditytoolkit:v3: schema changes
* [api] reseller:v1: schema changes
* [api] reseller:v1sandbox: schema changes
* [api] webmasters:v3: schema changes
* [api] youtubereporting:v1: method changes, schema changes
* [api-breaking] compute:v1: schema removal/changes, new resource
* [api-removal] admin:email_migration_v2

## 0.24.0

* [api-new] cloudresourcemanager:v1
* [api-new] dfareporting:v2.4
* [api-new] iam:v1
* [api-new] people:v1
* [api] adexchangebuyer:v1_3: schema changes
* [api] adexchangebuyer:v1_4: schema changes
* [api] analytics:v3: schema changes
* [api] appsactivity:v1: schema changes
* [api] bigquery:v2: schema changes
* [api] clouddebugger:v2: method changes
* [api] content:v2sandbox: schema changes
* [api] content:v2: schema changes
* [api] dataproc:v1: new resource
* [api] deploymentmanager: schema changes
* [api] drive:v2: schema changes
* [api] drive:v3: schema changes
* [api] games:v1: schema changes
* [api] genomics:v1: new schemas
* [api] gmail:v1: method changes
* [api] idenditytoolkit:v3: method/schema changes
* [api] reseller:v1sandbox: schema changes
* [api] reseller:v1: schema changes
* [api-breaking] adsense:v1_4: schema changes
* [api-breaking] books:v1: method changes
* [api-breaking] tagmanager:v1: method changes, new resources
* [api-breaking] youtube:v3: schema removal
* [api-removal] mapsengine:v1

## 0.23.0

* [api] androidenterprise:v1: schema changes
* [api] androidpublisher:v2: schema changes
* [api] books:v1: method/schema changes
* [api] compute:v1: new resource
* [api] doubleclickbidmanager:v1: new resource
* [api] gamesmanagement:v1management: schema changes
* [api] games:v1: schema changes
* [api] idenditytoolkit:v1: new methods, schema changes
* [api-breaking] adexchangebuyer:v1_4: resource removal/addition
* [api-breaking] youtube:v3: schema removal
* [api-removal] admin:email_migration_v2

## 0.22.0

* [api] youtube:v3: schema changes
* [api-breaking] bigquery:v2: resource removal

## 0.21.0

* [api-new] dataproc:v1
* [api-new] drive:v3
* [api-new] kgsearch:v1
* [api] adexchangebuyer:v1_4: schema changes
* [api] admin:directory_v1: new resources
* [api] analytics:v3: new method/resource
* [api] androidenterprise:v1: new resources
* [api] books:v1: method changes
* [api] clouddebugger:v2: method/schema changes
* [api] content:v2: resource changes
* [api] content:v2sandbox: resource changes
* [api] deploymentmanager:v2: resource changes
* [api] games:v1: new method/resource
* [api] storage:v1: schema changes
* [api] youtubeanalytics:v1: method changes
* [api] youtube:v3: new resources
* [api-breaking] cloudtrace:v1: resource removal
* [api-breaking] genomics:v1: method removal
* [api-breaking] plus:v1: resource removal

## 0.20.0

* [api-breaking] content:v2: renaming schema, api and schema changes
* [api-breaking] dfareporting:2.3: removal of schema and schema properties
* [api-breaking] identitytoolkit:v3: removal of api method and schemas
* [api-breaking] youtube:v3: removal of api method
* [api] analytics:v3: api changes
* [api] bigquery:v2: schema changes
* [api] compute:v1: schema changes
* [api] discovery:v1: schema changes
* [api] tagmanager:v1: api changes

## 0.19.0

* [api] adexchangebuyer:v1_3: api changes
* [api] bigquery:v2: schema changes
* [api] books:v1: schema changes
* [api] idenditytoolkit:v3: schema changes
* [api] pubsub:v1 schema changes
* [api] youtubereporting:v1: method changes
* [api-new] dfareporting:v2.3
* [api-breaking] adexchangebuyer:v1_4: removal of resource apis

## 0.18.0

* [apis-breaking] books:v1: new resources and schemas and schema changes
* [apis] compute:v1: added method/schemas
* [apis] identitytoolkit:v3: added method/schemas
* [apis] reseller:v1: schema changes
* [apis] reseller:v1sandbox: schema changes

## 0.17.0

* [apis-breaking] tagmanager:v1: removed resources and schemas
* [apis-new] cloudtrace:v1
* [apis] admin_directory:v1: new resources and schemas
* [apis] adsense:v1.4: schema changes
* [apis] books:v1: new resources and schemas
* [apis] compute:v1: new resources and schemas
* [apis] doubleclickbidmanager:v1: schema changes
* [apis] doubleclicksearch:v2: schema changes
* [apis] identitytoolkit:v3: schema changes
* [apis] plusDomains:v1: schema changes
* [apis] plus:v1: schema changes

## 0.16.1

* [apis-new] admin:datatransfer_v1
* [apis-new] youtubereporting:v1
* [apis-new] script:v1
* [apis] content:v2: new resource
* [apis] content:v2sandbox: new schemas
* [apis] storage:v1: schema changes

## 0.16.0

* [apis-breaking] adexchangebuyer:v1.4: method/schema changes
* [apis-new] content:v2sandbox
* [apis-new] reseller:v1sandbox
* [apis] adexchangebuyer:v1.3: schema changes
* [apis] bigquery:v2: schema changes
* [apis] identitytoolkit:v3: schema changes
* [apis] youtube:v3: schema changes

## 0.15.0

* [apis-breaking] compute:v1: schema changes
* [apis-breaking] genomics:v1: schema changes
* [apis-breaking] pubsub:v1: method/schema changes
* [apis-breaking] youtube:v3: method changes
* [apis] adexchangebuyer:v1.3: schema changes
* [apis] adexchangebuyer:v1.4: added method/schema
* [apis] admin_reports:v1: schema changes
* [apis] androidenterprise:v1: added method/schema
* [apis] civicinfo:v2: schema changes
* [apis] content:v2: schema changes
* [apis] deploymentmanager:v2: schema changes
* [apis] drive:v2: schema changes
* [apis] identitytoolkit:v3: schema changes
* [apis] partners:v2: schema/method changes
* [apis] tagmanager:v1: schema changes

## 0.14.0

* [apis-new] cloudbilling:v1
* [apis] bigquery:v2: schema changes
* [apis] clouddebugger:v2: schema changes
* [apis] container:v1: added method/schema
* [apis] content:v2: schema changes
* [apis] drive:v2: added method/schema
* [apis] genomics:v1: added methods/schemas
* [apis] playmoviespartner:v1: added schemas/resources
* [apis] plusDomains:v1: schema changes
* [apis-breaking] compute:v1: schema-changes
* [apis-breaking] plus:v1: method changes
* [apis-breaking] youtube:v3: schema changes

## 0.13.0

* [apis-breaking] fitness:v1: schema changes
* [apis-breaking] compute:v1: resource/schema changes
* [apis-new] adexchangebuyer:v1.4
* [apis-new] classroom:v1
* [apis-new] clouddebugger:v2
* [apis-new] cloudlatencytest:v2
* [apis-new] deploymentmanager:v2
* [apis-new] dfareporting:v2.1
* [apis-new] dfareporting:v2.2
* [apis-new] dns:v1
* [apis-new] genomics:v1
* [apis-new] partners:v2
* [apis-new] playmoviespartner:v1
* [apis-new] pubsub:v1
* [apis-new] storagetransfer:v1
* [apis] directory:v1: schema changes
* [apis] androidenterprise:v1: schema/method changes
* [apis] bigquery:v2: schema changes
* [apis] calendar:v3: schema changes
* [apis] civicinfo:v2: schema changes
* [apis] content:v2: method/schema changes
* [apis] discovery:v1: schema changes
* [apis] drive:v2: schema changes
* [apis] tagmanager:v1: schema changes
* [apis] youtube:v3: method/schema changes

## 0.12.1

* [apis] bigquery:v2: schema changes
* [apis] calendar:v3: schema/method changes
* [apis] webmasters:v3: schema changes
* [apis] compute:v1: resource/schema changes

## 0.12.0

* [apis-breaking] doubleclicksearch:v2: schema changes
* [apis-breaking] youtube:v3: method/schema changes
* [apis] admin_directory:v1: schema changes
* [apis] compute:v1: schema changes
* [apis] drive:v2: schema changes
* [apis] gmail:v1: schema changes

## 0.11.0

* [apis-breaking] bigquery:v2: schema/method changes, removed schema field
* [apis-breaking] youtube:v3: renamed enum values, schema changes
* [apis] adexchangebuyer:v1.3: schema changes
* [apis] androidenterprise:v1: schema/method changes
* [apis] compute:v1: schema changes
* [apis] drive:v2 method changes
* [apis] fitness:v1: schema/method changes
* [apis] gmail:v1: schema/method changes
* [apis] reseller:v1: schema changes
* [apis] tagmanager:v1: schema changes

## 0.10.0

* [apis-breaking] youtube:v3: schema changes

## 0.9.0

* [apis] analytics:v3: schema changes
* [apis] androidenterprise:v1: schema changes
* [apis] androidpublisher:v2: new resource
* [apis] bigquery:v2: schema changes
* [apis] blogger:v3: schema changes
* [apis] books:v1: method/schema changes
* [apis] compute:v1: schema changes
* [apis] content:v2: method/schema changes
* [apis] doubleclicksearch:v2: schema changes
* [apis] identitytoolkit:v3: schema/method changes
* [apis] storage:v1: schema/method changes
* [apis] youtube:v3: new resource, schema changes
* [api-breaking] fitness:v1: schema changes
* [apis-removed] cloudsearch:v1

## 0.8.0
* [api] admin_directory:v1: schema changes
* [api] compute:v1: method changes
* [api] content:v2: schema changes
* [api] directory:v1: schema changes
* [api] fitness:v1: schema/method changes
* [api] youtube:v3: new resources
* [api-breaking] storage:v1: method changes

## 0.7.0

* [apis-breaking] analytics:v3 removed dailyUploads API
* [apis-breaking] books:v1: removed method
* [apis-breaking] compute:v1: removed some Quota enum values, new methods and
  schemas
* [apis-new] androidenterprise:v1
* [apis-new] cloudsearch:v1
* [apis-removed] civicinfo:us_v1
* [apis-removed] civicinfo:v1
* [apis] admindirectory:v1: schema changes
* [apis] bigquery:v2: schema changes
* [apis] content:v2: method and schema changes
* [apis] discovery:v1: schema changes
* [apis] doubleclickbidmanager:v1 schema changes
* [apis] dfareporting:v2.0 schema changes
* [apis] drive:v2 method changes
* [apis] oauth2:v2 method and schema changes
* [apis] storage:v1 method changes
* [apis] youtubeanalytics:v1 method changes
* [apis] youtube:v2: method and schema changes


## 0.6.1

* [apis] bigquery:v2: schema changes
* [apis] books:v1: method changes
* [apis] content:v2: schema changes
* [apis] fitness:v1: schema changes
* [apis] gmail:v1: additional schemas
* [apis] youtube:v3: method changes
* [apis] youtubeanalytics:v1: new resources

## 0.6.0

* [apis] androidpublisher:v2: additional schemas/methods
* [apis] bigquery:v2: schema changes
* [apis] blogger:v3: schemas/methods changes
* [apis] books:v1: schemas/methods changes
* [apis] compute:v1: scope changes
* [apis] gmail:v1: method changes
* [apis-breaking] youtube:v3: schemas/methods changes

## 0.5.5

* [apis-new] gamesConfiguration:v1configuration: API added
* [apis-new] pagespeedonline:v2: API added
* [apis] analytics:v3: new resource added
* [apis] blogger:v3: method changes
* [apis] books:v1: schema changes
* [apis] content:v2: new resources added, schema changes
* [apis] doubleclickbidmanager:v1: schema changes
* [apis] oauth2:v2: new method/schema
* [apis] storage:v1: method changes
* [apis] youtube:v3: schema changes

## 0.5.4

* [apis] drive:v2: schema changes

## 0.5.3

* [generator] Roll to use DetailedApiRequestError when only a HTTP status code
  is present.

## 0.5.2

* [apis-new] dfareporting:v2.0: API added
* [apis] books:v1: method changes
* [apis] coordinate:v1: method/schema changes

## 0.5.1

* [apis-new] fusiontables:v2: API added
* [apis] adexchangebuyer:v1.3: method/schema changes
* [apis] admin_directory:v1: schema changes
* [apis] books:v1: method/schema changes
* [apis] compute:v1: method changes
* [apis] storage:v1: method changes
* [apis] youtube:v3: schema changes
* [generator] Roll to include optional rootUrl/servicePath arguments.

## 0.5.0

* [apis] bigquery:v2: schema changes
* [apis] books:v1: additional resource/schema changes
* [apis] doubleclicksearch:v2: schema changes
* [apis] fitness:v1: method changes
* [apis] reseller:v1: schema changes
* [apis] youtube:v3: schema changes
* [apis-breaking] calendar:v3: Removed title from EventAttachment
* [apis-breaking] tagmanager:v1: Removed dependencies from Tag and schema changes
* [apis-breaking] youtubeanalytics:v1: schema changes


## 0.4.1

* [apis] bigquery:v2: schema changes
* [apis] fitness:v1: schema changes
* [apis] youtube:v3: schema changes

## 0.4.0

* [apis-new] fitness:v1: API added
* [apis-new] tagmanager:v1: API added
* [apis] adexchangebuyer:v1.3: schema changes
* [apis] calendar:v3: schema changes
* [apis] civicinfo:us_v1: schema changes
* [apis] civicinfo:v1: schema changes
* [apis] civicinfo:v2: schema changes
* [apis] compute:v1: schema changes
* [apis] content:v2: schema/method changes
* [apis] drive:v2: schema/method changes
* [apis] games:v1: schema changes
* [apis] gamesManagement:v1management: schema/method changes
* [apis] gmail:v1: method changes
* [apis] mapsengine:v1: schema changes
* [apis-breaking] prediction:v1.6: String -> double change

## 0.3.1

* [apis] admin_directory:v1: additional schema/methods
* [apis] analytics:v3: additional schemas/methods
* [apis] gmail:v1: additional schemas/methods
* [apis] reseller:v1: additional schemas/methods

## 0.3.0

* [apis-removed] orkut:v2: removed (Orkut is shut down)
* [apis] compute:v1: additional schemas/methods
* [apis] doubleclicksearch:v2: schema changes
* [apis] games:v1: schema changes
* [apis] gamesManagement:v1management: schema changes
* [apis] gmail:v1: schema changes

## 0.2.1

* [apis-new] adexchangeseller:v2.0: API added
* [apis-new] civicinfo:v2: API added
* [apis-new] webmasters:v3: API added
* [apis] civicinfo:v1: schema changes
* [apis] youtube:v3: schema changes

## 0.2.0

* [apis] admin:directory: additional schemas/methods
* [apis] admin:reports_v1: schema changes
* [apis] androidpublisher:v2: additional schemas/methods
* [apis] drive:v2: schema changes
* [apis] identitytoolkit:v3: schema changes
* [apis] mirror:v1: schema changes
* [apis-breaking] mapsengine:v1: major changes (additional schemas/methods)
* [apis-breaking] prediction:v1.6: double -> String change
* [generator] Bugfix in resumable media uploader.
* [generator] Bugfix json decoding optimization.

## 0.1.1

* [apis] Added Discovery API
* [generator] Make shorter descriptions in pubspec.yaml: Only list api:version tuples.
* [generator] Rename test files to _test.dart so they get automatically run.

## 0.1.0

* First release
