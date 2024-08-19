# Copyright 2024 Gabriel Miguel Flechas
# 
# Licensed under the MIT License.
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

class ConfigureOutputControlTableStyle < OpenStudio::Measure::ModelMeasure
  # Human-readable name
  def name
    return 'Configure OutputControlTableStyle'
  end

  # Human-readable description
  def description
    return 'This measure allows users to set the column separator and unit conversion options for the OutputControl:Table:Style object in an OpenStudio model.'
  end

  # Modeler description
  def modeler_description
    return 'The measure provides choice arguments for column separator and unit conversion, then sets these options in the OutputControl:Table:Style object of the OpenStudio model. If the object does not exist, it will be created.'
  end

  # Define arguments
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # Column Separator choice argument
    column_separator = OpenStudio::Measure::OSArgument::makeChoiceArgument('column_separator', ['Comma', 'Tab', 'Fixed', 'HTML', 'XML', 'CommaAndHTML', 'TabAndHTML', 'XMLAndHTML', 'All'], true)
    column_separator.setDisplayName('Column Separator')
    column_separator.setDefaultValue('CommaAndHTML')
    args << column_separator

    # Unit Conversion choice argument
    unit_conversion = OpenStudio::Measure::OSArgument::makeChoiceArgument('unit_conversion', ['None', 'JtoKWH', 'JtoMJ', 'JtoGJ', 'InchPound'], true)
    unit_conversion.setDisplayName('Unit Conversion')
    unit_conversion.setDefaultValue('JtoKWH')
    args << unit_conversion

    return args
  end

  # Define the measure's run method
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # Use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # Assign the user inputs to variables
    column_separator = runner.getStringArgumentValue('column_separator', user_arguments)
    unit_conversion = runner.getStringArgumentValue('unit_conversion', user_arguments)

    # Get or create the OutputControl:Table:Style object
    output_control_table_style = model.getOutputControlTableStyle
    # if output_control_table_style.to_OutputControlTableStyle.empty?
    if not output_control_table_style.initialized
      output_control_table_style = OpenStudio::Model::OutputControlTableStyle.new(model)
    end

    # Set the column separator
    output_control_table_style.setColumnSeparator(column_separator)

    # Set the unit conversion
    output_control_table_style.setUnitConversion(unit_conversion)

    # Reporting final condition
    runner.registerFinalCondition("OutputControl:Table:Style object set with Column Separator as #{column_separator} and Unit Conversion as #{unit_conversion}.")

    return true
  end
end

# Register the measure to be used by the application
ConfigureOutputControlTableStyle.new.registerWithApplication
