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
