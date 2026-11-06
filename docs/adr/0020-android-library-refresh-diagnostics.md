# Android library refresh regression — diagnostic boundary

Date: 2026-11-06

## Observed

On a Huawei test device, four-tab navigation, titles and search passed, but the media library was not visible. The user confirms all music files are **directly in one directory** and that indexing worked in earlier builds. Do not attribute the report to nested folders, unsupported formats, device/network failure, or playback until evidence confirms it.

## Source inspection

Authentication checks WebDAV `/AllMusic` using Depth:0. Refresh independently performs Depth:1, applies the supported-audio filter, writes SQLite, and then starts metadata. An HTTP 207 verification is not evidence that the file listing or local database succeeded. The preexisting UI used the same generic "library not connected" empty screen whether refreshing, empty, or uninitialized, and swallowed the specific cause of a refresh error.

## Narrow change

Record whether a failure happened during listing/catalog storage or metadata extraction, and expose only the enumerated `CloudMailErrorCode` (or unknown). The error display never includes URL, path, response XML, account name, password, headers or raw exception text. Preserve already loaded tracks after metadata failures. Show the localized empty-library label only if refresh finished and found no supported files.

## Acceptance

Run Dart/Flutter/Python tests, Android debug and ARM64 preview CI at exact HEAD. On real device with saved credentials, press refresh once; observe the safe stage/code if it fails, or the actual number of tracks if it succeeds. No account data, filenames, logs or credentials should be pasted into an issue. If a specific failure is now reproducible, fix that cause in a subsequent focused PR. This change is diagnostic hardening, not proof that indexing is repaired.
