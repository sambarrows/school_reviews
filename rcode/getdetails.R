


nicedate=function(uglydate,today,yesterday){

	if(length(grep("day",uglydate))>0){

		# check for today, yesterday, or remove day and continue
		if(uglydate=="today"){
			uglydate=today
		} else {
			if(uglydate=="yesterday"){
				uglydate=yesterday
			} else {
				uglydate=substring(uglydate,(str_locate(uglydate,"day,")[2]+2))
			}
		}
	}	
	m=tolower(substring(uglydate,1,3))
	d=gsub(",","",unlist(strsplit(uglydate," "))[2])
	y=substr(uglydate,nchar(uglydate)-3,nchar(uglydate))

	datenice=paste(d,m,y,sep="")
	return(as.character(as.Date(datenice,"%d%B%Y")))
}




getschoolnameandlink=function(schoolline){
	sep1=unlist(strsplit(schoolline,"\""))
	sep1=sep1[which(sep1=="js-school-search-result-name"):length(sep1)]
	schoollink=gsub("\"","",sep1[5])
	schoolname=toString(unlist(strsplit(sep1[6],"[<>]"))[2])
	schoolname=gsub("/","-",schoolname)
	type=unlist(strsplit(sep1[8],"[<>]"))[4]
	return(c(schoolname,schoollink,type))
}




getdetails=function(state,city,today,yesterday){

	school.outdata=list()
	end="st=public&st=charter&st=private"

	# parse weblink
	(citylink=paste("http://www.greatschools.org/",state,"/",city,"/schools/?",end,sep=""))

	# grab webpage and number of schools in this category
	resultsfirstpage=readLines(citylink)
	num_schools_line=resultsfirstpage[grep("<span id=\"total-results-count\">",resultsfirstpage)][1]
	(n_schools=as.numeric(gsub(",","",unlist(strsplit(unlist(strsplit(num_schools_line,">"))[3],"<"))[1])))


	# grab all results pages
	sleep_time=1 # seconds to pause just in case they track screen scraping
	num_results_pages = floor(n_schools / 25)
	results_index = seq(0,num_results_pages*25,25)
	n_resultpages=length(results_index)

	results_pages = list()
	results_pages[[1]]=resultsfirstpage
	for(i in 2:n_resultpages){
		resultslink = paste(citylink,"&start=",results_index[i],sep="")
		results_pages[[i]]=readLines(resultslink)
	#	Sys.sleep(sleep_time+runif(1)) # in case too many requests
	}


	# list of schools
	# [name, link, type(pub vs priv vs chart), level (k-5, etc)

	all_results = unlist(results_pages)
	school_list=all_results[grep("js-school-search-result-name",all_results)]
	level=all_results[grep("js-school-search-result-street small bottom",all_results)]

	school_data=matrix("",nrow=n_schools,ncol=4)
	for(i in 1:n_schools){
		# name, link, type
		schoolline=school_list[i]
		school_data[i,1:3]=getschoolnameandlink(schoolline)
		# level
		school_data[i,4]=unlist(strsplit(level[i],"[<>]"))[3]		
	}



	n_reviews_keep=rep(0,n_schools)
	details_keep=matrix(0,ncol=17,nrow=n_schools)
	allreviews=c()

	# grab detailed data for each school
	
	for(school in 1:n_schools){

		school_name = school_data[school,1]
		school_link = school_data[school,2]
		name = "school"
		type = school_data[school,3]
		graderange = school_data[school,4]


		# school homepage
		schoolpage=readLines(paste(school_link,"?tab=reviews",sep=""))

		# GSID
		detailslines=schoolpage[grep("GS.ad.targeting.pageLevel",schoolpage)]
		if(is.na(grep("school_id",detailslines)[1])){
			gsid = ""
		} else {
			almostid=unlist(strsplit(detailslines[grep("school_id",detailslines)][1]," = "))[2]
			gsid=substr(almostid,3,nchar(almostid)-3)
		}

		# district
		if(is.na(grep("district_id",detailslines)[1])){
			districtid = ""
		} else {
			almostdistrict=unlist(strsplit(detailslines[grep("district_id",detailslines)][1]," = "))[2]
			districtid=substr(almostdistrict,3,nchar(almostdistrict)-3)
		}
	
		# enrollment
		if(length(schoolpage[grep("make-dddddd phs",schoolpage)])==0){
			enrollment = ""
		} else {
			if(length(grep("students",schoolpage[grep("make-dddddd phs",schoolpage)]))==0){
			} else {
				gradeenroll=schoolpage[grep("make-dddddd phs",schoolpage)]
				almostenrollment=unlist(strsplit(gradeenroll[grep("students",gradeenroll)],"> "))[2]
				enrollment=substr(almostenrollment,1,nchar(almostenrollment)-9)
			}
		}		

		# Address
		if(is.na(grep("http://maps.google.com",schoolpage)[1])){
			address = ""
		} else {
			almostaddress=unlist(strsplit(schoolpage[grep("http://maps.google.com",schoolpage)],"daddr="))[2]
			address=unlist(strsplit(almostaddress,"\\+\\("))[1]
			if(length(grep("\">Get",address))>0){
				address=unlist(strsplit(address,"\">Get"))[1]
				address=gsub("%20"," ",address)
			}
		}
	
		# Phone 
		if(is.na(grep("Phone",schoolpage)[1])){
			phone = ""
		} else {
			if(length(schoolpage[grep("Phone",schoolpage)])==1){
				phone=unlist(strsplit(schoolpage[grep("Phone",schoolpage)],"Phone: </strong>"))[2]
			} else {
				almostphone=strsplit(unlist(schoolpage[grep("schoolPhone",schoolpage)])[1],"schoolPhone")
				phone=substring(unlist(strsplit(unlist(strsplit(unlist(schoolpage[grep("schoolPhone",schoolpage)])[1],"schoolPhone"))[2],"</p>"))[1],3)
			}
		}

		# Website
		if(is.na(grep("Website",schoolpage)[1])){
			website = ""
		} else {
			almostwebsite=unlist(strsplit(unlist(strsplit(schoolpage[grep("Website",schoolpage)]," href="))[2],">"))[1]
			website=substr(almostwebsite,2,nchar(almostwebsite)-1)
		}
		
		# NCES id - can't find ncesdistrict; don't know how to extract it from full ncescode
		if(is.na(grep("data-gs-school-nces-code",schoolpage)[1])){
			ncesid= ""
		} else {
			almostnces=schoolpage[grep("data-gs-school-nces-code",schoolpage)]
			ncesid=unlist(strsplit(unlist(strsplit(almostnces,"data-gs-school-nces-code=\\\"")),"\\\" data-gs-school-name="))[2]
		}
	
		# lat, lon TBC - need a stable way to look up address for lat/lon
			lat = ""
			lon = ""

		# gs_rating
		if(is.na(grep("gs_rating",detailslines)[1])){
			gsrating = ""
		} else {
			almostid=unlist(strsplit(detailslines[grep("gs_rating",detailslines)][1]," = "))[2]
			gsrating=substr(almostid,3,nchar(almostid)-3)
		}

		# parentrating - assume this is community rating
		if(is.na(schoolpage[grep("Community Rating",schoolpage)][1])){
			parentrating = ""
		} else {
			parentratingline=schoolpage[grep("Community Rating",schoolpage)][1]	
			almostparentrating=unlist(strsplit(parentratingline,"h3"))
			if(length(grep("Rate this school",almostparentrating[2]))>0){
				parentrating = ""
			} else{
				parentrating=substr(unlist(strsplit(parentratingline,"h3"))[2],17,17)
			}
		}


		# put into matrix
		details_keep[school,]=c(school_name,school_link,gsid,name,type,graderange,enrollment,city,districtid,address,phone,website,ncesid,lat,lon,gsrating,parentrating)
	

		# num of reviews line
		numreviewsline=schoolpage[grep("</span> reviews of this school",schoolpage)][1]


		# if no reviews, put zero and go to next
		if(is.na(numreviewsline)){
			n_reviews_keep[school]=0
		} else {
		# else, grab reviews
			n_reviews_all=max(as.numeric(unlist(strsplit(numreviewsline,"[<>]")),na.rm=T),na.rm=T)
			n_reviews_keep[school]=n_reviews_all # number of total reviews
			n_review_pages=ceiling(as.numeric(n_reviews_all)/20)
		
			reviewer=rep("",n_reviews_all)
			stars=rep("",n_reviews_all)
			reviews=rep("",n_reviews_all)
			postdate=rep("",n_reviews_all)
			fin=1
	
			for(page in 1:n_review_pages){
			# Each page of reviews
				schoolpage_now = readLines(paste(school_link,"?sortBy=&tab=reviews&page=",page,"#revPagination",sep=""))
				n_reviews_now = length(schoolpage_now[grep("<div class=\"mvm\">",schoolpage_now)])-1
		
				for(i in 1:n_reviews_now){
					# info line
					infovec=unlist(strsplit(schoolpage_now[grep("<div class=\"mvm\">",schoolpage_now)][i+1],"[<>]"))
					# reviewer
					if(length(grep("Submitted",infovec))==0){
						reviewer[fin]="na"
					} else {
						almostreviewer=unlist(strsplit(infovec[grep("Submitted",infovec)]," "))[4]
						# check, sometimes there is a name here which messes things up
						if(almostreviewer %in% c("parent", "teacher", "student")){
							reviewer[fin]=almostreviewer
						} else {
							if(is.na(unlist(strsplit(unlist(strsplit(infovec[grep("Submitted",infovec)],","))[2]," "))[3])){
								reviewer[fin]="na"
							} else {
								reviewer[fin]=unlist(strsplit(unlist(strsplit(infovec[grep("Submitted",infovec)],","))[2]," "))[3]
							}
						}	
					}
					# review
					reviewline=schoolpage_now[grep("<div class=\"mvm\">",schoolpage_now)-1][i+1]
					reviews[fin]=gsub("</strong>","",gsub("                        <strong>","",reviewline))
				
					# stars
					infovec=unlist(strsplit(schoolpage_now[grep("<div class=\"mvm\">",schoolpage_now)][i],"[<>]"))
					if(length(grep("i-16-orange",infovec))==0){
						stars[fin]="99"
					} else{
						stars[fin]=unlist(strsplit(infovec[grep("i-16-orange",infovec)],"[- ]"))[12]
					}
		
					# postdate
					almostpostdate=gsub("Posted ","",str_trim(schoolpage_now[grep("<div class=\"mvm\">",schoolpage_now)+1][i]))
					postdate[fin]=nicedate(almostpostdate,today=today,yesterday=yesterday)
					fin = fin + 1
				}
			}
	
		allreviews = rbind(allreviews,cbind(gsid,reviewer,postdate,stars,reviews))
	
		}
		cat("Done with ",school," out of ",n_schools,"in ",state,"-",city,"\n")
	}
	
	# output data
	school.outdata[[1]]=allreviews
	school.outdata[[2]]=cbind(details_keep,n_reviews_keep)
	return(school.outdata)
}


