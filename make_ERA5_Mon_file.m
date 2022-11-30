% November 29, 2022

clear; clc; close all;

srcFolder='/glade/scratch/sglanvil/ERA5_yaga/';
srcVar='VAR_2T';
destFolder='/glade/scratch/sglanvil/ERA5_yaga/interp/';
destVar='tas_2m';

lon=0:359;
lat=-90:90;
[xNew,yNew]=meshgrid(lon,lat);

% ----------------------- loop and interpolate -----------------------
filePattern=fullfile(srcFolder,'*.nc'); 
files=dir(filePattern);
for k=1 %s:length(files)
    baseFileName=files(k).name;
    fullFileName=fullfile(files(k).folder,baseFileName);
    fprintf(1,'Now reading %s\n',fullFileName);
    varOBS=ncread(fullFileName,srcVar);
    lonOBS=ncread(fullFileName,'longitude'); % NOTE: check naming
    latOBS=ncread(fullFileName,'latitude'); % NOTE: check naming
    timeOBS=ncread(fullFileName,'time'); % NOTE: check existence/format
    [x,y]=meshgrid(lonOBS,latOBS);
    varOUT=interp2(x,y,varOBS',xNew,yNew,'linear');
    % ----------------------- save at netcdf -----------------------
    ncSave=sprintf('%s/%s',destFolder,baseFileName);
    fprintf(1,'--->Saving as %s\n',ncSave);
    ncid=netcdf.create(ncSave,'NC_WRITE');
    dimidlon = netcdf.defDim(ncid,'lon',length(lon));
    dimidlat = netcdf.defDim(ncid,'lat',length(lat));
    dimidtime = netcdf.defDim(ncid,'time',length(timeOBS));
    lon_ID=netcdf.defVar(ncid,'lon','float',[dimidlon]);
    lat_ID=netcdf.defVar(ncid,'lat','float',[dimidlat]);
    time_ID=netcdf.defVar(ncid,'time','float',[dimidtime]);
    var_ID=netcdf.defVar(ncid,destVar,'float',[dimidlon dimidlat dimidtime]);
    netcdf.endDef(ncid);
    netcdf.putVar(ncid,lat_ID,lat);
    netcdf.putVar(ncid,lon_ID,lon);
    netcdf.putVar(ncid,time_ID,timeOBS);
    netcdf.putVar(ncid,var_ID,varOUT);
    netcdf.close(ncid)
end

% ----------------------- bash/nco: make unlim & ncrcat -----------------------
% run: /glade/scratch/sglanvil/ERA5_yaga/interp/make_time_unlimited.sh
% create: glade/scratch/sglanvil/ERA5_yaga/interp/ERA5_19990101-20211231.nc

%% ----------------------- make smooth clim -----------------------
clear; clc; close all;
file='/glade/scratch/sglanvil/ERA5_yaga/interp/ERA5_19990101-20211231.nc';
var=ncread(file,'tas_2m');
lon=ncread(file,'lon');
lat=ncread(file,'lat');
t1=datetime('1/Jan/1999'); 
t2=datetime('31/Dec/2021'); 
time=t1:t2;
var(:,:,month(time)==2 & day(time)==29)=[]; % remove leap days
clear varClim
for iday=1:365
    varClim(:,:,iday)=nanmean(var(:,:,iday:365:end),3);
end
varClimCyclical=cat(3,varClim,varClim,varClim); % make a 3-year loop of clims
climSmooth0=movmean(movmean(varClimCyclical,31,3,'omitnan'),31,3,'omitnan'); % 31 day window to copy Lantao, but maybe it should be 16
clear varClimCyclical varClim
climSmooth=climSmooth0(:,:,366:366+364); % choose the middle year (smoothed)

% ----------------------- make anom -----------------------


% ----------------------- make Mon file -----------------------

