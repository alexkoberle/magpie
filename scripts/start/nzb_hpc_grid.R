## nzb_hpc_grid.R ===============================================================
## Comprehensive NZB test grid for the PIK HPC (SLURM). One start script; each
## start_run() -> one SLURM job. Launch on the LOGIN node with submit=direct.
##
## PREREQUISITE (run ONCE on login first, to warm the input cache and avoid the
## H12-fallback trap):   Rscript scripts/start/download_data_BRA.R
## then verify core/sets.gms shows `Regionscode: 5638d5dc` + 13 regions (incl. BRA).
##
## Launch:  Rscript start.R runscripts=nzb_hpc_grid submit=direct
##
## ---- TIER SWITCHES (edit these 2 lines to flip medium <-> light) -------------------
##   medium (~71 runs): STEP_AB=50 ; B_AR=c(TRUE,FALSE)
##   light  (~49 runs): STEP_AB=100; B_AR=c(TRUE)
STEP_AB <- 100            # cap-ladder step for families A & B (C is always 50)  [LIGHT]
B_AR    <- c(TRUE)        # A/R on/off in family B                              [LIGHT]
## ------------------------------------------------------------------------------------
##
## DESIGN (indexed by ACHIEVED reported GWP100AR6|Land BRA AFOLU 2050; nocc; AR6 GWP
## baked into cap_apr26_reg/preloop.gms; wood self-sufficiency forced for BRA):
##   Spine : parametric BRA cap, reported ladder {-200..+200} (cap target = reported+71;
##           dashboard re-indexes on achieved).
##   Fam C : conservation {WDPA, 30by30, HalfEarth} x cap ladder + ref. Cap ALONE
##           (forced 1.5C MACC, no price). HalfEarth = current dashboard corner (redo).
##   Fam A : global-policy context. RoW priced 2C (PkBudg1000, noselect); BRA capped.
##           Global context {A/R (RoW aff) + 2nd-gen bioenergy demand} toggled ON/OFF
##           together. Cons=HalfEarth.
##   Fam B : cap PLUS a BRA 1.5C CO2 price (PkBudg650) driving price-induced A/R and
##           price-driven MACC; A/R on/off. Cons=HalfEarth. Tests whether the price
##           deepens CO2 below the cap alone (compare B vs C-HalfEarth).
##   Anchor: NPI only, no MACC/restore/price/cap ("do nothing").
##
## Cap families (C, A) force 1.5C MACC (BRA has no own price). Family B is price-driven.
## A/R (s56_c_price_induced_aff) only bites where a price applies: RoW in A, BRA in B.
## ============================================================================
library(lucode2); library(gms); library(magpie4)
source("config/default.cfg"); source("scripts/start_functions.R")

# ---- input + infra (BRA-H13 W3; on HPC download_distribute falls back to local mirrors) ----
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

# ---- common GHG-policy / trade / horizon (all runs) --------------------------------
cfg$gms$ghg_policy           <- "cap_apr26_reg"   # AR6 GWP baked in (preloop.gms:131-133)
cfg$gms$c56_cap_policy       <- "all"             # soil incl. (PR #904)
cfg$gms$s56_source_bounds_on <- 0
cfg$gms$policy_countries56   <- "BRA"
cfg$gms$s21_force_wood_selfsuff <- 1              # forced BRA wood self-sufficiency (no leakage)
cfg$gms$policy_countries21   <- "BRA"
cfg$gms$c32_aff_policy  <- "npi"; cfg$gms$c35_ad_policy <- "npi"; cfg$gms$c35_aolc_policy <- "npi"
cfg$gms$c_timesteps <- "5year2050"                # <-- HORIZON knob: "coup2100" for 2100
cfg$output     <- c("rds_report")
cfg$sequential <- FALSE
cfg$qos        <- "standby"                       # many runs > priority MaxJobsPU cap

CAPOFFSET <- 71                                    # reported = cap - 71 (wood-SS on)
reps_main <- seq(-200, 200, by = 50)               # family C ladder
reps_ab   <- seq(-200, 200, by = STEP_AB)          # families A & B ladder

reptag <- function(r) if (r == 0) "rep000" else sprintf("rep%s%03d", if (r < 0) "M" else "P", abs(r))
launch <- function(cfg, title) { cfg$title <- title; start_run(cfg, codeCheck = FALSE) }

# ---- lever helpers -----------------------------------------------------------------
macc_forced <- function(cfg) {                     # forced 1.5C MACC, faded 2025->2050
  for (s in c("n_soil","n_awms","ch4_rice","ch4_entferm","ch4_awms"))
    cfg$gms[[paste0("s57_maxmac_", s)]] <- 106
  cfg$gms$s57_maxmac_fadein <- 1
  cfg$gms$s57_maxmac_fadein_start <- 2025; cfg$gms$s57_maxmac_fadein_end <- 2050
  cfg
}
macc_pricedriven <- function(cfg) {                # abatement follows the CO2 price
  for (s in c("n_soil","n_awms","ch4_rice","ch4_entferm","ch4_awms"))
    cfg$gms[[paste0("s57_maxmac_", s)]] <- -1
  cfg$gms$s57_maxmac_fadein <- 0
  cfg
}
conservation <- function(cfg, scen) {              # "none"(=WDPA base) / "30by30" / "PBL_HalfEarth"
  cfg$gms$c22_protect_scenario          <- scen
  cfg$gms$c22_protect_scenario_noselect <- "none"
  cfg$gms$s22_restore_land              <- if (scen == "none") 0 else 1
  cfg$gms$policy_countries22            <- "BRA"
  cfg
}
set_cap <- function(cfg, reported) {
  cfg$gms$s56_emis_cap_parametric  <- 1
  cfg$gms$s56_emis_cap_start_year  <- 2035
  cfg$gms$s56_emis_cap_start_value <- 600
  cfg$gms$s56_emis_cap_target_year <- 2050
  cfg$gms$s56_emis_cap_target      <- reported + CAPOFFSET
  cfg
}
set_nocap <- function(cfg) {
  cfg$gms$s56_emis_cap_parametric <- 0; cfg$gms$c56_emis_cap_scenario <- "none"; cfg
}
ladder <- function(base, fam, reps) {              # ref (no-cap) + cap ladder
  launch(set_nocap(base), sprintf("nzb_%s_ref", fam))
  for (r in reps) launch(set_cap(base, r), sprintf("nzb_%s_%s", fam, reptag(r)))
}

# ============================ Family C: conservation (cap alone) ====================
for (cons in list(list(tag="wdpa", scen="none"),
                  list(tag="30by30", scen="30by30"),
                  list(tag="half", scen="PBL_HalfEarth"))) {
  base <- conservation(macc_forced(cfg), cons$scen)
  base$gms$c56_pollutant_prices          <- "none"
  base$gms$c56_pollutant_prices_noselect <- "R34M410-SSP2-NPi2025"
  base$gms$s56_c_price_induced_aff       <- 0
  ladder(base, sprintf("gC_%s", cons$tag), reps_main)
}

# ===================== Family A: global-policy context (RoW priced 2C) ==============
# A/R (RoW afforestation) + 2nd-gen bioenergy demand toggled ON/OFF together.
for (ctx in c(TRUE, FALSE)) {
  base <- conservation(macc_forced(cfg), "PBL_HalfEarth")
  base$gms$c56_pollutant_prices          <- "none"                     # BRA capped
  base$gms$c56_pollutant_prices_noselect <- "R34M410-SSP2-PkBudg1000"  # RoW 2C
  base$gms$s56_c_price_induced_aff       <- if (ctx) 1 else 0
  bioscen <- if (ctx) "R34M410-SSP2-PkBudg1000" else "none"
  base$gms$c60_2ndgen_biodem             <- bioscen
  base$gms$c60_2ndgen_biodem_noselect    <- bioscen
  ladder(base, sprintf("gA_ctx%s", if (ctx) "ON" else "OFF"), reps_ab)
}

# ===================== Family B: cap + BRA 1.5C price (drives A/R + MACC) ============
for (ar in B_AR) {
  base <- conservation(macc_pricedriven(cfg), "PBL_HalfEarth")
  base$gms$c56_pollutant_prices          <- "R34M410-SSP2-PkBudg650"   # BRA priced 1.5C
  base$gms$c56_pollutant_prices_noselect <- "R34M410-SSP2-NPi2025"     # RoW current policies
  base$gms$s56_c_price_induced_aff       <- if (ar) 1 else 0
  ladder(base, sprintf("gB_ar%s", if (ar) "ON" else "OFF"), reps_ab)
}

# ===================== Anchor: NPI only (no MACC / restore / price / cap) ============
anchor <- set_nocap(conservation(macc_pricedriven(cfg), "none"))
anchor$gms$c56_pollutant_prices          <- "none"
anchor$gms$c56_pollutant_prices_noselect <- "R34M410-SSP2-NPi2025"
anchor$gms$s56_c_price_induced_aff       <- 0
launch(anchor, "nzb_g0_npi")

nC <- 3 * (length(reps_main) + 1)
nA <- 2 * (length(reps_ab) + 1)
nB <- length(B_AR) * (length(reps_ab) + 1)
cat(sprintf("== nzb_hpc_grid launched: C(%d) + A(%d) + B(%d) + anchor(1) = %d SLURM jobs ==\n",
            nC, nA, nB, nC + nA + nB + 1))
