# |  (C) 2008-2025 Potsdam Institute for Climate Impact Research (PIK)
# |  authors, and contributors see CITATION.cff file. This file is part
# |  of MAgPIE and licensed under AGPL-3.0-or-later. Under Section 7 of
# |  AGPL-3.0, you are granted additional permissions described in the
# |  MAgPIE License Exception, version 1.0 (see LICENSE file).
# |  Contact: magpie@pik-potsdam.de

# ----------------------------------------------------------
# description: Test runs for the cap_apr26 realization of 56_ghg_policy
# position: 10
# ----------------------------------------------------------
#
# Three runs in increasing order of complexity:
#
#   Run 1 — cap_nonbinding  : single timestep, cap = 1e6 (non-binding).
#              Purpose: verify GAMS compilation and that the realization
#              behaves identically to a no-policy run.
#              codeCheck = TRUE to catch any compilation errors.
#
#   Run 2 — cap_nonbinding_full : full time horizon, non-binding cap.
#              Purpose: verify recursive-dynamic loop, postsolve output,
#              and that p56_emis_cap_slack stays zero throughout.
#
#   Run 3 — cap_binding (REQUIRES USER ACTION, see below):
#              Tests a hard binding cap. To activate:
#                (a) Add a scenario column (e.g. "test_tight") to
#                    modules/56_ghg_policy/cap_apr26/input/f56_emis_cap.csv
#                    with Tg CO2eq/yr values tighter than the baseline.
#                (b) Register the name in capscen56 in
#                    modules/56_ghg_policy/cap_apr26/sets.gms.
#                (c) Uncomment Run 3 below and set c56_emis_cap_scenario.
#
# ----------------------------------------------------------

library(gms)
library(lucode2)

source("scripts/start_functions.R")
source("config/default.cfg")   # loads cfg; default.cfg is NOT modified

# --- shared cap_apr26 base settings ------------------------------------
cfg$gms$ghg_policy              <- "cap_apr26"
cfg$gms$c56_emis_cap_scenario   <- "none"      # non-binding (1e6 Tg CO2eq/yr)
cfg$gms$s56_emis_cap_start      <- 2025
cfg$gms$s56_emis_cap_penalty    <- 1e5
cfg$gms$c56_cap_policy          <- "all_nosoil"
cfg$gms$s56_source_bounds_on    <- 0
# Pricing stays off (pure quantity instrument default)
cfg$gms$c56_pollutant_prices    <- "none"
cfg$gms$c56_mute_ghgprices_until <- "y2150"

cfg$force_replace     <- TRUE
cfg$results_folder    <- "output/:title:"

# =======================================================================
# Run 1 — single timestep, non-binding cap, code check ON
# =======================================================================
# cfg$gms$c_timesteps <- 1
# cfg$title           <- "cap_apr26_nonbinding_1step"
# start_run(cfg, codeCheck = TRUE)

# =======================================================================
# Run 2 — full time horizon, non-binding cap
# =======================================================================
# cfg$gms$c_timesteps <- "coup2100"  # restore full horizon (default from default.cfg)
# cfg$title           <- "cap_apr26_nonbinding_full"
# start_run(cfg, codeCheck = FALSE)

# =======================================================================
# Run 3 — binding cap  [UNCOMMENT AFTER COMPLETING STEPS (a)-(c) ABOVE]
# =======================================================================
cfg$gms$c_timesteps          <- 1
cfg$gms$c56_emis_cap_scenario <- "test_tight"   # column in f56_emis_cap.csv
cfg$title                    <- "cap_apr26_binding_1step"
start_run(cfg, codeCheck = FALSE)
# After run: check output/cap_apr26_binding_1step/full.log for
#   oq56_emis_cap and ov56_slack_emis_cap to confirm constraint is active.

# =======================================================================
# Run 4 — Archetype A source bounds, single timestep  [UNCOMMENT TO TEST]
# =======================================================================
# cfg$gms$c_timesteps          <- 1
# cfg$gms$s56_source_bounds_on <- 1
# # Populate modules/56_ghg_policy/cap_apr26/input/f56_source_bound.cs3
# # before activating, otherwise all bounds remain 1e6 (non-binding).
# cfg$title                    <- "cap_apr26_archetypeA_1step"
# start_run(cfg, codeCheck = FALSE)
