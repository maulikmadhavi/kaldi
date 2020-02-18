import pandas as pd
from tqdm import tqdm
file='/data07/maulik/corpus/SdSV/docs/trials'
p=pd.read_csv(file,delimiter=' ',header=None)

mlist = sorted(set([var for var in p[0]]))
mlist_dict=[0]*len(mlist)

for id,m in enumerate(mlist):
    d = {line.split()[0] : line.split()[1] for line in open('scores/tri1/{0}.scores'.format(m))}
    mlist_dict[id] = d


s=[-5]*len(p)
for var in tqdm(range(len(p))):
    sc=mlist_dict[mlist.index(p[0][var])].get(p[1][var])
    if sc:
        s[var]=sc

with open('scores/tri1/outputscores_list', 'w') as f:
    for item in s:
        f.write("%s\n" % item)
