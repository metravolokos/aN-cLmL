# M0 status — 2026-11-05

- Source scaffold uploaded to this separate private GitHub repository for Codex Cloud trials.
- Stage: M0 only. No finished Flutter/Windows/Android application.
- Previous local attempt was blocked by DNS resolution for webdav.cloud.mail.ru, not by a confirmed invalid login.
- Six offline tests passed in the previous local environment. Re-run the tests on the GitHub branch before relying on this upload.
- Authenticated live WebDAV connection, Content-Range behavior, byte limits, timing, tag parsing, media playback and Cloud Mail.ru compatibility are NOT YET verified by Codex.
- The temporary credentials belong only in the Codex Personal environment secrets; they are not in this repository.

## Next

Configure Codex Cloud for this repository, with network access to webdav.cloud.mail.ru and personal environment variables WEBDAV_USERNAME and WEBDAV_PASSWORD. Launch CODEX_CLOUD_M0_TASK.md. Read its report before deciding on any further development. No M1 until confirmed by user.
