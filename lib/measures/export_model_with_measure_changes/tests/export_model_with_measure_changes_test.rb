# *******************************************************************************
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
# *******************************************************************************

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'

require_relative '../measure.rb'
require 'minitest/autorun'

class ExportModelWithMeasureChanges_Test < Minitest::Test

  def model_in_path
    # Correct the path to the test model file
    "#{File.dirname(__FILE__)}/example_model.osm"
  end

  def epw_path
    # Path to the test weather file
    "#{File.dirname(__FILE__)}/USA_CO_Golden-NREL.724666_TMY3.epw"
  end

  def run_dir(test_name)
    # Directory where test outputs will be saved
    "#{File.dirname(__FILE__)}/output/#{test_name}"
  end

  def resources_dir(test_name)
    # Directory where resources (OSW, etc.) will be stored
    "#{run_dir(test_name)}/resources"
  end

  def model_out_path(test_name)
    # Path where the duplicated model (seed file) will be saved
    "#{run_dir(test_name)}/#{test_name}_model.osm"
  end

  def model_output_path(test_name)
    # Path where the output model (in.osm) should be saved after simulation
    "#{resources_dir(test_name)}/run/in.osm"
  end

  def setup_test_environment(test_name)
    # Create the necessary directory structure
    FileUtils.mkdir_p(resources_dir(test_name))
    assert(File.exist?(resources_dir(test_name)))

    # Copy the model file to the test directory as a seed file
    FileUtils.cp(model_in_path, model_out_path(test_name))
    assert(File.exist?(model_out_path(test_name)))
  end

  def simulate_model(test_name)
    # Create a new OSW for the test in the resources directory
    osw_path = File.join(resources_dir(test_name), 'workflow.osw')
    osw_path = File.absolute_path(osw_path)

    # Create an empty OSW and add the model and weather file paths
    workflow = OpenStudio::WorkflowJSON.new
    workflow.setSeedFile(File.absolute_path(model_out_path(test_name)))  # Use the copied seed file
    workflow.setWeatherFile(File.absolute_path(epw_path))
    workflow.saveAs(osw_path)

    # Run the simulation using OpenStudio CLI
    cli_path = OpenStudio.getOpenStudioCLI
    cmd = "\"#{cli_path}\" run -w \"#{osw_path}\""
    system(cmd)

    # Ensure the simulation generated the expected output
    assert(File.exist?(model_output_path(test_name)))
    assert(File.exist?(epw_path))
  end

  def run_measure(test_name, measure, runner, argument_map)
    # Temporarily change directory to the resources directory and run the measure
    start_dir = Dir.pwd
    begin
      Dir.chdir(resources_dir(test_name))

      # Run the measure
      measure.run(runner, argument_map)
      result = runner.result
      show_output(result) 
    ensure
      Dir.chdir(start_dir)
    end
    # return the result to check for errors
    return result
  end

  def section_errors(runner)
    # Helper method to check for section errors
    runner.result.stepWarnings.select { |warning| warning.include?('section failed and was skipped because') }
  end

  def test_export_with_custom_name
    test_name = 'test_export_with_custom_name'

    # Initialize the measure
    measure = ExportModelWithMeasureChanges.new

    # Create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # Get and set measure arguments
    arguments = measure.arguments
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # Set custom arguments
    args_hash = {}
    args_hash['custom_name'] = 'MyCustomModel'
    args_hash['destination_dir'] = 'Generated Files Directory'
    args_hash['use_versioning'] = true
    args_hash['version_suffix'] = '_v'

    # Populate argument map
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # Setup the test environment
    setup_test_environment(test_name)

    # Simulate the model to generate necessary outputs
    simulate_model(test_name)

    # Set up runner paths
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_output_path(test_name)))
    runner.setLastEpwFilePath(OpenStudio::Path.new(epw_path))

    # Run the measure from the correct directory
    result = run_measure(test_name, measure, runner, argument_map)

    # Validate the output file
    exported_file = "#{run_dir(test_name)}/resources/generated_files/MyCustomModel_v1.osm"
    assert_equal('Success', result.value.valueName)
    assert(section_errors(runner).empty?)
    assert(File.exist?(exported_file))
  end

  def test_export_with_default_name
    test_name = 'test_export_with_default_name'

    # Initialize the measure
    measure = ExportModelWithMeasureChanges.new

    # Create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # Get and set measure arguments
    arguments = measure.arguments
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # Set arguments with default file name
    args_hash = {}
    args_hash['destination_dir'] = 'Generated Files Directory'
    args_hash['use_versioning'] = true
    args_hash['version_suffix'] = '_v'

    # Populate argument map
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # Setup the test environment
    setup_test_environment(test_name)

    # Simulate the model to generate necessary outputs
    simulate_model(test_name)

    # Set up runner paths
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_output_path(test_name)))
    runner.setLastEpwFilePath(OpenStudio::Path.new(epw_path))

    # Run the measure from the correct directory
    result = run_measure(test_name, measure, runner, argument_map)

    # Validate the output file
    parent_model_name = File.basename(model_out_path(test_name), '.*')
    exported_file = "#{run_dir(test_name)}/resources/generated_files/#{parent_model_name}_wMeasures_v1.osm"
    assert_equal('Success', result.value.valueName)
    assert(section_errors(runner).empty?)
    assert(File.exist?(exported_file))
  end

  def test_export_with_custom_path
    test_name = 'test_export_with_custom_path'

    # Initialize the measure
    measure = ExportModelWithMeasureChanges.new

    # Create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # Get and set measure arguments
    arguments = measure.arguments
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # Set custom arguments
    args_hash = {}
    args_hash['custom_name'] = 'MyCustomModel'
    args_hash['destination_dir'] = 'Custom Path'
    args_hash['custom_path'] = "#{"./.."}"
    args_hash['use_versioning'] = false

    # Populate argument map
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # Setup the test environment
    setup_test_environment(test_name)

    # Simulate the model to generate necessary outputs
    simulate_model(test_name)

    # Create custom directory if it doesn't exist
    FileUtils.mkdir_p("#{run_dir(test_name)}")
    assert(File.exist?("#{run_dir(test_name)}"))

    # Set up runner paths
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_output_path(test_name)))
    runner.setLastEpwFilePath(OpenStudio::Path.new(epw_path))

    # Run the measure from the correct directory
    result = run_measure(test_name, measure, runner, argument_map)

    # Validate the output file
    exported_file = "#{run_dir(test_name)}/MyCustomModel.osm"
    assert_equal('Success', result.value.valueName)
    assert(section_errors(runner).empty?)
    assert(File.exist?(exported_file))
  end

  def test_missing_custom_path
    test_name = 'test_missing_custom_path'

    # Initialize the measure
    measure = ExportModelWithMeasureChanges.new

    # Create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # Get and set measure arguments
    arguments = measure.arguments
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # Set custom arguments with a missing custom path
    args_hash = {}
    args_hash['destination_dir'] = 'Custom Path'
    args_hash['custom_path'] = nil  # Intentionally missing custom path

    # Populate argument map
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # Setup the test environment
    setup_test_environment(test_name)

    # Simulate the model to generate necessary outputs
    simulate_model(test_name)

    # Set up runner paths
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_output_path(test_name)))
    runner.setLastEpwFilePath(OpenStudio::Path.new(epw_path))

    # Run the measure from the correct directory
    result = run_measure(test_name, measure, runner, argument_map)

    # Expect the measure to fail due to missing custom path
    # result = runner.result
    assert_equal('Fail', result.value.valueName)
    assert(result.errors.size > 0)
  end

  def teardown
    # Clean up the output directory after each test
    if File.exist?(run_dir(''))
      FileUtils.rm_rf(run_dir(''))
    end
  end
  
end
