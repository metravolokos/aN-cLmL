# Cloud Mail.ru WebDAV notes

## Confirmed from official documentation (not live-tested here)
- Endpoint: https://webdav.cloud.mail.ru
- Requires a Mail.ru external application password rather than the account's ordinary password.
- Intended music root: /AllMusic.

Source: https://help.mail.ru/cloud/desktop/webdav/

## Observations from earlier local attempt, 2026-11-05
- DNS resolution to webdav.cloud.mail.ru failed in the temporary runtime.
- No HTTP status or authenticated response was obtained. This is NOT proof of invalid credentials.
- Offline unit tests passed but do not establish any provider behavior.

## Open validation for Codex Cloud
- HTTPS connection with account credentials; PROPFIND Depth 0 and 1.
- Audio-file HEAD response and metadata presence.
- GET Range for 4 KiB, 64 KiB, offset and 128 KiB requests, suffix request.
- Actual 206 framing and Content-Range syntax, especially bytes= vs bytes space.
- Bounded latency; no full-file downloads.

Not in scope: full indexing, high-concurrency/rate-limit stress, full audio streaming, seek latency, tag extraction, cache design, Flutter or Android builds. Record verified results with dates and mark unsupported cases as unknown, not passed.
