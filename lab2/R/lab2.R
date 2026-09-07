# lab2.R

library(Matrix)
source(file.path("R", "assignment_helpers.r"))

# ===========================================================================
#Lab Tasks
# ===========================================================================

# ---------------------------------------------------------------------------
# Task 3: nested loops, dense result
# ---------------------------------------------------------------------------
thresholded_distance_loop <- function(x, y, threshold = 0.5) {
  validate_pairwise_inputs(x, y)
  validate_threshold(threshold)

  m <- length(x)
  n <- length(y)

  result <- matrix(0, nrow = m, ncol = n)

  for (i in seq_len(m)) {
    xi <- x[i]
    for (j in seq_len(n)) {
      d <- abs(xi - y[j])          # each pair computed exactly once
      if (d < threshold) {
        result[i, j] <- 0          # strictly below the threshold
      } else {
        result[i, j] <- d          # at or above the threshold: preserved
      }
    }
  }

  result
}


# ---------------------------------------------------------------------------
# Task 4 
# ---------------------------------------------------------------------------
thresholded_distance_vectorized <- function(x, y, threshold = 0.5) {
  validate_pairwise_inputs(x, y)
  validate_threshold(threshold)

  d <- abs(outer(x, y, "-"))

  d[d < threshold] <- 0

  d
}


# ---------------------------------------------------------------------------
# Task 5
# ---------------------------------------------------------------------------
thresholded_distance_sparse <- function(x, y, threshold = 0.5) {
  if (!requireNamespace("Matrix", quietly = TRUE)) {
    stop("The 'Matrix' package is required for Task 5.", call. = FALSE)
  }

  d <- thresholded_distance_vectorized(x, y, threshold = threshold)

  # Coerce to a column-compressed sparse matrix.
  d_sparse <- as(as(as(d, "dMatrix"), "generalMatrix"), "CsparseMatrix")
  Matrix::drop0(d_sparse)
}


threshold <- 0.5
tol <- 1e-8


# ===========================================================================
# PART 1 -- CORRECTNESS CHECKS (small sample)
# ===========================================================================
x_test <- c(0, 1)
y_test <- c(0, 0.5, 2)

expected <- matrix(
  c(0, 0.5, 2,
    1, 0.5, 1),
  nrow = 2,
  byrow = TRUE
)

t3_test <- thresholded_distance_loop(x_test, y_test, threshold)
t4_test <- thresholded_distance_vectorized(x_test, y_test, threshold)
t5_test <- thresholded_distance_sparse(x_test, y_test, threshold)

stopifnot(
  "Task 3 does not match the expected small result" =
    isTRUE(all.equal(t3_test, expected, tolerance = tol)),
  "Task 4 does not match the expected small result" =
    isTRUE(all.equal(t4_test, expected, tolerance = tol)),
  "Task 5 does not match the expected small result" =
    isTRUE(all.equal(as.matrix(t5_test), expected,
                     tolerance = tol, check.attributes = FALSE)),

  # Task 3 and Task 4 must return a regular dense matrix.
  "Task 3 did not return a dense matrix" = is.matrix(t3_test),
  "Task 4 did not return a dense matrix" = is.matrix(t4_test),

  # Task 5 must return a sparse matrix object (dgCMatrix).
  "Task 5 did not return a dgCMatrix" = inherits(t5_test, "dgCMatrix"),

  # Distances of exactly 0.5 are preserved 
  "Exact-threshold distance lost in Task 3" =
    all(abs(t3_test[, 2] - 0.5) < tol),
  "Exact-threshold distance lost in Task 4" =
    all(abs(t4_test[, 2] - 0.5) < tol),
  "Exact-threshold distance lost in Task 5" =
    all(abs(as.matrix(t5_test)[, 2] - 0.5) < tol)
)

# The supplied validators reject malformed inputs.
stopifnot(
  "Non-numeric x was not rejected" =
    inherits(try(thresholded_distance_vectorized("a", 1), silent = TRUE),
             "try-error"),
  "Negative threshold was not rejected" =
    inherits(try(thresholded_distance_vectorized(1, 1, -1), silent = TRUE),
             "try-error")
)

cat("Small-example checks passed.\n")


# ===========================================================================
# PART 2 -- CORRECTNESS CHECKS (full assignment data)

# ===========================================================================
source(file.path("R", "gendata.r"))

# gendata.r writes the vectors to data-raw/lab2_vectors.rds as a two-element
# list. Read them back from that file (nothing in data-raw/ is edited by hand).
lab2_vectors <- readRDS(file.path("data-raw", "lab2_vectors.rds"))
x <- lab2_vectors$x
y <- lab2_vectors$y

stopifnot(
  "x must contain 3000 values" = length(x) == 3000,
  "y must contain 5000 values" = length(y) == 5000
)

d_loop   <- thresholded_distance_loop(x, y, threshold)
d_dense  <- thresholded_distance_vectorized(x, y, threshold)
d_sparse <- thresholded_distance_sparse(x, y, threshold)

stopifnot(
  # Dimensions and total number of pairwise distances.
  "Task 3 has the wrong dimensions" = all(dim(d_loop)   == c(3000, 5000)),
  "Task 4 has the wrong dimensions" = all(dim(d_dense)  == c(3000, 5000)),
  "Task 5 has the wrong dimensions" = all(dim(d_sparse) == c(3000, 5000)),
  "15,000,000 pairwise distances were not produced" = length(d_dense) == 15e6,

  # Tasks 3 and 4 agree entry by entry.
  "Task 3 and Task 4 disagree" =
    isTRUE(all.equal(d_loop, d_dense, tolerance = tol)),

  # Every dense entry, in BOTH dense results, is 0 or at least the threshold.
  "A Task 3 entry is neither 0 nor >= threshold" =
    all(d_loop  == 0 | d_loop  >= threshold - tol),
  "A Task 4 entry is neither 0 nor >= threshold" =
    all(d_dense == 0 | d_dense >= threshold - tol),

  # Nothing strictly between 0 and the threshold survived: the strict rule held.
  "A sub-threshold distance survived" =
    !any(d_dense > 0 & d_dense < threshold - tol),

  # Task 5 is sparse, matches Task 4's nonzero count, and stores no explicit
  # zeros (the number of stored values equals the number of nonzeros).
  "Task 5 did not return a dgCMatrix" = inherits(d_sparse, "dgCMatrix"),
  "Task 4 and Task 5 have different nonzero counts" =
    sum(d_dense != 0) == Matrix::nnzero(d_sparse),
  "Task 5 stores explicit zero entries" =
    length(d_sparse@x) == Matrix::nnzero(d_sparse),
  "Task 4 and Task 5 hold different values" =
    isTRUE(all.equal(as.matrix(d_sparse), d_dense,
                     tolerance = tol, check.attributes = FALSE))
)

cat("Large-result checks passed.\n")
cat("All correctness checks passed; beginning benchmark.\n\n")


# ---------------------------------------------------------------------------
# Stored-memory measurements, taken on the verified result objects
# ---------------------------------------------------------------------------
size_loop   <- as.numeric(object.size(d_loop))
size_dense  <- as.numeric(object.size(d_dense))
size_sparse <- as.numeric(object.size(d_sparse))

nnz_loop   <- sum(d_loop != 0)
nnz_dense  <- sum(d_dense != 0)
nnz_sparse <- Matrix::nnzero(d_sparse)

# Release the verified results so the timing runs start from a clean slate.
rm(d_loop, d_dense, d_sparse)
invisible(gc())


# ===========================================================================
# PART 3 -- BENCHMARK (once correctness checks have passed)
# ===========================================================================
time_loop       <- elapsed_seconds(thresholded_distance_loop,       x, y, threshold)
time_vectorized <- elapsed_seconds(thresholded_distance_vectorized, x, y, threshold)
time_sparse     <- elapsed_seconds(thresholded_distance_sparse,     x, y, threshold)


# ---------------------------------------------------------------------------
# Timing and memory comparison table
# ---------------------------------------------------------------------------
results <- data.frame(
  method = c("Task 3: nested loops (dense)",
             "Task 4: vectorized (dense)",
             "Task 5: vectorized (sparse)"),
  elapsed_seconds     = c(time_loop, time_vectorized, time_sparse),
  stored_result_bytes = c(size_loop, size_dense, size_sparse),
  nonzero_entries     = c(nnz_loop, nnz_dense, nnz_sparse),
  stringsAsFactors = FALSE
)

print(results, row.names = FALSE)
cat("\n")


# ---------------------------------------------------------------------------
# Required derived quantities
# ---------------------------------------------------------------------------
time_gain <- time_loop / time_vectorized

time_reduction_percent <- 100 * (1 - time_vectorized / time_loop)

memory_reduction_percent <- 100 * (1 - size_sparse / size_dense)

cat(sprintf("Task 3 -> Task 4 time gain:        %.2fx\n", time_gain))
cat(sprintf("Task 3 -> Task 4 time reduction:   %.2f%%\n", time_reduction_percent))
cat(sprintf("Task 4 -> Task 5 memory reduction: %.2f%%\n", memory_reduction_percent))

# Save the output
if (dir.exists("output")) {
  write.csv(results, file.path("output", "lab2_results.csv"), row.names = FALSE)
}
