# WhoCall Community Moderation Runbook

WhoCall applies zero tolerance to objectionable community content and abusive users. Every in-app content report and user block creates or updates a document in `communityModerationReports` and emits the structured Cloud Logging event `community_moderation_report_created`.

## Response target

- Review every report within the internal 4-hour response target and always before its `reviewBy` timestamp.
- The absolute removal and abusive-account action limit is 24 hours after the first report, as required by App Review Guideline 1.2.
- Reports remain `pending` until a moderator records a decision.
- A report or block immediately hides the affected content for the reporting user.
- Blocking a comment author immediately hides that author's comments for the reporting user and notifies the moderation queue.

## Moderator decisions

Use the protected `moderateCommunityReport` callable. Only Firebase users with the custom claim `communityModerator: true` can invoke it.

- `dismiss`: keep the content and close the report.
- `remove-content`: hide the reported comment globally or remove the reported tag.
- `remove-content-and-suspend-user`: remove the content and disable the author in Firebase Authentication.

Record the `reportID` and one of those decision values. The function stores the resolver hash and resolution timestamp in the report document.

## Daily queue check

1. Filter `communityModerationReports` where `status == "pending"`, ordered by `reviewBy` ascending.
2. Review the stored content snapshot and selected reason without exposing the reporter's identity.
3. Apply the appropriate moderator decision.
4. Confirm no pending item has crossed its `reviewBy` timestamp.
5. Escalate credible threats, unlawful disclosures, or repeat abuse to the account owner and legal contact immediately.

The enabled Cloud Monitoring log alert for `community_moderation_report_created` notifies `support@levelappstudio.com` when a new report reaches the moderation queue.
