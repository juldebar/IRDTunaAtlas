Atlas_i3_SpeciesYearByGearMonth <- function(df, 
                                            yearAttributeName="year", 
                                            monthAttributeName="month", 
                                            speciesAttributeName="species",
                                            gearTypeAttributeName="gear_type",
                                            valueAttributeName="value",
                                            meanPrev5YearsAttributeName="mean_prev_5_years",
                                            stddevPrev5YearsAttributeName="stddev_prev_5_years",
                                            withSparql=FALSE)
{
  if (! require(XML) | ! require(ggplot2) | ! require(RColorBrewer)) {
    stop("Missing library")
  }
  
  if (missing(df)) {
    stop("Input data frame not specified")
  }
  
  #check for input attributes
  if(sum(names(df) == yearAttributeName) == 0) {
    stop("Cannot found year attribute")
  }
  
  if(sum(names(df) == monthAttributeName) == 0) {
    stop("Cannot found month attribute")
  }
  
  if(sum(names(df) == speciesAttributeName) == 0) {
    stop("Cannot found species attribute")
  }
  
  if(sum(names(df) == gearTypeAttributeName) == 0) {
    stop("Cannot found gear attribute")
  }
  
  if(sum(names(df) == valueAttributeName) == 0) {
    stop("Cannot found value attribute")
  }  
  
  if(sum(names(df) == meanPrev5YearsAttributeName) == 0) {
    stop("Cannot found mean for previous years attribute")
  }
  
  if(sum(names(df) == stddevPrev5YearsAttributeName) == 0) {
    stop("Cannot found std_dev for previous years attribute")
  }
  
  #format columns  
  df[, yearAttributeName] <- as.numeric(df[, yearAttributeName])
  df[, monthAttributeName] <- as.numeric(df[, monthAttributeName])
  df[, speciesAttributeName] <- as.factor(df[, speciesAttributeName])
  df[, gearTypeAttributeName] <- as.factor(df[, gearTypeAttributeName])
  df[, valueAttributeName] <- as.numeric(df[, valueAttributeName])
  df[, meanPrev5YearsAttributeName] <- as.numeric(df[, meanPrev5YearsAttributeName])
  df[, stddevPrev5YearsAttributeName] <- as.numeric(df[, stddevPrev5YearsAttributeName])
  
  #rename columns
  names(df)[which(names(df) == yearAttributeName)] <- "year"
  names(df)[which(names(df) == monthAttributeName)] <- "month"  
  names(df)[which(names(df) == speciesAttributeName)] <- "species"
  names(df)[which(names(df) == gearTypeAttributeName)] <- "gear_type"
  names(df)[which(names(df) == valueAttributeName)] <- "value"
  names(df)[which(names(df) == meanPrev5YearsAttributeName)] <- "mean_prev_5_years"
  names(df)[which(names(df) == stddevPrev5YearsAttributeName)] <- "stddev_prev_5_years"
  
  #from std deviation to variance, and root square the sum of variances
  fct <- function(vec)
  {
    var <- vec * vec
    var <- sum(var)
    return(sqrt(var))
  }
  
  #test if FAO usual gear codes are used
  if (length(intersect(levels(df$gear_type), c("BB", "GILL", "LL", "PS", "OTHER_I", "OTHER_A", "TROL", "TRAP"))) == length(levels(df$gear_type))) {
    df$gear_type <- factor(df$gear_type, levels=c("BB", "GILL", "LL", "PS", "OTHER_I", "OTHER_A", "TROL", "TRAP"), labels=c("Baitboat", "Gillnet", "Longline", "Purse seine", "Unclass. art. Indian O.", "Unclass. art. Atl. O.", "Trol.", "Trap"))
  }
  
  #setup the palette
  my.colors <- brewer.pal(length(levels(df$gear_type)), "Set1")
  names(my.colors) <- levels(df$gear_type)
  
  #define the result
  result.df <- c()
  
  #for each species
  for (species.current in unique(df$species)) {
    species.label <- species.current
    species.URI <- species.current
    #for each year
    # for (year.current in unique(df[df$species == species.current,]$year)) {
    
      year.current= max(unique(df[df$species == species.current,]$year)) 
      current.df <- df[df$species == species.current & df$year == year.current,]
      
      if (! all(table(current.df$month) == 1)) {
        if (all(is.na(current.df$stddev_prev_5_years))) {
          stddev.agg <- cbind(month=unique(current.df$month), stddev_prev_5_years=NA)
        } else {
          stddev.agg <- aggregate(stddev_prev_5_years ~ month, data=current.df, fct)
        }
        
        if (all(is.na(current.df$mean_prev_5_years))) {
          mean.agg <- cbind(month=unique(current.df$month), mean_prev_5_years=NA)
        } else {
          mean.agg <- aggregate(mean_prev_5_years ~ month, data=current.df, sum)
        }
        
        dfPrev5Years <- merge(mean.agg, stddev.agg)            
        
      } else {
        dfPrev5Years <- current.df
      }
      #order gear factor levels by value
      current.df$gear_type <- factor(current.df$gear_type, levels=rev(levels(reorder(current.df$gear_type, current.df$value))))
      #set proper month label
      current.df$month <- factor(month.abb[current.df$month], levels=levels(reorder(month.abb[current.df$month], current.df$month)))
      dfPrev5Years$month <- factor(month.abb[dfPrev5Years$month], levels=levels(reorder(month.abb[dfPrev5Years$month], dfPrev5Years$month)))
      #build the plot
      resultPlot <- ggplot() +
        geom_bar(data=current.df,
                 mapping=aes(x=month, y=value, fill=gear_type, order=gear_type),
                 stat="identity") + 
        geom_line(data=dfPrev5Years,
                  mapping=aes(x=month, y=mean_prev_5_years, group=1),
                  stat="identity") + 
        geom_errorbar(data=dfPrev5Years,
                      mapping=aes(x=month, ymax=mean_prev_5_years + stddev_prev_5_years, ymin=mean_prev_5_years - stddev_prev_5_years), 
                      width=0.25, 
                      color="dimgray",
                      stat="identity") + 
        scale_fill_manual(name="Gear type", values=my.colors) +
        xlab("Month") + ylab("Catches in tons") + 
        ggtitle(paste(species.label, "monthly catches by gear type on", year.current))
      
    # }
    
    
  }
  
  return(resultPlot)
}