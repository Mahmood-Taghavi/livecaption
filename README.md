# livecaption

GitHub repository: <https://github.com/Mahmood-Taghavi/livecaption>

`livecaption` is a Windows-only R package for extracting text produced by
Windows 11 Live Captions and bringing it into R for further processing. It
turns manually selected caption snapshots and the text added between them into
ordinary R character strings, lists, and data frames that can be cleaned,
analysed, translated, saved, or used in later subtitle workflows.

Version 0.1.4 deliberately contains only the first dependable layer:

- start, stop, inspect, hide, and show the Windows Live Captions window;
- capture manually requested bookmarks;
- retain bookmarks as numbered R objects for the current R session;
- retrieve revised text added between two bookmarks.

## What the package brings into R

Windows Live Captions displays transcription on screen but does not provide a
convenient transcript for analysis. `livecaption` reads the accessible caption
text and makes it available as normal R objects. For example, you can:

- extract the current caption at meaningful moments;
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

### Experimental corner hiding

```r
lc_app_hide()                         # bottom-right corner
lc_app_hide("top_left", 40)          # choose a corner and visible edge
lc_app_status()
lc_app_show()
```

`lc_app_hide()` records the window's location and first tries to park almost all
of it beyond a selected corner of the virtual desktop. A small edge remains
visible so the window can also be recovered with the mouse. If Windows rejects
that position, the function parks the complete window snugly inside the same
corner instead. It verifies both the new position and caption accessibility; if
both placements fail, the original position is restored and an error is
reported. Live Captions may need to be in floating mode before Windows allows
this move.

`lc_app_show()` restores the saved position. If the position is unavailable,
it moves the window to the centre of the virtual desktop.

This feature is experimental because Windows Live Captions may reposition
itself depending on its floating, top, or bottom display mode.

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

lc_app_hide()
lc_bookmark("Bookmark while hidden")
lc_app_show()
lc_app_stop()
```

If hiding is rejected or makes the caption text inaccessible, leave the window
visible and continue using the other functions.

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
