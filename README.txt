STEP 1_ESTIMATE VALENCE_PYTHON
> INPUT subfolder: files with cleaned experience sampling prompt data from Studies 1 and 2
> OUTPUT subfolder: prompt data for Studies 1 and 2 with estimated (inferred) valence
> SCRIPTS subfolder:

STEP 2_COUNT EMOTION WORDS_PYTHON
> INPUT subfolder: <see Step 1 output>
> OUTPUT subfolder: prompt data for Studies 1 and 2 with estimated valence and word counts
> SCRIPTS subfolder:
- stem.py = stems a list of input words, so these stems can be matched against freely generated labels (stems)
- count_emotion_words.py = takes input texts, tokenizes and stems, and then compares stems to input list to count which and how many are used

STEP 3_MAIN ANALYSES_MATLAB
> INPUT subfolder: <see Step 2 output>; also includes questionnaire data from Studies 1 and 2, and emotion rating data from Study 1
> OUTPUT subfolder: valence data (self-reported, estimated, proportion positive words) for all participants in Studies 1 and 2
> SCRIPTS subfolder:
>> FUNCTIONS that are necessary for running scripts
- emotion_labels_Study1.m = calculates person- and prompt-level measures for participants in Study 1, generates descriptive statistics, runs correlational analyses
- emotion_labels_Study2.m = calculates person- and prompt-level measures for participants in Study 2, generates descriptive statistics, runs correlational analyses

STEP 4_SUPPLEMENTARY ANALYSES_R
> INPUT subfolder: <see Step 3 output>; emotion words from Studies 1 and 2 (for word clouds)
> SCRIPTS:
- valence_LMER.R = runs linear mixed-effects model comparing valence variables across participants
- word_clouds.R = creates word clouds from list of unique emotion words and corresponding frequency counts