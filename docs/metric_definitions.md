# Metric definitions

The same definitions are used in dbt (`dbt/models/marts`), the web dashboard and the Power BI measures (`powerbi/measures.dax`). If a number differs between them, one of them is wrong.

| Metric | Definition | Where |
|---|---|---|
| **Valid order** | Order status is not `canceled` or `unavailable` | `int_orders.is_valid_order` |
| **Orders** | Count of valid orders | `[Orders]` |
| **GMV** | Sum of item prices on valid orders. Freight is not included. | `[GMV]` |
| **Avg order value** | GMV / Orders | `[Avg Order Value]` |
| **Freight % of GMV** | Freight on valid orders / GMV | `[Freight % of GMV]` |
| **Delivered order** | Status is `delivered` and there is a delivery date (8 delivered orders have none) | `int_orders.is_delivered` |
| **Late delivery** | Delivered on a later calendar day than the estimated delivery date shown at checkout | `int_orders.is_late` |
| **Late delivery %** | Late orders / delivered orders | `[Late Delivery %]` |
| **Delivery days** | Days from purchase to delivery | `[Avg Delivery Days]` |
| **Promised days** | Days from purchase to the estimated delivery date | `[Avg Promised Days]` |
| **Avg review** | Average 1-5 review score. One review per order (the most recent one if there are several). Includes reviews on canceled orders. | `[Avg Review]` |
| **Bad review %** | Reviews with 1 or 2 stars / all reviews | `[Bad Review %]` |
| **Customer** | `customer_unique_id`. The source's `customer_id` changes with every order, so it can't be used to count customers. | `dim_customer` |
| **New customer** | A customer's first valid order | `[New Customers]` |
| **Repeat customer** | Customer with 2 or more valid orders, ever | `dim_customer.customer_type` |
| **Cohort retention** | Share of customers whose first order was in month X who placed another order N months later | `mart_cohort_retention` |
| **Seller tier** | Top: late 5% or less and avg review 4.3+. At risk: late over 15% or avg review under 3.5. Standard: everything else. Only sellers with 30+ delivered items are scored. | `mart_seller_scorecard` |

**Analysis window:** Jan 2017 - Aug 2018. The source has only a few hundred orders before 2017 and a few dozen after Aug 2018, which would distort monthly KPIs.

**Currency:** Brazilian reais (R$), nominal.
