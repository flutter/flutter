module.exports = async ({ github, context }) => {
  const owner = context.repo.owner;
  const repo = context.repo.repo;
  const labelName = 'waiting for response';
  const daysUntilClose = 21;
  const issueCloseComment = `Without additional information, we are unfortunately not sure how to resolve this issue. We are therefore reluctantly going to close this bug for now.

If you find this problem please file a new issue with the same description, what happens, logs and the output of 'flutter doctor -v'. All system setups can be slightly different so it's always better to open new issues and reference the related ones.

Thanks for your contribution.`;

  const prCloseComment = `This pull request is being closed because it has not been updated in the last 21 days after a request for more information.

If you are still working on this, please feel free to reopen it or file a new pull request.

Thanks for your contribution.`;

  const now = new Date();
  const closeDate = new Date(now.getTime() - (daysUntilClose * 24 * 60 * 60 * 1000));

  // Fetch issues and PRs with label
  const issues = await github.paginate(github.rest.issues.listForRepo, {
    owner,
    repo,
    state: 'open',
    labels: labelName,
  });

  for (const issue of issues) {
    const isPr = issue.pull_request !== undefined;

    // Fetch timeline events to find label date
    const events = await github.paginate(github.rest.issues.listEvents, {
      owner,
      repo,
      issue_number: issue.number,
    });

    const labelEvent = events.reverse().find(event => event.event === 'labeled' && event.label.name === labelName);

    if (!labelEvent) {
      continue; // Skip if label not found in events
    }

    const labeledAt = new Date(labelEvent.created_at);
    let isResponse = false;

    // Check for author comments after label
    const comments = await github.paginate(github.rest.issues.listComments, {
      owner,
      repo,
      issue_number: issue.number,
      since: labeledAt.toISOString(),
    });

    for (const comment of comments) {
      if (comment.user.id === issue.user.id && new Date(comment.created_at) > labeledAt) {
        isResponse = true;
        break;
      }
    }

    // Check for commits after label if it's a PR
    if (!isResponse && isPr) {
      const commits = await github.paginate(github.rest.pulls.listCommits, {
        owner,
        repo,
        pull_number: issue.number,
      });

      for (const commit of commits) {
        const commitDate = new Date(commit.commit.committer.date);
        if (commitDate > labeledAt) {
          isResponse = true;
          break;
        }
      }
    }

    if (isResponse) {
      console.log(`Removing label from #${issue.number} as author responded.`);
      await github.rest.issues.removeLabel({
        owner,
        repo,
        issue_number: issue.number,
        name: labelName,
      });


      continue; // Skip stale check
    }

    // Stale check
    if (issue.state === 'open') {
      if (labeledAt < closeDate) {
        console.log(`Closing #${issue.number} due to no response.`);
        const body = isPr ? prCloseComment : issueCloseComment;
        if (body) {
          await github.rest.issues.createComment({
            owner,
            repo,
            issue_number: issue.number,
            body: body,
          });
        }
        await github.rest.issues.update({
          owner,
          repo,
          issue_number: issue.number,
          state: 'closed',
        });
      }
    }
  }
};
