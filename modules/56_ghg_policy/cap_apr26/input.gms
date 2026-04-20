*** |  (C) 2008-2025 Potsdam Institute for Climate Impact Research (PIK)
*** |  authors, and contributors see CITATION.cff file. This file is part
*** |  of MAgPIE and licensed under AGPL-3.0-or-later. Under Section 7 of
*** |  AGPL-3.0, you are granted additional permissions described in the
*** |  MAgPIE License Exception, version 1.0 (see LICENSE file).
*** |  Contact: magpie@pik-potsdam.de

* Country sets for the inherited pricing infrastructure.
* cap_apr26 defaults to applying the cap globally (all iso countries),
* matching the default behaviour of policy_countries56 = all_iso_countries.
* The sets are defined as subsets of iso containing all elements; preloop then
* sets p56_region_price_shr = 1 for all regions automatically.
sets
  policy_countries56(iso) countries affected by ghg policy / ABW,AFG,AGO,AIA,ALA,ALB,AND,ARE,ARG,ARM,
                      ASM,ATA,ATF,ATG,AUS,AUT,AZE,BDI,BEL,BEN,
                      BES,BFA,BGD,BGR,BHR,BHS,BIH,BLM,BLR,BLZ,
                      BMU,BOL,BRA,BRB,BRN,BTN,BVT,BWA,CAF,CAN,
                      CCK,CHN,CHE,CHL,CIV,CMR,COD,COG,COK,COL,
                      COM,CPV,CRI,CUB,CUW,CXR,CYM,CYP,CZE,DEU,
                      DJI,DMA,DNK,DOM,DZA,ECU,EGY,ERI,ESH,ESP,
                      EST,ETH,FIN,FJI,FLK,FRA,FRO,FSM,GAB,GBR,
                      GEO,GGY,GHA,GIB,GIN,GLP,GMB,GNB,GNQ,GRC,
                      GRD,GRL,GTM,GUF,GUM,GUY,HKG,HMD,HND,HRV,
                      HTI,HUN,IDN,IMN,IND,IOT,IRL,IRN,IRQ,ISL,
                      ISR,ITA,JAM,JEY,JOR,JPN,KAZ,KEN,KGZ,KHM,
                      KIR,KNA,KOR,KWT,LAO,LBN,LBR,LBY,LCA,LIE,
                      LKA,LSO,LTU,LUX,LVA,MAC,MAF,MAR,MCO,MDA,
                      MDG,MDV,MEX,MHL,MKD,MLI,MLT,MMR,MNE,MNG,
                      MNP,MOZ,MRT,MSR,MTQ,MUS,MWI,MYS,MYT,NAM,
                      NCL,NER,NFK,NGA,NIC,NIU,NLD,NOR,NPL,NRU,
                      NZL,OMN,PAK,PAN,PCN,PER,PHL,PLW,PNG,POL,
                      PRI,PRK,PRT,PRY,PSE,PYF,QAT,REU,ROU,RUS,
                      RWA,SAU,SDN,SEN,SGP,SGS,SHN,SJM,SLB,SLE,
                      SLV,SMR,SOM,SPM,SRB,SSD,STP,SUR,SVK,SVN,
                      SWE,SWZ,SXM,SYC,SYR,TCA,TCD,TGO,THA,TJK,
                      TKL,TKM,TLS,TON,TTO,TUN,TUR,TUV,TWN,TZA,
                      UGA,UKR,UMI,URY,USA,UZB,VAT,VCT,VEN,VGB,
                      VIR,VNM,VUT,WLF,WSM,YEM,ZAF,ZMB,ZWE /
  fader_countries56(iso)  countries affected by ghg policy fader / ABW,AFG,AGO,AIA,ALA,AND,ARE,ARG,ARM,ASM,ATA,
                      ATF,ATG,AZE,BDI,BEN,BES,BFA,BGD,BHR,BHS,BLM,
                      BLR,BLZ,BMU,BOL,BRA,BRB,BRN,BTN,BVT,BWA,CAF,
                      CCK,CHN,CHL,CIV,CMR,COD,COG,COK,COL,COM,CPV,
                      CRI,CUB,CUW,CXR,CYM,DJI,DMA,DOM,DZA,ECU,EGY,
                      ERI,ESH,ETH,FJI,FLK,FRO,FSM,GAB,GEO,GGY,GHA,
                      GIB,GIN,GLP,GMB,GNB,GNQ,GRD,GRL,GTM,GUF,GUM,
                      GUY,HKG,HMD,HND,HTI,IDN,IMN,IND,IOT,IRN,IRQ,
                      ISR,JAM,JEY,JOR,KAZ,KEN,KGZ,KHM,KIR,KNA,KOR,
                      KWT,LAO,LBN,LBR,LBY,LCA,LIE,LKA,LSO,MAC,MAF,
                      MAR,MCO,MDA,MDG,MDV,MEX,MHL,MLI,MMR,MNG,MNP,
                      MOZ,MRT,MSR,MTQ,MUS,MWI,MYS,MYT,NAM,NCL,NER,
                      NFK,NGA,NIC,NIU,NPL,NRU,OMN,PAK,PAN,PCN,PER,
                      PHL,PLW,PNG,PRI,PRK,PRY,PSE,PYF,QAT,REU,RUS,
                      RWA,SAU,SDN,SEN,SGP,SGS,SHN,SJM,SLB,SLE,SLV,
                      SMR,SOM,SPM,SSD,STP,SUR,SWZ,SXM,SYC,SYR,TCA,
                      TCD,TGO,THA,TJK,TKL,TKM,TLS,TON,TTO,TUN,TUV,
                      TWN,TZA,UGA,UKR,UMI,URY,UZB,VAT,VCT,VEN,VGB,
                      VIR,VNM,VUT,WLF,WSM,YEM,ZAF,ZMB,ZWE /
  pollutants_fader(pollutants) pollutants affected by GHG policy fader
    / co2_c, ch4, n2o_n_direct, n2o_n_indirect, nh3_n, no2_n, no3_n /
;

scalars
  s56_limit_ch4_n2o_price         Upper limit for CH4 and N2O GHG prices (USD17MER per tC) / 4920 /
  s56_cprice_red_factor           Reduction factor for CO2 price (-) / 1 /
* Default minimum C price is 0 in cap mode (pure quantity instrument)
  s56_minimum_cprice              Minimum C price (USD17MER per tC) / 3.67 /
  s56_ghgprice_devstate_scaling   Switch for scaling GHG price with development state / 0 /
* Afforestation reward disabled by default in cap mode (option ii from audit)
  s56_c_price_induced_aff         Switch for C price driven re-afforestation (1=on 0=off) / 1 /
  s56_c_price_exp_aff             Time horizon of CO2 price expectation for re-afforestation (yr) / 50 /
  s56_buffer_aff                  Share of C credits pooled in buffer (1) / 0.5 /
  s56_counter                     Counter for C price interpolation (1) / 0 /
  s56_timesteps                   Number of time steps for C price interpolation (1) / 0 /
  s56_offset                      Helper for C price interpolation (1) / 0 /
  s56_ghgprice_fader              Switch for GHG policy fader (1=on 0=off) / 0 /
  s56_fader_start                 Start year of GHG policy fade-in (1) / 2035 /
  s56_fader_end                   End year of GHG policy fade-in (1) / 2050 /
  s56_fader_target                Target value of GHG policy fade-in in end year / 1 /
  s56_fader_functional_form       Switch for functional form of fader (1=linear 2=sigmoid) / 1 /
  s56_fader_cpriceaff_start       Start year of C price induced afforestation fade-in (1) / 2030 /
  s56_fader_cpriceaff_end         End year of C price induced afforestation fade-in (1) / 2030 /
* ---- cap_apr26 specific scalars ----
  s56_emis_cap_start    First year the emissions cap is binding (yr) / 2025 /
  s56_emis_cap_penalty  Penalty cost for slack (mio USD17MER per Tg CO2eq per yr) / 1e+05 /
  s56_source_bounds_on  Switch for Archetype A source-specific bounds (1=on 0=off) / 0 /
;

$setglobal c56_pollutant_prices          none
$setglobal c56_pollutant_prices_noselect R34M410-SSP2-NPi2025
$setglobal c56_emis_policy               reddnatveg_nosoil
$setglobal c56_cap_policy                all_nosoil
$setglobal c56_cprice_aff                secdforest_vegc
$setglobal c56_mute_ghgprices_until      y2150
$setglobal c56_carbon_stock_pricing      actualNoAcEst
$setglobal c56_emis_cap_scenario         test_tight

* Pricing tables — used only when c56_pollutant_prices is not "none"
table f56_pollutant_prices(t_all,i,pollutants,ghgscen56) GHG certificate prices (USD17MER per t)
$ondelim
$include "./modules/56_ghg_policy/input/f56_pollutant_prices.cs3"
$offdelim
;

* Emission policy mask: 1 = included, 0 = excluded
* Used for pricing scope AND as template for p56_cap_mask in preloop
table f56_emis_policy(scen56,pollutants_all,emis_source) GHG emission policy scenarios (1)
$ondelim
$include "./modules/56_ghg_policy/input/f56_emis_policy.csv"
$offdelim
;

* ---- Emissions cap (Archetype B) ----
*' Scenario "none" = non-binding (1e6 Tg CO2eq/yr).
*' Add project-specific scenario columns; register names in capscen56 (sets.gms).
table f56_emis_cap(t_all,capscen56) Global AFOLU emissions cap (Tg CO2eq per yr)
$ondelim
$include "./modules/56_ghg_policy/cap_apr26/input/f56_emis_cap.csv"
$offdelim
;

* ---- Source-specific bounds (Archetype A overlay) ----
*' Empty by default. preloop.gms sets all entries to 1e6 (non-binding).
*' Activate with s56_source_bounds_on=1 and populate the file.
$onEmpty
table f56_source_bound(t_all,i,emis_source) Source-specific emission upper bounds (Tg per yr)
$ondelim
$include "./modules/56_ghg_policy/cap_apr26/input/f56_source_bound.cs3"
$offdelim
;
$offEmpty
