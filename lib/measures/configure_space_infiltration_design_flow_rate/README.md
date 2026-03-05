

###### (Automatically generated documentation)

# Configure Space Infiltration Design Flow Rate

## Description
Configures Space Infiltration Design Flow Rate objects for all spaces in zones with at least one exterior surface. The user can either provide their own design flow coefficients or use NIST-derived coefficients (Ng et al.) based on building type, climate zone, and air barrier. The measure creates paired HVAC-on and HVAC-off infiltration objects per exterior space, with separate coefficients and schedules for each.

## Modeler Description
This measure removes existing infiltration objects if requested, determines which thermal zones have exterior exposure, constructs HVAC ON and OFF schedules from user input or by inferring from the largest air loop and/or building hours of operation, optionally rescales a user-supplied design infiltration value from a measured pressure to a reference pressure, and creates new SpaceInfiltrationDesignFlowRate objects for spaces in external thermal zones. For each qualifying space, two infiltration objects are created: one active when the HVAC is on (using a binary HVAC ON schedule and the HVAC-on ABCD coefficients) and one active when the HVAC is off (using a complementary HVAC OFF schedule and the HVAC-off ABCD coefficients). Coefficients may be explicitly provided or automatically looked up from NIST infiltration correlations.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Design Flow Rate Calculation Method
Select the design flow rate calculation method for the SpaceInfiltrationDesignFlowRate objects (e.g., Flow/Zone [m^3/s], Flow/Area [m^3/s-m^2], Flow/ExteriorSurfaceArea [m^3/s-m^2], Flow/ExteriorWallArea [m^3/s-m^2], AirChanges/Hour [1/h]).
**Name:** design_flow_rate_calculation_method,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["Flow/Space", "Flow/Area", "Flow/ExteriorArea", "Flow/ExteriorWallArea", "AirChanges/Hour"]


### Design Flow Value for Selected Method
Numeric design flow value consistent with the chosen calculation method. If your design flow is given in (cfm/ft^2) at a given pressure, convert to (m^3/h-m^2) by multiplying by 18.288 (m-min/ft-hr); then, if needed, convert hours to seconds.
**Name:** design_flow_value,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Measured Pressure for Design Flow (Pa)
Pressure at which the design flow value was measured (e.g., from a pressurization test). Used only if "Scale Design Flow to Reference Pressure" is enabled.
**Name:** measured_pressure,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Reference (Design) Pressure for Simulation (Pa)
Reference pressure at which the design infiltration value should be applied in the simulation. If your design flow is given in (cfm/ft^2) at a given pressure, first convert to (m^3/h-m^2) by multiplying by 18.288 (m-min/ft-hr), then convert to (m^3/s-m^2) as needed, and finally scale between pressures if desired.
**Name:** reference_pressure,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Scale Design Flow from Measured Pressure to Reference Pressure?
If true, the design flow value is scaled from the measured pressure to the reference pressure using a power-law relationship (exponent ~0.65).
**Name:** scale_to_reference_pressure,
**Type:** Boolean,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Use NIST Infiltration Correlation Coefficients?
If true, HVAC on/off infiltration coefficients (A, B, C, D) are looked up from NIST correlations based on building type, climate zone, and air barrier; user-provided coefficients are ignored.
**Name:** use_nist_coefficients,
**Type:** Boolean,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Climate Zone for NIST Coefficients
ASHRAE climate zone to use for NIST infiltration correlations. "Lookup From Model" will attempt to infer from the model climate zones (ASHRAE or mapped from CEC).
**Name:** climate_zone,
**Type:** Choice,
**Units:** ,
**Required:** false,
**Model Dependent:** false

**Choice Display Names** ["1A", "1B", "2A", "2B", "3A", "3B", "3C", "4A", "4B", "4C", "5A", "5B", "5C", "6A", "6B", "7A", "8A", "Lookup From Model"]


### Building Type for NIST Coefficients
Building type to use for NIST infiltration correlations. "Lookup From Model" will infer the closest matching NIST prototype from the model standards building type and floor area.
**Name:** building_type,
**Type:** Choice,
**Units:** ,
**Required:** false,
**Model Dependent:** false

**Choice Display Names** ["SecondarySchool", "PrimarySchool", "SmallOffice", "MediumOffice", "SmallHotel", "LargeHotel", "RetailStandalone", "RetailStripmall", "Hospital", "MidriseApartment", "HighriseApartment", "Lookup From Model"]


### Building Has Air Barrier? (For NIST Coefficients)
If true, use NIST coefficients for buildings with an air barrier. If false, use coefficients for buildings without an air barrier.
**Name:** air_barrier,
**Type:** Boolean,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### HVAC ON: Constant Term Coefficient (A_on)
Constant term coefficient in the infiltration correlation when HVAC is ON. Ignored if NIST coefficients are used.
**Name:** constant_term_coefficient_on,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### HVAC ON: Temperature Term Coefficient (B_on)
Temperature term coefficient in the infiltration correlation when HVAC is ON. Ignored if NIST coefficients are used.
**Name:** temperature_term_coefficient_on,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### HVAC ON: Velocity Term Coefficient (C_on)
Wind speed term coefficient in the infiltration correlation when HVAC is ON. Ignored if NIST coefficients are used.
**Name:** velocity_term_coefficient_on,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### HVAC ON: Velocity Squared Term Coefficient (D_on)
Wind speed squared term coefficient in the infiltration correlation when HVAC is ON. Ignored if NIST coefficients are used.
**Name:** velocity_squared_term_coefficient_on,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### HVAC OFF: Constant Term Coefficient (A_off)
Constant term coefficient in the infiltration correlation when HVAC is OFF. Ignored if NIST coefficients are used.
**Name:** constant_term_coefficient_off,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### HVAC OFF: Temperature Term Coefficient (B_off)
Temperature term coefficient in the infiltration correlation when HVAC is OFF. Ignored if NIST coefficients are used.
**Name:** temperature_term_coefficient_off,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### HVAC OFF: Velocity Term Coefficient (C_off)
Wind speed term coefficient in the infiltration correlation when HVAC is OFF. Ignored if NIST coefficients are used.
**Name:** velocity_term_coefficient_off,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### HVAC OFF: Velocity Squared Term Coefficient (D_off)
Wind speed squared term coefficient in the infiltration correlation when HVAC is OFF. Ignored if NIST coefficients are used.
**Name:** velocity_squared_term_coefficient_off,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### HVAC Operating (Availability) Schedule
Schedule that represents when the HVAC system is available/operating. "Lookup From Model" will use the availability schedule from the system serving the largest floor area or the building hours-of-operation schedule.
**Name:** hvac_operating_schedule,
**Type:** Choice,
**Units:** ,
**Required:** false,
**Model Dependent:** true


### HVAC Non-Operating (OFF) Schedule
Schedule used for infiltration when the HVAC system is off. You may select a schedule directly, use "Always On", or choose "Infer From HVAC Operating Schedule" to create an inverse of the HVAC ON schedule.
**Name:** hvac_non_operating_schedule,
**Type:** Choice,
**Units:** ,
**Required:** false,
**Model Dependent:** true


### Remove All Existing Infiltration Objects?
If true, all existing SpaceInfiltrationDesignFlowRate and SpaceInfiltrationEffectiveLeakageArea objects will be removed before creating new ones.
**Name:** remove_existing_infiltration,
**Type:** Boolean,
**Units:** ,
**Required:** false,
**Model Dependent:** false






