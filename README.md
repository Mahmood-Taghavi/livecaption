# livecaption

GitHub repository: <https://github.com/Mahmood-Taghavi/livecaption>

`livecaption` is a Windows-only R package for extracting text produced by
Windows 11 Live Captions and bringing it into R for further processing. It
turns manually selected caption snapshots and the text added between them into
ordinary R character strings, lists, and data frames that can be cleaned,
analysed, translated, saved, or used in later subtitle workflows.

Version 0.1.8 deliberately contains only the first dependable layer:

- start, stop, and inspect Windows Live Captions;
- capture manually requested bookmarks;
- retain bookmarks as numbered R objects for the current R session;
- retrieve revised text added between two bookmarks;
- immediately retrieve or copy text added after an initialized baseline.

## What the package brings into R

Windows Live Captions displays transcription on screen but does not provide a
convenient transcript for analysis. `livecaption` reads the accessible caption
text and makes it available as normal R objects. For example, you can:

- extract the current caption at meaningful moments;
- capture text added after a user-initialized baseline;
- isolate text added between two numbered bookmarks;
- inspect bookmarks as a list or data frame;
- copy long extracted text directly to the Windows clipboard;
- pass the text to R functions for cleaning, searching, translation, text
  analysis, reporting, or file export.

The package does not send caption text to an external service. Any subsequent
processing is determined by the R code and packages chosen by the user.

Continuous text capture, timestamped recording, subtitle reconstruction, and a
Shiny interface are planned for later versions.

## Licence

GPL version 3 or later.

## Requirements

- Windows 11 with Live Captions available;
- Windows PowerShell 5.1 or later;
- R 4.2 or later.

The package does not bypass or replace the configured PowerShell execution
policy. Its temporary local scripts inherit the effective policy set by
Windows or by your organization. If that policy prevents the scripts from
running, contact your system administrator rather than changing the policy.

The R dependencies are installed automatically:

- `processx`
- `jsonlite`

## Install from a local source folder

```r
install.packages("remotes")
remotes::install_local("C:/path/to/livecaption")
```

During development, you can also use:

```r
install.packages("devtools")
devtools::load_all("C:/path/to/livecaption")
```

## Install from GitHub

Install the development version directly from GitHub:

```r
install.packages("remotes")
remotes::install_github("Mahmood-Taghavi/livecaption")
```

## Application controls

```r
library(livecaption)

lc_app_start()
lc_app_status()
```

`lc_app_start()` first checks whether Live Captions is already open, so calling
it repeatedly will not toggle the application off.

Close it with:

```r
lc_app_stop()
```

The package intentionally does not hide, show, move, or minimize the Live
Captions window. Those actions were unreliable across Windows configurations.
You can reposition or minimize the window manually when needed, although text
accessibility while minimized depends on Windows and should be checked before
relying on it.

Inspect the window state programmatically:

```r
status <- lc_app_status()
status[c("running", "visible", "hidden", "text_accessible")]
```

## Immediate capture from a baseline

Initialize the current visible caption as the starting baseline:

```r
lc_capture_init()
```

After more captions appear, capture a fresh ending snapshot and return only the
text added after the baseline:

```r
captured_text <- lc_capture_text()
```

Or capture a fresh ending snapshot and copy the result directly to the Windows
clipboard:

```r
lc_capture_copy()
```

`lc_capture_text()` and `lc_capture_copy()` do not change the baseline and do
not create bookmarks. Calling `lc_capture_init()` again replaces the baseline.
If no baseline has been initialized, an empty dummy baseline is used, so the
complete caption currently exposed by Live Captions is returned or copied.

This is a two-snapshot operation. It can handle rolling-window overlap and
recent corrections, but text that has already left the Live Captions window
cannot be recovered when no overlap remains. In that case, the function warns
that the result may be incomplete. For longer material, create intermediate
bookmarks before text scrolls out of the caption window.

## Bookmarks

Create a bookmark from the complete caption currently visible:

```r
b1 <- lc_bookmark()
b1
```

Its structure is:

```r
list(
  bookmark_id = 1L,
  time = "2026-09-02T14:35:27.418+02:00",
  label = "2026-09-02T14:35:27.418+02:00",
  caption = "The complete visible caption."
)
```

The ISO 8601 timestamp is the default label. Supply a custom label when useful:

```r
lc_bookmark("Definition of feedback")
lc_bookmark("Important example")
```

Retrieve all bookmarks:

```r
bookmarks <- lc_bookmark_list()
bookmarks[[1]]$caption
```

Retrieve text added between bookmarks:

```r
lc_bookmark_text()                  # earliest to latest bookmark
lc_bookmark_text(from = 2, to = 5)
lc_bookmark_text(from = 5, to = 2) # same result: IDs are reordered
lc_bookmark_text(from = 0, to = 3) # empty dummy baseline to bookmark 3
```

With only one bookmark, the default comparison uses dummy bookmark 0, whose
caption is empty, and therefore returns the complete first bookmark. The
function merges all snapshots in the selected range so later Live Captions
corrections replace earlier wording. It does not create a new bookmark.

Caption text is stored as normalized single-line text. Visual line wrapping
from the Live Captions window is replaced with spaces.

Copy extracted text without printing it in the R console:

```r
lc_bookmark_copy()
lc_bookmark_copy(from = 2, to = 5)

# Paste the result into Notepad, Word, an email, or another application.
```

The function returns the same text invisibly and does not create a bookmark.

Convert them to a data frame for analysis:

```r
bookmark_data <- as.data.frame(lc_bookmark_list())
```

Remove the in-memory bookmarks:

```r
removed <- lc_bookmarks_clear()
```

Bookmarks are intentionally stored only in the current R session in this first
version. Assign `lc_bookmark_list()` to an object or save it with `saveRDS()` when
you need persistence:

```r
saveRDS(lc_bookmark_list(), "live-caption-bookmarks.rds")
```

## Initial Windows checks

After installation, try:

```r
library(livecaption)

lc_app_start()
lc_app_status()

# Speak or play audio until text is visible.
test_bookmark <- lc_bookmark("Initial test")
test_bookmark$caption

lc_capture_init()

# Allow more captions to appear.
captured_text <- lc_capture_text()
lc_capture_copy()

lc_app_stop()
```

## Caption-control troubleshooting

Different Windows 11 builds can expose the caption control under different UI
Automation IDs. The package first tries the known IDs and then falls back to
the most likely text element inside the detected Live Captions window. Inspect
the selected method with:

```r
status <- lc_app_status()
status[c(
  "running",
  "text_accessible",
  "caption_source",
  "caption_automation_id"
)]
```

When reporting a remaining detection problem, include the complete result from
`dput(lc_app_status())`.
