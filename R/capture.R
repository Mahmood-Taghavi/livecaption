.lc_make_capture_baseline <- function(caption, time = Sys.time()) {
  result <- list(
    time = .lc_iso_time(time),
    caption = .lc_normalize_caption(caption)
  )
  class(result) <- c("lc_capture_baseline", "list")
  result
}

.lc_capture_baseline_caption <- function() {
  baseline <- .livecaption_state$capture_baseline
  if (is.null(baseline) || is.null(baseline$caption)) return("")
  .lc_normalize_caption(baseline$caption)
}

.lc_capture_diff <- function(current) {
  current <- .lc_normalize_caption(current)
  baseline <- .lc_capture_baseline_caption()
  merged <- .lc_merge_caption_snapshot(baseline, current)

  if (nzchar(baseline) && !isTRUE(merged$matched)) {
    warning(
      paste0(
        "Caption overlap with the capture baseline could not be confirmed; ",
        "the returned text may be incomplete because older Live Captions text ",
        "can leave the visible window."
      ),
      call. = FALSE
    )
  }

  .lc_caption_after_baseline(merged$text, baseline)
}

#' Capture Windows Live Captions text from a baseline
#'
#' `lc_capture_init()` captures and stores the current Live Captions text as a
#' baseline. `lc_capture_text()` captures a fresh ending snapshot and returns
#' the text added after that baseline. `lc_capture_copy()` captures a fresh
#' ending snapshot, copies the resulting text to the Windows clipboard, and
#' returns it invisibly.
#'
#' If `lc_capture_init()` has not been called, the two retrieval functions use
#' an empty dummy baseline and therefore return or copy the complete caption
#' text currently exposed by Live Captions. Retrieving or copying text does not
#' replace the stored baseline and does not add anything to the bookmark list.
#'
#' @param timeout Maximum seconds to wait for the Live Captions text element.
#'
#' @return `lc_capture_init()` invisibly returns a list containing the baseline
#'   `time` and `caption`. `lc_capture_text()` returns one normalized character
#'   string. `lc_capture_copy()` returns the copied string invisibly.
#' @name lc_capture
NULL

#' @rdname lc_capture
#' @export
lc_capture_init <- function(timeout = 5) {
  baseline <- .lc_make_capture_baseline(
    caption = .lc_current_caption(timeout = timeout),
    time = Sys.time()
  )
  .livecaption_state$capture_baseline <- baseline
  message("Capture baseline initialized.")
  invisible(baseline)
}

#' @rdname lc_capture
#' @export
lc_capture_text <- function(timeout = 5) {
  current <- .lc_current_caption(timeout = timeout)
  .lc_capture_diff(current)
}

#' @rdname lc_capture
#' @export
lc_capture_copy <- function(timeout = 5) {
  .lc_assert_windows()
  text <- lc_capture_text(timeout = timeout)
  if (!nzchar(text)) {
    stop(
      "No caption text was added after the capture baseline; ",
      "the clipboard was not changed.",
      call. = FALSE
    )
  }

  success <- utils::writeClipboard(text, format = 13L)
  if (!isTRUE(success)) {
    stop("The caption text could not be copied to the Windows clipboard.", call. = FALSE)
  }

  message("Captured caption text copied to the Windows clipboard.")
  invisible(text)
}
