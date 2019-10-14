# -*- coding: utf-8 -*-
"""
Created on Mon Aug 26 21:23:13 2019

@author: sutturka
"""

import pandas as pd
import argparse

ap = argparse.ArgumentParser()

# Add the arguments to the parser
ap.add_argument("-ratio_genes", "--ratio_genes", required=True,
   help="List of ratio genes")
ap.add_argument("-seg_genes", "--seg_genes", required=True,
   help="List of segment genes")
ap.add_argument("-prefix", "--prefix", required=True,
   help="prefix for the output file")

args = vars(ap.parse_args())


#read input
ratio_genes   = str(args['ratio_genes'])
segment_genes = str(args['seg_genes'])
prefix        = str(args['prefix'])
outfile       = prefix + '_trusted_genes.txt'

ratio = pd.read_csv(ratio_genes, sep = "\t", header=None, names=["Gene_ID"])
seg   = pd.read_csv(segment_genes, sep = "\t", header=None, names=["Gene_ID", "cn"])

#sort and remove duplicate entries
ratio.sort_values("Gene_ID", inplace = True)
ratio.drop_duplicates(subset="Gene_ID", inplace=True)

seg.sort_values("Gene_ID", inplace = True)
seg = seg.loc[seg["cn"] != 2]           # keep only the gainloss regions
seg.drop_duplicates(subset="Gene_ID", inplace=True)

#determine intersection of two sets
intsec = pd.merge(seg, ratio, on="Gene_ID", how="inner")
intsec = intsec.assign(Sample=prefix)
intsec.to_csv(outfile, sep="\t", index=False)
