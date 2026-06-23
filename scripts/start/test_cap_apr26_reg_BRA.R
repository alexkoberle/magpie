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

# which input data sets should be used?
# cfg$input <- c(regional    = "rev4.131.9001NZB_BRA_H13_C200_W3_SwpFunBRA_5638d5dc_magpie.tgz",
#                cellular    = "rev4.131.9001NZB_BRA_H13_C200_W3_SwpFunBRA_5638d5dc_d8411e75_cellularmagpie_c200_MRI-ESM2-0-ssp245_lpjml-8e6c5eb1_clusterweight-d0236589.tgz",
#                validation  = "rev4.131.9001NZB_BRA_H13_C200_W3_SwpFunBRA_5638d5dc_92e02314_validation.tgz",
#                additional  = "additional_data_rev4.65.tgz",
#                calibration = "calibration_H12_FAO_01Apr26.tgz")

cfg$input <- c(regional    = "rev4.131.9001BRA_H13_C200_W3_MapbiomasIBGE_5638d5dc_magpie.tgz",
               cellular    = "rev4.131.9001BRA_H13_C200_W3_MapbiomasIBGE_5638d5dc_d8411e75_cellularmagpie_c200_MRI-ESM2-0-ssp245_lpjml-8e6c5eb1_clusterweight-d0236589.tgz",
               validation  = "rev4.131.9001BRA_H13_C200_W3_MapbiomasIBGE_5638d5dc_92e02314_validation.tgz",
               additional  = "additional_data_rev4.65.tgz",
               calibration = "calibration_BRA_H13_C200_W3_MapbiomasIBGE_18Jun26.tgz")


cfg$repositories <- append(list("https://rse.pik-potsdam.de/data/magpie/public"=NULL),
                              #   "./patch_inputdata"=NULL),
                           getOption("magpie_repos"))

cfg$title <- "cap_apr26_reg_MapbiomasIBGE"
cfg$gms$ghg_policy            <- "cap_apr26_reg"
# cfg$gms$c56_emis_cap_scenario <- "none"
cfg$gms$c56_pollutant_prices  <- "none"
# cfg$gms$c56_cap_policy        <- "all_nosoil"
cfg$gms$s56_source_bounds_on  <- 0
# cfg$gms$c_timesteps           <- 1
# cfg$output                    <- c("rds_report")
# cfg$codeCheck                 <- TRUE
start_run(cfg, codeCheck = TRUE)

# ## ---- Run 2: full horizon, non-binding cap --------------------------------
# # cfg$title     <- "cap_apr26_reg_nonbinding_full"
# # cfg$gms$c_timesteps <- "5year2050"   # "coup2100"
# # cfg$codeCheck <- FALSE
# # start_run(cfg, codeCheck = FALSE)

# ## ---- Run 3: binding regional caps (uncomment when scenario data ready) ---
# cfg$title <- "cap_apr26_reg_BRA_2050net0"
# cfg$gms$c56_emis_cap_scenario <- "user_scen"
# cfg$gms$c_timesteps           <- "5year2050"
# start_run(cfg, codeCheck = FALSE)

## ---- Run 3: binding regional caps (uncomment when scenario data ready) ---
# cfg$title <- "cap_apr26_reg_BRA_2050net0"
# cfg$gms$c56_emis_cap_scenario <- "user_scen"
# cfg$gms$c_timesteps           <- "5year2050"
# start_run(cfg, codeCheck = FALSE)



## ---- Cap runs ---
# cfg$title <- "cap_apr26_reg_BRA_allCap"
# print("here")
# cfg$gms$ghg_policy            <- "cap_apr26_reg"
# cfg$gms$c56_emis_cap_scenario <- "user_scen"
# cfg$gms$c56_pollutant_prices  <- "none"
# cfg$gms$c56_cap_policy        <- "all"     # "all_nosoil"
# cfg$gms$s56_source_bounds_on  <- 0
# cfg$gms$c_timesteps           <- "5year2050"
# # cfg$output                    <- c("rds_report_NZB")
# cfg$codeCheck                 <- TRUE
# start_run(cfg, codeCheck = cfg$codeCheck)