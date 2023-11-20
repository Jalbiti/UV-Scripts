#!/bin/bash

#SBATCH -p AMDMEM

module load ANACONDA2
conda activate triplex

echo $1
echo 01_bam_lane/$1.fastq.gz.bam

pairtools parse -o microc_pairs/$1.pairs.gz -c sacCer3.reduced.chrom.sizes \
  --drop-sam --drop-seq --output-stats $1.stats \
  --min-mapq 40 \
  --walks-policy 5unique \
  --max-inter-align-gap 30 \
  --assembly sacCer3 --no-flip \
  --add-columns mapq \
  01_bam_lane/$1.fastq.gz.bam

echo "done parse"

pairtools sort --nproc 5 -o microc_pairs_sorted/$1.sorted.pairs.gz microc_pairs/$1.pairs.gz

echo "done sort"

pairtools dedup \
    --nproc-in 5 \
    --max-mismatch 3 \
    --mark-dups \
    --output $1.nodups.pairs.gz \
    --output-stats microc_pairs_nodups/$1.dedup.stats \
    microc_pairs_sorted/$1.sorted.pairs.gz

echo "done dedup"

#pairtools split --nproc-in 8 --nproc-out 8 --output-pairs $1.filt.pairs.gz $1.nodups.pairs.gz

echo "done filtering"

# Note that the input pairs file happens to be space-delimited, so we convert to tab-delimited with `tr`.
CHROMSIZES_FILE='sacCer3.reduced.chrom.sizes'
BINSIZE=100

cooler cload pairs -c1 2 -p1 3 -c2 4 -p2 5 $CHROMSIZES_FILE:$BINSIZE $1.nodups.pairs.gz microc_cool_res/$1.cool

echo "done cool"

cooler zoomify \
    --nproc 5 \
    --out microc_mcool_res/$1.mcool \
    --resolutions 100,200,400,800,2000,3000,6000,13000 \
    --balance \
    microc_cool_res/$1.cool

echo "done zoomify"

cooler show --out $1_chrIV.png --dpi 200 microc_mcool_res/$1.mcool::/resolutions/6000 IV:0-1531930

