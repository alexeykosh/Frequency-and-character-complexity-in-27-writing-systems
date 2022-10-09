#!/usr/bin/env python
# coding: utf-8xw

import numpy as np
import pandas as pd


jamo = pd.read_csv('raw_data/PerimComplexRAW.csv', sep='\t')
jamo['ImageRef'] = jamo['ImageRef'].str.strip('.pnm')
jamo['ImageRef'] = jamo['ImageRef'].str.upper()
jamo = jamo[['ImageRef', 'PCComplexity']]
jamo.columns = ['character', 'PCComplexity']
jamo = jamo.drop_duplicates('character')
jamo_c = pd.read_csv('jamo/results.csv').drop_duplicates('filename')
jamo = jamo.set_index('character')
jamo__ = pd.merge(jamo, jamo_c[['filename', 'compressed']].set_index('filename'),
                  left_index=True, right_index=True).reset_index()
jamo__.columns = ['character', 'PCComplexity', 'compressed']
jamo__[jamo__['character'] == '03142']

final = pd.read_csv('../data/final.csv', index_col=0)
final_jamo = pd.merge(final[final['ISO_script'] == 'Jamo'].set_index('index').drop(['Compression'], axis=1), 
                      jamo__.set_index('character'), left_index=True, right_index=True).reset_index()
final_jamo = final_jamo.rename(columns={'compressed': 'Compression'})
final_ = pd.concat([final_jamo, final[final['ISO_script'] != 'Jamo']])
final_.to_csv('../data/final_correction.csv')
