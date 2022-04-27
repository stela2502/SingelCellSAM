# SingelCellSAM

## Usage

Illumnina 10x based single cell analysis is currently very much used in our lab.

Lately mitochondrial mutations have become more and more interesting 
as they can be used as an autonomous cell tagging system.
The bioniformatics tools provided by Illumina to analyze single cell data all use the STAR aligner. The standard aligner in genomics is bwa, but this one is not fit for using single cells. The main problem there is that bam files produced with bwa lack the single cell tags.

This Perl package is picking up at that point. After bwa mapping and before even sorting the sam files.

```
bwa map fastq.gz | add10xTags.pl read.R2.fastq.gz read.I1.fastq.gz barcodesOutFile.tsv > tagged.sam
```

This command is an example of how to use this package. The resulting sam file would contain all single cell tags.

```
samtools view bam | split10xsam.pl <barcodes.tsv> <path2sams>
```

Can afterwards split the (sorted) bam file into single cell bam files.

This functionallity should be enough to use bwa as a mapper for (10x) single cell data.


## Install

Recommended using cpanm:

```
sudo cpanm -l local https://github.com/stela2502/SingelCellSAM/tarball/main
```

