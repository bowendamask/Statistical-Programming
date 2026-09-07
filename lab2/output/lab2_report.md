# Lab 2

## Timing and memory comparison

| method | elapsed seconds | stored result bytes | nonzero entries |
|---|---:|---:|---:|
| Task 3: nested loops (dense) | 1.976 | 120,000,216 | 3,703,301 |
| Task 4: vectorized (dense) | 0.156 | 120,000,216 | 3,703,301 |
| Task 5: vectorized (sparse) | 0.317 | 44,461,120 | 3,703,301 |

Derived quantities:

- `time_gain <- time_loop / time_vectorized` = 1.976 / 0.156 = **12.67×**
- `time_reduction_percent <- 100 * (1 - time_vectorized / time_loop)` = **92.11%**
- `memory_reduction_percent` = 100 × (1 − 44,461,120 / 120,000,216) = **62.95%**

Task 5 takes slightly longer than Task 4 as Task 5 performs the entire
Task 4 calculation and then converts the dense result to sparse form. 

## Written responses

**1. If m = length(x) and n = length(y), how many pairwise distances must be calculated?**
m × n, since all of x is paired all of y, which in this case is 3,000 × 5,000 = 15,000,000.

**2. What is the time complexity of Tasks 3 and 4?**
Both are Θ(mn), and are quadratic in the input size when m and n grow together. Doubling both input lengths multiplies the work by four.

**3. Does vectorization change the asymptotic complexity, or does it reduce implementation costs and constant factors?**
No. Its still Θ(mn), the only thing vectorization changes in this case is just the constant. So its still quadratic growth its just cheaper to run.

**4. What speedup and percentage time reduction did you observe from Task 3 to Task 4? Was the refactoring useful?**
In this case vectorizing made it 12.67× faster, which is a 92.11% reduction in elapsed time (1.976 s → 0.156 s). And so yes the refactoring was useful as it made the function shorter and faster.

**5. Let k be the number of nonzero entries after thresholding. Compare the storage complexity of the dense and sparse results.**
The dense matrix stores every entry regardless of value/number of zero or non-zero entries.  The `dgCMatrix` stores only the nonzeros plus the index structure: k values, k row indices, and n+1 column pointers, so Θ(k + n) space. In this case, a sparse matrix would be better when k ≪ mn. The dense matrix stores every entry regardless of value, so it needs Θ(mn) space

**6. What percentage of final-object memory did Task 5 save relative to Task 4?**
For me atleast the percentage of final-object memory Task 5 saved relative to Task 4 was 62.95%, moving from 120,000,216 bytes to 44,461,120 bytes.

**7. Why can Task 5 produce a smaller final object while still using substantial peak memory during conversion from dense to sparse form?**
Task 5 reuses the Task 4 result and builds the sparse object from the complete 120 MB dense matrix. There is a point where both are active, so memory usage spikes and then drops once R clears the dense copy. In this case, object.size() reports the final object at the end of the process, not the maximum size reached when we build it. 
