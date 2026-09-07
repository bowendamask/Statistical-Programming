######################################################
#                                                    #
# Lab 2 assignment: Generate input vectors           #
#                                                    #
# R/gendata.r                                        #
#                                                    #
######################################################

set.seed(123)

n_x <- 3000L
n_y <- 5000L

lab2_vectors <- list(
  x = runif(n_x),
  y = runif(n_y)
)

saveRDS(
  lab2_vectors,
  file = file.path("data-raw", "lab2_vectors.rds")
)

cat(
  "Saved assignment vectors with lengths",
  length(lab2_vectors$x),
  "and",
  length(lab2_vectors$y),
  "to data-raw/lab2_vectors.rds.\n"
)
