# |  (C) 2008-2025 Potsdam Institute for Climate Impact Research (PIK)
# |  authors, and contributors see CITATION.cff file. This file is part
# |  of MAgPIE and licensed under AGPL-3.0-or-later. Under Section 7 of
# |  AGPL-3.0, you are granted additional permissions described in the
# |  MAgPIE License Exception, version 1.0 (see LICENSE file).
# |  Contact: magpie@pik-potsdam.de

# -----------------------------------------------------------------------
# description: Generate cluster-level land conversion cost calibration
#   factors (f39_calib_cluster.csv and f39_calib_past_cluster.csv) for
#   the BRA 58-cluster H13 configuration using IBGE-based observed land
#   areas. Runs standalone - does not modify start_functions.R or
#   calibrate_magpie(). Must be run from the model root directory.
#
# Prerequisites:
#   1. Input data downloaded (input/ must contain clustermap_rev*.rds)
#   2. Observation file in place:
#      modules/39_landconversion/calib_cluster_crop_past/input/obs_cells_crop_past.rds
#   3. Regional calibration files already generated:
#      modules/39_landconversion/input/f39_calib.csv
#      modules/39_landconversion/input/f39_calib_past.csv
#   4. GAMS accessible from PATH
#
# Output:
#   modules/39_landconversion/calib_cluster_crop_past/input/f39_calib_cluster.csv
#   modules/39_landconversion/calib_cluster_crop_past/input/f39_calib_past_cluster.csv
#   cluster_calib_run/  (GAMS logs and intermediate files)
# -----------------------------------------------------------------------

library(magclass)
library(madrat)
library(magpie4)
library(lucode2)

source("scripts/calibration/calibrate_cluster.R")

calibrateCluster(
  obs_cells_path     = "modules/39_landconversion/calib_cluster_crop_past/input/obs_cells_crop_past.rds",
  clustermap_path    = NULL,            # auto-detected from input/clustermap_rev*.rds
  selected_clusters  = paste0("BRA_", 1:58),
  calib_file_crop    = "modules/39_landconversion/calib_cluster_crop_past/input/f39_calib_cluster.csv",
  calib_file_past    = "modules/39_landconversion/calib_cluster_crop_past/input/f39_calib_past_cluster.csv",
  n_max_calib        = 20,
  cost_only_max_iter = 10,
  calib_accuracy     = 0.05,
  cost_max           = 2.5,
  cost_min           = 0.1,
  putfolder          = "cluster_calib_run",
  logoption          = 3,
  debug              = FALSE
)
