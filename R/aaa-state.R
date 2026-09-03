.livecaption_state <- new.env(parent = emptyenv())
.livecaption_state$bookmarks <- list()
.livecaption_state$next_bookmark_id <- 1L
.livecaption_state$capture_baseline <- NULL

.lc_is_windows <- function() {
  identical(.Platform$OS.type, "windows")
}

.lc_assert_windows <- function() {
  if (!.lc_is_windows()) {
    stop("livecaption requires Windows 11.", call. = FALSE)
  }
  invisible(TRUE)
}
