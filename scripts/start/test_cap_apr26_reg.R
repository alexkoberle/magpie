## test_cap_apr26_reg.R -------------------------------------------------------
## Test runs for the cap_apr26_reg realization (per-region AFOLU caps, H13).
##
## Run 1: single timestep + codeCheck — verifies compilation only (fast).
## Run 2: full coup2100 horizon, non-binding cap — baseline / runtime check.
## Run 3: binding regional caps — requires scenario data in f56_emis_cap.cs3
##         and the scenario name registered in capscen56 (sets.gms). Uncomment
##         when ready.
## -------------------------------------------------------------------------

library(magpie4)
source("config/default.cfg")
source("scripts/start_functions.R")

cfg$title <- "cap_apr26_reg_1step"
cfg$gms$ghg_policy            <- "cap_apr26_reg"
cfg$gms$c56_emis_cap_scenario <- "none"
cfg$gms$c56_pollutant_prices  <- "none"
cfg$gms$c56_cap_policy        <- "all_nosoil"
cfg$gms$s56_source_bounds_on  <- 0
cfg$gms$c_timesteps           <- 1
cfg$output                    <- c("rds_report")
cfg$codeCheck                 <- TRUE
start_run(cfg, codeCheck = cfg$codeCheck)

## ---- Run 2: full horizon, non-binding cap --------------------------------
cfg$title     <- "cap_apr26_reg_nonbinding_full"
cfg$gms$c_timesteps <- "coup2100"
cfg$codeCheck <- FALSE
start_run(cfg, codeCheck = FALSE)

## ---- Run 3: binding regional caps (uncomment when scenario data ready) ---
# cfg$title <- "cap_apr26_reg_binding_1step"
# cfg$gms$c56_emis_cap_scenario <- "your_scenario_name"
# cfg$gms$c_timesteps           <- 1
# start_run(cfg, codeCheck = FALSE)
