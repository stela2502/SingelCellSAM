head -n 2000 Sample001_mapped.sam > first1000reads.sam
zcat 10k_PBMC_Multiome_nextgem_Chromium_X_atac_S2_L001_R2_001.fastq.gz | head -n 4000 > first1000_R2.fastq
zcat 10k_PBMC_Multiome_nextgem_Chromium_X_atac_S2_L001_R1_001.fastq.gz | head -n 4000 > first1000_R1.fastq
zcat 10k_PBMC_Multiome_nextgem_Chromium_X_atac_S2_L001_R3_001.fastq.gz | head -n 4000 > first1000_R3.fastq
zcat 10k_PBMC_Multiome_nextgem_Chromium_X_atac_S2_L001_I1_001.fastq.gz | head -n 4000 > first1000_I1.fastq
