#!/usr/bin/env python3
"""
Derive paper-facing percentages from content/assets/data/ssb_mean_times.json.

Workflow (keep table §4 and JSON in sync):
  1. Edit mean times in 04-Performance-Evaluation.tex table when needed.
  2. Mirror the same means in ssb_mean_times.json.
  3. Run this script with --write-macros and --check-consistency.

Conventions:
  - Hive→Spark reduction per query: (H - S) / H * 100. Abstract range = min/max
    over the 13 queries (rounded to nearest integer).
  - Aggregate Hive→Spark reduction: (mean(H) - mean(S)) / mean(H) * 100.
  - Cache vs Spark (penalty): (C - S) / S * 100 when C > S; (improvement) (S - C) / S * 100 when C < S.
  - Mean global cache penalty vs Spark: (mean(C) - mean(S)) / mean(S) * 100.

Rounding for LaTeX macros: integer percents via round(); mean global cache uses one decimal.

Experimental section (§4) macros: group mean times in seconds (\\PaperExpHSG*Mean*)
and comparative reductions (\\PaperExpHSG*RedPct, cache overhead/gain percentages)
are derived from the same JSON rows as the results table.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
DEFAULT_DATA = REPO_ROOT / "content" / "assets" / "data" / "ssb_mean_times.json"
DEFAULT_MACROS = REPO_ROOT / "content" / "assets" / "generated" / "benchmark_macros.tex"

# Expected abstract bounds (from current SSB table); --check-consistency asserts these.
EXPECTED_HS_RED_PCT_MIN = 52
EXPECTED_HS_RED_PCT_MAX = 86


def load_rows(path: Path) -> tuple[list[dict], dict[str, list[str]], dict[str, list[str]]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    rows = data["queries"]
    subsets = data.get("subsets", {})
    groups = data.get("groups", {})
    if len(rows) != 13:
        raise ValueError(f"expected 13 queries, got {len(rows)}")
    for r in rows:
        for k in ("hive", "spark", "spark_cache"):
            v = r[k]
            if not isinstance(v, (int, float)) or v <= 0:
                raise ValueError(f"{r['id']}: invalid {k}={v}")
    return rows, subsets, groups


def row_by_id(rows: list[dict]) -> dict[str, dict]:
    return {r["id"]: r for r in rows}


def hive_spark_reduction_pct(h: float, s: float) -> float:
    return (h - s) / h * 100.0


def cache_penalty_pct(s: float, c: float) -> float:
    """Positive when cache is slower than uncached Spark."""
    return (c - s) / s * 100.0


def cache_improvement_pct(s: float, c: float) -> float:
    """Positive when cache is faster than uncached Spark."""
    return (s - c) / s * 100.0


def _group_hs_reduction(by_id: dict[str, dict], ids: list[str]) -> tuple[float, float, float]:
    """Return (mean_hive, mean_spark, reduction_pct)."""
    rs = [by_id[i] for i in ids]
    mean_h = sum(r["hive"] for r in rs) / len(rs)
    mean_s = sum(r["spark"] for r in rs) / len(rs)
    pct = hive_spark_reduction_pct(mean_h, mean_s)
    return mean_h, mean_s, pct


def _subset_cache_penalty_range(by_id: dict[str, dict], ids: list[str]) -> tuple[float, float]:
    pcts = [cache_penalty_pct(by_id[i]["spark"], by_id[i]["spark_cache"]) for i in ids]
    return min(pcts), max(pcts)


def compute_metrics(
    rows: list[dict], subsets: dict[str, list[str]], groups: dict[str, list[str]]
) -> dict:
    by_id = row_by_id(rows)
    hs_pcts = [hive_spark_reduction_pct(r["hive"], r["spark"]) for r in rows]
    mean_h = sum(r["hive"] for r in rows) / len(rows)
    mean_s = sum(r["spark"] for r in rows) / len(rows)
    mean_c = sum(r["spark_cache"] for r in rows) / len(rows)
    mean_agg = (mean_h - mean_s) / mean_h * 100.0
    mean_cache_penalty = (mean_c - mean_s) / mean_s * 100.0

    overhead_ids = subsets.get("cache_overhead_narrative", [])
    benefit_ids = subsets.get("cache_benefit_narrative", [])
    overhead_pcts: list[float] = []
    for qid in overhead_ids:
        r = by_id[qid]
        overhead_pcts.append(cache_penalty_pct(r["spark"], r["spark_cache"]))

    benefit_improvements: list[float] = []
    for qid in benefit_ids:
        r = by_id[qid]
        if r["spark_cache"] < r["spark"]:
            benefit_improvements.append(cache_improvement_pct(r["spark"], r["spark_cache"]))

    q32 = by_id["Q3.2"]
    q32_improve = cache_improvement_pct(q32["spark"], q32["spark_cache"])

    g1_ids = groups.get("hive_spark_q1", ["Q1.1", "Q1.2", "Q1.3"])
    g2_ids = groups.get("hive_spark_q2", ["Q2.1", "Q2.2", "Q2.3"])
    g3_ids = groups.get("hive_spark_q3", ["Q3.1", "Q3.2", "Q3.3", "Q3.4"])
    g4_ids = groups.get("hive_spark_q4", ["Q4.1", "Q4.2", "Q4.3"])
    mh1, ms1, p1 = _group_hs_reduction(by_id, g1_ids)
    mh2, ms2, p2 = _group_hs_reduction(by_id, g2_ids)
    mh3, ms3, p3 = _group_hs_reduction(by_id, g3_ids)
    mh4, ms4, p4 = _group_hs_reduction(by_id, g4_ids)

    q1o = subsets.get("cache_overhead_q1", ["Q1.1", "Q1.2", "Q1.3"])
    q2o = subsets.get("cache_overhead_q2", ["Q2.1", "Q2.2", "Q2.3"])
    q1_pen_min, q1_pen_max = _subset_cache_penalty_range(by_id, q1o)
    q2_pen_min, q2_pen_max = _subset_cache_penalty_range(by_id, q2o)
    q33_pen = cache_penalty_pct(by_id["Q3.3"]["spark"], by_id["Q3.3"]["spark_cache"])
    q31_gain = cache_improvement_pct(by_id["Q3.1"]["spark"], by_id["Q3.1"]["spark_cache"])
    q34_q43_ids = ["Q3.4", "Q4.1", "Q4.2", "Q4.3"]
    gains_34 = [
        cache_improvement_pct(by_id[i]["spark"], by_id[i]["spark_cache"]) for i in q34_q43_ids
    ]
    q34_gain_min, q34_gain_max = min(gains_34), max(gains_34)

    return {
        "hs_red_pct_min": min(hs_pcts),
        "hs_red_pct_max": max(hs_pcts),
        "hs_red_pct_mean_agg": mean_agg,
        "mean_cache_penalty_pct": mean_cache_penalty,
        "overhead_narrative_min": min(overhead_pcts) if overhead_pcts else float("nan"),
        "overhead_narrative_max": max(overhead_pcts) if overhead_pcts else float("nan"),
        "benefit_narrative_max_improve": max(benefit_improvements) if benefit_improvements else float("nan"),
        "q32_cache_improve_pct": q32_improve,
        "mean_hive": mean_h,
        "mean_spark": mean_s,
        "mean_cache": mean_c,
        "exp_hs_g1_mean_h": mh1,
        "exp_hs_g1_mean_s": ms1,
        "exp_hs_g1_red_pct": p1,
        "exp_hs_g2_mean_h": mh2,
        "exp_hs_g2_mean_s": ms2,
        "exp_hs_g2_red_pct": p2,
        "exp_hs_g3_mean_h": mh3,
        "exp_hs_g3_mean_s": ms3,
        "exp_hs_g3_red_pct": p3,
        "exp_hs_g4_mean_h": mh4,
        "exp_hs_g4_mean_s": ms4,
        "exp_hs_g4_red_pct": p4,
        "exp_cache_q1_pen_min": q1_pen_min,
        "exp_cache_q1_pen_max": q1_pen_max,
        "exp_cache_q2_pen_min": q2_pen_min,
        "exp_cache_q2_pen_max": q2_pen_max,
        "exp_cache_q33_pen_pct": q33_pen,
        "exp_q31_cache_gain_pct": q31_gain,
        "exp_cache_q34_q43_gain_min": q34_gain_min,
        "exp_cache_q34_q43_gain_max": q34_gain_max,
    }


def _fmt_thousands(x: float) -> str:
    """Integer part with TeX thousands separator {,}."""
    n = int(round(x))
    s = f"{n:,}"
    return s.replace(",", r"{,}")


def format_macros(m: dict) -> str:
    hs_min_i = int(round(m["hs_red_pct_min"]))
    hs_max_i = int(round(m["hs_red_pct_max"]))
    hs_mean_i = int(round(m["hs_red_pct_mean_agg"]))
    oh_min_i = int(round(m["overhead_narrative_min"]))
    oh_max_i = int(round(m["overhead_narrative_max"]))
    q32_i = int(round(m["q32_cache_improve_pct"]))
    cache_mean_1 = round(m["mean_cache_penalty_pct"], 1)

    g1h = _fmt_thousands(m["exp_hs_g1_mean_h"])
    g1s = _fmt_thousands(m["exp_hs_g1_mean_s"])
    g2h = _fmt_thousands(m["exp_hs_g2_mean_h"])
    g2s = _fmt_thousands(m["exp_hs_g2_mean_s"])
    g3h = _fmt_thousands(m["exp_hs_g3_mean_h"])
    g3s = _fmt_thousands(m["exp_hs_g3_mean_s"])
    g4h = _fmt_thousands(m["exp_hs_g4_mean_h"])
    g4s = _fmt_thousands(m["exp_hs_g4_mean_s"])

    lines = [
        "% Auto-generated by content/assets/scripts/compute_paper_metrics.py",
        "% Source: content/assets/data/ssb_mean_times.json (keep in sync with §4 table).",
        r"\providecommand{\PaperHSRedPctMin}{" + str(hs_min_i) + "}",
        r"\providecommand{\PaperHSRedPctMax}{" + str(hs_max_i) + "}",
        r"\providecommand{\PaperHSRedPctMeanAgg}{" + str(hs_mean_i) + "}",
        r"\providecommand{\PaperCacheVsSparkMeanPenaltyPct}{" + str(cache_mean_1) + "}",
        r"\providecommand{\PaperCacheOverheadNarrativeMinPct}{" + str(oh_min_i) + "}",
        r"\providecommand{\PaperCacheOverheadNarrativeMaxPct}{" + str(oh_max_i) + "}",
        r"\providecommand{\PaperQThreeTwoCacheImprovementPct}{" + str(q32_i) + "}",
        r"\providecommand{\PaperExpHSGOneMeanHive}{" + g1h + "}",
        r"\providecommand{\PaperExpHSGOneMeanSpark}{" + g1s + "}",
        r"\providecommand{\PaperExpHSGOneRedPct}{" + str(int(round(m["exp_hs_g1_red_pct"]))) + "}",
        r"\providecommand{\PaperExpHSGTwoMeanHive}{" + g2h + "}",
        r"\providecommand{\PaperExpHSGTwoMeanSpark}{" + g2s + "}",
        r"\providecommand{\PaperExpHSGTwoRedPct}{" + str(int(round(m["exp_hs_g2_red_pct"]))) + "}",
        r"\providecommand{\PaperExpHSGThreeMeanHive}{" + g3h + "}",
        r"\providecommand{\PaperExpHSGThreeMeanSpark}{" + g3s + "}",
        r"\providecommand{\PaperExpHSGThreeRedPct}{" + str(int(round(m["exp_hs_g3_red_pct"]))) + "}",
        r"\providecommand{\PaperExpHSGFourMeanHive}{" + g4h + "}",
        r"\providecommand{\PaperExpHSGFourMeanSpark}{" + g4s + "}",
        r"\providecommand{\PaperExpHSGFourRedPct}{" + str(int(round(m["exp_hs_g4_red_pct"]))) + "}",
        r"\providecommand{\PaperExpCacheQOneOverMinPct}{" + str(int(round(m["exp_cache_q1_pen_min"]))) + "}",
        r"\providecommand{\PaperExpCacheQOneOverMaxPct}{" + str(int(round(m["exp_cache_q1_pen_max"]))) + "}",
        r"\providecommand{\PaperExpCacheQTwoOverMinPct}{" + str(int(round(m["exp_cache_q2_pen_min"]))) + "}",
        r"\providecommand{\PaperExpCacheQTwoOverMaxPct}{" + str(int(round(m["exp_cache_q2_pen_max"]))) + "}",
        r"\providecommand{\PaperExpCacheQThreeThreeOverPct}{" + str(int(round(m["exp_cache_q33_pen_pct"]))) + "}",
        r"\providecommand{\PaperExpQThreeOneCacheGainPct}{" + str(int(round(m["exp_q31_cache_gain_pct"]))) + "}",
        r"\providecommand{\PaperExpCacheQThreeFourQFourThreeGainMinPct}{"
        + str(int(round(m["exp_cache_q34_q43_gain_min"])))
        + "}",
        r"\providecommand{\PaperExpCacheQThreeFourQFourThreeGainMaxPct}{"
        + str(int(round(m["exp_cache_q34_q43_gain_max"])))
        + "}",
    ]
    return "\n".join(lines) + "\n"


def check_consistency(m: dict) -> list[str]:
    errs: list[str] = []
    if int(round(m["hs_red_pct_min"])) != EXPECTED_HS_RED_PCT_MIN:
        errs.append(
            f"Hive→Spark min reduction rounds to {int(round(m['hs_red_pct_min']))}, "
            f"expected {EXPECTED_HS_RED_PCT_MIN} (update JSON or abstract expectations in script)."
        )
    if int(round(m["hs_red_pct_max"])) != EXPECTED_HS_RED_PCT_MAX:
        errs.append(
            f"Hive→Spark max reduction rounds to {int(round(m['hs_red_pct_max']))}, "
            f"expected {EXPECTED_HS_RED_PCT_MAX}."
        )
    return errs


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--data", type=Path, default=DEFAULT_DATA, help="Path to ssb_mean_times.json")
    ap.add_argument("--write-macros", type=Path, metavar="OUT.tex", help="Write LaTeX \\providecommand macros")
    ap.add_argument("--check-consistency", action="store_true", help="Fail if abstract-scale min/max do not match")
    ap.add_argument("--print-report", action="store_true", help="Print human-readable metrics to stdout")
    args = ap.parse_args()

    rows, subsets, groups = load_rows(args.data)
    m = compute_metrics(rows, subsets, groups)

    if args.print_report:
        print("Hive→Spark reduction (% per query): min=", m["hs_red_pct_min"], " max=", m["hs_red_pct_max"])
        print("Hive→Spark aggregate over means (%):", m["hs_red_pct_mean_agg"])
        print("Mean cache vs Spark (% slower, ratio of means):", m["mean_cache_penalty_pct"])
        print("Narrative overhead subset (% vs Spark):", m["overhead_narrative_min"], "–", m["overhead_narrative_max"])
        print("Q3.2 cache improvement (% vs Spark):", m["q32_cache_improve_pct"])
        print("Benefit subset max improvement (%):", m["benefit_narrative_max_improve"])

    if args.check_consistency:
        errs = check_consistency(m)
        for e in errs:
            print(e, file=sys.stderr)
        if errs:
            return 1

    if args.write_macros:
        args.write_macros.parent.mkdir(parents=True, exist_ok=True)
        args.write_macros.write_text(format_macros(m), encoding="utf-8")
        print(f"Wrote {args.write_macros}", file=sys.stderr)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
