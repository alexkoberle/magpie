*** |  (C) 2008-2025 Potsdam Institute for Climate Impact Research (PIK)
*** |  authors, and contributors see CITATION.cff file. This file is part
*** |  of MAgPIE and licensed under AGPL-3.0-or-later. Under Section 7 of
*** |  AGPL-3.0, you are granted additional permissions described in the
*** |  MAgPIE License Exception, version 1.0 (see LICENSE file).
*** |  Contact: magpie@pik-potsdam.de

* ---- cap_apr26: Archetype A source-specific upper bounds (presolve) ----
*' Each timestep, reset vm_emissions_reg.up to +INF so no stale bound from the
*' previous iteration persists. If s56_source_bounds_on=1, tighten the upper
*' bound for every (i, emis_source) pair where f56_source_bound holds an
*' explicitly set value (< 1e5 Tg/yr). The bound is applied uniformly across
*' all pollutants of the source; for single-pollutant sources (e.g. co2_c from
*' deforestation, ch4 from enteric fermentation) this is exact. The sum across
*' pollutants for multi-pollutant sources is therefore conservative.

vm_emissions_reg.up(i,emis_source,pollutants) = +INF;

if (s56_source_bounds_on = 1,
  vm_emissions_reg.up(i,emis_source,pollutants)$(
    sum(ct, f56_source_bound(ct,i,emis_source)) < 1e5) =
      sum(ct, f56_source_bound(ct,i,emis_source));
);
