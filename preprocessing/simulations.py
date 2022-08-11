#!/usr/bin/env python
# coding: utf-8

# In[2]:


import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from collections import Counter 
from tqdm.notebook import trange
from scipy.spatial.distance import jensenshannon
import scipy.stats as st
import random


pd.options.mode.chained_assignment = None


# In[3]:


np.random.beta(2, 5, 10)


# In[102]:


import string 

def generate_word():
    l = np.random.poisson(lam=2.9)
    return ''.join([random.choice(string.ascii_letters) for n in range(l)]) 

corpus = [generate_word().lower() for _ in range(100000)]
df = pd.DataFrame.from_dict(Counter(corpus), orient='index', columns = ['count']).reset_index().sort_values('count', ascending=False).reset_index(drop=True)
df['rank'] = df['count'].rank(method="min", ascending=False)
df['count'] = df['count']/df['count'].sum()
plt.scatter(np.log(df['rank']), np.log(df['count']), s=5)


# ## 1. English approximation:

# Get the corpus:

# In[292]:


with open('texts.txt', 'r') as file:
    texts = file.read().replace('"', '').replace('\n', '').replace(' ', '')


# Corpus size:

# Letter frequencies in the whole corpora:

# In[293]:


res = Counter(texts)
df = pd.DataFrame.from_dict(res, orient='index', columns = ['count']).reset_index().sort_values('index', ascending=True).reset_index(drop=True)
df['freq'] = df['count']/df['count'].sum()
freq_final = df['freq'].tolist()


# Frequencies are correctly counted:

# In[15]:


df['freq'].sum()


# In[18]:


10**5


# Increase the initial chunk size of $10^4$ each step with a $10^4$ random chunk. Then compare the frequencies for each chunk up to $10^5$ with the actual frequency distribution from the whole corpora:

# In[16]:


dfss = []
chunk = 10000
maximum = len(texts)

for k in trange(100):
    dfs = []
    text = ''
    for _ in range(100):
        diff = random.randint(0, maximum-chunk)
        text += texts[diff:diff+chunk]
        res = Counter(text)
        df = pd.DataFrame.from_dict(res, orient='index', columns = ['count']).reset_index()        .sort_values('index', ascending=True).reset_index(drop= True)
        df['freq'] = df['count']/df['count'].sum()
        dfs.append(df['freq'].tolist())
    
    jsd = []

    for el in dfs:
        if len(el) == 26:
            jsd.append(jensenshannon(el, freq_final))
        else:
            pass
    dfss.append(jsd)
        
del text


# In[21]:


plt.figure(figsize=(8, 5))
for jsd in dfss:
    plt.plot(jsd, color='blue', alpha=0.1)
plt.hlines(0.005, xmin=0, xmax=100,
           color='r', linestyles='--',
           label='0.005 difference', linewidth=2)
plt.ylabel('Jensen-Shannon difference w/ \n actual distribution')
plt.xlabel('Number of letters ($\\times 10^4$)')
plt.legend()


# Confidence intervals for the mean:

# In[88]:


res = []

for jsd in zip(*dfss):
    confint = st.norm.interval(0.95,
                            loc=np.mean(jsd),
                            scale=st.sem(jsd))
    mean = np.mean(jsd)
    res.append(list(confint) + [mean])


# In[89]:


mean_ci = pd.DataFrame.from_records(res, columns=['lower', 'upper', 'mean'])


# In[90]:


plt.figure(figsize=(8, 5))
plt.plot([_ for _ in range(100)], mean_ci['mean'])
plt.fill_between([_ for _ in range(100)],
                 y1=mean_ci['lower'],
                 y2=mean_ci['upper'], 
                 alpha=0.2, 
                 color='red')
plt.hlines(0.005, xmin=0, xmax=100,
           color='r', linestyles='--',
           label='0.005 difference', linewidth=2)


# ## 2. Random Zipfian process:

# In[276]:


import scipy.stats as stats
import seaborn as sns
from scipy.stats import rankdata, zipf


# In[326]:


k = np.linspace(0, 80, 101)

for a in np.linspace(1.1, 2, 3):
    p = zipf.pmf(k, a=a)
    plt.plot(k, p, label='a={}'.format(a))


# In[327]:


np.sum(p)


# In[258]:


n = 100000


# In[270]:


z = np.random.zipf(4, n)


# In[271]:


def get_proba(z):
    z = sorted(np.random.zipf(4, n))
    rank = rankdata(z,  method='dense')
    res = Counter(rank)
    df = pd.DataFrame.from_dict(res, orient='index', columns = ['count']).reset_index()    .sort_values('index', ascending=True).reset_index(drop= True)
    df['freq'] = df['count']/df['count'].sum()
    return df['freq'].to_list()


# In[272]:


initial_prob = get_proba(z)
initial_size = len(initial_prob)
print(initial_size)


# In[275]:


get_proba(z[1:10000])


# In[267]:


chunk = 10000
sets = []

for _ in range(100):
    diff = random.randint(0, n-chunk)
    sets += z[diff:diff+chunk]
    prob = get_proba(sets)
    print(prob)
    if len(prob) == initial_size:
        print(jensenshannon(prob, initial_prob))


# In[ ]:




