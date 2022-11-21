# run on casper
set -e

for iyear in {1999..2020}; do
        for imonth in {01..12}; do
                export iyear
                export imonth
                qsub -v iyear,imonth /glade/work/sglanvil/CCR/ERA5/ERA5grab.sh
        done
done
