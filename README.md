# 🛒 Philippine E-Commerce Regional Sales & RFM Analytics

An end-to-end data analytics project featuring data cleaning, SQL view transformations, customer behavioral segmentation (RFM analysis), and year-over-year (YoY) revenue pacing across Philippine island groups (**Luzon, Visayas, Mindanao**).

---

## 📌 Project Executive Summary

This project evaluates retail transactional performance for an e-commerce business operating across the Philippines for **2025 and 2026**. Raw transactional datasets were cleaned, transformed, and modeled using SQL to analyze:

1. **Regional Sales Distribution:** Mapping customer distribution across regions.
2. **Year-over-Year (YoY) Financial Growth:** Tracking monthly revenue performance and cumulative annual pacing.
3. **RFM Customer Lifecycle Segmentation:** Categorizing customer behavior using Recency, Frequency, and Monetary metrics to identify high-value VIPs and at-risk revenue.
4. **Product Portfolio Performance:** Ranking hero products by sales volume, gross revenue, and Average Order Value (AOV).

---

## 🛠️ Tool Stack

* **SQL (Database Staging & Views):** Data cleaning, string parsing, conditional categorization, window functions (`SUM OVER`, `PERCENT_RANK`, `RANK`), CTEs, and view definitions.
* **Power BI (Data Visualization & Dashboarding):** Star-schema data modeling, interactive visual layout, and DAX measures.
* **Git & GitHub:** Version control and portfolio documentation.

---

## 📁 Dataset Architecture & SQL Transformation

The dataset was AI-generated using Mockaroo with the following schema:
  orders (order_id, customer_id, order_date, order_status)
  order_items (order_id, product_id, unit_price, quantity)
  customers (customer_id, signup_date, region)

The data pipeline transitions raw transactional data into clean, structured database views optimized for reporting:

### 1. Data Cleaning & Staging Pipeline
* **Customer Regional Mapping:** Transformed raw regional location data into major island groups (**Luzon, Visayas, Mindanao**).
* **Currency Formatting:** Stripped currency strings (`$`) and converted monetary fields to numeric `DECIMAL(10,2)` types.
* **SQL Staging Views Generated:** `vw_customers`, `vw_orders`, `vw_order_items`.

### 2. Analytical Database Views Created

| View Name | Core Analytical Focus | Key SQL Techniques Used |
| :--- | :--- | :--- |
| `vw_monthly_revenue` | 2025 vs. 2026 Monthly Revenue & YoY Growth | CTEs, `CASE WHEN` Aggregation, `SUM() OVER(ORDER BY month)` |
| `vw_Recency` | Customer Inactivity Bucketing (`Active`, `At Risk`, `Lost`) | `DATEDIFF`, `MAX(order_date)`, Conditional Logic |
| `vw_Frequency` | Order Volume Tiers (`One-time`, `Repeat`, `Frequent`) | `COUNT(*)`, Aggregations, Conditional Bucketing |
| `vw_Monetary` | Spend Distribution Tiers (`VIP Top 5%`, `High Value`, `Core`) | Windowed `PERCENT_RANK() OVER(ORDER BY total_monetary DESC)` |
| `vw_Product_Perf` | Item Rankings, Volume, Revenue, and AOV | `SUM()`, `COUNT(DISTINCT)`, `ROUND()`, `RANK() OVER()` |

---

## ❓ Business Questions Answered

### 1. Revenue Dynamics & YoY Growth
* How is our monthly revenue pacing in **2026 compared to 2025**?
* Which months demonstrate peak seasonality versus low-volume periods?

### 2. Customer Health & Retention Analytics
* What percentage of our total customer base is **Active** ($\le 100\text{ days}$) vs. **At Risk** ($101\text{--}200\text{ days}$)?
* How severe is customer drop-off after the initial purchase (One-time Buyers vs. Repeat Buyers)?

### 3. Customer Value & Revenue Concentration (RFM)
* Does our revenue distribution follow the **80/20 Pareto Principle**?
* What proportion of total revenue is tied to our **VIPs (Top 5% Spenders)**?
* What is our total financial risk exposure from customers currently in the **At-Risk** recency window?

### 4. Product Efficiency & Regional Footprint
* Which top-ranked products drive the majority of top-line revenue?
* How does Average Order Value (AOV) vary across product categories?
* What is the geographic distribution of our customer base across the different regions?

---

## 📊 Key Performance Indicators (KPIs)
* **Net YoY Growth (%):** $\frac{\text{Revenue 2026} - \text{Revenue 2025}}{\text{Revenue 2025}} \times 100$
* **Product AOV:** $\frac{\text{Total Revenue}}{\text{Distinct Order Count}}$
* **VIP Revenue Share (%):** $\frac{\text{Total Spend from VIP Customers}}{\text{Total Overall Company Revenue}} \times 100$
* **At-Risk Revenue Exposure (%):** $\frac{\text{Total Spend from At-Risk Customers}}{\text{Total Overall Company Revenue}} \times 100$

---

## 🎨 Power BI Dashboard Architecture

The Power BI report utilizes two primary views:

* **Page 1: Executive Revenue & Regional Overview:** High-level KPI cards, monthly dual-axis revenue comparison chart, regional donut breakdown, and product performance leaderboard.
* **Page 2: RFM Customer Behavioral Segmentation:** Customer recency, frequency, and monetary spend tier donut chart.

---

## 💡 Strategic Business Recommendations

1. **Win-Back Re-engagement Campaigns:** Automate targeted email discounts for customers moving into the **At-Risk** window ($101\text{--}200\text{ days}$) to protect revenue exposure before they transition to **Lost**.
2. **First-Purchase Onboarding Incentives:** Build automated follow-up sequences for **One-Time Buyers** within 14 days of receipt to convert them into **Repeat Customers**.
3. **VIP Loyalty Program:** Establish exclusive perks and early product access for the **Top 5% VIP spenders** to maintain top-tier retention.


