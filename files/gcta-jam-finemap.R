# 9-2-2018 MRC-Epid JHZ

options(scipen=20, width=200, rgl.useNULL=TRUE)

if(file.exists("gcta-slct.csv")&file.exists("jam.cs"))
{
  require(dplyr)
  slct <- rename(read.csv("gcta-slct.csv",as.is=TRUE), rsid1=rsid)
  cs <- rename(read.table("jam.cs",header=TRUE,as.is=TRUE), rsid2=rsid)
  require(openxlsx)
  xlsx <- "gcta-jam-finemap.xlsx"
  wb <- createWorkbook(xlsx)
  addWorksheet(wb, "gcta")
  writeDataTable(wb, "gcta", slct)
  addWorksheet(wb, "jam")
  writeDataTable(wb, "jam", cs)
  m1 <- read.table("jam.out",as.is=TRUE,header=TRUE)
  gcta_m1 <- merge(m1[c("SNP","PostProb_model","PostProb","BF")],slct,by="SNP")
  gcta_cs <- merge(cs[c("snpid","PostProb","BF","Pos")],slct,by.x="snpid",by.y="SNP")
  ord <- with(gcta_cs,order(Chr,Pos))
  addWorksheet(wb, "m1")
  writeDataTable(wb, "m1", m1)
  addWorksheet(wb, "gcta-m1")
  writeDataTable(wb, "gcta-m1", gcta_m1)
  addWorksheet(wb, "gcta-cs")
  writeDataTable(wb, "gcta-cs", gcta_cs[ord,])
  saveWorkbook(wb, file=xlsx, overwrite=TRUE)

  stbed <- read.table("st.bed",as.is=TRUE,header=TRUE)
  require(qpcR)
  for(i in seq(nrow(stbed)))
  {
    r <- paste0("chr",stbed[i,1],"_",stbed[i,2],"_",stbed[i,3])
    cat(stbed[i,"r"],r,"\n")
    slct.r <- subset(slct,region==r)
    cs.r <- subset(cs,region==r)
    slct_cs.r <- qpcR:::cbind.na(slct.r[c("region","SNP","rsid1","pJ")],cs.r[c("snpid","rsid2","PostProb","BF")])
    addWorksheet(wb, r)
    writeDataTable(wb, r, slct_cs.r)
    snplist <- data.frame(snp=unique(sort(c(with(slct.r, SNP),with(cs.r, snpid)))))
    fm <- paste0(r,c(".snp",".config",".ld",".z"))
    if(file.exists(fm[1])&file.exists(fm[2])&file.exists(fm[3])&file.exists(fm[4]))
    {
      snp <- read.table(fm[1],as.is=TRUE,header=TRUE)
      config <- read.table(fm[2],as.is=TRUE,header=TRUE)
      ld <- read.table(fm[3])
      z <- read.table(fm[4],col.names=c("snp","z"))
      index <- with(merge(snp,snplist,by="snp"),index)
      sumstat <- merge(z,snplist,by="snp")
      ld[index,index][upper.tri(ld[index,index])] <- NA
      info <- data.frame(index=rownames(ld)[index],sumstat,ld[index,index])
      slct_cs_info <- paste0(r,".info")
      addWorksheet(wb, slct_cs_info)
      writeDataTable(wb, slct_cs_info, info)
    }
  }
  saveWorkbook(wb, file=xlsx, overwrite=TRUE)

# get in data
  slct <- rename(slct, snpid=SNP, Pos=bp, rsid=rsid1)
  cs <- rename(cs, rsid=rsid2)
  p <- bind_rows(slct[c("region","Chr","Pos","snpid","pJ","rsid")],
                 cs[c("region","Chr","Pos","snpid", "rsid", "PostProb", "BF")])
  ord <- with(p,order(Chr,Pos))
  slct_cs <- p[ord,]

# overlaps, 
  rs <- slct_cs %>% distinct(region, snpid,.keep_all=TRUE)
  i <- intersect(with(slct,snpid),with(cs,snpid))
  filter(rs,snpid%in%i)
  filter(rs,!(snpid%in%i))
  s <- slct_cs %>% distinct(snpid,.keep_all=TRUE)
  u <- with(s,snpid)
  with(s,setdiff(snpid,i))
  write.table(s[c("region","Chr","Pos","PostProb","BF","pJ","snpid","rsid")],file="id",row.names=FALSE,quote=FALSE)
  write.table(u,file="ld",col.names=FALSE,row.names=FALSE,quote=FALSE)
}
