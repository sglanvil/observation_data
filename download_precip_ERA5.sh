#!/bin/bash
#PBS -N ERA5_grab
#PBS -A CESM0021 
#PBS -l select=1:ncpus=1:mem=100GB
#PBS -l walltime=06:00:00
#PBS -k eod
#PBS -j oe
#PBS -q casper
#PBS -m abe

# /glade/work/sglanvil/CCR/ERA5
# use /glade/work/sglanvil/CCR/ERA5/loop_ERA5.sh

module load nco

# ------------ ERA5 Data ------------ 
mkdir -p /glade/scratch/sglanvil/ERA5_precip/
cd /glade/scratch/sglanvil/ERA5_precip/
dir=/gpfs/fs1/collections/rda/data/ds633.0/e5.oper.fc.sfc.meanflux/ # two files per month (12-hourly data)
files=$(ls $dir/$iyear$imonth/*_mtpr.*nc)

for ifile in $files; do
        echo
        echo $ifile
        day1=$(echo $ifile | rev | cut -c 17-18 | rev)
        timeSteps=$(ncdump -h $ifile | grep currently | rev | cut -c 12-13 | rev)
        totalDays=$(($timeSteps/2))
        echo $timeSteps $totalDays $day1
        echo
        for ((iday=1;iday<=$totalDays;iday++)); do
                hour1=$(((10#$iday-1)*2))
                hour2=$(((10#$iday-1)*2+1))
                idayOUT=$(printf "%02d" $(($iday+$day1-1)))
                echo $idayOUT $hour1 $hour2
                ncra -O -d forecast_initial_time,$hour1,$hour2 $ifile ERA5_precip0_$iyear-$imonth-$idayOUT.nc
                ncks -O -3 ERA5_precip0_$iyear-$imonth-$idayOUT.nc ERA5_precip0_$iyear-$imonth-$idayOUT.nc
                ncwa -O -a forecast_hour -v MTPR ERA5_precip0_$iyear-$imonth-$idayOUT.nc ERA5_precip_$iyear-$imonth-$idayOUT.nc
                rm ERA5_precip0_$iyear-$imonth-$idayOUT.nc
        done
done

exit

