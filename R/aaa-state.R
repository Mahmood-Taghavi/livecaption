.livecaption_state <- new.env(parent = emptyenv())
.livecaption_state$bookmarks <- list()
.livecaption_state$next_bookmark_id <- 1L
.livecaption_state$app_original_rect <- NULL
.livecaption_state$hidden_handle <- NA_real_
.livecaption_state$hidden_rect <- NULL

.lc_is_windows <- function() {
  identical(.Platform$OS.type, "windows")
}

.lc_assert_windows <- function() {
  if (!.lc_is_windows()) {
    stop("livecaption requires Windows 11.", call. = FALSE)
  }
  invisible(TRUE)
}

.lc_reset_window_state <- function() {
  .livecaption_state$app_original_rect <- NULL
  .livecaption_state$hidden_handle <- NA_real_
  .livecaption_state$hidden_rect <- NULL
  invisible(NULL)
}

.onUnload <- function(libpath) {
  # Best-effort recovery if a user unloads the package after parking the Live
  # Captions window at a corner. Never allow unload cleanup to raise an error.
  if (
    .lc_is_windows() &&
      !is.null(.livecaption_state$app_original_rect) &&
      is.finite(.livecaption_state$hidden_handle)
  ) {
    rect <- .livecaption_state$app_original_rect
    try(
      .lc_move_window(
        handle = .livecaption_state$hidden_handle,
        x = rect$x,
        y = rect$y,
        activate = FALSE
      ),
      silent = TRUE
    )
  }
  invisible(NULL)
}
