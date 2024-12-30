
# Create and Assign CLT Construction Set

## Overview

This measure allows a modeler to change the construction set in their model to a CLT (Cross-Laminated Timber) construction set. The measure includes options for CLT exterior walls, CLT interior floors, and roof. It also provides options to infer insulation levels from existing constructions, replace external walls, and specify custom thickness for CLT layers. Additionally, it allows duplicating existing construction sets to preserve originals and includes detailed R-value calculations in construction names.

## How It Works

The measure enables the assignment of CLT construction sets to a model. Features include specifying CLT types and plies for inner floors, roofs, and walls, with the option to use custom thicknesses. The measure can infer insulation levels based on existing constructions, splitting required R-values between exterior and interior insulation if specified. It supports duplicating existing construction sets for preservation and ensures that inner floors and ceilings share the same construction. The measure also calculates and includes the effective R-value in the construction names.

## Inputs and Arguments

### Required Arguments

1. **Inner Floor CLT Type**: Select the type of CLT for the inner floor. Options are SPF (Spruce-Pine-Fir) and DF (Douglas Fir).
2. **Inner Floor CLT Ply**: Select the number of plies for the inner floor CLT. Options are 3, 5, 7, 9, 11.
3. **Roof CLT Type**: Select the type of CLT for the roof. Options are SPF and DF.
4. **Roof CLT Ply**: Select the number of plies for the roof CLT. Options are 3, 5, 7, 9, 11.
5. **Wall CLT Ply**: Select the number of plies for the wall CLT. Options are 3, 5, 7, 9, 11.
6. **CLT Layer**: Select the type of CLT layer to be used for the wall. Options are SPF and DF.

### Optional Arguments

1. **Duplicate All Construction Sets**: If true, all existing construction sets will be duplicated and modified, preserving the originals. Default is true.
2. **Use Custom Inner Floor Thickness**: If true, the specified custom thickness will be used for the inner floor CLT. Otherwise, the thickness will be calculated based on the selected ply. Default is false.
3. **Custom Inner Floor CLT Thickness**: Specify the custom thickness for the inner floor CLT if "Use Custom Inner Floor Thickness" is true. Default is 0.1016 meters.
4. **Use Custom Roof Thickness**: If true, the specified custom thickness will be used for the roof CLT. Otherwise, the thickness will be calculated based on the selected ply. Default is false.
5. **Custom Roof CLT Thickness**: Specify the custom thickness for the roof CLT if "Use Custom Roof Thickness" is true. Default is 0.1715 meters.
6. **Replace External Walls with CLT**: If true, the external walls will be replaced with CLT constructions. Default is false.
7. **Use Custom Wall Thickness**: If true, the specified custom thickness will be used for the wall CLT. Otherwise, the thickness will be calculated based on the selected ply. Default is false.
8. **Custom Wall CLT Layer Thickness**: Specify the custom thickness for the wall CLT if "Use Custom Wall Thickness" is true. Default is 0.1016 meters.
9. **Infer Insulation Levels from Existing Constructions**: If true, the measure will analyze existing wall and roof constructions to infer insulation levels and apply them to the new CLT constructions. Default is false.
10. **Roof Insulation R-value**: Specify the R-value for the roof insulation. Default is 5.28.
11. **Facade Layer**: Select the facade layer to be applied on the exterior walls. Options are None, Brick, Stucco, Metal Surface. Default is None.
12. **Exterior Insulation**: Select the type of outer insulation for the exterior walls. Options are None, Mineral Fiberboard, Polyiso. Default is Polyiso.
13. **Exterior Insulation R-value**: Specify the R-value for the exterior insulation. Default is 5.28.
14. **Inner Insulation**: Select the type of inner insulation for the interior walls. Options are None, Fiberglass Batt, Spray Foam. Default is None.
15. **Interior Insulation R-value**: Specify the R-value for the interior insulation. Default is 0.
16. **Inner Wall Face Layer**: Select the type of inner wall face layer. Options are None, Gypsum. Default is None.

## Additional Information

### CLT Construction and Buildings

Cross-Laminated Timber (CLT) is an engineered wood product made from layers of solid-sawn lumber, stacked crosswise at 90 degrees and bonded together with structural adhesives. This provides exceptional strength, stability, and rigidity. CLT is used for walls, roofs, floors, and other structural applications.

### How to Use the Measure

1. **Select the CLT Types and Plies**: Choose the appropriate types and plies for the inner floor, roof, and walls.
2. **Set Optional Arguments**: Configure optional settings such as custom thickness, insulation types, and whether to infer insulation levels.
3. **Run the Measure**: Apply the measure to your model. The measure will create and assign the new CLT construction sets based on the specified inputs.

### Tips for Best Results

- **Review Existing Constructions**: Check the existing constructions in your model to understand the current insulation levels before running the measure.
- **Use Custom Thicknesses**: For more precise modeling, use the custom thickness options to match specific design requirements.
- **Duplicate Construction Sets**: Enable the duplication of construction sets to preserve the original sets for comparison.

This measure simplifies the process of incorporating CLT construction into your models, providing flexibility and precision in specifying materials and insulation levels.
