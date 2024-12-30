

###### (Automatically generated documentation)

# Create and Assign CLT Construction Set

## Description
This measure allows a modeler to change the construction set in their model for a CLT construction set. The measure includes options for CLT exterior walls, CLT interior floors, and roof. It also provides options to infer insulation levels from existing constructions, replace external walls, and specify custom thickness for CLT layers. Additionally, it allows duplicating existing construction sets to preserve originals and includes detailed R-value calculations in construction names.

## Modeler Description
This measure enables the assignment of CLT construction sets to a model. Features include specifying CLT types and plies for inner floors, roofs, and walls, with the option to use custom thicknesses. The measure can infer insulation levels based on existing constructions, splitting required R-values between exterior and interior insulation if specified. It supports duplicating existing construction sets for preservation and ensures that inner floors and ceilings share the same construction. The measure also calculates and includes the effective R-value in the construction names.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Exclude Construction Sets
Comma-separated list of strings to match construction set names against. If a match is found, those construction sets will be excluded from modification.
**Name:** exclude_construction_sets,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Duplicate All Construction Sets
If true, all existing construction sets will be duplicated and modified, preserving the originals.
**Name:** duplicate_all_sets,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Use Custom Inner Floor Thickness
If true, the specified custom thickness will be used for the inner floor CLT. Otherwise, the thickness will be calculated based on the selected ply.
**Name:** use_custom_inner_floor_thickness,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Use Custom Roof Thickness
If true, the specified custom thickness will be used for the roof CLT. Otherwise, the thickness will be calculated based on the selected ply.
**Name:** use_custom_roof_thickness,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Replace External Walls with CLT
If true, the external walls will be replaced with CLT constructions.
**Name:** replace_external_walls,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Use Custom Wall Thickness
If true, the specified custom thickness will be used for the wall CLT. Otherwise, the thickness will be calculated based on the selected ply.
**Name:** use_custom_wall_thickness,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Infer Insulation Levels from Existing Constructions
If true, the measure will analyze existing wall and roof constructions to infer insulation levels and apply them to the new CLT constructions.
**Name:** infer_insulation_levels,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Inner Floor CLT Type
Select the type of CLT for the inner floor.
**Name:** inner_floor_clt_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["SPF", "DF"]


### Inner Floor CLT Ply
Select the number of plies for the inner floor CLT.
**Name:** inner_floor_clt_ply,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["3", "5", "7", "9", "11"]


### Custom Inner Floor CLT Thickness
Specify the custom thickness for the inner floor CLT if "Use Custom Inner Floor Thickness" is true.
**Name:** inner_floor_clt_thickness,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Roof CLT Type
Select the type of CLT for the roof.
**Name:** roof_clt_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["SPF", "DF"]


### Roof CLT Ply
Select the number of plies for the roof CLT.
**Name:** roof_clt_ply,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["3", "5", "7", "9", "11"]


### Custom Roof CLT Thickness
Specify the custom thickness for the roof CLT if "Use Custom Roof Thickness" is true.
**Name:** roof_clt_thickness,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Roof Insulation R-value
Specify the R-value for the roof insulation.
**Name:** roof_insulation_r_value,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Facade Layer
Select the facade layer to be applied on the exterior walls.
**Name:** facade_layer,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["None", "Brick", "Stucco", "Metal Surface"]


### Exterior Insulation
Select the type of outer insulation for the exterior walls.
**Name:** outer_insulation,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["None", "Mineral Fiberboard", "Polyiso"]


### Exterior Insulation R-value
Specify the R-value for the exterior insulation.
**Name:** exterior_insulation_r_value,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### CLT Layer
Select the type of CLT layer to be used.
**Name:** clt_layer,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["None", "SPF", "DF"]


### Wall CLT Ply
Select the number of plies for the wall CLT.
**Name:** wall_clt_ply,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["3", "5", "7", "9", "11"]


### Custom Wall CLT Layer Thickness
Specify the custom thickness for the wall CLT if "Use Custom Wall Thickness" is true.
**Name:** wall_clt_layer_thickness,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Inner Insulation
Select the type of inner insulation for the interior walls.
**Name:** inner_insulation,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["None", "Fiberglass Batt", "Spray Foam"]


### Interior Insulation R-value
Specify the R-value for the interior insulation.
**Name:** interior_insulation_r_value,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Inner Wall Face Layer
Select the type of inner wall face layer.
**Name:** inner_wall,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["None", "Gypsum"]






