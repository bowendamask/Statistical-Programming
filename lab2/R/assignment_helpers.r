######################################################
#                                                    #
# Lab 2 assignment: Shared helper functions          #
#                                                    #
# R/assignment_helpers.r                             #
#                                                    #
######################################################

validate_pairwise_inputs <- function(x, y) {
  valid_x <-
    is.numeric(x) &&
    is.atomic(x) &&
    is.null(dim(x)) &&
    length(x) > 0L &&
    all(is.finite(x))

  valid_y <-
    is.numeric(y) &&
    is.atomic(y) &&
    is.null(dim(y)) &&
    length(y) > 0L &&
    all(is.finite(y))

  if (!valid_x) {
    stop("`x` must be a non-empty numeric vector of finite values.", call. = FALSE)
  }

  if (!valid_y) {
    stop("`y` must be a non-empty numeric vector of finite values.", call. = FALSE)
  }

  invisible(TRUE)
}

validate_threshold <- function(threshold) {
  valid_threshold <-
    length(threshold) == 1L &&
    is.numeric(threshold) &&
    !is.na(threshold) &&
    is.finite(threshold) &&
    threshold >= 0

  if (!valid_threshold) {
    stop("`threshold` must be one non-negative finite number.", call. = FALSE)
  }

  invisible(TRUE)
}

elapsed_seconds <- function(fun, ...) {
  timing <- system.time(fun(...))
  unname(timing[["elapsed"]])
}
