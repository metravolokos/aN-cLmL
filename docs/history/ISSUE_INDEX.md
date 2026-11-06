# Historical issue register

Source: https://github.com/metravolokos/cloudmail-player-m0/issues. Live issue conversations and comments remain linked at original URLs; the text below preserves the descriptions available at migration.

## [M2 transport decision gate — measured WebDAV benchmark before selecting Dio/HttpClient/native](https://github.com/metravolokos/cloudmail-player-m0/issues/6)

## Why this is required

The user explicitly rejected an unmeasured technology choice. M2-A PR #4 (ChatGPT, dart:io HttpClient) and PR #5 (Codex, Dio) are both green but use different request/session lifecycle, retry and parsing rules. Their CI test counts do **not** provide comparative transport performance data. Do not pick a permanent transport or merge either solely on style/test count.

Goal: choose the **best verified Windows 11 + Huawei Android (no Google Mobile Services)** networking technology for Cloud Mail.ru WebDAV /AllMusic, based on reliable real-world measurements, security and maintainability, with a short bounded experiment rather than hours-long stress testing.

## Research and candidates (write a short decision matrix first)

1. Persistent dart:io HttpClient on both platforms (reuse one client; do not create/close per request).
2. Dio with default dart:io IOHttpClientAdapter on both platforms.
3. Official package:http IOClient (same underlying networking, different replaceable abstraction).
4. Android-native OkHttp client, considering package:ok_http and the maintenance status of the package and/or a thin Kotlin adapter; verify PROPFIND support, streaming Range responses, cancellation, proxy/VPN, and no GMS.
5. Android-native Cronet *embedded* (the default Google Play Services-backed option is **ineligible**); assess APK size, maintenance and feasibility for arbitrary WebDAV methods.
6. Windows-native WinHTTP, and optionally WinINet if desktop system-proxy requirements justify it; consider platform-channel/FFI complexity.
7. Existing libcurl/curl_cffi or other cross-platform native transport only if credible maintenance/platform packaging and safe proxies/TLS; don't add candidates by guesswork.

Research official API docs, package releases, supported target platforms, dependency GMS audit, Windows packaging, maintenance, proxy/VPN behavior and protocol capabilities. Reject unsupported candidates **with recorded reasons**; do not silently limit scope to Dio vs dart:io. Primary comparison should first cover equivalent Dart transports; native alternatives receive short feasibility and representative on-device probes where viable.

Documentation references: https://pub.dev/documentation/http/latest/ , https://pub.dev/documentation/dio/latest/dio/HttpClientAdapter-class.html , https://pub.dev/packages/cronet_http , https://pub.dev/packages/ok_http , https://learn.microsoft.com/en-us/windows/desktop/WinHttp/about-winhttp .

## Fair benchmark design

**Two layers, not mixing them:** (a) isolated transport benchmark with identical WebDAV request/response validation, connection reuse and security policies; (b) end-to-end sample of the actual app implementation to expose extra parser/UI overhead. Do not compare PR #4's one-new-HttpClient-per-request against PR #5's pooled Dio and attribute the difference to the library; add pooled dart:io candidate.

- Real test target: HTTPS webdav.cloud.mail.ru, strictly read-only /AllMusic. Use fresh external-application password in user's secure/local environment only. **Never commit any credentials, real filenames, URLs with credentials, raw XML, Authorization headers, metadata or file lists. CI uses anonymous loopback fixtures exclusively.**
- Fix a sanitized selection procedure of 16–24 existing files; sample positions and FLAC/MP3 mix without logging names. Use exactly the same set and byte ranges for each candidate.
- Include: root PROPFIND Depth:0, one **real full flat-folder Depth:1** listing (record response size and whether parser/body budget supports ~3590 files), 4 KiB and 64 KiB Range GET, status 206/207 and Cloud-specific Content-Range syntax; optional single 128 KiB probe as a separate compatibility check, not assumed safe by default.
- Measure cold first connection and warmed/reused requests separately; sequential vs max 4 simultaneous requests. Rotate candidate execution order (ABBA or randomized fixed seeded order) in at least two short rounds on each target, rather than running all A on a good network interval and B later. Keep request behavior identical: timeouts, compression off for ranged data, disabled redirects, same retries (prefer no retries for raw performance, separate retry/cancellation correctness tests), same process/network conditions.
- Metrics: success/transport errors, HTTP statuses, exact bytes requested/received, per-request latency p50/p95, full listing time and XML bytes, wall-clock per 16–24-track sample, peak memory, CPU (where measurable), network connections/TLS handshakes (when measurable), APK/EXE footprint, cancellation correctness, observed behavior through user's VPN/proxy path, Android without GMS.
- Bound budgets **per platform**: <=10 minutes total, <=400 GET calls, <=24 MiB received audio bytes, <=12 full-directory PROPFIND operations, no full-track downloads, no writes. Stop sooner if results are decisive. Device/network logs are sanitized summaries only. If a 1 MiB hard cap prevents the full listing, record failure and review cap/streaming parse design instead of claiming server failure.
- Use one short loopback correctness test suite for all transport adapters (redirect Authorization isolation, invalid XML/path, no full GET, status and content-range, timeouts, cancellation) before real benchmark.
- Windows 11 desktop and user's Huawei Android each need **actual on-device** results; Linux runners alone are NOT substitute. Ideally same WLAN for the comparison, additionally brief test of realistic VPN/proxy/mobile network conditions if normally used.

## Decision gate

1. **Hard failures:** reject GMS-dependent implementation, path escape, credential forwarding, wrong-size/full-range behavior, broken cancellation, inability to use real Cloud Mail.ru or user's VPN/proxy. Performance never overrides these.
2. Among passing options, compare results by platform and workload: cold/warm, sequential/concurrent, failures, p95 and total wall time; benchmark uncertainty due to variable server/network conditions. Do not declare a winner based on one absolute latency measurement.
3. If equivalent within measurement noise, choose lower-complexity, maintainable transport and document why. If native is materially superior on the Huawei/Windows, allow platform-specific adapters behind **one** transport interface rather than forcing identical internals on both platforms.
4. Write a concise ADR with test setup, numbers, observed limitations, decision and fallback. Attach sanitized CSV/JSON results to a Draft PR or Issue. User explicitly approves selection and merge afterward.
5. Keep PR #4 and PR #5 separate and Draft until results are compared. Do not reuse either PR's code as benchmark reference without controlling lifecycle and validation parity. No speculative refactor, 6-hour soak, or long network budget.

## Ownership / next step
Coordinator: review benchmark protocol and independent results; implementation agents: create small benchmark harness / adapters and run when device and local secret access are available. Use GitHub Actions only for no-credential offline contract tests. No claims of measured results until the tools actually run.


---

## [M2 — Cloud Mail.ru WebDAV connection, local index and incremental sync (small slices)](https://github.com/metravolokos/cloudmail-player-m0/issues/3)

## Goal
Turn the accepted Flutter M1 shell into a real Cloud Mail.ru-backed music library restricted to **/AllMusic**. This issue describes M2 only; artwork presentation and playback belong to M3/M4. Keep the implementation small and pragmatic.

## Evidence carried from M0
- HTTPS via managed proxy works; authenticated PROPFIND `/AllMusic` returns HTTP 207; HEAD sample HTTP 200 with ETag.
- Five sampled GET Range responses HTTP 206, including 128 KiB; the provider used **`Content-Range: bytes=first-last/total`**, not just the RFC space variant.
- Last-Modified and Accept-Ranges were absent in the sampled HEAD. Never assume they exist. Preserve strict boundary/framing validation.
- These are samples, not general guarantees. No re-running lengthy network stress.

## Work in three focused sub-steps
**M2-A — connection (first, one vertical slice).**
- Choose and verify a Flutter Windows+Android compatible HTTPS client and OS secure credential storage without GMS. Write one short ADR. Do not put secrets into repository, build logs, screenshots, issues, PRs or CI.
- Russian Settings UI: credentials input, Connect / Disconnect, connection error messages (invalid credentials, unavailable service, missing /AllMusic), no default account or hardcoded password.
- Read-only WebDAV PROPFIND Depth:0/1 parser robust to namespaces and percent-encoded Unicode, strict /AllMusic path containment. No DELETE/PUT/MOVE/PROPPATCH. Short cancellable requests and bounded retries.
- Automated local fake server tests, including HTTP 207/401/404, malformed XML and path traversal; no real credentials in CI. Manual connection on user devices once built.

**M2-B — local SQLite catalog.**
- Store per-file stable path/id, ETag, size, optional modification time, scan state and sync-generation marker. Implement bounded Depth:1 breadth-first listing; incremental add/change/remove; cancel/resume; do not scan outside /AllMusic.
- Nonblocking progress and clear empty/error state. Keep scope to the catalog; visual media library layout remains M3. Introduce migration/versioned schema; no speculative indexing architecture.
- Tests with a small fake tree: initial scan, unchanged scan, changed metadata, removed file, cancellation and resume, Unicode filenames.

**M2-C — ranged tag metadata.**
- Read small bounded head/tail ranges for MP3/FLAC first; expand to planned AAC/Opus when validated. Respect Cloud Mail.ru's observed `bytes=` Content-Range shape without relaxing byte count or 206 validation.
- Store artist, album artist, album, title, duration, disc/track numbers; fallback to file/folder name. Track limitations in docs, no whole-file download to parse tags.
- Format-specific tests against fixtures. No artwork rendering, player engine, shuffle, multi-hour soak or 50k full stress in M2.

## Verification / acceptance
- Each sub-step: short named PR with meaningful CI, unit/widget tests and actual Android + Windows build at readiness; user checks relevant UI on devices.
- GMS-free design and APK dependency checks; never use personal account in GitHub Actions.
- Credentials remain in OS-backed secure storage. Cloud access on real account only from user-controlled secure environment, with sanitized output.
- Update docs/STATUS.md, docs/ROADMAP.md, ADR and tests. No unrequested features (playlists, favorites, equalizer).
- M1 PR #2 must be merged before new M2 implementation branches are started.

## Cost/time discipline
No six-hour tests, no repeated revalidation of already established M0 facts, no broad refactors or package sprawl. Investigate concrete failures once, fix regressions, and get working app behavior quickly.