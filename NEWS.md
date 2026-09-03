# livecaption 0.1.8

- Rebuilt the package from the stable 0.1.4 application-control implementation.
- Retained the safe JSON sanitization for non-finite window coordinates so
  status checks do not fail after manual window-state changes.
- Removed `lc_app_hide()` and `lc_app_show()` and their window-moving helpers;
  users can manage Live Captions visibility and position directly through
  Windows.
- Added `lc_capture_init()` to store the current caption as a baseline.
- Added `lc_capture_text()` to capture a fresh ending snapshot and return the
  overlap-aware text added after the baseline.
- Added `lc_capture_copy()` to capture a fresh ending snapshot and copy the
  resulting text to the Windows Unicode clipboard.
- When no capture baseline exists, retrieval uses an empty dummy baseline and
  returns the complete currently exposed caption. Capture calls do not create
  bookmarks or replace the stored baseline.

# livecaption 0.1.7

- Changed `lc_app_hide()` back to capture-safe corner parking. It keeps Live
  Captions restored, leaves a small visible edge, and verifies that its caption
  control remains accessible.
- `lc_app_show()` restores the position recorded by `lc_app_hide()` but leaves
  an already-visible, manually repositioned window unchanged.
- Retained detection and restoration of windows minimized manually through
  Windows, while documenting that caption extraction during minimization is not
  considered reliable.
- `lc_bookmark()` now refuses capture while Live Captions is minimized instead
  of returning potentially unavailable or stale text.
- Retained the 0.1.6 JSON fix that converts non-finite UI Automation rectangle
  coordinates to `null`.

# livecaption 0.1.6

- Fixed `lc_app_status()` after minimization by converting the non-finite UI
  Automation rectangle values returned by some Windows builds to JSON `null`.
- This prevents `Infinity` and `-Infinity` values from causing a JSON parsing
  error while `lc_app_hide()` verifies that minimization succeeded.

# livecaption 0.1.5

- Replaced experimental corner parking with native Windows minimization in
  `lc_app_hide()`.
- Changed `lc_app_show()` to restore a minimized Live Captions window to its
  previous size and position and then request foreground focus.
- Added `minimized`, `foreground`, and `offscreen` fields to `lc_app_status()`.
- Removed the `corner` and `visible_pixels` arguments and all saved-position
  state because hide/show no longer moves the window.

# livecaption 0.1.4

- Removed the process-level PowerShell `ExecutionPolicy Bypass` setting.
- PowerShell scripts now inherit the effective Windows execution policy,
  including policies configured by an organization.

# livecaption 0.1.3

- Re-established `lc_app_start()` and `lc_app_stop()` as the only application
  lifecycle names; removed `lc_app_run()` and `lc_app_close()`.
- Added `lc_bookmark_copy()` for copying extracted caption text to the Windows
  Unicode clipboard without printing long strings in the R console.
- Made `lc_app_show()` leave an already-visible, manually positioned window
  unchanged.
- Reframed the package documentation around its main purpose: extracting
  Windows Live Captions text into R for further processing and export.
- Added the project GitHub repository and issue-tracker links.

# livecaption 0.1.2

- Renamed the primary application commands to `lc_app_run()` and
  `lc_app_close()`. The former names remain as deprecated aliases.
- Added the read-only `lc_bookmark_text()` function with automatic bookmark 0,
  order-independent numeric endpoints, intermediate-snapshot merging, and
  overlap-aware handling of rolling and revised captions.
- Normalized visual Live Captions line breaks to ordinary spaces in retrieved
  and stored caption text.

# livecaption 0.1.1

- Restored the caption-control fallback from the original Shiny prototype so
  Windows builds without `CaptionsTextBlock` can use the most likely text
  element inside the detected Live Captions window.
- Added a second known caption ID and process-name-based window detection.
- Added the caption selector and detected Automation ID to `lc_app_status()`
  for troubleshooting Windows UI variations.
- Renamed the bookmark retrieval function to `lc_bookmark_list()`.
- Changed `lc_app_stop()` to close the detected window directly rather than
  treating the start shortcut as a toggle.
- Changed `lc_app_hide()` to park Live Captions at a selected corner while
  leaving a small visible edge for manual recovery.

# livecaption 0.1.0

- Added idempotent Windows Live Captions start and stop functions.
- Added window status inspection.
- Added experimental, reversible corner hide and show functions.
- Added numbered, in-memory bookmarks with ISO 8601 timestamps.
- Added list and data-frame representations of bookmarks.
