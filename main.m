% -------------------------------------------------------------------------
% Main for task-related component analysis
%
% Dataset (Sx.mat):
%   A 40-target SSVEP dataset recorded from a single subject. The stimuli
%   were generated by the j oint frequency-phase modulation (JFPM) [3]
%     - Stimulus frequencies    : 8.0 - 15.8 Hz with an interval of 0.2 Hz
%     - Stimulus phases         : 0pi, 0.5pi, 1.0pi, and 1.5pi
%     - # of channels           : 9 (1: Pz, 2: PO5,3:  PO3, 4: POz, 5: PO4,
%                                    6: PO6, 7: O1, 8: Oz, and 9: O2)
%     - # of recording blocks   : 6
%     - Data length of epochs   : 5 [seconds]
%     - Sampling rate           : 250 [Hz]
%     - Data format             : # channels, # points, # targets, # blocks
% 
% See also:
%   TRCA.m
% -------------------------------------------------------------------------

clear all
close all

load ('Freq_Phase.mat')
load('subject7.mat')
eeg = subject7;
[N_channel,~, N_target, N_block] = size(eeg);

%% ------------classification-------------
tic
% LOO cross-validation
for loocv_i = 1:N_block
     Testdata = squeeze(eeg(:, :, :, loocv_i));
     Traindata = eeg;
     Traindata(:, :, :, loocv_i) = [];
    for targ_i = 1:N_target
        aver_Traindata(:, :, targ_i) = squeeze(mean(squeeze(Traindata(:,:,targ_i,:)),3));
    end % end targ_i
    
    % labels assignment according to testdata
    truelabels=freqs;
    
    N_testTrial=size(Testdata, 3);
    for trial_i=1:N_testTrial
        coefficience = zeros(1,length(truelabels));
        for targ_j=1:length(freqs)             
            % compute spatial filter wn using training data
            wn = TRCA(squeeze(Traindata(:,:,targ_j,:)));
            % compute correlation between test and averaged training data
            weighted_train = wn'*aver_Traindata(:,:,targ_j);
            weighted_test = wn'*Testdata(:,:,trial_i);
            coefficienceMatrix = corrcoef(weighted_test,weighted_train);
            coefficience(targ_j) = coefficienceMatrix(1,2);
        end % end targ_i

            % target detection
            [~, index] = max(coefficience);
            outputlabels(trial_i) = freqs(index);
            
    end % end trial_i
    trueNum = sum((outputlabels-truelabels)==0);
    acc(loocv_i) = trueNum/length(truelabels);
    fprintf('The %d-th CV accuracy is: %.4f, samples: %d/%d\n',loocv_i,...
        acc(loocv_i),trueNum, N_testTrial)
end % end looCv_i
t=toc;
% data visualization
fprintf('\n-----------------------------------------\n')
disp(['total time: ',num2str(t),' s']);
fprintf('6-fold CV average accuracy is: %.4f\n',mean(acc))
