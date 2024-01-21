library(wordcloud)
library(ggplot2)

#LOAD DATA
DF <- read.csv("emotion words_Study2.csv", fileEncoding = 'UTF-8-BOM')

#WORD CLOUDS (https://towardsdatascience.com/create-a-word-cloud-with-r-bde3e7422e8a; https://r-graph-gallery.com/38-rcolorbrewers-palettes.html)
#tiff("word_cloud.tiff", res=360, compression="lzw", pointsize=2)
#png("word_cloud_Jolie.png")
cloud <- wordcloud(words=DF$Word, freq=DF$Freq, max.words = 100, random.order=FALSE, rot.per=.30, colors=brewer.pal(8, "Dark2"))
#print(cloud)
#dev.off()
ggsave("cloud.png", width = 8, height = 8, units = "in")