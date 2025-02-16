import pandas as pd

def main():
    df_start_names = ["divvy_start", "citi_start", "metro_start"]
    df_end_names = ["divvy_end", "citi_end", "metro_end"]

    dfs = {}
    for df_name in df_start_names + df_end_names:
        dfs[df_name] = pd.read_csv(f"../data/final/{df_name}.csv", header=0, index_col=0)

    with open("output/variable_stats.csv", "w"):
        pass # clear contents of the file, ensures idempotency

    for df_name in df_start_names + df_end_names:
        df = dfs[df_name]
        stats = df.agg(['mean', 'median', 'max', 'min'])

        with open("output/variable_stats.csv", "a") as f:
            f.write(f"\n{df_name}\n")
            stats.to_csv(f)
            f.write("\n-----\n")

if __name__ == "__main__":
    main()