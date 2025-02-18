import pandas as pd
import statsmodels.api as sm
from statsmodels.stats.outliers_influence import variance_inflation_factor
import seaborn as sns
import matplotlib.pyplot as plt

VIF_THRESHOLD = 10

def calculate_vif(df: pd.DataFrame):
    vif_data = pd.DataFrame({
        "Variable": df.columns,
        "VIF": [variance_inflation_factor(df.values, i) for i in range(df.shape[1])]
    })
    return vif_data


def remove_collinear_variables(df: pd.DataFrame):
    while True:
        vif_data = calculate_vif(df)
        max_vif = vif_data["VIF"].max()

        if max_vif < VIF_THRESHOLD:
            break

        var = vif_data.loc[vif_data["VIF"].idxmax(), "Variable"]
        df = df.drop(columns=[var])
        print(f"dropping {var} because it has VIF={max_vif} > 10")

    return df


def run_ols(df: pd.DataFrame, df_name, outfile, ax_mi, ax_ms):
    df_numeric = df.select_dtypes(include=['number']).dropna()

    mi_y = df_numeric["mi_count"] / df_numeric["num_trips"]
    ms_y = df_numeric["ms_count"] / df_numeric["num_trips"]

    X = df_numeric.iloc[:, 5:-2]  # independent variable starts at median_age col
    # X = sm.add_constant(X)

    # X_filtered = X[["median_age", "median_household_income", "intersection_density", "avg_traffic", "num_jobs"]]
    X_filtered = X.drop(columns=["prop_commute_drove", "prop_commute_carpooled", "prop_commute_pubtransit", "prop_commute_walked", "mean_commute_time", "avg_vehicle_miles"])
    X_filtered = remove_collinear_variables(X_filtered)

    mi_model = sm.OLS(mi_y, X_filtered).fit()
    ms_model = sm.OLS(ms_y, X_filtered).fit()

    mi_coefs = pd.DataFrame({
        "Feature": X_filtered.columns,
        "Coefficient": mi_model.params,
        "Lower": mi_model.conf_int()[0],
        "Upper": mi_model.conf_int()[1]
    })

    ms_coefs = pd.DataFrame({
        "Feature": X_filtered.columns,
        "Coefficient": ms_model.params,
        "Lower": ms_model.conf_int()[0],
        "Upper": ms_model.conf_int()[1]
    })

    with open(outfile, "a") as f:
        f.write(f"\nmodal integration, {df_name}:\n")
        f.write(mi_model.summary().as_text())

        f.write(f"\n\n\nmodal substitution, {df_name}:\n")
        f.write(ms_model.summary().as_text())

        vif_final = calculate_vif(X_filtered)
        f.write("\nvif:\n")
        f.write(vif_final.to_string(index=False))
        f.write("\n-----\n")

    ax_mi.errorbar(mi_coefs["Coefficient"], mi_coefs["Feature"],
                   xerr=[mi_coefs["Coefficient"] - mi_coefs["Lower"], mi_coefs["Upper"] - mi_coefs["Coefficient"]],
                   fmt="o", capsize=5)
    ax_mi.axvline(0, linestyle="--", color="black", linewidth=1)
    ax_mi.set_title(f"{df_name} (MI)")
    ax_mi.set_xlabel("coefficient")
    ax_mi.set_ylabel("feature")

    ax_ms.errorbar(ms_coefs["Coefficient"], ms_coefs["Feature"],
                   xerr=[ms_coefs["Coefficient"] - ms_coefs["Lower"], ms_coefs["Upper"] - ms_coefs["Coefficient"]],
                   fmt="o", capsize=5)
    ax_ms.axvline(0, linestyle="--", color="black", linewidth=1)
    ax_ms.set_title(f"{df_name} (MS)")
    ax_ms.set_xlabel("coefficient")
    ax_ms.set_ylabel("feature")

def main():
    df_start_names = ["divvy_start", "citi_start", "metro_start"]
    df_end_names = ["divvy_end", "citi_end", "metro_end"]

    dfs = {}
    for df_name in df_start_names + df_end_names:
        dfs[df_name] = pd.read_csv(f"../data/final/{df_name}.csv", header=0, index_col=0)
        dfs[df_name]["mi_count"] = dfs[df_name][["mi_flm_count", "mi_fm_count", "mi_lm_count"]].sum(axis=1)
        dfs[df_name]["num_trips"] = dfs[df_name][["mi_count", "ms_count", "none_count"]].sum(axis=1)

        # corr_matrix = dfs[df_name].iloc[:, 5:-2].corr()
        # plt.figure(figsize=(8, 6))
        # sns.heatmap(corr_matrix, cmap="coolwarm", linewidths=0.5)
        # plt.savefig(f"output/{df_name}_correlation.png", bbox_inches="tight")

    with open("output/ols_results_start.txt", "w"):
        pass
    with open("output/ols_results_end.txt", "w"):
        pass

    num_rows_start = len(df_start_names)
    fig_start, axes_start = plt.subplots(num_rows_start, 2, figsize=(10, 5 * num_rows_start))
    fig_start.suptitle("OLS regression coefficients, trip origin", fontsize=16, y=0.99)
    axes_start = axes_start.flatten()

    for i, df_name in enumerate(df_start_names):
        run_ols(dfs[df_name], df_name, "output/ols_results_start.txt", axes_start[i * 2], axes_start[i * 2 + 1])

    plt.tight_layout()
    plt.savefig("output/ols_coefs_start.png", bbox_inches="tight")

    num_rows_end = len(df_end_names)
    fig_end, axes_end = plt.subplots(num_rows_end, 2, figsize=(10, 5 * num_rows_end))
    fig_end.suptitle("OLS regression coefficients, trip destination", fontsize=16, y=0.99)
    axes_end = axes_end.flatten()

    for i, df_name in enumerate(df_end_names):
        run_ols(dfs[df_name], df_name, "output/ols_results_end.txt", axes_end[i * 2], axes_end[i * 2 + 1])

    plt.tight_layout()
    plt.savefig("output/ols_coefs_end.png", bbox_inches="tight")

if __name__ == "__main__":
    main()