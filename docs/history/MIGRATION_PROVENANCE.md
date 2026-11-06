# Android migration provenance

- Original: https://github.com/metravolokos/cloudmail-player-m0
- Destination: https://github.com/metravolokos/aN-cLmL
- Source main at migration audit: `2d373369bfe0e7b256dd98534cc90933336e3811` (verify exact merge ancestry before relying on SHA as a frozen release).
- Destination imported HEAD: `37e296518fc53bbb37c9cc7de5f689ff3e0c726e`.
- Original code, history, specifications, source/experiment branches and tags imported by owner through non-force Git operation.
- Original repository is read-only *for this migration process*; not modified.
- Source project licence removal merged as PR #52 before import; third-party notices remain separately applicable.
- Secret scan: 342 commits scanned locally; Gitleaks reported two reviewed false positives in docs/PLATFORMS.md line 18 for a Linux package name; verify scanner configuration and rerun on new refs before release. Scanner is heuristic, not a guarantee.
- Original `docs/USER_SPEC_RU.md` is an immutable historical requirement source, including desktop scope. Current Android specification must separately record Android-applicable requirements without rewriting historical text.
- Existing desktop directories remain until an Android-only change passes CI. No runtime functionality can be called accepted on Huawei solely from the source migration.
- GitHub native PRs/issues/comments/actions are not automatically copied by Git history. The historical indexes link them; an additional audited discussion export can preserve their available content.

## Unfinished upstream work

- [PR #36](https://github.com/metravolokos/cloudmail-player-m0/pull/36): stale source stream event guards; unmerged, evaluate for Android.
- [PR #38](https://github.com/metravolokos/cloudmail-player-m0/pull/38): history scanning; unmerged, evaluate separately.
- [PR #48](https://github.com/metravolokos/cloudmail-player-m0/pull/48): explainability contract; unmerged, carry forward the intent.
- Windows-specific P03 diagnostics belong to desktop historical research, not Android's immediate backlog.
