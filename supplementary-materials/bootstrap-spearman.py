import pandas as pd
from collections import defaultdict
import scipy.stats as st
import numpy as np
from tqdm.auto import tqdm

def permute_spearman(data, complexity_measure: str, n_rep=5000):
    '''
    Function that computes the Spearman correlation between the relative
    frequency of characters and a complexity measure for each script in 
    the dataset. It then permutes the complexity measure for each script
    and computes the Spearman correlation for each permutation. 

    Parameters
    ----------
    data : pd.DataFrame
        Dataframe containing the relative frequency of characters and the   
        complexity measure for each script.
    complexity_measure : str
        Name of the complexity measure. Could be either 'Perimetric_complexity'
        or 'Algorithmic_complexity'.
    n_rep : int, optional (default=1000)
        Number of permutations to compute.
    '''
    spearman = defaultdict(list)
    ac = defaultdict(list)
    
    for script in tqdm(data['ISO_script'].unique(),
                desc='Running the simulation', 
                position=0, 
                leave=True):
        sp = []
        freq = data[data['ISO_script'] == script]['Relative_frequency']
        ac[script] = [st.spearmanr(freq, data[data['ISO_script'] == script][complexity_measure])[0]]
        for _ in range(n_rep):
            sample = data[data['ISO_script'] == script][complexity_measure].sample(n=data[data['ISO_script']
                                                                                          == script].shape[0],
                                                                                   replace=True)
            random_correlation = st.spearmanr(freq, sample)[0]
            sp.append(random_correlation)
        spearman[script] = sp
    
    df = pd.DataFrame.from_dict(spearman)
    df = pd.melt(df, var_name=None)
    df.columns = ['ISO_code', 'correlation']

    ac = pd.DataFrame.from_dict(ac)
    ac = pd.melt(ac, var_name=None)
    ac.columns = ['ISO_code', 'actual_correlation']

    return df, ac

if __name__ == '__main__':
    # Load data
    data = pd.read_csv('../data/final_correction.csv')
    data['Relative_frequency_l'] = data['Relative_frequency'].apply(np.log)
    data = data.query('ISO_language != "heb"')
    # Compute Spearman correlation and permuted Spearman correlation
    df, ac = permute_spearman(data, 'Relative_frequency_l')
    # Save data
    df.to_csv('../data/spearman.csv')
    ac.to_csv('../data/actual_spearman.csv')
