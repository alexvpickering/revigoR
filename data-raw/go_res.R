## code to prepare `go_res` dataset goes here

go_res <- data.frame(
   row.names = c('GO:0002274', 'GO:0006955', 'GO:0002366', 'GO:0006751', 'GO:1901748', 'GO:0002218', 'GO:0072604', 'GO:0007249'),
   p.val = c(2e-27, 4e-27, 6e-24, 5e-7, 5e-7, 1e-6, 1e-6, 1e-5),
   SYMBOL = I(list(
      c('ADAM8','ALOX5','AMPD3','ANXA3','RHOG','CEACAM1','BST1','CBL','CD58','CD59'),
      c('ADAM8','ALOX5','AMPD3','ANXA1','ANXA3','XIAP','APOA4','RHOG','ARRB2','BCL3','BCL6','CEACAM1','POLR3D','BST1','C4BPA'),
      c('ADAM8','ALOX5','AMPD3','ANXA1','ANXA3','RHOG','BCL3','BCL6','CEACAM1','BST1','CBL','CD86','CD58','CD59','CD63'),
      c('GGT1','GGT3P','GGT5','GGTLC2','GGTLC1','GGT2'),
      c('GGT1','GGT3P','GGT5','GGTLC2','GGTLC1','GGT2'),
      c('XIAP','ARRB2','FCER1G','FFAR2','HCK','IRAK2','LYN','MUC3A','MYD88','NFKB1','NFKBIA','PAK2','PLCG2','PRKCD','PRKDC','RELA','RELB'),
      c('IL1B','IL1RAP','MBP','HYAL2','LILRA2','C5AR2','TLR8','ZC3H12A','IL17RC','NLRP10','LILRA5'),
      c('BCL3','DDX1','IL1B','IL1RN','IRAK2','LTBR','MYD88','NFKBIA','RELA','RELB','ROCK1','SECTM1','TNFAIP3','TNFRSF1A','TRIM25','CFLAR','USP10'))),
   logFC = I(list(
      c(0.51,0.91,0.37,1.4,0.53,1.1,0.46,0.67,0.74,0.97),
      c(0.51,0.91,0.37,-.64,1.4,0.28,0.21,0.53,0.44,0.77,0.1,1.1,-.27,0.46,2.03),
      c(0.51,0.91,0.37,-.64,1.4,0.53,0.77,0.1,1.1,0.46,0.67,-.7,0.74,0.97,.3),
      c(.5,.4,.23,.51,.51,.51),
      c(.5,.4,.23,.51,.51,.51),
      c(0.28,0.44,.34,.97,.55,.76,.54,.24,.33,.49,.6,.55,.49,-.31,-.31,.22,.75),
      c(1.3,0.85,0.74,0.44,0.61,-.46,.73,.88,.3,.47,.75),
      c(0.77,-.37,1.3,.78,.76,.48,.33,.6,.22,.75,.7,.6,.5,.38,.58,.71,.69))),
   analysis = c(0,0,1,0,0,0,1,0),
   stringsAsFactors = FALSE
)

usethis::use_data(go_res, overwrite = TRUE)
