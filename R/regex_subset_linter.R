#' Require usage of direct methods for subsetting strings via regex
#'
#' Using `value = TRUE` in [grep()] returns the subset of the input that matches
#'   the pattern, e.g. `grep("[a-m]", letters, value = TRUE)` will return the
#'   first 13 elements (`a` through `m`).
#'
#' `letters[grep("[a-m]", letters)]` and `letters[grepl("[a-m]", letters)]`
#'   both return the same thing, but more circuitously and more verbosely.
#'
#' The `stringr` package also provides an even more readable alternative,
#'   namely `str_subset()`, which should be preferred to versions using
#'   `str_detect()` and `str_which()`.
#'
#' @section Exceptions:
#'   Note that `x[grep(pattern, x)]` and `grep(pattern, x, value = TRUE)`
#'   are not _completely_ interchangeable when `x` is not character
#'   (most commonly, when `x` is a factor), because the output of the
#'   latter will be a character vector while the former remains a factor.
#'   It still may be preferable to refactor such code, as it may be faster
#'   to match the pattern on `levels(x)` and use that to subset instead.
#'
#' @evalRd rd_tags("regex_subset_linter")
#'
#' @examples
#' # will produce lints
#' lint(
#'   text = "x[grep(pattern, x)]",
#'   linters = regex_subset_linter()
#' )
#'
#' lint(
#'   text = "x[stringr::str_which(x, pattern)]",
#'   linters = regex_subset_linter()
#' )
#'
#' # okay
#' lint(
#'   text = "grep(pattern, x, value = TRUE)",
#'   linters = regex_subset_linter()
#' )
#'
#' lint(
#'   text = "stringr::str_subset(x, pattern)",
#'   linters = regex_subset_linter()
#' )
#'
#' @seealso [linters] for a complete list of linters available in lintr.
#' @export
regex_subset_linter <- function() {
  # parent::expr for LEFT_ASSIGN and RIGHT_ASSIGN, but, strangely,
  #   parent::equal_assign for EQ_ASSIGN. So just use * as a catchall.
  # See https://www.w3.org/TR/1999/REC-xpath-19991116/#booleans;
  #   equality of nodes is based on the string value of the nodes, which
  #   is basically what we need, i.e., whatever expression comes in
  #   <expr>[grepl(pattern, <expr>)] matches exactly, e.g. names(x)[grepl(ptn, names(x))].
  xpath_fmt <- "
  //SYMBOL_FUNCTION_CALL[ {xp_text_in_table(calls)} ]
    /parent::expr
    /parent::expr[
      parent::expr[
        OP-LEFT-BRACKET
        and not(parent::*[LEFT_ASSIGN or EQ_ASSIGN or RIGHT_ASSIGN])
      ]
      and expr[position() = {arg_pos} ] = parent::expr/expr[1]
    ]
  "
  grep_xpath <- glue::glue(xpath_fmt, calls = c("grepl", "grep"), arg_pos = 3L)
  stringr_xpath <- glue::glue(xpath_fmt, calls = c("str_detect", "str_which"), arg_pos = 2L)

  Linter(function(source_expression) {
    if (!is_lint_level(source_expression, "expression")) {
      return(list())
    }

    xml <- source_expression$xml_parsed_content

    grep_expr <- xml2::xml_find_all(xml, grep_xpath)

    grep_lints <- xml_nodes_to_lints(
      grep_expr,
      source_expression = source_expression,
      lint_message =
        "Prefer grep(pattern, x, ..., value = TRUE) over x[grep(pattern, x, ...)] and x[grepl(pattern, x, ...)].",
      type = "warning"
    )

    stringr_expr <- xml2::xml_find_all(xml, stringr_xpath)

    stringr_lints <- xml_nodes_to_lints(
      stringr_expr,
      source_expression = source_expression,
      lint_message =
        "Prefer stringr::str_subset(x, pattern) over x[str_detect(x, pattern)] and x[str_which(x, pattern)].",
      type = "warning"
    )

    return(c(grep_lints, stringr_lints))
  })
}
