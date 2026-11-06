# Failed approaches and engineering lessons (evidence-linked)

Historical evidence, not assertions that a defect remains in the current code. Read the source PR, follow-up PR and current implementation before changing a module.

## Independent M2-A transport implementations

Early development compared [ChatGPT's dart:io HttpClient implementation (PR #4)](https://github.com/metravolokos/cloudmail-player-m0/pull/4) with [Codex's Dio implementation (PR #5)](https://github.com/metravolokos/cloudmail-player-m0/pull/5). Both were kept as separate Draft comparisons rather than promoted simply because CI passed.

- [Review on PR #4](https://github.com/metravolokos/cloudmail-player-m0/pull/4#issuecomment-6659514360): the smaller HttpClient implementation needed explicit rejection of XML document-type/entity constructs; the settings widget held an app-password copy in widget state longer than necessary. It did include DAV namespace and root checks.
- [Review on PR #5](https://github.com/metravolokos/cloudmail-player-m0/pull/5#issuecomment-6659513396): the Dio variant initially omitted INTERNET in the release Android manifest while debug/profile carried it, creating a release-only network risk. Its DAV namespace checking and missing-root error classification also needed scrutiny.
- [Technology decision on PR #4](https://github.com/metravolokos/cloudmail-player-m0/pull/4#issuecomment-6659711929) and [PR #5](https://github.com/metravolokos/cloudmail-player-m0/pull/5#issuecomment-6659714877): compare persistent pooled HttpClient and Dio under equivalent real-cloud Range/timeout/retry rules; green unit/CI tests are **not throughput evidence**. The associated benchmark gate is [Issue #6](https://github.com/metravolokos/cloudmail-player-m0/issues/6).
- Both drafts were superseded by the integrated [PR #11](https://github.com/metravolokos/cloudmail-player-m0/pull/11), as documented in the [PR #4 closure comment](https://github.com/metravolokos/cloudmail-player-m0/pull/4#issuecomment-6666108570) and [PR #5 closure comment](https://github.com/metravolokos/cloudmail-player-m0/pull/5#issuecomment-6666110004). Do not reopen the old branches as new Android feature work.

**Reusable lesson:** inspect the release manifest, credentials lifetime, DAV parsing and live-cloud evidence separately. Passing CI did not establish successful authenticated playback.

## Shared async playback defects and guards

- [PR #12](https://github.com/metravolokos/cloudmail-player-m0/pull/12) guarded against audio resuming after Stop during asynchronous source opening.
- [PR #13](https://github.com/metravolokos/cloudmail-player-m0/pull/13) guarded against stale credential-store reads recreating a disconnected session.
- [PR #23](https://github.com/metravolokos/cloudmail-player-m0/pull/23) prevented delayed Play/Seek commands from reviving stopped playback.
- [PR #35](https://github.com/metravolokos/cloudmail-player-m0/pull/35) guarded transport commands during asynchronous track switches.
- [PR #36](https://github.com/metravolokos/cloudmail-player-m0/pull/36) remains an unmerged draft proposing to suppress stale source stream events. Assess and test it against current Android code before adopting it.

**Reusable lesson:** selecting, stopping, replacing and disconnecting an audio source all cross asynchronous boundaries; the latest user intent and lifecycle generation must win. Avoid assuming that an upstream draft was merged.

## Privacy and publication

- [PR #37](https://github.com/metravolokos/cloudmail-player-m0/pull/37) replaced private WebDAV relative file names in Android MediaSession IDs with opaque identities.
- [PR #52](https://github.com/metravolokos/cloudmail-player-m0/pull/52) removed an unrequested MIT licence. Publication alone does not establish an owner-authorized project-wide licence; dependencies have separate notices.

## Coverage gaps requiring evidence

- [PR #50](https://github.com/metravolokos/cloudmail-player-m0/pull/50) addressed an observed library-not-updating issue shared across platforms.
- [PR #53](https://github.com/metravolokos/cloudmail-player-m0/pull/53) investigated a Windows P03 backend error; its Windows-specific native diagnosis is historical, **not** evidence of an Android defect.
- [Android device checklist](../ANDROID_PREVIEW.md) and [requirement traceability](../REQUIREMENTS_TRACEABILITY.md) still distinguish integrated code and build checks from Huawei acceptance.

## How future agents should use this record

Cite exact source PR/issue/comment/commit for each explanation. Check the current tree and regression tests before stating a historical problem persists. Record novel failed experiments in new evidence-linked entries; never turn guesses into reasons after the fact.
