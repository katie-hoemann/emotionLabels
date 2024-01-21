clear all;
clc;

%% set parameters
print = 0; % set to 1 to write tables and generate figures

%% import experience sampling prompt data
promptData = importdata('Study2_PromptData_Cleaned_withInferredValence_withWordCounts_20230718.xlsx'); % import data

%% import questionnaire data
questData = importdata('Study2_QuestionnaireData_CheckIn2_Aligned_Cleaned.xlsx'); % mid-point 2
Anx = questData.data(:,32); 
Dep = questData.data(:,41); 
mentalHealth = (zscore(Anx) + zscore(Dep))/2;

%% reconcile participants between prompt and questionnaire data
participantIDlist = unique(promptData.data(:,1)); % get list of unique participant IDs
participantIDlist1 = array2table(participantIDlist,'VariableNames',{'PPID1'});
participantIDlist2 = array2table(questData.data(:,2),'VariableNames',{'PPID2'});
participantIDlist_join = outerjoin(participantIDlist1,participantIDlist2,'LeftKeys','PPID1','RightKeys','PPID2');
notInQuest = find(isnan(participantIDlist_join.PPID2));
notInQuestIDs = participantIDlist(notInQuest);
promptData.data(ismember(promptData.data(:,1),notInQuestIDs),:) = [];
participantIDlist(notInQuest) = [];

%% clean experience sampling prompt data
noEmotionWords = promptData.data(:,20)==0;
promptData.data(noEmotionWords,:) = []; % drop prompts where no emotion words were used
participantIDlist = intersect(unique(promptData.data(:,1)),participantIDlist); % only in case some participants no have no data

%% derive variables
for i_participant = 1:length(participantIDlist)
    participantID = participantIDlist(i_participant); % get participant ID from list
    participantData = promptData.data(find(promptData.data(:,1)==participantID),:); % get all prompt data for that participant
    
    % prompt-level word variables
    numWords = participantData(:,20); % number of emotion words used at each prompt
    estValence = participantData(:,13); % valence estimated at each prompt
    propPos = participantData(:,19); % proportion of positive emotion words used at each prompt
    
    % participant-level word variables
    totalPrompts(i_participant,:) = size(participantData,1); % number included prompts
    totalWords(i_participant,:) = sum(participantData(:,20)); % total number of emotion words used across all prompts
    totalPos(i_participant,:) = sum(participantData(:,18)); % total number of positive words used across all prompts
    totalNeg(i_participant,:) = sum(participantData(:,16)); % total number of negative words used across all prompts
    numUniquePos(i_participant,:) = sum(sum(participantData(:,388:689),1)>=1); % number of unique positive words used across all prompts
    numUniqueNeg(i_participant,:) = sum(sum(participantData(:,22:387),1)>=1); % number of unique negative words used across all prompts
    numUnique(i_participant,:) = numUniquePos(i_participant,:)+numUniqueNeg(i_participant,:); % number of unique words used across all prompts
    
    wordsPerPrompt(i_participant,:) = totalWords(i_participant,:)/totalPrompts(i_participant,:); % mean emotion words per prompt
    meanEstValence(i_participant,:) = mean(estValence); % mean estimated valence from words
    meanPropPos(i_participant,:) = totalPos(i_participant,:)/totalWords(i_participant,:); % mean proportion positive words
    propUniquePos(i_participant,:) = numUniquePos(i_participant,:)/totalPos(i_participant,:); % ratio of all positive words that were unique
    propUniqueNeg(i_participant,:) = numUniqueNeg(i_participant,:)/totalNeg(i_participant,:); % ratio of all negative words that were unique
    propUnique(i_participant,:) = numUnique(i_participant,:)/totalWords(i_participant,:); % ratio of all words that were unique
    
    % reported valence variables
    repValence = participantData(:,9); % valence rated at each prompt
    meanRepValence(i_participant,:) = mean(repValence); % mean valence from ratings
    
    % within-person descriptive statistics
    numWords_min(i_participant,:) = min(numWords);
    numWords_max(i_participant,:) = max(numWords);
    numWords_mean(i_participant,:) = mean(numWords);
    numWords_std(i_participant,:) = std(numWords);    
    
    estValence_min(i_participant,:) = min(estValence);
    estValence_max(i_participant,:) = max(estValence);
    estValence_mean(i_participant,:) = mean(estValence);
    estValence_std(i_participant,:) = std(estValence);
    
    propPos_min(i_participant,:) = min(propPos);
    propPos_max(i_participant,:) = max(propPos);
    propPos_mean(i_participant,:) = mean(propPos);
    propPos_std(i_participant,:) = std(propPos);
       
    % within-person correlations    
    [r_eV(i_participant,:),p_eV(i_participant,:)] = corr(repValence,estValence,'rows','complete');
    [r_pP(i_participant,:),p_pP(i_participant,:)] = corr(repValence,propPos,'rows','complete');
    
    [r_eVpP(i_participant,:),p_eVpP(i_participant,:)] = corr(estValence,propPos,'rows','complete');
    [r_nWeV(i_participant,:),p_nWeV(i_participant,:)] = corr(numWords,estValence,'rows','complete');
    [r_nWpP(i_participant,:),p_nWpP(i_participant,:)] = corr(numWords,propPos,'rows','complete');
        
    % compile prompt-level variables for export
    withinPersonsData_valence(find(promptData.data(:,1)==participantID),:) = [participantData(:,[1 5]) repValence estValence propPos];
    
    clear participantData repValence estValence propPos numWords
end

%% get descriptive statistics for within-person valence correlations
outliers_eV = r_eV<(nanmean(r_eV)-2*nanstd(r_eV));
numOutliers_eV = sum(outliers_eV);
NS_eV = p_eV>.05;
numNS_eV = sum(NS_eV);
min_eV = min(r_eV);
max_eV = max(r_eV);
mean_eV = nanmean(r_eV);

outliers_pP = r_pP<(nanmean(r_pP)-2*nanstd(r_pP));
numOutliers_pP = sum(outliers_pP);
NS_pP = p_pP>.05;
numNS_pP = sum(NS_pP);
min_pP = min(r_pP);
max_pP = max(r_pP);
mean_pP = nanmean(r_pP);

withinCorrelations = [participantIDlist totalPrompts r_eV p_eV NS_eV outliers_eV r_pP p_pP NS_pP outliers_pP];

%% export data for analysis in other scripts
if print == 1
    % valence data
    columns = {'PPID','Beep','Reported','Estimated','PropPos'};
    withinPersonsData_valence = array2table(withinPersonsData_valence,'VariableNames',columns);
    writetable(withinPersonsData_valence,'valence_data_Study2.csv');
    
    % within-participants correlations
    columns = {'PPID','numPrompts','r_eV','p_eV','NS_eV','out_eV','r_pP','p_pP','NS_pP','out_pP'};
    withinCorrelations = array2table(withinCorrelations,'VariableNames',columns);
    writetable(withinCorrelations,'within_correlations_Study2.csv');
end   

%% create table of descriptive statistics
descStats_prompts = [mean(numWords_mean) std(numWords_mean) min(numWords_mean) max(numWords_mean) min(numWords_min) max(numWords_max);...
    mean(estValence_mean) std(estValence_mean) min(estValence_mean) max(estValence_mean) NaN NaN;...
    mean(propPos_mean) std(propPos_mean) min(propPos_mean) max(propPos_mean) NaN NaN];
descStats_participants = [mean(wordsPerPrompt) std(wordsPerPrompt) min(wordsPerPrompt) max(wordsPerPrompt);...
    mean(totalWords) std(totalWords) min(totalWords) max(totalWords);...
    mean(meanEstValence) std(meanEstValence) min(meanEstValence) max(meanEstValence);...
    mean(meanPropPos) std(meanPropPos) min(meanPropPos) max(meanPropPos);...
    mean(numUnique) std(numUnique) min(numUnique) max(numUnique);...
    mean(propUnique) std(propUnique) min(propUnique) max(propUnique);...
    nanmean(propUniquePos) nanstd(propUniquePos) nanmin(propUniquePos) nanmax(propUniquePos);...
    nanmean(propUniqueNeg) nanstd(propUniqueNeg) nanmin(propUniqueNeg) nanmax(propUniqueNeg)];

%% run between-persons correlations with self-reported mental health
participantIDlist1 = array2table(participantIDlist,'VariableNames',{'PPID1'});
participantIDlist2 = array2table(questData.data(:,2),'VariableNames',{'PPID2'});
participantIDlist_join = outerjoin(participantIDlist1,participantIDlist2,'LeftKeys','PPID1','RightKeys','PPID2');
notInESM = find(isnan(participantIDlist_join.PPID1));
mentalHealth(notInESM) = []; % need to reconcile the lists again if someone has been dropped due to lack of data

toCorrelate_mHealth = [meanPropPos propUniquePos propUniqueNeg meanEstValence meanRepValence mentalHealth];
[r_mHealth,p_mHealth] = corr(toCorrelate_mHealth,'rows','complete');  
names = {'pP','pUp','pUn','eV','rV','anxDep'};
r_table = array2table(r_mHealth,'RowNames',names,'VariableNames',names);
p_table = array2table(p_mHealth,'RowNames',names,'VariableNames',names);
if print == 1
    writetable(r_table,'r_table_Study2.xlsx');
    writetable(p_table,'p_table_Study2.xlsx');
end