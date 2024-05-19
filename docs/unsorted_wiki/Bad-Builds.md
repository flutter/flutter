## Flutter Bad Builds Triage Guidelines (for Googlers)

1. If you encounter a serious P0 flutter production Google3 or a github issue, triage the issue and check if the issue is already part of Flutter's bad build [tracker](http://go/flutter-bad-builds).
If the issue is not listed in Flutter bad builds [tracker](http://go/flutter-bad-builds), check that it meets the below criteria to qualify for bad builds visibility -
   * A P0 bug
   * Can be in any component, Flutter’s component or Flutter user’s component
   * Must be a bug, not a feature request
   * Must affect end-users, not a regression on tooling, debugging features, infra etc
   * Issue must be open

2. If there is a buganizer for this already and no github issue, create a github bug in the github repo. Label the github bug with label _a: production_ and _customer: google_.

3. Add following information to Flutter bad builds visibility [tracker](http://go/flutter-bad-builds)
   * Issue create date - this can be either buganizer or github issue create date
   * Triaged by - your LDAP
   * Github issue id
   * Begin bad build commit hash URL (Commit hash URL can be from dart, engine, flutter and skia repos)
   * Impacted platform

3. Automation will take care of finding the corresponding begin bad build commit CL based on the begin bad build commit URL you entered. Automation will run once every 12 hrs

4. Contact the [Flutter@Google team on-call ](https://rotations.corp.google.com/rotation/5644450090975232) for more visibility into the issue. This will also help identify duplicates across github & Google3.

5. Once a fix has been merged, enter the “End bad build commit hash 1 URL”.

6. There are cases when a fix is merged as part of 2 different commits. In that case, you can use the “ End bad build commit hash 2 URL” column to populate the second commits hash information. Automation will take care of finding the corresponding End bad build commit CL based on the End bad build commit URL you entered.