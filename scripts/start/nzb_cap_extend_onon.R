## nzb_cap_extend_onon.R --------------------------------------------------------
## Extend the {MACC on, restore on} cap ladder so the dashboard slider can span
## reported BRA AFOLU 2050 from ~-200 to ~+200 Mt. 4 NEW runs via the parametric
## switch (s56_emis_cap_parametric=1); no cs3 columns, no GAMS changes.
##
##   capm200  600/400/200 -> -200   fixed ramp  (matches existing grid; monotone)
##   capm150  600/400/200 -> -150   fixed ramp
##   cap200   600/467/333 -> +200   SCALED monotone waypoints (loose cap)
##   cap300   600/500/400 -> +300   SCALED monotone waypoints
##
## Lower pair brackets reported -200; upper pair brackets reported +200 (reported
## ~ endpoint - ~50..77 offset; reported saturates at the no-cap ~277). Scaled
## waypoints = linear 600(2035) -> endpoint(2050) so the loose-cap path declines
## smoothly instead of dipping to 200 in 2045 then rebounding.
## All 4 fit one wave (<=6 on 24 GB). Output: rds_report. {on,on} levers only.
## ---------------------------------------------------------------------------
library(lucode2); library(gms); library(magpie4)
source("config/default.cfg"); source("scripts/start_functions.R")

cfg$input <- c(regional    = "rev4.131.9001BRA_H13_C200_W3_MapbiomasIBGE_5638d5dc_magpie.tgz",
               cellular    = "rev4.131.9001BRA_H13_C200_W3_MapbiomasIBGE_5638d5dc_d8411e75_cellularmagpie_c200_MRI-ESM2-0-ssp245_lpjml-8e6c5eb1_clusterweight-d0236589.tgz",
               validation  = "rev4.131.9001BRA_H13_C200_W3_MapbiomasIBGE_5638d5dc_92e02314_validation.tgz",
               additional  = "additional_data_rev4.65.tgz",
               calibration = "calibration_BRA_H13_C200_W3_MapbiomasIBGE_18Jun26.tgz")
cfg$repositories <- append(list("https://rse.pik-potsdam.de/data/magpie/public" = NULL),
                           getOption("magpie_repos"))
cfg$force_download <- FALSE; cfg$force_replace <- TRUE
cfg$recalibrate <- FALSE; cfg$recalibrate_landconversion_cost <- FALSE
cfg <- setScenario(cfg, "nocc")

# ---- common cap config (== library) ----------------------------------------
cfg$gms$ghg_policy           <- "cap_apr26_reg"
cfg$gms$c56_cap_policy       <- "all"
cfg$gms$s56_source_bounds_on <- 0
cfg$gms$c56_pollutant_prices <- "none"
cfg$gms$s56_c_price_induced_aff <- 0
cfg$gms$c_timesteps <- "5year2050"
cfg$output     <- c("rds_report")
cfg$sequential <- FALSE

# ---- {MACC on, restore on} levers (fixed across these 4 runs) --------------
v <- 106
cfg$gms$s57_maxmac_n_soil <- v;   cfg$gms$s57_maxmac_n_awms <- v
cfg$gms$s57_maxmac_ch4_rice <- v; cfg$gms$s57_maxmac_ch4_entferm <- v
cfg$gms$s57_maxmac_ch4_awms <- v
cfg$gms$s57_maxmac_fadein <- 1
cfg$gms$s57_maxmac_fadein_start <- 2025; cfg$gms$s57_maxmac_fadein_end <- 2050
cfg$gms$c22_protect_scenario <- "PBL_HalfEarth"; cfg$gms$s22_restore_land <- 1
cfg$gms$c22_protect_scenario_noselect <- "none"; cfg$gms$policy_countries22 <- "BRA"

# ---- parametric cap on; BRA-only via policy_countries56. The linear ramp from
#      start_value (600 @ start_year) to the 2050 endpoint reproduces the scaled
#      waypoints; only the endpoint differs per run.
cfg$gms$s56_emis_cap_parametric  <- 1
cfg$gms$s56_emis_cap_start_year  <- 2035
cfg$gms$s56_emis_cap_start_value <- 600
cfg$gms$s56_emis_cap_target_year <- 2050
cfg$gms$policy_countries56       <- "BRA"   # parametric cap applies to this region only

# capcol -> 2050 endpoint (Tg CO2eq/yr)
runs <- list(capm200 = -200, capm150 = -150, cap200 = 200, cap300 = 300)

launch <- function(cfg, capcol, target){
  cfg$gms$s56_emis_cap_target <- target
  cfg$title <- sprintf("nzb_lib_mON_rON_%s", capcol)
  start_run(cfg, codeCheck = FALSE)
  cfg$title
}
titles <- mapply(function(cc, t) launch(cfg, cc, t), names(runs), runs)
cat("== launched 4 extended {on,on} cap runs ==\n"); print(unname(titles))
