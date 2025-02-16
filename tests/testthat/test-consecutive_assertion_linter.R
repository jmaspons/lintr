test_that("consecutive_assertion_linter skips allowed usages", {
  linter <- consecutive_assertion_linter()
  expect_lint("stopifnot(x)", NULL, linter)
  expect_lint("stopifnot(x, y, z)", NULL, linter)

  # intervening expression
  expect_lint("stopifnot(x); y; stopifnot(z)", NULL, linter)

  # inline or potentially with gaps don't matter
  expect_lint(
    trim_some("
      stopifnot(x)
      y
  
      stopifnot(z)
    "),
    NULL,
    linter
  )
})

test_that("consecutive_assertion_linter blocks simple disallowed usages", {
  linter <- consecutive_assertion_linter()
  lint_msg <- rex::rex("Unify consecutive calls to stopifnot().")

  # one test of inline usage
  expect_lint(
    "stopifnot(x); stopifnot(y)",
    lint_msg,
    linter
  )

  expect_lint(
    trim_some("
      stopifnot(x)
  
      stopifnot(y, z)
    "),
    lint_msg,
    linter
  )

  expect_lint(
    trim_some("
      stopifnot(x)
      stopifnot(y)
    "),
    lint_msg,
    linter
  )

  expect_lint(
    trim_some("
      stopifnot(x)
      # a comment on y
      stopifnot(y)
    "),
    lint_msg,
    linter
  )
})

test_that("assert_that usages are handled correctly too", {
  linter <- consecutive_assertion_linter()
  lint_msg <- rex::rex("Unify consecutive calls to assert_that().")

  expect_lint("assert_that(x)", NULL, linter)
  expect_lint("assertthat::assert_that(x, y, z)", NULL, linter)

  # if msg= is used, can't necessarily combine
  lines <- trim_some("
    assert_that(x, msg = 'bad x')
    assert_that(y, msg = 'bad y')
  ")
  expect_lint(lines, NULL, linter)

  # one test of inline usage
  expect_lint(
    "assert_that(x); assert_that(y)",
    lint_msg,
    linter
  )

  lines_gap <- trim_some("
    assert_that(x)

    assertthat::assert_that(y, z)
  ")
  expect_lint(lines_gap, lint_msg, linter)
})

test_that("Mixing test functions is fine", {
  expect_lint(
    trim_some("
      assert_that(x)
      stopifnot(y)
    "),
    NULL,
    consecutive_assertion_linter()
  )
})

test_that("old name consecutive_stopifnot_linter() is deprecated", {
  expect_warning(
    {
      old_linter <- consecutive_stopifnot_linter()
    },
    "Use consecutive_assertion_linter instead",
    fixed = TRUE
  )
  expect_lint("stopifnot(x); y; stopifnot(z)", NULL, old_linter)
  expect_lint("stopifnot(x); stopifnot(y)", "Unify consecutive calls", old_linter)
})
