% December 8, 2022
clear; clc; close all;

% see /Users/sglanvil/Documents/sg_indices/sg_read_nino34.m
% load /Users/sglanvil/Documents/sg_indices/nino34_obs.mat
load /glade/work/sglanvil/CCR/S2S/data/nino34_obs.mat
t1=datetime('1/Jan/1999'); 
t2=datetime('31/Dec/2020'); 
timeENSOdaily=t1:t2;
anomENSOmonthly=nino34-nanmean(nino34);
timeENSOmonthly=timeENSOdaily(day(timeENSOdaily)==15); % datetime monthly option
anomENSOdaily=interp1(timeENSOmonthly,anomENSOmonthly,timeENSOdaily);
timeEL=timeENSOdaily(anomENSOdaily>0.5);
timeLA=timeENSOdaily(anomENSOdaily<-0.5);
timeENSOACTIVE=sort(cat(2,timeEL,timeLA));
timeENSONEUTRAL=timeENSOdaily(abs(anomENSOdaily)<=0.5);

% ----------------------- interp -----------------------
lon=0:359;
lat=-90:90;
[xNew,yNew]=meshgrid(lon,lat);
file='/glade/scratch/sglanvil/GPCP_yaga/pr_sfc_GPCP_19990101-20211231.nc';
var0=ncread(file,'precip');
lon0=ncread(file,'longitude'); 
lat0=ncread(file,'latitude'); 
[x,y]=meshgrid(lon0,lat0);
t1=datetime('1/Jan/1999'); 
t2=datetime('31/Dec/2021'); 
time=t1:t2;
var0(abs(var0)>1000)=NaN; % some weird flags
clear var
for itime=1:length(time)
    var(:,:,itime)=interp2(x,y,squeeze(var0(:,:,itime))',xNew',yNew','linear');
end

% ----------------------- make smooth clim -----------------------
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
    yy=year(time(itime));% November 30, 2022
    if mod(yy,4)==0 && mm>2 % handle leap days
        doy=doy-1;
    end
    varAnom(:,:,itime)=var(:,:,itime)-varClimSmooth(:,:,doy);
end

% ----------------------- make Mon 4-d array -----------------------
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

%% ----------------------- make ACC files -----------------------
divideOBSby=86400; % OBS (mm/day) vs MODEL (mm/s)
varName='pr_sfc'; 
caseList={'cesm2cam6v2',...
    'cesm2cam6climoATMv2','cesm2cam6climoLNDv2','cesm2cam6climoOCNv2',...
    'cesm2cam6climoOCNclimoATMv2','cesm2cam6climoOCNFIXclimoLNDv2',...
    'cesm2cam6climoALLv2','cesm2cam6climoALLFIXv2'};
scenarioName='scenario1';

% compositeList={'ALL' 'DJF' 'JJA' 'EL' 'LA'};
compositeList={'ENSOACTIVE','ENSONEUTRAL'};
timeFreq='dailySmooth'; % 'daily' or 'twoWeek' or 'dailySmooth'

for icomposite=1:2
    composite=compositeList{icomposite};
    for icase=1:8
        caseName=caseList{icase};
        disp(caseName)
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
        anomOBS=anomOBS0(:,:,:,ib)/divideOBSby;    
        starttime=starttime(ia);
        starttimeOBS=starttimeOBS(ib);

        amonth=0;
        if strcmp(composite,'DJF')==1
            amonth=1; bmonth=2; cmonth=12;
        elseif strcmp(composite,'MAM')==1
            amonth=3; bmonth=4; cmonth=5;
        elseif strcmp(composite,'JJA')==1
            amonth=6; bmonth=7; cmonth=8;
        elseif strcmp(composite,'SON')==1
            amonth=9; bmonth=10; cmonth=11;
        end
        if strcmp(composite,'ALL')~=1 && amonth>0 % if particular season (not annual mean)
            anom=squeeze(anom(:,:,:,...
                month(starttime)==amonth | month(starttime)==bmonth | month(starttime)==cmonth));
            anomOBS=squeeze(anomOBS(:,:,:,...
                month(starttimeOBS)==amonth | month(starttimeOBS)==bmonth | month(starttimeOBS)==cmonth));
        end

        if strcmp(composite,'EL')==1
            [C,ia,ib]=intersect(starttime,timeEL);
            anom=anom(:,:,:,ia);
            [C,ia,ib]=intersect(starttimeOBS,timeEL);
            anomOBS=anomOBS(:,:,:,ia);        
        elseif strcmp(composite,'LA')==1
            [C,ia,ib]=intersect(starttime,timeLA);
            anom=anom(:,:,:,ia);
            [C,ia,ib]=intersect(starttimeOBS,timeLA);
            anomOBS=anomOBS(:,:,:,ia);  
        end

        if strcmp(composite,'ENSOACTIVE')==1
            [C,ia,ib]=intersect(starttime,timeENSOACTIVE);
            anom=anom(:,:,:,ia);
            [C,ia,ib]=intersect(starttimeOBS,timeENSOACTIVE);
            anomOBS=anomOBS(:,:,:,ia);        
        elseif strcmp(composite,'ENSONEUTRAL')==1
            [C,ia,ib]=intersect(starttime,timeENSONEUTRAL);
            anom=anom(:,:,:,ia);
            [C,ia,ib]=intersect(starttimeOBS,timeENSONEUTRAL);
            anomOBS=anomOBS(:,:,:,ia);  
        end        
        
        if strcmp(timeFreq,'dailySmooth')==1
            clear anom_smooth anomOBS_smooth
            anom_smooth=movmean(anom,3,3,'omitnan','Endpoints','shrink');
            anomOBS_smooth=movmean(anomOBS,3,3,'omitnan','Endpoints','shrink');
            
            anom=anom_smooth;
            anomOBS=anomOBS_smooth;
        end

        if strcmp(timeFreq,'twoWeek')==1
            icounter=0;
            clear anom_weekly anomOBS_weekly
            for week=[1 3 5]
                icounter=icounter+1;
                anom_weekly(:,:,icounter,:)=squeeze(nanmean(...
                    anom(:,:,(week-1)*7+1+1:(week-1)*7+14+1,:),3)); % note +1 at the end (Lantao)
                anomOBS_weekly(:,:,icounter,:)=squeeze(nanmean(...
                    anomOBS(:,:,(week-1)*7+1:(week-1)*7+14+1,:),3));
            end
            anom=anom_weekly;
            anomOBS=anomOBS_weekly;
        end

        sampleSize=size(anomOBS,4);

        clear ACC RMSE
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
            RMSE(:,:,ilead)=sqrt(nanmean((anomFF-anomAA).^2,3));
        end    
        lead=1:size(ACC,3);

        % ------------------------ save as netcdf ------------------------
        ncSave=sprintf('/glade/work/sglanvil/CCR/S2S/data/%s_ACC_%scomposite_%s_%s.%s_%.4dsample_GPCP_s2s_data.nc',...
            varName,composite,timeFreq,caseName,scenarioName,sampleSize);
        ncid=netcdf.create(ncSave,'NC_WRITE');
        dimidlon = netcdf.defDim(ncid,'lon',length(lon));
        dimidlat = netcdf.defDim(ncid,'lat',length(lat));
        dimidlead = netcdf.defDim(ncid,'lead',length(lead));
        lon_ID=netcdf.defVar(ncid,'lon','float',[dimidlon]);
        lat_ID=netcdf.defVar(ncid,'lat','float',[dimidlat]);
        lead_ID=netcdf.defVar(ncid,'lead','float',[dimidlead]);
        ACC_ID=netcdf.defVar(ncid,'ACC','float',[dimidlon dimidlat dimidlead]);
        RMSE_ID=netcdf.defVar(ncid,'RMSE','float',[dimidlon dimidlat dimidlead]);
        netcdf.endDef(ncid);
        netcdf.putVar(ncid,lon_ID,lon);
        netcdf.putVar(ncid,lat_ID,lat);
        netcdf.putVar(ncid,lead_ID,lead);
        netcdf.putVar(ncid,ACC_ID,ACC); 
        netcdf.putVar(ncid,RMSE_ID,RMSE); 
        netcdf.close(ncid)     
    end
end
