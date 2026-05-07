# Unified Check Run User Manual

## Changes to GitHub Workflow
When the Unified Check Run functionality is enabled for your GitHub account, creating a pull request (PR) with the 'CICD' label will consolidate multiple check-runs into a single Flutter Presubmits check-run.

To view detailed information, click the View more details on the flutter-dashboard link located at the bottom of the check-run summary.

If a test fails, you can re-run the failed tests directly from the check-run interface by clicking the Re-run Failed button. Alternatively, you can use the presubmit dashboard, accessible via the Failed Checks Details link at the top of the check-run description or the View more details on flutter-dashboard link at the bottom.

## Presubmit Dashboard
Clicking the View more details on flutter-dashboard link within the Flutter Presubmits check-run opens the presubmit dashboard. This interface provides detailed test run execution information, allows you to re-run failed tests from the latest check-run, and provides links to the LUCI UI for deeper investigation into test execution.


