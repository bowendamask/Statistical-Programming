# Lab 2 — Thresholded Pairwise Distances

`x`: 3,000 values ~ U(0,1) · `y`: 5,000 values ~ U(0,1) · seed 123 · `threshold <- 0.5`
Result: 3,000 × 5,000 = 15,000,000 pairwise distances. Row *i* ↔ `x[i]`, column *j* ↔ `y[j]`.

## Correctness checks

All checks in `R/lab2.R` pass, and all of them complete before any benchmarking
begins. Comparisons use `all.equal(..., tolerance = 1e-8)`; the script halts on any
failure via `stopifnot()`.

Small example (`x_test <- c(0, 1)`, `y_test <- c(0, 0.5, 2)`):

| Check | Result |
|---|---|
| Task 3 result equals `expected` | pass |
| Task 4 result equals `expected` | pass |
| `as.matrix()` of Task 5 equals `expected` | pass |
| Tasks 3 and 4 return regular dense matrices | pass |
| Task 5 returns a `dgCMatrix` | pass |
| Distances exactly equal to 0.5 preserved in all three (column 2) | pass |

Full assignment data (3,000 x 5,000):

| Check | Result |
|---|---|
| All three results have dimensions 3000 x 5000 | pass |
| Dense result holds 15,000,000 pairwise distances | pass |
| Task 3 equals Task 4 entry by entry | pass |
| Every Task 3 entry is 0 or at least 0.5 | pass |
| Every Task 4 entry is 0 or at least 0.5 | pass |
| No distance strictly between 0 and 0.5 survived (strict rule held) | pass |
| Task 5 has the same nonzero count as Task 4 (3,703,301 both) | pass |
| Task 5 stores no explicit zeros (`length(@x) == nnzero()`) | pass |
| Task 5 holds the same values as Task 4 | pass |
| Supplied validators reject non-numeric `x` and a negative `threshold` | pass |

## Timing and memory comparison

macOS (MacBook Pro), single run, same vectors / threshold / machine / timing procedure
for all three implementations. Elapsed time is measured with the supplied
`elapsed_seconds()` helper, which wraps `system.time()`; because that helper discards the
function's return value, the `object.size()` and `Matrix::nnzero()` figures are taken from
the verified result objects produced during the correctness pass.

| method | elapsed seconds | stored result bytes | nonzero entries |
|---|---:|---:|---:|
| Task 3: nested loops (dense) | 1.976 | 120,000,216 | 3,703,301 |
| Task 4: vectorized (dense) | 0.156 | 120,000,216 | 3,703,301 |
| Task 5: vectorized (sparse) | 0.317 | 44,461,120 | 3,703,301 |

Derived quantities:

- `time_gain <- time_loop / time_vectorized` = 1.976 / 0.156 = **12.67×**
- `time_reduction_percent <- 100 * (1 - time_vectorized / time_loop)` = **92.11%**
- `memory_reduction_percent` = 100 × (1 − 44,461,120 / 120,000,216) = **62.95%**

Exact timings vary across computers, and also from run to run on the same computer:
repeated runs of this script gave Task 3-to-Task 4 gains between roughly 5x and 14x, with
most runs near 13x, because a single `system.time()` measurement of a job dominated by
120 MB allocations is sensitive to the state of R's heap and garbage collector. The loop's
elapsed time was stable near 2 s throughout; the variation came almost entirely from the
vectorized run, whose absolute time is small enough that allocation overhead dominates it. The memory
figures and the nonzero count do not vary, since the seed and dimensions are fixed.

Task 5 takes slightly longer than Task 4, which is expected: Task 5 performs the entire
Task 4 calculation and then converts the dense result to sparse form. Its advantage is in
storage, not speed. Nonzero density is 3,703,301 / 15,000,000 ≈ 24.7%, close to the
theoretical P(|X − Y| ≥ 0.5) = 0.25 for independent U(0,1) draws.

## Written responses

**1. How many pairwise distances?**
Every element of `x` is paired with every element of `y`, so `m * n` distances —
here 3,000 × 5,000 = 15,000,000.

**2. Time complexity of Tasks 3 and 4.**
Both are Θ(mn), i.e. O(mn) — quadratic in the input size when m and n grow together.
Each of the mn pairs is visited exactly once and given constant work (one subtraction,
one `abs`, one comparison, one store).

**3. Does vectorization change the asymptotic complexity?**
No. Task 4 still performs mn distance calculations; it is Θ(mn) just like Task 3.
Vectorization reduces the constant factor and the per-element interpreter overhead: the
loop version pays for 15 million R-level iterations, index lookups, and `if` dispatches,
while `outer()` and the vectorized comparison push the same arithmetic down into compiled
C code operating over contiguous memory. The curve has the same shape; it is just lower.

**4. Observed speedup and time reduction — was the refactoring useful?**
12.67× faster, a 92.11% reduction in elapsed time (1.976 s → 0.156 s). Yes, clearly
useful: the refactoring removed more than nine tenths of the runtime while also making
the function three lines shorter and easier to verify. The saving comes entirely from
eliminating per-element interpreter overhead — 15 million iterations of index lookup,
`if` dispatch and scalar assignment — not from performing less arithmetic; both versions
compute exactly 15,000,000 distances. What remains in the vectorized version is close to
the unavoidable cost of allocating and writing a 120 MB result. That measured ratio
should be read as approximate: across repeated runs it ranged from about 5× to 14×, since
the vectorized time is small enough that memory-allocation and garbage-collection effects
move it substantially, while the loop time stayed near 2 s. The direction and rough order
of the improvement are robust even though the precise multiple is not.

**5. Storage complexity, dense vs sparse, with k nonzeros.**
The dense matrix stores every entry regardless of value: Θ(mn) — 15,000,000 doubles,
about 120 MB, whether or not most are zero. The `dgCMatrix` stores only the nonzeros plus
the index structure: k values, k row indices, and n+1 column pointers, so Θ(k + n) space.
Sparse storage wins when k ≪ mn. The crossover for a dgCMatrix (8-byte double + 4-byte
integer per nonzero vs 8 bytes per dense entry) is roughly k / (mn) < 2/3; here the
density is 24.7%, comfortably below it.

**6. Memory saved by Task 5 relative to Task 4.**
62.95% (120,000,216 bytes → 44,461,120 bytes), a reduction of about 75.5 MB.

**7. Smaller final object, but substantial peak memory — why?**
Task 5 reuses the Task 4 result, so it first materializes the complete 120 MB dense
matrix (and the vectorized calculation itself allocates further 15-million-element
temporaries — the `outer()` difference matrix and the logical mask from `d < threshold`).
The sparse object is then built *from* that dense matrix, so for a moment both the dense
input and the growing sparse output are alive simultaneously; peak RSS exceeds either one.
Only after the dense copy goes out of scope and R's garbage collector reclaims it does
memory use fall to the ~44 MB of the sparse object. `object.size()` measures the surviving
result, not the high-water mark. Avoiding that peak would require building the sparse
matrix directly from indices — for example computing the qualifying (i, j, value) triplets
in blocks and feeding them to `Matrix::sparseMatrix()` — so the dense form is never
created. The assignment explicitly asks Task 5 to reuse Task 4, so the peak is expected.
