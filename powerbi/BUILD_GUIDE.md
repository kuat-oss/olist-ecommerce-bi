# Building the Power BI report

Everything the report needs is already in this folder: the star schema as Parquet files (`data/`), all measures (`measures.dax`), a theme (`theme.json`) and the numbers to check against (`expected_values.md`). Plan on 1-2 hours.

Power BI Desktop only runs on Windows. On a Mac, use a Windows VM (Parallels, UTM) or a lab computer.

## 1. Load the data

1. Open Power BI Desktop, then **Home > Get data > More... > Parquet > Connect**.
2. Paste the full path to `data/fct_orders.parquet`, then click **OK** and **Load**.
3. Repeat for the other five files: `fct_order_items`, `dim_date`, `dim_customer`, `dim_product`, `dim_seller`.
4. Rename each query to the file name without `.parquet` (in the Data pane: right-click > Rename). The measures rely on these exact names.

Check in **Table view** that columns like `is_valid_order` and `is_late` show as True/False. If they show as text, open **Transform data** and set their type to *True/False*.

## 2. Build the model

Go to **Model view** and make sure these relationships exist. Power BI often detects them itself, so delete any extra ones it guessed.

| From (many) | To (one) |
|---|---|
| `fct_orders[date_key]` | `dim_date[date_key]` |
| `fct_orders[customer_key]` | `dim_customer[customer_key]` |
| `fct_order_items[date_key]` | `dim_date[date_key]` |
| `fct_order_items[customer_key]` | `dim_customer[customer_key]` |
| `fct_order_items[product_key]` | `dim_product[product_key]` |
| `fct_order_items[seller_key]` | `dim_seller[seller_key]` |

All of them should be **single direction, many-to-one**. Do not connect the two fact tables to each other: they share dimensions instead.

Then:
- Select `dim_date`, choose **Table tools > Mark as date table**, and pick the `date` column. Time intelligence measures need this.
- Sort `dim_date[month_name]` by `dim_date[month]` (Column tools > Sort by column).
- Hide the key columns in both fact tables (right-click > Hide in report view) so people use the dimensions.
- Set number formats: `item_value`, `freight_value` and `price` as currency (R$); later, also all the `%` measures as percentage.

## 3. Add the measures

1. Open **DAX query view** (the fourth icon on the left).
2. Paste the whole `measures.dax` file.
3. Click **Update model: Add new measures**, the grey link above `DEFINE`. All measures are added in one go.
4. Press **F5** to run the query. Compare the result table with `expected_values.md`: the numbers should match.

## 4. Apply the theme

**View > Themes > Browse for themes**, then pick `theme.json`.

## 5. Report pages

Put a date slicer (`dim_date[date]`, between) and a region slicer (`dim_customer[region]`) on every page, and sync them (View > Sync slicers). Set the date slicer to Jan 2017 - Aug 2018.

### Page 1: Executive overview
- Cards: `GMV`, `Orders`, `Avg Order Value`, `Active Customers`, `Late Delivery %`, `Avg Review`
- Line and column chart: x = `dim_date[year_month]`, columns = `GMV`, line = `Orders`
- Line chart: `GMV MoM %` by month
- Bar chart: top 10 `dim_product[category]` by `Item GMV` (filter: Top N = 10)
- Filled map or bar chart: `GMV` by `dim_customer[state_code]`

### Page 2: Delivery and customer experience
- Cards: `Late Delivery %`, `Avg Delivery Days`, `Avg Promised Days`, `Bad Reviews From Late Orders %`
- Line chart: `Late Delivery %` and `Avg Review` by month, with a constant line at 8% (Analytics pane)
- Clustered bar: `Late Delivery %` by `dim_customer[region]`
- Table: state, `Orders`, `Avg Delivery Days`, `Late Delivery %`, `Avg Review`, with conditional formatting on `Late Delivery %` (background color, red above 0.08)

### Page 3: Sellers
- Card: `Active Sellers`
- Table: `dim_seller[seller_key]`, `dim_seller[state_code]`, `Item GMV`, `Items Sold`, `Item Late %`, `Item Avg Review`. Filter to sellers with 30+ items, sort by `Item GMV`
- Scatter: x = `Item Late %`, y = `Item Avg Review`, size = `Item GMV`, details = seller. The bottom-right corner shows the sellers to talk to first.

### Page 4: Customers
- Cards: `New Customers`, `Repeat Order %`
- Donut: count of `dim_customer[customer_key]` by `dim_customer[customer_type]`
- Matrix (cohort table): rows = `dim_customer[cohort_month]`, columns = months since first order. For this you need a calculated column in `fct_orders`:

  ```
  Months Since First =
  DATEDIFF ( RELATED ( dim_customer[cohort_month] ), RELATED ( dim_date[date] ), MONTH )
  ```

  Values = `Active Customers`. Use conditional formatting to turn it into a heatmap.

## 6. Save and share

- Save as `olist_bi.pbix` in this `powerbi/` folder.
- Take a screenshot of each page and save them as `docs/powerbi_overview.png`, `docs/powerbi_delivery.png`, `docs/powerbi_sellers.png` and `docs/powerbi_customers.png`.
- Commit the `.pbix` and the screenshots. The file is about 15-20 MB, which is fine for GitHub.
