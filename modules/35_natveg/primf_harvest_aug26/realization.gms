*** |  (C) 2008-2025 Potsdam Institute for Climate Impact Research (PIK)
*** |  authors, and contributors see CITATION.cff file. This file is part
*** |  of MAgPIE and licensed under AGPL-3.0-or-later. Under Section 7 of
*** |  AGPL-3.0, you are granted additional permissions described in the
*** |  MAgPIE License Exception, version 1.0 (see LICENSE file).
*** |  Contact: magpie@pik-potsdam.de

*' @description primf_harvest_aug26 extends pot_forest_may24 with a second, region-gated
*' pathway for primary forest loss: `v35_clearcut_primforest`. Where pot_forest_may24 forces
*' every harvested hectare of primary forest to be reclassified as secondary forest
*' (`q35_secdforest_regeneration`), this realization lets primary forest that is directly
*' deforested (converted to agricultural or other non-forest land, via `vm_lu_transitions`
*' in [10_land]) also earn wood-harvest revenue, discounted by a regional recovery-share
*' parameter reflecting that clear-cut salvage is less complete than selective logging.
*' The new pathway is fixed to zero outside `policy_countries35_clearcut` (default: BRA),
*' so the realization is a no-op everywhere it is not explicitly switched on.
*'
*' All other behavior — land and carbon stock dynamics, NPI/NDC forest and other-land
*' protection, forest damage, selective-harvest timber production — is inherited unchanged
*' from pot_forest_may24; see that realization's documentation for details.
*'
*' @limitations Same limitations as pot_forest_may24. Additionally: the clear-cut wood
*' recovery share and harvest cost are regional (i-indexed), not cluster-level — they
*' cannot yet be calibrated against cluster-level historical deforestation observations
*' (a target-array mechanism analogous to `calib_cluster_crop_past`'s `f39_calib_cluster.csv`
*' is a planned follow-up, not yet implemented). Clear-cut wood uses the same
*' roundwood/woodfuel product mix as selectively harvested wood; this is a simplification
*' pending further refinement once the basic mechanism's sensitivity is understood.

*####################### R SECTION START (PHASES) ##############################
$Ifi "%phase%" == "sets" $include "./modules/35_natveg/primf_harvest_aug26/sets.gms"
$Ifi "%phase%" == "declarations" $include "./modules/35_natveg/primf_harvest_aug26/declarations.gms"
$Ifi "%phase%" == "input" $include "./modules/35_natveg/primf_harvest_aug26/input.gms"
$Ifi "%phase%" == "equations" $include "./modules/35_natveg/primf_harvest_aug26/equations.gms"
$Ifi "%phase%" == "scaling" $include "./modules/35_natveg/primf_harvest_aug26/scaling.gms"
$Ifi "%phase%" == "preloop" $include "./modules/35_natveg/primf_harvest_aug26/preloop.gms"
$Ifi "%phase%" == "presolve" $include "./modules/35_natveg/primf_harvest_aug26/presolve.gms"
$Ifi "%phase%" == "postsolve" $include "./modules/35_natveg/primf_harvest_aug26/postsolve.gms"
*######################## R SECTION END (PHASES) ###############################
