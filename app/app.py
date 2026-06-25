import os
import pandas as pd
import numpy as np
import plotly.express as px
import plotly.graph_objects as go
import streamlit as st
from datetime import date
from utils.data_utils import load_orders, filter_df, compute_kpis, cohort_analysis, rfm_segmentation

st.set_page_config(page_title="Data Storytelling Dashboard", layout="wide")

DATA_PATH = os.environ.get("ORDERS_CSV", os.path.join(os.path.dirname(__file__), "..", "data", "orders.csv"))

@st.cache_data(show_spinner=False)
def load_data():
    return load_orders(DATA_PATH)

df = load_data()
min_d, max_d = df["order_date"].dt.date.min(), df["order_date"].dt.date.max()

st.sidebar.header("Filters")
date_range = st.sidebar.date_input("Date range", value=(min_d, max_d), min_value=min_d, max_value=max_d)
countries = st.sidebar.multiselect("Countries", sorted(df["country"].unique().tolist()))
channels = st.sidebar.multiselect("Channels", sorted(df["channel"].unique().tolist()))
categories = st.sidebar.multiselect("Categories", sorted(df["category"].unique().tolist()))

fdf = filter_df(df, date_range, countries, channels, categories)

kpis = compute_kpis(fdf)
col1, col2, col3, col4, col5, col6 = st.columns(6)
col1.metric("Revenue", f"${kpis['Revenue']:,.0f}")
col2.metric("Profit", f"${kpis['Profit']:,.0f}")
col3.metric("Orders", f"{kpis['Orders']:,}")
col4.metric("Customers", f"{kpis['Customers']:,}")
col5.metric("AOV", f"${kpis['AOV']:,.2f}")
col6.metric("Margin %", f"{kpis['Margin%']*100:,.1f}%")

st.markdown('---')

ts = fdf.groupby("order_month").agg({"revenue":"sum","profit":"sum","order_id":"nunique"}).reset_index()
ts = ts.sort_values("order_month")
fig_ts = go.Figure()
fig_ts.add_trace(go.Scatter(x=ts["order_month"], y=ts["revenue"], mode="lines+markers", name="Revenue"))
fig_ts.add_trace(go.Scatter(x=ts["order_month"], y=ts["profit"], mode="lines+markers", name="Profit", yaxis="y2"))
fig_ts.update_layout(title="Monthly Revenue & Profit", xaxis_title="Month", yaxis_title="Revenue",
                     yaxis2=dict(title="Profit", overlaying="y", side="right"),
                     margin=dict(l=40,r=40,t=60,b=40), height=420)
st.plotly_chart(fig_ts, use_container_width=True)

c1, c2 = st.columns(2)
cat_rev = fdf.groupby("category")["revenue"].sum().sort_values(ascending=False).reset_index()
fig_cat = px.bar(cat_rev, x="category", y="revenue", title="Revenue by Category")
c1.plotly_chart(fig_cat, use_container_width=True)

prod = fdf.groupby(["product_id","subcategory"])["revenue"].sum().reset_index().sort_values("revenue", ascending=False).head(15)
fig_prod = px.bar(prod, x="revenue", y="product_id", color="subcategory", title="Top 15 Products", orientation="h")
c2.plotly_chart(fig_prod, use_container_width=True)

geo = fdf.groupby(["country","city"])["revenue"].sum().reset_index()
fig_geo = px.treemap(geo, path=["country","city"], values="revenue", title="Revenue by Geography (Country → City)")
st.plotly_chart(fig_geo, use_container_width=True)

ch = fdf.groupby("channel")["revenue"].sum().reset_index()
fig_ch = px.pie(ch, values="revenue", names="channel", title="Channel Revenue Share", hole=0.45)
st.plotly_chart(fig_ch, use_container_width=True)

st.subheader("Cohort Analysis (Customer Retention)")
cohort_abs, cohort_ret = cohort_analysis(fdf)
st.caption("Absolute active customers per cohort (rows = cohort month, columns = months since first purchase)")
st.dataframe(cohort_abs.style.background_gradient(cmap="Blues"))
st.caption("Retention rate per cohort")
st.dataframe((cohort_ret*100).round(1).style.background_gradient(cmap="Greens"))

st.subheader("RFM Segmentation")
rfm = rfm_segmentation(fdf)
seg_counts = rfm["Segment"].value_counts().reset_index()
seg_counts.columns = ["Segment","Customers"]
fig_rfm = px.bar(seg_counts, x="Segment", y="Customers", title="Customers by RFM Segment")
st.plotly_chart(fig_rfm, use_container_width=True)

st.download_button("Download filtered CSV", data=fdf.to_csv(index=False).encode("utf-8"),
                   file_name="filtered_orders.csv", mime="text/csv")

st.markdown('---')
st.caption("Data Storytelling Dashboard • Streamlit + Plotly • Synthetic e-commerce dataset")