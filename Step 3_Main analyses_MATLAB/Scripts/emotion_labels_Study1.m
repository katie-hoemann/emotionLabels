clear all;
clc;

%% set parameters
print = 0; % set to 1 to write tables and generate figures
typeICC = 'C-k'; % set to A-k for agreement; C-k for consistency

%% import and clean experience sampling prompt data
promptData = importdata('Study1_PromptData_Cleaned_withInferredValence_withWordCounts_20230713.xlsx'); % import data
didNotComplete = promptData.data(:,2)==0;
promptData.data(didNotComplete,:) = []; % drop data for participants who did not complete the full protocol (PP60, PP65)
noEmotionWords = promptData.data(:,23)==0;
promptData.data(noEmotionWords,:) = []; % drop prompts where no emotion words were used

%% import daily diary data
diaryData = importdata('Study1_DiaryData_EmotionRatings.xlsx');
words = readtable('Study1_DiaryData_RatedWords.csv'); 
wordList = diaryData.colheaders(4:end)';  % grab sampled words from top row of data file
% set valence and arousal categories for sampled words
for i_word = 1:height(words) % define valence categories
if words.Valence(i_word) > 5 % derived based on the database mean for Warriner et al (2013)
    valCat(i_word) = {'Positive'};
    positive(i_word) = 1;
    valence(i_word) = 1;
else
    valCat(i_word) = {'Negative'};
    positive(i_word) = 0;
    valence(i_word) = 2;
end
end 
for i_word = 1:height(words) % define arousal categories
if words.Arousal(i_word) > 4.6 % derived based on the sample mean for 88 PANAS-X terms in Warriner et al (2013)
    aroCat(i_word) = {'High'};
    high(i_word) = 1;
else
    aroCat(i_word) = {'Low'};
    high(i_word) = 0;
end
end 
words = [words valCat' aroCat']; % append table with category assignments
words.Properties.VariableNames(5:end) = {'ValCat' 'AroCat'}; % label new variables
labels = [positive' high']; % create matrix for logical indexing in ICC commands

%% derive variables
participantIDlist = unique(promptData.data(:,1)); % get list of unique participant IDs
for i_participant = 1:length(participantIDlist)
    participantID = participantIDlist(i_participant); % get participant ID from list
    participantData_prompt = promptData.data(find(promptData.data(:,1)==participantID),:); % get all prompt data for that participant
    
    % prompt-level word variables
    numWords = participantData_prompt(:,23); % number of emotion words used at each prompt
    estValence = participantData_prompt(:,16); % valence estimated at each prompt
    propPos = participantData_prompt(:,12); % proportion of positive emotion words used at each prompt
    
    % participant-level word variables
    totalPrompts(i_participant,:) = size(participantData_prompt,1); % number included prompts
    totalWords(i_participant,:) = sum(participantData_prompt(:,23)); % total number of emotion words used across all prompts
    totalPos(i_participant,:) = sum(participantData_prompt(:,21)); % total number of positive words used across all prompts
    totalNeg(i_participant,:) = sum(participantData_prompt(:,19)); % total number of negative words used across all prompts
    numUniquePos(i_participant,:) = sum(sum(participantData_prompt(:,206:end),1)>=1); % number of unique positive words used across all prompts
    numUniqueNeg(i_participant,:) = sum(sum(participantData_prompt(:,25:205),1)>=1); % number of unique negative words used across all prompts
    numUnique(i_participant,:) = numUniquePos(i_participant,:)+numUniqueNeg(i_participant,:); % number of unique words used across all prompts
    
    wordsPerPrompt(i_participant,:) = totalWords(i_participant,:)/totalPrompts(i_participant,:); % mean emotion words per prompt
    wordsPerPromptPos(i_participant,:) = totalPos(i_participant,:)/totalPrompts(i_participant,:); % mean positive emotion words per prompt
    wordsPerPromptNeg(i_participant,:) = totalNeg(i_participant,:)/totalPrompts(i_participant,:); % mean negative emotion words per prompt
    meanEstValence(i_participant,:) = mean(estValence); % mean estimated valence from words
    meanPropPos(i_participant,:) = totalPos(i_participant,:)/totalWords(i_participant,:); % mean proportion positive words
    propUniquePos(i_participant,:) = numUniquePos(i_participant,:)/totalPos(i_participant,:); % ratio of all positive words that were unique
    propUniqueNeg(i_participant,:) = numUniqueNeg(i_participant,:)/totalNeg(i_participant,:); % ratio of all negative words that were unique
    propUnique(i_participant,:) = numUnique(i_participant,:)/totalWords(i_participant,:); % ratio of all words that were unique
    
    % reported valence variables
    repValence = participantData_prompt(:,5); % valence rated at each prompt
    meanRepValence(i_participant,:) = mean(repValence); % mean valence from ratings
    
    % emotion rating-based variables
    participantData_rating = diaryData.data(find(diaryData.data(:,1)==participantID),4:end); % get all rating data for that participant
    participantData_rating(participantData_rating > 6) = NaN; % remove invalid values
    missingData = any(isnan(participantData_rating),2); % identify missing data
    participantData_rating = participantData_rating(~missingData,:); % remove missing data
    participantData_rating_neg = participantData_rating(:,(labels(:,1)==0)); % negative emotions
    participantData_rating_pos = participantData_rating(:,(labels(:,1)==1)); % positive emotions

    % emodiversity
    numEmotions = length(wordList);
    for i_emotion = 1:numEmotions
        countEmotionRanked(i_emotion) = sum(participantData_rating(:,i_emotion)>0); % get number of times each emotion was rated > 0
    end
    countEmotionRanked = sort(countEmotionRanked); % sort to get ranking of emotions
    index = 1:1:numEmotions;
    for i_emotion = 1:numEmotions
        weightedCount(i_emotion) = countEmotionRanked(i_emotion)*index(i_emotion); % weight the count of each emotion by its ranking
    end
    emoDiv(i_participant,:) = 1-(((2*sum(weightedCount))/(numEmotions*sum(countEmotionRanked)))-((numEmotions+1)/numEmotions)); % calculate Gini coefficient following Benson et al (2018)
    
    % negative emodiversity
    numNegEmotions = sum(labels(:,1)==0);
    for i_emotion = 1:numNegEmotions
        countNegEmotionRanked(i_emotion) = sum(participantData_rating_neg(:,i_emotion)>0); 
    end
    countNegEmotionRanked = sort(countNegEmotionRanked); 
    indexNeg = 1:1:numNegEmotions;
    for i_emotion = 1:numNegEmotions
        weightedCountNeg(i_emotion) = countNegEmotionRanked(i_emotion)*indexNeg(i_emotion);
    end
    emoDivNeg(i_participant,:) = 1-(((2*sum(weightedCountNeg))/(numNegEmotions*sum(countNegEmotionRanked)))-((numNegEmotions+1)/numNegEmotions)); 
    
    % positive emodiversity
    numPosEmotions = sum(labels(:,1)==1);
    for i_emotion = 1:numPosEmotions
        countPosEmotionRanked(i_emotion) = sum(participantData_rating_pos(:,i_emotion)>0); 
    end
    countPosEmotionRanked = sort(countPosEmotionRanked); 
    indexPos = 1:1:numPosEmotions;
    for i_emotion = 1:numPosEmotions
        weightedCountPos(i_emotion) = countPosEmotionRanked(i_emotion)*indexPos(i_emotion); 
    end
    emoDivPos(i_participant,:) = 1-(((2*sum(weightedCountPos))/(numPosEmotions*sum(countPosEmotionRanked)))-((numPosEmotions+1)/numPosEmotions)); 
    
    % participant-level emotional granularity
    rawICC(i_participant,1) = ICC(participantData_rating_neg,typeICC); % negative valence ICC
    rawICC(i_participant,2) = ICC(participantData_rating_pos,typeICC); % positive valence ICC
    rawICC(i_participant,3) = (rawICC(i_participant,1)+rawICC(i_participant,2))/2; % mean ICC
    rawICC(rawICC<0) = 0; % recode negative values as 0
    rtoZ(i_participant,1) = 0.5*log((1+rawICC(i_participant,1))/(1-rawICC(i_participant,1))); % Fisher-transform ICCs
    rtoZ(i_participant,2) = 0.5*log((1+rawICC(i_participant,2))/(1-rawICC(i_participant,2))); 
    rtoZ(i_participant,3) = 0.5*log((1+rawICC(i_participant,3))/(1-rawICC(i_participant,3)));
    granNeg(i_participant,:) = rtoZ(i_participant,1)*-1; % invert zICC values to get intuitively scaled measure
    granPos(i_participant,:) = rtoZ(i_participant,2)*-1; 
    emoGran(i_participant,:) = rtoZ(i_participant,3)*-1;
      
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
    withinPersonsData_valence(find(promptData.data(:,3)==participantID),:) = [participantData_prompt(:,[3 4]) repValence estValence propPos];
    
    clear participantData_prompt participantData_rating repValence estValence propPos numWords
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
    columns = {'PPID','Day','Reported','Estimated','PropPos'};
    withinPersonsData_valence = array2table(withinPersonsData_valence,'VariableNames',columns);
    writetable(withinPersonsData_valence,'valence_data_Study1.csv');
    
    % within-participants correlations
    columns = {'PPID','numPrompts','r_eV','p_eV','NS_eV','out_eV','r_pP','p_pP','NS_pP','out_pP'};
    withinCorrelations = array2table(withinCorrelations,'VariableNames',columns);
    writetable(withinCorrelations,'within_correlations_Study1.csv');
end   

%% import questionnaire data
questData = importdata('Study1_QuestionnaireData.xlsx');
GAD7 = questData.data(:,34);
PHQ8 = questData.data(:,48);
TAS20 = questData.data(:,39);
RDEES = questData.data(:,45);
mentalHealth = (zscore(GAD7) + zscore(PHQ8))/2;

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
toCorrelate_mHealth = [meanPropPos propUniquePos propUniqueNeg meanEstValence meanRepValence mentalHealth];
[r_mHealth,p_mHealth] = corr(toCorrelate_mHealth,'rows','complete');  
names = {'pP','pUp','pUn','eV','rV','anxDep'};
r_table = array2table(r_mHealth,'RowNames',names,'VariableNames',names);
p_table = array2table(p_mHealth,'RowNames',names,'VariableNames',names);
if print == 1
    writetable(r_table,'r_table_Study1_mHealth.xlsx');
    writetable(p_table,'p_table_Study1_mHealth.xlsx');
end

%% run between-persons correlations with emotional function (derived and self-reported)
toCorrelate_emo = [wordsPerPrompt propUnique TAS20 RDEES emoDiv emoGran]; 
[r_emo,p_emo] = corr(toCorrelate_emo,'rows','complete');
names_emo = {'wPP','pU','TAS20','RDEES','emoDiv','emoGran'};
r_table_emo = array2table(r_emo,'RowNames',names_emo,'VariableNames',names_emo);
p_table_emo = array2table(p_emo,'RowNames',names_emo,'VariableNames',names_emo);
if print == 1
    writetable(r_table_emo,'r_table_Study1_emoFxn.xlsx');
    writetable(p_table_emo,'p_table_Study1_emoFxn.xlsx');
end

toCorrelate_emo_neg = [wordsPerPromptNeg propUniqueNeg emoDivNeg granNeg]; 
[r_emo_neg,p_emo_neg] = corr(toCorrelate_emo_neg,'rows','complete');
names_emo_neg = {'wPPn','pUn','divNeg','granNeg'};
r_table_emo_neg = array2table(r_emo_neg,'RowNames',names_emo_neg,'VariableNames',names_emo_neg);
p_table_emo_neg = array2table(p_emo_neg,'RowNames',names_emo_neg,'VariableNames',names_emo_neg);
if print == 1
    writetable(r_table_emo,'r_table_Study1_emoFxn_neg.xlsx');
    writetable(p_table_emo,'p_table_Study1_emoFxn_neg.xlsx');
end

toCorrelate_emo_pos = [wordsPerPromptPos propUniquePos emoDivPos granPos]; 
[r_emo_pos,p_emo_pos] = corr(toCorrelate_emo_pos,'rows','complete');
names_emo_pos = {'wPPp','pUp','divPos','granPos'};
r_table_emo_pos = array2table(r_emo_pos,'RowNames',names_emo_pos,'VariableNames',names_emo_pos);
p_table_emo_pos = array2table(p_emo_pos,'RowNames',names_emo_pos,'VariableNames',names_emo_pos);
if print == 1
    writetable(r_table_emo,'r_table_Study1_emoFxn_pos.xlsx');
    writetable(p_table_emo,'p_table_Study1_emoFxn_pos.xlsx');
end

%% generate figures
if print == 1
    figure;
    colormap(brewermap([],'PuBu')) 
    heatmap1 = imagesc(r_pers);
    axis square;
    labels = names_pers;
    set(gca,'XTick',1:1:length(labels),'XTickLabel',labels);
    xtickangle(45)
    set(gca,'YTick',1:1:length(labels),'YTickLabel',labels);
end