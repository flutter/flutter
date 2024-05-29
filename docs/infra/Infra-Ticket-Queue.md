# Quick Links
*   [Ticket queue kanban board](https://github.com/orgs/flutter/projects/81)
*   [Build dashboards](https://flutter-dashboard.appspot.com/)
*   [Current on-call](https://rotations.corp.google.com/rotation/5729708174999552) (Google internal link)

# Background

The Flutter infra team uses a ticket queue to manage operational tasks, such as:
*   Configuration requests: "Please add a new LUCI builder"
*   Outage/degradation notifications: "Build dashboard is down/slow"
*   Requests for help: "How do I debug a test on devicelab machine X?"

This allows the team to separate their engineering work from ["toil" work](https://landing.google.com/sre/sre-book/chapters/eliminating-toil/). It also lets them see which types of tasks are common and worth automating.

IMPORTANT: Whenever you have a request for the infra team, please file a ticket instead of contacting team members directly, even for seemingly trivial things or even if an individual has done the same thing for you in the past. Infra on-call will be there to handle your request, and it lets non on-call team members focus on their engineering tasks.

When in doubt, ask on the `#hackers-infra` channel in [Chat](../contributing/Chat.md).

# How to File a Ticket as an Infra Customer
1. Open a [new infra issue](https://github.com/flutter/flutter/issues/new?template=6_infrastructure.yml). (That template summarizes the information on this page.)
2. Add a descriptive **title**. A message like "Add a LUCI builder for linux web engine" or "Debug gallery startup" is much more helpful than "quick request" or "test doesn't work?".
3. Clearly describe the issue or request in the description field. For example, if a ticket is requesting running several commands on the bots, the ticket should explain why, what commands are needed, on which bots and how to verify the results.
4. Skip the priority label which infra on-call will add after triaging.
5. **Add the project "Infra Ticket Queue".** This is the step that is important to get it into the queue!
6. Click the **Submit new issue** button. No need to set an **assignee**; infra on-call will handle all new tickets.

Please note that **the ticket queue is meant for high priority P0 and P1 issues** and should not be used to file low priority issues like feature requests or minor bugs. We have another separate weekly triage meeting that will look through ALL of the open infra issues. The ticket queue should only be used for issues that fall into the following categories, which should be very rare:

  * Build break or regression.
  * Critical work is blocked without a workaround.
  * An immediate-level incident will happen if this is not addressed (e.g., almost out of quota).
  * Degraded service (Build bots work but are slow to start).
  * Other time-sensitive requests.

# How to Serve Tickets as an Infra On-call
Below are instructions for infra on-call on how to process the ticket queue. It describes the processes that on-call should follow, along with useful tips and tricks. If you are on call and see a problem or omission on this page, please change it!

## Triaging
SLO: A ticket in the queue will be triaged within 4 business hours provided it is opened during regularly kept office hours (9 a.m. to 5 p.m. PST). Otherwise it will be triaged the following business day.

The issue priorities can be found [here](../contributing/issue_hygiene/README.md#priorities). Issues that are **not P0 or P1** will still be seen (during the infra weekly triage meeting) but do not belong on the ticket queue.

New, un-triaged tickets will be in the **New** column in [the ticket queue](https://github.com/orgs/flutter/projects/81/views/1).

When a new ticket comes in, an on-call should:
1. Double check to see if the issue is a duplicate and close with a reference to the existing open issue.
2. Check the issue summary and description. If the summary isn't clear, clarify it.
3. Validate that the priority of the issue is accurate.
4. Move triaged issues to the **Triaged** column.
5. Assign the issue to the correct team member.

This is meant to be quick and mechanical, and doesn't require a lot of thought. Even if you don't have time to take any immediate action, it's helpful to keep the new column empty. Your marking it triaged also lets the ticket creator know that someone has seen it.

## Serving
Once all tickets have been triaged, on-call's job is to service them. Apply judgement regarding which is most pressing. The order will also depend on your expertise and how much time you have. If a lower-priority ticket can be resolved in a couple minutes, don't feel like it has to wait behind a higher-priority ticket.

From the top of the priority queue down, on-call makes sure that someone is working on each ticket. It's important to keep things moving if you see that they're stuck; try CC'ing people with more information and making it clear what a given ticket is blocked on.

1. Set the assignee. Read the [guideline](../contributing/issue_hygiene/README.md#assigning-issues) first. In addition:
    *   All tickets must be assigned to someone who is working on them.
2. Start working on the ticket
    *   Set the status to "in progress", typically by dragging its card to the **In progress** column.
    *   Add a comment, if you think it helps.
3. P0 issue should be updated daily and P1 issue should be updated weekly, since many people may be blocked and will be waiting for updates.
4. Update the ticket's workflow state when you reach a stopping point
    *   If it's closed, move it to **Done**.
    *   If it's blocked on something else, make it clear in the comments.
    *   If you (or the assignee) can no longer work on the ticket, find a new owner or move it back to **New**.
    *   If you're heading home for the day, add a final status update, especially if they're not going to get resolved in their urgency window.

When servicing a ticket as an on-call, remember that **it is not your responsibility to fix every ticket, only to make sure that someone is working on it**. You may not be the most appropriate person to do the work, but you make sure the work gets done. This goes for new tickets as well as older tickets that someone has claimed but dropped on the floor -- some of those tickets may even have been created and assigned during the previous on-call shift, so it's important to check up on older tickets and re-assign if necessary.

## Handoff

On Monday during the 15-minute handoff meeting, please add comments and update the status on any tickets on which you have context, as this will help the next on-call person ramp up and understand the coming workload.
