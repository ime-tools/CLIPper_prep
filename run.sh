#!/bin/bash

./prep_clipper.pl ../hg38/Homo_sapiens.GRCh38.91.gff3 hg_AS.STRUCTURE.COMPILED.gff hg_exons.bed
./prep_clipper.pl ../mm38/Mus_musculus.GRCm38.91.gff3 mm_AS.STRUCTURE.COMPILED.gff mm_exons.bed
