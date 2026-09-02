test_that("ISO times include milliseconds and a UTC offset", {
  value <- livecaption:::.lc_iso_time(
    as.POSIXct("2026-09-02 12:34:56.123", tz = "UTC")
  )
  expect_match(value, "^2026-09-02T12:34:56\\.[0-9]{3}[+-][0-9]{2}:[0-9]{2}$")
})

test_that("bookmark structure and default label are stable", {
  item <- livecaption:::.lc_make_bookmark(
    caption = "  A caption.  ",
    label = NULL,
    time = as.POSIXct("2026-09-02 12:34:56", tz = "UTC"),
    id = 3L
  )

  expect_s3_class(item, "lc_bookmark")
  expect_identical(names(item), c("bookmark_id", "time", "label", "caption"))
  expect_identical(item$bookmark_id, 3L)
  expect_identical(item$label, item$time)
  expect_identical(item$caption, "A caption.")
})

test_that("caption normalization removes visual line wrapping", {
  value <- livecaption:::.lc_normalize_caption("First line\r\n second\nthird")
  expect_identical(value, "First line second third")
})

test_that("custom labels are retained", {
  item <- livecaption:::.lc_make_bookmark(
    caption = "Text",
    label = "Important",
    id = 1L
  )
  expect_identical(item$label, "Important")
  expect_identical(tail(names(item), 1L), "caption")
})

test_that("bookmark lists convert to data frames", {
  one <- livecaption:::.lc_make_bookmark("First", id = 1L)
  two <- livecaption:::.lc_make_bookmark("Second", "Two", id = 2L)
  items <- structure(list(one, two), class = c("lc_bookmark_list", "list"))

  result <- as.data.frame(items)
  expect_identical(
    names(result),
    c("bookmark_id", "time", "label", "caption")
  )
  expect_equal(nrow(result), 2L)
  expect_identical(result$caption, c("First", "Second"))
})

test_that("lc_bookmark_list returns the numbered in-memory list", {
  state <- livecaption:::.livecaption_state
  old_bookmarks <- state$bookmarks
  on.exit(state$bookmarks <- old_bookmarks, add = TRUE)

  one <- livecaption:::.lc_make_bookmark("First", id = 1L)
  two <- livecaption:::.lc_make_bookmark("Second", id = 2L)
  state$bookmarks <- list(one, two)

  result <- lc_bookmark_list()
  expect_s3_class(result, "lc_bookmark_list")
  expect_identical(names(result), c("bookmark_0001", "bookmark_0002"))
})

test_that("one bookmark uses dummy bookmark zero", {
  state <- livecaption:::.livecaption_state
  old_bookmarks <- state$bookmarks
  on.exit(state$bookmarks <- old_bookmarks, add = TRUE)

  state$bookmarks <- list(livecaption:::.lc_make_bookmark("Complete text", id = 4L))
  expect_identical(lc_bookmark_text(), "Complete text")
  expect_identical(lc_bookmark_text(0, 4), "Complete text")
})

test_that("bookmark text requires at least one bookmark", {
  state <- livecaption:::.livecaption_state
  old_bookmarks <- state$bookmarks
  on.exit(state$bookmarks <- old_bookmarks, add = TRUE)

  state$bookmarks <- list()
  expect_error(lc_bookmark_text(), "No bookmarks are available")
})

test_that("bookmark text keeps latest revisions and rolling additions", {
  state <- livecaption:::.livecaption_state
  old_bookmarks <- state$bookmarks
  on.exit(state$bookmarks <- old_bookmarks, add = TRUE)

  state$bookmarks <- list(
    livecaption:::.lc_make_bookmark("alpha beta", id = 1L),
    livecaption:::.lc_make_bookmark("alpha beta gamma old epsilon", id = 2L),
    livecaption:::.lc_make_bookmark("alpha beta gamma revised epsilon zeta", id = 3L),
    livecaption:::.lc_make_bookmark("epsilon zeta eta theta", id = 4L)
  )

  expected <- "gamma revised epsilon zeta eta theta"
  expect_identical(lc_bookmark_text(), expected)
  expect_identical(lc_bookmark_text(4, 1), expected)
})

test_that("bookmark text validates endpoints and has no side effects", {
  state <- livecaption:::.livecaption_state
  old_bookmarks <- state$bookmarks
  on.exit(state$bookmarks <- old_bookmarks, add = TRUE)

  state$bookmarks <- list(
    livecaption:::.lc_make_bookmark("one", id = 2L),
    livecaption:::.lc_make_bookmark("one two", id = 5L)
  )
  before <- state$bookmarks

  expect_identical(lc_bookmark_text(2, 2), "")
  expect_error(lc_bookmark_text(from = 2), "Supply both")
  expect_error(lc_bookmark_text(2, 3), "Unknown bookmark ID")
  expect_identical(state$bookmarks, before)
})

test_that("status is safe on non-Windows systems", {
  skip_on_os("windows")
  status <- lc_app_status()
  expect_s3_class(status, "lc_app_status")
  expect_false(status$supported)
  expect_false(status$running)
  expect_identical(status$caption_source, "none")
  expect_identical(status$caption_automation_id, "")
})

test_that("caption probe contains the tolerant text-control fallback", {
  script <- livecaption:::.lc_window_script(include_caption = TRUE)
  expect_match(script, "CaptionTextBlock", fixed = TRUE)
  expect_match(script, "longest_text", fixed = TRUE)
  expect_match(script, "LiveCaptions?", fixed = TRUE)
})

test_that("clipboard helper fails safely outside Windows", {
  skip_on_os("windows")
  expect_error(lc_bookmark_copy(), "requires Windows 11")
})

test_that("application lifecycle uses only start and stop names", {
  namespace <- asNamespace("livecaption")
  expect_true(exists("lc_app_start", namespace, inherits = FALSE))
  expect_true(exists("lc_app_stop", namespace, inherits = FALSE))
  expect_false(exists("lc_app_run", namespace, inherits = FALSE))
  expect_false(exists("lc_app_close", namespace, inherits = FALSE))
})
