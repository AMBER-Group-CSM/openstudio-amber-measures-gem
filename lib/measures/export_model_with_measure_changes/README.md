

###### (Automatically generated documentation)

# Export Model with Measure Changes

## Description
This measure exports the in.osm file created for the simulation, moves it to a specified directory, and renames it. The default name is {name_of_parent_model}_wMeasures.osm, but a custom name can be specified.

## Modeler Description
This measure is useful for archiving the modified OSM file after measures have been applied and simulations have been run. The exported file can be saved to the OpenStudio "reports" directory or a custom path. A custom name for the exported file can also be specified, with an option to add an incrementing version number.

## Measure Type
ReportingMeasure

## Taxonomy


## Arguments


### Custom File Name
Specify a custom name for the exported OSM file. Do not include the .osm extension. If left blank, the default name will be used.
**Name:** custom_name,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Destination Directory

**Name:** destination_dir,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["Generated Files Directory", "Custom Path"]


### Custom Path
Specify a custom path for the exported OSM file. This is used if "Custom Path" is selected as the destination directory.
**Name:** custom_path,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Use Versioning
If selected, the exported file will have a version number appended to its name.
**Name:** use_versioning,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Version Suffix
Specify a suffix to use before the version number. For example, "_v". This is used if versioning is enabled.
**Name:** version_suffix,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false






