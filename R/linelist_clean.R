library(dplyr)
library(data.table)

big_data<-rio::import(here::here("inst", "Merged_linelist_2021-01-05.xlsx"), readxl = FALSE)
#import has for some reason lost the values in some columns (ageonsetdays), due to the read_excel that is used.
#as the output from the merge file is a .xlsx we can specify readxl =FALSE so the read.xlsx function will be used on the import instead
#the read.xlsx functions requires the dependancy openxlsx


big_data_clean<-big_data
#read in all dates
big_data_clean<-dplyr::mutate(big_data_clean, across(contains("date"), as.Date, origin= "1899-12-30"))
#remove all instances that should be coded as missing done this in the merge
# big_data_clean<-data.frame(lapply(big_data, function(x) {gsub("(?i)^NA$|(?i)^N/A$|(?i)^N/A,|(?i)^N\\A$|(?i)^Unknown$|(?i)know|(?i)
# #                                                               ^Unkown$|(?i)^N.A$|(?i)^NE SAIT PAS$|(?i)^Inconnu$|^ $|(?i)^Nao aplicavel$|(?i)^Sem informacao$",NA, x, ignore.case= T, perl = T) }), stringsAsFactors=F)


##report date ## use dplyr::if_else for date handeling
big_data_clean$report_date<-dplyr::if_else(is.na(big_data_clean$report_date),big_data_clean$lab_resdate,big_data_clean$report_date)
big_data_clean$report_date<- dplyr::if_else(big_data_clean$report_date< as.Date("2020-01-01") | big_data_clean$report_date > as.Date(Sys.Date()),as.Date(NA),big_data_clean$report_date)
#big_data_clean$report_date<-as.Date(big_data_clean$report_date, origin= "1899-12-30")

#test for problem dates handle all dates that are same way
#problem_dates<-subset(big_data_clean, report_date < as.Date("2020-01-01") | report_date > as.Date(Sys.Date()))

##patinfo_ageonset##
big_data_clean$patinfo_ageonset<- ifelse(grepl("month|M",big_data_clean$patinfo_ageonsetunit, ignore.case = T), as.numeric(big_data_clean$patinfo_ageonset)/12, big_data_clean$patinfo_ageonset)
big_data_clean$patinfo_ageonset<- ifelse(grepl("day",big_data_clean$patinfo_ageonsetunit, ignore.case = T), as.numeric(big_data_clean$patinfo_ageonset)/365, big_data_clean$patinfo_ageonset)

# remove writen units
big_data_clean$patinfo_ageonsetunit<- ifelse(grepl("month|M|year|day|^0$",big_data_clean$patinfo_ageonsetunit, ignore.case = T),NA,big_data_clean$patinfo_ageonsetunit)
# column was suppose to be for ages under 12 months so convert these to years and leave the rest
big_data_clean$patinfo_ageonsetunit<- as.numeric(big_data_clean$patinfo_ageonsetunit)/12

big_data_clean$patinfo_ageonsetunitdays<- ifelse(grepl("month|M|year|day|^0$",big_data_clean$patinfo_ageonsetunitdays, ignore.case = T),NA,big_data_clean$patinfo_ageonsetunitdays)
# column was suppose to be for ages under 12 months so convert these to years and leave the rest
big_data_clean$patinfo_ageonsetunitdays<- as.numeric(big_data_clean$patinfo_ageonsetunitdays)/365


# replace ages that are in the unit column if missing in the normal age column or 0 in the normal age column but has a valueinputed in the unit column
big_data_clean$patinfo_ageonset<-ifelse(is.na(big_data_clean$patinfo_ageonset)|big_data_clean$patinfo_ageonset==0 & !is.na(big_data_clean$patinfo_ageonsetunit), big_data_clean$patinfo_ageonsetunit, big_data_clean$patinfo_ageonset)
big_data_clean$patinfo_ageonset<-ifelse(is.na(big_data_clean$patinfo_ageonset)|big_data_clean$patinfo_ageonset==0 & !is.na(big_data_clean$patinfo_ageonsetunitdays), big_data_clean$patinfo_ageonsetunitdays, big_data_clean$patinfo_ageonset)

#drop ages that are clearly incorrect
big_data_clean$patinfo_ageonset<- ifelse(big_data_clean$patinfo_ageonset>120 | big_data_clean$patinfo_ageonset<0 & !is.na(big_data_clean$patinfo_ageonset),NA,big_data_clean$patinfo_ageonset)

#drop unit columns now irrelavent
big_data_clean$patinfo_ageonsetunit<-NULL
big_data_clean$patinfo_ageonsetunitdays<-NULL


##patinfo_sex##
#keep first letter of sex (always M or F)
big_data_clean<-big_data_clean %>% mutate_at("patinfo_sex",.funs=gsub,pattern="[0-9?]",replacement = NA, ignore.case = T, perl = T)
big_data_clean$patinfo_sex<- substr(big_data_clean$patinfo_sex,1,1)
#capitalise
big_data_clean$patinfo_sex<- toupper(big_data_clean$patinfo_sex)
#if entered incorrect make equal to NA
big_data_clean$patinfo_sex<-ifelse(!grepl("M|F", big_data_clean$patinfo_sex, ignore.case = T),NA,big_data_clean$patinfo_sex)


##pat_symptomatic##
#ensure id variable is present as splitting up dataframe
big_data_clean$id<-rownames(big_data_clean)
#nex steps requrie dataframe format (not data table)

big_data_clean<-data.frame(big_data_clean)
#ensure orihinal pat_symptomatic contains no numbers of special characters and only yes or no
big_data_clean<-big_data_clean %>% mutate_at("pat_symptomatic",.funs=gsub,pattern="[0-9?]",replacement = NA, ignore.case = T, perl = T) %>%
  mutate_at("pat_symptomatic",.funs=gsub,pattern="(?i)^no$|(?i)^non$|(?i)^n$",replacement = "no", ignore.case = T, perl = T) %>%
  mutate_at("pat_symptomatic",.funs=gsub,pattern="(?i)^yes$|(?i)^oui$|(?i)^sim$|(?i)^y$",replacement = "yes", ignore.case = T, perl = T)
big_data_clean$pat_symptomatic<-ifelse(!grepl("^no$|^yes$",big_data_clean$pat_symptomatic, ignore.case = T),NA,big_data_clean$pat_symptomatic)

#Creat a symptomatic column those missing variable using other symptoms variables
symptoms<- big_data_clean %>% select(id,contains("sympt")) %>% select(-contains(c("pat_symptomatic", "pat_asymptomatic")))
symptvars<-names(symptoms)
#symptoms[,-1] means apply to everything except column 1 which is the id variable
#remove any ? or numerics
symptoms[,-1]<- data.frame(lapply(symptoms[,-1], function(x) {gsub("[0-9?]",NA, x, ignore.case = T, perl = T) }), stringsAsFactors=F)
#change all variations of no to standardised
symptoms[,-1]<- data.frame(lapply(symptoms[,-1], function(x) {gsub("^NAO$|^NON$|^NO$|^none$|^nil$|^null$|.*Know.*|^N/A$|^NA$|0|^not$|^n$|nn","no", x, ignore.case = T, perl = T) }), stringsAsFactors=F)
#replace 1 or more spaces with one space
symptoms[,-1]<- data.frame(lapply(symptoms[,-1], function(x) {gsub("\\s+", " ",x, ignore.case = T, perl = T) }), stringsAsFactors=F)
#blank cells to NA
symptoms[symptoms==" "]<-NA
symptoms[symptoms==""]<-NA

#determine if patient had symptoms
#sum row if contains no or is missing (if all rows are no of missing =7)
symptoms$symptoms_none<-rowSums(symptoms[,-1]=="no" | is.na(symptoms[,-1]))
#sum rwo if it is missing (if all ros missing =7)
symptoms$symptoms_na<-rowSums(is.na(symptoms[,-1]))
#initialised symptomatic variable
symptoms$pat_symptomatic<-NA

#if row sums in symptoms_none=7 then all rows had no or missing in symptoms
symptoms$pat_symptomatic<-ifelse(symptoms$symptoms_none==7,"no",symptoms$pat_symptomatic)
#if row sums in symptoms_none<7 then at least one row had yes or other symptoms
symptoms$pat_symptomatic<-ifelse(symptoms$symptoms_none<7,"yes",symptoms$pat_symptomatic)
#replace rows that had all missing in all symptoms
symptoms$pat_symptomatic<-ifelse(symptoms$symptoms_na==7,NA,symptoms$pat_symptomatic)

#add id back to columns for merging
symptoms_clean<- symptoms %>% select(id,pat_symptomatic)

#merge with big data to infill symptomatic yes or no, only if missing this variable
big_data_clean<-merge(big_data_clean,symptoms_clean, by="id")
big_data_clean$pat_symptomatic.x<-ifelse(is.na(big_data_clean$pat_symptomatic.x), big_data_clean$pat_symptomatic.y,big_data_clean$pat_symptomatic.x)


#final clean up of pat_symptomatic
big_data_clean$pat_symptomatic<-big_data_clean$pat_symptomatic.x
big_data_clean$pat_asymptomatic<-ifelse(big_data_clean$pat_asymptomatic==1,0,big_data_clean$pat_asymptomatic)
big_data_clean$pat_symptomatic<-ifelse(is.na(big_data_clean$pat_symptomatic) & !is.na(big_data_clean$pat_asymptomatic) & big_data_clean$pat_asymptomatic==0,"no",big_data_clean$pat_symptomatic)

big_data_clean$pat_symptomatic.x<-NULL
big_data_clean$pat_symptomatic.y<-NULL
big_data_clean$pat_asymptomatic<-NULL

#debug to check
#sympt_test<- big_data_clean %>% select(id,contains("sympt"))

#remove now unneccessary symptoms variables but leave symptomatic variable
big_data_clean<-big_data_clean[ , -which(names(big_data_clean) %in% symptvars)]


#patinfo_occus
#list of words/ strings associated with healthcare
occupation<-rio::import(here::here("inst/","Cleaning_dict_alice.xlsx"), which=1) %>% select(patinfo_occus)
#remove accents from occupation column
big_data_clean<-data.table(big_data_clean)
#Create a column that creates TRUE for health care worker after a match or partial match with list above
big_data_clean$hcw <- grepl(paste(occupation$patinfo_occus, collapse="|"),big_data_clean$patinfo_occus, ignore.case = T)
#replce if occupation was missing
big_data_clean$hcw<- ifelse(is.na(big_data_clean$patinfo_occus),NA,big_data_clean$hcw) #this column is if healthcare workerso use in analysis as this

#patcourse_status
#list of words/ strings associated with dead or alive
dead<-rio::import(here::here("inst/","Cleaning_dict_alice.xlsx"), which=2) %>% select(dead) %>% na.omit()
alive<-rio::import(here::here("inst/","Cleaning_dict_alice.xlsx"), which=2) %>% select(alive) %>% na.omit()
recovered<-rio::import(here::here("inst/","Cleaning_dict_alice.xlsx"), which=2) %>% select(recovered) %>% na.omit()
#if missing patcourse_status make equal to patcurrent status
big_data_clean$patcourse_status<-ifelse(is.na(big_data_clean$patcourse_status),big_data_clean$patcurrent_status,big_data_clean$patcourse_status)

#remove any numbers in there or special characters

big_data_clean<-big_data_clean %>% mutate_at("patcourse_status",.funs=gsub,pattern="[0-9?]",replacement = NA, ignore.case = T, perl = T)  %>%
  mutate_at("patcurrent_status",.funs=gsub,pattern="[0-9?]",replacement = NA, ignore.case = T, perl = T)
big_data_clean$patcourse_status_dead<- grepl(paste(dead$dead, collapse="|"),big_data_clean$patcourse_status, ignore.case = T)
big_data_clean$patcourse_status_dead<-ifelse(big_data_clean$patcourse_status_dead==FALSE,NA,big_data_clean$patcourse_status_dead)
big_data_clean$patcourse_status_dead<-ifelse(big_data_clean$patcourse_status_dead==TRUE,"dead",big_data_clean$patcourse_status_dead)
big_data_clean$patcourse_status_alive<- grepl(paste(alive$alive, collapse="|"),big_data_clean$patcourse_status, ignore.case = T)
big_data_clean$patcourse_status_alive<-ifelse(big_data_clean$patcourse_status_alive==FALSE,NA,big_data_clean$patcourse_status_alive)
big_data_clean$patcourse_status_alive<-ifelse(big_data_clean$patcourse_status_alive==TRUE,"alive",big_data_clean$patcourse_status_alive)


#identifying those alive and recovered
big_data_clean$patcourse_status_recovered<-grepl(paste(recovered$recovered, collapse="|"),big_data_clean$patcourse_status, ignore.case = T)
big_data_clean$patcourse_status_recovered<-ifelse(big_data_clean$patcourse_status_recovered==FALSE,NA,big_data_clean$patcourse_status_recovered)
big_data_clean$patcourse_status_recovered<-ifelse(big_data_clean$patcourse_status_recovered==TRUE,"recovered",big_data_clean$patcourse_status_recovered)
big_data_clean$patcourse_status_recovered<-ifelse(is.na(big_data_clean$patcourse_status_recovered) & !is.na(big_data_clean$patcourse_datedischarge),"recovered",big_data_clean$patcourse_status_recovered)

big_data_clean$patcourse_status<- ifelse(!is.na(big_data_clean$patcourse_status) & !is.na(big_data_clean$patcourse_status_dead), big_data_clean$patcourse_status_dead,big_data_clean$patcourse_status)
big_data_clean$patcourse_status<-ifelse(!is.na(big_data_clean$patcourse_status) & !is.na(big_data_clean$patcourse_status_alive), big_data_clean$patcourse_status_alive, big_data_clean$patcourse_status)
big_data_clean$patcourse_status<-ifelse(big_data_clean$patcourse_status=="LTFU" | grepl("lost",big_data_clean$patcourse_status, ignore.case = T),"Lost to follow up",big_data_clean$patcourse_status)


#drop columns created, uncommment if needed for debugging
big_data_clean$patcourse_status_dead<-NULL
big_data_clean$patcourse_status_alive<-NULL
big_data_clean$patcourse_status<-ifelse(!grepl("alive|dead|lost|pending",big_data_clean$patcourse_status, ignore.case = T),NA,big_data_clean$patcourse_status)
big_data_clean$patcourse_status_recovered<-ifelse(is.na(big_data_clean$patcourse_status_recovered),big_data_clean$patcourse_status, big_data_clean$patcourse_status_recovered)

#some cases with a date of death but not "dead" in their status column?

#Date of death handling.
#some countries used a date of outcome column, this needs cleaning if patient is not dead then empy the date of death column and put dtae in the discharge column
big_data_clean$patcourse_datedischarge<-ifelse(big_data_clean$patcourse_status!="dead",big_data_clean$patcourse_datedeath,big_data_clean$patcourse_datedischarge)
big_data_clean$patcourse_datedeath<-ifelse(big_data_clean$patcourse_status!="dead",NA,big_data_clean$patcourse_datedeath)
big_data_clean$patcourse_datedischarge<-ifelse(big_data_clean$patcourse_status=="dead",NA,big_data_clean$patcourse_datedischarge)


#report classif
probabale<-rio::import(here::here("inst/","Cleaning_dict_alice.xlsx"), which=2) %>% select(probable) %>% na.omit()
suspected<-rio::import(here::here("inst/","Cleaning_dict_alice.xlsx"), which=2) %>% select(suspected) %>% na.omit()
confirmed<-rio::import(here::here("inst/","Cleaning_dict_alice.xlsx"), which=2) %>% select(confirmed) %>% na.omit()
notacase<-rio::import(here::here("inst/","Cleaning_dict_alice.xlsx"), which=2) %>% select(notacase) %>% na.omit()

#remove any numbers in there or special characters
big_data_clean<-big_data_clean %>% mutate_at("report_classif",.funs=gsub,pattern="[0-9?]",replacement = NA, ignore.case = T, perl = T)

#probable
big_data_clean$report_classif_probable<- grepl(paste(probabale$probable, collapse="|"),big_data_clean$report_classif, ignore.case = T)
big_data_clean$report_classif_probable<-ifelse(big_data_clean$report_classif_probable==FALSE,NA,big_data_clean$report_classif_probable)
big_data_clean$report_classif_probable<-ifelse(big_data_clean$report_classif_probable==TRUE,"probabale",big_data_clean$report_classif_probable)
#suspected
big_data_clean$report_classif_suspected<- grepl(paste(suspected$suspected, collapse="|"),big_data_clean$report_classif, ignore.case = T)
big_data_clean$report_classif_suspected<-ifelse(big_data_clean$report_classif_suspected==FALSE,NA,big_data_clean$report_classif_suspected)
big_data_clean$report_classif_suspected<-ifelse(big_data_clean$report_classif_suspected==TRUE,"suspected",big_data_clean$report_classif_suspected)
#confirmed
big_data_clean$report_classif_confirmed<- grepl(paste(confirmed$confirmed, collapse="|"),big_data_clean$report_classif, ignore.case = T)
big_data_clean$report_classif_confirmed<-ifelse(big_data_clean$report_classif_confirmed==FALSE,NA,big_data_clean$report_classif_confirmed)
big_data_clean$report_classif_confirmed<-ifelse(big_data_clean$report_classif_confirmed==TRUE,"confirmed",big_data_clean$report_classif_confirmed)
#not a case
big_data_clean$report_classif_nac<- grepl(paste(notacase$notacase, collapse="|"),big_data_clean$report_classif, ignore.case = T)
big_data_clean$report_classif_nac<-ifelse(big_data_clean$report_classif_nac==FALSE,NA,big_data_clean$report_classif_nac)
big_data_clean$report_classif_nac<-ifelse(big_data_clean$report_classif_nac==TRUE,"not a case",big_data_clean$report_classif_nac)

big_data_clean$report_classif<- ifelse(!is.na(big_data_clean$report_classif) & !is.na(big_data_clean$report_classif_probable), big_data_clean$report_classif_probable,big_data_clean$report_classif)
big_data_clean$report_classif<-ifelse(!is.na(big_data_clean$report_classif) & !is.na(big_data_clean$report_classif_suspected), big_data_clean$report_classif_suspected, big_data_clean$report_classif)
big_data_clean$report_classif<-ifelse(!is.na(big_data_clean$report_classif) & !is.na(big_data_clean$report_classif_confirmed), big_data_clean$report_classif_confirmed, big_data_clean$report_classif)
big_data_clean$report_classif<-ifelse(!is.na(big_data_clean$report_classif) & !is.na(big_data_clean$report_classif_nac), big_data_clean$report_classif_nac, big_data_clean$report_classif)

#report_test<- big_data_clean %>% select(patinfo_id,contains("report"))

#drop columns created, uncommment if needed for debugging
big_data_clean$report_classif_probable<- NULL
big_data_clean$report_classif_suspected<- NULL
big_data_clean$report_classif_confirmed<- NULL
big_data_clean$report_classif_nac<- NULL

big_data_clean$report_classif<-ifelse(!grepl("suspected|probabale|confirmed|not a case",big_data_clean$report_classif, ignore.case = T),NA,big_data_clean$report_classif)

#use patcurrent status in the report classif if missing classification ??


#labresult
positive<-rio::import(here::here("inst/","Cleaning_dict_alice.xlsx"), which=2) %>% select(positive) %>% na.omit()
negative<-rio::import(here::here("inst/","Cleaning_dict_alice.xlsx"), which=2) %>% select(negative) %>% na.omit()
inconclusive<-rio::import(here::here("inst/","Cleaning_dict_alice.xlsx"), which=2) %>% select(inconclusive) %>% na.omit()
#remove accents from status columns
big_data_clean<-data.table(big_data_clean)
big_data_clean<-big_data_clean[, lab_result := stringi::stri_trans_general(str = lab_result, id = "Latin-ASCII")]
#remove any numbers in there or special characters
big_data_clean<-big_data_clean %>% mutate_at("lab_result",.funs=gsub,pattern="[0-9?]",replacement = NA, ignore.case = T, perl = T)
#positive
big_data_clean$lab_result_pos<- grepl(paste(positive$positive, collapse="|"),big_data_clean$lab_result, ignore.case = T)
big_data_clean$lab_result_pos<-ifelse(big_data_clean$lab_result_pos==FALSE,NA,big_data_clean$lab_result_pos)
big_data_clean$lab_result_pos<-ifelse(big_data_clean$lab_result_pos==TRUE,"positive",big_data_clean$lab_result_pos)
#negative
big_data_clean$lab_result_neg<- grepl(paste(negative$negative, collapse="|"),big_data_clean$lab_result, ignore.case = T)
big_data_clean$lab_result_neg<-ifelse(big_data_clean$lab_result_neg==FALSE,NA,big_data_clean$lab_result_neg)
big_data_clean$lab_result_neg<-ifelse(big_data_clean$lab_result_neg==TRUE,"negative",big_data_clean$lab_result_neg)
#inconclusive
big_data_clean$lab_result_incon<- grepl(paste(inconclusive$inconclusive, collapse="|"),big_data_clean$lab_result, ignore.case = T)
big_data_clean$lab_result_incon<-ifelse(big_data_clean$lab_result_incon==FALSE,NA,big_data_clean$lab_result_incon)
big_data_clean$lab_result_incon<-ifelse(big_data_clean$lab_result_incon==TRUE,"inconclusive",big_data_clean$lab_result_incon)

big_data_clean$lab_result<- ifelse(!is.na(big_data_clean$lab_result) & !is.na(big_data_clean$lab_result_pos), big_data_clean$lab_result_pos,big_data_clean$lab_result)
big_data_clean$lab_result<-ifelse(!is.na(big_data_clean$lab_result) & !is.na(big_data_clean$lab_result_neg), big_data_clean$lab_result_neg, big_data_clean$lab_result)
big_data_clean$lab_result<-ifelse(!is.na(big_data_clean$lab_result) & !is.na(big_data_clean$lab_result_incon), big_data_clean$lab_result_incon, big_data_clean$lab_result)

#drop columns created, uncommment if needed for debugging
big_data_clean$lab_result_pos<- NULL
big_data_clean$lab_result_neg<- NULL
big_data_clean$lab_result_incon<- NULL


#using lab result to confirm case
#create report_classif_alice variable to work off until we decide how this is to be cleaned

big_data_clean$report_classif_alice<-big_data_clean$report_classif
big_data_clean$report_classif_alice<-ifelse(big_data_clean$lab_result=="positive" & !is.na(big_data_clean$lab_result),"confirmed",big_data_clean$report_classif)

#load in dictionary for linelists that are only the positves / confirmed cases
linelist_pos<-rio::import(here::here("inst/","Cleaning_dict_alice.xlsx"), which=5)
linelist_pos<-filter(linelist_pos,!is.na(linelist_pos$labresult))

big_data_clean$report_classif_alice<-ifelse(is.na(big_data_clean$report_classif_alice),linelist_pos$classification[match(big_data_clean$country_iso, linelist_pos$country_iso)],big_data_clean$report_classif_alice)
big_data_clean$lab_result<-ifelse(is.na(big_data_clean$lab_result),linelist_pos$labresult[match(big_data_clean$country_iso, linelist_pos$country_iso)],big_data_clean$lab_result)


###comorbidies
comorbs<-rio::import(here::here("inst/","Cleaning_dict_alice.xlsx"), which=3)
clean_noyes<-rio::import(here::here("inst/","Cleaning_dict_alice.xlsx"), which=2)
big_data_comorbs<-select(big_data_clean,contains("comcond"))
big_data_comorbs$id<-rownames(big_data_comorbs)
#partial string matches using above spreadsheet disctionary for each ncd, checking in both comcond columns
big_data_comorbs$diabetes<-apply(big_data_comorbs, 1, function(x) any(grepl(paste(na.omit(comorbs$diabetes), collapse="|"),x,ignore.case = T)))
big_data_comorbs$asthma<-apply(big_data_comorbs, 1, function(x) any(grepl(paste(na.omit(comorbs$asthma), collapse="|"),x,ignore.case = T)))
big_data_comorbs$hypertension<-apply(big_data_comorbs, 1, function(x) any(grepl(paste(na.omit(comorbs$hypertension), collapse="|"),x,ignore.case = T)))
big_data_comorbs$obesity<-apply(big_data_comorbs, 1, function(x) any(grepl(paste(na.omit(comorbs$obesity), collapse="|"),x,ignore.case = T)))
big_data_comorbs$cardiovascular_disease<-apply(big_data_comorbs, 1, function(x) any(grepl(paste(na.omit(comorbs$`cardiovascular disease`), collapse="|"),x,ignore.case = T)))
big_data_comorbs$pregnancy<-apply(big_data_comorbs, 1, function(x) any(grepl(paste(na.omit(comorbs$Pregnancy), collapse="|"),x,ignore.case = T)))
big_data_comorbs$renal_disease<-apply(big_data_comorbs, 1, function(x) any(grepl(paste(na.omit(comorbs$`Renal disease`), collapse="|"),x,ignore.case = T)))
big_data_comorbs$drepanocytosis<-apply(big_data_comorbs, 1, function(x) any(grepl(paste(na.omit(comorbs$Drepanocytosis), collapse="|"),x,ignore.case = T)))
big_data_comorbs$chronic_pulmonary<-apply(big_data_comorbs, 1, function(x) any(grepl(paste0(na.omit(comorbs$`Chronic pulmonary disease`), collapse="|"),x,ignore.case = T)))
big_data_comorbs$cancer<-apply(big_data_comorbs, 1, function(x) any(grepl(paste(na.omit(comorbs$Cancer), collapse="|"),x,ignore.case = T)))
big_data_comorbs$other_comorb<-apply(big_data_comorbs, 1, function(x) any(grepl(paste(na.omit(comorbs$Other), collapse="|"),x,ignore.case = T)))

#changes all TRUE to 1 and FALSE to NA ftom grepl
big_data_comorbs <- data.frame(lapply(big_data_comorbs, function(x) {gsub("TRUE", 1, x, ignore.case = T, perl = T)}), stringsAsFactors = F)
big_data_comorbs <- data.frame(lapply(big_data_comorbs, function(x) {gsub("FALSE", NA, x, ignore.case = T, perl = T)}), stringsAsFactors = F)
# changes variations of yes and no to standard
big_data_comorbs<- data.frame(lapply(big_data_comorbs, function(x) {gsub(paste0("(?i)^",na.omit(clean_noyes$no),"$",collapse="|"), "no", x, ignore.case = T, perl = T)}), stringsAsFactors = F)
big_data_comorbs<- data.frame(lapply(big_data_comorbs, function(x) {gsub(paste0("(?i)^",na.omit(clean_noyes$yes),"$",collapse="|"), "yes", x, ignore.case = T, perl = T)}), stringsAsFactors = F)

# removed anything entered in here that is not yes or no or not given
big_data_comorbs$comcond_preexist1<-ifelse(grepl("yes|no",big_data_comorbs$comcond_preexist1, ignore.case = T),big_data_comorbs$comcond_preexist1,NA)
big_data_comorbs$comcond_preexist1<-ifelse(grepl("yes",big_data_comorbs$comcond_preexist1, ignore.case = T),"yes",big_data_comorbs$comcond_preexist1)
big_data_comorbs$comcond_preexist1<-ifelse(grepl("(?i)^no$",big_data_comorbs$comcond_preexist1, perl = T),"no",big_data_comorbs$comcond_preexist1)
big_data_comorbs$comcond_preexist1<-ifelse(is.na(big_data_comorbs$comcond_preexist1) & grepl("yes|(?i)^no$",big_data_comorbs$comcond_preexist, ignore.case = T, perl=T), big_data_comorbs$comcond_preexist, big_data_comorbs$comcond_preexist1)


#If RowSums=0 then there are no ncd specified
big_data_comorbs<-dplyr::mutate(big_data_comorbs, across(c(-comcond_preexist1,-comcond_preexist), as.numeric))
big_data_comorbs$comcond_preexsist_yesno<-rowSums(select(big_data_comorbs, -c("comcond_preexist1","comcond_preexist", "id")), na.rm = T)
big_data_comorbs$not_specified_comorb<-ifelse(big_data_comorbs$comcond_preexist1=="yes" & is.na(big_data_comorbs$comcond_preexist) & big_data_comorbs$comcond_preexsist_yesno==0 | grepl(paste(na.omit(comorbs$`Not Specified`), collapse="|"),big_data_comorbs$comcond_preexist,ignore.case = T),1,NA)


#variable correction for yes/no ncd based on previous dictionary
#if no ncd were picked up then the yes/no variable is changed to no
#if ncd was picked up then yes/no variable is changed to yes
#i have added these as a separate variable _alice for comparison

big_data_comorbs$comcond_preexist1_alice<-big_data_comorbs$comcond_preexist1
big_data_comorbs$comcond_preexist1_alice<-ifelse(is.na(big_data_comorbs$comcond_preexist1_alice) & big_data_comorbs$not_specified_comorb==1,"yes",big_data_comorbs$comcond_preexist1_alice)
big_data_comorbs$comcond_preexist1_alice<-ifelse(big_data_comorbs$comcond_preexsist_yesno>0 & is.na(big_data_comorbs$comcond_preexist1_alice), "yes", big_data_comorbs$comcond_preexist1_alice)
big_data_comorbs$comcond_preexist1_alice<-ifelse(!grepl("(?i)^yes$|(?i)^no$",big_data_comorbs$comcond_preexist1_alice, perl=T), NA, big_data_comorbs$comcond_preexist1_alice)


###
#generate row id to ensure correct back merge
big_data_clean$id<-rownames(big_data_clean)
#removed old comcond variables
big_data_clean<-dplyr::select(big_data_clean,-c(contains("comcond")))
#change comborbs if to character for merge
big_data_comorbs$id<-as.character(big_data_comorbs$id)
big_data_clean<-merge(big_data_clean,big_data_comorbs, by="id")



###capital city
country<-rio::import(here::here("inst/","Cleaning_dict_alice.xlsx"), which=4)
#varible of country full name from aboove dictionary
big_data_clean$country_full <- country$country_full[match(big_data_clean$country_iso, country$country_iso)]
#add column that is the capital city
big_data_clean$capital <- country$capital[match(big_data_clean$country_iso, country$country_iso)]
#partial match readmin1 variable to identify if patient is in capital city
big_data_clean$capital_final <-mapply(function(x, y) grepl(x, y, ignore.case = T), big_data_clean$capital, big_data_clean$patinfo_resadmin1)
big_data_clean$capital <-NULL #drop variable that was used for matching



#re-run this line to replace any report dates that were dropped because entered incorrectly we can use the labdate as a surrogate at the end of this clean, again doing a final drop of incorrect dates
big_data_clean$report_date<-dplyr::if_else(is.na(big_data_clean$report_date),big_data_clean$lab_resdate,big_data_clean$report_date)
big_data_clean$report_date<- dplyr::if_else(big_data_clean$report_date< as.Date("2020-01-01") | big_data_clean$report_date > as.Date(Sys.Date()),as.Date(NA),big_data_clean$report_date)



openxlsx::write.xlsx(big_data_clean,paste0("inst/Cleaned_linelist_", Sys.Date(),".xlsx"))





########################################################################################################################

