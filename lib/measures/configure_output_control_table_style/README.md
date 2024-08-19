

###### (Automatically generated documentation)

# Configure OutputControlTableStyle

## Description
This measure allows users to set the column separator and unit conversion options for the OutputControl:Table:Style object in an OpenStudio model.

## Modeler Description
The measure provides choice arguments for column separator and unit conversion, then sets these options in the OutputControl:Table:Style object of the OpenStudio model. If the object does not exist, it will be created.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Column Separator

**Name:** column_separator,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["Comma", "Tab", "Fixed", "HTML", "XML", "CommaAndHTML", "TabAndHTML", "XMLAndHTML", "All"]


### Unit Conversion

**Name:** unit_conversion,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["None", "JtoKWH", "JtoMJ", "JtoGJ", "InchPound"]






