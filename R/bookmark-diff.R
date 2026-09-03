.lc_caption_words <- function(text) {
  text <- .lc_normalize_caption(text)
  if (!nzchar(text)) return(character())
  unlist(strsplit(text, " ", fixed = TRUE), use.names = FALSE)
}

.lc_caption_word_keys <- function(words) {
  keys <- tolower(words)
  gsub("[^\\p{L}\\p{N}]+", "", keys, perl = TRUE)
}

.lc_word_overlap <- function(previous_words, current_words, max_words = 500L) {
  if (!length(previous_words) || !length(current_words)) return(0L)
  previous_keys <- .lc_caption_word_keys(previous_words)
  current_keys <- .lc_caption_word_keys(current_words)
  maximum <- min(length(previous_keys), length(current_keys), as.integer(max_words))

  for (size in rev(seq_len(maximum))) {
    if (identical(tail(previous_keys, size), head(current_keys, size))) {
      return(as.integer(size))
    }
  }
  0L
}

.lc_prefix_alignment <- function(reference_words, current_words) {
  reference_keys <- .lc_caption_word_keys(reference_words)
  current_keys <- .lc_caption_word_keys(current_words)
  compared <- min(length(reference_keys), length(current_keys))
  if (!compared) return(FALSE)

  comparison <- reference_keys[seq_len(compared)] == current_keys[seq_len(compared)]
  anchor_length <- min(2L, compared)
  if (!all(comparison[seq_len(anchor_length)])) return(FALSE)

  allowed <- if (compared < 5L) 0L else max(1L, ceiling(compared * 0.03))
  sum(!comparison) <= allowed
}

.lc_merge_caption_snapshot <- function(history, current) {
  history <- .lc_normalize_caption(history)
  current <- .lc_normalize_caption(current)

  finish <- function(text, matched, method) {
    list(text = .lc_normalize_caption(text), matched = matched, method = method)
  }

  if (!nzchar(current)) return(finish(history, TRUE, "empty_current"))
  if (!nzchar(history)) return(finish(current, TRUE, "empty_history"))
  if (identical(history, current)) return(finish(current, TRUE, "unchanged"))
  if (startsWith(current, history)) return(finish(current, TRUE, "character_extension"))
  if (startsWith(history, current)) return(finish(history, TRUE, "contraction"))

  history_words <- .lc_caption_words(history)
  current_words <- .lc_caption_words(current)

  if (.lc_prefix_alignment(history_words, current_words)) {
    if (length(current_words) >= length(history_words)) {
      return(finish(current, TRUE, "revised_word_extension"))
    }
    return(finish(history, TRUE, "revised_contraction"))
  }

  overlap <- .lc_word_overlap(history_words, current_words)
  if (overlap > 0L) {
    prefix_length <- length(history_words) - overlap
    prefix <- if (prefix_length > 0L) history_words[seq_len(prefix_length)] else character()
    return(finish(
      paste(c(prefix, current_words), collapse = " "),
      TRUE,
      paste0("rolling_overlap_", overlap)
    ))
  }

  if (grepl(current, history, fixed = TRUE)) {
    return(finish(history, TRUE, "embedded_contraction"))
  }

  finish(paste(history, current), FALSE, "unmatched_append")
}

.lc_caption_after_baseline <- function(history, baseline) {
  history <- .lc_normalize_caption(history)
  baseline <- .lc_normalize_caption(baseline)
  if (!nzchar(baseline)) return(history)

  if (startsWith(history, baseline)) {
    start <- nchar(baseline) + 1L
    if (start > nchar(history)) return("")
    return(.lc_normalize_caption(substr(history, start, nchar(history))))
  }

  history_words <- .lc_caption_words(history)
  baseline_words <- .lc_caption_words(baseline)
  if (length(history_words) <= length(baseline_words)) return("")

  .lc_normalize_caption(paste(
    history_words[(length(baseline_words) + 1L):length(history_words)],
    collapse = " "
  ))
}

.lc_bookmark_id <- function(x, argument) {
  value <- suppressWarnings(as.numeric(x))
  valid <- length(value) == 1L && is.finite(value) && value >= 0 && value == floor(value)
  if (!valid) {
    stop(argument, " must be one non-negative whole bookmark number.", call. = FALSE)
  }
  if (value > .Machine$integer.max) {
    stop(argument, " is too large to be a bookmark number.", call. = FALSE)
  }
  as.integer(value)
}
