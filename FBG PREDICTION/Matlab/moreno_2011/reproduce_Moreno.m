% Reproducing Moreno et al on collected PPG data. 
% Chirath Hettiarachchi 2020 March
% Data collected at 60Hz, 3600 samples / min

% Note: Weight & BMI cannot be replicated. Limitation of data collection.

% Implemented features
% BGL
% AGE - 1
% Spo2 - 1
% AR Coeff - 5
% KTE AR Coeff - 5
% KTE Frame - 4
% Entropy - 4
% log energy - 5 + 2
% HR - 4
% full features implemented 31


clear all;
close all;

addpath(genpath('lib/'));

% select dataset
DATASET = 2;
if DATASET == 1
    subject = csvread('data_handler/data1.csv',1,0);
    file_prefix = 'data1/AAA';
else
    subject = csvread('data_handler/data2.csv',1,0);
    file_prefix = 'data2/X_';
end
[m,n] = size(subject);

% Calculate the target features. 
feature_vector = [];
for patient = 1:1:m
    id = int2str(subject(patient,1));
    disp(id);
    f_BGL = subject(patient,3);
    f_AGE = subject(patient,2);
    
    % f_SPO2
    name = strcat('input/spo2/',file_prefix, id, '.csv');
    T = readtable(name);
    spo2 = table2array(T(:,3));
    [start_spo2, end_spo2] = get_bestSignal(spo2,2);
    spo2 = spo2(start_spo2:end_spo2,:);
    f_SPO2 = mean(spo2);
    
    name = strcat('input/ppg/',file_prefix, id, '.csv');
    wave = csvread(name,1,0);
    PPGsignal = wave; % the raw ppg is being used. 
    [ppg_start, ppg_end] = get_bestSignal(PPGsignal,1);
    PPGsignal = PPGsignal(ppg_start:ppg_end,:);
    
    % AR Coefficients.(5 features)
    sys = ar(PPGsignal,5,'yw');
    f_ARppg = sys.A;
    f_ARppg = f_ARppg(1,2:end);
    
    % KTE
    %kte(2:end-1) = PPGsignal(2:end-1).^2 - PPGsignal(1:end-2).*PPGsignal(3:end);
    for i = 2:length(PPGsignal)-1
        kte(i) =  PPGsignal(i)^2 - PPGsignal(i-1)*PPGsignal(i+1);
    end
    sys = ar(kte,5,'yw');
    f_AR_KTEppg = sys.A;
    f_AR_KTEppg = f_AR_KTEppg(1,2:end);
    
    %calculate the frame_array from the window. 
    frame_array = {};
    count = 0;
    for i = 1:155:length(PPGsignal) - 310
        count = count + 1;
        temp_frame = PPGsignal(i:i+309,1);
        frame_array{count} = temp_frame;   
    end
    
    f_FRAME_KTE = get_frameKTE_features(frame_array); % get frame kte features.
    f_FRAME_SE = get_frameSE_features(frame_array);   % get frame spec entr fea.
    f_LE = get_logEnergy_features(frame_array); % get log energy based features.
    
    % Heart Rate features. 
    %filtered_PPG = hr_preprocessSignal(PPGsignal); %the filter in the
    %paper is errorneous
    filtered_PPG = preprocessSignal(PPGsignal);
    
    F_HR = get_HR_features(filtered_PPG');
    
    %figure
    %plot(filtered_PPG');
     
    temp = [f_BGL f_AGE f_SPO2 f_ARppg f_AR_KTEppg f_FRAME_KTE f_FRAME_SE f_LE F_HR];
    feature_vector = [feature_vector ; temp];
end


% print to file. 
csvwrite('data2_Moreno_features.csv',feature_vector);

