## add_cap_scenario.R --------------------------------------------------------
## Adds a new scenario column to f56_emis_cap.cs3 using magclass read/write.
##
## Accepts scenario values as a data.table with columns:
##   year   (character, e.g. "y2025")
##   region (character, e.g. "BRA")
##   value  (numeric, Tg CO2eq per yr; use 1e6 for non-binding)
##
## Any (year, region) pair not present in scen_dt keeps the default 1e6.
##
## Dot/underscore guard: magclass uses "." as subdimension separator.
## Scenario names with dots cause GAMS $170 errors — use underscores.
## ---------------------------------------------------------------------------

library(magclass)
library(data.table)

# ---- trajectory builder: linear BRA ramp from historical anchor to cap ------
build_bra_trajectory <- function(cap_tg, target_year,
                                  hist_2020 = 1490, hist_2025 = 1440) {
  # Returns data.table(year, region, value) covering y2020:y2150 in 5-yr steps.
  # Units: Tg CO2eq per yr (== Mt CO2eq per yr; 1 Tg = 1 Mt).
  # cap_tg comes from nzb_launch.R: cap = target + OFFSET_MT, already in Tg.
  target_year <- as.integer(target_year)
  if (!target_year %in% c(2040L, 2045L, 2050L))
    stop("build_bra_trajectory: target_year must be 2040, 2045, or 2050.")
  years  <- seq(2020L, 2150L, by = 5L)
  values <- vapply(years, function(y) {
    if (y == 2020L)            hist_2020
    else if (y <= 2025L)       hist_2025
    else if (y <= target_year) hist_2025 + (cap_tg - hist_2025) * (y - 2025) / (target_year - 2025)
    else                       cap_tg
  }, numeric(1))
  data.table(year = paste0("y", years), region = "BRA", value = values)
}

# ---- helper: magpie -> data.table (avoids NA column name issue) -----------
magpie_to_dt <- function(x, scen) {
  df <- as.data.frame(x[, , scen], rev = TRUE)
  # as.data.frame(rev=TRUE) gives: Cell, Region, Year, [Data cols...], value
  # For a (t x i x 1-scenario) slice the cols are: Cell, Region, Year, Data1, value
  # Rename positionally — robust to magclass version differences
  nc <- ncol(df)
  names(df)[nc]     <- "value"
  names(df)[nc - 1] <- "scenario"
  names(df)[nc - 2] <- "year"
  names(df)[nc - 3] <- "region"
  dt <- as.data.table(df)[, .(
    year     = as.character(year),
    region   = as.character(region),
    scenario = as.character(scenario),
    value    = as.numeric(value)
  )]
  dt
}

# ---- helper: data.table -> magpie slice -----------------------------------
dt_to_magpie_slice <- function(dt, template, scen_name) {
  # Start from a non-binding template (all 1e6)
  x_slice <- template[, , "none"]
  x_slice[, , ] <- 1e6
  getItems(x_slice, dim = 3) <- scen_name

  # Fill values from data.table row by row
  dt_char <- dt[, .(
    year   = as.character(year),
    region = as.character(region),
    value  = as.numeric(value)
  )]
  # magclass: dim 1 = cells/regions (spatial), dim 2 = time.
  # scen_dt years may lack the leading "y" (as.data.frame strips it);
  # getItems(dim=2) always returns "y2020" style — normalise before matching.
  for (k in seq_len(nrow(dt_char))) {
    yr <- dt_char$year[k]
    rg <- dt_char$region[k]
    vl <- dt_char$value[k]
    # Normalise year: add "y" prefix if absent
    yr_mag <- if (startsWith(as.character(yr), "y")) yr else paste0("y", yr)
    if (rg %in% getItems(x_slice, dim = 1) && yr_mag %in% getItems(x_slice, dim = 2)) {
      x_slice[rg, yr_mag, scen_name] <- vl
    } else {
      warning("Skipping (", yr, ", ", rg, ") — not in template dimensions.")
    }
  }
  x_slice
}

# ---- main function --------------------------------------------------------
add_cap_scenario <- function(
    scen_name = "user_scen",
    scen_dt   = NULL,
    cs3_file  = "modules/56_ghg_policy/cap_apr26_reg/input/f56_emis_cap.cs3",
    dry_run   = TRUE,
    overwrite = FALSE
) {

  # 1. Validate scenario name
  if (grepl("\\.", scen_name)) {
    stop(
      "Scenario name '", scen_name, "' contains a dot.\n",
      "  magclass uses '.' as a subdimension separator — GAMS will fail $170.\n",
      "  Use underscores instead: '", gsub("\\.", "_", scen_name), "'."
    )
  }

  # 2. Read existing file
  cat("Reading:", cs3_file, "\n")
  x <- read.magpie(cs3_file)

  # magclass convention: dim 1 = cells/regions (spatial), dim 2 = time, dim 3 = data
  regions <- as.character(getItems(x, dim = 1))
  years   <- as.character(getItems(x, dim = 2))
  scens   <- as.character(getItems(x, dim = 3))

  cat("  Years  :", paste(range(years), collapse = " to "), "\n")
  cat("  Regions:", paste(regions, collapse = ", "), "\n")
  cat("  Existing scenarios:", paste(scens, collapse = ", "), "\n")

  # Warn if magclass silently converted underscores to dots in region names
  if (any(grepl("\\.", regions))) {
    warning(
      "Region names contain dots after read: ",
      paste(regions[grepl("\\.", regions)], collapse = ", "), "\n",
      "  magclass may have converted underscores. Verify against GAMS 'i' set."
    )
  }

  # 3. Abort or overwrite if scenario already exists
  if (scen_name %in% scens) {
    if (!overwrite)
      stop("Scenario '", scen_name, "' already exists. Pass overwrite=TRUE to replace it.")
    x <- x[, , scens[scens != scen_name], drop = FALSE]
    cat("  Overwriting existing scenario '", scen_name, "'.\n", sep = "")
  }

  # 4. Build new scenario slice from data.table
  if (!is.null(scen_dt)) {
    if (!is.data.table(scen_dt)) scen_dt <- as.data.table(scen_dt)
    needed <- c("year", "region", "value")
    missing_cols <- setdiff(needed, names(scen_dt))
    if (length(missing_cols) > 0)
      stop("scen_dt is missing columns: ", paste(missing_cols, collapse = ", "))
    x_new_scen <- dt_to_magpie_slice(scen_dt, x, scen_name)
    cat("  Scenario slice built from data.table (",
        nrow(scen_dt), "rows with custom values).\n")
  } else {
    # No values supplied — initialise entirely non-binding
    x_new_scen <- x[, , "none"]
    x_new_scen[, , ] <- 1e6
    getItems(x_new_scen, dim = 3) <- scen_name
    cat("  No scen_dt supplied — new column initialised to 1e6 (non-binding).\n")
  }

  # 5. Bind and optionally write
  x_out <- mbind(x, x_new_scen)
  cat("  Output scenarios:", paste(as.character(getItems(x_out, dim = 3)), collapse = ", "), "\n")

  if (dry_run) {
    cat("\ndry_run = TRUE — no file written. Set dry_run = FALSE to save.\n")
    return(invisible(x_out))
  }

  write.magpie(x_out, cs3_file, file_type = "cs3")
  cat("Written:", cs3_file, "\n")

  # 6. Format check
  raw <- readLines(cs3_file, n = 20)
  data_lines <- raw[!grepl("^\\*", raw)]
  cat("\nFirst 3 non-comment lines:\n")
  cat(head(data_lines, 3), sep = "\n")

  n_dummies <- sum(strsplit(data_lines[1], ",")[[1]] == "dummy")
  if (n_dummies != 2L) {
    warning("Header has ", n_dummies, " dummy columns; GAMS expects 2 for f56_emis_cap(t_all,i,capscen56).")
  } else {
    cat("\nFormat check PASSED: 2 dummy columns.\n")
  }

  invisible(x_out)
}
