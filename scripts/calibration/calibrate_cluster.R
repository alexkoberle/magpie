# |  (C) 2008-2025 Potsdam Institute for Climate Impact Research (PIK)
# |  authors, and contributors see CITATION.cff file. This file is part
# |  of MAgPIE and licensed under AGPL-3.0-or-later. Under Section 7 of
# |  AGPL-3.0, you are granted additional permissions described in the
# |  MAgPIE License Exception, version 1.0 (see LICENSE file).
# |  Contact: magpie@pik-potsdam.de

# *********************************************************************
# ***  Standalone cluster-level land conversion cost calibration    ***
# ***  Calibrates f39_calib_cluster.csv and f39_calib_past_cluster  ***
# ***  .csv using IBGE-based observed cluster land areas            ***
# *********************************************************************
#
# Run from the model root directory. Source this file then call
# calibrateCluster(). See scripts/start/extra/calibrate_cluster_BRA.R.
#
# Calibration window: y1995-y2020 (requires c_timesteps="calib_2020" in sets.gms)
# Convergence: cost-only for the first cost_only_max_iter iterations;
#              reward activated as fallback if still not converged.

# Run one GAMS calibration solve with calib_2020 timestep and
# calib_cluster_crop_past realization.
calibrationRunCluster <- function(putfolder, calibMagpieName, logoption, useGDX) {
  require(lucode2)
  require(magpie4)

  cat("=== CALIBRATION_RUN_CLUSTER START ===\n")
  cat(paste0("Putfolder: ", putfolder, ", useGDX: ", useGDX, "\n"))

  unlink(paste0(calibMagpieName, ".gms"))
  unlink("fulldata.gdx")

  if (!file.copy("main.gms", paste0(calibMagpieName, ".gms"), overwrite = TRUE)) {
    stop(paste("Unable to create", paste0(calibMagpieName, ".gms")))
  }
  lucode2::manipulateConfig(paste0(calibMagpieName, ".gms"), c_timesteps    = "calib_2020")
  lucode2::manipulateConfig(paste0(calibMagpieName, ".gms"), landconversion = "calib_cluster_crop_past")
  lucode2::manipulateConfig(paste0(calibMagpieName, ".gms"), useGDX         = useGDX)
  file.copy(paste0(calibMagpieName, ".gms"), putfolder, overwrite = TRUE)

  cat("Starting GAMS run...\n")
  system(paste0("gams ", calibMagpieName, ".gms -errmsg=1 -PUTDIR ./",
                putfolder, " -LOGOPTION=", logoption), wait = TRUE)
  cat("GAMS run completed\n")
  file.copy("fulldata.gdx", putfolder)
  cat("=== CALIBRATION_RUN_CLUSTER END ===\n")
}

# Aggregate obs_cells (0.5-degree magpie object, underscore cell notation) to
# cluster level using the clustermap RDS. Returns cluster-level magpie object
# with GAMS underscore notation (BRA_1 ... BRA_58).
aggregateToCluster <- function(obs_cells, clustermap_path) {
  require(madrat)
  require(magclass)

  # clustermap uses dot notation (-73p75.-7p75.BRA); obs_cells uses underscore
  # after as.magpie conversion (-73p75_-7p75_BRA). Convert obs_cells to dot.
  getCells(obs_cells) <- gsub("_", ".", getCells(obs_cells))

  # toolAggregate requires the relation matrix to cover exactly the cells in x.
  # The full clustermap has 67,420 global cells but obs_cells has only 2,901
  # BRA cells, so we filter the clustermap to the cells present in obs_cells.
  clustermap <- readRDS(clustermap_path)
  bra_map <- clustermap[clustermap$cell %in% getCells(obs_cells), c("cell", "cluster")]
  if (nrow(bra_map) == 0) stop("No matching cells found between obs_cells and clustermap")

  obs_cluster <- madrat::toolAggregate(obs_cells, bra_map,
                                       from = "cell", to = "cluster", dim = 1)

  # Convert cluster names back to GAMS underscore notation (BRA_1)
  getCells(obs_cluster) <- gsub("\\.", "_", getCells(obs_cluster))

  return(obs_cluster)
}

# Compute divergence ratio mod/obs at cluster level for one land type.
# ratio > 1 means model has too much land -> cost factor will increase.
# ratio < 1 means model has too little land -> cost factor will decrease.
getCalibFactorCluster <- function(gdxFile, obs_cluster, land_type, calib_years) {
  require(magpie4)
  require(magclass)

  cat(paste0("  [getCalibFactorCluster:", land_type, "] reading GDX...\n"))

  mod_all <- land(gdxFile, level = "cell")
  # land() returns magclass dot notation (BRA.1); normalize to GAMS underscore (BRA_1)
  getCells(mod_all) <- gsub("\\.", "_", getCells(mod_all))
  avail_yr <- intersect(calib_years, getYears(mod_all))
  if (length(avail_yr) == 0) stop("No calibration years found in GDX")

  mod <- mod_all[, avail_yr, land_type]
  getNames(mod) <- NULL

  avail_cl <- intersect(getCells(obs_cluster), getCells(mod))
  if (length(avail_cl) == 0) stop("No matching clusters between GDX and obs_cluster")

  mod_sub <- mod[avail_cl, avail_yr, ]
  obs_sub  <- obs_cluster[avail_cl, avail_yr, land_type]
  getNames(obs_sub) <- NULL

  eps <- 1e-4  # ~100 ha; treat smaller areas as negligible

  # Per-year ratio (mod/obs) per cluster
  obs_wt   <- pmax(obs_sub, eps)
  ratio_yr <- mod_sub / obs_wt
  ratio_yr[obs_sub < eps] <- 1  # no calibration for negligible observed area

  # Collapse to a single obs-area-weighted ratio per cluster, then broadcast
  # back to all calibration years. Using year-specific ratios in a dynamic
  # model causes zigzag oscillation: correcting one year's stock perturbs the
  # starting stock for all subsequent years, triggering overcorrection there.
  obs_total <- dimSums(obs_wt,            dim = 2)  # sum across years
  ratio_avg <- dimSums(ratio_yr * obs_wt, dim = 2) / obs_total
  ratio <- ratio_yr
  for (yr in avail_yr) ratio[, yr, ] <- ratio_avg

  cat(paste0("  max|ratio-1| = ", round(max(abs(ratio - 1), na.rm = TRUE), 4), "\n"))
  return(ratio)
}

# Compute year-over-year change in observed area for one land type.
# Positive = obs expanding, negative = obs contracting.
# Used to suppress reward calibration where obs is not contracting.
expandHistCluster <- function(obs_cluster, land_type, avail_cl, calib_years) {
  require(magclass)
  obs_cal <- obs_cluster[avail_cl, calib_years, land_type]
  getNames(obs_cal) <- NULL
  expand_hist <- obs_cal * 0
  for (k in seq_len(dim(obs_cal)[2])) {
    if (k > 1) {
      expand_hist[, k, ] <- setYears(obs_cal[, k, ], NULL) -
                            setYears(obs_cal[, k - 1, ], NULL)
    }
  }
  return(expand_hist)
}

# Extend calibration window (y1995-y2020) to all model years (y1995-y2150).
# Years beyond the calibration window carry forward the last calibrated value.
timeSeriesCluster <- function(calib_window) {
  require(magclass)
  all_years <- seq(1995, 2150, by = 5)
  out <- new.magpie(getCells(calib_window), years = all_years,
                    names = getNames(calib_window), fill = NA)
  out[, getYears(calib_window), ] <- calib_window
  last_yr  <- getYears(calib_window)[length(getYears(calib_window))]
  last_val <- setYears(calib_window[, last_yr, ], NULL)
  future_years <- all_years[all_years > as.integer(sub("y", "", last_yr))]
  for (yr in future_years) out[, yr, ] <- last_val
  return(out)
}

# Write cluster calibration CSV in the format GAMS expects:
#   dummy,dummy,cost,reward
#   y1995,BRA_1,<cost>,<reward>
# Uses binary connection so no BOM is written (required by GAMS).
writeCalibClusterCSV <- function(calib_full, calib_file, description, calibration_step) {
  years    <- getYears(calib_full, as.integer = TRUE)
  clusters <- getCells(calib_full)

  header <- c(
    paste0("* description: ", description),
    "* unit: -",
    paste0("* note: Calibration step ", calibration_step, " | ", date()),
    "* origin: scripts/calibration/calibrate_cluster.R",
    "dummy,dummy,cost,reward"
  )

  data_lines <- character(length(years) * length(clusters))
  k <- 1L
  for (yr in years) {
    y_str <- paste0("y", yr)
    for (cl in clusters) {
      cost_val   <- round(as.numeric(calib_full[cl, y_str, "cost"]),   6)
      reward_val <- round(as.numeric(calib_full[cl, y_str, "reward"]), 6)
      data_lines[k] <- paste0(y_str, ",", cl, ",", cost_val, ",", reward_val)
      k <- k + 1L
    }
  }

  con <- file(calib_file, open = "wb")
  writeLines(c(header, data_lines), con = con, sep = "\n")
  close(con)
  cat(paste0("  Written ", calib_file, " (", length(data_lines), " data rows)\n"))
}

# Update one calibration CSV (crop or past) from the latest GDX.
# Returns TRUE when convergence is reached.
updateCalibCluster <- function(gdxFile, obs_cluster, land_type, calib_file,
                                calibration_step, calib_accuracy,
                                cost_max, cost_min, enable_reward, calib_years) {
  require(magclass)

  cat(paste0("=== UPDATE_CALIB_CLUSTER [", land_type, "] step ", calibration_step, " ===\n"))

  calib_divergence <- getCalibFactorCluster(gdxFile, obs_cluster, land_type, calib_years)
  avail_cl <- getCells(calib_divergence)
  avail_yr <- getYears(calib_divergence)

  # Load existing factors or initialise to neutral
  if (file.exists(calib_file)) {
    old_raw <- read.magpie(calib_file)
    getCells(old_raw) <- gsub("\\.", "_", getCells(old_raw))
    old_calib <- old_raw[avail_cl, avail_yr, ]
  } else {
    cat("  No existing calibration file; initialising cost=1, reward=0\n")
    old_calib <- new.magpie(avail_cl, avail_yr, names = c("cost", "reward"), fill = NA)
    old_calib[, , "cost"]   <- 1
    old_calib[, , "reward"] <- 0
  }

  # Reinforcement schedule (same as calibrateLandconversion)
  reinforcement <- if (calibration_step <= 8) 10 else if (calibration_step <= 11) 5 else 1

  new_cost <- setNames(old_calib[, , "cost"], NULL) * calib_divergence ^ reinforcement
  new_cost  <- pmin(pmax(new_cost, cost_min), cost_max)

  new_reward <- setNames(old_calib[, , "reward"], NULL)
  if (enable_reward) {
    expand_hist <- expandHistCluster(obs_cluster, land_type, avail_cl, avail_yr)
    new_reward  <- new_reward + (calib_divergence - 1) * reinforcement
    new_reward[setNames(expand_hist, NULL) >= 0] <- 0  # no reward where obs expands
    new_reward[new_reward < 0] <- 0
  }

  convergence_reached <- abs(calib_divergence - 1) <= calib_accuracy
  no_change <- (new_cost   == setNames(old_calib[, , "cost"],   NULL)) &
               (new_reward == setNames(old_calib[, , "reward"], NULL))
  done <- all(convergence_reached | no_change)

  cat(sprintf("  max|divergence-1| = %.4f %s\n",
              max(abs(calib_divergence - 1), na.rm = TRUE),
              if (done) "(CONVERGED)" else ""))

  calib_window <- mbind(
    add_dimension(new_cost,   dim = 3.1, nm = "cost"),
    add_dimension(new_reward, dim = 3.1, nm = "reward")
  )
  calib_full <- timeSeriesCluster(calib_window)

  description <- if (land_type == "crop") {
    "Cluster-level land conversion cost calibration factors for cropland"
  } else {
    "Cluster-level land conversion cost calibration factors for pasture"
  }
  writeCalibClusterCSV(calib_full, calib_file, description, calibration_step)

  return(done)
}

# Main calibration loop. Run from the model root directory.
#
# Parameters:
#   obs_cells_path     Path to preprocessed obs RDS (magpie, million ha, BRA cells)
#   clustermap_path    Path to clustermap RDS; NULL = auto-detect from input/
#   selected_clusters  GAMS-notation cluster IDs to calibrate
#   calib_file_crop    Output path for cropland calibration CSV
#   calib_file_past    Output path for pasture calibration CSV
#   n_max_calib        Maximum calibration iterations
#   cost_only_max_iter Iterations before reward calibration is activated as fallback
#   calib_accuracy     Convergence threshold for max|divergence-1|
#   cost_max / cost_min  Bounds on the cost factor
#   calibMagpieName    Name for the temporary GAMS file
#   putfolder          Directory for GAMS logs and intermediate GDX files
#   logoption          GAMS log option (3 = file only)
#   debug              Keep per-iteration listing and GDX files
calibrateCluster <- function(
  obs_cells_path     = "modules/39_landconversion/calib_cluster_crop_past/input/obs_cells_crop_past.rds",
  clustermap_path    = NULL,
  selected_clusters  = paste0("BRA_", 1:58),
  calib_file_crop    = "modules/39_landconversion/calib_cluster_crop_past/input/f39_calib_cluster.csv",
  calib_file_past    = "modules/39_landconversion/calib_cluster_crop_past/input/f39_calib_past_cluster.csv",
  n_max_calib        = 20,
  cost_only_max_iter = 10,
  calib_accuracy     = 0.05,
  cost_max           = 2.5,
  cost_min           = 0.1,
  calibMagpieName    = "magpie_calib_cluster",
  putfolder          = "cluster_calib_run",
  logoption          = 3,
  debug              = FALSE
) {
  require(magclass)
  require(madrat)
  require(magpie4)
  require(lucode2)

  # Auto-detect clustermap
  if (is.null(clustermap_path)) {
    maps <- Sys.glob("input/clustermap_rev*.rds")
    if (length(maps) == 0) {
      stop("No clustermap_rev*.rds found in input/. Provide clustermap_path explicitly.")
    }
    if (length(maps) > 1) warning("Multiple clustermaps found, using: ", maps[1])
    clustermap_path <- maps[1]
  }

  cat("##################################################################\n")
  cat("### CALIBRATE_CLUSTER START ###\n")
  cat("##################################################################\n")
  cat("Clustermap:      ", clustermap_path, "\n")
  cat("Obs file:        ", obs_cells_path, "\n")
  cat("Crop calib file: ", calib_file_crop, "\n")
  cat("Past calib file: ", calib_file_past, "\n")
  cat("n_max_calib:", n_max_calib,
      "| cost_only_max_iter:", cost_only_max_iter,
      "| calib_accuracy:", calib_accuracy, "\n")

  # Prepare putfolder
  unlink(putfolder, recursive = TRUE)
  dir.create(putfolder)

  # Load and aggregate obs once (expensive; reused every iteration)
  cat("\nLoading obs file...\n")
  obs_cells   <- readRDS(obs_cells_path)
  cat("Aggregating to cluster level...\n")
  obs_cluster <- aggregateToCluster(obs_cells, clustermap_path)
  avail_cl    <- intersect(selected_clusters, getCells(obs_cluster))
  if (length(avail_cl) == 0) stop("No selected_clusters found in aggregated obs")
  obs_cluster <- obs_cluster[avail_cl, , ]
  cat("Clusters available:", length(avail_cl), "\n")

  calib_years <- paste0("y", c(1995, 2000, 2005, 2010, 2015, 2020))

  logfile_conn <- file(file.path(putfolder, "calibration_cluster.log"), open = "w")
  sink(logfile_conn)
  sink(logfile_conn, type = "message")
  on.exit({
    try(sink(type = "message"), silent = TRUE)
    try(sink(), silent = TRUE)
    try(close(logfile_conn), silent = TRUE)
  }, add = TRUE)

  tryCatch({
    useGDX        <- 0
    enable_reward <- FALSE

    for (i in seq_len(n_max_calib)) {

      if (i > cost_only_max_iter && !enable_reward) {
        cat("\n>>> Cost-only iterations exhausted; enabling reward calibration\n")
        enable_reward <- TRUE
      }

      cat(paste0("\n### ITERATION ", i,
                 " (useGDX=", useGDX,
                 ", reward=", enable_reward, ") ###\n"))

      calibrationRunCluster(putfolder, calibMagpieName, logoption, useGDX)

      if (debug) {
        lst <- paste0(calibMagpieName, ".lst")
        if (file.exists(lst))
          file.copy(lst, file.path(putfolder, paste0(calibMagpieName, "_iter", i, ".lst")),
                    overwrite = TRUE)
        file.copy("fulldata.gdx",
                  file.path(putfolder, paste0("fulldata_iter", i, ".gdx")),
                  overwrite = TRUE)
      }

      done_crop <- updateCalibCluster("fulldata.gdx", obs_cluster, "crop",
                                      calib_file_crop, i, calib_accuracy,
                                      cost_max, cost_min, enable_reward, calib_years)
      done_past <- updateCalibCluster("fulldata.gdx", obs_cluster, "past",
                                      calib_file_past, i, calib_accuracy,
                                      cost_max, cost_min, enable_reward, calib_years)
      done <- done_crop && done_past

      if (done && useGDX == 2) {
        useGDX <- 0
        next
      } else if (done && useGDX == 0) {
        break
      } else {
        useGDX <- 2
      }
    }

    unlink(paste0(calibMagpieName, ".*"))
    unlink("fulldata.gdx")

    cat("\n### CALIBRATE_CLUSTER COMPLETE ###\n")
    cat("Calibrated files:\n")
    cat(" ", calib_file_crop, "\n")
    cat(" ", calib_file_past, "\n")

  }, error = function(e) {
    try(sink(type = "message"), silent = TRUE)
    try(sink(), silent = TRUE)
    try(close(logfile_conn), silent = TRUE)
    stop(e)
  })
}
