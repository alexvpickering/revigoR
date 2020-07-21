## code to prepare `go_up` dataset goes here

# from GSE80060 ACR 90+ D1 vs ACR30- D1
go_up1 <- readRDS('data-raw/go_up1.rds')

# from patient data
go_up2 <- readRDS('data-raw/go_up2.rds')



usethis::use_data(go_up1, go_up2, overwrite = TRUE)
