#!/bin/bash

# /glade/scratch/sglanvil/ERA5_precip/interp/

module load nco

for ifile in *.nc; do
        echo ${ifile}
        ncks --mk_rec_dmn time -O ${ifile} unlim_${ifile}
done

ncrcat -O unlim_*.nc pr_sfc_ERA5_19990101-20211231.nc
