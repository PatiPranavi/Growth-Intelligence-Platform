import pandas as pd
import numpy as np

def load_orders(csv_path: str) -> pd.DataFrame:
    df = pd.read_csv(csv_path, parse_dates=["order_date"])
    df["order_month"] = df["order_date"].values.astype("datetime64[M]")
    df["profit"] = df["revenue"] - df["cost"]
    return df

def filter_df(df, date_range, countries=None, channels=None, categories=None):
    mask = (df["order_date"].dt.date >= date_range[0]) & (df["order_date"].dt.date <= date_range[1])
    if countries: mask &= df["country"].isin(countries)
    if channels: mask &= df["channel"].isin(channels)
    if categories: mask &= df["category"].isin(categories)
    return df.loc[mask].copy()

def compute_kpis(df):
    kpis = {}
    kpis["Revenue"] = df["revenue"].sum()
    kpis["Profit"] = df["profit"].sum()
    kpis["Orders"] = df["order_id"].nunique()
    kpis["Customers"] = df["customer_id"].nunique()
    kpis["AOV"] = df.groupby("order_id")["revenue"].sum().mean()
    kpis["Margin%"] = (df["profit"].sum() / df["revenue"].sum()) if df["revenue"].sum()>0 else 0
    return kpis

def cohort_analysis(df):
    first = df.groupby("customer_id")["order_month"].min().rename("cohort_month")
    tmp = df.merge(first, on="customer_id", how="left")
    tmp["cohort_index"] = ((tmp["order_month"].dt.year - tmp["cohort_month"].dt.year) * 12 +
                           (tmp["order_month"].dt.month - tmp["cohort_month"].dt.month)) + 1
    cohort = tmp.groupby(["cohort_month", "cohort_index"])["customer_id"].nunique().reset_index()
    cohort_pivot = cohort.pivot(index="cohort_month", columns="cohort_index", values="customer_id").fillna(0).astype(int)
    cohort_ret = cohort_pivot.divide(cohort_pivot[1], axis=0).round(3)
    return cohort_pivot, cohort_ret

def rfm_segmentation(df, as_of=None):
    if as_of is None:
        as_of = df["order_date"].max().normalize() + pd.Timedelta(days=1)
    recency = df.groupby("customer_id")["order_date"].max().apply(lambda d: (as_of - d).days)
    frequency = df.groupby("customer_id")["order_id"].nunique()
    monetary = df.groupby("customer_id")["revenue"].sum()
    r = pd.qcut(recency, 3, labels=[3,2,1])
    f = pd.qcut(frequency.rank(method="first"), 3, labels=[1,2,3])
    m = pd.qcut(monetary.rank(method="first"), 3, labels=[1,2,3])
    rfm = pd.DataFrame({"R":r.astype(int), "F":f.astype(int), "M":m.astype(int)})
    rfm["RFM_Score"] = rfm.sum(axis=1)
    rfm["Segment"] = pd.cut(rfm["RFM_Score"], bins=[2,5,7,9], labels=["New/Cold","Active","Champions"], include_lowest=True)
    rfm.index.name = "customer_id"
    return rfm.reset_index()