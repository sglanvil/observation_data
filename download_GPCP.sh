#!/bin/bash

# /glade/scratch/sglanvil/GPCP_yaga

for iyear in {1999..2021}; do
        wget -r -l1 --no-parent -A.nc https://www.ncei.noaa.gov/data/global-precipitation-climatology-project-gpcp-daily/access/${iyear}/
done

for iyear in {1999..2021}; do
        echo ${iyear}
        mv /glade/scratch/sglanvil/GPCP_yaga/www.ncei.noaa.gov/data/global-precipitation-climatology-project-gpcp-daily/access/${iyear}/* /glade/scratch/sglanvil/GPCP_yaga/
done

# Do this by hand.
# NOTE: there are 3 files that are corrupt (they are very small, and they have duplicates with different creation dates)
# Find them, and remove them.
# ls -Srql * | head -10
# rm gpcp_v01r03_daily_d20180401_c20180712.nc gpcp_v01r03_daily_d20171101_c20180207.nc gpcp_v01r03_daily_d20170801_c20171107.nc

