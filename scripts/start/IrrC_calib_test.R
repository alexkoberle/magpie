# |  (C) 2008-2023 Potsdam Institute for Climate Impact Research (PIK)
# |  authors, and contributors see CITATION.cff file. This file is part
# |  of MAgPIE and licensed under AGPL-3.0-or-later. Under Section 7 of
# |  AGPL-3.0, you are granted additional permissions described in the
# |  MAgPIE License Exception, version 1.0 (see LICENSE file).
# |  Contact: magpie@pik-potsdam.de

# ------------------------------------------------
# description: start run with default.cfg settings
# position: 1
# ------------------------------------------------

library(gms)
library(lucode2)
library(magclass)

# Load start_run(cfg) function which is needed to start MAgPIE runs
source("scripts/start_functions.R")

runID <- "v13landcalib"

# # ====================
# # Calibration
# # ====================

# source("config/IrrC_calib_test.cfg")
source("config/default.cfg")

cfg$input <- c(regional    = "rev4.96_h12_magpie.tgz",
               cellular    = "rev4.96_h12_fd712c0b_cellularmagpie_c200_MRI-ESM2-0-ssp370_lpjml-8e6c5eb1.tgz",
               validation  = "rev4.96_h12_validation.tgz",
               additional  = "additional_data_rev4.47.tgz"#,
            #    calibration = "calibration_H12_per_ton_fao_may22_glo_08Aug23.tgz"
            )


cfg$force_download <- FALSE #TRUE

cfg$title <- "calib_run_full"
cfg$force_replace <- TRUE

cfg$recalibrate <- TRUE
cfg$recalibrate_landconversion_cost <- TRUE

cfg$gms$s14_use_yield_calib <- 1    # def = 0

# # sticky
# cfg$gms$factor_costs <- "sticky_feb18"

# # crop realisation
# cfg$gms$crop <- "endo_apr21"
# cfg$gms$c30_marginal_land <- "q33_marginal"

cfg$gms$past <- "grasslands_apr22"               # def = endo_jun13
# cfg$gms$c31_past_suit_scen <- "yields"

cfg$qos <- "standby_maxMem_dayMax"
# cfg$gms$s80_optfile <- 1

#start MAgPIE run
start_run(cfg=cfg)
# calib_grass_tgz <- magpie4::submitCalibration(paste0("IrrC_",runID,"_grass"))
calib_grass_tgz <- magpie4::submitCalibration(paste0("IrrC_",runID,"sticky_grass"))
