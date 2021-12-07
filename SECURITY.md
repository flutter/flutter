# Security Policy

## Supported Versions

We commit to publishing security updates for the version of Flutter currently
on the `stable` branch.

## Reporting a Vulnerability

To report a vulnerability, please e-mail `security@flutter.dev` with a description of the issue,
the steps you took to create the issue, affected versions, and if known, mitigations for the issue.

We should reply within three working days, probably much sooner.

We use GitHub's security advisory feature to track open security issues. You should expect
a close collaboration as we work to resolve the issue you have reported. Please reach out to
`security@flutter.dev` again if you do not receive prompt attention and regular updates.

You may also reach out to the team via our public [Discord](https://github.com/flutter/flutter/wiki/Chat) chat channels; however, please make
sure to e-mail `security@flutter.dev` when reporting an issue, and avoid revealing information about
vulnerabilities in public if that could put users at risk.

## Process

This section describes the process used by the Flutter team when handling vulnerability reports.

Vulnerability reports are received via the `security@flutter.dev` e-mail alias. Certain team members
who have been designated the "vulnerability management team" receive these e-mails. When receiving
such an e-mail, they will:

0. Reply to the e-mail acknowledging its receipt, cc'ing `security@flutter.dev` so that the other
   members of the team are aware that they are handling the issue.
1. Create a new [security advisory](https://github.com/flutter/flutter/security/advisories/new).
   One must be one of the repo admins to do this. Vulnerability management team members who are not
   also a repo admin will reach out to the repo admins until they find one who can create the advisory.
   The repo admins who are also vulnerability management team members are @Hixie, @tvolkert, and @pcsosinski.
2. [Add the reporter](https://docs.github.com/en/free-pro-team@latest/github/managing-security-vulnerabilities/adding-a-collaborator-to-a-security-advisory)
   to the security advisory so that they can get updates.
3. Reopen https://github.com/flutter/flutter/issues/72555 to ensure that security vulnerabilities
   will be checked during critical triage.
4. Inform the relevant team lead, adding them to the security advisory.
5. If the security issue does not yet have a CVE number, they will, as a Googler, see go/cve-request to
   establish one.

As the fix is being developed, they will then reach out to the reporter to ask them if they would like to be involved
and whether they would like to be credited. For credit, the GitHub security advisory UI has a field
that allows contributors to be credited.

When the issue is resolved, they will contact the release team and our PR team to coordinate the publication of the security advisory.

Security issues have the equivalent of a P0 priority level, but (other than via issue 72555) are
not tracked explicitly in the issue database. This means that we attempt to fix them as quickly as possible.

For more information on security advisories, see [the GitHub documentation](https://docs.github.com/en/free-pro-team@latest/github/managing-security-vulnerabilities/managing-security-vulnerabilities-in-your-project).

If team members need additional help from Google, as a Googler, they can see go/vuln.
