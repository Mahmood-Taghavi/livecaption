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
#' These functions open, close, inspect, and move the Windows Live Captions
#' window to or from a desktop corner. Starting uses Windows + Ctrl + L; stopping
#' sends a close request directly to the detected window. State is checked first,
#' so repeated calls are idempotent.
#'
#' @param wait Maximum number of seconds to wait for the requested state.
#' @param poll_interval Seconds between state checks while waiting.
#' @param corner Desktop corner used by `lc_app_hide()`.
#' @param visible_pixels Approximate number of pixels of the parked window left
#'   visible at the selected corner, so it can still be recovered manually.
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

  hidden_by_package <- isTRUE(probe$running) &&
    is.finite(.livecaption_state$hidden_handle) &&
    identical(as.numeric(probe$handle), as.numeric(.livecaption_state$hidden_handle))

  hidden_rect <- .livecaption_state$hidden_rect
  if (
    hidden_by_package &&
      !is.null(hidden_rect) &&
      all(is.finite(c(probe$x, probe$y, hidden_rect$x, hidden_rect$y))) &&
      (abs(probe$x - hidden_rect$x) > 80 || abs(probe$y - hidden_rect$y) > 80)
  ) {
    .lc_reset_window_state()
    hidden_by_package <- FALSE
  }

  if (
    !isTRUE(probe$running) &&
      is.null(probe$error) &&
      (is.finite(.livecaption_state$hidden_handle) ||
        !is.null(.livecaption_state$app_original_rect))
  ) {
    .lc_reset_window_state()
    hidden_by_package <- FALSE
  }

  result <- list(
    supported = supported,
    running = isTRUE(probe$running),
    visible = isTRUE(probe$running) &&
      !hidden_by_package && !isTRUE(probe$is_offscreen),
    hidden = isTRUE(probe$running) &&
      (hidden_by_package || isTRUE(probe$is_offscreen)),
    hidden_by_package = hidden_by_package,
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
  if (!isTRUE(before$running)) {
    .lc_reset_window_state()
    return(invisible(before))
  }
  if (!is.finite(before$handle) || before$handle == 0) {
    stop("Could not obtain the Live Captions window handle.", call. = FALSE)
  }

  # Restore first so an unexpectedly failed close never strands the window at
  # its parked location.
  if (isTRUE(before$hidden_by_package)) {
    try(lc_app_show(), silent = TRUE)
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
  } else {
    .lc_reset_window_state()
  }

  invisible(status)
}

#' @rdname lc_app
#' @export
lc_app_hide <- function(
  corner = c("bottom_right", "top_right", "bottom_left", "top_left"),
  visible_pixels = 32
) {
  .lc_assert_windows()
  corner <- match.arg(corner)
  visible_pixels <- as.numeric(visible_pixels)
  if (length(visible_pixels) != 1L || !is.finite(visible_pixels) || visible_pixels < 8) {
    stop("visible_pixels must be one finite number of at least 8.", call. = FALSE)
  }
  before <- lc_app_status()
  .lc_assert_status_probe(before)

  if (!isTRUE(before$running)) {
    stop("Windows Live Captions is not running. Call lc_app_start() first.", call. = FALSE)
  }
  if (!isTRUE(before$text_accessible)) {
    stop(
      "The Live Captions text element is not accessible. Run ",
      "dput(lc_app_status()) to obtain diagnostic details.",
      call. = FALSE
    )
  }
  if (isTRUE(before$hidden_by_package)) return(invisible(before))
  if (!is.finite(before$handle) || before$handle == 0) {
    stop("Could not obtain the Live Captions window handle.", call. = FALSE)
  }

  rect <- before$rectangle
  if (!all(is.finite(unlist(rect)))) {
    stop("Could not determine the Live Captions window position.", call. = FALSE)
  }

  screen <- .lc_virtual_screen()
  screen_left <- as.numeric(screen$left)
  screen_top <- as.numeric(screen$top)
  screen_right <- screen_left + as.numeric(screen$width)
  screen_bottom <- screen_top + as.numeric(screen$height)
  edge_x <- min(visible_pixels, max(8, rect$width / 2))
  edge_y <- min(visible_pixels, max(8, rect$height / 2))

  target_x <- switch(
    corner,
    bottom_right = screen_right - edge_x,
    top_right = screen_right - edge_x,
    bottom_left = screen_left - rect$width + edge_x,
    top_left = screen_left - rect$width + edge_x
  )
  target_y <- switch(
    corner,
    bottom_right = screen_bottom - edge_y,
    bottom_left = screen_bottom - edge_y,
    top_right = screen_top - rect$height + edge_y,
    top_left = screen_top - rect$height + edge_y
  )

  margin <- 8
  inside_x <- switch(
    corner,
    bottom_right = screen_right - rect$width - margin,
    top_right = screen_right - rect$width - margin,
    bottom_left = screen_left + margin,
    top_left = screen_left + margin
  )
  inside_y <- switch(
    corner,
    bottom_right = screen_bottom - rect$height - margin,
    bottom_left = screen_bottom - rect$height - margin,
    top_right = screen_top + margin,
    top_left = screen_top + margin
  )

  candidates <- list(
    list(x = target_x, y = target_y),
    list(x = inside_x, y = inside_y)
  )
  probe_after <- NULL

  for (candidate in candidates) {
    moved <- tryCatch(
      .lc_move_window(before$handle, candidate$x, candidate$y, activate = FALSE),
      error = function(e) FALSE
    )
    if (!isTRUE(moved)) next

    Sys.sleep(0.25)
    probe <- .lc_probe_window(include_caption = FALSE)
    near_target <- isTRUE(probe$running) &&
      all(is.finite(c(probe$x, probe$y))) &&
      abs(probe$x - candidate$x) <= 80 &&
      abs(probe$y - candidate$y) <= 80

    if (near_target && isTRUE(probe$text_accessible)) {
      probe_after <- probe
      break
    }
  }

  if (is.null(probe_after)) {
    try(
      .lc_move_window(before$handle, rect$x, rect$y, activate = FALSE),
      silent = TRUE
    )
    .lc_reset_window_state()
    stop(
      "Windows did not park Live Captions at the requested corner while keeping its text accessible, so the original position was restored. Try changing Live Captions to floating mode first.",
      call. = FALSE
    )
  }

  .livecaption_state$app_original_rect <- rect
  .livecaption_state$hidden_handle <- as.numeric(probe_after$handle)
  .livecaption_state$hidden_rect <- list(x = probe_after$x, y = probe_after$y)
  after <- lc_app_status()

  invisible(after)
}

#' @rdname lc_app
#' @export
lc_app_show <- function() {
  .lc_assert_windows()
  before <- lc_app_status()
  .lc_assert_status_probe(before)

  if (!isTRUE(before$running)) {
    .lc_reset_window_state()
    return(invisible(before))
  }
  if (isTRUE(before$visible) && !isTRUE(before$hidden_by_package)) {
    message("Windows Live Captions is already visible; its position was not changed.")
    return(invisible(before))
  }
  if (!is.finite(before$handle) || before$handle == 0) {
    stop("Could not obtain the Live Captions window handle.", call. = FALSE)
  }

  original <- .livecaption_state$app_original_rect
  same_window <- is.finite(.livecaption_state$hidden_handle) &&
    identical(as.numeric(before$handle), as.numeric(.livecaption_state$hidden_handle))

  if (!is.null(original) && same_window && all(is.finite(unlist(original)))) {
    target_x <- original$x
    target_y <- original$y
  } else {
    screen <- .lc_virtual_screen()
    width <- if (is.finite(before$rectangle$width)) before$rectangle$width else 900
    height <- if (is.finite(before$rectangle$height)) before$rectangle$height else 300
    target_x <- as.numeric(screen$left) + (as.numeric(screen$width) - width) / 2
    target_y <- as.numeric(screen$top) + (as.numeric(screen$height) - height) / 2
  }

  moved <- .lc_move_window(before$handle, target_x, target_y, activate = TRUE)
  if (!isTRUE(moved)) {
    stop("Windows did not allow the Live Captions window to be restored.", call. = FALSE)
  }

  .lc_reset_window_state()
  Sys.sleep(0.25)
  invisible(lc_app_status())
}

#' @export
print.lc_app_status <- function(x, ...) {
  cat("Windows Live Captions: ", if (isTRUE(x$running)) "running" else "not detected", "\n", sep = "")
  if (isTRUE(x$running)) {
    state <- if (isTRUE(x$hidden)) "hidden" else "visible"
    cat("Window:                ", state, "\n", sep = "")
    cat("Caption accessible:    ", isTRUE(x$text_accessible), "\n", sep = "")
    if (!isTRUE(x$text_accessible) || !identical(x$caption_source, "automation_id")) {
      cat("Caption selector:      ", x$caption_source, "\n", sep = "")
      if (!is.null(x$caption_automation_id) && nzchar(x$caption_automation_id)) {
        cat("Caption control ID:    ", x$caption_automation_id, "\n", sep = "")
      }
    }
  }
  if (!is.null(x$error) && nzchar(x$error)) cat("Error:                 ", x$error, "\n", sep = "")
  invisible(x)
}
