.lc_make_bookmark <- function(caption, label = NULL, time = Sys.time(), id = 1L) {
  iso_time <- .lc_iso_time(time)

  if (is.null(label) || !length(label) || is.na(label[[1L]]) || !nzchar(trimws(label[[1L]]))) {
    label <- iso_time
  } else {
    label <- as.character(label[[1L]])
  }

  result <- list(
    bookmark_id = as.integer(id),
    time = iso_time,
    label = label,
    caption = .lc_normalize_caption(caption)
  )
  class(result) <- c("lc_bookmark", "list")
  result
}

.lc_current_caption <- function(timeout = 5, poll_interval = 0.15) {
  .lc_assert_windows()
  deadline <- Sys.time() + max(0, as.numeric(timeout))

  repeat {
    probe <- .lc_probe_window(include_caption = TRUE)
    if (isTRUE(probe$running) && isTRUE(probe$text_accessible)) {
      return(.lc_normalize_caption(probe$caption))
    }

    if (Sys.time() >= deadline) break
    Sys.sleep(max(0.05, as.numeric(poll_interval)))
  }

  if (!is.null(probe$error) && nzchar(probe$error)) {
    stop("Could not read Windows Live Captions: ", probe$error, call. = FALSE)
  }
  if (!isTRUE(probe$running)) {
    stop("Windows Live Captions is not running. Call lc_app_start() first.", call. = FALSE)
  }
  stop(
    "The Live Captions text element is not accessible. Run ",
    "dput(lc_app_status()) to obtain diagnostic details.",
    call. = FALSE
  )
}

#' Create and manage caption bookmarks
#'
#' `lc_bookmark()` captures the complete text currently exposed by Windows Live
#' Captions and stores it in memory for the current R session. Its ISO 8601
#' timestamp is also used as the default label. `lc_bookmark_list()` returns all
#' bookmarks as a numbered list. `lc_bookmark_text()` brings the text added
#' between bookmarks into R for further processing, and `lc_bookmark_copy()`
#' copies that text to the Windows clipboard. `lc_bookmarks_clear()` removes
#' bookmarks and returns the removed list invisibly.
#'
#' @param label Optional bookmark label. A millisecond ISO 8601 timestamp with
#'   local UTC offset is used when `NULL` or empty.
#' @param timeout Maximum seconds to wait for the caption text element.
#' @param from Optional starting bookmark ID. Supply together with `to`.
#' @param to Optional ending bookmark ID. Supply together with `from`. The
#'   smaller supplied ID is always treated as `from`.
#' @param reset_ids Whether clearing also resets numbering to one.
#'
#' @return `lc_bookmark()` returns an object of class `lc_bookmark` whose last
#'   element is `caption`. `lc_bookmark_list()` returns an `lc_bookmark_list`.
#'   `lc_bookmark_text()` returns one normalized character string containing
#'   text added between the selected bookmarks. `lc_bookmark_copy()` returns
#'   the copied text invisibly.
#' @name lc_bookmark_list
NULL

#' @rdname lc_bookmark_list
#' @export
lc_bookmark <- function(label = NULL, timeout = 5) {
  caption <- .lc_current_caption(timeout = timeout)
  id <- .livecaption_state$next_bookmark_id
  bookmark <- .lc_make_bookmark(
    caption = caption,
    label = label,
    time = Sys.time(),
    id = id
  )

  .livecaption_state$bookmarks[[length(.livecaption_state$bookmarks) + 1L]] <- bookmark
  .livecaption_state$next_bookmark_id <- id + 1L
  bookmark
}

#' @rdname lc_bookmark_list
#' @export
lc_bookmark_list <- function() {
  result <- .livecaption_state$bookmarks
  if (length(result)) {
    names(result) <- sprintf(
      "bookmark_%04d",
      vapply(result, function(x) x$bookmark_id, integer(1))
    )
  }
  class(result) <- c("lc_bookmark_list", "list")
  result
}

#' @rdname lc_bookmark_list
#' @export
lc_bookmark_text <- function(from = NULL, to = NULL) {
  bookmarks <- .livecaption_state$bookmarks
  if (!length(bookmarks)) {
    stop("No bookmarks are available. Create one with lc_bookmark().", call. = FALSE)
  }

  ids <- vapply(bookmarks, function(item) item$bookmark_id, integer(1))

  if (is.null(from) && is.null(to)) {
    endpoints <- if (length(ids) == 1L) c(0L, ids[[1L]]) else range(ids)
  } else {
    if (is.null(from) || is.null(to)) {
      stop("Supply both from and to, or omit both.", call. = FALSE)
    }
    endpoints <- c(
      .lc_bookmark_id(from, "from"),
      .lc_bookmark_id(to, "to")
    )
    endpoints <- sort(endpoints)
  }

  from_id <- as.integer(endpoints[[1L]])
  to_id <- as.integer(endpoints[[2L]])
  available <- c(0L, ids)
  missing_ids <- setdiff(c(from_id, to_id), available)
  if (length(missing_ids)) {
    stop(
      "Unknown bookmark ID: ", paste(missing_ids, collapse = ", "),
      ". Available IDs are 0 and ", paste(ids, collapse = ", "), ".",
      call. = FALSE
    )
  }
  if (identical(from_id, to_id)) return("")

  order_index <- order(ids)
  bookmarks <- bookmarks[order_index]
  ids <- ids[order_index]
  baseline <- if (from_id == 0L) {
    ""
  } else {
    bookmarks[[match(from_id, ids)]]$caption
  }

  history <- .lc_normalize_caption(baseline)
  selected <- which(ids > from_id & ids <= to_id)
  unmatched <- integer()

  for (index in selected) {
    merged <- .lc_merge_caption_snapshot(history, bookmarks[[index]]$caption)
    history <- merged$text
    if (!isTRUE(merged$matched)) unmatched <- c(unmatched, ids[[index]])
  }

  if (length(unmatched)) {
    warning(
      "Caption overlap could not be confirmed at bookmark ID(s) ",
      paste(unmatched, collapse = ", "),
      "; their text was appended conservatively.",
      call. = FALSE
    )
  }

  .lc_caption_after_baseline(history, baseline)
}

#' @rdname lc_bookmark_list
#' @export
lc_bookmark_copy <- function(from = NULL, to = NULL) {
  .lc_assert_windows()
  text <- lc_bookmark_text(from = from, to = to)
  if (!nzchar(text)) {
    stop(
      "The selected bookmark range contains no new caption text; ",
      "the clipboard was not changed.",
      call. = FALSE
    )
  }

  success <- utils::writeClipboard(text, format = 13L)
  if (!isTRUE(success)) {
    stop("The caption text could not be copied to the Windows clipboard.", call. = FALSE)
  }

  message("Caption text copied to the Windows clipboard.")
  invisible(text)
}

#' @rdname lc_bookmark_list
#' @export
lc_bookmarks_clear <- function(reset_ids = TRUE) {
  removed <- lc_bookmark_list()
  .livecaption_state$bookmarks <- list()
  if (isTRUE(reset_ids)) .livecaption_state$next_bookmark_id <- 1L
  invisible(removed)
}

#' @export
print.lc_bookmark <- function(x, ...) {
  cat("<lc_bookmark ", x$bookmark_id, ">\n", sep = "")
  cat("  time:    ", x$time, "\n", sep = "")
  cat("  label:   ", x$label, "\n", sep = "")
  cat("  caption: ", nchar(x$caption), " character(s)\n", sep = "")
  invisible(x)
}

#' @export
print.lc_bookmark_list <- function(x, ...) {
  cat("<lc_bookmark_list> ", length(x), " bookmark(s)\n", sep = "")
  if (length(x)) {
    table <- data.frame(
      id = vapply(x, function(item) item$bookmark_id, integer(1)),
      time = vapply(x, function(item) item$time, character(1)),
      label = vapply(x, function(item) item$label, character(1)),
      characters = vapply(x, function(item) nchar(item$caption), integer(1)),
      stringsAsFactors = FALSE
    )
    print(table, row.names = FALSE)
  }
  invisible(x)
}

#' @export
as.data.frame.lc_bookmark <- function(x, row.names = NULL, optional = FALSE, ...) {
  data.frame(
    bookmark_id = x$bookmark_id,
    time = x$time,
    label = x$label,
    caption = x$caption,
    stringsAsFactors = FALSE
  )
}

#' @export
as.data.frame.lc_bookmark_list <- function(x, row.names = NULL, optional = FALSE, ...) {
  if (!length(x)) {
    return(data.frame(
      bookmark_id = integer(),
      time = character(),
      label = character(),
      caption = character(),
      stringsAsFactors = FALSE
    ))
  }

  result <- do.call(rbind, lapply(x, as.data.frame))
  rownames(result) <- NULL
  result
}
