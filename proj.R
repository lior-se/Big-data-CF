library(DBI)
library(odbc)
library(dplyr)
library(ggplot2)
library(recommenderlab)

con <- dbConnect(odbc::odbc(),
                 .connection_string = "Driver={Oracle dans OraDB21Home1};Dbq=localhost:1521/XEPDB1;Uid=proj;Pwd=code;")

bxBooks <- dbReadTable(con, "BX-Books")
bxRating <- dbReadTable(con, "BX-Book-Ratings")
bxUser <- dbReadTable(con, "BX-User")

dbDisconnect(con)

#3.a
nb_unique_users <- n_distinct(bxUser[[1]])
print(nb_unique_users) # 278858

#3.b
nb_unique_books <- n_distinct(bxBooks[[1]])
print(nb_unique_books)# 270545

#3.c
nb_unique_ratings <- nrow(bxRating)
print(nb_unique_ratings)# 1144612

#3.d
freq_user_rating <- bxRating %>%
  group_by(User.ID) %>%              
  summarise(n = n()) %>%              
  group_by(n) %>%                    
  summarise(num_users = n())          
print(freq_user_rating)

#3.e

freq_book_rating <- bxRating %>%
  group_by(ISBN) %>%               
  summarise(n = n()) %>%             
  group_by(n) %>%                     
  summarise(num_books = n())          

print(freq_book_rating)
#3.f

book_ratings <- bxRating %>%
  group_by(ISBN) %>%
  summarise(num_ratings = n())


book_ratings_with_titles <- book_ratings %>%
  inner_join(bxBooks, by = "ISBN")


top_10_books <- book_ratings_with_titles %>%
  arrange(desc(num_ratings)) %>%
  slice(1:10) %>%
  mutate(rank = row_number()) %>%
  select( Book.Title, rank) 
  
print(top_10_books)

#3.g

top_10_users <- bxRating %>%
  group_by(User.ID) %>%
  summarise(num_ratings = n())%>%
  arrange(desc(num_ratings)) %>%
  slice(1:10) %>%
  mutate(rank = row_number()) %>%
  select(User.ID,rank)

print(top_10_users)


books <- bxBooks[!is.na(bxBooks[,2]),]

ratings <- bxRating[bxRating$ISBN %in% books$ISBN & bxRating$User.ID %in% bxUser$User.ID, ]
ratings <- ratings[ratings$Book.Rating != 0, ]




books_rating_counts <- table(ratings$ISBN)
removed_books <- names(books_rating_counts)[books_rating_counts <= 6]
ratings <- ratings[!ratings$ISBN %in% removed_books, ]

user_rating_counts <- table(ratings$User.ID)
removed_users <- names(user_rating_counts)[user_rating_counts <= 11]
ratings <- ratings[!ratings$User.ID %in% removed_users,]


ratings.matrix <- as(ratings, "realRatingMatrix")
percent_train <- 0.8
rating_threshold <- 3      # good rating implies >=3
giv<-8
eval_sets <- evaluationScheme(data = ratings.matrix, method = "split",k=5,
                              train = percent_train,given=giv,
                              goodRating = rating_threshold)

set.seed(26)

params <- list(method="cosine")
UBCF_rec <- Recommender(data = getData(eval_sets, "train"), method = "ubcf", parameter = params) 

R.UB <- predict(object = UBCF_rec, newdata = getData(eval_sets, "known"),n=3, type = "ratings")

UBCF_accuracy <- calcPredictionAccuracy(x = R.UB,given=giv, data = getData(eval_sets, "unknown"), byUser=TRUE)
UBCF_accuracy_general <- calcPredictionAccuracy(x = R.UB,given=giv, data = getData(eval_sets, "unknown"), byUser=FALSE)


max(UBCF_accuracy[, "RMSE"], na.rm = TRUE)
min(UBCF_accuracy[, "RMSE"], na.rm = TRUE)

max(IBCF_accuracy[, "RMSE"], na.rm = TRUE)
min(IBCF_accuracy[, "RMSE"], na.rm = TRUE)

params <- list(method="cosine")
IBCF_rec <- Recommender(data = getData(eval_sets, "train"), method = "ibcf", parameter = params) 

R.IB <- predict(object = IBCF_rec, newdata = getData(eval_sets, "known"),n=3, type = "ratings")

IBCF_accuracy <- calcPredictionAccuracy(x = R.IB,given=giv, data = getData(eval_sets, "unknown"), byUser=TRUE)
IBCF_accuracy_general <- calcPredictionAccuracy(x = R.IB,given=giv, data = getData(eval_sets, "unknown"), byUser=FALSE)

V.RMSE <- list()

V.RMSE[['UBCF']] <- UBCF_accuracy[, "RMSE"]

V.RMSE[['IBCF']] <- IBCF_accuracy[, "RMSE"]

save(ratings.matrix, eval_sets, R.UB,R.IB,V.RMSE, file = "model.rdata")

hist_UBCF <- hist(V.RMSE[["UBCF"]], breaks = seq(0,ceiling(max(UBCF_accuracy[, "RMSE"], na.rm = TRUE)),0.25))

hist_UBCF_table <- data.frame(
  RMSE = hist_UBCF$breaks[-length(hist_UBCF$breaks)],
  Frequency = hist_UBCF$counts
)

hist_IBCF <- hist(V.RMSE[["IBCF"]], breaks = seq(0,ceiling(max(IBCF_accuracy[, "RMSE"], na.rm = TRUE)),0.25))

hist_IBCF_table <- data.frame(
  RMSE = hist_IBCF$breaks[-length(hist_IBCF$breaks)],
  Frequency = hist_IBCF$counts
)


random_indices <- sample(1:nrow(R.UB), 500)

R.UB_500 <- as(R.UB, "matrix")[random_indices, 1:10]
R.UB_500 <- round(R.UB_500, digits = 0.1)

colnames(R.UB_500) <- sapply(colnames(R.UB_500), function(c) {
  book_title <- books[books$ISBN == c, ]$Book.Title
  substr(book_title, start = 1, stop = 12)
})

R.IB_500 <- as(R.IB, "matrix")[random_indices, 1:10]
R.IB_500<-round(R.IB_500, digits = 0.1 )
colnames(R.IB_500) <- sapply(colnames(R.IB_500), function(c) {
  book_title <- books[books$ISBN == c, ]$Book.Title
  substr(book_title, start = 1, stop = 12)
})

tar("Hackaton.tar", c("proj.r", "proj.out", "model.rdata", "basics.txt", "model.txt"))
