\name{lc_capture}
\alias{lc_capture_init}
\alias{lc_capture_text}
\alias{lc_capture_copy}
\title{Capture Windows Live Captions Text from a Baseline}
\usage{
lc_capture_init(timeout = 5)

lc_capture_text(timeout = 5)

lc_capture_copy(timeout = 5)
}
\arguments{
\item{timeout}{Maximum seconds to wait for the Live Captions text element.}
}
\description{
Capture the text added after a stored Live Captions baseline without creating
bookmarks.
}
\details{
\code{lc_capture_init()} captures the complete caption currently exposed by
Windows Live Captions and stores it as the baseline for the current R session.
Calling it again replaces the previous baseline.

\code{lc_capture_text()} captures a fresh ending snapshot and returns the text
added after the stored baseline. \code{lc_capture_copy()} independently captures
a fresh ending snapshot, copies the resulting text to the Windows Unicode
clipboard, and returns it invisibly. Neither function replaces the baseline or
adds an item to the bookmark list.

If no baseline has been initialized, an empty dummy baseline is used, so the
complete caption text currently exposed by Live Captions is returned or copied.

The comparison is overlap-aware and accommodates the rolling Live Captions
window and recent wording corrections when the two snapshots still overlap. If
no overlap remains, the returned text can be incomplete because text that has
already left the Live Captions window cannot be reconstructed from two
snapshots; the function reports a warning.
}
\value{
\code{lc_capture_init()} invisibly returns a list containing \code{time} and
\code{caption}. \code{lc_capture_text()} returns one normalized character
string. \code{lc_capture_copy()} returns the copied string invisibly.
}
\examples{
\dontrun{
lc_app_start()
lc_capture_init()

# Allow more captions to appear.
text <- lc_capture_text()
lc_capture_copy()
}
}
