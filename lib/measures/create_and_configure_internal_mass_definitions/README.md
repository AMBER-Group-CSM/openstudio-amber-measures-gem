

###### (Automatically generated documentation)

# Create and Configure Internal Mass Definitions

## Description
Create a new internal mass definition using a layered construction and assign to matching spaces.

## Modeler Description
Build an opaque material from user inputs, wrap it in a layered construction, create an InternalMassDefinition, set sizing method, then instantiate and assign InternalMass objects to spaces matching a name pattern.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Internal Mass Definition Name

**Name:** definition_name,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Opaque Material Name

**Name:** material_name,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Material Roughness

**Name:** roughness,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["VeryRough", "Rough", "MediumRough", "MediumSmooth", "Smooth", "VerySmooth"]


### Layer Thickness (m)

**Name:** thickness,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Thermal Conductivity (W/m·K)

**Name:** conductivity,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Density (kg/m³)

**Name:** density,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Specific Heat (J/kg·K)

**Name:** specific_heat,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Surface Area (m²)

**Name:** surface_area,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Surface Area per Space Floor Area (m²/m²)

**Name:** surface_area_per_floor_area,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Surface Area per Person (m²/person)

**Name:** surface_area_per_person,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Sizing Calculation Method

**Name:** calculation_method,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["Surface Area", "Surface Area per Space Floor Area", "Surface Area per Person"]


### Internal Mass Multiplier

**Name:** multiplier,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Space Name Pattern

**Name:** space_name_pattern,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Override Internal Mass Convection Coefficients
If true, the internal mass convection coefficients will be overridden with the a custom SurfacePropertyConvectionCoefficient object.
**Name:** override_convection,
**Type:** Boolean,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Natural Convection Coefficient Multiplier
Multiplier for the internal mass natural convection coefficient
**Name:** nat_conv_multiplier,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Secondary Convection Coefficient Term Scaler for Room Mixing Effects
Scaler for the additional convection coefficient term to account for room mixing effects
**Name:** added_conv_scaler,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Exponential for Added Convection Coefficient Temperature Difference
Shapes the curve of the secondary convection coefficient term.
**Name:** added_conv_exp,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false






