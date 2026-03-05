

###### (Automatically generated documentation)

# Configure Custom Interior Surface Convection

## Description
Sets inside-face convection for selected surfaces using h = C · |ΔT|^n, with a second (reduced) coefficient and exponent for horizontal surfaces. Walls always use the baseline C,n. Floors/Ceilings switch between baseline vs reduced by the sign of ΔT. Recommended starting points (TARP-inspired): Walls C≈1.31, Horizontal enhanced C≈1.52, Horizontal reduced C≈0.76, n≈1/3.

## Modeler Description
For selected opaque surfaces (interior+exterior), this attaches SurfaceProperty:ConvectionCoefficients on the INSIDE face and drives them via EMS. Law: h = C · |(T_si - T_air)|^n. Walls always use (C_base, n_base). Floors use (C_base, n_base) when RAW_DT>0 (surface warmer than air), else (C_red, n_red). Ceilings use (C_base, n_base) when RAW_DT<0 (surface cooler than air), else (C_red, n_red). Suggested seeds: Walls C≈1.31, Horizontal enhanced C≈1.52, Horizontal reduced C≈0.76, with n≈1/3. Choose C_base according to the surface category you're targeting.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Target Surface Category

**Name:** target_surface_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["Walls", "Floors", "Ceilings", "InternalMass"]


### Baseline Coefficient C_base (W/m2-K / K^n_base)
Walls use this. Floors/Ceilings use this in the “enhanced” branch.
**Name:** coeff_base,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Reduced Coefficient for Horizontal C_red (W/m2-K / K^n_red)
Used only by Floors/Ceilings in the “reduced” branch.
**Name:** coeff_reduced,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Exponent n_base

**Name:** power_base,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Exponent n_red (reduced branch)

**Name:** power_reduced,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Update Inside Coefficient if SPCC Already Exists?

**Name:** overwrite_existing,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Report H_OUT, RAW_DT, and DT?

**Name:** report_hconv,
**Type:** Boolean,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Internal Mass: Use Enhanced/Reduced Branch (like Floors/Ceilings)?
If true, internal mass uses enhanced vs reduced convection based on temperature direction (like floors/ceilings). If false, it uses the fixed (walls) branch.
**Name:** internal_mass_enhanced_branch,
**Type:** Boolean,
**Units:** ,
**Required:** false,
**Model Dependent:** false






