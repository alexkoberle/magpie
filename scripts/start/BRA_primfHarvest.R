# |  (C) 2008-2025 Potsdam Institute for Climate Impact Research (PIK)
# |  authors, and contributors see CITATION.cff file. This file is part
# |  of MAgPIE and licensed under AGPL-3.0-or-later. Under Section 7 of
# |  AGPL-3.0, you are granted additional permissions described in the
# |  MAgPIE License Exception, version 1.0 (see LICENSE file).
# |  Contact: magpie@pik-potsdam.de


# ----------------------------------------------------------
# description: Script using BRA_H13_C200_W2 data (Secd Forest from MapBiomas) 
# ----------------------------------------------------------


######################################
#### Script to start a MAgPIE run ####
######################################

library(gms)
library(lucode2)
library(magclass)

# Load start_run(cfg) function which is needed to start MAgPIE runs
source("scripts/start_functions.R")

#start MAgPIE run
source("config/default.cfg")


cfg$repositories <- append(list("https://rse.pik-potsdam.de/data/magpie/public"=NULL,
                                "./patch_inputdata"=NULL),
                           getOption("magpie_repos"))

#Input data files to be used for SecdForest data analysis
# cfg$input <- c(regional    = "rev4.129.9001NZB_BRA_H13_C200_W2_SwpFun_5638d5dc_magpie.tgz",
#                cellular    = "rev4.129.9001NZB_BRA_H13_C200_W2_SwpFun_5638d5dc_22226bc0_cellularmagpie_c200_MRI-ESM2-0-ssp245_lpjml-8e6c5eb1_clusterweight-917fb741.tgz",
#                validation  = "rev4.129.9001NZB_BRA_H13_C200_W2_SwpFun_5638d5dc_92e02314_validation.tgz",
#                additional  = "additional_data_rev4.65.tgz",
#                calibration = "calibration_BRA_H13_C200_W2_SwpFun_Feb26.tgz")
# which input data sets should be used?
cfg$input <- c(regional    = "rev4.131.9001BRA_H13_C200_W3_MapbiomasIBGE_5638d5dc_magpie.tgz",
               cellular    = "rev4.131.9001BRA_H13_C200_W3_MapbiomasIBGE_5638d5dc_d8411e75_cellularmagpie_c200_MRI-ESM2-0-ssp245_lpjml-8e6c5eb1_clusterweight-d0236589.tgz",
               validation  = "rev4.131.9001BRA_H13_C200_W3_MapbiomasIBGE_5638d5dc_92e02314_validation.tgz",
               additional  = "additional_data_rev4.65.tgz",
               calibration = "calibration_BRA_H13_C200_W3_MapbiomasIBGE_18Jun26.tgz")




# cfg$title <- "calib_cluster_W3newTGZ_defaultValues"
# cfg$title <- "primfHarvest_test_MBra"
# cfg$title <- "primfHarvest_aug26_test1"
cfg$title <- "primfHarvest_aug26_zerodamage1"
# cfg$title <- "BRA_W3_MapbiomasIBGE_calibCluster_1stTry"

# cfg$gms$c_timesteps          <- "5year2050"

# * (calib):    Costs for cropland expansion are scaled with a regional calibration factor
# *       Costs for pasture and forestry expansion are global static
# * (calib_cluster_crop_past): Costs for cropland expansion are scaled with a regional calibration factor, which is further scaled
# * on cluster level with the share of cropland in the cluster. Costs for pasture expansion are scaled with a regional calibration factor,
# * which is further scaled on cluster level with the share of pasture in the cluster. Costs for forestry expansion are global static.
# cfg$gms$landconversion <- "calib_cluster_crop_past"           # def = calib

# * Switch for ignoring land conversion cost calibration factors
# * Options: 1 (ignore calibration factors)
# *      0 (use calibration factors)
# cfg$gms$s39_ignore_calib <- 0           #def = 0

# * (pot_forest_may24): base realization -- harvested primary forest is always
# *      reclassified as secondary forest, never earns wood revenue when directly
# *      deforested to agricultural/other land.
# * (primf_harvest_aug26): adds v35_clearcut_primforest -- primary forest directly
# *      deforested (not reclassified as secdforest) can also earn wood-harvest
# *      revenue, discounted by a BRA-specific recovery-share parameter (0.30) and
# *      costed at a BRA-specific harvest cost ($70/m3, converted internally to
# *      USD17MER/tDM). Active only for policy_countries35_clearcut (default "BRA");
# *      a no-op everywhere else, so this is safe to leave on for non-BRA runs too.
cfg$gms$natveg <- "primf_harvest_aug26"        # def = pot_forest_may24

# * s35_hvarea = 2 (endogenous, the model default) is what actually exercises the
# * new v35_clearcut_primforest pathway -- the model decides each period how much
# * primary-forest loss is selectively harvested (-> secdforest, degradation) vs.
# * clear-cut (-> agricultural/other land, deforestation, with discounted wood
# * revenue) vs. left as unharvested deforestation, based on relative costs/revenue.
# cfg$gms$s35_hvarea <- 2                      # def = 2 (uncomment only to override)

# * s35_hvarea_clearcut: exogenous annual clear-cut rate, only takes effect if
# * s35_hvarea is set to 1 above. Left at its default (0, i.e. inactive) for this
# * first test run -- see project memory (project_primf_harvest_realization.md)
# * for the planned cluster-level calibration follow-up.
# cfg$gms$s35_hvarea_clearcut <- 0             # def = 0

# * s35_forest_damage: isolation test (title "zerodamage") -- the default (2)
# * applies an exogenous shifting-agriculture disturbance loss to primary forest
# * every period (independent of any LP/harvest decision, fading out by
# * s35_forest_damage_end = 2050). In the first test run (primfHarvest_aug26_test1)
# * this exogenous mechanism accounted for ~80% of all primary forest loss,
# * leaving very little primary-forest area for the LP to allocate at all -- which
# * is why v35_clearcut_primforest never activated and cropland expansion drew
# * almost entirely from Other Land instead of Forest. Setting this to 0 removes
# * the exogenous mechanism entirely, so all primary forest reduction becomes
# * LP-driven -- isolating whether Other Land still wins on economics alone.
cfg$gms$s35_forest_damage <- 0                 # def = 2

start_run(cfg,codeCheck = FALSE)
