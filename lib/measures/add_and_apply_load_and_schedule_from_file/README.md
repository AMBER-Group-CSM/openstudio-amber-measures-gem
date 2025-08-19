

###### (Automatically generated documentation)

# Add and Apply Load and Schedule from File

## Description
This measure imports electric or lighting load data from a CSV file and applies it to a selected load in the OpenStudio model as a ScheduleInterval. The measure offers options to normalize the data by floor area, invert the data if it represents energy consumption as negative values, and replace the existing power or power intensity with the maximum value from the CSV data.

## Modeler Description
This measure enhances the flexibility of energy modeling by allowing users to apply real-world load data to their OpenStudio models. It reads a specified column of electric or lighting load data from a CSV file and processes it to create a ScheduleInterval for a selected load object (either ElectricEquipment or Lights). Key features include the ability to normalize the data by the maximum value in the CSV column, adjust for floor area (either the whole building or a specific level), and replace existing design-level values with the maximum value from the CSV.
    Additionally, the measure provides an option to invert the load data, which is particularly useful if the data is reported as negative values when the load is consuming energy, such as in some sub-metered data sets. The measure handles various data intervals, such as hourly, 15-minute, or 1-minute data, and includes comprehensive error handling and logging to ensure the user is informed of any issues or actions taken during the measure's execution.
    The measure also supports the reuse of file paths and names across multiple runs by storing user-defined paths and filenames in a JSON file, making it easier to apply consistent settings across different projects or scenarios.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Select the Load Object:
Select the electric or lighting load object from the model to which the schedule will be applied.
**Name:** load_object,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** []


### Replace existing design/watts per floor area
If checked, this will replace the existing design value or watts per floor area with the maximum value from the CSV data.
**Name:** replace_load_value,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Override schedules associated with the load
If checked, this will override the existing schedule associated with the selected load with the new schedule created from the CSV data.
**Name:** replace_schedules,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Invert Load Data
Check if your sub-metered data is reported as a negative value when the load is consuming energy.
**Name:** invert_load_data,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Normalize by Floor Area
Choose whether to normalize the load data by the floor area of the whole building or a specific level.
**Name:** floor_area_selection,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["None", "Whole Building", "For a Level"]


### Select the Level:
Select the specific level of the building if you have chosen to normalize the load data by floor area for a particular level.
**Name:** level_selection,
**Type:** Choice,
**Units:** ,
**Required:** false,
**Model Dependent:** false

**Choice Display Names** []


### Enter the path to the directory where the data file is stored
Specify the directory path where the CSV data file is located. Leave this blank in subsequent runtime measures to reuse the same path. Example: 'C:\Projects\data'
**Name:** file_dir,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Enter the name of the CSV file
Specify the name of the CSV file containing the load data. Leave this blank in subsequent runtime measures to reuse the same file name. Example: 'values.csv'
**Name:** file_name,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Data Column in the CSV File
Specify the column number in the CSV file that contains the load data to be applied.
**Name:** data_columns,
**Type:** Integer,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Rows to Skip in the CSV File
Specify the number of rows to skip at the beginning of the CSV file. This is useful if the file has a header row or other non-data rows.
**Name:** rows_to_skip,
**Type:** Integer,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Units of the data in the CSV column
Specify the units of the load data in the CSV file. This can be left blank, or you can select from Watts (W), Kilowatts (kW), or BTU/hr.
**Name:** unit_choice,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["", "W", "kW", "BTU/hr"]






