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

runID <- "testWDPA"

# # ====================
# # Calibration
# # ====================

# source("config/IrrC_calib_test.cfg")
source("config/default.cfg")

# which input data sets should be used?
# cfg$input <- c(regional    = "rev4.96_h12_magpie.tgz",
#                cellular    = "rev4.96_h12_fd712c0b_cellularmagpie_c200_MRI-ESM2-0-ssp370_lpjml-8e6c5eb1.tgz",
#                validation  = "rev4.96_h12_validation.tgz",
#                additional  = "additional_data_rev4.47.tgz",
#                calibration = "calibration_IrrC_v13landcalibsticky_grass_15Mar24.tgz"
#             )

# cfg$force_download <- FALSE #TRUE

cfg$title <- paste0("IrrC_",runID)
# cfg$force_replace <- TRUE

# cfg$recalibrate <- TRUE
# cfg$recalibrate_landconversion_cost <- TRUE

# # sticky
cfg$gms$factor_costs <- "sticky_feb18"

# # crop realisation
# cfg$gms$crop <- "endo_apr21"
# cfg$gms$c30_marginal_land <- "q33_marginal"

cfg$gms$past <- "grasslands_apr22"               # def = endo_jun13
# cfg$gms$c31_past_suit_scen <- "yields"

# ***---------------------    22_land_conservation    --------------------------------------
# * (area_based_apr22):    Area-based conservation (baseline and future)
# *                        based on WDPA and conservation priority areas
cfg$gms$land_conservation  <- "area_based_apr22"           # def = area_based_apr22

# * Baseline protection in historic and future time steps
# * ("WDPA")              All legally protected areas across all IUCN categories
# * ("WDPA_I-II-III")     All legally protected areas in IUCN categories I, II & III
# * ("WDPA_IV-V-VI")      All legally protected areas in IUCN categories IV, V & VI
# * ("none")              No baseline protection
# * Note: c22_base_protect applies to countries selected in policy_countries22
# * c22_base_protect_noselect applies to all other countries.
cfg$gms$c22_base_protect <- "WDPA"              # def = WDPA
cfg$gms$c22_base_protect_noselect <- "WDPA"     # def = WDPA

# * Additional land conservation target based on conservation priority areas
# * during future time steps (after `cfg$gms$sm_fix_SSP2`).
# * ("none")              No additional land conservation target (WDPA only)
# * ("30by30")            30 % of global land surface in Key Biodiversity Areas (KBA),
# *                       GSN Distinct Species Assemblages & Critical Connectivity Areas + WDPA
# * ("KBA")               Key Biodiversity Areas + WDPA
# * ("GSN_DSA")           Global Safety Net: Distinct Species Assemblages + WDPA
# * ("GSN_RarePhen")      Global Safety Net: Rare Phenomena + WDPA
# * ("GSN_AreaIntct")     Global Safety Net: Areas of Intactness + WDPA
# * ("GSN_ClimTier1")     Global Safety Net: Climate Stabilisation Tier 1 + WDPA
# * ("GSN_ClimTier2")     Global Safety Net: Climate Stabilisation Tier 2 + WDPA
# * ("CCA")               Critical Connectivity Areas (Brennan et al. 2022) + WDPA
# * ("IrrC_XXpc")         Land area that covers XX percent of total global irrecoverable carbon
# *                       as defined by Noon et al. (2022), where XX correponds to either
# *                       50, 75, 95, or 99 percent + WDPA
# * ("IrrC_XXpc_30by30")  30by30 + Land area that covers XX percent of total global irrecoverable
# *                       carbon as defined by Noon et al. (2022), where XX correponds to either
# *                       50, 75, 95, or 99 percent + WDPA
# * ("BH")                Biodiversity Hotspots + WDPA
# * ("IFL")               Intact Forest Landscapes + WDPA
# * ("BH_IFL")            Biodiversity Hotspots + Intact Forest Landscapes  + WDPA
# * ("GSN_HalfEarth")     Full protection of areas within the Global Safety Net, which
# *                       roughly corresponds to 50 percent of the global land surface
# * ("PBL_HalfEarth")     Ecoregion-based approach to protecting half of the global land surface
# * Note: c22_protect_scenario applies to countries selected in policy_countries22
# * c22_protect_scenario_noselect applies to all other countries.

# cons_scen <- c("none","30by30",
#                 "IrrC_50pc","IrrC_75pc","IrrC_95pc","IrrC_99pc",
#                 "IrrC_50pc_30by30","IrrC_75pc_30by30","IrrC_95pc_30by30","IrrC_99pc_30by30")
wdpa_scen <- c("none", "WDPA_I-II-III", "WDPA_IV-V-VI", "WDPA")
cons_scen <- c("none","30by30",
                "IrrC_75pc","IrrC_95pc","IrrC_99pc",
                "IrrC_75pc_30by30","IrrC_95pc_30by30","IrrC_99pc_30by30") # 

#start MAgPIE runs
# for (w in wdpa_scen) {
#     for(cons in cons_scen) {     # 2:length(cons_scen)

#     cfg$title <- paste0("IrrC_",runID,"_",w,"_",cons)        # ,"_sticky_grass"
#     cfg$gms$c22_base_protect <- w      # def = None
#     cfg$gms$c22_protect_scenario <- cons      # def = None
    
#     start_run(cfg=cfg)
# # calib_grass_tgz <- magpie4::submitCalibration(paste0("IrrC_",runID,"_grass"))
# # calib_grass_tgz <- magpie4::submitCalibration(paste0("IrrC_",runID,"sticky_grass"))
#     }
# }

# Run none base protection scenarios using specific calibration
for (cons in cons_scen) {

    cfg$input <- c(regional    = "rev4.105_h12_magpie.tgz",
               cellular    = "rev4.105_h12_fd712c0b_cellularmagpie_c200_MRI-ESM2-0-ssp370_lpjml-8e6c5eb1.tgz",
               validation  = "rev4.105_h12_validation.tgz",
               additional  = "additional_data_rev4.48.tgz",
               calibration = "calibration_calib_WDPA_none_20May24.tgz")  # "calibration_H12_26Mar24.tgz"

    cfg$title <- paste0("IrrC_",runID,"_none_",cons)        # ,"_sticky_grass"
    
    cfg$gms$c22_base_protect <- "none"      # def = None
    cfg$gms$c22_protect_scenario <- cons      # def = None
    
    start_run(cfg=cfg)
# calib_grass_tgz <- magpie4::submitCalibration(paste0("IrrC_",runID,"_grass"))
# calib_grass_tgz <- magpie4::submitCalibration(paste0("IrrC_",runID,"sticky_grass"))
    }


# Run WDPA_I-II-III base protection scenarios using specific calibration
for (cons in cons_scen) {

    cfg$input <- c(regional    = "rev4.105_h12_magpie.tgz",
               cellular    = "rev4.105_h12_fd712c0b_cellularmagpie_c200_MRI-ESM2-0-ssp370_lpjml-8e6c5eb1.tgz",
               validation  = "rev4.105_h12_validation.tgz",
               additional  = "additional_data_rev4.48.tgz",
               calibration = "calibration_calib_WDPA_WDPA_I-II-III_20May24.tgz")  # "calibration_H12_26Mar24.tgz"

    cfg$title <- paste0("IrrC_",runID,"_WDPA_I-II-III_",cons)        # ,"_sticky_grass"
    
    cfg$gms$c22_base_protect <- "WDPA_I-II-III"      # def = None
    cfg$gms$c22_protect_scenario <- cons      # def = None
    
    start_run(cfg=cfg)
# calib_grass_tgz <- magpie4::submitCalibration(paste0("IrrC_",runID,"_grass"))
# calib_grass_tgz <- magpie4::submitCalibration(paste0("IrrC_",runID,"sticky_grass"))
    }

# Run WDPA_IV-V-VI base protection scenarios using specific calibration
for (cons in cons_scen) {

    cfg$input <- c(regional    = "rev4.105_h12_magpie.tgz",
               cellular    = "rev4.105_h12_fd712c0b_cellularmagpie_c200_MRI-ESM2-0-ssp370_lpjml-8e6c5eb1.tgz",
               validation  = "rev4.105_h12_validation.tgz",
               additional  = "additional_data_rev4.48.tgz",
               calibration = "calibration_calib_WDPA_WDPA_IV-V-VI_20May24.tgz")  # "calibration_H12_26Mar24.tgz"

    cfg$title <- paste0("IrrC_",runID,"_WDPA_IV-V-VI_",cons)        # ,"_sticky_grass"
    
    cfg$gms$c22_base_protect <- "WDPA_IV-V-VI"      # def = None
    cfg$gms$c22_protect_scenario <- cons      # def = None
    
    start_run(cfg=cfg)
# calib_grass_tgz <- magpie4::submitCalibration(paste0("IrrC_",runID,"_grass"))
# calib_grass_tgz <- magpie4::submitCalibration(paste0("IrrC_",runID,"sticky_grass"))
    }


# Run full WDPA base protection scenarios using specific calibration
for (cons in cons_scen) {

    cfg$input <- c(regional    = "rev4.105_h12_magpie.tgz",
               cellular    = "rev4.105_h12_fd712c0b_cellularmagpie_c200_MRI-ESM2-0-ssp370_lpjml-8e6c5eb1.tgz",
               validation  = "rev4.105_h12_validation.tgz",
               additional  = "additional_data_rev4.48.tgz",
               calibration = "calibration_calib_WDPA_none_20May24.tgz")  # "calibration_H12_26Mar24.tgz"

    cfg$title <- paste0("IrrC_",runID,"_WDPA",cons)        # ,"_sticky_grass"
    
    cfg$gms$c22_base_protect <- "WDPA"      # def = None
    cfg$gms$c22_protect_scenario <- cons      # def = None
    
    start_run(cfg=cfg)
# calib_grass_tgz <- magpie4::submitCalibration(paste0("IrrC_",runID,"_grass"))
# calib_grass_tgz <- magpie4::submitCalibration(paste0("IrrC_",runID,"sticky_grass"))
    }