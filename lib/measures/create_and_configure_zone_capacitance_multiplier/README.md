

###### (Automatically generated documentation)

# Create and Configure ZoneCapacitanceMultiplier

## Description
Creates ZoneCapacitanceMultiplier fully configurable objects for the requested zones. If you a user needs different capacitance multiplier values for different zones, use multiple measures in a workflow and request objects for the different zone names.

## Modeler Description
Creates ZoneCapacitanceMultiplier fully configurable objects for the requested zones. If you a user needs different capacitance multiplier values for different zones, use multiple measures in a workflow and request objects for the different zone names.

Description of this object from the documentation:
"This object is an advanced feature that can be used to control the effective storage capacity of the zone. Capacitance multipliers of 1.0 indicate the capacitance is that of the (moist) air in the volume of the specified zone. This multiplier can be increased if the zone air capacitance needs to be increased for stability of the simulation or to allow modeling higher or lower levels of damping of behavior over time. The multipliers are applied to the base value corresponding to the total capacitance for the zone’s volume of air at current zone (moist) conditions."

## Measure Type
EnergyPlusMeasure

## Taxonomy


## Arguments


### Zone Name/Names
The name of the zone to which the capacitance multiplier will be applied. If you want to apply the same multiplier to multiple zones, use a ZoneList object. Supports Regex. * to apply the multiplier to all zones.
**Name:** zone_name,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Temperature Capacity Multiplier
This field is used to alter the effective heat capacitance of the zone air volume. This affects the transient calculations of zone air temperature. Values greater than 1.0 have the effect of smoothing or damping the rate of change in the temperature of zone air from timestep to timestep.
**Name:** temperature_capacity_multiplier,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Humidity Capacity Multiplier
This field is used to alter the effective moisture capacitance of the zone air volume. This affects the transient calculations of zone air humidity ratio. Values greater than 1.0 have the effect of smoothing, or damping, the rate of change in the water content of zone air from timestep to timestep.
**Name:** humidity_capacity_multiplier,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Carbon Dioxide Capacity Multiplier
This field is used to alter the effective carbon dioxide capacitance of the zone air volume. This affects the transient calculations of zone air carbon dioxide concentration. Values greater than 1.0 have the effect of smoothing or damping the rate of change in the carbon dioxide level of zone air from timestep to timestep.
**Name:** carbon_dioxide_capacity_multiplier,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Generic Contaminant Capacity Multiplier
This field is used to alter the effective generic contaminant capacitance of the zone air volume. This affects the transient calculations of zone air generic contaminant concentration. Values greater than 1.0 have the effect of smoothing or damping the rate of change in the generic contaminant level of zone air from timestep to timestep.
**Name:** generic_contaminant_capacity_multiplier,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false






