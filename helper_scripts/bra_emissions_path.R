# Brazil GHG emissions trajectory toward a target cap
# Linear interpolation from 2025 base value to a user-defined cap reached in
# 2040, 2045 or 2050; held constant thereafter through 2150.
# Units: Mt CO2eq / yr. 5-year MAgPIE timesteps.

# Author: Alexandre Köberle

library(data.table)

# Historical anchors (Mt CO2eq/yr)
hist_2020 <- 1490
hist_2025 <- 1440

# --- User input ----------------------------------------------------------
target_cap <- suppressWarnings(as.numeric(
  readline("Target emissions cap (Mt CO2eq/yr): ")
))
if (is.na(target_cap)) stop("Target cap must be numeric.")

valid_years <- c(2040L, 2045L, 2050L)
repeat {
  target_year <- suppressWarnings(as.integer(
    readline("Target year (2040, 2045, or 2050): ")
  ))
  if (!is.na(target_year) && target_year %in% valid_years) break
  message("Invalid year. Choose one of: ", paste(valid_years, collapse = ", "))
}

# --- Build trajectory ----------------------------------------------------
years <- seq(2020L, 2150L, by = 5L)

value <- vapply(years, function(y) {
  if (y == 2020L) {
    hist_2020
  } else if (y <= 2025L) {
    hist_2025
  } else if (y <= target_year) {
    hist_2025 + (target_cap - hist_2025) * (y - 2025) / (target_year - 2025)
  } else {
    target_cap
  }
}, numeric(1))

dt <- data.table(year = years, value = value)

# --- Write outputs -------------------------------------------------------
out_base <- sprintf("bra_emissions_path_%d_cap%g", target_year, target_cap)
csv_path <- paste0(out_base, ".csv")
rds_path <- paste0(out_base, ".rds")

fwrite(dt, csv_path)
saveRDS(dt, rds_path)

cat(sprintf("Wrote %s and %s\n", csv_path, rds_path))
print(dt)
