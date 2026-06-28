## nzb_baseline_variants.R ------------------------------------------------------
## Baseline (no-cap) sensitivities to complete the reference picture. All share
## the {off,off}-style baseline (no cap, restore off, WDPA base only, nocc, no GHG
## prices); they differ only in forest-policy stringency and MACC ceiling.
##
##   1. nzb_R0_offoff_polnone  forest policy = none (no NPI)     MACC off
##   2. nzb_R0_offoff_ndc      forest policy = ndc               MACC off
##   3. nzb_R0_npi_fullmacc    forest = npi + FULL MACC (201)    MACC full
##
## Forest policy = c32_aff_policy (afforestation) + c35_ad_policy (avoided defor)
##                 + c35_aolc_policy (avoided other-land conversion).
## "Full MACC potential" = s57_maxmac_* = 201 (max curve step ~1222 USD/tCO2eq)
##   vs the library's 106 (~641 USD, the 1.5C price). fadein=1 kept (same phase-in).
## The NPI {off,off} no-cap baseline already exists (nzb_R0_mOFF_rOFF).
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

# ---- common baseline config (no cap, restore off, no prices) ---------------
cfg$gms$ghg_policy            <- "cap_apr26_reg"
cfg$gms$c56_cap_policy        <- "all"
cfg$gms$c56_emis_cap_scenario <- "none"        # non-binding (no cap)
cfg$gms$s56_emis_cap_parametric <- 0           # force OFF (input.gms drift guard)
cfg$gms$s56_source_bounds_on  <- 0
cfg$gms$c56_pollutant_prices  <- "none"
cfg$gms$s56_c_price_induced_aff <- 0
# restore off (baseline): WDPA base protection only
cfg$gms$c22_protect_scenario  <- "none"; cfg$gms$s22_restore_land <- 0
cfg$gms$c22_protect_scenario_noselect <- "none"; cfg$gms$policy_countries22 <- "BRA"
cfg$gms$c_timesteps <- "5year2050"
cfg$output     <- c("rds_report")
cfg$sequential <- FALSE

set_macc <- function(cfg, step){     # step (e.g. 106, 201) or -1 = off
  cfg$gms$s57_maxmac_n_soil <- step;   cfg$gms$s57_maxmac_n_awms <- step
  cfg$gms$s57_maxmac_ch4_rice <- step; cfg$gms$s57_maxmac_ch4_entferm <- step
  cfg$gms$s57_maxmac_ch4_awms <- step
  cfg$gms$s57_maxmac_fadein <- if (step > 0) 1 else 0
  cfg$gms$s57_maxmac_fadein_start <- 2025; cfg$gms$s57_maxmac_fadein_end <- 2050
  cfg
}
set_forest <- function(cfg, pol){    # "none" | "npi" | "ndc"
  cfg$gms$c32_aff_policy  <- pol
  cfg$gms$c35_ad_policy   <- pol
  cfg$gms$c35_aolc_policy <- pol
  cfg
}

# variant | forest policy | macc step
variants <- list(
  nzb_R0_offoff_polnone = list(forest = "none", macc = -1),
  nzb_R0_offoff_ndc     = list(forest = "ndc",  macc = -1),
  nzb_R0_npi_fullmacc   = list(forest = "npi",  macc = 201))

launch <- function(cfg, title, v){
  cfg <- set_forest(cfg, v$forest); cfg <- set_macc(cfg, v$macc)
  cfg$title <- title
  start_run(cfg, codeCheck = FALSE)
  title
}
titles <- mapply(function(nm, v) launch(cfg, nm, v), names(variants), variants)
cat("== launched 3 baseline-variant runs ==\n"); print(unname(titles))
