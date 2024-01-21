# set directories
setwd("C:/Users/Katie/Documents/R/Emotion_Labels")
base_dir <- 'C:/Users/Katie/Documents/R/Emotion_Labels'

# load required libraries (install if necessary)
library(readr)
library(lme4) 
library(lmerTest)
library(CorrMixed)

# read in data
d <- read.csv("valence_data_Study2.csv", fileEncoding='UTF-8-BOM')

# run regression models
m1 <- lmer(scale(Reported) ~ scale(Estimated) + (scale(Estimated)|PPID), data=d) # standardized coefficients
summary(m1)

m2 <- lmer(scale(Reported) ~ scale(PropPos) + (scale(PropPos)|PPID), data=d) # standardized coefficients
summary(m2)

# # create spaghetti plots
# Spaghetti.Plot(Dataset = d, Outcome = Reported, Id = PPID, Time = Estimated)