#!/usr/bin/env python
# coding: utf-8

# In[1]:


#data wrangling
import pandas as pd

#datetime
import datetime as dt


# In[2]:


# load sheet Transactions trong file KPMG và in ra 5 dòng đầu tiên
Trans=pd.read_excel("KPMG.xlsx",sheet_name="Transactions")
Trans = Trans.loc[:, ~Trans.columns.str.contains('^Unnamed')]
Trans.head(5)


# In[3]:


# in ra info bảng
Trans.info()


# In[4]:


# describe default
Trans.describe()


# In[5]:


# describe các biến object
Trans.describe(include=[object])


# In[6]:


#describe all
Trans.describe(include="all")


# In[7]:


# count số dòng bị null ở mỗi cột
Trans.isna().sum()


# # 1. Data Correction

# ## 1.1 Drop NA

# In[8]:


# tạo bảng df_dropna_all bằng cách loại bỏ tất cả giá trị null trong bảng và in ra info
df_dropna_all=Trans.dropna()
df_dropna_all.info()


# In[9]:


# tạo bảng df_dropna_online_order bằng cách loại bỏ giá trị null trong cột online_order và in ra info
df_dropna_online_order = Trans.dropna(subset = ['online_order'])
df_dropna_online_order.info()



# ## 1.2 Fill NA

# In[10]:


# fill tất cả NA bằng 0, lưu vào bảng df_fillna_0 và in ra info
df_fillna_0=Trans.fillna(0)


# In[11]:


# fill NA bằng ffill, lưu vào bảng df_fillna_ffill và in ra info
df_fillna_ffill=Trans.fillna(method="ffill")


# In[12]:


# fill NA bằng bfill, lưu vào bảng df_fillna_bfill và in ra info
df_fillna_bfill=Trans.fillna(method="bfill")


# ## 1.3. Assess Categorial Data

# In[13]:


# load sheet Demographic và hiển thị top head
Degra=pd.read_excel("KPMG.xlsx",sheet_name="CustomerDemographic")


# In[14]:


# in ra info bảng 
Degra.info()


# In[15]:


# describe các giá trị object
Degra.describe(include=[object])


# In[16]:


# Remove all NA row
Degra.dropna()


# In[17]:


# In ra các giá trị unique của cột gender
Degra.gender.unique()


# In[18]:


# Quy chuẩn cột Gender về 2 nhóm Male và Female, Unisex và in ra giá trị unique mới
Degra["gender"]=Degra["gender"].replace(["M","F","U","Femal"],["Male","Female","Unisex","Female"])


# In[19]:


# Tính tuổi của mỗi khách hàng và lưu vào cột "Age" và in ra min age, max age
Degra.gender.unique()


# In[20]:


# phân nhóm khách hàng dưới 35 tuổi là nhóm "Young", Từ 36 - 55 là "Middle", trên 55 là Older
# lưu vào cột "Age_Group" bằng cách sử dụng hàm cut
Degra_DOB=Degra.dropna(subset=["DOB"])
import pandas as pd
from datetime import datetime
today = datetime.today()
Degra_DOB['age'] = Degra_DOB['DOB'].apply(
               lambda x: today.year - x.year - 
               ((today.month, today.day) < (x.month, x.day)) 
               )
bins=[0,36,55,110]
labels=["Young","Middle","Older"]
Degra_DOB["Age_Group"]=pd.cut(Degra_DOB["age"],bins=bins,labels=labels,right=True)
print('min age:', Degra_DOB['age'].min())
print('max age:', Degra_DOB['age'].max())


# # 2. Data Completeness

# In[21]:


#join data sale vs demographic và in ra những trường hợp missing trong demographic


# In[22]:


Trans_Degra=Trans.merge(Degra,how="left",on="customer_id")
Trans_Degra


# In[23]:


Trans_Degra[Trans_Degra["transaction_id"].isna()]

#Trường hợp này anh muốn in ra những customer mà có trong data sale mà ko có trong bảng demographic.
# Nếu data chuẩn thì tất cả khách hàng ở data sale phải được reflect trong bảng demographic

# Degra_Trans[Degra_Trans["first_name"].isnull()]


# # 3. Data Aggregation

# In[24]:


# tính tổng khách hàng bằng hàm nunique
Trans_Degra["first_name"].nunique()


# In[25]:


# Tính số khách khách hàng mỗi tháng
# hint 1: tạo collum year_month bằng hàm dt.strftime
# hint 2: group by year_month và nunique
Total_customer_per_month=Trans_Degra.groupby(pd.Grouper(key='transaction_date', axis=0, 
                      freq='M'))["first_name"].nunique()
Total_customer_per_month


# In[26]:


# Tính Gross magin của mỗi tháng. Gross magin = list_price - standard_cost
# hint 1: tạo collum Gross_Margin
# hint 2: group by year_month và sử dụng hàm agg
Trans_Degra["Gross_Margin"]=Trans_Degra["list_price"]-Trans_Degra["standard_cost"]
Gross_margin_per_month=Trans_Degra.groupby(pd.Grouper(key='transaction_date', axis=0, 
                      freq='M'))["Gross_Margin"].sum()
Gross_margin_per_month


# In[27]:


# Tính số lượng order và doanh thu group by online_order và order_status 
# hint 1: group by online_order, order_status và sử dụng hàm agg
sum_order_gross=Trans_Degra.groupby(["online_order","order_status"])["online_order","Gross_Margin"].agg(["sum"])
sum_order_gross


# # 4. Data Visualization

# In[28]:


# Sử dụng seaborn và vẽ ra 5 loại chart khác nhau (column, line, box,...) với đầy đủ tên chart, tên các trục và chú thích.
import matplotlib.pyplot as plt
import seaborn as sns
Trans_Degra


# In[29]:


sns.catplot(x="order_status",data=Trans_Degra,kind="count")


# In[30]:


sns.relplot(x="list_price",y="Gross_Margin",data=Trans_Degra,kind="scatter",hue="list_price")


# In[31]:


Total_customer_per_month_df=pd.DataFrame(Total_customer_per_month).rename(columns={"first_name":"Total"})
Total_customer_per_month_df=Total_customer_per_month_df.reset_index()
Total_customer_per_month_df


# In[32]:


sns.relplot(x="transaction_date",y="Total",data=Total_customer_per_month_df,kind="line")


# In[33]:


sns.catplot(x="wealth_segment",y="list_price",kind="box", data=Trans_Degra)


# In[34]:


sns.catplot(x="product_line",y="Gross_Margin",kind="point", data=Trans_Degra,hue="product_line")


# In[ ]:




