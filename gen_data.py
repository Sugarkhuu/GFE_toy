import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
sns.set_theme()

ny = 20
nc = 10
ng = 3

gtreshold = [0.33,0.66,1]
gtrend = [2,1,4]

# random group assignment
np.random.seed(5)
cg = [1 if i<gtreshold[0] else (2 if i<gtreshold[1] else 3)  for i in np.random.random(nc)]
print(cg)

# create trends for groups
groups = {}
for i in range(ng):
    ds = [0]
    for y in range(ny):
        ds.append(ds[-1]+gtrend[i]+np.random.rand()*25)
    groups['g'+str(i+1)+'t'] = ds[1:]

# create panel data based on groups, group trends and noise
G = []
time = []
individual = []
i_group = []
for i, group in enumerate(cg):
    obs = groups['g'+str(group)+'t']
    G.extend(obs)
    time.extend(np.arange(ny))
    individual.extend(np.full(ny,i))
    i_group.extend(np.full(ny,group))

df = pd.DataFrame()
df['X1'] = np.random.rand(len(G))
df['X2'] = np.random.rand(len(G))
df['Y0'] = G
df['u']  = 10*np.random.randn(len(G))
df['Y'] = df['Y0'] + 5*df['X2'] + 15*df['X1'] + df['u']
df['time'] = time
df['individual'] = individual
df['group'] = i_group

# Visualize
sns.lineplot(data=df,x='time',y='Y',hue='individual')
plt.xticks(np.arange(0, ny, step=5))
plt.show()

df.to_stata(r'Bonhomme_Manresa_codes_replicationFiles_Bonhomme\Bonhomme_Manresa_codes\Application\GFE_generic\df.dta')

# # Have df.dta and Bootstrap_version.exe in GFE_generic. Configure GFE_code.do in line with its instructions regarding df.dta.
# # Then run GFE_code, the resulting data will have the assignment info of groups.
## When running GFE_code.do, choose the following parameters:
# -Enter the path on line 87.
# -Number of groups: type “4”.
# -Number of covariates: “2”.
# -Algorithm: type “1” (for Algorithm 2).
# -Number of simulations: type “10”.
# -Number of neighbors: type “10”.
# -Number of steps: type “10”.
# -Standard errors: type “1” (for bootstrapped standard errors).
# -Algorithm: type “1” (for Algorithm 2).
# -Number of simulations: type “5”.
# -Number of neighbors: type “10”.
# -Number of steps: type “5”.
# -Number of bootstrap replications: type “100”.

# # outputobj.txt contains theta common parameter 

df_gfe = pd.read_stata(r'Bonhomme_Manresa_codes_replicationFiles_Bonhomme\Bonhomme_Manresa_codes\Application\GFE_generic\DATA_GFE.dta')
df_gfe.groupby('individual').agg({'assignment':['mean','max','min']})


## Case study

df = pd.read_stata(r'D:\Documents\bonn\study\22_1\topics_metrics\bonhomme_manresa_2015\Bonhomme_Manresa_codes_replicationFiles_Bonhomme\Bonhomme_Manresa_codes\Application\5yearpanel.dta')
df_gfe = pd.read_stata(r'D:\Documents\bonn\study\22_1\topics_metrics\bonhomme_manresa_2015\Bonhomme_Manresa_codes_replicationFiles_Bonhomme\Bonhomme_Manresa_codes\Application\5yearpanel_GFE.dta')
df_gfe = df_gfe[['fhpolrigaug','lrgdpch','year','assignment','code']]
df_gfe['group'] = df_gfe['assignment'].map({1:'early transition',2:'low democracy',
                        3:'late transition',4:'high democracy'})

palette = {"high democracy":"tab:blue",
           "early transition":"black", 
           "late transition":"yellowgreen",
           "low democracy":"tab:brown",
           "e":"tab:orange", 
           "f":"tab:purple"}
plt.figure()
sns.lineplot(data=df_gfe,x='year',y='fhpolrigaug', hue='group',
        hue_order = ['high democracy', 'early transition', 'late transition','low democracy'],palette=palette)
plt.legend(loc='lower center', ncol=4)
plt.ylabel('Democracy')
plt.xlabel(None)
plt.savefig('democracy.png')

plt.figure()
sns.lineplot(data=df_gfe,x='year',y='lrgdpch', hue='group',
        hue_order = ['high democracy', 'early transition', 'late transition','low democracy'],palette=palette)
plt.legend(loc='lower center', ncol=4)
plt.ylabel('log GDP per capita')
plt.xlabel(None)
plt.savefig('gdp.png')
plt.show()




# codes = df_gfe['code'].unique()
# short_code = []
# for code in codes:
#     print(code)
#     short_code.append(code)
#     sns.lineplot(data=df_gfe[(df_gfe['code'].isin(short_code))],x='year',y='fhpolrigaug', hue='assignment', palette='vlag')
#     plt.show()

# gr = df_gfe.groupby('code').agg({'assignment':['mean','max','min']})
# gr.columns=['mean','max','min']
# gr['range']=gr['max']-gr['min']

# df[["worldincome","worlddemocracy"]].plot()
# df['year'].unique()

# # groups estimated
# # regression is run
# # the group values are mean residuals of the period for those in the group.
# #  0

# df_gfe[(df_gfe['code'].isin(short_code)) & (df_gfe['assignment']==1)]

