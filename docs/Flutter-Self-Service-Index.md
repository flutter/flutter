## Flutter Self Service Index

Flutter provides multiple functionality through self-service services. Most of these services are available to any member of the Flutter GitHub organization.


### Audiences


<table>
  <tr>
   <td><strong>Name</strong>
   </td>
   <td><strong>Description</strong>
   </td>
  </tr>
  <tr>
   <td>Flutter contributors
   </td>
   <td>Anyone contributing to the flutter organization independently of membership to the organization.
   </td>
  </tr>
  <tr>
   <td>Flutter organization members
   </td>
   <td>[Anyone with write access to the flutter organization resources.](./contributing/Contributor-access.md)
   </td>
  </tr>
  <tr>
   <td>Googlers
   </td>
   <td>Members of the Flutter Organization that are also Googlers.
   </td>
  </tr>
  <tr>
   <td>Flutter organization administrators
   </td>
   <td>Members of the Flutter organization that have write access to the organization's settings.
   </td>
  </tr>
</table>



### Infrastructure


<table>
  <tr>
   <td><strong>Service</strong>
   </td>
   <td><strong>Description</strong>
   </td>
   <td><strong>Audience</strong>
   </td>
   <td><strong>Documentation</strong>
   </td>
   <td><strong>Location</strong>
   </td>
  </tr>
  <tr>
   <td>.ci.yaml
   </td>
   <td>Configuration file to instruct the Flutter Infrastructure which tasks to use to validate commits in a given repository. ".ci.yaml" is read from the top level folder of every supported repository.
   </td>
   <td>Flutter contributors
   </td>
   <td><a href="https://github.com/flutter/cocoon/blob/main/CI_YAML.md">Link</a>
   </td>
   <td>Top level folder of the GitHub repositories. E.g. <a href="https://github.com/flutter/flutter/blob/main/.ci.yaml">flutter/flutter</a>.
   </td>
  </tr>
  <tr>
   <td>Engine build configurations
   </td>
   <td>Configuration files to describe Flutter Engine builds and tests.
   </td>
   <td>Flutter contributors
   </td>
   <td><a href="https://github.com/flutter/engine/blob/main/ci/builders/README.md">Link</a>
   </td>
   <td><a href="https://github.com/flutter/engine/tree/main/ci/builders">engine/ci/builders</a> in the <a href="https://github.com/flutter/engine/tree/main">flutter/engine</a> repository contains all the current configuration files.
   </td>
  </tr>
  <tr>
   <td>Autosubmit
   </td>
   <td>GitHub application that auto-submits pull requests that meet the approval criteria.
   </td>
   <td>Flutter organization administrators
   </td>
   <td><a href="go/enabling_autosubmit">Link</a>
   </td>
   <td>The application code is available in the <a href="https://github.com/flutter/cocoon/tree/main/auto_submit">flutter/cocoon</a> repository.
   </td>
  </tr>
  <tr>
   <td>FirebaseLab tests
   </td>
   <td>Special type of tests configured through .ci.yaml that use resources from FirebaseLab
   </td>
   <td>Flutter contributors
   </td>
   <td>[Link](./infra/Flutter-FirebaseLab-Tests.md)
   </td>
   <td>These configurations go directly in the .ci.yaml file of <a href="https://github.com/flutter/flutter">flutter/flutter</a> repository.
   </td>
  </tr>
  <tr>
   <td>Codesigning
   </td>
   <td>Add metadata to engine artifacts for code signing infrastructure to sign them.
   </td>
   <td>Flutter contributors
   </td>
   <td>[Link](./engine/release/Code-signing-metadata.md)
   </td>
   <td>GN files and global generator scripts in the <a href="https://github.com/flutter/engine">flutter/engine</a> repository.
   </td>
  </tr>
  <tr>
   <td>Emulators support
   </td>
   <td>Using android emulators from tests.
   </td>
   <td>Flutter contributors
   </td>
   <td>[Link](./platforms/android/Testing-Android-Changes-in-the-Devicelab-on-an-Emulator.md)
   </td>
   <td>Flutter GitHub Wiki page under the “Android Development” Section.
   </td>
  </tr>
  <tr>
   <td>Rerun GitHub presubmit test using command line
   </td>
   <td>Run presubmit tasks using `reset-try-task` end point and gcloud CLI.
   </td>
   <td> Googlers
   </td>
   <td><a href="https://g3doc.corp.google.com/company/teams/flutter/infrastructure/playbook.md?cl=head#manually-trigger-try-pre-submit-builds">Link</a>
   </td>
   <td>Source code is available <a href="https://github.com/flutter/cocoon/blob/main/app_dart/lib/src/request_handlers/reset_try_task.dart">here</a>
   </td>
  </tr>
  <tr>
   <td>Rerun postsubmit test from Flutter build dashboard
   </td>
   <td>Re-run postsubmit tasks from the go/flutter-dashboard.
   </td>
   <td> Googlers
   </td>
   <td><a href="https://screenshot.googleplex.com/3CgvqjbPEuoLzXs">Link</a>
   </td>
   <td>Source code is available <a href="https://g3doc.corp.google.com/company/teams/flutter/go/flutter-dashboard">go/flutter-dashboard</a>
   </td>
  </tr>
  <tr>
   <td>Run a test multiple times in parallel via LED
   </td>
   <td>Run a shard test against a pull request to validate changes/fixes in parallel.
   </td>
   <td> Googlers
   </td>
   <td><a href="https://g3doc.corp.google.com/company/teams/flutter/infrastructure/playbook.md?cl=head#run-a-shard-multiple-times-in-parallel-via-led">Link</a>
   </td>
   <td>N/A
   </td>
  </tr>
  <tr>
   <td>Create a CIPD package
   </td>
   <td>Create and add the package build scripts to cocoon to enable auto building and uploading to flutter CIPD namespaces.
   </td>
   <td> Flutter contributors
   </td>
   <td><a href="https://github.com/flutter/cocoon/tree/main/cipd_packages">Link</a>
   </td>
   <td>Flutter public CIPD namespace: <a href="https://chrome-infra-packages.appspot.com/p/flutter">flutter</a>
   </td>
  </tr>
  <tr>
   <td>View Infra SLO metrics
   </td>
   <td>DataSite with links to a collection of Engineering Productivity dashboards including infrastructure, release and rolls.
   </td>
   <td> Googlers
   </td>
   <td><a href="https://data.corp.google.com/sites/dash_infra_metrics_datasite/infra_slo_metrics/">Link</a>
   </td>
   <td>N/A
   </td>
  </tr>
</table>



### Release


<table>
  <tr>
   <td><strong>Service</strong>
   </td>
   <td><strong>Description</strong>
   </td>
   <td><strong>Audience</strong>
   </td>
   <td><strong>Documentation</strong>
   </td>
   <td><strong>Location</strong>
   </td>
  </tr>
  <tr>
   <td>Create non flutter release candidate branches
   </td>
   <td>Self service to create release candidate branches used by products different than flutter
   </td>
   <td> Googlers
   </td>
   <td><a href="https://g3doc.corp.google.com/company/teams/flutter/go/flutter-self-service-branches">Link</a>
   </td>
   <td>N/A
   </td>
  </tr>
  <tr>
   <td>Request 1P cherry picks
   </td>
   <td>Request approvals for cherry picks to release candidate branches
   </td>
   <td> Googlers
   </td>
   <td><a href="https://g3doc.corp.google.com/company/teams/flutter/go/flutter-cp">Link</a>
   </td>
   <td><a href="https://g3doc.corp.google.com/company/teams/flutter/github.com/flutter/flutter">flutter/flutter</a>
   </td>
  </tr>
  <tr>
   <td>G3 Fixes
   </td>
   <td>Apply G3 fixes that are automatically applied during the roll process.
   </td>
   <td> Googlers
   </td>
   <td><a href="https://g3doc.corp.google.com/company/teams/flutter/go/flutter-life-of-a-pr#g3fix">Link</a>
   </td>
   <td>N/A
   </td>
  </tr>
  <tr>
   <td>Single command releases
   </td>
   <td>Creating a third party flutter release with multi party approvals.
   </td>
   <td> Release Engineering
   </td>
   <td><a href="https://g3doc.corp.google.com/company/teams/flutter/go/flutter-release-workflow#push">Link</a>
   </td>
   <td>N/A
   </td>
  </tr>
</table>


### Security


<table>
  <tr>
   <td><strong>Service</strong>
   </td>
   <td><strong>Description</strong>
   </td>
   <td><strong>Audience</strong>
   </td>
   <td><strong>Documentation</strong>
   </td>
   <td><strong>Location</strong>
   </td>
  </tr>
  <tr>
   <td>Vulnerability scanning and fixes validation
   </td>
   <td>Automatic scanning of c, c++ third party dependencies and vulnerability. fix validation.
   </td>
   <td>Flutter organization members
   </td>
   <td><a href="https://github.com/flutter/engine/security/code-scanning">Link</a>
   </td>
   <td><a href="https://github.com/flutter/engine/security">Engine GitHub security tab</a>.
   </td>
  </tr>
  <tr>
   <td>Request write access to non-prod GCP projects
   </td>
   <td>
   </td>
   <td> Googlers
   </td>
   <td><a href="https://g3doc.corp.google.com/company/teams/flutter/security/gcp_security/aod_roles_for_dash_projects.md?cl=head#available-groups">Link</a>
   </td>
   <td>N/A
   </td>
  </tr>
  <tr>
   <td>Rolling non-auto-updating 3p mirrored deps
   </td>
   <td>Dependencies on mirrors that do not automatically roll changes from their upstream might need to be manually rolled
   </td>
   <td> Googlers
   </td>
   <td><a href="https://g3doc.corp.google.com/company/teams/flutter/security/third_party_deps/index.md?cl=head#rolling-mirrored-dependencies">Link</a>
   </td>
   <td>N/A
   </td>
  </tr>
</table>


Googlers can access the internal version using [go/flutter-self-service](http://go/flutter-self-service)