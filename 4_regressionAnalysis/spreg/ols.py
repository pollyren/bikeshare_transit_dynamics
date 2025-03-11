import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.preprocessing import StandardScaler
from spreg import OLS
from statsmodels.stats.outliers_influence import variance_inflation_factor

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


def run_spatial_ols(df: pd.DataFrame, df_name, outfile, ax_mi, ax_ms):
    X = df.select_dtypes(include=['number']).dropna()

    mi_y = X["mi_count"] * 100 / X["num_trips"]
    ms_y = X["ms_count"] * 100 / X["num_trips"]

    scaler_y = StandardScaler()
    mi_y_std = scaler_y.fit_transform(mi_y.values.reshape(-1, 1)).flatten()
    ms_y_std = scaler_y.fit_transform(ms_y.values.reshape(-1, 1)).flatten()

    X_filtered = X[["median_household_income", "avg_traffic", "households_with_children", "prop_commute_walked",
                    "intersection_density", "num_streets", "housing_units", "num_jobs", "dock_count", "stop_count"]]

    scaler = StandardScaler()
    X_std = pd.DataFrame(scaler.fit_transform(X_filtered), columns=X_filtered.columns, index=X_filtered.index)
    X_std.insert(0, "Intercept", 1)

    # convert to numpy arrays for spreg
    y_mi = mi_y_std.reshape(-1, 1)
    y_ms = ms_y_std.reshape(-1, 1)
    X_np = X_std.to_numpy()

    # run spreg.OLS
    mi_model = OLS(y_mi, X_np, name_y="mi_prop", name_x=X_std.columns.tolist())
    ms_model = OLS(y_ms, X_np, name_y="ms_prop", name_x=X_std.columns.tolist())

    mi_coefs = pd.DataFrame({
        "Feature": X_std.columns,
        "Coefficient": mi_model.betas.flatten(),
        "Lower": mi_model.vm.diagonal() ** 0.5 * -1.96 + mi_model.betas.flatten(),
        "Upper": mi_model.vm.diagonal() ** 0.5 * 1.96 + mi_model.betas.flatten()
    })

    ms_coefs = pd.DataFrame({
        "Feature": X_std.columns,
        "Coefficient": ms_model.betas.flatten(),
        "Lower": ms_model.vm.diagonal() ** 0.5 * -1.96 + ms_model.betas.flatten(),
        "Upper": ms_model.vm.diagonal() ** 0.5 * 1.96 + ms_model.betas.flatten()
    })

    with open(outfile, "a") as f:
        f.write(f"\nmodal integration, {df_name}:\n")
        f.write(str(mi_model.summary))

        f.write(f"\n\n\nmodal substitution, {df_name}:\n")
        f.write(str(ms_model.summary))

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
        dfs[df_name] = pd.read_csv(f"../../data/final/{df_name}.csv", header=0, index_col=0)
        dfs[df_name]["mi_count"] = dfs[df_name][["mi_flm_count", "mi_fm_count", "mi_lm_count"]].sum(axis=1)
        dfs[df_name]["num_trips"] = dfs[df_name][["mi_count", "ms_count", "none_count"]].sum(axis=1)

    with open("output/spreg_ols_results_start.txt", "w"):
        pass
    with open("output/spreg_ols_results_end.txt", "w"):
        pass

    num_rows_start = len(df_start_names)
    fig_start, axes_start = plt.subplots(num_rows_start, 2, figsize=(10, 5 * num_rows_start))
    fig_start.suptitle("spreg OLS regression coefficients, trip origin", fontsize=16, y=0.99)
    axes_start = axes_start.flatten()

    for i, df_name in enumerate(df_start_names):
        run_spatial_ols(dfs[df_name], df_name, "output/spreg_ols_results_start.txt", axes_start[i * 2], axes_start[i * 2 + 1])

    plt.tight_layout()
    plt.savefig("output/spreg_ols_coefs_start.png", bbox_inches="tight")

    num_rows_end = len(df_end_names)
    fig_end, axes_end = plt.subplots(num_rows_end, 2, figsize=(10, 5 * num_rows_end))
    fig_end.suptitle("spreg OLS regression coefficients, trip destination", fontsize=16, y=0.99)
    axes_end = axes_end.flatten()

    for i, df_name in enumerate(df_end_names):
        run_spatial_ols(dfs[df_name], df_name, "output/spreg_ols_results_end.txt", axes_end[i * 2], axes_end[i * 2 + 1])

    plt.tight_layout()
    plt.savefig("output/spreg_ols_coefs_end.png", bbox_inches="tight")

if __name__ == "__main__":
    main()
