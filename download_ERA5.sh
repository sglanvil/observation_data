#!/bin/bash
#PBS -N ERA5_grab
#PBS -A CESM0021 
#PBS -l select=1:ncpus=1:mem=100GB
#PBS -l walltime=06:00:00
#PBS -k eod
#PBS -j oe
#PBS -q casper
#PBS -m abe

# script: /glade/work/sglanvil/CCR/ERA5

module load nco
module load ncl

# ------------ ERA5 Data ------------ 
mkdir -p /glade/scratch/sglanvil/ERA5_yaga
cd /glade/scratch/sglanvil/ERA5_yaga
dir=/gpfs/fs1/collections/rda/data/ds633.0/e5.oper.an.sfc/ # one file per month (hourly data)

ifile=$(ls $dir/$iyear$imonth/*_2t.*nc)
endDay=$(echo $ifile | rev | cut -c 6-7 | rev)

echo $iyear $imonth $endDay
echo 
echo $ifile
echo 

for ((iday=1;iday<=$endDay;iday++)); do
        hour1=$(((10#$iday-1)*24))
        hour2=$(((10#$iday-1)*24+23))
        idayOUT=$(printf "%02d" $iday)
        echo $idayOUT $hour1 $hour2
        rm ERA5_$iyear-$imonth-$idayOUT.nc 2> /dev/null
        ncra -d time,$hour1,$hour2 $ifile ERA5_$iyear-$imonth-$idayOUT.nc
done

exit
