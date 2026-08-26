# Unified Check Run User Manual

## Changes to GitHub Workflow
When the Unified Check Run functionality is enabled for your GitHub account, creating a pull request (PR) with the 'CICD' label will consolidate multiple check-runs into a single **Flutter Presubmits** check-run.
<img width="349" height="168" alt="Flutter Presubmits Check-run" src="https://github.com/user-attachments/assets/93a765b2-94a0-46d1-a865-db11a346a507" />

To view detailed information, click the **View more details on flutter-dashboard** link located at the bottom of the check-run summary.
<img width="277" height="235" alt="Link to Presubmit Dashboard" src="https://github.com/user-attachments/assets/4b1de26a-6dac-4446-a655-2c8a3569d492" />

If a test fails, you can re-run the failed tests directly from the check-run interface by clicking the **Re-run Failed** button. Alternatively, you can use the presubmit dashboard, accessible via the **Failed Checks Details** link at the top of the check-run description or the **View more details on flutter-dashboard** link at the bottom.
<img width="657" height="585" alt="Failed Flutter Presubmits Check-run" src="https://github.com/user-attachments/assets/08489428-ce16-4061-9d88-478d01531c86" />

## Presubmit Dashboard
Clicking the **View more details on flutter-dashboard** link within the **Flutter Presubmits** check-run opens the presubmit dashboard. This interface provides detailed test run execution information, allows you to re-run failed tests from the latest check-run, and provides links to the LUCI UI for deeper investigation into test execution.
<img width="820" height="471" alt="Presubmit Dashboard" src="https://github.com/user-attachments/assets/3bca7bfe-da48-490b-97dd-dd4cde42356f" />
