.lc_wait_for_app <- function(running, wait, poll_interval) {
  deadline <- Sys.time() + max(0, as.numeric(wait))
  repeat {
    status <- lc_app_status()
    if (!is.null(status$error) && nzchar(status$error)) return(status)
    if (identical(isTRUE(status$running), isTRUE(running))) return(status)
    if (Sys.time() >= deadline) return(status)
    Sys.sleep(max(0.1, as.numeric(poll_interval)))
  }
}

.lc_assert_status_probe <- function(status) {
  if (!is.null(status$error) && nzchar(status$error)) {
    stop(
      "Could not determine the Windows Live Captions state. ",
      status$error,
      call. = FALSE
    )
  }
  invisible(TRUE)
}

#' Manage Windows Live Captions
#'
#' These functions open, close, and inspect Windows Live Captions. Starting uses
#' Windows + Ctrl + L; stopping sends a close request directly to the detected
#' window. State is checked first, so repeated calls are idempotent.
#'
#' The package intentionally does not hide, show, move, or minimize the Live
#' Captions window. Users can manage its position and visibility through Windows.
#'
#' @param wait Maximum number of seconds to wait for the requested state.
#' @param poll_interval Seconds between state checks while waiting.
#'
#' @return `lc_app_status()` returns an object of class `lc_app_status`, including
#'   `caption_source` and `caption_automation_id` diagnostic fields. The other
#'   functions return the resulting status invisibly.
#' @name lc_app
NULL

#' @rdname lc_app
#' @export
lc_app_status <- function() {
  probe <- .lc_probe_window(include_caption = FALSE)
  supported <- .lc_is_windows()

  result <- list(
    supported = supported,
    running = isTRUE(probe$running),
    visible = isTRUE(probe$running) && !isTRUE(probe$is_offscreen),
    hidden = isTRUE(probe$running) && isTRUE(probe$is_offscreen),
    text_accessible = isTRUE(probe$text_accessible),
    caption_source = probe$caption_source,
    caption_automation_id = probe$caption_automation_id,
    title = probe$title,
    handle = probe$handle,
    rectangle = list(
      x = probe$x,
      y = probe$y,
      width = probe$width,
      height = probe$height
    ),
    checked_at = .lc_iso_time(),
    error = probe$error
  )
  class(result) <- c("lc_app_status", "list")
  result
}

#' @rdname lc_app
#' @export
lc_app_start <- function(wait = 12, poll_interval = 0.4) {
  .lc_assert_windows()
  before <- lc_app_status()
  .lc_assert_status_probe(before)
  if (isTRUE(before$running)) return(invisible(before))

  .lc_send_toggle_shortcut()
  status <- .lc_wait_for_app(TRUE, wait, poll_interval)
  .lc_assert_status_probe(status)

  if (!isTRUE(status$running)) {
    warning(
      "The shortcut was sent, but Windows Live Captions was not detected within ",
      wait, " seconds. First-time Windows setup may still be open.",
      call. = FALSE
    )
  }

  invisible(status)
}

#' @rdname lc_app
#' @export
lc_app_stop <- function(wait = 8, poll_interval = 0.3) {
  .lc_assert_windows()
  before <- lc_app_status()
  .lc_assert_status_probe(before)
  if (!isTRUE(before$running)) return(invisible(before))
  if (!is.finite(before$handle) || before$handle == 0) {
    stop("Could not obtain the Live Captions window handle.", call. = FALSE)
  }

  requested <- .lc_close_window(before$handle)
  if (!isTRUE(requested)) {
    warning(
      "Windows did not confirm that the close request was accepted.",
      call. = FALSE
    )
  }
  status <- .lc_wait_for_app(FALSE, wait, poll_interval)
  .lc_assert_status_probe(status)

  if (isTRUE(status$running)) {
    warning(
      "Windows Live Captions was still detected after ", wait, " seconds.",
      call. = FALSE
    )
  }

  invisible(status)
}

#' @export
print.lc_app_status <- function(x, ...) {
  app_state <- if (isTRUE(x$running)) "running" else "not detected"
  cat("Windows Live Captions: ", app_state, "\n", sep = "")
  if (isTRUE(x$running)) {
    state <- if (isTRUE(x$hidden)) "not visible" else "visible"
    cat("Window:                ", state, "\n", sep = "")
    cat("Caption accessible:    ", isTRUE(x$text_accessible), "\n", sep = "")
    if (!isTRUE(x$text_accessible) ||
        !identical(x$caption_source, "automation_id")) {
      cat("Caption selector:      ", x$caption_source, "\n", sep = "")
      if (!is.null(x$caption_automation_id) &&
          nzchar(x$caption_automation_id)) {
        cat("Caption control ID:    ", x$caption_automation_id, "\n", sep = "")
      }
    }
  }
  if (!is.null(x$error) && nzchar(x$error)) {
    cat("Error:                 ", x$error, "\n", sep = "")
  }
  invisible(x)
}
