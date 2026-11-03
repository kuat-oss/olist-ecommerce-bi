# Export the star schema from DuckDB to files Power BI can load.
# usage: python scripts/export_powerbi.py [--csv]
import sys
from pathlib import Path

import duckdb

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "powerbi" / "data"
TABLES = ["dim_date", "dim_customer", "dim_product", "dim_seller", "fct_orders", "fct_order_items"]


def main():
    fmt = "csv" if "--csv" in sys.argv else "parquet"
    OUT.mkdir(parents=True, exist_ok=True)
    con = duckdb.connect(str(ROOT / "warehouse" / "olist.duckdb"), read_only=True)
    for t in TABLES:
        path = OUT / f"{t}.{fmt}"
        opts = "(format csv, header true)" if fmt == "csv" else "(format parquet, compression zstd)"
        con.execute(f"copy (select * from {t}) to '{path}' {opts}")
        rows = con.execute(f"select count(*) from {t}").fetchall()[0][0]
        print(f"{t:18s} {rows:>8,} rows -> {path.relative_to(ROOT)}")
    con.close()


if __name__ == "__main__":
    main()
