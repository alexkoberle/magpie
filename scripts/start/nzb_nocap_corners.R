## nzb_nocap_corners.R ---------------------------------------------------------
## The 3 MISSING no-cap (R0) references, one per lever corner that lacks one.
## {MACC on, restore on} already exists (nzb_R0_ref). This adds:
##   nzb_R0_mON_rOFF  (MACC on,  restore off)
##   nzb_R0_mOFF_rON  (MACC off, restore on)
##   nzb_R0_mOFF_rOFF (MACC off, restore off)
## Each = non-binding cap (c56_emis_cap_scenario "none" -> p56_emis_cap 1e6), so
## the dashboard's "no cap" reference matches the toggled corner exactly instead
## of falling back to the {on,on} R0. Same input/calibration as the library.
## All 3 fit one wave (<=6 on 24 GB). Output: rds_report.
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

# ---- common config (== library, but NON-BINDING cap) -----------------------
cfg$gms$ghg_policy            <- "cap_apr26_reg"
cfg$gms$c56_cap_policy        <- "all"
cfg$gms$c56_emis_cap_scenario <- "none"        # p56_emis_cap = 1e6 -> never binds
cfg$gms$s56_emis_cap_parametric <- 0           # force OFF (input.gms has drift from prior runs)
cfg$gms$s56_source_bounds_on  <- 0
cfg$gms$c56_pollutant_prices  <- "none"
cfg$gms$s56_c_price_induced_aff <- 0
cfg$gms$c_timesteps <- "5year2050"
cfg$output     <- c("rds_report")
cfg$sequential <- FALSE

apply_macc <- function(cfg, on){
  v <- if(on) 106 else -1
  cfg$gms$s57_maxmac_n_soil <- v;     cfg$gms$s57_maxmac_n_awms   <- v
  cfg$gms$s57_maxmac_ch4_rice <- v;   cfg$gms$s57_maxmac_ch4_entferm <- v
  cfg$gms$s57_maxmac_ch4_awms <- v
  cfg$gms$s57_maxmac_fadein <- if(on) 1 else 0
  cfg$gms$s57_maxmac_fadein_start <- 2025; cfg$gms$s57_maxmac_fadein_end <- 2050
  cfg
}
apply_rest <- function(cfg, on){
  if(on){ cfg$gms$c22_protect_scenario <- "PBL_HalfEarth"; cfg$gms$s22_restore_land <- 1 }
  else  { cfg$gms$c22_protect_scenario <- "none";          cfg$gms$s22_restore_land <- 0 }
  cfg$gms$c22_protect_scenario_noselect <- "none"
  cfg$gms$policy_countries22 <- "BRA"
  cfg
}
launch <- function(cfg, macc, rest){
  cfg <- apply_macc(cfg, macc); cfg <- apply_rest(cfg, rest)
  cfg$title <- sprintf("nzb_R0_m%s_r%s", if(macc)"ON" else"OFF", if(rest)"ON" else"OFF")
  start_run(cfg, codeCheck = FALSE)
  cfg$title
}

corners <- list(c(TRUE, FALSE), c(FALSE, TRUE), c(FALSE, FALSE))   # the 3 missing
titles  <- sapply(corners, function(cc) launch(cfg, cc[1], cc[2]))
cat("== launched 3 no-cap corner runs ==\n"); print(unname(titles))
