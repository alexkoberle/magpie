## create_cap_scenario_dt.R --------------------------------------------------
## Reads f56_emis_cap.cs3 into a data.table, lets you modify values for
## specific regions/years, then passes the result to add_cap_scenario().
##
## Run from the project root.
## ---------------------------------------------------------------------------

library(magclass)
library(data.table)
source("add_cap_scenario.R")

CS3_FILE_IN  <- "f56_emis_cap_reg_H13_template.cs3"
CS3_FILE_OUT  <- "f56_emis_cap_reg.cs3"
SCEN_NAME <- "user_scen"   # must match an entry you will add to capscen56

# ---- 1. Read ----------------------------------------------------------------
x <- read.magpie(CS3_FILE_IN)
write.magpie(x, CS3_FILE_OUT, col.names = TRUE)

# ---- 2. Convert to data.table (via as.data.frame to avoid NA column issue) -
# as.data.table(x) directly fails because the value column is unnamed.
# Going through as.data.frame(rev=TRUE) gives properly named columns first.
df <- as.data.frame(x[, , "none"], rev = TRUE)

# as.data.frame(rev=TRUE) column order: Cell, Region, Year, Data1, value
# Rename positionally — last col = value, second-to-last = scenario/data dim
nc <- ncol(df)
names(df)[nc]     <- "value"
names(df)[nc - 1] <- "scenario"
names(df)[nc - 2] <- "year"
names(df)[nc - 3] <- "region"

# Convert, drop Cell column, ensure character (not factor)
dt <- as.data.table(df)[, .(
  year   = as.character(year),
  region = as.character(region),
  value  = as.numeric(value)
)]

cat("Loaded", nrow(dt), "rows —",
    uniqueN(dt$year), "years x", uniqueN(dt$region), "regions\n")
cat("Regions:", paste(sort(unique(dt$region)), collapse = ", "), "\n")

# ---- 3. Inspect BRA rows ----------------------------------------------------
cat("\nBRA rows (first 5):\n")
print(dt[region == "BRA"][1:5])

# ---- 4. Create new scenario — start from non-binding template --------------
dt_new <- copy(dt)                 # all regions, all years, value = 1e6

# Modify BRA: read desired cap trajectory from CSV, units in Tg CO2eq per yr
# Change filename of CSV for platform use as needed
bra_caps <- fread("bra_emissions_path_2050_cap0.csv", sep=",")


# dt_new[region == "BRA", value := bra_caps$value[match(year, bra_caps$year)]]
dt_new[region == "BRA", value := bra_caps$value[match(year, bra_caps$year)]]

# Any NA values (years in dt not in bra_caps) stay 1e6 — restore them
# dt_new[region == "BRA" & is.na(value), value := 1e6]
dt_new[region == "BRA" & is.na(value), value := 1e6]

cat("\nBRA rows after modification:\n")
print(dt_new[region == "BRA"])

# ---- 5. Dry run — inspect without writing -----------------------------------
result <- add_cap_scenario(
  scen_name = SCEN_NAME,
  scen_dt   = dt_new,
  cs3_file  = CS3_FILE_OUT,   ### To write the new file directly to input folder, use "paste0(../modules/56_ghg_policy/cap_apr26_reg/input/", CS3_FILE_OUT)"
  dry_run   = FALSE
)

# Spot-check: BRA values in the new scenario should reflect your trajectory
cat("\nBRA in new scenario (spot-check):\n")
yrs_sel   <- getYears(result)[getYears(result, as.integer = TRUE) >= 2025 &
                                getYears(result, as.integer = TRUE) <= 2050]
bra_check <- as.data.frame(result["BRA", yrs_sel, ], rev = TRUE)
print(bra_check)

# ---- 6. Write when satisfied ------------------------------------------------
# Uncomment when the values look correct:
# add_cap_scenario(SCEN_NAME, scen_dt = dt_new, cs3_file = CS3_FILE_OUT, dry_run = FALSE)

# ---- 7. Register in sets.gms ------------------------------------------------
# After writing, add the scenario name to capscen56 in:
#   modules/56_ghg_policy/cap_apr26_reg/sets.gms
#
#   capscen56 / none, user_scen /
#
# Then activate in your start script:
#   cfg$gms$c56_emis_cap_scenario <- "user_scen"
