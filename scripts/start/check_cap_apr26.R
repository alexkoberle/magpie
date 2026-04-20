## check_cap_apr26.R -------------------------------------------------------
## Post-run diagnostics for cap_apr26 (and cap_apr26_ref).
##
## Three checks:
##   1. oq56_emis_cap marginal  → should be ~0 when cap is non-binding
##   2. ov56_slack_emis_cap     → should be 0 throughout (no infeasibility)
##   3. ov56_emis_co2eq global  → should sit in 5 000 – 10 000 Tg CO2eq/yr
##
## Usage (interactive):
##   source("scripts/start/check_cap_apr26.R")
##   check_cap_apr26("output/<your_run_folder>")
##
## Usage (batch — pass folder as first command-line arg):
##   Rscript scripts/start/check_cap_apr26.R output/<your_run_folder>
## -------------------------------------------------------------------------

library(magclass)   # magpie object handling + dimSums / mselect
library(gdx)        # readGDX

# ---- helper: pretty-print a magpie object as a data frame ----------------
.mp2df <- function(x, value_name = "value") {
  df <- as.data.frame(x, rev = TRUE)
  names(df)[ncol(df)] <- value_name
  df
}

# ---- main diagnostic function --------------------------------------------
check_cap_apr26 <- function(run_dir, plot = TRUE) {

  gdx_path <- file.path(run_dir, "fulldata.gdx")
  if (!file.exists(gdx_path)) {
    stop("fulldata.gdx not found in: ", run_dir,
         "\nDid the run finish? Check for full.lst errors.")
  }

  cat("\n=== cap_apr26 diagnostics ===\n")
  cat("Run folder:", run_dir, "\n\n")

  # ------------------------------------------------------------------
  # 1. Cap constraint shadow price
  #    oq56_emis_cap(t, type)  — type="marginal" is the dual variable.
  #    Non-binding cap  → marginal = 0.
  #    Binding cap      → marginal > 0 (USD17MER per Tg CO2eq).
  # ------------------------------------------------------------------
  cap_dual <- readGDX(gdx_path, "oq56_emis_cap",
                      select = list(type = "marginal"), react = "silent")

  cat("--- CHECK 1: Cap constraint shadow price (marginal) ---\n")
  if (is.null(cap_dual) || max(abs(cap_dual), na.rm = TRUE) < 1e-6) {
    cat("  PASS — marginal is effectively zero (non-binding cap).\n")
  } else {
    cat("  NOTE — cap is binding in some periods. Shadow prices:\n")
    print(.mp2df(cap_dual, "shadow_price_USD17MER_per_TgCO2eq"))
  }

  # ------------------------------------------------------------------
  # 2. Slack variable
  #    ov56_slack_emis_cap(t, type)  — type="level".
  #    Any non-zero value means the biophysical floor exceeded the cap.
  # ------------------------------------------------------------------
  slack <- readGDX(gdx_path, "ov56_slack_emis_cap",
                   select = list(type = "level"), react = "silent")

  cat("\n--- CHECK 2: Slack variable level (infeasibility guard) ---\n")
  if (is.null(slack) || max(abs(slack), na.rm = TRUE) < 1e-6) {
    cat("  PASS — slack is zero throughout.\n")
  } else {
    cat("  WARNING — non-zero slack detected. Cap may be tighter than\n")
    cat("  the biophysical floor for these periods:\n")
    df_slack <- .mp2df(slack, "slack_TgCO2eq_yr")
    print(df_slack[df_slack$slack_TgCO2eq_yr > 1e-6, , drop = FALSE])
  }

  # ------------------------------------------------------------------
  # 3. Global AFOLU CO2eq total
  #    ov56_emis_co2eq(t, i, emis_source, pollutants, type)
  #    Sum over i, emis_source, pollutants → global Tg CO2eq per yr.
  #    Expected range: 5 000 – 10 000 Tg CO2eq/yr (5–10 Gt CO2eq).
  # ------------------------------------------------------------------
  co2eq_raw <- readGDX(gdx_path, "ov56_emis_co2eq",
                       select = list(type = "level"), react = "silent")

  cat("\n--- CHECK 3: Global AFOLU CO2eq (Tg CO2eq per yr) ---\n")
  if (is.null(co2eq_raw)) {
    cat("  SKIP — ov56_emis_co2eq not found in GDX",
        "(realization may not have written it).\n")
  } else {
    # Use set names so the sum is robust to any number of subdimensions.
    # getSets() returns every named dimension; drop "t" to keep only time.
    all_sets   <- getSets(co2eq_raw)
    non_t_sets <- setdiff(all_sets, "t")

    global_co2eq <- dimSums(co2eq_raw, dim = non_t_sets)

    # as.data.frame(magpie, rev=TRUE) gives columns: Cell, Region, Year, Data1, <value>
    # Pull the year column by name rather than position.
    df_raw  <- as.data.frame(global_co2eq, rev = TRUE)
    yr_col  <- grep("^[Yy]ear$|^t$|^t_all$", names(df_raw), value = TRUE)[1]
    val_col <- tail(names(df_raw), 1)
    df_global <- data.frame(
      year              = as.integer(sub("^y", "", as.character(df_raw[[yr_col]]))),
      global_TgCO2eq_yr = df_raw[[val_col]],
      global_GtCO2eq_yr = round(df_raw[[val_col]] / 1e3, 2)
    )

    # Range check on post-2020 periods only (1995–2020 are historic/calibration).
    df_future <- df_global[df_global$year > 2020, , drop = FALSE]
    in_range  <- nrow(df_future) == 0 ||
                 all(df_future$global_TgCO2eq_yr > 500 &
                       df_future$global_TgCO2eq_yr < 20000, na.rm = TRUE)
    if (in_range) {
      cat("  PASS — post-2020 values look plausible.\n")
    } else {
      cat("  WARNING — post-2020 values outside expected 500–20 000 Tg range.\n")
    }
    cat("  (Note: 1995 is a calibration artefact; only 2000+ rows are model output.)\n")
    print(df_global)

    # Optional breakdown: top emission sources (post-2020 mean)
    if ("emis_source" %in% all_sets) {
      cat("\n  Top 5 emis_source by post-2020 mean CO2eq contribution (Tg/yr):\n")
      sum_dims  <- setdiff(all_sets, c("t", "emis_source"))
      by_source <- dimSums(co2eq_raw, dim = sum_dims)        # (t x emis_source)
      src_df    <- as.data.frame(by_source, rev = TRUE)
      s_yr_col  <- grep("^[Yy]ear$|^t$|^t_all$", names(src_df), value = TRUE)[1]
      s_src_col <- grep("emis_source", names(src_df), value = TRUE)[1]
      s_val_col <- tail(names(src_df), 1)
      src_future <- src_df[as.integer(sub("^y", "", as.character(src_df[[s_yr_col]]))) > 2020, , drop = FALSE]
      mean_src  <- tapply(src_future[[s_val_col]], src_future[[s_src_col]],
                          mean, na.rm = TRUE)
      top5 <- sort(mean_src, decreasing = TRUE)[seq_len(min(5L, length(mean_src)))]
      print(round(top5, 1))
    }

    # ------------------------------------------------------------------
    # Plot: time series of global CO2eq (post-2000 only to avoid artefact)
    # ------------------------------------------------------------------
    df_plot <- df_global[df_global$year >= 2000, , drop = FALSE]
    if (plot && nrow(df_plot) > 1) {
      plot(df_plot$year, df_plot$global_TgCO2eq_yr,
           type = "b", pch = 16,
           xlab = "Year", ylab = "Tg CO2eq per yr",
           main = paste0("Global AFOLU CO2eq — ", basename(run_dir)),
           ylim = c(0, max(df_plot$global_TgCO2eq_yr, na.rm = TRUE) * 1.15))
      abline(h = c(5000, 10000), lty = 2, col = "grey50")
      legend("topright", legend = "5–10 Gt range", lty = 2, col = "grey50",
             bty = "n", cex = 0.8)
    }
  }

  cat("\n=== diagnostics complete ===\n")
  invisible(list(cap_dual = cap_dual, slack = slack, co2eq = co2eq_raw))
}

# ---- batch entry point ---------------------------------------------------
if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) == 0) {
    # auto-detect: most recently modified output folder
    runs <- list.dirs("output", recursive = FALSE, full.names = TRUE)
    if (length(runs) == 0) stop("No output folder found.")
    run_dir <- runs[which.max(file.mtime(runs))]
    cat("No folder supplied — using most recent output:\n ", run_dir, "\n")
  } else {
    run_dir <- args[1]
  }
  check_cap_apr26(run_dir, plot = FALSE)
}
