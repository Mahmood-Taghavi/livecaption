\name{lc_bookmark_list}
\alias{lc_bookmark}
\alias{lc_bookmark_copy}
\alias{lc_bookmark_list}
\alias{lc_bookmark_text}
\alias{lc_bookmarks_clear}
\title{Create and Manage Caption Bookmarks}
\usage{
lc_bookmark(label = NULL, timeout = 5)

lc_bookmark_list()

lc_bookmark_text(from = NULL, to = NULL)

lc_bookmark_copy(from = NULL, to = NULL)

lc_bookmarks_clear(reset_ids = TRUE)
}
\arguments{
\item{label}{Optional label. The ISO 8601 timestamp is used when omitted.}
\item{timeout}{Maximum seconds to wait for the Live Captions text element.}
\item{from}{Optional starting bookmark ID. Supply together with \code{to}.}
\item{to}{Optional ending bookmark ID. Supply together with \code{from}. The
smaller supplied ID is always treated as the starting bookmark.}
\item{reset_ids}{Whether clearing also resets bookmark numbering to one.}
}
\description{
Extract caption text from Windows Live Captions into R and retain numbered
bookmarks in memory for the current R session. Retrieved character strings and
data frames can then be processed with ordinary R tools.
}
\details{
Each bookmark contains \code{bookmark_id}, \code{time}, \code{label}, and
\code{caption}, in that order. The timestamp includes milliseconds and the
local UTC offset. Captions are normalized to one line, so visual wrapping from
the Live Captions window is replaced with spaces. Use
\code{as.data.frame(lc_bookmark_list())} for a tabular result.

\code{lc_bookmark_text()} returns text added between two bookmark IDs. With no
arguments it compares the earliest and latest bookmarks. When only one bookmark
exists, an empty dummy bookmark 0 is used as the baseline. Explicit \code{from}
and \code{to} values must both be supplied; their order does not matter, and 0
can be used explicitly. Every stored snapshot in the selected range is merged
so later caption corrections replace earlier wording. Calling this function
does not create a bookmark.

\code{lc_bookmark_copy()} applies the same bookmark selection rules, copies the
extracted text to the Windows Unicode clipboard, and returns it invisibly. This
avoids printing long captions in the R console. Empty extracted text produces
an error and leaves the existing clipboard unchanged.
}
\value{
\code{lc_bookmark()} returns an \code{lc_bookmark}. \code{lc_bookmark_list()}
returns an \code{lc_bookmark_list}. \code{lc_bookmarks_clear()} invisibly
returns the removed bookmarks. \code{lc_bookmark_text()} returns one character
string. \code{lc_bookmark_copy()} returns the copied string invisibly.
}
\examples{
\dontrun{
lc_app_start()
lc_bookmark()
lc_bookmark("Important definition")
bookmarks <- lc_bookmark_list()
as.data.frame(bookmarks)
lc_bookmark_text()
lc_bookmark_text(2, 5)
lc_bookmark_copy(2, 5)
lc_bookmarks_clear()
}
}
