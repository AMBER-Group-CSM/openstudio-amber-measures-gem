

###### (Automatically generated documentation)

# Choose Constructions for SurfaceProperty:HeatTransferAlgorithm

## Description
Presents a checkbox for each Construction in the model so you can pick which ones to tag with a SurfaceProperty:HeatTransferAlgorithm:Construction and which algorithm to use.

## Modeler Description
Loops through all Construction objects, makes one Bool argument per construction, and then in run() adds a SurfaceProperty:HeatTransferAlgorithm:Construction for each checked construction using the chosen algorithm.

## Measure Type
EnergyPlusMeasure

## Taxonomy


## Arguments


### Optional Comma Separated List of Custom Constructions
If you have added custom constructions in a measure workflow, you can enter the names here. Those are searched for in addition to the ones checked above.
**Name:** custom_constructions,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Select Heat Transfer Algorithm

**Name:** algorithm,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["MoisturePenetrationDepthConductionTransferFunction", "CombinedHeatAndMoistureFiniteElement", "ConductionFiniteDifference", "ConductionTransferFunction"]


### Change the Timesteps per Hour?
Sets a new timestep, leave blank for no change.
**Name:** timestep,
**Type:** Integer,
**Units:** ,
**Required:** false,
**Model Dependent:** false






