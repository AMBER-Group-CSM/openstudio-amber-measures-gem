

###### (Automatically generated documentation)

# Add EMPD Material Properties PreDefined

## Description
Adds effective moisture penetration depth (EMPD) Heat Balance Model properties for a selected material in the model.

## Modeler Description
Adds the properties for the 'MoisturePenetrationDepthConductionTransferFunction' or effective moisture penetration depth (EMPD) Heat Balance Model with inputs for penetration depths. Using the values a=0, b=1, c=0, and d=1 results in a non-absorbant material and is useful for adding properties to a material in a zone so that you can use the algorithm, but for a zone/material that doesn't participate in the moisture balance.
Leaving 'Change heat balance algorithm?' blank will use the current OpenStudio heat balance algorithm setting.
At least 1 interior material in every zone needs to have moisture penetration depth properties set to use the EMPD heat balance algorithm.
Moisture properties are drawn from a modified idf of the EnergyPlus MoistureProperties.idf dataset file. The modified file has moisture properties for SPF and DF cross-laminated timber based on the research study by Kordziel et al. 'Hygrothermal characterization and modeling of cross-laminated timber in the building envelope'.


## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Select Material

**Name:** selected_material,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Optional Custom Material Name
If you have added a custom material in a measure workflow, you can enter the name here. Leave empty to use the selected material.
**Name:** opt_custom_material,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Select the closest material here to the one in your model

**Name:** moisture_material_choice,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Override PreDefined Material's Water Vapor Diffusion Resistance Factor?

**Name:** cust_waterDiffFact,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Set value for Water Vapor Diffusion Resistance Factor

**Name:** waterDiffFact,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Override PreDefined Material's Moisture Equation Coefficients (a-d)?

**Name:** cust_coeffs,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Set value for Moisture Equation Coefficient A

**Name:** coefA,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Set value for Moisture Equation Coefficient B

**Name:** coefB,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Set value for Moisture Equation Coefficient C

**Name:** coefC,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Set value for Moisture Equation Coefficient D

**Name:** coefD,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Override PreDefined Material's Surface Layer Penetration Depth?

**Name:** cust_surfacePenetration,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Set value for Surface Layer Penetration Depth

**Name:** surfacePenetration,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Override PreDefined Material's Deep Layer Penetration Depth?

**Name:** cust_deepPenetration,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Set value for Deep Layer Penetration Depth

**Name:** deepPenetration,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Override PreDefined Material's Coating Layer Thickness?

**Name:** cust_coating,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Set value for Coating Layer Thickness

**Name:** coating,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Override PreDefined Material's Coating Layer Resistance Factor

**Name:** cust_coatingRes,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Set value for Coating Layer Resistance Factor

**Name:** coatingRes,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Change heat balance algorithm?

**Name:** algorithm,
**Type:** Choice,
**Units:** ,
**Required:** false,
**Model Dependent:** false




