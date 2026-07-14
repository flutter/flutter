# **Unified Check Run User Manual**

# **Changes to GitHub Workflow**

When the Unified Check Run functionality is enabled for your GitHub account, creating a pull request (PR) with the 'CICD' label will consolidate multiple check-runs into a single **Dashboard Checks** check-run.

<img width="370" height="69" alt="Image" src="https://github.com/user-attachments/assets/3fe35d6d-5c9c-44b9-abef-d378ba89fd00" />

To view detailed information, click the **View more details on the flutter-dashboard** link located at the bottom of the check-run summary.

<img width="285" height="296" alt="Image" src="https://github.com/user-attachments/assets/6fb2ee61-69af-4efe-9017-09d1d6b1adfb" />

If a test fails, you can re-run the failed tests directly from the check-run interface by clicking the **Re-run Failed** button. Alternatively, you can use the presubmit dashboard, accessible via the **Failed Checks Details** link at the top of the check-run description or the **View more details on flutter-dashboard** link at the bottom.

<img width="781" height="658" alt="Image" src="https://github.com/user-attachments/assets/46cac8e2-ffbd-4fdd-bd11-e9624c7269d9" />

# **Presubmit Dashboard**

Clicking the **View more details on flutter-dashboard** link within the **Flutter Presubmits** check-run opens the presubmit dashboard. This interface provides detailed test run execution information.

# **Check run selection**

By clicking on the SHA selector, you can navigate through the check runs for the current pull request.

<img width="1768" height="658" alt="Image" src="https://github.com/user-attachments/assets/a740685d-f113-4664-95d3-b7aa877a18a6" />

# **Re-running failed jobs**

If the latest check-run is selected, the dashboard allows you to re-run specific failed tests or all failed tests.

<img width="886" height="491" alt="Image" src="https://github.com/user-attachments/assets/ced24eff-6014-41db-bbbc-f948c45afe35" />

**Filtering jobs**
By clicking on the **Filter jobs** button, you can filter jobs by status, platform, or regex.

<img width="886" height="491" alt="Image" src="https://github.com/user-attachments/assets/ca5ef372-5c84-4287-ba6b-cefb54dec89c" />

<img width="1772" height="1210" alt="Image" src="https://github.com/user-attachments/assets/b9b1bde3-4783-413b-b61e-7664d605e6d5" />

**Troubleshooting**
The presubmit dashboard for every failed job provides links to the LUCI UI for deeper investigation of the LUCI build execution associated with this job.

<img width="886" height="491" alt="Image" src="https://github.com/user-attachments/assets/677f1729-f2d3-4e2e-aa49-dbfb53e8d5d4" />

# **Analyze logs with Gemini**

If you have write permission to the Flutter repository and the selected check run is the latest one, you can not only view logs of failed jobs but also analyze them with Gemini.

<img width="886" height="491" alt="Image" src="https://github.com/user-attachments/assets/1b1e1da8-e657-42ea-909f-aa203fc4450a" />

This will provide not only a summary of the failure but also suggested fixes.

<img width="872" height="388" alt="Image" src="https://github.com/user-attachments/assets/d444e2b3-bb2e-4f09-9a47-f5bb66d8c1e5" />
