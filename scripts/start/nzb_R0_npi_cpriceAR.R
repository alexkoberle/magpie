## nzb_R0_npi_cpriceAR.R --------------------------------------------------------
## New no-cap reference: NPI forest + a 1.5C CO2 PRICE (BRA) that drives BOTH the
## non-CO2 MACCs AND carbon-price-induced afforestation/reforestation (A/R), with
## Half-Earth restoration OFF. Purpose: test whether price-driven A/R can deliver
## a deeper BRA land-CO2 sink by 2050 than the forced Half-Earth restoration.
##
## Mechanism (verified in cap_apr26_reg + module 57):
##  - c56_pollutant_prices = R34M410-SSP2-PkBudg650  -> 1.5C price (~641 USD/tCO2eq
##    by 2050; the same level as MACC step 106). Applied to BRA only via
##    policy_countries56="BRA"; rest of world stays at NPi2025 (noselect). Price is
##    muted until 2030 (c56_mute_ghgprices_until) then follows the PkBudg650 path.
##  - s57_maxmac_* = -1  -> MACC abatement is PRICE-DRIVEN (forced override off).
##  - s56_c_price_induced_aff = 1  -> the CO2 price rewards A/R (faded in from 2030).
##  - restoration off: c22_protect_scenario=none, s22_restore_land=0 (WDPA base only).
##  - no cap, nocc, NPI forest policy.
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

cfg$gms$ghg_policy            <- "cap_apr26_reg"
cfg$gms$c56_cap_policy        <- "all"
cfg$gms$c56_emis_cap_scenario <- "none"          # NO cap
cfg$gms$s56_emis_cap_parametric <- 0
cfg$gms$s56_source_bounds_on  <- 0

# --- 1.5C CO2 price for BRA (drives MACC + A/R); rest of world at NPi baseline ---
cfg$gms$c56_pollutant_prices          <- "R34M410-SSP2-PkBudg650"
cfg$gms$c56_pollutant_prices_noselect <- "R34M410-SSP2-NPi2025"
cfg$gms$policy_countries56            <- "BRA"
# carbon-price-induced afforestation ON (faded in from 2030)
cfg$gms$s56_c_price_induced_aff <- 1

# --- price-driven MACC (forced override OFF) ---
cfg$gms$s57_maxmac_n_soil      <- -1
cfg$gms$s57_maxmac_n_awms      <- -1
cfg$gms$s57_maxmac_ch4_rice    <- -1
cfg$gms$s57_maxmac_ch4_entferm <- -1
cfg$gms$s57_maxmac_ch4_awms    <- -1
cfg$gms$s57_maxmac_fadein       <- 0

# --- NPI forest policy ---
cfg$gms$c32_aff_policy  <- "npi"
cfg$gms$c35_ad_policy   <- "npi"
cfg$gms$c35_aolc_policy <- "npi"

# --- restoration OFF (WDPA base protection only) ---
cfg$gms$c22_protect_scenario          <- "none"
cfg$gms$c22_protect_scenario_noselect <- "none"
cfg$gms$policy_countries22            <- "BRA"
cfg$gms$s22_restore_land              <- 0

cfg$gms$c_timesteps <- "5year2050"
cfg$output     <- c("rds_report")
cfg$sequential <- FALSE

cfg$title <- "nzb_R0_npi_cpriceAR"
start_run(cfg, codeCheck = FALSE)
