import pandas as pd
import matplotlib.pyplot as plt
import sys
import os
import scipy

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from constants import MODAL_COLOURS

COL_NAME_TO_NAME = {
    "mi_flm_count": "MI-FLM",
    "mi_fm_count": "MI-FM",
    "mi_lm_count": "MI-LM",
    "ms_count": "MS",
    "none_count": "none"
}

def main():
    df_start_names = {
        "divvy_start": "Chicago",
        "citi_start": "New York City",
        "metro_start": "Los Angeles"
    }
    df_end_names = ["divvy_end", "citi_end", "metro_end"]

    count_data = {}

    dfs = {}
    for df_name in list(df_start_names.keys()) + df_end_names:
        dfs[df_name] = pd.read_csv(f"../data/final/{df_name}.csv", header=0, index_col=0)

    with open("output/variable_stats.csv", "w"):
        pass # clear contents of the file, ensures idempotency

    for df_name in list(df_start_names.keys()) + df_end_names:
        df = dfs[df_name]
        stats = df.agg(['sum', 'mean', 'std', 'median', 'max', 'min'])

        with open("output/variable_stats.csv", "a") as f:
            f.write(f"\n{df_name}\n")
            stats.to_csv(f)
            f.write("\n-----\n")

        if "start" in df_name:
            city = df_start_names[df_name]
            counts = stats.loc["sum", ["mi_flm_count", "mi_fm_count", "mi_lm_count", "ms_count", "none_count"]]
            count_data[city] = (counts / counts.sum()) * 100

    count_df = pd.DataFrame(count_data)
    count_df.index = [COL_NAME_TO_NAME[col] for col in count_df.index]
    ax = count_df.T.plot(kind="bar", stacked=True, figsize=(8, 6),
                         color=[MODAL_COLOURS[col] for col in count_df.index])

    plt.title("Proportion of MI and MS trips across cities")
    plt.ylabel("Percentage (%)")
    plt.xlabel("City")
    plt.xticks(rotation=0)
    plt.legend(title="Classification", bbox_to_anchor=(1.05, 1), loc='upper left')
    plt.ylim(0, 100)
    plt.tight_layout()

    for bar in ax.containers:
        ax.bar_label(bar, fmt='%.1f%%', label_type='center', fontsize=10, color='white')

    plt.savefig("output/total_counts.png")

if __name__ == "__main__":
    main()