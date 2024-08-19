require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ConfigureOutputControlTableStyle_Test < Minitest::Test
  def test_ConfigureOutputControlTableStyle
    # Create an instance of the measure
    measure = ConfigureOutputControlTableStyle.new

    # Create an empty model
    model = OpenStudio::Model::Model.new

    # Create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # Create an instance of the arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # Set argument values
    column_separator = arguments[0].clone
    assert(column_separator.setValue('Comma'))
    argument_map['column_separator'] = column_separator

    unit_conversion = arguments[1].clone
    assert(unit_conversion.setValue('None'))
    argument_map['unit_conversion'] = unit_conversion

    # Run the measure
    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)

    # Assert that the measure ran successfully
    assert_equal('Success', result.value.valueName)

    # Check that the OutputControl:Table:Style object was set correctly
    output_control_table_style = model.getOutputControlTableStyle
    assert(output_control_table_style.initialized)
    output_control_table_style = output_control_table_style
    assert_equal('Comma', output_control_table_style.columnSeparator)
    assert_equal('None', output_control_table_style.unitConversion)
  end
end
