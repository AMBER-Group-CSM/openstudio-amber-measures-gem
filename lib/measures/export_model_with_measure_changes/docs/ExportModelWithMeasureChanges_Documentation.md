
# Export Model with Measure Changes

## Overview

The `ExportModelWithMeasureChanges` measure is designed to facilitate the export and archival of a modified OpenStudio Model (OSM) file after simulation measures have been applied. It ensures that the final OSM file, reflecting all applied measures, is saved in a specified location with a user-defined or default naming convention. This is particularly useful for archiving the modified model after simulations and measures have been executed.

## Key Features

### Purpose
- Exports the `in.osm` file created during the simulation.
- Moves the file to a specified directory, renaming it according to user-defined or default naming conventions.

### Naming and Path Customization
- **Custom File Name:** Users can specify a custom name for the exported OSM file. If not provided, the default name `{name_of_parent_model}_wMeasures.osm` is used.
- **Destination Directory:** The measure offers two options:
  - **Generated Files Directory:** The default directory where simulation files are typically stored.
  - **Custom Path:** A user-defined directory path where the file will be saved.
- **Versioning:** Includes an option for versioning, which appends an incrementing version number to the exported file name. Users can specify a suffix to be included before the version number.

### Execution
- **Parent Model Identification:** The measure identifies the parent model file (excluding temporary files) from the directory above the root simulation directory.
- **Path Determination:** The appropriate destination directory and file name are determined based on user inputs.
- **File Operation:** The `in.osm` file from the simulation is copied to the chosen directory with the specified name, overwriting any existing file with the same name.

### Error Handling and Logging
- **Error Checking:** Ensures that all required inputs are valid. For instance, it checks if the custom path is provided when "Custom Path" is selected and if the source `in.osm` file exists.
- **Informative Logging:** Registers informative messages and warnings throughout the process to assist with debugging and ensure users are aware of the measure's operations.

## User Inputs

### Arguments

1. **Custom File Name (`custom_name`)** (optional): 
   - Specify a custom name for the exported OSM file. If left blank, the default name will be used.
   - Do not include the `.osm` extension in this field.

2. **Destination Directory (`destination_dir`)**:
   - Select the destination directory for the exported file.
   - Options: `Generated Files Directory` (default) or `Custom Path`.

3. **Custom Path (`custom_path`)** (optional):
   - Specify a custom path for the exported OSM file.
   - This argument is required if `Custom Path` is selected as the destination directory.

4. **Use Versioning (`use_versioning`)**:
   - If selected, the exported file will have a version number appended to its name.
   - This is useful for tracking changes across multiple simulations.

5. **Version Suffix (`version_suffix`)** (optional):
   - Specify a suffix to be included before the version number in the file name.
   - This argument is only relevant if versioning is enabled.

## Use Cases

### Archiving Models
This measure is particularly useful when you want to archive OSM files after applying simulation measures. By exporting the model with a versioned name, you can keep track of changes and iterations during your project.

### Custom Directory Storage
When working in environments where project files need to be stored in specific directories, this measure allows you to define a custom path for exporting the final OSM model, ensuring it fits within your project’s organizational structure.

## Troubleshooting

### Common Errors
- **No Parent Model Found:** Ensure that the directory structure is correct and that the parent model file exists in the expected location.
- **Missing Custom Path:** If "Custom Path" is selected as the destination directory, ensure that a valid path is provided.
- **Source File Not Found:** Ensure that the simulation has been run and that the `in.osm` file exists in the expected location.

## Example

Assume you want to export the modified OSM file to a custom directory with versioning enabled. You would set the following arguments:
- `custom_name`: `MySimulationModel`
- `destination_dir`: `Custom Path`
- `custom_path`: `/path/to/my/directory`
- `use_versioning`: `True`
- `version_suffix`: `_v`

The measure would then export the file as `/path/to/my/directory/MySimulationModel_v1.osm`, creating the directory if it doesn’t exist.
