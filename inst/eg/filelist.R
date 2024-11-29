library(furrr)
library(minioclient)

mc_alias_set("pawsey", "projects.pawsey.org.au", "", "")

mc_ls("pawsey/idea-objects")
# [1] "idea-objects.parquet"
#f <- mc_ls("pawsey/idea-sealevel-glo-phy-l4-nrt-008-046", recursive = T)


## or
buckets <- c("pawsey/idea-10.5067-mpyg15waa4wx",
             "pawsey/idea-10.7289-v5sq8xb5",
             "pawsey/vzarr",
             #"pawsey/idea-objects"
             "pawsey/idea-sealevel-glo-phy-l4-nrt-008-046",
             "pawsey/idea-sealevel-glo-phy-l4-rep-observations-008-047")

options(parallelly.fork.enable = TRUE, future.rng.onMisuse = "ignore")
library(furrr); plan(multicore)
system.time(f <- future_map(buckets, mc_ls, recursive = T))
plan(sequential)


