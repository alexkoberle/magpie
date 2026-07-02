## nzb_export_grid.R ============================================================
## NZB export-protection grid for the PIK HPC (SLURM). One start script; each
## start_run() -> one SLURM job. Launch on the LOGIN node with submit=direct.
##
## PREREQUISITE (once, on login, to warm the input cache / avoid the H12-fallback):
##   Rscript scripts/start/download_data_BRA.R
##   then verify core/sets.gms shows `Regionscode: 5638d5dc` + 13 regions (incl. BRA).
##
## Launch:  Rscript start.R runscripts=nzb_export_grid submit=direct
##   subset: NZB_FAMILIES=F Rscript start.R runscripts=nzb_export_grid submit=direct
##
## FAMILIES (7; all: cap_apr26_reg, nocc, AR6 GWP, c56_cap_policy=all, BRA cap,
##           s21_force_selfsuff=1 (BRA), WDPA base conservation, forest NPI, 5year2050;
##           indexed by ACHIEVED reported GWP100AR6|Land BRA AFOLU 2050):
##   gC_wdpa / gC_30by30 / gC_half : conservation, cap ALONE + forced 1.5C MACC.
##   gA_RoW2C : RoW pursues 2C (PkBudg1000 + price-induced A/R + 2C 2nd-gen bioenergy);
##              BRA capped, unpriced, WDPA, BRA bioenergy held at baseline (MACRO in NZB).
##   gB_price : cap + BRA 1.5C CO2 price (PkBudg650) -> price-driven A/R + MACC; WDPA.
##   gF_freeze: like gC_wdpa but forcesuff21 = ALL BRA f21_self_suff>1 (export freeze).
##   g0_npi   : NPI only (no cap/MACC/price) anchor ("do nothing").
##
## LADDER (reported targets, Mt): {-1000,-500,-250,-100,-50,0,50,100,250,500}; the cap
##   target = reported + CAPOFFSET (nominal; the true offset is ~+30..+70, varying with
##   family/depth, so the dashboard re-indexes on ACHIEVED reported). B is trimmed to its
##   sub-floor {-1000,-500,-250,-100} (its 0..+500 half is non-binding, floors ~-63).
##   Reachability: +250/+500 saturate at each family's no-cap plateau; -500/-1000 sit at/
##   below the feasibility frontier (may run on slack). Both are informative endpoints.
##
## RUN COUNT: C(3x11) + A(11) + F(11) + B(5) + anchor(1) = 61 jobs.
## ============================================================================
FAMILIES <- strsplit(Sys.getenv("NZB_FAMILIES", "C,A,B,F,0"), ",")[[1]]

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
cfg$gms$s21_force_selfsuff   <- 1                 # min self-sufficiency floor (general mechanism)
cfg$gms$forcesuff21          <- "wood, woodfuel"  # default (overridden for gF_freeze)
cfg$gms$policy_countries21   <- "BRA"
cfg$gms$c32_aff_policy  <- "npi"; cfg$gms$c35_ad_policy <- "npi"; cfg$gms$c35_aolc_policy <- "npi"
cfg$gms$c_timesteps <- "5year2050"                # <-- HORIZON knob: "coup2100" for 2100
cfg$output     <- c("rds_report")
cfg$results_folder <- "output/:title:"            # undated folders -> stable names
cfg$sequential <- FALSE
cfg$qos        <- "standby"                       # many runs > priority MaxJobsPU cap

CAPOFFSET  <- 50                                            # nominal reported->cap offset
reps_main  <- c(-1000, -500, -250, -100, -50, 0, 50, 100, 250, 500)   # C, A, F
reps_B     <- c(-1000, -500, -250, -100)                             # B trimmed (<= -63 floor)

# all BRA commodities with f21_self_suff > 1 (net exporters) + wood/woodfuel (gF_freeze)
FREEZE_LIST <- paste("wood, woodfuel, fibres, soybean, groundnut, sugar, oilcakes,",
                     "livst_pig, maiz, livst_chick, others, livst_rum, alcohol, oils,",
                     "rice_pro, livst_milk, cottn_pro, brans, cassav_sp, livst_egg")

reptag <- function(r) if (r == 0) "rep000" else sprintf("rep%s%d", if (r < 0) "M" else "P", abs(r))
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
if ("C" %in% FAMILIES) for (cons in list(list(tag="wdpa",   scen="none"),
                                         list(tag="30by30", scen="30by30"),
                                         list(tag="half",   scen="PBL_HalfEarth"))) {
  base <- conservation(macc_forced(cfg), cons$scen)
  base$gms$c56_pollutant_prices          <- "none"
  base$gms$c56_pollutant_prices_noselect <- "R34M410-SSP2-NPi2025"
  base$gms$s56_c_price_induced_aff       <- 0
  ladder(base, sprintf("gC_%s", cons$tag), reps_main)
}

# ===================== Family A: RoW pursues 2C, BRA capped (WDPA, BRA bioen baseline) =====
if ("A" %in% FAMILIES) {
  base <- conservation(macc_forced(cfg), "none")                       # WDPA (was HalfEarth)
  base$gms$c56_pollutant_prices          <- "none"                     # BRA capped, not priced
  base$gms$c56_pollutant_prices_noselect <- "R34M410-SSP2-PkBudg1000"  # RoW 2C price
  base$gms$s56_c_price_induced_aff       <- 1                          # price-induced A/R (RoW only)
  base$gms$scen_countries60              <- "BRA"                      # split BRA vs RoW bioenergy
  base$gms$c60_2ndgen_biodem             <- "R34M410-SSP2-NPi2025"     # BRA baseline (MACRO in NZB)
  base$gms$c60_2ndgen_biodem_noselect    <- "R34M410-SSP2-PkBudg1000"  # RoW 2C bioenergy demand
  ladder(base, "gA_RoW2C", reps_main)
}

# ===================== Family B: cap + BRA 1.5C price (drives A/R + MACC), WDPA ======
if ("B" %in% FAMILIES) {
  base <- conservation(macc_pricedriven(cfg), "none")                  # WDPA (was HalfEarth)
  base$gms$c56_pollutant_prices          <- "R34M410-SSP2-PkBudg650"   # BRA priced 1.5C
  base$gms$c56_pollutant_prices_noselect <- "R34M410-SSP2-NPi2025"     # RoW current policies
  base$gms$s56_c_price_induced_aff       <- 1                          # price-induced A/R (BRA)
  ladder(base, "gB_price", reps_B)                                     # trimmed to <= -63
}

# ===================== Family F: export freeze (gC_wdpa + all f21>1 forcesuff21) =====
if ("F" %in% FAMILIES) {
  base <- conservation(macc_forced(cfg), "none")                       # WDPA
  base$gms$c56_pollutant_prices          <- "none"
  base$gms$c56_pollutant_prices_noselect <- "R34M410-SSP2-NPi2025"
  base$gms$s56_c_price_induced_aff       <- 0
  base$gms$forcesuff21                   <- FREEZE_LIST                # freeze ALL BRA exports
  ladder(base, "gF_freeze", reps_main)
}

# ===================== Anchor: NPI only (no MACC / restore / price / cap) ============
if ("0" %in% FAMILIES) {
  anchor <- set_nocap(conservation(macc_pricedriven(cfg), "none"))
  anchor$gms$c56_pollutant_prices          <- "none"
  anchor$gms$c56_pollutant_prices_noselect <- "R34M410-SSP2-NPi2025"
  anchor$gms$s56_c_price_induced_aff       <- 0
  launch(anchor, "nzb_g0_npi")
}

nC <- if ("C" %in% FAMILIES) 3 * (length(reps_main) + 1) else 0
nA <- if ("A" %in% FAMILIES) length(reps_main) + 1 else 0
nB <- if ("B" %in% FAMILIES) length(reps_B) + 1 else 0
nF <- if ("F" %in% FAMILIES) length(reps_main) + 1 else 0
n0 <- if ("0" %in% FAMILIES) 1 else 0
cat(sprintf("== nzb_export_grid launched [%s]: C(%d)+A(%d)+B(%d)+F(%d)+anchor(%d) = %d jobs ==\n",
            paste(FAMILIES, collapse=","), nC, nA, nB, nF, n0, nC + nA + nB + nF + n0))
