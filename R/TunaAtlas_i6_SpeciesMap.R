Atlas_i6_SpeciesMap <- function(df,
                                geomIdAttributeName="geom_id",
                                yearAttributeName="year", 
                                speciesAttributeName="species",                                         
                                valueAttributeName="value",
                                withSparql=FALSE)
{
  if (! require(maps)) {
    stop("Missing library")
  }
  
  #check inputs
  if (class(df) != "SpatialPolygonsDataFrame")
  {
    stop(paste("Bad geometrical feature type, must be a SpatialPolygonsDataFrame"))
  }
  
  if(sum(names(df) == geomIdAttributeName) == 0) {
    stop("Cannot found geom id attribute")
  }
  
  if(sum(names(df) == yearAttributeName) == 0) {
    stop("Cannot found year attribute")
  }
  
  if(sum(names(df) == speciesAttributeName) == 0) {
    stop("Cannot found species attribute")
  }
  
  if(sum(names(df) == valueAttributeName) == 0) {
    stop("Cannot found value attribute")
  }
  
  #format columns
  df@data[, geomIdAttributeName] <- as.character(df@data[, geomIdAttributeName])
  df@data[, yearAttributeName] <- as.numeric(df@data[, yearAttributeName])
  df@data[, speciesAttributeName] <- as.factor(df@data[, speciesAttributeName])
  df@data[, valueAttributeName] <- as.numeric(df@data[, valueAttributeName])
  
  #rename columns
  names(df)[which(names(df) == geomIdAttributeName)] <- "geom_id"
  names(df)[which(names(df) == yearAttributeName)] <- "year"  
  names(df)[which(names(df) == speciesAttributeName)] <- "species"
  names(df)[which(names(df) == valueAttributeName)] <- "value"
  
  
  plotFct <- function(subDf, species.label, lims) {
    # subDf  <- species.df[species.df$decade==decade.current,]
    #aggregate values by 5° CWP square
    aggData <- aggregate(value ~ geom_id, data=subDf, sum)      
    
    #create a spatial df object from
    aggSp <- SpatialPolygons(species.df[match(aggData$geom_id, species.df$geom_id),]@polygons, proj4string=CRS("+init=epsg:4326"))
    aggSpdf <- SpatialPolygonsDataFrame(Sr=aggSp, data=aggData, match.ID=FALSE)
    
    names(aggSpdf)[names(aggSpdf) == "geom_id"] <- "id"
    aggSpdf.fortify <- ggplot2::fortify(aggSpdf, region="id")
    class(aggSpdf.fortify)
    aggSpdf.df <- plyr::join(aggSpdf.fortify, aggSpdf@data, by="id")
    
    world.df <-  ggplot2::fortify(maps::map("world", plot = FALSE, fill = TRUE))
    
    if (missing(lims)) {
      lims <- range(aggSpdf.df$value, na.rm=TRUE)
    }
    
    if (min(subDf$year) == max(subDf$year)) {
      my.title <- paste(species.label , " catches 5x5° for ",  min(subDf$year), sep="")
    } else {
      my.title <- paste(species.label , " catches 5x5° for ",  min(subDf$year), "-",  max(subDf$year), sep="")
    }
    
    resultPlot <- ggplot2::ggplot() +
      ggplot2::geom_polygon(data=aggSpdf.df, mapping=ggplot2::aes(x = long, y = lat, fill=value, group=group)) +
      ggplot2::scale_fill_continuous(low="yellow", high="blue", na.value="grey25", name="Catches in k. tons", limits=lims, 
                                     guide=guide_colourbar(direction="horizontal", 
                                                           title.position="top",
                                                           label.position="bottom",
                                                           barwidth=20)) +
      geom_path(data=world.df, mapping=ggplot2::aes(x=long, y=lat, group=group), colour="grey25") +
      coord_equal() +
      theme(legend.position="bottom", axis.title.x=element_blank(), axis.title.y=element_blank()) +
      labs(title=my.title)
    
    #draw the plot
    base_temp_file <- tempfile(pattern=paste("I6_", gsub(" ", "_", species.label), "_", as.character(min(subDf$year)), "-", as.character(max(subDf$year)), "_", sep=""))
    plot_file_path <- paste(base_temp_file, ".png", sep="")
    ggsave(filename=plot_file_path, plot=resultPlot, dpi=100)
    return(resultPlot)
  }
  
  #define the resulr df  
  result.df <- c()
  
  #convert values from tons to thousand tons
  df$value <- df$value / 1000
  
  #fisrt subset by species
  for (species.current in unique(df$species)) {
    
    
    species.label <- species.current
    species.URI <- species.current
    
    species.df <- df[df$species == species.current,]
    
    #plot for all the period
    result.plot.df <- plotFct(species.df, species.label)
    result.df <- rbind(result.df, result.plot.df)
    
    #for each year
    if (length(unique(species.df$year)) > 1)
    {
      for(year.current in unique(species.df$year)) {
        result.plot.df <- plotFct(species.df[species.df$year==year.current,], species.label)
        result.df <- rbind(result.df, result.plot.df)
      }
      
      #for each decade
      species.df$decade <- species.df$year - (species.df$year %% 10)
      if (length(unique(species.df$decade)) > 1)
      {
        for(decade.current in unique(species.df$decade)) {
          result.plot.df <- plotFct(species.df[species.df$decade==decade.current,], species.label)
          result.df <- rbind(result.df, result.plot.df)
        }
      }
    }
  }
  
  # return(result.df)
  return(result.plot.df)
}

