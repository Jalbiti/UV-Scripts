#!/bin/bash

#SBATCH -p AMDMEM

module load ANACONDA2
conda activate triplex

pairtools parse -o microc_pairs/$1.pairs.gz -c sacCer3.reduced.chrom.sizes \
  --drop-sam --drop-seq --output-stats $1.stats \
  --assembly sacCer3 --no-flip \
  --add-columns mapq \
  --walks-policy mask \
  01_bam_lane/$1.fastq.gz.bam

echo "done parse"

pairtools dedup \
    --max-mismatch 3 \
    --mark-dups \
    --output \
        >( pairtools split \
            --output-pairs $1.nodups.pairs.gz \
         ) \
    --output-stats microc_pairs_nodups/$1.dedup.stats \
    microc_pairs/$1.pairs.gz

echo "done dedup"

pairtools sort --nproc 5 -o microc_pairs_sorted/$1.sorted.pairs.gz microc_pairs_nodups/$1.nodups.pairs.gz    

echo "done sort"

CHROMSIZES_FILE='sacCer3.reduced.chrom.sizes'
BINSIZE=100

cooler cload pairs -c1 2 -p1 3 -c2 4 -p2 5 $CHROMSIZES_FILE:$BINSIZE microc_pairs_sorted/$1.sorted.pairs.gz microc_cool_res/$1.cool

echo "done cool"

cooler zoomify \
    --nproc 5 \
    --out microc_mcool_res/$1.mcool \
    --resolutions 100,200,400,800,2000,3000,6000,13000 \
    --balance \
    microc_cool_res/$1.cool

echo "done zoomify"

cooler show --out $1_chrIV.png --dpi 200 microc_cool/$1.cool IV:0-1531930

