\name{lc_app}
\alias{lc_app_start}
\alias{lc_app_stop}
\alias{lc_app_status}
\title{Manage Windows Live Captions}
\usage{
lc_app_start(wait = 12, poll_interval = 0.4)

lc_app_stop(wait = 8, poll_interval = 0.3)

lc_app_status()
}
\arguments{
\item{wait}{Maximum number of seconds to wait for the requested state.}
\item{poll_interval}{Seconds between state checks while waiting.}
}
\description{
Open, close, and inspect Windows Live Captions.
}
\details{
Starting uses the Windows + Ctrl + L shortcut. Stopping first tries the UI
Automation close operation and then sends a standard Windows close message to
the detected top-level window. Existing state is checked first, making repeated
calls idempotent. The package intentionally does not hide, show, move, or
minimize the Live Captions window; users can manage its position and visibility
through Windows.
}
\value{
\code{lc_app_status()} returns a named list of class \code{lc_app_status}.
It includes \code{caption_source} and \code{caption_automation_id} to describe
how the caption text control was detected.
The other functions return the resulting status invisibly.
}
\examples{
\dontrun{
lc_app_start()
lc_app_status()
lc_app_stop()
}
}
