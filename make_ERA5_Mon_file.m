% November 29, 2022

% clear; clc; close all;
% 
% srcFolder='/glade/scratch/sglanvil/ERA5_yaga/';
% srcVar='VAR_2T';
% destFolder='/glade/scratch/sglanvil/ERA5_yaga/interp/';
% destVar='tas_2m';
% 
% lon=0:359;
% lat=-90:90;
% [xNew,yNew]=meshgrid(lon,lat);
% 
% % ----------------------- loop and interpolate -----------------------
% filePattern=fullfile(srcFolder,'*.nc'); 
% files=dir(filePattern);
% for k=1 %s:length(files)
%     baseFileName=files(k).name;
%     fullFileName=fullfile(files(k).folder,baseFileName);
%     fprintf(1,'Now reading %s\n',fullFileName);
%     varOBS=ncread(fullFileName,srcVar);
%     lonOBS=ncread(fullFileName,'longitude'); % NOTE: check naming
%     latOBS=ncread(fullFileName,'latitude'); % NOTE: check naming
%     timeOBS=ncread(fullFileName,'time'); % NOTE: check existence/format
%     [x,y]=meshgrid(lonOBS,latOBS);
%     varOUT=interp2(x,y,varOBS',xNew,yNew,'linear');
%     % ----------------------- save at netcdf -----------------------
%     ncSave=sprintf('%s/%s',destFolder,baseFileName);
%     fprintf(1,'--->Saving as %s\n',ncSave);
%     ncid=netcdf.create(ncSave,'NC_WRITE');
%     dimidlon = netcdf.defDim(ncid,'lon',length(lon));
%     dimidlat = netcdf.defDim(ncid,'lat',length(lat));
%     dimidtime = netcdf.defDim(ncid,'time',length(timeOBS));
%     lon_ID=netcdf.defVar(ncid,'lon','float',[dimidlon]);
%     lat_ID=netcdf.defVar(ncid,'lat','float',[dimidlat]);
%     time_ID=netcdf.defVar(ncid,'time','float',[dimidtime]);
%     var_ID=netcdf.defVar(ncid,destVar,'float',[dimidlon dimidlat dimidtime]);
%     netcdf.endDef(ncid);
%     netcdf.putVar(ncid,lat_ID,lat);
%     netcdf.putVar(ncid,lon_ID,lon);
%     netcdf.putVar(ncid,time_ID,timeOBS);
%     netcdf.putVar(ncid,var_ID,varOUT);
%     netcdf.close(ncid)
% end

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
time(month(time)==2 & day(time)==29)=[]; % remove leap days
clear varClim
for iday=1:365
    varClim(:,:,iday)=nanmean(var(:,:,iday:365:end),3);
end
varClimCyclical=cat(3,varClim,varClim,varClim); % make a 3-year loop of clims
varClimSmooth0=movmean(movmean(varClimCyclical,31,3,'omitnan'),31,3,'omitnan'); % 31 day window to copy Lantao, but maybe it should be 16
clear varClimCyclical varClim
varClimSmooth=varClimSmooth0(:,:,366:366+364); % choose the middle year (smoothed)

% ----------------------- make anom -----------------------
clear varAnom
for itime=1:size(var,3)
    doy=day(time(itime),'dayofyear');
    mm=month(time(itime));
    yy=year(time(itime));
    if mod(yy,4)==0 && mm>2 % handle leap days
        doy=doy-1;
    end
    varAnom(:,:,itime)=var(:,:,itime)-varClimSmooth(:,:,doy);
end

% ----------------------- make Mon file -----------------------
inxMonday=find(weekday(time)==2); % find Mondays
inxMonday(end-5:end)=[]; % can't go past available dates for the +45 lead stuff

varAnom4dim=cat(4,varAnom(:,:,inxMonday),varAnom(:,:,inxMonday+1),varAnom(:,:,inxMonday+2),...
    varAnom(:,:,inxMonday+3),varAnom(:,:,inxMonday+4),varAnom(:,:,inxMonday+5),...
    varAnom(:,:,inxMonday+6),varAnom(:,:,inxMonday+7),varAnom(:,:,inxMonday+8),...
    varAnom(:,:,inxMonday+9),varAnom(:,:,inxMonday+10),varAnom(:,:,inxMonday+11),...
    varAnom(:,:,inxMonday+12),varAnom(:,:,inxMonday+13),varAnom(:,:,inxMonday+14),...
    varAnom(:,:,inxMonday+15),varAnom(:,:,inxMonday+16),varAnom(:,:,inxMonday+17),...
    varAnom(:,:,inxMonday+18),varAnom(:,:,inxMonday+19),varAnom(:,:,inxMonday+20),...
    varAnom(:,:,inxMonday+21),varAnom(:,:,inxMonday+22),varAnom(:,:,inxMonday+23),...
    varAnom(:,:,inxMonday+24),varAnom(:,:,inxMonday+25),varAnom(:,:,inxMonday+26),...
    varAnom(:,:,inxMonday+27),varAnom(:,:,inxMonday+28),varAnom(:,:,inxMonday+29),...
    varAnom(:,:,inxMonday+30),varAnom(:,:,inxMonday+31),varAnom(:,:,inxMonday+32),...
    varAnom(:,:,inxMonday+33),varAnom(:,:,inxMonday+34),varAnom(:,:,inxMonday+35),...
    varAnom(:,:,inxMonday+36),varAnom(:,:,inxMonday+37),varAnom(:,:,inxMonday+38),...
    varAnom(:,:,inxMonday+39),varAnom(:,:,inxMonday+40),varAnom(:,:,inxMonday+41),...
    varAnom(:,:,inxMonday+42),varAnom(:,:,inxMonday+43),varAnom(:,:,inxMonday+44),...
    varAnom(:,:,inxMonday+45));
varAnomFinal=permute(varAnom4dim,[1 2 4 3]); % rearrange dim: (lon,lat,time,lead)-->(lon,lat,lead,time)
timeFinal=time(inxMonday);
varAnomFinal(:,:,:,year(timeFinal)>2020)=[];
timeFinal(year(timeFinal)>2020)=[];

anomOBS0=varAnomFinal;
dateOBS=yyyymmdd(timeFinal);
clear var varAnom varAnomFinal varAnom4dim varClimSmooth varClimSmooth0

% ------------------------ save as netcdf ------------------------
% ncSave='/glade/campaign/cesm/development/cross-wg/S2S/sglanvil/data/tas_2m_anom_ERA5_Mon_199901-202012_data.nc';
% ncid=netcdf.create(ncSave,'NC_WRITE');
% dimidlon = netcdf.defDim(ncid,'lon',length(lon));
% dimidlat = netcdf.defDim(ncid,'lat',length(lat));
% dimidlead = netcdf.defDim(ncid,'lead',length(lead));
% dimidtime = netcdf.defDim(ncid,'time',length(time));
% lon_ID=netcdf.defVar(ncid,'lon','float',[dimidlon]);
% lat_ID=netcdf.defVar(ncid,'lat','float',[dimidlat]);
% lead_ID=netcdf.defVar(ncid,'lead','float',[dimidlead]);
% time_ID=netcdf.defVar(ncid,'time','float',[dimidtime]);
% anom_ID=netcdf.defVar(ncid,'anom','float',[dimidlon dimidlat dimidlead dimidtime]);
% netcdf.endDef(ncid);
% netcdf.putVar(ncid,lon_ID,lon);
% netcdf.putVar(ncid,lat_ID,lat);
% netcdf.putVar(ncid,lead_ID,lead);
% netcdf.putVar(ncid,time_ID,time);
% netcdf.putVar(ncid,anom_ID,anom);
% netcdf.close(ncid)

%%

varName='tas_2m';
caseList={'cesm2cam6v2',...
    'cesm2cam6climoATMv2','cesm2cam6climoLNDv2','cesm2cam6climoOCNv2',...
    'cesm2cam6climoOCNclimoATMv2','cesm2cam6climoOCNFIXclimoLNDv2',...
    'cesm2cam6climoALLv2','cesm2cam6climoALLFIXv2'};
scenarioName='scenario1';
season='DJF';
timeAvg='daily';

for icase=1:8
    caseName=caseList{icase};
    disp(caseName)
    ncSave=sprintf('/glade/campaign/cesm/development/cross-wg/S2S/sglanvil/data/%s_ACC_ERA5_%sseason_%s_%s.%s_s2s_data.nc',...
        varName,season,timeAvg,caseName,scenarioName);
    fil=sprintf('/glade/campaign/cesm/development/cross-wg/S2S/sglanvil/data/%s_anom_%s.%s_s2s_data.nc',...
        varName,caseName,scenarioName);
    anom=ncread(fil,'anom'); 
    lat=ncread(fil,'lat');
    lon=ncread(fil,'lon');
    date=ncread(fil,'date');
    
    starttime=datetime(date,'ConvertFrom','yyyymmdd');
    starttimeOBS=datetime(dateOBS,'ConvertFrom','yyyymmdd');
    
    [C,ia,ib]=intersect(starttime,starttimeOBS);
    anom=anom(:,:,:,ia);
    anomOBS=anomOBS0(:,:,:,ib);    
    starttime=starttime(ia);
    starttimeOBS=starttimeOBS(ib);
        
    [starttime(1) starttimeOBS(1)]
    [starttime(end) starttimeOBS(end)]

    if strcmp(season,'DJF')==1
        amonth=1; bmonth=2; cmonth=12;
    elseif strcmp(season,'MAM')==1
        amonth=3; bmonth=4; cmonth=5;
    elseif strcmp(season,'JJA')==1
        amonth=6; bmonth=7; cmonth=8;
    elseif strcmp(season,'SON')==1
        amonth=9; bmonth=10; cmonth=11;
    end

    size(anom)
    size(anomOBS)
    anom=squeeze(anom(:,:,:,...
        month(starttime)==amonth | month(starttime)==bmonth | month(starttime)==cmonth));
    anomOBS=squeeze(anomOBS(:,:,:,...
        month(starttimeOBS)==amonth | month(starttimeOBS)==bmonth | month(starttimeOBS)==cmonth));
    size(anom)
    size(anomOBS)

    clear ACC
    for ilead=1:size(anomOBS,3) % lead in obs may be shorter than model
        anomFF=squeeze(anom(:,:,ilead,:));
        anomAA=squeeze(anomOBS(:,:,ilead,:));
        a=(anomFF.*anomAA);
        b=(anomFF).^2;
        c=(anomAA).^2;
        aTM=squeeze(nanmean(a,3)); % calculate time means (TM)
        bTM=squeeze(nanmean(b,3));
        cTM=squeeze(nanmean(c,3));
        ACC(:,:,ilead)=aTM./sqrt(bTM.*cTM);
    end
    lead=1:size(ACC,3);

    % ------------------------ save as netcdf ------------------------
    ncid=netcdf.create(ncSave,'NC_WRITE');
    dimidlon = netcdf.defDim(ncid,'lon',length(lon));
    dimidlat = netcdf.defDim(ncid,'lat',length(lat));
    dimidlead = netcdf.defDim(ncid,'lead',length(lead));
    lon_ID=netcdf.defVar(ncid,'lon','float',[dimidlon]);
    lat_ID=netcdf.defVar(ncid,'lat','float',[dimidlat]);
    lead_ID=netcdf.defVar(ncid,'lead','float',[dimidlead]);
    ACC_ID = netcdf.defVar(ncid,'ACC','float',[dimidlon dimidlat dimidlead]);
    netcdf.endDef(ncid);
    netcdf.putVar(ncid,lon_ID,lon);
    netcdf.putVar(ncid,lat_ID,lat);
    netcdf.putVar(ncid,lead_ID,lead);
    netcdf.putVar(ncid,ACC_ID,ACC); 
    netcdf.close(ncid)     
end

             

