%Author: Christian Pelayo
%Affiliation: Scripps Institution of Oceanography
%Purpose: Loads each EPCAPE aerosol, cloud, and meteorological dataset, averages
%every dataset to a common 2-hr time window, and merges them on time into
%one table, H2_All, which is used for the analysis in the manuscript.
%Date Last Edited: 11/05/25

clear
clc

%% ========================================================================
%  1. SETTINGS
%  ========================================================================
%  binHours = length of the common time window (hr) used for averaging.
%  CP20     = 20-color palette used for plotting.

binHours = 2;

cd 'D:\EPCAPE Correlations'

CP20 = [
    0.1216, 0.4667, 0.7059;  % blue
    1.0000, 0.4980, 0.0549;  % orange
    0.1725, 0.6275, 0.1725;  % green
    0.8392, 0.1529, 0.1569;  % red
    0.5804, 0.4039, 0.7412;  % purple
    0.5490, 0.3373, 0.2941;  % brown
    0.8902, 0.4667, 0.7608;  % pink
    0.4980, 0.4980, 0.4980;  % grey
    0.7373, 0.7412, 0.1333;  % yellow-green
    0.0902, 0.7451, 0.8118;  % cyan-teal
    0.5020, 0.0000, 0.5020;  % dark purple
    0.8471, 0.1961, 0.6000;  % magenta
    0.0000, 0.5020, 0.5020;  % dark cyan
    0.7451, 0.5020, 0.0000;  % dark orange
    0.0000, 0.0000, 0.5020;  % navy
    0.5020, 0.0000, 0.0000;  % dark red
    0.6275, 0.6275, 0.6275;  % light grey
    0.0000, 0.5020, 0.0000;  % dark green
    1.0000, 0.0000, 1.0000;  % bright magenta
    0.0000, 1.0000, 1.0000;  % bright cyan
];

%% ========================================================================
%  2. IN SITU N_d: FOG MONITOR (FM-120) AT MT. SOLEDAD
%  ========================================================================
%  Input : monthly FM-120 files, Feb 2023 - Feb 2024 (2023-02.csv ... 2024-02.csv)
%  Clean : N_d set to NaN when liquid water content < 0.01 g m-3 (no cloud)
%  Avg   : 2-hr nanmean of all variables
%  Output: H2_Fog_T

cd 'D:\Paper 2\Fog Monitor\Monthly FM-120 Files'

T2 = readtable('2023-02.csv');

T3 = readtable('2023-03.csv');
T4 = readtable('2023-04.csv');
T5 = readtable('2023-05.csv');
T6 = readtable('2023-06.csv');
T7 = readtable('2023-07.csv');
T8 = readtable('2023-08.csv');
T9 = readtable('2023-09.csv');
T10 = readtable('2023-10.csv');
T11 = readtable('2023-11.csv');
T12 = readtable('2023-12.csv');
T01 = readtable('2024-01.csv');
T02 = readtable('2024-02.csv');
% Stack the monthly tables into single columns
T_all = {T2,T3,T4,T5,T6,T7,T8,T9,T10,T11,T12,T01,T02};
Var1_all = [];
NumberConc_all = [];
LWC_all = [];
for i = 1:length(T_all)
    T = T_all{i};

    Var1_all = [Var1_all; T.Var1];
    NumberConc_all = [NumberConc_all; T.NumberConc___cm_3_];
    LWC_all = [LWC_all; T.LWC_g_m_3_]
end
% Build the table (the second definition, with LWC, is the one used)
Fog_T = table(Var1_all,NumberConc_all,'VariableNames', {'Time','FogMonitorNd'});
Fog_T = table(Var1_all, NumberConc_all, LWC_all, ...
    'VariableNames', {'Time','FogMonitorNd' ,'LWC'});
Fog_T.FogMonitorNd(Fog_T.LWC < 0.01) = NaN;
% Step 1: Floor Time to 2-hour bins
Time2h = dateshift(Fog_T.Time, 'start', 'hour');   % round down to hour
Time2h.Hour = floor(Time2h.Hour / binHours) * binHours;   % 2-hour bins
% Step 2: Add Time2h column
Fog_T.Time2h = Time2h;
% Step 3: Find numeric variables (exclude time)
numericVars = Fog_T.Properties.VariableNames;
numericVars = setdiff(numericVars, {'Time','Time2h'});
% Step 4: Group + nanmean
Fog_T_2h = varfun(@nanmean, Fog_T, ...
    'InputVariables', numericVars, ...
    'GroupingVariables', 'Time2h');
% Step 5: Rename back to original variable names
Fog_T_2h.Properties.VariableNames{'Time2h'} = 'Time';
for k = 1:length(numericVars)
    Fog_T_2h.Properties.VariableNames{ ...
        strcmp(Fog_T_2h.Properties.VariableNames, ...
        ['nanmean_' numericVars{k}])} = numericVars{k};
end
% Step 6: Final output table
H2_Fog_T = Fog_T_2h(:, [{'Time'}, numericVars]);

%% ========================================================================
%  3. SATELLITE N_d: SatCORPS (PROVIDED BY C. SEETHALA)
%  ========================================================================
%  Input : PelayoSeethalaSatCorpsv05132602deg.csv (the last file read below;
%          the earlier reads are overwritten)
%  Clean : keep Time and Nd; remove rows with missing Nd
%  Avg   : 2-hr nanmean
%  Output: H2_Nd_T

cd 'D:\Paper 2'
Nd_T2 = readtable('PelayoSeethalaSatCorps020326.csv');
Nd_T2 = readtable('PelayoSeethalaSatCorps020326v4.csv');
Nd_T2 = readtable('PelayoSeethalaSatCorpsv05132602deg.csv');   % file used in the analysis

Nd_T = Nd_T2;
% Rename BaseTime to Time
Nd_T.Properties.VariableNames{'BaseTime'} = 'Time';
% Keep only Time and Nd
Nd_T = Nd_T(:, {'Time','Nd'});
Nd_T = Nd_T(~isnan(Nd_T.Nd), :);
% Step 1: Floor times to 2-hour bins
Time2h = dateshift(Nd_T.Time, 'start', 'hour');   % round down to the hour
Time2h.Hour = floor(Time2h.Hour / binHours) * binHours;        % floor to 2-hour blocks
% Step 2: Add 2-hour column to the table
Nd_T.Time2h = Time2h;

% Step 3: Group by 2-hour bins and calculate nanmean of Nd
Nd_T_2h = varfun(@nanmean, Nd_T, 'InputVariables', 'Nd', 'GroupingVariables', 'Time2h');

% Step 4: Rename columns to match original names
Nd_T_2h.Properties.VariableNames{'Time2h'} = 'Time';
Nd_T_2h.Properties.VariableNames{'nanmean_Nd'} = 'Nd';

% Step 5: Keep only Time and Nd
H2_Nd_T = Nd_T_2h(:, {'Time', 'Nd'});

%% ========================================================================
%  4. LOW-CLOUD PERIOD FLAG
%  ========================================================================
%  Input : bb2743661p_30_1.txt
%  Avg   : 2-hr MODE (the flag is categorical, so it is not averaged)
%  Extra : LowCloudPeriodDay = 1 if any 2-hr period in that day is flagged
%  Output: T_Low_2h

cd 'D:\Paper 2'

% Read table
T_Low = readtable('bb2743661p_30_1.txt');

% Convert datenum to datetime
T_Low.Time = datetime(T_Low.time,'ConvertFrom','datenum');

% Step 1: Floor Time to 2-hour bins
Time2h = dateshift(T_Low.Time, 'start', 'hour');
Time2h.Hour = floor(Time2h.Hour / binHours) * binHours;

% Step 2: Add temporary column
T_Low.Time2h = Time2h;

% Step 3: Identify numeric variables
numericVars = T_Low.Properties.VariableNames;
numericVars = setdiff(numericVars, {'time','Time','Time2h'});

% Keep only numeric columns
isNum = varfun(@isnumeric, T_Low, 'OutputFormat', 'uniform');
numericVars = intersect(numericVars, T_Low.Properties.VariableNames(isNum));

% Step 4: Group by 2-hour bins and calculate mode
T_Low_2h = varfun(@mode, T_Low, ...
    'InputVariables', numericVars, ...
    'GroupingVariables', 'Time2h');

% Step 5: Rename variables
T_Low_2h.Properties.VariableNames{'Time2h'} = 'Time';

for k = 1:length(numericVars)
    oldName = ['mode_' numericVars{k}];
    idx = strcmp(T_Low_2h.Properties.VariableNames, oldName);

    if any(idx)
        T_Low_2h.Properties.VariableNames{idx} = numericVars{k};
    end
end

% Step 6: Keep only Time + numeric variables
T_Low_2h = T_Low_2h(:, [{'Time'}, numericVars]);

% Create day identifier
dayID = dateshift(T_Low_2h.Time,'start','day');

% Group by day
[grp, ~] = findgroups(dayID);

% Daily flag: 1 if any 2-hour period is 1
dailyFlag = splitapply(@max, T_Low_2h.LowCloudPeriod, grp);

% Add back to table
T_Low_2h.LowCloudPeriodDay = dailyFlag(grp);

%% ========================================================================
%  5. MERRA-2 AOD
%  ========================================================================
%  Input : MERRA2AODv050826TEST.csv
%  Clean : keep Time and MERRA2AOD; remove rows with missing AOD
%  Avg   : 2-hr nanmean
%  Output: H2_MERRA_T

cd 'D:\Paper 2'

MERRA_T = readtable('MERRA2AODv050826TEST.csv');

% Keep only Time and MERRA2AOD
MERRA_T = MERRA_T(:, {'Time','MERRA2AOD'});

MERRA_T = MERRA_T(~isnan(MERRA_T.MERRA2AOD), :);

% Step 1: Floor times to 2-hour bins
Time2h = dateshift(MERRA_T.Time, 'start', 'hour');
Time2h.Hour = floor(Time2h.Hour / binHours) * binHours;

% Step 2: Add 2-hour column to the table
MERRA_T.Time2h = Time2h;

% Step 3: Group by 2-hour bins and calculate nanmean
MERRA_T_2h = varfun(@nanmean, MERRA_T, ...
    'InputVariables', 'MERRA2AOD', ...
    'GroupingVariables', 'Time2h');

% Step 4: Rename columns
MERRA_T_2h.Properties.VariableNames{'Time2h'} = 'Time';
MERRA_T_2h.Properties.VariableNames{'nanmean_MERRA2AOD'} = 'MERRA2AOD';

% Step 5: Keep only Time and MERRA2AOD
H2_MERRA_T = MERRA_T_2h(:, {'Time', 'MERRA2AOD'});

%% ========================================================================
%  6. SATELLITE CLOUD PROPERTIES: SatCORPS
%  ========================================================================
%  Input : SATCORPS_02deg_mean_std_phase_cloudfraction_051126.csv (the first
%          read below is overwritten)
%  Clean : keep grid cells within +/-0.5 deg of the site (32.840 N, 117.249 W)
%          remove "_mean" from the names of columns 6, 8, ..., 18
%          keep warm, low, liquid clouds:
%            cloud top height < 3 km
%            20 <= LWP <= 300 g m-2
%            cloud top temperature > 273 K
%            visible optical depth > 7
%  Avg   : 2-hr nanmean
%  Output: H2_SatCorps_T

SatCorps_T = readtable('SATCORPSv012126.csv');
cd 'D:\Paper 2\050726'
SatCorps_T = readtable('SATCORPS_02deg_mean_std_phase_cloudfraction_051126.csv');
% Site location and box half-width (deg)
lat_ref = 32.840;
lon_ref = -117.249;

lat_tol = 0.5;
lon_tol = 0.5;

idx = SatCorps_T.Latitude  >= (lat_ref - lat_tol) & ...
      SatCorps_T.Latitude  <= (lat_ref + lat_tol) & ...
      SatCorps_T.Longitude >= (lon_ref - lon_tol) & ...
      SatCorps_T.Longitude <= (lon_ref + lon_tol);

SatCorps_T = SatCorps_T(idx,:);

cols = [6 8 10 12 14 16 18];

oldNames = SatCorps_T.Properties.VariableNames;

for k = cols
    oldName = oldNames{k};
    newName = erase(oldName, '_mean');
    oldNames{k} = newName;
end

SatCorps_T.Properties.VariableNames = oldNames;

% Apply all cloud filters at once
combinedFilter = (SatCorps_T.CloudTopHeight < 3) & ...
                 (SatCorps_T.CloudLWP_IWP >= 20 & SatCorps_T.CloudLWP_IWP <= 300) & ...
                 (SatCorps_T.CloudTopTemp > 273) & ...
                 (SatCorps_T.CloudVisibleOpticalDepth > 7);
% Apply combined filter
Combined_T = SatCorps_T(combinedFilter, :);
SatCorps_T = SatCorps_T(combinedFilter, :);
% Display number of rows that satisfy all conditions
fprintf('Number of rows satisfying ALL conditions: %d\n', height(Combined_T));

SatCorps_T.Properties.VariableNames{'BaseTime'} = 'Time';

% Step 1: Floor BaseTime to 2-hour bins
Time2h = dateshift(SatCorps_T.Time, 'start', 'hour');   % round down to the hour
Time2h.Hour = floor(Time2h.Hour / binHours) * binHours;                  % floor to 2-hour blocks

% Step 2: Add the 2-hour column to the table
SatCorps_T.Time2h = Time2h;

% Step 3: Group by 2-hour bins and calculate nanmean of all numeric variables except BaseTime
numericVars = SatCorps_T.Properties.VariableNames;
numericVars = setdiff(numericVars, {'Time', 'Time2h'}); % exclude time columns

SatCorps_T_2h = varfun(@nanmean, SatCorps_T, 'InputVariables', numericVars, ...
                        'GroupingVariables', 'Time2h');

% Step 4: Rename columns to match original names
SatCorps_T_2h.Properties.VariableNames{'Time2h'} = 'Time';
for k = 1:length(numericVars)
    SatCorps_T_2h.Properties.VariableNames{strcmp(SatCorps_T_2h.Properties.VariableNames, ['nanmean_' numericVars{k}])} = numericVars{k};
end

% Step 5: Keep BaseTime plus the averaged variables
H2_SatCorps_T = SatCorps_T_2h(:, [{'Time'}, numericVars]);

%% ========================================================================
%  7. GROUND-BASED N_d: ARM NDROP VALUE-ADDED PRODUCT (1-min)
%  ========================================================================
%  Input : EPCAPE_NDROP.mat
%  Vars  : CDNC (N_d), CDNC_Ad (adiabatic N_d), CBH (cloud base height),
%          CBT (cloud base type), Tau (cloud optical depth), LWP
%  Avg   : 2-hr nanmean
%  Output: H2_NDROP_T

cd 'D:\EPCAPE AOD'
check2 = load('EPCAPE_NDROP.mat')

NDROP_drop_number_conc2 = check2.NDROP_Nd_1min';
NDROP_drop_number_conc_adiabatic2 = check2.NDROP_Nd_ad_1min';
NDROP_cloud_base_height2 = check2.NDROP_CBH_1min';
NDROP_cloud_base_type2 = check2.NDROP_base_type_1min';
NDROP_LWP = check2.NDROP_lwp_meas_1min';
NDROP_Tau = check2.NDROP_tauc_1min';
NDROP_time_dt2 = datetime(check2.NDROP_time_1min,'ConvertFrom','datenum')';
NDROP_T2 = table(NDROP_time_dt2,NDROP_drop_number_conc2, NDROP_drop_number_conc_adiabatic2, NDROP_cloud_base_height2, NDROP_cloud_base_type2, NDROP_Tau, NDROP_LWP, 'VariableNames', {'Time','CDNC','CDNC_Ad','CBH','CBT','Tau','LWP'});

% Step 1: Floor Time to 2-hour bins
Time2h = dateshift(NDROP_T2.Time, 'start', 'hour');   % round down to hour
Time2h.Hour = floor(Time2h.Hour / binHours) * binHours;            % floor to 2-hour blocks

% Step 2: Add Time2h as a temporary column
NDROP_T2.Time2h = Time2h;

% Step 3: Automatically find all numeric variables (exclude Time columns)
numericVars = NDROP_T2.Properties.VariableNames;
numericVars = setdiff(numericVars, {'Time','Time2h'});

% Step 4: Group by 2-hour bins and calculate nanmean
NDROP_T_2h = varfun(@nanmean, NDROP_T2, 'InputVariables', numericVars, ...
                    'GroupingVariables', 'Time2h');

% Step 5: Rename columns back to original
NDROP_T_2h.Properties.VariableNames{'Time2h'} = 'Time';
for k = 1:length(numericVars)
    NDROP_T_2h.Properties.VariableNames{strcmp(NDROP_T_2h.Properties.VariableNames, ['nanmean_' numericVars{k}])} = numericVars{k};
end

% Step 6: Keep only Time + numeric variables
H2_NDROP_T = NDROP_T_2h(:, [{'Time'}, numericVars]);

%% ========================================================================
%  8. LOCAL CLOUD FRACTION: TOTAL SKY IMAGER (TSI)
%  ========================================================================
%  Input : EPCAPE_TSI_251217.mat (percent opaque sky cover)
%  Clean : values with a nonzero QC flag set to NaN
%  Avg   : hourly mean first, then 2-hr nanmean
%  Output: H2_TSI_T

cd 'D:\EPCAPE AOD'

load('EPCAPE_TSI_251217.mat')

TSI_percent_opaque(TSI_qc_percent_opaque ~= 0) = NaN;
% Create table
TSI_T = table(TSI_time_dt, TSI_percent_opaque, ...
    'VariableNames', {'Time', 'Percent_Opaque'});

% Convert Time to hourly bins
hourBin = dateshift(TSI_T.Time, 'start', 'hour');

% Group by hour
[G, hourGroups] = findgroups(hourBin);

% Take hourly mean, ignoring NaNs
Percent_Opaque_mean = splitapply(@(x) mean(x,'omitnan'), TSI_T.Percent_Opaque, G);

% Create new table with same variable names
TSI_T = table(hourGroups, Percent_Opaque_mean, ...
                     'VariableNames', {'Time', 'Percent_Opaque'});

% Step 1: Floor times to 2-hour bins
Time2h = dateshift(TSI_T.Time, 'start', 'hour');   % round down to the hour
Time2h.Hour = floor(Time2h.Hour / binHours) * binHours;          % floor to 2-hour blocks

% Step 2: Add as temporary column
TSI_T.Time2h = Time2h;

% Step 3: Group by 2-hour bins and calculate nanmean of Percent_Opaque
TSI_T_2h = varfun(@nanmean, TSI_T, 'InputVariables', 'Percent_Opaque', ...
                  'GroupingVariables', 'Time2h');

% Step 4: Rename columns to match original names
TSI_T_2h.Properties.VariableNames{'Time2h'} = 'Time';
TSI_T_2h.Properties.VariableNames{'nanmean_Percent_Opaque'} = 'Percent_Opaque';

% Step 5: Keep only Time and Percent_Opaque
H2_TSI_T = TSI_T_2h(:, {'Time','Percent_Opaque'});

%% ========================================================================
%  9. SATELLITE AOD: VIIRS (1 x 1 DEG BOX)
%  ========================================================================
%  Three boxes are processed with the same steps:
%    9a. box centered on the site  -> H2_VIIRS_1deg_T
%    9b. box west of the site      -> H2_VIIRS_1deg_TWEST
%    9c. box east of the site      -> H2_VIIRS_1deg_TEAST
%  Clean : keep 15 Feb 2023 - 15 Feb 2024
%  Avg   : 2-hr nanmean

% ----- 9a. Box centered on the site -----
cd 'D:\Paper 2';

VIIRS_1deg_T = readtable('VIIRS_CA_All_1deg_Min021626.csv');

startDate = datetime(2023,2,15,0,0,0);
endDate   = datetime(2024,2,15,23,59,59);

idx1 = ~isnat(VIIRS_1deg_T.Scan_Time_Mean) & ...
       VIIRS_1deg_T.Scan_Time_Mean >= startDate & ...
       VIIRS_1deg_T.Scan_Time_Mean <= endDate;
VIIRS_1deg_T = VIIRS_1deg_T(idx1,:);
VIIRS_1deg_T.Properties.VariableNames{'Scan_Time_Mean'} = 'Time';

% Step 1: Floor Time to 2-hour bins
Time2h = dateshift(VIIRS_1deg_T.Time, 'start', 'hour');   % round down to hour
Time2h.Hour = floor(Time2h.Hour / binHours) * binHours;                 % floor to 2-hour blocks

% Step 2: Add as temporary column
VIIRS_1deg_T.Time2h = Time2h;

% Step 3: Identify numeric columns (exclude Time columns)
numericVars = VIIRS_1deg_T.Properties.VariableNames;
numericVars = setdiff(numericVars, {'Time','Time2h'});

% Step 4: Group by 2-hour bins and calculate nanmean
VIIRS_1deg_T_2h = varfun(@nanmean, VIIRS_1deg_T, 'InputVariables', numericVars, ...
                         'GroupingVariables', 'Time2h');

% Step 5: Rename columns to match original names
VIIRS_1deg_T_2h.Properties.VariableNames{'Time2h'} = 'Time';
for k = 1:length(numericVars)
    VIIRS_1deg_T_2h.Properties.VariableNames{strcmp(VIIRS_1deg_T_2h.Properties.VariableNames, ['nanmean_' numericVars{k}])} = numericVars{k};
end

% Step 6: Keep only Time + numeric variables
H2_VIIRS_1deg_T = VIIRS_1deg_T_2h(:, [{'Time'}, numericVars]);

% ----- 9b. Box west of the site -----
cd 'D:\Paper 2';

VIIRS_1deg_T = readtable('VIIRS_CA_All_1deg_MinWEST032226.csv');

startDate = datetime(2023,2,15,0,0,0);
endDate   = datetime(2024,2,15,23,59,59);

idx1 = ~isnat(VIIRS_1deg_T.Scan_Time_Mean) & ...
       VIIRS_1deg_T.Scan_Time_Mean >= startDate & ...
       VIIRS_1deg_T.Scan_Time_Mean <= endDate;
VIIRS_1deg_T = VIIRS_1deg_T(idx1,:);
VIIRS_1deg_T.Properties.VariableNames{'Scan_Time_Mean'} = 'Time';

% Step 1: Floor Time to 2-hour bins
Time2h = dateshift(VIIRS_1deg_T.Time, 'start', 'hour');   % round down to hour
Time2h.Hour = floor(Time2h.Hour / binHours) * binHours;                 % floor to 2-hour blocks

% Step 2: Add as temporary column
VIIRS_1deg_T.Time2h = Time2h;

% Step 3: Identify numeric columns (exclude Time columns)
numericVars = VIIRS_1deg_T.Properties.VariableNames;
numericVars = setdiff(numericVars, {'Time','Time2h'});

% Step 4: Group by 2-hour bins and calculate nanmean
VIIRS_1deg_T_2h = varfun(@nanmean, VIIRS_1deg_T, 'InputVariables', numericVars, ...
                         'GroupingVariables', 'Time2h');

% Step 5: Rename columns to match original names
VIIRS_1deg_T_2h.Properties.VariableNames{'Time2h'} = 'Time';
for k = 1:length(numericVars)
    VIIRS_1deg_T_2h.Properties.VariableNames{strcmp(VIIRS_1deg_T_2h.Properties.VariableNames, ['nanmean_' numericVars{k}])} = numericVars{k};
end

% Step 6: Keep only Time + numeric variables
H2_VIIRS_1deg_TWEST = VIIRS_1deg_T_2h(:, [{'Time'}, numericVars]);

% ----- 9c. Box east of the site -----
cd 'D:\Paper 2';

VIIRS_1deg_T = readtable('VIIRS_CA_All_1deg_MinEAST032226.csv');

startDate = datetime(2023,2,15,0,0,0);
endDate   = datetime(2024,2,15,23,59,59);

idx1 = ~isnat(VIIRS_1deg_T.Scan_Time_Mean) & ...
       VIIRS_1deg_T.Scan_Time_Mean >= startDate & ...
       VIIRS_1deg_T.Scan_Time_Mean <= endDate;
VIIRS_1deg_T = VIIRS_1deg_T(idx1,:);
VIIRS_1deg_T.Properties.VariableNames{'Scan_Time_Mean'} = 'Time';

% Step 1: Floor Time to 2-hour bins
Time2h = dateshift(VIIRS_1deg_T.Time, 'start', 'hour');   % round down to hour
Time2h.Hour = floor(Time2h.Hour / binHours) * binHours;                 % floor to 2-hour blocks

% Step 2: Add as temporary column
VIIRS_1deg_T.Time2h = Time2h;

% Step 3: Identify numeric columns (exclude Time columns)
numericVars = VIIRS_1deg_T.Properties.VariableNames;
numericVars = setdiff(numericVars, {'Time','Time2h'});

% Step 4: Group by 2-hour bins and calculate nanmean
VIIRS_1deg_T_2h = varfun(@nanmean, VIIRS_1deg_T, 'InputVariables', numericVars, ...
                         'GroupingVariables', 'Time2h');

% Step 5: Rename columns to match original names
VIIRS_1deg_T_2h.Properties.VariableNames{'Time2h'} = 'Time';
for k = 1:length(numericVars)
    VIIRS_1deg_T_2h.Properties.VariableNames{strcmp(VIIRS_1deg_T_2h.Properties.VariableNames, ['nanmean_' numericVars{k}])} = numericVars{k};
end

% Step 6: Keep only Time + numeric variables
H2_VIIRS_1deg_TEAST = VIIRS_1deg_T_2h(:, [{'Time'}, numericVars]);

% Rename AOD so the west and east boxes stay separate after merging
H2_VIIRS_1deg_TWEST.Properties.VariableNames{'AOD_550'} = 'AOD_550WEST';
H2_VIIRS_1deg_TEAST.Properties.VariableNames{'AOD_550'} = 'AOD_550EAST';

%% ========================================================================
%  10. GROUND-BASED AOD: CIMEL SUN PHOTOMETER (CSPHOT)
%  ========================================================================
%  Input : EPCAPE_CSPHOT_011226.csv
%  Clean : negative AOD_500 set to NaN
%  Avg   : 2-hr nanmean of all variables, plus 2-hr standard deviation of AOD_500
%  Output: H2_CSPHOT_T (means), CSPHOT_T_2h_std (standard deviation)

cd 'D:\EPCAPE AOD'

% Load CSPHOT data
CSPHOT_T = readtable('EPCAPE_CSPHOT_011226.csv');
% Clean negative values
CSPHOT_T.AOD_500(CSPHOT_T.AOD_500 < 0) = NaN;

% Step 1: Floor Time to 2-hour bins
Time2h = dateshift(CSPHOT_T.Time, 'start', 'hour');   % round down to the hour
Time2h.Hour = floor(Time2h.Hour / binHours) * binHours;             % floor to 2-hour blocks

% Step 2: Add as temporary column
CSPHOT_T.Time2h = Time2h;

% Step 3: Identify numeric columns (exclude Time columns)
numericVars = CSPHOT_T.Properties.VariableNames;
numericVars = setdiff(numericVars, {'Time','Time2h'});

% Step 4: Group by 2-hour bins and calculate nanmean
CSPHOT_T_2h = varfun(@nanmean, CSPHOT_T, 'InputVariables', numericVars, ...
                     'GroupingVariables', 'Time2h');

% Step 4b: Group by 2-hour bins and calculate nanstd for AOD_500 only
CSPHOT_T_2h_std = varfun(@nanstd, CSPHOT_T, 'InputVariables', 'AOD_500', ...
'GroupingVariables', 'Time2h');

% Step 5: Rename columns to match original names
CSPHOT_T_2h.Properties.VariableNames{'Time2h'} = 'Time';
for k = 1:length(numericVars)
    CSPHOT_T_2h.Properties.VariableNames{strcmp(CSPHOT_T_2h.Properties.VariableNames, ['nanmean_' numericVars{k}])} = numericVars{k};
end

% Step 5b: Rename std column and merge into CSPHOT_T_2h
CSPHOT_T_2h_std.Properties.VariableNames{'nanstd_AOD_500'} = 'AOD_500_std';
CSPHOT_T_2h.AOD_500_std = CSPHOT_T_2h_std.AOD_500_std;

CSPHOT_T_2h_std.Properties.VariableNames{'Time2h'} = 'Time';
% Step 6: Keep only Time + numeric variables
H2_CSPHOT_T = CSPHOT_T_2h(:, [{'Time'}, numericVars]);

%% ========================================================================
%  11. IN SITU CCN AT SCRIPPS PIER (LEAK-CORRECTED)
%  ========================================================================
%  Input : epcccn2colaavgM1_DedrickCorrected.txt (read from the current folder,
%          D:\EPCAPE AOD, set in Section 10)
%  Vars  : CN01, CN02, CN04, CN06, CN08, CN10 = CCN at 0.1, 0.2, 0.4, 0.6, 0.8,
%          and 1.0% supersaturation
%  Avg   : 2-hr nanmean
%  Output: H2_CCN_T

filename = 'epcccn2colaavgM1_DedrickCorrected.txt';

% Read as numeric matrix
ccn = readmatrix(filename);
% 1. Keep the time column and the six supersaturation columns
ccn_subset = ccn(:, 1:7);

% 2. Convert first column from datenum to datetime
CCN_Time = datetime(ccn_subset(:,1), 'ConvertFrom', 'datenum');

% 3. Assign one variable per supersaturation
CN01 = ccn_subset(:,2);
CN02 = ccn_subset(:,3);
CN04 = ccn_subset(:,4);
CN06 = ccn_subset(:,5);
CN08 = ccn_subset(:,6);
CN10 = ccn_subset(:,7);

% 4. Create a table
CCN_T = table(CCN_Time,CN01, CN02, CN04, CN06, CN08, CN10);
CCN_T.Properties.VariableNames{'CCN_Time'} = 'Time';

% Step 1: Floor Time to 2-hour bins
Time2h = dateshift(CCN_T.Time, 'start', 'hour');   % round down to hour
Time2h.Hour = floor(Time2h.Hour / binHours) * binHours;          % floor to 2-hour blocks

% Step 2: Add as temporary column
CCN_T.Time2h = Time2h;

% Step 3: Identify numeric columns (exclude Time columns)
numericVars = CCN_T.Properties.VariableNames;
numericVars = setdiff(numericVars, {'Time','Time2h'});

% Step 4: Group by 2-hour bins and calculate nanmean
CCN_T_2h = varfun(@nanmean, CCN_T, 'InputVariables', numericVars, ...
                  'GroupingVariables', 'Time2h');

% Step 5: Rename columns to match original names
CCN_T_2h.Properties.VariableNames{'Time2h'} = 'Time';
for k = 1:length(numericVars)
    CCN_T_2h.Properties.VariableNames{strcmp(CCN_T_2h.Properties.VariableNames, ['nanmean_' numericVars{k}])} = numericVars{k};
end

% Step 6: Keep only Time + numeric variables
H2_CCN_T = CCN_T_2h(:, [{'Time'}, numericVars]);

%% ========================================================================
%  12. IN SITU CCN AT MT. SOLEDAD (5-min)
%  ========================================================================
%  Input : EPCAPE_Soledad_CCN_for_christian_20250923.mat
%  Vars  : CCN02 ... CCN10 = CCN at 0.2, 0.4, 0.6, 0.8, and 1.0% supersaturation
%  Avg   : 2-hr nanmean
%  Output: H2_SolCCN_T (used in Section 26 to fill gaps in pier CCN at 0.2%)

cd 'D:\Paper 2'
SolCCN = load('EPCAPE_Soledad_CCN_for_christian_20250923.mat');
SolCCNTime = SolCCN.EPCAPE_time_5min;
SolCCNVal = SolCCN.Soledad_NCCN_cvi_retime_5min;

CCN02 = SolCCNVal(1,:)';
CCN04 = SolCCNVal(2,:)';
CCN06 = SolCCNVal(3,:)';
CCN08 = SolCCNVal(4,:)';
CCN10 = SolCCNVal(5,:)';

SolCCN_T = table(SolCCNTime', CCN02, CCN04, CCN06, CCN08, CCN10);
SolCCN_T.Properties.VariableNames{1} = 'Time';
% Step 1: Floor Time to 2-hour bins
Time2h = dateshift(SolCCN_T.Time, 'start', 'hour');
Time2h.Hour = floor(Time2h.Hour / binHours) * binHours;

% Step 2: Add as temporary column
SolCCN_T.Time2h = Time2h;

% Step 3: Identify numeric columns (exclude Time columns)
numericVars = SolCCN_T.Properties.VariableNames;
numericVars = setdiff(numericVars, {'Time','Time2h'});

% Step 4: Group by 2-hour bins and calculate nanmean
SolCCN_T_2h = varfun(@nanmean, SolCCN_T, ...
    'InputVariables', numericVars, ...
    'GroupingVariables', 'Time2h');

% Step 5: Rename columns to match original names
SolCCN_T_2h.Properties.VariableNames{'Time2h'} = 'Time';

for k = 1:length(numericVars)
    SolCCN_T_2h.Properties.VariableNames{ ...
        strcmp(SolCCN_T_2h.Properties.VariableNames, ...
        ['nanmean_' numericVars{k}])} = numericVars{k};
end

% Step 6: Keep only Time + numeric variables
H2_SolCCN_T = SolCCN_T_2h(:, [{'Time'}, numericVars]);

%% ========================================================================
%  13. SATELLITE AOD: MODIS TERRA (MOD04) AND AQUA (MYD04), 1 x 1 DEG BOX, QA = 3
%  ========================================================================
%  Three boxes are processed with the same steps:
%    13a. box centered on the site -> H2_MOD_T,     H2_MYD_T
%    13b. box west of the site     -> H2_MOD_TWEST, H2_MYD_TWEST
%    13c. box east of the site     -> H2_MOD_TEAST, H2_MYD_TEAST
%  Clean : keep 15 Feb 2023 - 15 Feb 2024; drop the Filename column
%  Avg   : 2-hr nanmean

cd 'D:\Paper 2'

% ----- 13a. Box centered on the site -----
MOD_T = readtable('MOD04_MeanAOD_Angstrom_1deg_QA3_050526.csv');
MYD_T = readtable('MYD04_MeanAOD_Angstrom_1deg_QA3_050526.csv');

% Define date range
startDate = datetime(2023,2,15,0,0,0);
endDate   = datetime(2024,2,15,23,59,59);

% Filter MOD_T
MOD_T = MOD_T(MOD_T.Mean_ScanTime >= startDate & MOD_T.Mean_ScanTime <= endDate, :);

% Filter MYD_T
MYD_T = MYD_T(MYD_T.Mean_ScanTime >= startDate & MYD_T.Mean_ScanTime <= endDate, :);

% Remove the variable 'Filename' from MOD_T and MYD_T
MOD_T = removevars(MOD_T, 'Filename');
MYD_T = removevars(MYD_T, 'Filename');

% Step 1: Floor times to 2-hour bins
MOD2h = dateshift(MOD_T.Mean_ScanTime, 'start', 'hour');
MOD2h.Hour = floor(MOD2h.Hour / binHours) * binHours;

MYD2h = dateshift(MYD_T.Mean_ScanTime, 'start', 'hour');
MYD2h.Hour = floor(MYD2h.Hour / binHours) * binHours;

% Step 2: Add as temporary column
MOD_T.Time2h = MOD2h;
MYD_T.Time2h = MYD2h;

% Step 3: Identify numeric columns (exclude time columns)
MOD_numericVars = setdiff(MOD_T.Properties.VariableNames, {'Mean_ScanTime','Time2h'});
MYD_numericVars = setdiff(MYD_T.Properties.VariableNames, {'Mean_ScanTime','Time2h'});

% Step 4: Group by 2-hour bins and calculate nanmean
MOD_T_2h = varfun(@nanmean, MOD_T, 'InputVariables', MOD_numericVars, ...
                  'GroupingVariables', 'Time2h');
MYD_T_2h = varfun(@nanmean, MYD_T, 'InputVariables', MYD_numericVars, ...
                  'GroupingVariables', 'Time2h');

% Step 5: Rename columns to match original names
MOD_T_2h.Properties.VariableNames{'Time2h'} = 'Time';
MYD_T_2h.Properties.VariableNames{'Time2h'} = 'Time';

for k = 1:length(MOD_numericVars)
    oldName = ['nanmean_' MOD_numericVars{k}];
    MOD_T_2h.Properties.VariableNames{strcmp(MOD_T_2h.Properties.VariableNames, oldName)} = MOD_numericVars{k};
end

for k = 1:length(MYD_numericVars)
    oldName = ['nanmean_' MYD_numericVars{k}];
    MYD_T_2h.Properties.VariableNames{strcmp(MYD_T_2h.Properties.VariableNames, oldName)} = MYD_numericVars{k};
end

% Step 6: Keep only Time + numeric variables
H2_MOD_T = MOD_T_2h(:, [{'Time'}, MOD_numericVars]);
H2_MYD_T = MYD_T_2h(:, [{'Time'}, MYD_numericVars]);

% Rename the Mean_AOD column
H2_MYD_T.Properties.VariableNames{'Mean_AOD'} = 'MYD_AOD';
H2_MOD_T.Properties.VariableNames{'Mean_AOD'} = 'MOD_AOD';

% ----- 13b. Box west of the site -----
MOD_T = readtable('MOD04_MeanAOD_1deg_QA3_stddev_032226WEST');
MYD_T = readtable('MYD04_MeanAOD_1deg_QA3_stddev_032226WEST');

startDate = datetime(2023,2,15,0,0,0);
endDate   = datetime(2024,2,15,23,59,59);

% Filter MOD_T
MOD_T = MOD_T(MOD_T.Mean_ScanTime >= startDate & MOD_T.Mean_ScanTime <= endDate, :);

% Filter MYD_T
MYD_T = MYD_T(MYD_T.Mean_ScanTime >= startDate & MYD_T.Mean_ScanTime <= endDate, :);

% Remove the variable 'Filename' from MOD_T and MYD_T
MOD_T = removevars(MOD_T, 'Filename');
MYD_T = removevars(MYD_T, 'Filename');

% Step 1: Floor times to 2-hour bins
MOD2h = dateshift(MOD_T.Mean_ScanTime, 'start', 'hour');
MOD2h.Hour = floor(MOD2h.Hour / binHours) * binHours;

MYD2h = dateshift(MYD_T.Mean_ScanTime, 'start', 'hour');
MYD2h.Hour = floor(MYD2h.Hour / binHours) * binHours;

% Step 2: Add as temporary column
MOD_T.Time2h = MOD2h;
MYD_T.Time2h = MYD2h;

% Step 3: Identify numeric columns (exclude time columns)
MOD_numericVars = setdiff(MOD_T.Properties.VariableNames, {'Mean_ScanTime','Time2h'});
MYD_numericVars = setdiff(MYD_T.Properties.VariableNames, {'Mean_ScanTime','Time2h'});

% Step 4: Group by 2-hour bins and calculate nanmean
MOD_T_2h = varfun(@nanmean, MOD_T, 'InputVariables', MOD_numericVars, ...
                  'GroupingVariables', 'Time2h');
MYD_T_2h = varfun(@nanmean, MYD_T, 'InputVariables', MYD_numericVars, ...
                  'GroupingVariables', 'Time2h');

% Step 5: Rename columns to match original names
MOD_T_2h.Properties.VariableNames{'Time2h'} = 'Time';
MYD_T_2h.Properties.VariableNames{'Time2h'} = 'Time';

for k = 1:length(MOD_numericVars)
    oldName = ['nanmean_' MOD_numericVars{k}];
    MOD_T_2h.Properties.VariableNames{strcmp(MOD_T_2h.Properties.VariableNames, oldName)} = MOD_numericVars{k};
end

for k = 1:length(MYD_numericVars)
    oldName = ['nanmean_' MYD_numericVars{k}];
    MYD_T_2h.Properties.VariableNames{strcmp(MYD_T_2h.Properties.VariableNames, oldName)} = MYD_numericVars{k};
end

% Step 6: Keep only Time + numeric variables
H2_MOD_TWEST = MOD_T_2h(:, [{'Time'}, MOD_numericVars]);
H2_MYD_TWEST = MYD_T_2h(:, [{'Time'}, MYD_numericVars]);

% ----- 13c. Box east of the site -----
MOD_T = readtable('MOD04_MeanAOD_1deg_QA3_stddev_032226EAST');
MYD_T = readtable('MYD04_MeanAOD_1deg_QA3_stddev_032226EAST');

startDate = datetime(2023,2,15,0,0,0);
endDate   = datetime(2024,2,15,23,59,59);

% Filter MOD_T
MOD_T = MOD_T(MOD_T.Mean_ScanTime >= startDate & MOD_T.Mean_ScanTime <= endDate, :);

% Filter MYD_T
MYD_T = MYD_T(MYD_T.Mean_ScanTime >= startDate & MYD_T.Mean_ScanTime <= endDate, :);

% Remove the variable 'Filename' from MOD_T and MYD_T
MOD_T = removevars(MOD_T, 'Filename');
MYD_T = removevars(MYD_T, 'Filename');

% Step 1: Floor times to 2-hour bins
MOD2h = dateshift(MOD_T.Mean_ScanTime, 'start', 'hour');
MOD2h.Hour = floor(MOD2h.Hour / binHours) * binHours;

MYD2h = dateshift(MYD_T.Mean_ScanTime, 'start', 'hour');
MYD2h.Hour = floor(MYD2h.Hour / binHours) * binHours;

% Step 2: Add as temporary column
MOD_T.Time2h = MOD2h;
MYD_T.Time2h = MYD2h;

% Step 3: Identify numeric columns (exclude time columns)
MOD_numericVars = setdiff(MOD_T.Properties.VariableNames, {'Mean_ScanTime','Time2h'});
MYD_numericVars = setdiff(MYD_T.Properties.VariableNames, {'Mean_ScanTime','Time2h'});

% Step 4: Group by 2-hour bins and calculate nanmean
MOD_T_2h = varfun(@nanmean, MOD_T, 'InputVariables', MOD_numericVars, ...
                  'GroupingVariables', 'Time2h');
MYD_T_2h = varfun(@nanmean, MYD_T, 'InputVariables', MYD_numericVars, ...
                  'GroupingVariables', 'Time2h');

% Step 5: Rename columns to match original names
MOD_T_2h.Properties.VariableNames{'Time2h'} = 'Time';
MYD_T_2h.Properties.VariableNames{'Time2h'} = 'Time';

for k = 1:length(MOD_numericVars)
    oldName = ['nanmean_' MOD_numericVars{k}];
    MOD_T_2h.Properties.VariableNames{strcmp(MOD_T_2h.Properties.VariableNames, oldName)} = MOD_numericVars{k};
end

for k = 1:length(MYD_numericVars)
    oldName = ['nanmean_' MYD_numericVars{k}];
    MYD_T_2h.Properties.VariableNames{strcmp(MYD_T_2h.Properties.VariableNames, oldName)} = MYD_numericVars{k};
end

% Step 6: Keep only Time + numeric variables
H2_MOD_TEAST = MOD_T_2h(:, [{'Time'}, MOD_numericVars]);
H2_MYD_TEAST = MYD_T_2h(:, [{'Time'}, MYD_numericVars]);

% Rename Mean_AOD so each satellite and box stays separate after merging
H2_MYD_TEAST.Properties.VariableNames{'Mean_AOD'} = 'MYD_AODEAST';
H2_MOD_TEAST.Properties.VariableNames{'Mean_AOD'} = 'MOD_AODEAST';

H2_MYD_TWEST.Properties.VariableNames{'Mean_AOD'} = 'MYD_AODWEST';
H2_MOD_TWEST.Properties.VariableNames{'Mean_AOD'} = 'MOD_AODWEST';

%% ========================================================================
%  14. CRITICAL ACTIVATION DIAMETER (Dcrit) AT SCRIPPS PIER
%  ========================================================================
%  Input : Pier_Dcrit032626.mat (one row per supersaturation: 0.1, 0.2, 0.4,
%          0.6, 0.8, 1.0%)
%  Avg   : 2-hr nanmean using retime
%  Output: DcritT_2hr

cd 'D:\EPCAPE Correlations'

% Load variables
load('Pier_Dcrit032626.mat');

% Transpose Pier_Dcrit so each row becomes a column
Dcrit_data = Pier_Dcrit';   % Now size = [time x 6]

% Manually assign each row to the desired variable names
Dcrit01 = Dcrit_data(:,1);
Dcrit02 = Dcrit_data(:,2);
Dcrit04 = Dcrit_data(:,3);
Dcrit06 = Dcrit_data(:,4);
Dcrit08 = Dcrit_data(:,5);
Dcrit10 = Dcrit_data(:,6);

% Create timetable with manual variable assignments
DcritTT = timetable(Pier_Dcrit_Time', Dcrit01, Dcrit02, Dcrit04, Dcrit06, Dcrit08, Dcrit10);

% Rename time dimension
DcritTT.Properties.DimensionNames{1} = 'Time';

% Retime to 2-hour averages using nanmean
DcritTT_2hr = retime(DcritTT, 'regular', @(x) nanmean(x), 'TimeStep', hours(2));

% Convert back to regular table
DcritT_2hr = timetable2table(DcritTT_2hr, 'ConvertRowTimes', true);
DcritT_2hr.Properties.VariableNames{1} = 'Time';

%% ========================================================================
%  15. MERGED SMPS/APS SIZE DISTRIBUTIONS AND MODE FITS
%  ========================================================================
%  Input : EPCAPE_Mode_Fits_070726.mat (number and mass size distributions for
%          the Aitken, accumulation, and coarse modes)
%  Steps : 1. integrate each size distribution to get total number (N) and
%             mass (M) per mode, plus the diameter of the number and mass peaks
%          2. compute accumulation-mode volume from the number distribution
%          3. set values below the 1st and above the 99th percentile to NaN
%             for N_acc, N_coarse, M_acc (and V_acc), and M_coarse
%  Avg   : 2-hr nanmean, plus 2-hr standard deviation of N_acc and 2-hr mode
%          of the k-means size-distribution cluster
%  Output: H2_SMPSAPS_Mode_T

load('EPCAPE_Mode_Fits_070726.mat')
% Make diameter a column vector
SMPSAPS_diameter = SMPSAPS_diameter(:);  % 100x1

% Compute log10 bin edges and dlogDp
logDp  = log10(SMPSAPS_diameter);     % 100x1
dlogDp = diff(logDp);                 % 99x1
dlogDp = [dlogDp; dlogDp(end)];       % 100x1

% Number of PSDs
num_PSDs = size(SMPSAPS_PNSD_Acc_Matrix, 2);

% =========================
% Preallocate (Accumulation)
% =========================
N_total_Acc       = nan(num_PSDs,1);
D_peak_number_Acc = nan(num_PSDs,1);
M_total_Acc       = nan(num_PSDs,1);
D_peak_mass_Acc   = nan(num_PSDs,1);

% =========================
% Preallocate (Aitken)
% =========================
N_total_Ait       = nan(num_PSDs,1);
D_peak_number_Ait = nan(num_PSDs,1);
M_total_Ait       = nan(num_PSDs,1);
D_peak_mass_Ait   = nan(num_PSDs,1);

% =========================
% Preallocate (Coarse)
% =========================
N_total_Coarse       = nan(num_PSDs,1);
D_peak_number_Coarse = nan(num_PSDs,1);
M_total_Coarse       = nan(num_PSDs,1);
D_peak_mass_Coarse   = nan(num_PSDs,1);

V_total_Acc = NaN(1, num_PSDs)';

% Volume per particle in each diameter bin
Dp_m = SMPSAPS_diameter * 1e-6;   % microns -> meters
r = Dp_m / 2;
V_bin = (4/3) * pi * r.^3;        % m^3 per particle

% =========================
% Loop over time
% =========================
for i = 1:num_PSDs

    % ---------- ACCUMULATION ----------
    PNSD = SMPSAPS_PNSD_Acc_Matrix(:,i);
    PMSD = SMPSAPS_PMSD_Acc_Matrix(:,i);

    if ~all(isnan(PNSD))
        N_total_Acc(i) = sum(PNSD .* dlogDp, 'omitnan');
        [~, idx] = max(PNSD);
        D_peak_number_Acc(i) = SMPSAPS_diameter(idx);
    end

    if ~all(isnan(PMSD))
        M_total_Acc(i) = sum(PMSD .* dlogDp, 'omitnan');
        [~, idx] = max(PMSD);
        D_peak_mass_Acc(i) = SMPSAPS_diameter(idx);
    end

    % ---- Volume (from PNSD, same bins as N_total) ----
    if ~all(isnan(PNSD))
        dV = PNSD .* V_bin .* dlogDp * 1e6;   % cm^-3 -> m^-3 conversion
        V_total_Acc(i) = sum(dV, 'omitnan');
    end

    % ---------- AITKEN ----------
    PNSD = SMPSAPS_PNSD_Ait_Matrix(:,i);
    PMSD = SMPSAPS_PMSD_Ait_Matrix(:,i);

    if ~all(isnan(PNSD))
        N_total_Ait(i) = sum(PNSD .* dlogDp, 'omitnan');
        [~, idx] = max(PNSD);
        D_peak_number_Ait(i) = SMPSAPS_diameter(idx);
    end

    if ~all(isnan(PMSD))
        M_total_Ait(i) = sum(PMSD .* dlogDp, 'omitnan');
        [~, idx] = max(PMSD);
        D_peak_mass_Ait(i) = SMPSAPS_diameter(idx);
    end

    % ---------- COARSE ----------
    PNSD = SMPSAPS_PNSD_Coarse_Matrix(:,i);
    PMSD = SMPSAPS_PMSD_Coarse_Matrix(:,i);

    if ~all(isnan(PNSD))
        N_total_Coarse(i) = sum(PNSD .* dlogDp, 'omitnan');
        [~, idx] = max(PNSD);
        D_peak_number_Coarse(i) = SMPSAPS_diameter(idx);
    end

    if ~all(isnan(PMSD))
        M_total_Coarse(i) = sum(PMSD .* dlogDp, 'omitnan');
        [~, idx] = max(PMSD);
        D_peak_mass_Coarse(i) = SMPSAPS_diameter(idx);
    end

end

% ----- Remove outliers: values below the 1st or above the 99th percentile -----
% (p2 and p98 hold the 1st and 99th percentiles)

% Accumulation-mode number
x = N_total_Acc;

% Compute percentile thresholds (ignore NaNs)
p2  = prctile(x, 1);
p98 = prctile(x, 99);

% Set extremes to NaN
x(x <= p2 | x >= p98) = NaN;

% Assign back
N_total_Acc = x;

% Coarse-mode number
x = N_total_Coarse;

% Compute percentile thresholds (ignore NaNs)
p2  = prctile(x, 1);
p98 = prctile(x, 99);

% Set extremes to NaN
x(x <= p2 | x >= p98) = NaN;
% Assign back
N_total_Coarse = x;

% Accumulation-mode mass (accumulation-mode volume uses the same mask)
x = M_total_Acc;

% Compute percentile thresholds (ignore NaNs)
p2  = prctile(x, 1);
p98 = prctile(x, 99);

% Set extremes to NaN
M_total_Acc(x <= p2 | x >= p98) = NaN;
V_total_Acc(x <= p2 | x >= p98) = NaN;
x(x <= p2 | x >= p98) = NaN;

% Assign back
M_total_Acc = x;

% Coarse-mode mass
x = M_total_Coarse;

% Compute percentile thresholds (ignore NaNs)
p2  = prctile(x, 1);
p98 = prctile(x, 99);

% Set extremes to NaN
%M_total_Coarse(x <= p2 | x >= p98) = NaN;
x(x <= p2 | x >= p98) = NaN;

% Assign back
M_total_Coarse = x;

% =========================
% Column vectors (safe for tables)
% =========================
SMPSAPS_time          = SMPSAPS_time(:);
SMPSAPS_kmeanscluster = SMPSAPS_kmeanscluster(:);

SMPSAPS_Mode_T = table(...
    SMPSAPS_time, SMPSAPS_kmeanscluster, ...
    N_total_Ait, M_total_Ait, D_peak_number_Ait, D_peak_mass_Ait, ...
    N_total_Acc, M_total_Acc, D_peak_number_Acc, D_peak_mass_Acc, ...
    N_total_Coarse, M_total_Coarse, D_peak_number_Coarse, D_peak_mass_Coarse, SMPSAPS_DHM, V_total_Acc, ...
    'VariableNames', { ...
        'Time', 'KMeansCluster', ...
        'N_Aitken', 'M_Aitken', 'Dpk_N_Aitken', 'Dpk_M_Aitken', ...
        'N_Accumulation', 'M_Accumulation', 'Dpk_N_Accumulation', 'Dpk_M_Accumulation', ...
        'N_Coarse', 'M_Coarse', 'Dpk_N_Coarse', 'Dpk_M_Coarse','Pier_DHM', 'V_total_Acc' ...
    } ...
);

% Step 1: Floor Time to 2-hour bins
Time2h = dateshift(SMPSAPS_Mode_T.Time, 'start', 'hour');
Time2h.Hour = floor(Time2h.Hour/binHours)*binHours;

% Step 2: Add temporary Time2h column
SMPSAPS_Mode_T.Time2h = Time2h;

% Step 3: Identify numeric variables (exclude Time + grouping vars)
numericVars = SMPSAPS_Mode_T.Properties.VariableNames;
numericVars = setdiff(numericVars, {'Time','Time2h'});

% Step 4: Group by 2-hour bins and calculate nanmean
SMPSAPS_2h = varfun(@nanmean, SMPSAPS_Mode_T, ...
                    'InputVariables', numericVars, ...
                    'GroupingVariables', 'Time2h');

% Step 4b: Group by 2-hour bins and calculate nanstd for N_Accumulation only
SMPSAPS_2h_std = varfun(@nanstd, SMPSAPS_Mode_T, ...
'InputVariables', 'N_Accumulation', ...
'GroupingVariables', 'Time2h');

% Step 5: Rename columns to match original names
SMPSAPS_2h.Properties.VariableNames{'Time2h'} = 'Time';

for k = 1:length(numericVars)
    oldName = ['nanmean_' numericVars{k}];
    SMPSAPS_2h.Properties.VariableNames{ ...
        strcmp(SMPSAPS_2h.Properties.VariableNames, oldName) ...
        } = numericVars{k};
end

% Step 5b: Rename std column and merge into SMPSAPS_2h
SMPSAPS_2h_std.Properties.VariableNames{'nanstd_N_Accumulation'} = 'N_Accumulation_std';
SMPSAPS_2h.N_Accumulation_std = SMPSAPS_2h_std.N_Accumulation_std;

% Step 6: Keep only Time + numeric variables + std column
H2_SMPSAPS_Mode_T = SMPSAPS_2h(:, [{'Time'}, numericVars, {'N_Accumulation_std'}]);

% Replace the averaged k-means cluster with the 2-hr mode (cluster is categorical)
cluster_mode = varfun(@mode, SMPSAPS_Mode_T, ...
    'InputVariables', 'KMeansCluster', ...
    'GroupingVariables', 'Time2h');

% Overwrite KMeansCluster with mode values
H2_SMPSAPS_Mode_T.KMeansCluster = cluster_mode.mode_KMeansCluster;

%% ========================================================================
%  16. PM1, PM2.5, PM10, SURFACE AREA, AND VOLUME FROM SMPS/APS
%  ========================================================================
%  Input : SMPSAPSPM071326_withSAandV.csv (the last file read below; the
%          earlier reads are overwritten)
%  Clean : remove rows with missing PM1
%  Avg   : 2-hr nanmean
%  Output: SMPSPM_2h

cd 'D:\EPCAPE Correlations'

SMPSPM = readtable('SMPSAPSPM031926.csv')

% Load table (only the last file read is used)
SMPSPM = readtable('SMPSAPSPM031926.csv');
SMPSPM = readtable('SMPSAPSPM031926_withSA.csv');
SMPSPM = readtable('SMPSAPSPM071326_withSAandV.csv');

% Remove rows with missing PM1
SMPSPM = SMPSPM(~isnan(SMPSPM.PM1), :);

% Step 1: Floor times to 2-hour bins
Time2h = dateshift(SMPSPM.SMPSAPSTime, 'start', 'hour');
Time2h.Hour = floor(Time2h.Hour / binHours) * binHours;

% Step 2: Add 2-hour column
SMPSPM.Time2h = Time2h;

% Step 3: Compute 2-hour means
SMPSPM_2h = varfun(@nanmean, SMPSPM, ...
    'InputVariables', {'PM1','PM25','PM10','SA1','SA25','SA10','V1','V25'}, ...
    'GroupingVariables', 'Time2h');

% Step 4: Clean variable names
SMPSPM_2h.Properties.VariableNames = ...
    {'Time2h','GroupCount','PM1','PM25','PM10','SA1','SA25','SA10','V1','V25'};

% Step 5: Rename columns to match original names
SMPSPM_2h.Properties.VariableNames{'Time2h'} = 'Time';

disp(SMPSPM_2h(1:5,:))

%% ========================================================================
%  17. EFFECTIVE DENSITY AT SCRIPPS PIER
%  ========================================================================
%  Input : bb2743661p_28_1.nc
%  Avg   : 2-hr mean using retime
%  Output: PierDensityT_2hr

PierDensity = ncread('bb2743661p_28_1.nc','Effective_Density');
PierDensityTime = ncread('bb2743661p_28_1.nc','Time');
PierDensityTime_dt = datetime(PierDensityTime, 'ConvertFrom', 'datenum');

% 1. Convert datenum -> datetime
PierDensityTime_dt = datetime(PierDensityTime, 'ConvertFrom', 'datenum');

% 2. Create table
DensityT = table(PierDensityTime_dt, PierDensity);

% 3. Convert to timetable
DensityTT = table2timetable(DensityT, 'RowTimes', 'PierDensityTime_dt');

% 4. Take 2-hour nanmean (retime automatically ignores NaNs with 'mean')
PierDensityTT_2hr = retime(DensityTT, 'regular', 'mean', 'TimeStep', hours(2));

% 5. Convert back to table
PierDensityT_2hr = timetable2table(PierDensityTT_2hr);
PierDensityT_2hr.Properties.VariableNames{'PierDensityTime_dt'} = 'Time';

%% ========================================================================
%  18. PLANETARY BOUNDARY LAYER HEIGHT (TWO SOURCES)
%  ========================================================================
%  18a. EPCAPE_PBLHdata.mat -> pblh_table  (variable pblh)
%  18b. BL_depth.csv        -> pblh_table2 (variable pblh2)
%  Avg   : 2-hr mean using retime

cd 'D:'\'EPCAPE Correlations'\
% ----- 18a. EPCAPE_PBLHdata.mat -----
load('EPCAPE_PBLHdata.mat')

% Step 1: Convert datenum to datetime
pblh_time_dt = datetime(pblh_time, 'ConvertFrom', 'datenum');

% Step 2: Make a timetable
pblh_tt = timetable(pblh_time_dt, pblh);

% Step 3: Retiming to 2-hour means using hours(2)
pblh_tt_2h = retime(pblh_tt, 'regular', 'mean', 'TimeStep', hours(2));

% Step 4: Convert back to table
pblh_table = timetable2table(pblh_tt_2h);

% Step 5: Rename the time column
pblh_table.Properties.VariableNames{'pblh_time_dt'} = 'Time';

% ----- 18b. BL_depth.csv -----
cd 'D:\Paper 2\'
pblh_t = readtable('BL_depth.csv');

% Step 1: Convert table to timetable
pblh_tt = table2timetable(pblh_t);

% Step 2: Retime to 2-hour means
pblh_tt_2h = retime(pblh_tt, 'regular', 'mean', ...
    'TimeStep', hours(2));

% Step 3: Convert back to table
pblh_table2 = timetable2table(pblh_tt_2h);

% Step 4: Rename time and depth columns
pblh_table2.Properties.VariableNames{'Time'} = 'Time';

pblh_table2.Properties.VariableNames{'Depth'} = 'pblh2';

%% ========================================================================
%  19. AEROSOL CHEMICAL SPECIATION MONITOR (ACSM)
%  ========================================================================
%  Input : ACSMJunkRemovedAmmoniumFixed10225.mat
%  Vars  : sulfate, organics, nitrate, chloride, ammonium
%  Avg   : 2-hr nanmean using retime
%  Output: ACSM_table2h

cd 'D:'\'EPCAPE Correlations'\
load('ACSMJunkRemovedAmmoniumFixed10225.mat')

% Step 1: Create timetable
ACSM_tt = timetable(ACSMTime, ...
                    ACSMSulfateJunkRemoved, ...
                    ACSMOrganicsJunkRemoved, ...
                    ACSMNitrateJunkRemoved, ...
                    ACSMChlorideJunkRemoved, ...
                    ACSMAmmoniumJunkRemoved2);

% Step 2: Rename variables
ACSM_tt.Properties.VariableNames = {'Sulfate', 'Org', 'Nit', 'Chl', 'Amm'};

% Step 3: Retiming to 2-hour intervals using nanmean
ACSM_tt2h = retime(ACSM_tt, 'regular', @nanmean, 'TimeStep', hours(2));

% Step 4: Convert back to table
ACSM_table2h = timetable2table(ACSM_tt2h);
% Rename the first column to 'Time'
ACSM_table2h.Properties.VariableNames{1} = 'Time';

%% ========================================================================
%  20. RELATIVE HUMIDITY AT SCRIPPS PIER (1-min)
%  ========================================================================
%  Input : PierAOSMinuteMean012725.csv
%  Clean : keep RH >= 0
%  Avg   : 2-hr mean using retime
%  Output: PierMet_2hr

PierMet_T = readtable('PierAOSMinuteMean012725.csv');

PierMet_T = PierMet_T(:, {'Datetime','RelativeHumidity'});
PierMet_T.Properties.VariableNames{'Datetime'} = 'Time';
PierMet_T = PierMet_T(PierMet_T.RelativeHumidity >= 0, :);

% Convert to timetable
PierMet_TT = table2timetable(PierMet_T);

% Take 2-hour averages
PierMet_2hr = retime(PierMet_TT,'regular','mean','TimeStep',hours(2));
PierMet_2hr = timetable2table(PierMet_2hr);

%% ========================================================================
%  21. BACK-TRAJECTORY CLUSTERS
%  ========================================================================
%  Input : EPCAPE_trajectory_cluster_UTC_updated.csv
%  Avg   : hourly (carry the last value forward), then 2-hr MODE (categorical)
%  Output: Traj_table2h

TTraj = readtable('EPCAPE_trajectory_cluster_UTC_updated.csv');
Traj_Time = TTraj.DatetimeUTC;
Traj = TTraj.ARMTRAJSFC;

% Step 1: Create timetable
Traj_tt = timetable(Traj_Time, Traj);
Traj_tt.Properties.VariableNames = {'ARMTRAJCluster'};

% Step 2: Retiming to 1-hourly by carrying forward last value
Traj_tt1h = retime(Traj_tt, 'regular', 'previous', 'TimeStep', hours(1));

% Step 3: Retiming to 2-hourly using mode
Traj_tt2h = retime(Traj_tt1h, 'regular', @mode, 'TimeStep', hours(2));

% Step 4: Convert back to table and rename first column
Traj_table2h = timetable2table(Traj_tt2h);
Traj_table2h.Properties.VariableNames{1} = 'Time';

%% ========================================================================
%  22. HYGROSCOPICITY (kappa) AND UCVF
%  ========================================================================
%  Both files are already 2-hr averages, so they are only read in.
%  Output: H2_Kappa, H2_UCVF

cd 'D:\Paper 2'
H2_Kappa = readtable('PierKappa041526.csv');

H2_UCVF = readtable('UCVF_2hr.csv');

%% ========================================================================
%  23. NEPHELOMETER DRY AND WET SCATTERING
%  ========================================================================
%  Input : DryWetNeph071326.csv
%  Steps : 1. split by impactor size cut (impactor_state_DryT = 1 for PM1,
%             10 for PM10)
%          2. add a suffix to every variable name (_PM1DRY, _PM10DRY,
%             _PM1WET, _PM10WET) so they stay separate after merging
%  Avg   : 2-hr mean using retime
%  Output: H2_NephWetDryPM1DRY, H2_NephWetDryPM10DRY,
%          H2_NephWetDryPM1WET, H2_NephWetDryPM10WET

cd('D:\Paper 2')
H2_NephWetDry = readtable('DryWetNeph071326.csv');

% Split into PM1 and PM10 subsets
% ----- Dry scattering: split into PM1 and PM10 -----
H2_NephWetDryPM1DRY  = H2_NephWetDry(H2_NephWetDry.impactor_state_DryT == 1, :);
H2_NephWetDryPM10DRY = H2_NephWetDry(H2_NephWetDry.impactor_state_DryT == 10, :);

% Add '_PM1DRY' to all variable names except Time

varNames = H2_NephWetDryPM1DRY.Properties.VariableNames;
varsToRename = setdiff(varNames, {'Time'});

newNames = strcat(varsToRename, '_PM1DRY');

H2_NephWetDryPM1DRY = renamevars(H2_NephWetDryPM1DRY, varsToRename, newNames);
% Add '_PM10DRY' to all variable names except Time

varNames = H2_NephWetDryPM10DRY.Properties.VariableNames;
varsToRename = setdiff(varNames, {'Time'});

newNames = strcat(varsToRename, '_PM10DRY');

H2_NephWetDryPM10DRY = renamevars(H2_NephWetDryPM10DRY, varsToRename, newNames);
% PM1 dry: convert to timetable, take 2-hour means, convert back
H2_NephWetDryPM1DRY = table2timetable(H2_NephWetDryPM1DRY, 'RowTimes', 'Time');
H2_NephWetDryPM1DRY = retime(H2_NephWetDryPM1DRY, 'regular', 'mean', 'TimeStep', hours(2));
H2_NephWetDryPM1DRY = timetable2table(H2_NephWetDryPM1DRY, 'ConvertRowTimes', true);

% PM10 dry: convert to timetable, take 2-hour means, convert back
H2_NephWetDryPM10DRY = table2timetable(H2_NephWetDryPM10DRY, 'RowTimes', 'Time');
H2_NephWetDryPM10DRY = retime(H2_NephWetDryPM10DRY, 'regular', 'mean', 'TimeStep', hours(2));
H2_NephWetDryPM10DRY = timetable2table(H2_NephWetDryPM10DRY, 'ConvertRowTimes', true);

% ----- Wet scattering: split into PM1 and PM10 -----
H2_NephWetDryPM1WET  = H2_NephWetDry(H2_NephWetDry.impactor_state_DryT == 1, :);
H2_NephWetDryPM10WET = H2_NephWetDry(H2_NephWetDry.impactor_state_DryT == 10, :);

% Add '_PM1WET' to all variable names except Time

varNames = H2_NephWetDryPM1WET.Properties.VariableNames;
varsToRename = setdiff(varNames, {'Time'});

newNames = strcat(varsToRename, '_PM1WET');

H2_NephWetDryPM1WET = renamevars(H2_NephWetDryPM1WET, varsToRename, newNames);
% Add '_PM10WET' to all variable names except Time

varNames = H2_NephWetDryPM10WET.Properties.VariableNames;
varsToRename = setdiff(varNames, {'Time'});

newNames = strcat(varsToRename, '_PM10WET');

H2_NephWetDryPM10WET = renamevars(H2_NephWetDryPM10WET, varsToRename, newNames);
% PM1 wet: convert to timetable, take 2-hour means, convert back
H2_NephWetDryPM1WET = table2timetable(H2_NephWetDryPM1WET, 'RowTimes', 'Time');
H2_NephWetDryPM1WET = retime(H2_NephWetDryPM1WET, 'regular', 'mean', 'TimeStep', hours(2));
H2_NephWetDryPM1WET = timetable2table(H2_NephWetDryPM1WET, 'ConvertRowTimes', true);

% PM10 wet: convert to timetable, take 2-hour means, convert back
H2_NephWetDryPM10WET = table2timetable(H2_NephWetDryPM10WET, 'RowTimes', 'Time');
H2_NephWetDryPM10WET = retime(H2_NephWetDryPM10WET, 'regular', 'mean', 'TimeStep', hours(2));
H2_NephWetDryPM10WET = timetable2table(H2_NephWetDryPM10WET, 'ConvertRowTimes', true);

%% ========================================================================
%  24. WELL-MIXED BOUNDARY LAYER FLAG
%  ========================================================================
%  Input : PelayoWellMixed052926.csv (read here; not part of the merge below)

PelayoWellMixedT = readtable('PelayoWellMixed052926.csv');

%% ========================================================================
%  25. MERGE ALL 2-HR TABLES ON TIME -> H2_All
%  ========================================================================
%  All 2-hr tables are joined with an outer join on Time, so every 2-hr
%  period with data from any dataset is kept. Missing values are NaN.
%  Rows after 16 Feb 2024 are then removed.

cd 'D:\EPCAPE Correlations'

% List of all 2-hr tables to merge
tablesList = { ...
    H2_SolCCN_T, H2_CCN_T, ...
    H2_CSPHOT_T, ...
    H2_VIIRS_1deg_T, ...
    H2_Nd_T, ...
    H2_SatCorps_T, ...
    H2_TSI_T, ...
    H2_MOD_T, ...
    H2_MYD_T, ...
    H2_SMPSAPS_Mode_T, SMPSPM_2h ,PierMet_2hr, ACSM_table2h, pblh_table, DcritT_2hr, Traj_table2h, H2_VIIRS_1deg_TWEST, H2_VIIRS_1deg_TEAST, H2_MYD_TEAST, H2_MYD_TWEST, H2_MOD_TEAST, H2_MOD_TWEST, H2_Kappa, PierDensityT_2hr, H2_UCVF, H2_NephWetDryPM1DRY, H2_NephWetDryPM10DRY, H2_NephWetDryPM1WET, H2_NephWetDryPM10WET, H2_Fog_T, H2_MERRA_T, H2_NDROP_T, pblh_table2, T_Low_2h, CSPHOT_T_2h_std};
% -----------------------------
% Merge tables using outer join on Time
% -----------------------------
H2_All = tablesList{1};

for k = 2:length(tablesList)
    H2_All = outerjoin( ...
        H2_All, tablesList{k}, ...
        'Keys', 'Time', ...
        'MergeKeys', true );
end

% -----------------------------
% Sort by time
% -----------------------------
H2_All = sortrows(H2_All, 'Time');

% -----------------------------
% (Optional) Quick checks
% -----------------------------
disp('Merged table size:');
disp(size(H2_All));

disp('Time range:');
disp([min(H2_All.Time) max(H2_All.Time)]);

% Define cutoff time
cutoffTime = datetime(2024, 2, 16, 0, 0, 0);

% Keep only rows at or before the cutoff
H2_All = H2_All(H2_All.Time <= cutoffTime, :);

%% ========================================================================
%  26. DERIVED VARIABLES IN H2_All
%  ========================================================================
%  Combined satellite AOD, retrieval ratios, gap-filled CCN, PM cleanup,
%  mode sums and ratios, wet mass, aerosol index (AI), and the final
%  time range. Columns ending in _H2_All and _right were created by
%  outerjoin when two merged tables had a column with the same name.

% Combined MODIS AOD: Terra (MOD) where available, otherwise Aqua (MYD)
x = H2_All.MOD_AOD;
useMYD = isnan(x);
x(useMYD) = H2_All.MYD_AOD(useMYD);
H2_All.MODMYD_AOD = x;

% Combined satellite AOD: MODIS where available, otherwise VIIRS
x = H2_All.MODMYD_AOD;
useMYD = isnan(x);
x(useMYD) = H2_All.AOD_550(useMYD);
H2_All.Satellite_AOD = x;

% Combined MODIS AOD for the east box (Terra, otherwise Aqua)
x = H2_All.MOD_AODEAST;
useMYD = isnan(x);
x(useMYD) = H2_All.MYD_AODEAST(useMYD);
H2_All.MODMYD_AODEAST = x;

% Combined MODIS AOD for the west box (Terra, otherwise Aqua)
x = H2_All.MOD_AODWEST;
useMYD = isnan(x);
x(useMYD) = H2_All.MYD_AODWEST(useMYD);
H2_All.MODMYD_AODWEST = x;

% Combined MODIS count of QA = 3 pixels (this block is repeated three times;
% the result is the same each time)
x = H2_All.NumQA3_H2_All;
useMYD = isnan(x);
x(useMYD) = H2_All.NumQA3_right(useMYD);
H2_All.MODMYDNumQA3 = x;

x = H2_All.NumQA3_H2_All;
useMYD = isnan(x);
x(useMYD) = H2_All.NumQA3_right(useMYD);
H2_All.MODMYDNumQA3 = x;

x = H2_All.NumQA3_H2_All;
useMYD = isnan(x);
x(useMYD) = H2_All.NumQA3_right(useMYD);
H2_All.MODMYDNumQA3 = x;

% Combined MODIS Angstrom exponent
x = H2_All.Mean_Ang1_H2_All;
useMYD = isnan(x);
x(useMYD) = H2_All.Mean_Ang1_right(useMYD);
H2_All.MODIS_Angstrom = x;

% Combined MODIS total pixel count, then fraction of pixels retrieved
% for MODIS and VIIRS
x = H2_All.TotalPixels_H2_All;
useMYD = isnan(x);
x(useMYD) = H2_All.TotalPixels_right(useMYD);
H2_All.MODMYDTotalPixels = x;
H2_All.MODMYDRetrievedRatio = H2_All.MODMYDNumQA3 ./ H2_All.MODMYDTotalPixels;
H2_All.VIIRSRetrievedRatio = H2_All.Valid_AOD_Pixels ./ H2_All.Total_Pixels;

% CCN at 0.2% supersaturation: Scripps Pier (CN02), gaps filled with Mt. Soledad (CCN02)
H2_All.CN02_filled = H2_All.CN02;  % start with primary
idx = isnan(H2_All.CN02_filled);    % where primary is missing
H2_All.CN02_filled(idx) = H2_All.CCN02(idx);  % fill from backup

% PM and surface area: zeros set to NaN
H2_All.PM1(H2_All.PM1 == 0)   = NaN;
H2_All.PM25(H2_All.PM25 == 0) = NaN;
H2_All.PM10(H2_All.PM10 == 0) = NaN;
H2_All.SA25(H2_All.SA25 == 0)   = NaN;
H2_All.SA1(H2_All.SA1 == 0) = NaN;
H2_All.SA10(H2_All.SA10 == 0) = NaN;

% Scale PM1 and PM2.5 by a dry density of 1.4 g cm-3
H2_All.PM1 = H2_All.PM1*1.4;
H2_All.PM25 = H2_All.PM25.*1.4;

% Mode sums and ratios
H2_All.Maccumcoarse = H2_All.M_Accumulation + H2_All.M_Coarse;
H2_All.Naccumcoarse = H2_All.N_Accumulation + H2_All.N_Coarse;
H2_All.MaccumoverMcoarse = H2_All.M_Accumulation ./ H2_All.M_Coarse;
H2_All.NaccumoverMcoarse = H2_All.N_Accumulation ./ H2_All.N_Coarse;

% PM: values above the 99th percentile set to NaN
vars = {'PM1','PM25','PM10'};

for i = 1:numel(vars)
    v = vars{i};

    % Compute 99th percentile
    pct99 = prctile(H2_All.(v), 99, 'all');

    % Set all values above 99th percentile to NaN
    H2_All.(v)(H2_All.(v) > pct99) = NaN;
end

% Convert RH from % to a fraction
H2_All.RelativeHumidity = H2_All.RelativeHumidity ./ 100;

% Wet mass from kappa-Kohler growth. The first version (with density) is
% overwritten by the second version; both are recalculated in Section 28.
H2_All.PM25_wet = H2_All.PM25 .* (1./H2_All.PierDensity) .* (1 + H2_All.kappa .* ...
    (H2_All.RelativeHumidity ./ (1 - H2_All.RelativeHumidity)));
H2_All.M_Accumulation_wet = H2_All.M_Accumulation .* (1./H2_All.PierDensity) .* (1 + H2_All.kappa .* ...
    (H2_All.RelativeHumidity ./ (1 - H2_All.RelativeHumidity)));
H2_All.PM1_wet = H2_All.PM1 .* (1./H2_All.PierDensity) .* (1 + H2_All.kappa .* ...
    (H2_All.RelativeHumidity ./ (1 - H2_All.RelativeHumidity)));

H2_All.PM25_wet = H2_All.PM25  .* (1 + H2_All.kappa .* ...
    (H2_All.RelativeHumidity ./ (1 - H2_All.RelativeHumidity)));
H2_All.M_Accumulation_wet = H2_All.M_Accumulation  .* (1 + H2_All.kappa .* ...
    (H2_All.RelativeHumidity ./ (1 - H2_All.RelativeHumidity)));
H2_All.PM1_wet = H2_All.PM1  .* (1 + H2_All.kappa .* ...
    (H2_All.RelativeHumidity ./ (1 - H2_All.RelativeHumidity)));

% Angstrom exponents: negative ground-based values set to NaN; MODIS
% values divided by 1000 (scale factor)
H2_All.Angstrom_440_870(H2_All.Angstrom_440_870 < 0) = NaN;
H2_All.MODIS_Angstrom = H2_All.MODIS_Angstrom./1000;

% Aerosol index (AI) = AOD x Angstrom exponent
H2_All.GroundAI = H2_All.AOD_500 .* H2_All.Angstrom_440_870;
H2_All.VIIRSAI = H2_All.AOD_550 .* H2_All.Angstrom_Exponent_H2_All;
H2_All.MODISAI = H2_All.MODMYD_AOD .* H2_All.MODIS_Angstrom;

% Final time range: 14 Feb 2023 - 15 Feb 2024
tStart = datetime(2023,2,14,0,0,0);
tEnd   = datetime(2024,2,15,0,0,0);

H2_All = H2_All(H2_All.Time >= tStart & H2_All.Time <= tEnd,:);

%% ========================================================================
%  27. UN-AVERAGED (RAW) DATA FOR THE TIME-WINDOW SENSITIVITY ANALYSIS
%  ========================================================================
%  Keeps the original (not 2-hr averaged) data for each main measurement,
%  limited to 15 Feb 2023 - 15 Feb 2024. MODIS and VIIRS are re-read here.
%  These RAW_ tables are used by the commented-out analysis at the end of
%  this section, which is not run.

cd 'D:\Paper 2'

MOD_T = readtable('MOD04_MeanAOD_Angstrom_1deg_QA3_050526.csv');
MYD_T = readtable('MYD04_MeanAOD_Angstrom_1deg_QA3_050526.csv');

cd 'D:\Paper 2';

VIIRS_1deg_T = readtable('VIIRS_CA_All_1deg_Min021626.csv');
VIIRS_1deg_T.Properties.VariableNames{'Scan_Time_Mean'} = 'Time';

tStart = datetime(2023,2,15,0,0,0);
tEnd   = datetime(2024,2,15,23,59,59);

RAW_CSPHOT = CSPHOT_T(:, {'Time','AOD_500'});
RAW_CSPHOT = RAW_CSPHOT(RAW_CSPHOT.Time >= tStart & RAW_CSPHOT.Time <= tEnd, :);

RAW_NDROP = NDROP_T2(:, {'Time','CDNC'});
RAW_NDROP = RAW_NDROP(RAW_NDROP.Time >= tStart & RAW_NDROP.Time <= tEnd, :);

RAW_SatCorps = Nd_T(:, {'Time','Nd'});
RAW_SatCorps = RAW_SatCorps(RAW_SatCorps.Time >= tStart & RAW_SatCorps.Time <= tEnd, :);

COMBINEDMODIS_T = [MOD_T; MYD_T];

RAW_MYD = MYD_T(:, {'Mean_ScanTime','Mean_AOD'});
RAW_MYD.Properties.VariableNames(strcmp(RAW_MYD.Properties.VariableNames,'Mean_ScanTime')) = {'Time'};
RAW_MYD.Properties.VariableNames{'Mean_AOD'} = 'MYD_AOD';
RAW_MYD = RAW_MYD(RAW_MYD.Time >= tStart & RAW_MYD.Time <= tEnd, :);

RAW_MOD = MOD_T(:, {'Mean_ScanTime','Mean_AOD'});
RAW_MOD.Properties.VariableNames(strcmp(RAW_MOD.Properties.VariableNames,'Mean_ScanTime')) = {'Time'};
RAW_MOD.Properties.VariableNames{'Mean_AOD'} = 'MOD_AOD';
RAW_MOD = RAW_MOD(RAW_MOD.Time >= tStart & RAW_MOD.Time <= tEnd, :);

RAW_SMPSAPS = SMPSAPS_Mode_T(:, {'Time','N_Accumulation'});
RAW_SMPSAPS = RAW_SMPSAPS(RAW_SMPSAPS.Time >= tStart & RAW_SMPSAPS.Time <= tEnd, :);

RAW_CCN = CCN_T(:, {'Time','CN01'});
RAW_CCN = RAW_CCN(RAW_CCN.Time >= tStart & RAW_CCN.Time <= tEnd, :);

RAW_VIIRS = VIIRS_1deg_T(:, {'Time','AOD_550'});
RAW_VIIRS = RAW_VIIRS(RAW_VIIRS.Time >= tStart & RAW_VIIRS.Time <= tEnd, :);
rawTables = {'RAW_CCN','RAW_CSPHOT','RAW_MODIS','RAW_NDROP','RAW_SMPSAPS','RAW_SatCorps','RAW_VIIRS'};


%% ========================================================================
%  28. CHECKS, VOLUME, AND WET (kappa-Kohler) MASS
%  ========================================================================
%  Quick checks, then wet volume, wet mass, and wet density for PM1, PM2.5,
%  and accumulation-mode mass using kappa-Kohler growth:
%    V_water = kappa * V_dry * RH / (1 - RH)
%  Values above the 99th percentile of each wet mass are then set to NaN,
%  and missing values are matched between paired dry and wet variables.

% Median cloud fraction when VIIRS AOD is available
valid = H2_All.AOD_550 > 0;
check = nanmedian(H2_All.Percent_Opaque(valid))

% Volume: zeros set to NaN
H2_All.V_total_Acc(H2_All.V_total_Acc == 0) = NaN;
H2_All.V1(H2_All.V1 == 0) = NaN;
H2_All.V25(H2_All.V25 == 0) = NaN;

% Diagnostic plot: dry volumes
figure()
plot(H2_All.Time,H2_All.V_total_Acc);
hold on
plot(H2_All.Time,H2_All.V1);
plot(H2_All.Time,H2_All.V25);
legend('Acc','V1','V25')

% Implied densities (mass / volume)
check = H2_All.PM1./H2_All.V1  .* 1e-12;
check2 = H2_All.PM25./H2_All.V25 .* 1e-12;
check3 = H2_All.M_Accumulation./H2_All.V_total_Acc .* 1e-12;

% ----- PM1 wet mass -----
rho_dry = 1.4;        % g/cm^3
rho_water = 1.0;      % g/cm^3
kappa = H2_All.kappa;
V_dry = H2_All.V1;        % m^3/m^3
RH = H2_All.RelativeHumidity;   % fraction (0-1), converted in Section 26

% Water volume via simplified kappa-Kohler
V_water = kappa .* V_dry .* (RH ./ (1 - RH));

% Wet volume (dry + water)
V_wet = V_dry + V_water;

% Wet mass (convert g/cm^3 * m^3/m^3 -> ug/m^3 using the 1e12 factor)
M_wet_PM1 = (rho_dry .* V_dry + rho_water .* V_water) * 1e12;

% Wet density = wet mass / wet volume
% M_wet_PM1 is in ug/m^3 (air); V_wet is in m^3(particle)/m^3(air)
% Convert back to g/cm^3: (ug/m^3) / (m^3/m^3) * 1e-12
rho_wet = (M_wet_PM1 ./ V_wet) * 1e-12;   % g/cm^3

% Dry mass for comparison
M_dry_PM1 = H2_All.PM1;

% Wet-to-dry mass growth factor
mass_growth_factor = M_wet_PM1 ./ M_dry_PM1;

% Wet-to-dry density ratio
rho_wet_over_dry = rho_wet ./ rho_dry;

% Add results to H2_All
H2_All.PM1V_water = V_water;
H2_All.PM1V_wet = V_wet;
H2_All.PM1_wet = M_wet_PM1;
H2_All.PM1mass_growth_factor = mass_growth_factor;
H2_All.PM1rho_wet = rho_wet;
H2_All.PM1rho_wet_over_dry = rho_wet_over_dry;

H2_All.PM1dryrhoPM1 = H2_All.PM1 ./ H2_All.V1 * 1e-12;   % g/cm^3, for the plot below

% ----- PM2.5 wet mass -----
V_dry = H2_All.V25;        % m^3/m^3
RH = H2_All.RelativeHumidity;   % fraction (0-1)
% Water volume via simplified kappa-Kohler
V_water = kappa .* V_dry .* (RH ./ (1 - RH));

% Wet volume (dry + water)
V_wet = V_dry + V_water;

% Wet mass (convert g/cm^3 * m^3/m^3 -> ug/m^3 using the 1e12 factor)
M_wet_PM25 = (rho_dry .* V_dry + rho_water .* V_water) * 1e12;

% Wet density = wet mass / wet volume
% M_wet_PM25 is in ug/m^3 (air); V_wet is in m^3(particle)/m^3(air)
% Convert back to g/cm^3: (ug/m^3) / (m^3/m^3) * 1e-12
rho_wet = (M_wet_PM25 ./ V_wet) * 1e-12;   % g/cm^3

% Dry mass for comparison
M_dry_PM25 = H2_All.PM25;

% Wet-to-dry mass growth factor
mass_growth_factor = M_wet_PM25 ./ M_dry_PM25;

% Wet-to-dry density ratio
rho_wet_over_dry = rho_wet ./ rho_dry;

% Add results to H2_All
H2_All.PM25V_water = V_water;
H2_All.PM25V_wet = V_wet;
H2_All.PM25_wet = M_wet_PM25;
H2_All.PM25mass_growth_factor = mass_growth_factor;
H2_All.PM25rho_wet = rho_wet;
H2_All.PM25rho_wet_over_dry = rho_wet_over_dry;

H2_All.PM25dryrhoPM25 = H2_All.PM25 ./ H2_All.V25 * 1e-12;   % g/cm^3, for the plot below

% ----- Accumulation-mode wet mass (dry volume from mass and dry density) -----
V_dry = H2_All.M_Accumulation * 1e-12 / rho_dry;
RH = H2_All.RelativeHumidity;   % fraction (0-1)
% Water volume via simplified kappa-Kohler
V_water = kappa .* V_dry .* (RH ./ (1 - RH));

% Wet volume (dry + water)
V_wet = V_dry + V_water;

% Wet mass (convert g/cm^3 * m^3/m^3 -> ug/m^3 using the 1e12 factor)
M_wet_Accum = (rho_dry .* V_dry + rho_water .* V_water) * 1e12;

% Wet density = wet mass / wet volume
% M_wet_Accum is in ug/m^3 (air); V_wet is in m^3(particle)/m^3(air)
% Convert back to g/cm^3: (ug/m^3) / (m^3/m^3) * 1e-12
rho_wet = (M_wet_Accum ./ V_wet) * 1e-12;   % g/cm^3

% Dry mass for comparison
M_dry_Accum = H2_All.M_Accumulation;

% Wet-to-dry mass growth factor
mass_growth_factor = M_wet_Accum ./ M_dry_Accum;

% Wet-to-dry density ratio
rho_wet_over_dry = rho_wet ./ rho_dry;

% Add results to H2_All
H2_All.AccumV_water = V_water;
H2_All.AccumV_wet = V_wet;
H2_All.M_Accumulation_wet = M_wet_Accum;
H2_All.Accummass_growth_factor = mass_growth_factor;
H2_All.Accumrho_wet = rho_wet;
H2_All.Accumrho_wet_over_dry = rho_wet_over_dry;

H2_All.Accumdryrho = H2_All.M_Accumulation ./ H2_All.V1 * 1e-12;   % g/cm^3

% Diagnostic plots: dry vs. wet mass, RH, and volume
figure()
plot(H2_All.Time,H2_All.PM1)
hold on
plot(H2_All.Time,H2_All.PM1_wet)
legend('PM1','Wet PM1')

figure()
plot(H2_All.Time,H2_All.PM25)
hold on
plot(H2_All.Time,H2_All.PM25_wet)
legend('PM2.5','Wet PM2.5')

figure()
plot(H2_All.Time,H2_All.M_Accumulation)
hold on
plot(H2_All.Time,H2_All.M_Accumulation_wet)
legend('M Accum','Wet M Accum')
figure()
plot(H2_All.Time,H2_All.RelativeHumidity)
xlim([datetime(2023,12,1) datetime(2023,12,14)])
ylabel('RH')

figure()
plot(H2_All.Time,H2_All.V1)
hold on
plot(H2_All.Time,H2_All.PM1V_wet)
xlim([datetime(2023,12,1) datetime(2023,12,14)])
% Wet mass: values above the 99th percentile set to NaN
p99_PM1 = prctile(H2_All.PM1_wet, 99);
H2_All.PM1_wet(H2_All.PM1_wet > p99_PM1) = NaN;

p99_PM25 = prctile(H2_All.PM25_wet, 99);
H2_All.PM25_wet(H2_All.PM25_wet > p99_PM25) = NaN;

p99_MAcc = prctile(H2_All.M_Accumulation_wet, 99);
H2_All.M_Accumulation_wet(H2_All.M_Accumulation_wet > p99_MAcc) = NaN;

% Match missing values between paired variables: volume is set to NaN where the matching mass is NaN

H2_All.V1(isnan(H2_All.PM1) & H2_All.V1 > 0) = NaN;
H2_All.V25(isnan(H2_All.PM25) & H2_All.V25 > 0) = NaN;
H2_All.V_total_Acc(isnan(H2_All.M_Accumulation) & H2_All.V_total_Acc > 0) = NaN;

H2_All.PM1V_wet(isnan(H2_All.PM1_wet) & H2_All.PM1V_wet > 0) = NaN;
H2_All.PM25V_wet(isnan(H2_All.PM25_wet) & H2_All.PM25V_wet > 0) = NaN;
H2_All.AccumV_wet(isnan(H2_All.M_Accumulation_wet) & H2_All.AccumV_wet > 0) = NaN;



