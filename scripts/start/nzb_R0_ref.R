## nzb_R0_ref.R --------------------------------------------------------------
## NZB R0 REFERENCE run (no binding cap). Locates where Brazil's reported AFOLU
## lands from the prescribed levers ALONE, before any cap binds.
##
## Revised design (call with Alex Koberle, 2026-06-25; recipe (a)):
##  - NO climate-change impacts  -> setScenario(cfg, "nocc") sets all 7 climate
##    switches (c14 yields, c35 pot_forest, c42/c43 water, c52 carbon,
##    c52 land_carbon_sink, c59 som). Pure bookkeeping convention.
##  - NO GHG prices  -> c56_pollutant_prices = "none" (im_pollutant_prices = 0),
##    s56_c_price_induced_aff = 0. Reason: do not distort the deforestation signal.
##  - A/R via restoration  -> Half-Earth PBL conservation, BRA only, forced,
##    phased 2025->2050 (the knob that will later vary with the cap).
##  - Non-CO2 via FIXED 1.5C MACC fade  -> s57_maxmac_* = 106 (= PkBudg650 2050
##    step: co2_c 2350 USD/tC ~ 641 USD/tCO2eq; step = ceil(2350/22.4)+1 = 106),
##    phased linearly from step 1 @2025 to 106 @2050 (s57_maxmac_fadein = 1).
##    All five non-CO2 sources. Global (BRA-only MACC is a later refinement).
##  - Cap scope c56_cap_policy = "all" (soil now included; PR #904 applied).
##  - Cap level c56_emis_cap_scenario = "none"  -> p56_emis_cap = 1e6 = NON-BINDING.
##
## Soil-carbon bugfix PR #904 already applied to modules/59_som/{cellpool_jan23,
## static_jan19}/postsolve.gms. MACC linear fade-in added to
## modules/57_maccs/on_aug22/{input,declarations,preloop}.gms (gated by
## s57_maxmac_fadein; fadein=0 reproduces the flat baseline bit-for-bit).
##
## Run directly from this worktree (project folder renamed AlexKoberle, ASCII path
## -> renv no longer breaks; the separate magpie_nzb_run copy was retired). Input
## rev4.131 W3 already prepared in input/ (source_files.log matches) -> no download.
## ---------------------------------------------------------------------------

library(lucode2)   # setScenario lives in gms/lucode2 - load before use
library(gms)
library(magpie4)
source("config/default.cfg")
source("scripts/start_functions.R")

# --- input data (rev4.131 W3, == Alex's runs) -------------------------------
cfg$input <- c(regional    = "rev4.131.9001BRA_H13_C200_W3_MapbiomasIBGE_5638d5dc_magpie.tgz",
               cellular    = "rev4.131.9001BRA_H13_C200_W3_MapbiomasIBGE_5638d5dc_d8411e75_cellularmagpie_c200_MRI-ESM2-0-ssp245_lpjml-8e6c5eb1_clusterweight-d0236589.tgz",
               validation  = "rev4.131.9001BRA_H13_C200_W3_MapbiomasIBGE_5638d5dc_92e02314_validation.tgz",
               additional  = "additional_data_rev4.65.tgz",
               calibration = "calibration_BRA_H13_C200_W3_MapbiomasIBGE_18Jun26.tgz")
cfg$repositories <- append(list("https://rse.pik-potsdam.de/data/magpie/public" = NULL),
                           getOption("magpie_repos"))

# --- do NOT download / recalibrate (proven config from prior runs) ----------
cfg$force_download                  <- FALSE
cfg$force_replace                   <- TRUE
cfg$recalibrate                     <- FALSE
cfg$recalibrate_landconversion_cost <- FALSE

# --- climate OFF: bookkeeping convention (all 7 switches) -------------------
cfg <- setScenario(cfg, "nocc")

# --- run settings -----------------------------------------------------------
cfg$title          <- "nzb_R0_ref"
cfg$gms$ghg_policy  <- "cap_apr26_reg"

# cap: scope "all" (soil included; bug fixed); NON-BINDING (R0 reference)
cfg$gms$c56_cap_policy        <- "all"
cfg$gms$c56_emis_cap_scenario <- "none"        # p56_emis_cap = 1e6 -> never binds
cfg$gms$s56_source_bounds_on  <- 0

# NO GHG prices (do not distort deforestation); no C-price-induced A/R
cfg$gms$c56_pollutant_prices    <- "none"
cfg$gms$s56_c_price_induced_aff <- 0

# A/R via Half-Earth restoration, Brazil only (forced, phased 2025->2050)
cfg$gms$c22_protect_scenario          <- "PBL_HalfEarth"
cfg$gms$c22_protect_scenario_noselect <- "none"
cfg$gms$policy_countries22            <- "BRA"
cfg$gms$s22_restore_land              <- 1

# Non-CO2 via FIXED 1.5C MACC fade (step 1 @2025 -> 106 @2050, linear, 5 sources)
cfg$gms$s57_maxmac_fadein       <- 1
cfg$gms$s57_maxmac_fadein_start <- 2025
cfg$gms$s57_maxmac_fadein_end   <- 2050
cfg$gms$s57_maxmac_n_soil      <- 106
cfg$gms$s57_maxmac_n_awms      <- 106
cfg$gms$s57_maxmac_ch4_rice    <- 106
cfg$gms$s57_maxmac_ch4_entferm <- 106
cfg$gms$s57_maxmac_ch4_awms    <- 106

cfg$gms$c_timesteps <- "5year2050"
cfg$output          <- c("rds_report")
cfg$sequential      <- FALSE

start_run(cfg, codeCheck = FALSE)
