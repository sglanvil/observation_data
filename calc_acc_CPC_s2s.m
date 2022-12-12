% November 23, 2022

clear; clc; close all;

varName='pr_sfc';
lon=0:359;
lat=-90:90;
[xNew,yNew]=meshgrid(lon,lat);

filOBS=sprintf('/glade/work/sglanvil/CCR/S2S/data/%s_anom_CPC_sg_s2s_data.nc',varName);
anomOBS0=ncread(filOBS,'anom');
lonOBS=ncread(filOBS,'lon');
latOBS=ncread(filOBS,'lat');
[x,y]=meshgrid(lonOBS,latOBS);
clear varAnom
for itime=1:size(anomOBS0,3) % regrid the obs to match the model
    varAnom(:,:,itime)=interp2(x,y,squeeze(anomOBS0(:,:,itime))',xNew',yNew','linear');
end
time=datetime(int2str(ncread(filOBS,'date')),'InputFormat','yyyyMMdd');

varAnom(:,:,month(time)==2 & day(time)==29)=[]; % remove leap days
time(month(time)==2 & day(time)==29)=[]; % remove leap days
varAnom(:,:,year(time)>2021)=[];
time(year(time)>2021)=[];

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
clear var varAnom varAnomFinal varAnom4dim

%% ----------------------- make ACC files -----------------------
varName='pr_sfc';
caseList={'cesm2cam6v2',...
    'cesm2cam6climoATMv2','cesm2cam6climoLNDv2','cesm2cam6climoOCNv2',...
    'cesm2cam6climoOCNclimoATMv2','cesm2cam6climoOCNFIXclimoLNDv2',...
    'cesm2cam6climoALLv2','cesm2cam6climoALLFIXv2'};
scenarioName='scenario1';
season='ALL';
timeAvg='daily'; % 'daily' or 'doubleWeek'

divideOBSby=1;
if strcmp(varName,'pr_sfc')==1
    divideOBSby=86400; % OBS (mm/day) vs MODEL (mm/s)
end
for icase=1:8
    caseName=caseList{icase};
    disp(caseName)
    ncSave=sprintf('/glade/work/sglanvil/CCR/S2S/data/%s_ACC_CPC_%sseason_%s_%s.%s_s2s_data.nc',...
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
    anomOBS=anomOBS0(:,:,:,ib)/divideOBSby;    
    starttime=starttime(ia);
    starttimeOBS=starttimeOBS(ib);

    if strcmp(season,'DJF')==1
        amonth=1; bmonth=2; cmonth=12;
    elseif strcmp(season,'MAM')==1
        amonth=3; bmonth=4; cmonth=5;
    elseif strcmp(season,'JJA')==1
        amonth=6; bmonth=7; cmonth=8;
    elseif strcmp(season,'SON')==1
        amonth=9; bmonth=10; cmonth=11;
    end
    if strcmp(season,'ALL')~=1 % if particular season (not annual mean)
        anom=squeeze(anom(:,:,:,...
            month(starttime)==amonth | month(starttime)==bmonth | month(starttime)==cmonth));
        anomOBS=squeeze(anomOBS(:,:,:,...
            month(starttimeOBS)==amonth | month(starttimeOBS)==bmonth | month(starttimeOBS)==cmonth));
    end
    
    if strcmp(timeAvg,'doubleWeek')==1
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

        
