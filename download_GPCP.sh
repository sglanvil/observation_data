#!/bin/bash

# /glade/scratch/sglanvil/GPCP_yaga

for iyear in {1999..2020}; do
        wget -r -l1 --no-parent -A.nc https://www.ncei.noaa.gov/data/global-precipitation-climatology-project-gpcp-daily/access/${iyear}/
done

for iyear in {1999..2020}; do
        echo ${iyear}
        mv /glade/scratch/sglanvil/GPCP_yaga/www.ncei.noaa.gov/data/global-precipitation-climatology-project-gpcp-daily/access/${iyear}/* /glade/scratch/sglanvil/GPCP_yaga/
done
