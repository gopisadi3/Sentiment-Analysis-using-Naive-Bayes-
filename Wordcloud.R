# Load required libraries
library(tm)
library(e1071)
library(caret) #Used for Classification And Regression Training
library(wordcloud)
library(dplyr)
# Library for parallel processing
library(doMC)
registerDoMC(cores=detectCores())  # Use all available cores


# Read file
mydata <- read.csv(file.choose(), header = T, stringsAsFactors = F)
glimpse(mydata)

#Randomize the dataset
set.seed(1)
mydata <- mydata[sample(nrow(mydata)), ]
mydata <- mydata[sample(nrow(mydata)), ]
glimpse(mydata)

# Convert the 'class' variable from character to factor.
mydata$Sentiment <- as.factor(mydata$Sentiment)

# Build corpus
corpus <- iconv(mydata$Medical.Condition, to = "utf-8")
corpus <- Corpus(VectorSource(mydata$Medical.Condition))
inspect(corpus[1:5])

# Clean text
corpus <- tm_map(corpus, tolower) 
inspect(corpus[1:5])

corpus <- tm_map(corpus, removeWords, stopwords('english'))
inspect(corpus[1:5])

corpus <- tm_map(corpus, removePunctuation)
inspect(corpus[1:5])

corpus <- tm_map(corpus, removeNumbers)
inspect(corpus[1:5])

cleanset <- tm_map(corpus, stripWhitespace)
inspect(cleanset[1:5])

# Term document matrix
tdm <- TermDocumentMatrix(cleanset)
tdm <- as.matrix(tdm)
tdm[1:10, 1:20]

# Bar plot
w <- rowSums(tdm)
w <- subset(w, w>=30)
barplot(w, main = 'Frequency of words',
        las = 2,
        col = rainbow(15))

# Word cloud
w <- sort(rowSums(tdm), decreasing= TRUE)
w
set.seed(222)
wordcloud(words = names(w),
          freq = w,
          max.words = 150,
          random.order = F,
          min.freq = 4,
          colors = brewer.pal(8, 'Dark2'),
          scale = c(3, 0.25),
          rot.per = 0.35)



#Partitioning the data 
mydata.train<- mydata[1:162,]
mydata.test<-mydata[163:180,]

#Create Matrix representation of Bag of Words : The Document Term Matrix
dtm <- DocumentTermMatrix(cleanset)

dtm.train <- dtm[1:162,]
dtm.test <- dtm[163:180,]


cleanset.train<- cleanset[1:162]
cleanset.test <- cleanset[163:180]

#Feature Selection
dim(dtm.train)

#Selection frequency above five
fivefrequency<- findFreqTerms(dtm.train,5)
length(fivefrequency)

# Use only 5 most frequent words (fivefreq) to build the DTM
dtm.train.nb <- DocumentTermMatrix(cleanset.train, control=list(dictionary = fivefrequency))
dim(dtm.train.nb)

dtm.test.nb <- DocumentTermMatrix(cleanset.test, control=list(dictionary = fivefrequency))
dim(dtm.test.nb)

# Function to convert the word frequencies to yes (presence) and no (absence) labels
convert_count <- function(x) {
  y <- ifelse(x > 0, 1,0)
  y <- factor(y, levels=c(0,1), labels=c("No", "Yes"))
  y
}

# Apply the convert_count function to get final training and testing DTMs
trainNB <- apply(dtm.train.nb, 2, convert_count)
testNB <- apply(dtm.test.nb, 2, convert_count)

# Train the classifier
system.time(classifier<- naiveBayes(trainNB, mydata.train$Sentiment, laplace = 1) )
# Use the NB classifier we built to make predictions on the test set.
system.time( pred <- predict(classifier, newdata=testNB) )
pred[6]
# Create a truth table by tabulating the predicted class labels with the actual class labels 
table("Predictions"= pred,  "Actual" = mydata.test$Sentiment)

# Prepare the confusion matrix
conf.mat <- confusionMatrix(pred, mydata.test$Sentiment)

conf.mat

conf.mat$byClass

conf.mat$overall

# Prediction Accuracy
conf.mat$overall['Accuracy']
accuracy<-c(conf.mat$overall['Accuracy'])
accuracy<-append(accuracy,values =conf.mat$overall['Accuracy'],after = length(accuracy))
yacc<-accuracy[1:5]*100

#plot accuracy graph with different ratio
ratio_train_test<-c(50,60,70,80,90)
par(pch=22, col="red")
plot(ratio_train_test,yacc,xlab = 'Training dataset ratio',ylab = 'Accuracy (in %) ',main = 'Accuracies of different dataset proportions for training and testing')
lines(ratio_train_test,yacc,xlab = 'Training ratio',type = 'o')