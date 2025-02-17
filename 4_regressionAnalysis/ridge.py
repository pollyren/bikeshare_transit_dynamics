import pandas as pd
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt
from sklearn.linear_model import RidgeCV
from sklearn.preprocessing import StandardScaler

def run_ridge_regression(df: pd.DataFrame, df_name: str, outfile: str):
    df_numeric = df.select_dtypes(include=['number']).dropna()

    mi_y = df_numeric["mi_count"] / df_numeric["num_trips"]
    ms_y = df_numeric["ms_count"] / df_numeric["num_trips"]

    X = df_numeric.iloc[:, 5:-2]
    X = X[["median_age", "median_household_income", "intersection_density", "avg_traffic", "num_jobs"]]

    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)

    ridge_mi = RidgeCV(alphas=np.logspace(-6, 6, 13), store_cv_results=True)
    ridge_ms = RidgeCV(alphas=np.logspace(-6, 6, 13), store_cv_results=True)

    mi_model = ridge_mi.fit(X_scaled, mi_y)
    ms_model = ridge_ms.fit(X_scaled, ms_y)

    mi_coefs = pd.DataFrame({"Feature": X.columns, "Coefficient": mi_model.coef_})
    ms_coefs = pd.DataFrame({"Feature": X.columns, "Coefficient": ms_model.coef_})

    with open(outfile, "a") as f:
        f.write(f"\nmodal integration, {df_name} (alpha={mi_model.alpha_}):\n")
        f.write(mi_coefs.to_string(index=False))

        f.write(f"\nmodal substitution, {df_name} (alpha={ms_model.alpha_}):\n")
        f.write(ms_coefs.to_string(index=False))
        f.write("\n-----\n")

    plt.figure(figsize=(10, 6))
    sns.barplot(x=mi_coefs["Coefficient"], y=mi_coefs["Feature"])
    plt.title(f"ridge regression coefficients, {df_name} (MI)")
    plt.xlabel("coefficient")
    plt.ylabel("feature")
    plt.tight_layout()
    plt.savefig(f"output/{df_name}_mi_ridge_coefs.png")

    plt.figure(figsize=(10, 6))
    sns.barplot(x=ms_coefs["Coefficient"], y=ms_coefs["Feature"])
    plt.title(f"ridge regression coefficients, {df_name} (MS)")
    plt.xlabel("coefficient")
    plt.ylabel("feature")
    plt.tight_layout()
    plt.savefig(f"output/{df_name}_ms_ridge_coefs.png")


def main():
    df_start_names = ["divvy_start", "citi_start", "metro_start"]
    df_end_names = ["divvy_end", "citi_end", "metro_end"]

    dfs = {}
    for df_name in df_start_names + df_end_names:
        dfs[df_name] = pd.read_csv(f"../data/final/{df_name}.csv", header=0, index_col=0)
        dfs[df_name]["mi_count"] = dfs[df_name][["mi_flm_count", "mi_fm_count", "mi_lm_count"]].sum(axis=1)
        dfs[df_name]["num_trips"] = dfs[df_name][["mi_count", "ms_count", "none_count"]].sum(axis=1)

    with open("output/ridge_results_start.txt", "w"):
        pass
    with open("output/ridge_results_end.txt", "w"):
        pass

    for df_name in df_start_names:
        run_ridge_regression(dfs[df_name], df_name, "output/ridge_results_start.txt")

    for df_name in df_end_names:
        run_ridge_regression(dfs[df_name], df_name, "output/ridge_results_end.txt")

if __name__ == "__main__":
    main()