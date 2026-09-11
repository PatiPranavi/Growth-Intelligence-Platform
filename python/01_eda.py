# =============================================
# GROWTH INTELLIGENCE PLATFORM
# Python EDA
# STEP 1: Load & Inspect Data
# =============================================

import pandas as pd


# ---------------------------------------------
# 1. Load dataset
# ---------------------------------------------

df = pd.read_csv("data/orders.csv")


# ---------------------------------------------
# 2. Basic information
# ---------------------------------------------

print("\n========== DATASET SHAPE ==========")
print(df.shape)


print("\n========== FIRST 5 ROWS ==========")
print(df.head())


print("\n========== COLUMN NAMES ==========")
print(df.columns.tolist())


print("\n========== DATA TYPES ==========")
print(df.dtypes)


print("\n========== MISSING VALUES ==========")
print(df.isnull().sum())


print("\n========== DUPLICATE ROWS ==========")
print(df.duplicated().sum())


print("\n========== UNIQUE VALUES ==========")

print("Orders:", df["order_id"].nunique())
print("Customers:", df["customer_id"].nunique())
print("Products:", df["product_id"].nunique())
print("Categories:", df["category"].nunique())
print("Subcategories:", df["subcategory"].nunique())
print("Channels:", df["channel"].nunique())


print("\n========== NUMERICAL SUMMARY ==========")
print(df.describe())

# ---------------------------------------------
# 3. Data preparation
# ---------------------------------------------

# Convert order_date to datetime
df["order_date"] = pd.to_datetime(df["order_date"])


# Create profit column
df["profit"] = df["revenue"] - df["cost"]


# Create profit margin column
df["profit_margin"] = (
    df["profit"] / df["revenue"] * 100
)


print("\n========== DATA TYPES AFTER PREPARATION ==========")
print(df.dtypes)


print("\n========== DATE RANGE ==========")
print("Start:", df["order_date"].min())
print("End:", df["order_date"].max())


print("\n========== PROFIT SUMMARY ==========")
print(df["profit"].describe())


print("\n========== PROFIT MARGIN SUMMARY ==========")
print(df["profit_margin"].describe())

loss_items = df[df["profit"] < 0]

print("Number of loss-making line items:", len(loss_items))

print(
    "Percentage of line items:",
    round(len(loss_items) / len(df) * 100, 2),
)

print(
    "Total loss:",
    round(loss_items["profit"].sum(), 2)
)
# ---------------------------------------------
# 5. Customer purchase frequency
# ---------------------------------------------

customer_orders = (
    df.groupby("customer_id")["order_id"]
      .nunique()
      .reset_index(name="order_count")
)

print("\n========== CUSTOMER ORDER FREQUENCY ==========")

print(customer_orders.head())

print("\nOrder count summary:")

print(customer_orders["order_count"].describe())


# ---------------------------------------------
# 6. Customer purchase frequency distribution
# ---------------------------------------------

order_frequency = (
    customer_orders["order_count"]
    .value_counts()
    .sort_index()
)

print("\n========== CUSTOMERS BY ORDER COUNT ==========")

print(order_frequency)


# ---------------------------------------------
# 7. Statistical Exploration
# ---------------------------------------------

print("\n========== SKEWNESS ==========")

numeric_columns = [
    "unit_price",
    "quantity",
    "discount",
    "revenue",
    "cost",
    "profit"
]

print(df[numeric_columns].skew())


# ---------------------------------------------
# 8. Variability
# ---------------------------------------------

print("\n========== VARIABILITY ==========")

variability = pd.DataFrame({
    "mean": df[numeric_columns].mean(),
    "std": df[numeric_columns].std(),
    "min": df[numeric_columns].min(),
    "max": df[numeric_columns].max()
})

print(variability)


# ---------------------------------------------
# 9. Revenue Distribution
# ---------------------------------------------

print("\n========== REVENUE DISTRIBUTION ==========")

print(
    df["revenue"].quantile(
        [0.25, 0.50, 0.75, 0.90, 0.95, 0.99]
    )
)


# ---------------------------------------------
# 10. Profit Distribution
# ---------------------------------------------

print("\n========== PROFIT DISTRIBUTION ==========")

print(
    df["profit"].quantile(
        [0.25, 0.50, 0.75, 0.90, 0.95, 0.99]
    )
)
# ---------------------------------------------
# 11. Revenue Distribution
# ---------------------------------------------

import matplotlib.pyplot as plt

plt.figure(figsize=(8, 5))

plt.hist(df["revenue"], bins=30)

plt.xlabel("Revenue")
plt.ylabel("Number of Transactions")
plt.title("Revenue Distribution")

plt.tight_layout()
plt.show()
# ---------------------------------------------
# 12. Profit Distribution
# ---------------------------------------------

plt.figure(figsize=(8, 5))

plt.hist(df["profit"], bins=30)

plt.xlabel("Profit")
plt.ylabel("Number of Transactions")
plt.title("Profit Distribution")

plt.tight_layout()
plt.show()
# ---------------------------------------------
# 13. Customer Purchase Frequency
# ---------------------------------------------

plt.figure(figsize=(8, 5))

plt.bar(
    order_frequency.index,
    order_frequency.values
)

plt.xlabel("Number of Orders per Customer")
plt.ylabel("Number of Customers")
plt.title("Customer Purchase Frequency")

plt.xticks(order_frequency.index)

plt.tight_layout()
plt.show()
# ---------------------------------------------
# 14. Order-Level Metrics
# ---------------------------------------------

order_metrics = (
    df.groupby("order_id")
      .agg(
          order_revenue=("revenue", "sum"),
          order_quantity=("quantity", "sum")
      )
      .reset_index()
)

print("\n========== ORDER-LEVEL METRICS ==========")

print(order_metrics.head())
# ---------------------------------------------
# 15. Order Revenue Distribution
# ---------------------------------------------

plt.figure(figsize=(8, 5))

plt.hist(
    order_metrics["order_revenue"],
    bins=30
)

plt.xlabel("Order Revenue")
plt.ylabel("Number of Orders")
plt.title("Order Revenue Distribution")

plt.tight_layout()
plt.show()
# ---------------------------------------------
# 16. Correlation Analysis
# ---------------------------------------------

correlation = df[
    [
        "unit_price",
        "quantity",
        "discount",
        "revenue",
        "cost",
        "profit",
        "profit_margin"
    ]
].corr()

print("\n========== CORRELATION MATRIX ==========")

print(correlation.round(2))
# ---------------------------------------------
# 17. Discount vs Profit Margin
# ---------------------------------------------

df["discount_level"] = pd.cut(
    df["discount"],
    bins=[-0.01, 0, 0.05, 0.15, 1],
    labels=[
        "No Discount",
        "Low Discount",
        "Medium Discount",
        "High Discount"
    ]
)
discount_analysis = (
    df.groupby("discount_level", observed=True)
      .agg(
          transactions=("order_id", "count"),
          avg_profit_margin=("profit_margin", "mean")
      )
      .reset_index()
)

print("\n========== DISCOUNT VS PROFIT MARGIN ==========")

print(
    discount_analysis.round(2)
)
# ---------------------------------------------
# 18. Discount vs Profit Margin by Category
# ---------------------------------------------

category_discount_analysis = (
    df.groupby(
        ["category", "discount_level"],
        observed=True
    )
    .agg(
        transactions=("order_id", "count"),
        avg_profit_margin=("profit_margin", "mean")
    )
    .reset_index()
)

print("\n========== DISCOUNT VS PROFIT MARGIN BY CATEGORY ==========")

print(
    category_discount_analysis.round(2)
)
# ---------------------------------------------
# 19. Monthly Revenue & Profit Trend
# ---------------------------------------------

monthly_trend = (
    df.set_index("order_date")
      .resample("ME")
      .agg(
          revenue=("revenue", "sum"),
          profit=("profit", "sum")
      )
      .reset_index()
)

print("\n========== MONTHLY TREND ==========")

print(monthly_trend.head())
plt.figure(figsize=(10, 5))

plt.plot(
    monthly_trend["order_date"],
    monthly_trend["revenue"],
    label="Revenue"
)

plt.plot(
    monthly_trend["order_date"],
    monthly_trend["profit"],
    label="Profit"
)

plt.xlabel("Month")
plt.ylabel("Amount")
plt.title("Monthly Revenue and Profit Trend")

plt.legend()
plt.tight_layout()
plt.show()
# ---------------------------------------------
# 20. SQL Result Validation
# ---------------------------------------------

total_revenue = df["revenue"].sum()
total_cost = df["cost"].sum()
total_profit = df["profit"].sum()

overall_margin = (
    total_profit / total_revenue * 100
)

print("\n========== SQL RESULT VALIDATION ==========")

print("Total Revenue:", round(total_revenue, 2))
print("Total Cost:", round(total_cost, 2))
print("Total Profit:", round(total_profit, 2))
print("Overall Profit Margin:", round(overall_margin, 2))