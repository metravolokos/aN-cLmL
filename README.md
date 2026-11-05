# CloudMail Player — WebDAV M0

M0 research only. This repository is **not** a finished Windows/Android player. Planned application: cross-platform Flutter music player using only Cloud Mail.ru WebDAV /AllMusic with no Google services.

## Probe

Python 3.11+ standard library only.

~~~sh
python -m unittest discover -s tests -v
python tools/webdav_probe.py
# Only after Codex Personal environment secrets have been configured:
python tools/webdav_probe.py --live --output m0-results.private.json
~~~

No live request is made unless --live is given. Use a Mail.ru *external application password*, not an ordinary mail password. Supply WEBDAV_USERNAME and WEBDAV_PASSWORD as process environment variables, not command arguments or committed files. The endpoint is https://webdav.cloud.mail.ru.

The live probe uses only PROPFIND, HEAD, and small GET Range requests, never modifies cloud files, and intentionally excludes personal filenames and credentials from results. A complete index, streaming playback, rate-limit benchmarks, Android integration and all other stages are out of scope.

Codex task: CODEX_CLOUD_M0_TASK.md. Agent rules: AGENTS.md. Results and limitations: docs/webdav-notes.md.
