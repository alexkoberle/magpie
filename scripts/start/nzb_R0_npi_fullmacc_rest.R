## nzb_R0_npi_fullmacc_rest.R ---------------------------------------------------
## Corrected baseline variant: NPI forest policy + FULL MACC potential (step 201)
## + restoration ON (Half-Earth PBL, BRA). No cap. (Replaces the mistaken
## nzb_R0_npi_fullmacc which had restore OFF.)
## Same baseline frame as the other variants: nocc, non-binding cap, no GHG prices.
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
cfg$gms$c56_emis_cap_scenario <- "none"          # non-binding (no cap)
cfg$gms$s56_emis_cap_parametric <- 0
cfg$gms$s56_source_bounds_on  <- 0
cfg$gms$c56_pollutant_prices  <- "none"
cfg$gms$s56_c_price_induced_aff <- 0
cfg$gms$c_timesteps <- "5year2050"
cfg$output     <- c("rds_report")
cfg$sequential <- FALSE

# forest policy = NPI (default, set explicitly)
cfg$gms$c32_aff_policy  <- "npi"
cfg$gms$c35_ad_policy   <- "npi"
cfg$gms$c35_aolc_policy <- "npi"

# restoration ON (Half-Earth PBL, BRA)
cfg$gms$c22_protect_scenario          <- "PBL_HalfEarth"
cfg$gms$c22_protect_scenario_noselect <- "none"
cfg$gms$policy_countries22            <- "BRA"
cfg$gms$s22_restore_land              <- 1

# FULL MACC potential: max curve step 201 (~1222 USD/tCO2eq), phased in as usual
cfg$gms$s57_maxmac_n_soil      <- 201
cfg$gms$s57_maxmac_n_awms      <- 201
cfg$gms$s57_maxmac_ch4_rice    <- 201
cfg$gms$s57_maxmac_ch4_entferm <- 201
cfg$gms$s57_maxmac_ch4_awms    <- 201
cfg$gms$s57_maxmac_fadein       <- 1
cfg$gms$s57_maxmac_fadein_start <- 2025
cfg$gms$s57_maxmac_fadein_end   <- 2050

cfg$title <- "nzb_R0_npi_fullmacc_rest"
start_run(cfg, codeCheck = FALSE)
