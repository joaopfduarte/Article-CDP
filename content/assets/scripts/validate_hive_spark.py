#!/usr/bin/env python3
"""Recompute Hive vs Spark statistics from results.csv and cross-check prose claims.

Usage (from repo root):
    python3 content/assets/scripts/validate_hive_spark.py

Expects content/assets/scripts/results.csv with columns Original_Value and
Simulacao_1..Simulacao_9 (10 measured runs per query/engine).
"""
from __future__ import annotations

import csv
import sys
from pathlib import Path
from statistics import mean

# Rounded means as published in Table~\\ref{tab:benchmark-results} (Performance Evaluation).
TABLE_PAPER: dict[str, tuple[float, float]] = {
    "Q1": (541.5, 259.9),
    "Q2": (561.1, 203.0),
    "Q3": (518.8, 213.0),
    "Q4": (557.0, 204.9),
    "Q5": (1120.2, 257.8),
    "Q6": (1519.3, 238.2),
    "Q7": (959.4, 252.5),
    "Q8": (1175.1, 318.3),
    "Q9": (1871.5, 574.8),
    "Q10": (1785.5, 288.2),
    "Q11": (884.4, 278.3),
    "Q12": (2459.1, 347.2),
    "Q13": (1326.0, 279.0),
    "Q14": (881.0, 288.1),
}

GROUPS: list[tuple[str, list[str]]] = [
    ("Q1--Q4", ["Q1", "Q2", "Q3", "Q4"]),
    ("Q5--Q7", ["Q5", "Q6", "Q7"]),
    ("Q8--Q11", ["Q8", "Q9", "Q10", "Q11"]),
    ("Q12--Q14", ["Q12", "Q13", "Q14"]),
]


def ten_values(row: dict[str, str]) -> list[float]:
    vals = [float(row["Original_Value"])]
    for i in range(1, 10):
        vals.append(float(row[f"Simulacao_{i}"]))
    return vals


def main() -> int:
    root = Path(__file__).resolve().parents[3]  # .../cdp-article
    csv_path = root / "content" / "assets" / "scripts" / "results.csv"
    if not csv_path.is_file():
        print(f"Missing {csv_path}", file=sys.stderr)
        return 1

    by_q: dict[str, dict[str, list[float]]] = {}
    with csv_path.open(newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            q, eng = row["Query"], row["Engine"]
            by_q.setdefault(q, {})[eng] = ten_values(row)

    queries = sorted(by_q.keys(), key=lambda x: int(x[1:]))
    diffs: list[float] = []
    max_table_delta = 0.0

    print("Per-query: CSV mean vs table; |Hive_err| |Spark_err| (should be ~0)")
    for q in queries:
        m_h = mean(by_q[q]["Hive"])
        m_s = mean(by_q[q]["Spark"])
        diffs.append(m_h - m_s)
        th, ts = TABLE_PAPER[q]
        dh = abs(m_h - th)
        ds = abs(m_s - ts)
        max_table_delta = max(max_table_delta, dh, ds)
        print(f"  {q}: Hive {m_h:.2f} vs {th} (Δ{dh:.3f}), Spark {m_s:.2f} vs {ts} (Δ{ds:.3f})")

    mean_margin = mean(diffs)
    print()
    print(f"Mean of per-query (Hive − Spark) margins: {mean_margin:.2f} s  →  prose: ~{round(mean_margin)} s")
    print(f"Min / max margin: {min(diffs):.2f} s / {max(diffs):.2f} s  →  rounded: {round(min(diffs))} / {round(max(diffs))}")
    print()
    print("Group averages (Hive mean, Spark mean, ratio):")
    for name, qs in GROUPS:
        mh = mean(mean(by_q[q]["Hive"]) for q in qs)
        ms = mean(mean(by_q[q]["Spark"]) for q in qs)
        print(f"  {name}: Hive {mh:.2f} s, Spark {ms:.2f} s, {mh / ms:.2f}×")

    print()
    if max_table_delta > 0.06:
        print(f"WARNING: table vs CSV mean mismatch up to {max_table_delta:.3f} s", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
