## nzb_launch.R ================================================================
## Launch ONE Net-Zero-Brazil scenario, defined as a column in
## config/scenario_config_nzb.csv (FSEC-style base+delta), with the cap supplied
## at launch. Companion to the batch grid scripts/start/nzb_export_grid.R -- same
## families, but one run per call and driven by the CSV instead of R branching.
##
## INPUTS (env vars, or key=value CLI args):
##   scenario  (NZB_SCENARIO)  required. A column of scenario_config_nzb.csv:
##             gC_wdpa | gC_30by30 | gC_half | gA_RoW2C | gB_price | gF_freeze | g0_npi
##   target    (NZB_TARGET)    optional. Desired REPORTED AFOLU 2050 (GWP100AR6|Land, Mt CO2eq).
##             The script sets the emissions cap to  cap = target + OFFSET_MT  (see OFFSET
##             below) and enables the parametric ramp 2035->2050. This is the platform knob.
##   cap       (NZB_CAP)       optional. RAW emissions cap value (s56_emis_cap_target, Mt CO2eq),
##             set verbatim -- bypasses the offset. Reported AFOLU then comes out ~ cap - OFFSET_MT.
##   -> Give EITHER target OR cap (not both). Omit both -> the scenario's no-cap reference run.
##
## OFFSET (reported <-> cap). The cap bounds vm_emissions_reg, a SUPERSET of the reported
## GWP100AR6|Land AFOLU, so  reported ~ cap - OFFSET_MT  with OFFSET_MT = 63 Mt (median across
## families; ~+50 of it is the intact-peatland CH4+DOC slice the cap includes but the report
## excludes). Hence  cap = target + 63. The per-family spread is ~57-71 and the reachable-target
## range is per family -- see NZB_scenario_config_approach.md. Retune via OFFSET_MT below.
##
## INPUT DATA -- the BRA input tarballs are read from a local folder OUTSIDE the model
## root (default: sibling ../BRA_input_data; override with NZB_INPUT_DIR), which this
## script prepends to cfg$repositories. From that folder MAgPIE provisions everything on
## the first launch -- it unpacks the input AND writes the BRA region into core/sets.gms /
## main.gms -- so no separate data step is needed. renv is initialised by start.R's fixDeps
## (see LAUNCH), which is why the start.R route is the safe one.
##
## LAUNCH (recommended) -- go via start.R so it runs piamenv::fixDeps() first, which
## initialises / repairs this checkout's renv (the safe path, esp. on a fresh checkout).
## start.R auto-detects the NZB launch (a scenario=/runscripts=nzb_launch CLI arg, or the
## NZB_SCENARIO env var) and SKIPS its interactive "Update now? (Y/n)" renv prompt WITHOUT
## force-updating packages; pass submit=direct so it does not prompt for a submission type
## either. Fully non-interactive.
##
## Pass scenario + target/cap as R CLI args (needs submit=direct -- args reach the runscript
## only via start.R's in-process source):
##     Rscript start.R runscripts=nzb_launch submit=direct scenario=gF_freeze target=-100
##     Rscript start.R runscripts=nzb_launch submit=direct scenario=gF_freeze cap=-37   # raw cap
##     Rscript start.R runscripts=nzb_launch submit=direct scenario=g0_npi              # no cap -> ref
##
## ...or as NZB_* env vars, which ALSO work with background/SLURM submit modes (a spawned
## Rscript inherits env vars but drops CLI args):
##     NZB_SCENARIO=gF_freeze NZB_TARGET=-100 Rscript start.R runscripts=nzb_launch submit=direct
##   (To force non-interactive without an NZB launch, set NZB_NONINTERACTIVE=TRUE.)
##
## ALTERNATIVE -- run this script DIRECTLY (bypasses start.R AND its fixDeps). Skips the
## renv prompt too, but does NOT initialise renv -- only safe once renv is already set up
## in this checkout. CLI args also work here.
##     NZB_SCENARIO=gF_freeze NZB_TARGET=-100 Rscript scripts/start/nzb_launch.R
##     Rscript scripts/start/nzb_launch.R scenario=gF_freeze target=-100
##
## The CSV is the scenario registry; a platform edits/adds columns or just picks a
## column + cap. No config text is generated as code -> nothing to mis-template.
## ============================================================================
library(lucode2); library(gms); library(magpie4)
source("config/default.cfg"); source("scripts/start_functions.R")

SCEN_CSV <- "config/scenario_config_nzb.csv"

# ---- read launch args (CLI key=value first, else NZB_* env) -------------------------
.args <- commandArgs(trailingOnly = TRUE)
getarg <- function(key) {
  hit <- grep(paste0("^", key, "="), .args, value = TRUE)
  if (length(hit)) return(sub(paste0("^", key, "="), "", hit[1]))
  e <- Sys.getenv(paste0("NZB_", toupper(key)), ""); if (nzchar(e)) e else NA_character_
}
scenario   <- getarg("scenario")
target_raw <- getarg("target")
cap_raw    <- getarg("cap")
have <- function(x) !is.na(x) && nzchar(x)

valid <- setdiff(colnames(read.csv2(SCEN_CSV, check.names = FALSE, nrows = 1))[-1], c("", "nzb_base"))
if (is.na(scenario))
  stop("nzb_launch: no scenario given. Set NZB_SCENARIO=<col> (or scenario=<col>).\n",
       "  columns: ", paste(valid, collapse = ", "))
if (!scenario %in% valid)
  stop("nzb_launch: scenario '", scenario, "' is not a column of ", SCEN_CSV, ".\n",
       "  columns: ", paste(valid, collapse = ", "))

# ---- resolve the scenario: nocc (native) + nzb_base + the chosen family -------------
# setScenario is MAgPIE's central scenario mechanism (base+delta overlay, as in FSEC),
# so the whole NZB registry rides it. One wrinkle: setScenario splits any comma-bearing
# cell into a character VECTOR -- here the list-valued GAMS *set* switch forcesuff21 (a
# subset of k_trade). A vector serialises to a valid GAMS set list via manipulateConfig
# (exactly like the ~249-element policy_countries* sets), so the MODEL is fine either
# way. But setScenario's own scalar re-comparison `if (from != to & to != "")` of an
# already-vectorised value on a SECOND overlaid column errors ("the condition has length
# > 1"). So we overlay the columns ONE AT A TIME and collapse forcesuff21 back to the
# single comma-string that default.cfg / nzb_export_grid.R use, after each call. The
# collapse round-trips the cell verbatim ('a, b' -> c('a',' b') -> 'a, b') and is a
# no-op when the family cell is empty (forcesuff21 already a length-1 string from base).
cfg <- setScenario(cfg, "nocc")                                    # native climate-off scenario
for (col in c("nzb_base", scenario)) {
  cfg <- setScenario(cfg, col, scenario_config = SCEN_CSV)         # scalar deltas overlaid natively
  cfg$gms$forcesuff21 <- paste(cfg$gms$forcesuff21, collapse = ",") # comma-list switch: vector -> single string
}

# ---- common run settings (not policy levers; same for every NZB run) ----------------
cfg$input <- c(regional    = "rev4.131.9001BRA_H13_C200_W3_MapbiomasIBGE_5638d5dc_magpie.tgz",
               cellular    = "rev4.131.9001BRA_H13_C200_W3_MapbiomasIBGE_5638d5dc_d8411e75_cellularmagpie_c200_MRI-ESM2-0-ssp245_lpjml-8e6c5eb1_clusterweight-d0236589.tgz",
               validation  = "rev4.131.9001BRA_H13_C200_W3_MapbiomasIBGE_5638d5dc_92e02314_validation.tgz",
               additional  = "additional_data_rev4.65.tgz",
               calibration = "calibration_BRA_H13_C200_W3_MapbiomasIBGE_18Jun26.tgz")
cfg$force_download <- FALSE; cfg$force_replace <- TRUE
cfg$recalibrate <- FALSE; cfg$recalibrate_landconversion_cost <- FALSE
cfg$output <- c("rds_report"); cfg$results_folder <- "output/:title:"
# sequential = TRUE -> start_run runs GAMS in the FOREGROUND (system("Rscript submit.R",
# wait = TRUE)). This is a single-run launcher, so there is nothing to parallelise; and the
# background variant (sequential = FALSE -> system(wait = FALSE)) detaches poorly on Windows
# -- the GAMS child is killed when this R session exits, so the run stops right after prep
# (NPI/NDC calc) with no full.lst / full.log. Foreground is cross-platform.
cfg$sequential <- TRUE

# ---- local input-data repository -----------------------------------------------------
# Read the BRA input tarballs from a local folder OUTSIDE the model root, so several
# checkouts can share one copy and no remote download is needed at run time. The folder is
# prepended to cfg$repositories, so download_distribute finds every tarball there first and
# the repo loop stops as soon as all files are found. Default: sibling ../BRA_input_data;
# override with the NZB_INPUT_DIR env var. If the folder is absent, the default
# repositories are used.
inputRepo <- Sys.getenv("NZB_INPUT_DIR", unset = "")
if (!nzchar(inputRepo)) inputRepo <- file.path(dirname(normalizePath(".")), "BRA_input_data")
if (dir.exists(inputRepo)) {
  cfg$repositories <- c(stats::setNames(list(NULL), normalizePath(inputRepo)), cfg$repositories)
  message("nzb_launch: local input repository checked first: ", normalizePath(inputRepo))
} else {
  message("nzb_launch: no local input repo at '", inputRepo,
          "' -- using the default repositories.")
}

# ---- cap: from a reported-AFOLU target (cap = target + OFFSET_MT) or a raw cap value ------
# OFFSET_MT is the reported<->cap offset (see header): reported GWP100AR6|Land AFOLU ~ cap -
# OFFSET_MT, so cap = target_reported + OFFSET_MT. +63 Mt = median across families (~+50 is the
# intact-peatland CH4+DOC slice the cap includes but the report excludes). Retune here if needed.
OFFSET_MT <- 63

if (have(target_raw) && have(cap_raw))
  stop("nzb_launch: give EITHER target= (reported AFOLU) OR cap= (raw s56_emis_cap_target), not both.")

cap <- NA_real_; from_target <- FALSE
if (have(target_raw)) {
  target <- suppressWarnings(as.numeric(target_raw))
  if (!is.finite(target)) stop("nzb_launch: target='", target_raw, "' is not a number.")
  cap <- target + OFFSET_MT; from_target <- TRUE
  message(sprintf("nzb_launch: reported-AFOLU target %+g Mt -> cap %+g Mt (offset +%g)",
                  target, cap, OFFSET_MT))
} else if (have(cap_raw)) {
  cap <- suppressWarnings(as.numeric(cap_raw))
  if (!is.finite(cap)) stop("nzb_launch: cap='", cap_raw, "' is not a number.")
}

if (is.finite(cap)) {
  if (cap < -300 || cap > 600)
    warning("nzb_launch: cap ", cap, " Mt is outside the tested band [-300, 600]; ",
            "may be infeasible (on-slack) or non-binding. See the per-family reach table.")
  cfg$gms$s56_emis_cap_parametric  <- 1
  cfg$gms$s56_emis_cap_start_year  <- 2035
  cfg$gms$s56_emis_cap_start_value <- 600
  cfg$gms$s56_emis_cap_target_year <- 2050
  cfg$gms$s56_emis_cap_target      <- cap
  cfg$title <- sprintf("nzb_%s_%s", scenario,
    if (from_target) sprintf("tgt%s%d", if (target < 0) "M" else "P", abs(round(target)))
    else             sprintf("cap%s%d", if (cap    < 0) "M" else "P", abs(round(cap))))
} else {
  # neither target nor cap: honour whatever the CSV/default set (parametric off = ref run)
  cfg$title <- if (isTRUE(cfg$gms$s56_emis_cap_parametric == 1))
                 sprintf("nzb_%s_capCSV", scenario) else sprintf("nzb_%s_ref", scenario)
}

message("nzb_launch: scenario=", scenario, "  title=", cfg$title,
        "  cap=", if (is.finite(cap)) cap else "(none/ref)")
start_run(cfg, codeCheck = FALSE)
