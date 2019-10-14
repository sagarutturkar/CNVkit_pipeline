# -*- coding: utf-8 -*-
"""
Created on Fri Oct  4 09:45:05 2019

@author: sutturka
"""
import pandas as pd
import argparse

ap = argparse.ArgumentParser()

# Add the arguments to the parser
ap.add_argument("-infile", "--infile", required=True,
   help="input file name")
ap.add_argument("-outfile", "--outfile", required=True,
   help="output file name")

args = vars(ap.parse_args())

#read input
infile   = str(args['infile'])
outfile  = str(args['outfile'])

df = pd.read_csv(infile, sep = "\t", header=0, 
                 names=["Gene_ID", "cn", "Sample"])

pd.crosstab(df['Gene_ID'], df['Sample'])

x = df.pivot_table(index='Gene_ID', columns='Sample', 
                   values='cn')

x["Altered in Samples"] = x.count(axis=1)
x = x.sort_values(by = "Altered in Samples", ascending=False)

x.to_csv(outfile, sep="\t")
