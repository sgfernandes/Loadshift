#!/usr/bin/env python
# coding: utf-8

# In[1]:


# NOTE: coding is utf-8
import numpy as np
import pandas as pd
import seaborn as sns


# In[2]:


# dmu_data = pd.read_excel('/Users/abrarrahman/Downloads/Prelim results july/DMU_120_final.xlsx')
towt_data = pd.read_excel('/Users/abrarrahman/Downloads/Prelim results july/TOWT_120_final.xlsx')
# wmu_data = pd.read_excel('/Users/abrarrahman/Downloads/Prelim results july/WMU_120_final.xlsx')
# te_data = pd.read_csv('/Users/abrarrahman/Downloads/Prelim results july/t_e50.csv')
default_data = pd.read_csv('/Users/abrarrahman/Downloads/Prelim results july/default.csv')


# In[3]:


data_list = [towt_data, default_data]
weekdays_list = []
weekends_list = []

for data in data_list:
    data = data.infer_objects()
    data['Date'] = pd.to_datetime(data.Date)
    data['Hour'] = data.Date.dt.hour
    data['Month'] = data.Date.dt.month_name()
    data['Day'] = data.Date.dt.day_name()

    weekdays_list.append(data[(data['Day']=='Monday') | (data['Day']=='Tuesday') | (data['Day']=='Wednesday') | (data['Day']=='Thursday') | (data['Day']=='Friday')])
    weekends_list.append(data[(data['Day'] == 'Saturday') | (data['Day'] == 'Sunday')])


# In[7]:


month_to_season = {
    "December": "Winter",
    "January": "Winter",
    "February": "Winter",
    "March": "Spring",
    "April": "Spring",
    "May": "Spring",
    "June": "Summer",
    "July": "Summer",
    "August": "Summer",
    "September": "Autumn",
    "October": "Autumn",
    "November": "Autumn"
}

for i in range(len(weekdays_list)):
    weekdays_list[i]["Season"] = weekdays_list[i]["Month"].map(month_to_season)
    weekends_list[i]["Season"] = weekends_list[i]["Month"].map(month_to_season)


# In[11]:


# RUNS SLOW
# SKIP IF METERID NOT IN FORMAT <METER_NAME.ENTRY_NUM>

all_weekdays_split = []
all_weekends_split = []

for i in range(len(weekdays_list)):
    weekdays_split = {}
    weekends_split = {}
    
    for index, row in weekdays_list[i].iterrows():
        this_meter = row["meterID"].split(".")[0]
        this_row_dict = {
            "meterID": row["meterID"],
            "Date": row["Date"],
            "Algorithm": row["Algorithm"],
            "NMBE": row["NMBE"],
            "Hour": row["Hour"],
            "Month": row["Month"],
            "Day": row["Day"],
            "Season": row["Season"],
        }
        
        if this_meter not in weekdays_split:
            weekdays_split[this_meter] = [this_row_dict]
        else:
            weekdays_split[this_meter].append(this_row_dict)
            
    for index, row in weekends_list[i].iterrows():
        this_meter = row["meterID"].split(".")[0]
        this_row_dict = {
            "meterID": row["meterID"],
            "Date": row["Date"],
            "Algorithm": row["Algorithm"],
            "NMBE": row["NMBE"],
            "Hour": row["Hour"],
            "Month": row["Month"],
            "Day": row["Day"],
            "Season": row["Season"],
        }
        
        if this_meter not in weekends_split:
            weekends_split[this_meter] = [this_row_dict]
        else:
            weekends_split[this_meter].append(this_row_dict)
    
    all_weekdays_split.append(weekdays_split)
    all_weekends_split.append(weekends_split)


# In[16]:


# SKIP IF METERID NOT IN FORMAT <METER_NAME.ENTRY_NUM>

towt_weekdays = all_weekdays_split[1]
default_weekends = all_weekdays_split[4]
towt_weekends = all_weekends_split[1]
default_weekends = all_weekends_split[4]

dict_to_df_list = [towt_weekdays, default_weekends, towt_weekends, default_weekends]
for dict_to_df in dict_to_df_list:
    for key, value in dict_to_df.items():
        dict_to_df[key] = pd.DataFrame(data=dict_to_df[key])

dict_to_df_list[0]['12_T_DC_140']


# In[5]:


def custom_pivot_table(source: pd.DataFrame, index_col: str, aggregator) -> pd.DataFrame:
    return source.pivot_table(index=index_col, columns='Hour', values='mape', aggfunc=aggregator)

def excel_outputs(path: str, cases: list):
    with pd.ExcelWriter(path) as writer:
        for case in cases:
            custom_pivot_table(case[0], case[1], case[2]).to_excel(writer, sheet_name = case[3])


# In[6]:


cases = [
    [weekdays, "Month", np.mean, "weekday_means"],
    [weekends, "Month", np.mean, "weekend_means"],
    [weekdays, "Month", np.median, "weekday_medians"],
    [weekends, "Month", np.median, "weekend_medians"],
    [weekdays, "Season", np.mean, "szn_weekday_means"],
    [weekends, "Season", np.mean, "szn_weekend_means"],
    [weekdays, "Season", np.median, "szn_weekday_medians"],
    [weekends, "Season", np.median, "szn_weekend_medians"]
]

excel_outputs('/Users/abrarrahman/Desktop/vermont_pivot_tables.xlsx', cases)


# In[49]:


weekdays


# In[95]:


weekdays.boxplot("mape")


# In[93]:


# TODO: comparative by location

a4_dims = (11.7, 8.27)
fig, ax = pyplot.subplots(figsize=a4_dims)
sns.violinplot(ax=ax, x="Season", y="mape", data=weekdays, inner="box")


# In[94]:


a4_dims = (11.7, 8.27)
fig, ax = pyplot.subplots(figsize=a4_dims)
sns.violinplot(ax=ax, x="Season", y="mape", data=weekends, inner="quartile")


# In[18]:


line = sns.relplot(x="Month", y="mape", kind="line", data=weekdays)
line.fig.set_size_inches(10,4)
line


# In[20]:


line = sns.relplot(x="Month", y="mape", kind="line", data=weekends)
line.fig.set_size_inches(10,4)
line


# In[96]:


# TODO: change alphabetization
heatprep = weekends[["Hour","Month","Season","mape"]]
piv = pd.pivot_table(heatprep, values="mape",index=["Month"], columns=["Hour"], fill_value=0)

sns.heatmap(piv)


# In[98]:


piv = pd.pivot_table(heatprep, values="mape",index=["Season"], columns=["Hour"], fill_value=0)

sns.heatmap(piv)


# In[ ]:





# In[ ]:




