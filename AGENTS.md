# CloudMail Player M0 — agent instructions

Read README.md, docs/STATUS.md, docs/webdav-notes.md and CODEX_CLOUD_M0_TASK.md first.

This is a read-only WebDAV connectivity experiment, not yet a music player. Work on M0 only. No Flutter setup, Android SDK, app UI or changes to the real cloud.

Never print, inspect, commit, log, paste, or include in task reports any authentication values, Authorization headers, account identifier, filenames from the user's cloud, or raw WebDAV XML. Obtain WEBDAV_USERNAME and WEBDAV_PASSWORD only from the Codex personal secrets/environment configuration. Never put credentials in source, issues, commits, CI secrets logs, shell commands, or .env files.

For the live account use only HTTPS to https://webdav.cloud.mail.ru and only PROPFIND, HEAD and bounded GET Range. Never use write WebDAV methods, full-media downloads, large-scale scans, or rate-limit stress testing. Respect timeouts and stop on unexpected errors. An HTTP response is not proof of media playback.

Before changing the probe, run the unit tests. Make minimal fixes, rerun tests, update docs/STATUS.md and docs/webdav-notes.md, then stop. Do not start M1 before user approval. Communication: Russian; code, comments and docs: English.
