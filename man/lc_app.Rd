\name{lc_app}
\alias{lc_app_start}
\alias{lc_app_stop}
\alias{lc_app_hide}
\alias{lc_app_show}
\alias{lc_app_status}
\title{Manage Windows Live Captions}
\usage{
lc_app_start(wait = 12, poll_interval = 0.4)

lc_app_stop(wait = 8, poll_interval = 0.3)

lc_app_hide(
  corner = c("bottom_right", "top_right", "bottom_left", "top_left"),
  visible_pixels = 32
)

lc_app_show()

lc_app_status()
}
\arguments{
\item{wait}{Maximum number of seconds to wait for the requested state.}
\item{poll_interval}{Seconds between state checks while waiting.}
\item{corner}{Desktop corner at which to park the Live Captions window.}
\item{visible_pixels}{Approximate number of pixels left visible at the selected
corner, allowing manual recovery with the mouse. Must be at least 8.}
}
\description{
Open, close, inspect, and experimentally move the Windows Live Captions window
to or from a desktop corner.
}
\details{
Starting uses the Windows + Ctrl + L shortcut. Stopping first tries the UI
Automation close operation and then sends a standard Windows close message to
the detected top-level window. Existing state is checked first, making repeated
calls idempotent.

Hiding stores the original coordinates and first tries to park nearly all the
window beyond the selected virtual-desktop corner while retaining a small
visible edge. If Windows rejects that position, it parks the complete window
inside the same corner. It checks the resulting position and caption
accessibility and reverses the move if both placements fail. This behaviour is
experimental because Windows may manage the position of Live Captions itself;
floating mode may be required.

If Live Captions is already visible, \code{lc_app_show()} leaves its current
position unchanged. This respects a position chosen manually by the user. It
restores the saved position only when the window is still hidden by the
package; centring is retained as recovery for a genuinely off-screen window
without saved coordinates.
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
lc_app_hide()
lc_app_show()
lc_app_stop()
}
}
