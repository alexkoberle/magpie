# |  (C) 2008-2025 Potsdam Institute for Climate Impact Research (PIK)
# |  authors, and contributors see CITATION.cff file. This file is part
# |  of MAgPIE and licensed under AGPL-3.0-or-later. Under Section 7 of
# |  AGPL-3.0, you are granted additional permissions described in the
# |  MAgPIE License Exception, version 1.0 (see LICENSE file).
# |  Contact: magpie@pik-potsdam.de

# --------------------------------------------------------------
# description: extracts ov_emissions_reg from fulldata.gdx, converts to
#              CO2eq using AR5 GWP100 factors, and produces:
#              (1) a wide-format summary table (pollutant x year, Tg CO2eq/yr)
#              (2) a stacked bar plot of GHG emissions in Tg CO2eq/yr
#
# Source filter: emission sources included in the table and plot are
#              controlled by cap_policy (default "reddnatveg_nosoil"),
#              read from modules/56_ghg_policy/input/f56_emis_policy.csv.
#              Set cap_policy <- "all" to include all sources.
# comparison script: FALSE
# ---------------------------------------------------------------

library(gdx)
library(magclass)
library(data.table)
library(ggplot2)
library(lucode2)

options(error = function() traceback(2))

############################# BASIC CONFIGURATION #############################
if (!exists("source_include")) {
  outputdir <- file.path("output/", list.dirs("output/", full.names = FALSE,
                                               recursive = FALSE))
  lucode2::readArgs("outputdir")
}

# Source filter: which f56_emis_policy scenario to use as the inclusion mask.
# "reddnatveg_nosoil" matches the default cap_apr26_reg policy scope.
# Use "all" to include every source, or any other scen56 entry.
if (!exists("cap_policy")) cap_policy <- "reddnatveg_nosoil"
###############################################################################

# ---- AR5 GWP100 factors (consistent with price_aug22/preloop.gms) ----------
GWP <- c(
  co2_c          = 44 / 12,
  ch4            = 28,
  n2o_n_direct   = 265 * (44 / 28),
  n2o_n_indirect = 265 * (44 / 28),
  nh3_n          = 0,
  no2_n          = 0,
  no3_n          = 0
)
GHG_POLLUTANTS <- names(GWP[GWP > 0])

POL_LABELS <- c(
  co2_c          = "CO2",
  ch4            = "CH4",
  n2o_n_direct   = "N2O direct",
  n2o_n_indirect = "N2O indirect"
)
POL_COLOURS <- c(
  "CO2"          = "#D73027",
  "CH4"          = "#FC8D59",
  "N2O direct"   = "#FEE090",
  "N2O indirect" = "#91BFDB"
)

# ---- Build source filter from f56_emis_policy.csv --------------------------
EMIS_POLICY_FILE <- "modules/56_ghg_policy/input/f56_emis_policy.csv"

build_mask <- function(policy, emis_policy_file) {
  if (!file.exists(emis_policy_file))
    stop("Cannot find emis_policy file: ", emis_policy_file)

  raw <- read.csv(emis_policy_file, check.names = FALSE,
                  stringsAsFactors = FALSE)
  names(raw)[1:2] <- c("scenario", "pollutant")

  if (policy == "all") {
    # Return NULL — no filtering, all (emis_source, pollutant) pairs kept
    cat("  Source filter: ALL sources included (cap_policy = 'all')\n")
    return(NULL)
  }

  if (!policy %in% raw$scenario)
    stop("cap_policy '", policy, "' not found in f56_emis_policy.csv. ",
         "Available: ", paste(unique(raw$scenario), collapse = ", "))

  # Melt wide -> long; keep only GHG pollutants and active (==1) cells
  emis_cols <- setdiff(names(raw), c("scenario", "pollutant"))
  sub <- raw[raw$scenario == policy & raw$pollutant %in% names(GWP), ]
  dt  <- as.data.table(sub)
  dt  <- melt(dt, id.vars = c("scenario", "pollutant"),
              variable.name = "emis_source", value.name = "active",
              variable.factor = FALSE)
  mask <- dt[active == 1, .(emis_source, pollutant)]

  cat("  Source filter: cap_policy =", policy, "->",
      nrow(mask), "active (emis_source, pollutant) combinations\n")
  mask
}

source_mask <- build_mask(cap_policy, EMIS_POLICY_FILE)

# ============================================================================
cat("\nStarting plot_emis_co2eq output generation\n")
cat("  cap_policy:", cap_policy, "\n")

for (odir in outputdir) {

  gdx_path <- file.path(odir, "fulldata.gdx")
  if (!file.exists(gdx_path)) {
    warning("fulldata.gdx not found in: ", odir, " — skipping.")
    next
  }

  cat("\nProcessing:", odir, "\n")

  # ---- 1. Read ov_emissions_reg (time-series output parameter) -------------
  # NOTE: vm_emissions_reg has no t dimension in GAMS — reading it with
  # field="l" returns only the last timestep. ov_emissions_reg(t,i,
  # emis_source,pollutants,type) is the postsolve output with full history.
  # [, , "level"] selects the "level" slice of the type subdimension;
  # collapseNames removes the now single-valued type subdimension.
  emis_raw <- collapseNames(
    readGDX(gdx_path, "ov_emissions_reg", react = "silent")[, , "level"]
  )
  # Dims after collapseNames: (i=region, t=time, emis_source.pollutants)
  cat("  Read ov_emissions_reg:", paste(dim(emis_raw), collapse = " x "),
      "| sets:", paste(getSets(emis_raw), collapse = ", "), "\n")

  # ---- 2. Convert to data.table --------------------------------------------
  # as.data.frame(rev=TRUE) column order for a (d1,d2,d3.1,d3.2) magpie:
  #   Cell, region(d1), year(d2), emis_source(d3.1), pollutant(d3.2), value
  # Working from the end: nc=value, nc-1=pollutant, nc-2=emis_source,
  #                        nc-3=year, nc-4=region
  df <- as.data.frame(emis_raw, rev = TRUE)
  nc <- ncol(df)
  names(df)[nc]     <- "value_native"
  names(df)[nc - 1] <- "pollutant"
  names(df)[nc - 2] <- "emis_source"
  names(df)[nc - 3] <- "year"
  names(df)[nc - 4] <- "region"

  dt <- as.data.table(df)[, .(
    region       = as.character(region),
    year         = as.integer(sub("^y", "", as.character(year))),
    emis_source  = as.character(emis_source),
    pollutant    = as.character(pollutant),
    value_native = as.numeric(value_native)
  )]

  cat("  Years found:", paste(sort(unique(dt$year)), collapse = ", "), "\n")

  # Drop 1995: initialisation artefact — carbon stock deltas not yet meaningful
  dt <- dt[year != 1995]

  # ---- 3. Apply GWP factors ------------------------------------------------
  dt[, gwp   := GWP[pollutant]]
  dt[is.na(gwp), gwp := 0]
  dt[, co2eq := value_native * gwp]

  # ---- 4. Apply source filter (f56_emis_policy mask) -----------------------
  if (!is.null(source_mask)) {
    dt <- dt[source_mask, on = .(emis_source, pollutant), nomatch = NULL]
    cat("  Rows after source filter:", nrow(dt), "\n")
  }

  # ---- 5. Global totals: sum over emis_source and regions ------------------
  dt_glo <- dt[, .(
    co2eq = sum(co2eq, na.rm = TRUE),
    gwp   = first(gwp)
  ), by = .(year, pollutant)]

  # ---- 6. Summary table: pollutant x year ----------------------------------
  tab <- dcast(dt_glo, pollutant ~ year, value.var = "co2eq",
               fun.aggregate = sum)
  year_cols  <- setdiff(names(tab), "pollutant")
  tab_total  <- data.table(pollutant = "TOTAL",
                            as.data.table(t(colSums(
                              tab[, year_cols, with = FALSE]))))
  tab_out    <- rbind(tab, tab_total)
  tab_out[, (year_cols) := lapply(.SD, round, 1), .SDcols = year_cols]

  cat("\n  === Global AFOLU emissions (Tg CO2eq/yr) | filter:", cap_policy,
      "===\n")
  print(tab_out, row.names = FALSE)

  csv_path <- file.path(odir,
                        paste0("emis_co2eq_", cap_policy, ".csv"))
  fwrite(tab_out, csv_path)
  cat("  Table saved to:", csv_path, "\n")

  # ---- 7. Stacked bar plot -------------------------------------------------
  dt_ghg <- dt_glo[gwp > 0]
  dt_ghg[, label := POL_LABELS[pollutant]]
  dt_ghg[is.na(label), label := pollutant]

  label_order <- intersect(unname(POL_LABELS), unique(dt_ghg$label))
  dt_ghg[, label := factor(label, levels = label_order)]

  p <- ggplot(dt_ghg, aes(x = factor(year), y = co2eq, fill = label)) +
    geom_col(width = 0.75, colour = "white", linewidth = 0.2) +
    geom_hline(yintercept = 0, linewidth = 0.4, colour = "grey30") +
    scale_fill_manual(values = POL_COLOURS, name = NULL, drop = FALSE) +
    scale_y_continuous(
      labels = function(x) format(x, big.mark = ",", scientific = FALSE),
      expand = expansion(mult = c(0.05, 0.05))
    ) +
    labs(
      title    = paste0("Global AFOLU GHG emissions — ", basename(odir)),
      subtitle = paste0("AR5 GWP100  |  source filter: ", cap_policy,
                        "  |  ov_emissions_reg, all regions"),
      x        = "Year",
      y        = "Tg CO2eq / yr",
      caption  = gdx_path
    ) +
    theme_bw(base_size = 12) +
    theme(
      legend.position    = "bottom",
      legend.key.size    = unit(0.4, "cm"),
      axis.text.x        = element_text(angle = 45, hjust = 1),
      panel.grid.major.x = element_blank(),
      plot.caption       = element_text(size = 7, colour = "grey50")
    )

  png_path <- file.path(odir,
                        paste0("emis_co2eq_stacked_", cap_policy, ".png"))
  ggsave(png_path, p, width = 10, height = 6, dpi = 150)
  cat("  Plot saved to:", png_path, "\n")
}

cat("\nDone.\n")
