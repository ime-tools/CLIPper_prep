#!/usr/bin/env perl

use strict;
use warnings;

my $in = shift;
my $out1 = shift;
my $out2 = shift;

open(IN, "<", $in) || die "$in: $!\n";
open(OUT1, ">", $out1) || die "$out1: $!\n";
open(OUT2, ">", $out2) || die "$out2: $!\n";

my $input = {};
my $ids   = {};

while(<IN>)
{
    chomp;
    my @f = split(/\t/, $_);
    next unless ($f[2]);# && ($f[2] eq "exon" || $f[2] eq "gene" || $f[2] eq "mRNA"));

    my $id;
    if ($f[8] =~ /ID=([^;]+)/)
    {
	$id = $1;
	$ids->{$id} = \@f;
    }

    my $parent;
    if ($f[8] =~ /Parent=([^;]+)/)
    {
	$parent = $1;
	#push(@{$input->{$parent}}, \@f);
    }

    if ($f[2] eq "exon" && $parent)
    {
	# find the gene id
	while ($ids->{$parent}[2] ne "gene" && $ids->{$parent}[8] =~ /Parent=([^;]+)/)
	{
	    unless ($ids->{$parent}[8] =~ /Parent=([^;]+)/)
	    {
		die "'$parent' could not be found\n";
	    }

	    $parent = $1;
	}
	
	$ids->{$parent}[10] += ($f[4]-$f[3]+1);

	# only print exons for genes
	next unless ($ids->{$parent}[2] eq "gene");

# You'll need to make two things.  First a XX_exons.bed file.

# This file should contain a listing on the exons you want to look at and
# follows the bed format

# chr1    11869   12227   ENSG00000223972.5       0       +

# col1: chrom

# col2: exon start

# col3: exon stop

# col4: gene id (used to identify all exons in a gene)

# col5: 0 (empty, used for score normally)

# col6: strand of exon
	
	print OUT2 join("\t", (
			    $f[0],
			    $f[3],
			    $f[4],
			    $parent,
			    0,
			    $f[6]
			)), "\n";
    }
}

# You'll also need a XX_AS.STRUCTURE.COMPILED.gff

# it follows a fairly standard gff file format

# chr19   AS_STRUCTURE    gene    68403   69146   .       +       .
# gene_id=ENSG00000267111.1;mrna_length=744;premrna_length=744

# col1: chrom

# col2: AS_STRUCTURE (just leave it as is)

# col3: gene (just leave that as is as well, there are only features of type
# gene in this file)

# col4: gene start

# col5: gene stop

# col6: . (empty)

# col7: strand of gene

# col8: . (empty)

# col9: extra features.  It needs to follow format I've got above exactly

#     gene_id=XXX;mrna_length=XXX;premrna_length=XXX

#     gene_id is a unique ID for the gene.  It needs to match the gene IDs found
#     in the XX_exons.bed file

#     mrna_length is the length of the predicted mRNA.  I sum all exon lengths to
#     get this

#     premrna_length is the length of the pre-mrna.  I calculate this just by
#     doing gene stop - gene start.

foreach my $key (sort {$ids->{$a}[0] cmp $ids->{$b}[0] || $ids->{$a}[3] <=> $ids->{$b}[3] || $ids->{$a}[6] cmp $ids->{$b}[6] } keys %{$ids})
{
    if ($ids->{$key}[2] eq "gene")
    {
	unless (defined $ids->{$key}[10])
	{
	    $ids->{$key}[10] = 0;
	}
	print OUT1 join("\t", (
			    $ids->{$key}[0], 
			    "AS_STRUCTURE", 
			    $ids->{$key}[2], 
			    $ids->{$key}[3], 
			    $ids->{$key}[4], 
			    ".", 
			    $ids->{$key}[6], 
			    ".", 
			    "gene_id=".$key.";mrna_length=".($ids->{$key}[10]).";premrna_length=".($ids->{$key}[4]-$ids->{$key}[3]+1)
			)), "\n";
    }
}

close(OUT2) || die "$out2: $!\n";
close(OUT1) || die "$out1: $!\n";
close(IN) || die "$in: $!\n";
