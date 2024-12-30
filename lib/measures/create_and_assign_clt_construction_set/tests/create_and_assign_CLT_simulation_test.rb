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

class CreateAndAssignCLTConstructionSet_Test < Minitest::Test

  def model_in_path
    "#{File.dirname(__FILE__)}/example_model.osm"
  end

  def run_dir(test_name)
    "#{File.dirname(__FILE__)}/output/#{test_name}"
  end

  def resources_dir(test_name)
    "#{run_dir(test_name)}/resources"
  end

  def model_out_path(test_name)
    "#{run_dir(test_name)}/#{test_name}_model.osm"
  end

  def setup_test_environment(test_name)
    # Setup the directory structure for the test
    FileUtils.mkdir_p(resources_dir(test_name))
    assert(File.exist?(resources_dir(test_name)))

    # Copy the model to the test directory
    FileUtils.cp(model_in_path, model_out_path(test_name))
    assert(File.exist?(model_out_path(test_name)))
  end

  def run_measure(test_name, measure, runner, argument_map, model)
    start_dir = Dir.pwd
    begin
      Dir.chdir(resources_dir(test_name))

      # Apply the measure to the model
      measure.run(model, runner, argument_map)
      result = runner.result
      show_output(result)
    ensure
      Dir.chdir(start_dir)
    end
    result
  end

  def test_apply_clt_construction_set
    test_name = 'test_apply_clt_construction_set'

    # Initialize the measure
    measure = CreateAndAssignCLTConstructionSet.new

    # Create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # Load the model from file
    translator = OpenStudio::OSVersion::VersionTranslator.new
    model = translator.loadModel(OpenStudio::Path.new(model_in_path))
    assert(!model.empty?)
    model = model.get

    # Get and set measure arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # Set argument values for testing
    args_hash = {}
    args_hash['exclude_construction_sets'] = ''
    args_hash['duplicate_all_sets'] = true
    args_hash['replace_external_walls'] = true

    # Populate argument map with test values
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # Setup the test environment
    setup_test_environment(test_name)

    # Run the measure and check the result
    result = run_measure(test_name, measure, runner, argument_map, model)

    # Validate the measure result
    assert_equal('Success', result.value.valueName)
    assert(result.errors.empty?)
    assert(result.warnings.empty?)
  end

  def teardown
    # Cleanup the test output directory
    if File.exist?(run_dir(''))
      FileUtils.rm_rf(run_dir(''))
    end
  end

end
