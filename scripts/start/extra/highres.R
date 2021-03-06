# |  (C) 2008-2021 Potsdam Institute for Climate Impact Research (PIK)
# |  authors, and contributors see CITATION.cff file. This file is part
# |  of MAgPIE and licensed under AGPL-3.0-or-later. Under Section 7 of
# |  AGPL-3.0, you are granted additional permissions described in the
# |  MAgPIE License Exception, version 1.0 (see LICENSE file).
# |  Contact: magpie@pik-potsdam.de


# ----------------------------------------------------------
# description: Start a set of runs with default and high resolution
# ----------------------------------------------------------

library(gms)
library(magclass)
library(gdx)
library(magpie4)

# Load start_run(cfg) function which is needed to start MAgPIE runs
source("scripts/start_functions.R")
source("config/default.cfg")

#cfg$force_download <- TRUE

cfg$results_folder <- "output/:title:"

#the high resolution can be adjusted in the output script "highres.R"
cfg$output <- c("rds_report","highres")

prefix <- "T07"

#cfg$qos <- "priority"
lr <- "c200"
cfg$input <- c(paste0("isimip_rcp-IPSL_CM5A_LR-rcp2p6-co2_rev44_",lr,"_690d3718e151be1b450b394c1064b1c5.tgz"),
               "rev4.44_h12_magpie.tgz",
               "rev4.44_h12_validation.tgz",
               paste0("calibration_H12_",lr,"_26Feb20.tgz"),
               "additional_data_rev3.79.tgz")

download_and_update(cfg)

ssps <- c("SSP1","SSP2","SSP3","SSP4","SSP5")
scen <- "2p6"

for (ssp in ssps) {
  cfg$title <- paste(prefix,ssp,scen,sep="_")
  cfg <- gms::setScenario(cfg,c(ssp,"NDC"))
  cfg$gms$c56_pollutant_prices <- "SSPDB-SSP2-26-REMIND-MAGPIE"
  cfg$gms$c60_2ndgen_biodem <- "SSPDB-SSP2-26-REMIND-MAGPIE"
  start_run(cfg,codeCheck=FALSE)
}
