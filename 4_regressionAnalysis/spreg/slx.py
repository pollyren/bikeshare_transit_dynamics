import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.preprocessing import StandardScaler
from spreg import OLS
import geopandas as gpd
import libpysal
from collections import defaultdict

def create_weights(df, shapefile):
    gdf = gpd.read_file(shapefile)

    gdf["GEOID"] = gdf["GEOID"].astype(str).str.zfill(11)
    df.index = df.index.astype(str).str.zfill(11)
    gdf_subset = gdf[gdf["GEOID"].isin(df.index.astype(str))]
    gdf_subset = gdf_subset.to_crs("EPSG:5070") # use Conus Albers (metres instead of degrees)

    w = libpysal.weights.DistanceBand.from_dataframe(gdf_subset, threshold=1600) # 1 mile threshold
    w.transform = "r" # row standardise

    return w


def run_spatial_ols(df: pd.DataFrame, df_name, weights, outfile, ax_mi, ax_ms):
    spatial = weights is not None

    X = df

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

    orig_features = X_std.columns.tolist()
    slx_features = ["W_" + col for col in orig_features if col != "Intercept"]
    all_features = orig_features + slx_features

    # run spreg.OLS with slx lag
    mi_model = OLS(y_mi, X_np, name_y="mi_prop", name_x=orig_features,
                   w=weights, spat_diag=spatial, moran=spatial, slx_lags=1)
    ms_model = OLS(y_ms, X_np, name_y="ms_prop", name_x=orig_features,
                   w=weights, spat_diag=spatial, moran=spatial, slx_lags=1)

    mi_coefs = pd.DataFrame({
        "Feature": all_features,
        "Coefficient": mi_model.betas.flatten(),
        "Lower": mi_model.vm.diagonal() ** 0.5 * -1.96 + mi_model.betas.flatten(),
        "Upper": mi_model.vm.diagonal() ** 0.5 * 1.96 + mi_model.betas.flatten()
    })

    ms_coefs = pd.DataFrame({
        "Feature": all_features,
        "Coefficient": ms_model.betas.flatten(),
        "Lower": ms_model.vm.diagonal() ** 0.5 * -1.96 + ms_model.betas.flatten(),
        "Upper": ms_model.vm.diagonal() ** 0.5 * 1.96 + ms_model.betas.flatten()
    })

    with open(outfile, "a") as f:
        f.write(f"\nmodal integration, {df_name}:\n")
        f.write(str(mi_model.summary))

        f.write(f"\n\n\nmodal substitution, {df_name}:\n")
        f.write(str(ms_model.summary))

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
    df_start_names = {
        "divvy_start": "../../data/shapefiles/chicago/tl_2023_17_tract.shp",
        "citi_start": "../../data/shapefiles/nyc/tl_2023_36_tract.shp",
        "metro_start": "../../data/shapefiles/la/tl_2023_06_tract.shp"
    }
    df_end_names = {
        "divvy_end": "../../data/shapefiles/chicago/tl_2023_17_tract.shp",
        "citi_end": "../../data/shapefiles/nyc/tl_2023_36_tract.shp",
        "metro_end": "../../data/shapefiles/la/tl_2023_06_tract.shp"
    }

    weights = defaultdict(lambda: None)

    dfs = {}
    for df_name in list(df_start_names.keys()) + list(df_end_names.keys()):
        dfs[df_name] = pd.read_csv(f"../../data/final/{df_name}.csv", header=0, index_col=0)
        dfs[df_name]["mi_count"] = dfs[df_name][["mi_flm_count", "mi_fm_count", "mi_lm_count"]].sum(axis=1)
        dfs[df_name]["num_trips"] = dfs[df_name][["mi_count", "ms_count", "none_count"]].sum(axis=1)
        dfs[df_name] = dfs[df_name].select_dtypes(include=['number']).dropna()

        weights[df_name] = create_weights(dfs[df_name], (df_start_names | df_end_names)[df_name])

    prefix = "spreg_slx"

    with open(f"output/{prefix}_results_start.txt", "w"):
        pass
    with open(f"output/{prefix}_results_end.txt", "w"):
        pass

    num_rows_start = len(df_start_names)
    fig_start, axes_start = plt.subplots(num_rows_start, 2, figsize=(10, 5 * num_rows_start))
    fig_start.suptitle(
        f"spreg OLS regression coefficients (with SLX), trip origin",
        fontsize=16, y=0.99
    )
    axes_start = axes_start.flatten()

    for i, df_name in enumerate(df_start_names):
        run_spatial_ols(dfs[df_name], df_name, weights[df_name],
                        f"output/{prefix}_results_start.txt", axes_start[i * 2], axes_start[i * 2 + 1])

    plt.tight_layout()
    plt.savefig(f"output/{prefix}_coefs_start.png", bbox_inches="tight")

    num_rows_end = len(df_end_names)
    fig_end, axes_end = plt.subplots(num_rows_end, 2, figsize=(10, 5 * num_rows_end))
    fig_end.suptitle(
        f"spreg OLS regression coefficients (with SLX), trip destination",
        fontsize=16, y=0.99
    )
    axes_end = axes_end.flatten()

    for i, df_name in enumerate(df_end_names):
        run_spatial_ols(dfs[df_name], df_name, weights[df_name],
                        f"output/{prefix}_results_end.txt", axes_end[i * 2], axes_end[i * 2 + 1])

    plt.tight_layout()
    plt.savefig(f"output/{prefix}_coefs_end.png", bbox_inches="tight")

if __name__ == "__main__":
    main()
