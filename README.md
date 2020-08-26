# SafeGraphCompareDashboard
Compare Two Locations or Location Sets on their SafeGraph Foot Traffic - Example Using Houston

This repo includes:

1. (create_example_dashboard_data.R) Processing SafeGraph Core and Monthly Patterns files so as to create county-specific files for CBG information, location information, and visit information. Requires an `ncodes.Rdata` `data.table` object created with `SafeGraphR::naics_link` from the Core file.
1. The results of that code run for Harris County, Texas (which includes Houston). `houston_cbg.Rdata`, `houston_loc.Rdata`, and `houston_vis.Rdata`
1. `houstonmap.Rdata`, which is Harris county shapefile (and other) data, created from `tigris::block_groups(cb = TRUE)` set to Harris County in Texas, and then immediately saved to file with `saveRDS()`
1. `houston_dash_example.RMD` which contains the code for the dashboard, which can be seen at 
