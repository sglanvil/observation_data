# run on casper
set -e

# /glade/work/sglanvil/CCR/ERA5

for iyear in {1999..2020}; do
        for imonth in {01..12}; do
                export iyear
                export imonth
                qsub -v iyear,imonth /glade/work/sglanvil/CCR/ERA5/download_ERA5.sh
        done
done
