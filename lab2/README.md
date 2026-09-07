# Lab 2 

Files and answers for Stat programming Lab 2 assignment

## Requirements

- R (developed and tested on 4.3.3)
- The [`Matrix`](https://cran.r-project.org/package=Matrix) package 

## Repository layout

```
.
├── R/
│   ├── gendata.r               # supplied with the assignment 
│   ├── assignment_helpers.r    # supplied with the assignment 
│   └── lab2.R                  # Tasks 3-5, correctness checks, benchmark
├── data-raw/        # raw data 
├── output/
│   ├── lab2_report.md   # write-up
│   └── lab2_results.csv # output comparison table
├── .gitignore
└── README.md
```

> `R/gendata.r` and `R/assignment_helpers.r` are supplied with the assignment.
> `gendata.r` writes the vectors to
> `data-raw/lab2_vectors.rds`; `R/lab2.R` sources it and then reads `x` and `y` back from
> that file. `assignment_helpers.r` supplies
> `validate_pairwise_inputs()` and `validate_threshold()`, which guard all three
> implementations, and `elapsed_seconds()`, which is used for every timing measurement.

## Running

With the repository root as the working directory:

```bash
Rscript R/lab2.R
```

or from an R session:

```r
source(file.path("R", "lab2.R"))
```

The script runs every correctness check first and stops on any failure, then benchmarks, prints the comparison table, and writes
`output/lab2_results.csv`.

## Functions

| Function | Task | Returns |
|---|---|---|
| `thresholded_distance_loop(x, y, threshold = 0.5)` | 3 | dense `matrix`, preallocated, two nested loops |
| `thresholded_distance_vectorized(x, y, threshold = 0.5)` | 4 | dense `matrix` via `outer()`, no loops |
| `thresholded_distance_sparse(x, y, threshold = 0.5)` | 5 | `dgCMatrix`, no explicit zeros |

All three return a 3000 × 5000 result on the assignment data: row *i* corresponds to
`x[i]`, column *j* to `y[j]`, 15,000,000 pairwise distances.

## Results

| method | elapsed seconds | stored result bytes | nonzero entries |
|---|---:|---:|---:|
| Task 3: nested loops (dense) | 1.976 | 120,000,216 | 3,703,301 |
| Task 4: vectorized (dense) | 0.156 | 120,000,216 | 3,703,301 |
| Task 5: vectorized (sparse) | 0.317 | 44,461,120 | 3,703,301 |

- Time gain (Task 3 → 4): **12.67×**
- Time reduction: **92.11%**
- Final-object memory reduction (Task 4 → 5): **62.95%**

Nonzero density is 3,703,301 / 15,000,000 ≈ 24.7%, close to the theoretical
P(|X − Y| ≥ 0.5) = 0.25 for independent Uniform(0, 1) draws.

The full write-up is in [`output/lab2_report.md`](output/lab2_report.md).

##Disclosure

Assignment used Claude Code for debugging, code efficiency, readability, and organization.
