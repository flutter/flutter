module.exports = async ({github, context}) => {
  const owner = context.repo.owner;
  const repo = context.repo.repo;
  const labelName = 'waiting for customer response';

  const item = context.payload.issue || context.payload.pull_request;
  const sender = context.payload.sender;

  let isResponse = false;

  if (context.eventName === 'issue_comment' || context.eventName === 'pull_request_review_comment') {
    const comment = context.payload.comment;
    if (comment && comment.user.id === item.user.id) {
      isResponse = true;
    }
  } else if (context.eventName === 'pull_request' && context.payload.action === 'synchronize') {
    if (sender && sender.id === item.user.id) {
      isResponse = true;
    }
  }

  if (isResponse) {
    // Author responded
    const hasLabel = item.labels.some(l => l.name === labelName);
    if (hasLabel) {
      console.log(`Removing label from #${item.number} as author responded.`);
      await github.rest.issues.removeLabel({
        owner,
        repo,
        issue_number: item.number,
        name: labelName,
      });

      if (item.state === 'closed') {
        console.log(`Reopening #${item.number}.`);
        await github.rest.issues.update({
          owner,
          repo,
          issue_number: item.number,
          state: 'open',
        });
      }
    }
  }
};
