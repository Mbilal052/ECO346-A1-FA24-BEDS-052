#!/usr/bin/env python3
"""Question 5: recompute the Q3 band table and redraw the Q3 figure in Python."""

from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.ticker import FuncFormatter

ROOT = Path(__file__).resolve().parents[1]

person = pd.read_csv(ROOT / "data" / "pslm_person_subset.csv")
hh = pd.read_csv(
    ROOT / "data" / "pslm_hh_subset.csv",
    usecols=["hhid", "hhweight", "prov_code", "urban_rural"],
)

d = person.merge(hh, on="hhid", how="left", validate="many_to_one")
d = d[(d["prov_code"] == 1) & (d["urban_rural"] == 1)].copy()

literacy = d[d["literate"].notna() & d["age"].between(10, 64)].copy()
literacy["band"] = (10 + 5 * ((literacy["age"] - 10) // 5)).astype(int)
literacy["mid"] = literacy["band"] + 2
literacy["one"] = 1
literacy["wx"] = literacy["hhweight"] * literacy["literate"]

agg = (
    literacy.groupby(["band", "sex"], as_index=False)
    .agg(n=("one", "sum"), w=("hhweight", "sum"), wx=("wx", "sum"))
)
agg["rate"] = 100 * agg["wx"] / agg["w"]
agg["mid"] = agg["band"] + 2
agg["thin"] = agg["n"] < 30
agg["label"] = np.where(agg["sex"] == 1, "Men", "Women")

wide = agg.pivot(index="band", columns="sex", values="rate")
gap = wide[1] - wide[2]
band_max = int(gap.abs().idxmax())
gap_max = float(abs(gap.loc[band_max]))

fig, ax = plt.subplots(figsize=(10, 6.5))
colors = {2: "#D55E00", 1: "#0072B2"}

for sex, label in [(2, "Women"), (1, "Men")]:
    z = agg[agg["sex"] == sex].sort_values("band")
    color = colors[sex]
    ax.plot(z["mid"], z["rate"], color=color, linewidth=1.4, zorder=1)
    thin = z["thin"].to_numpy()
    ax.scatter(
        z["mid"][~thin], z["rate"][~thin], s=58,
        facecolor=color, edgecolor=color, linewidths=0.9, zorder=2,
    )
    if thin.any():
        ax.scatter(
            z["mid"][thin], z["rate"][thin], s=58,
            facecolor="white", edgecolor=color, linewidths=1.1, zorder=3,
        )
    ax.text(
        z["mid"].iloc[-1] + 1.3, z["rate"].iloc[-1], label,
        color=color, fontweight="bold", fontsize=11,
        va="center", ha="left",
    )

mid_max = band_max + 2
f_rate = float(wide.loc[band_max, 2])
m_rate = float(wide.loc[band_max, 1])
ax.annotate(
    "", xy=(mid_max + 0.15, m_rate), xytext=(mid_max + 0.15, f_rate),
    arrowprops=dict(arrowstyle="<->", color="0.25", linewidth=0.9),
)
ax.text(
    mid_max + 0.9, (f_rate + m_rate) / 2,
    f"Largest gap:\nages {band_max}-{band_max + 4}\n({gap_max:.1f} pp)",
    ha="left", va="center", fontsize=9.5, style="italic", color="0.15",
)

ax.set_xlim(9, 68)
ax.set_ylim(0, 100)
ax.set_xticks(np.arange(12, 63, 5))
ax.set_xticklabels([f"{b}-{b + 4}" for b in range(10, 65, 5)])
ax.set_yticks(np.arange(0, 101, 20))
ax.yaxis.set_major_formatter(FuncFormatter(lambda value, _: f"{value:.0f}%"))
ax.set_xlabel("Age band (years)")
ax.set_ylabel("Weighted literacy rate (%)")
ax.set_title(
    "Literacy falls with age, and the gender gap peaks at ages 45-49",
    fontweight="bold", fontsize=13,
)
ax.grid(axis="both", color="0.90", linewidth=0.7)
ax.set_axisbelow(True)
for side in ["top", "right"]:
    ax.spines[side].set_visible(False)
ax.spines["left"].set_color("0.7")
ax.spines["bottom"].set_color("0.7")

caption = (
    "Source: PSLM 2019-20 person and household files. "
    "Sample: persons aged 10-64 with non-missing literacy in KP rural (variant 4). "
    "Weighted by hhweight. Hollow markers would mark an age-sex cell with fewer "
    "than 30 unweighted persons; every cell here has at least 30."
)
fig.text(0.01, 0.01, caption, ha="left", va="bottom", fontsize=8.3,
         color="0.35", wrap=True)
fig.tight_layout(rect=[0, 0.055, 1, 1])

out = ROOT / "figures" / "literacy_python.svg"
fig.savefig(out, format="svg", facecolor="white", bbox_inches="tight")
plt.close(fig)

ordered = agg.sort_values(["band", "sex"])
print("Variant 4: Khyber Pakhtunkhwa, rural")
print(f"Literacy sample: {len(literacy)} persons\n")
print(f"{'band':<7} {'sex':<6} {'N':>8} {'weighted%':>10}")
for _, row in ordered.iterrows():
    print(
        f"{int(row['band'])}-{int(row['band']) + 4:<4} "
        f"{row['label']:<6} {int(row['n']):>8d} {row['rate']:>10.1f}"
    )

print()
print(f"Women 15-19: {float(wide.loc[15, 2]):.1f}")
print(f"Men 15-19: {float(wide.loc[15, 1]):.1f}")
print(f"Women 55-59: {float(wide.loc[55, 2]):.1f}")
print(f"Men 55-59: {float(wide.loc[55, 1]):.1f}")
print(f"Largest gap: ages {band_max}-{band_max + 4} = {gap_max:.1f} pp")
print(f"Thin cells: {int(agg['thin'].sum())}")
print(f"Figure saved: {out}")
