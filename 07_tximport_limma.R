
### zblezble @ 2025

# set paths
setwd("C:/users/zblezble/astrocytes/")

# set seed
set.seed(1337)

# load libraries
library("GenomicFeatures")
library("tximport")
library("AnnotationDbi")
library("limma")
library("dplyr")
library("edgeR")
library("org.Hs.eg.db")
library("tibble")

# load metadata
samples <- read.csv("metadata.csv", row.names = 1)

# load salmon results
files <- file.path("salmon", samples$sample_id, "quant.sf")
names(files) <- samples$Name
all(file.exists(files))

# use genomicFeatures to make tx2gene from gtf file
txVoc1 <- makeTxDbFromGFF("gencode.v49.annotation.gtf", dataSource = "GENCODE", organism = "Homo sapiens")
columns(txVoc1)
k <- keys(txVoc1, keytype = "TXNAME")
txdb1 <- AnnotationDbi::select(txVoc1, k, "GENEID", "TXNAME")

# remove gene versions
head(txdb1)
txdb1$GENEID <- gsub("\\..*", "", txdb1$GENEID)
head(txdb1)

### import and convert data from salmon
txi <- tximport(files, type = "salmon", tx2gene = txdb1)

# get counts
counts <- DGEList(txi$counts)

# filtering using the design
design <- model.matrix(~0 + Type, data = samples)
keep <- filterByExpr(counts, design)
data <- counts[keep, ]

# normalize
data <- calcNormFactors(data)
linearCPM <- cpm(data, log = FALSE)
logCPM <- cpm(data, log = TRUE)

# run voom transformation
vdata <- voom(data, design, plot = TRUE)

# fitting linear model
fit <- lmFit(vdata, design)

# set comparisons
head(coef(fit))
contr <- makeContrasts(TypesAD - Typecontrol, levels = colnames(coef(fit)))
tmp <- contrasts.fit(fit, contr)

# add annotations
top.table <- topTable(tmp, sort.by = "P", n = Inf)
head(top.table)
resOut <- as.data.frame(top.table)
resOut$symbol = mapIds(org.Hs.eg.db, keys = row.names(resOut), column = "SYMBOL", keytype = "ENSEMBL", multiVals = "first")
resOut$entrezid = mapIds(org.Hs.eg.db, keys = row.names(resOut),  column = "ENTREZID", keytype = "ENSEMBL", multiVals = "first")
resOut$genename = mapIds(org.Hs.eg.db, keys = row.names(resOut),  column = "GENENAME", keytype = "ENSEMBL", multiVals = "first")

# export results
write.csv(resOut, "limma_type.csv", row.names = TRUE)


