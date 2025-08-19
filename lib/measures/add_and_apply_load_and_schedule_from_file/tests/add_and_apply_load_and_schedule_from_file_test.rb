require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require 'fileutils'
require_relative '../measure.rb'  # Ensure the measure is loaded

class AddAndApplyLoadAndScheduleFromFileTest < Minitest::Test

  # Helper function to load the model and measure
  def load_model_and_measure(osm_file_path)
    translator = OpenStudio::OSVersion::VersionTranslator.new
    model = translator.loadModel(osm_file_path)
    assert(!model.empty?)
    model = model.get

    measure = AddAndApplyLoadAndScheduleFromFile.new
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    return model, measure, runner
  end

  # Helper function to run the measure
  def run_measure(model, measure, runner, arguments)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(measure.arguments(model))
    arguments.each do |arg_name, arg_value|
      temp_arg_var = argument_map[arg_name].clone
      assert(temp_arg_var.setValue(arg_value))
      argument_map[arg_name] = temp_arg_var
    end

    # Run the measure
    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)

    return result
  end

  # Test with good hourly data
  def test_good_hourly_data
    model, measure, runner = load_model_and_measure('example_model.osm')

    # Select the first electric equipment and lighting load
    electric_equipment = model.getElectricEquipments.first
    lights = model.getLightss.first

    # Arguments for electric equipment with good hourly data
    arguments = {
      'load_object' => electric_equipment.handle.to_s,
      'replace_load_value' => true,
      'replace_schedules' => true,
      'invert_load_data' => false,  # No inversion
      'floor_area_selection' => 'Whole Building',
      'file_dir' => '.',  # Adjust the path to where the CSV files are located
      'file_name' => 'hourly_values.csv',
      'data_columns' => 1,
      'rows_to_skip' => 0,
      'unit_choice' => 'kW'
    }

    result = run_measure(model, measure, runner, arguments)
    assert_equal("Success", result.value.valueName)
  end

  # Test with good 15-minute data using level normalization
  def test_good_15min_data_level_normalization
    model, measure, runner = load_model_and_measure('example_model.osm')

    lights = model.getLightss.first

    # Arguments for lighting with good 15-minute data and level normalization
    arguments = {
      'load_object' => lights.handle.to_s,
      'replace_load_value' => true,
      'replace_schedules' => true,
      'invert_load_data' => false,  # No inversion
      'floor_area_selection' => 'For a Level',
      'level_selection' => model.getBuildingStorys.first.name.get,
      'file_dir' => '.',  # Adjust the path to where the CSV files are located
      'file_name' => '15min_values.csv',
      'data_columns' => 1,
      'rows_to_skip' => 0,
      'unit_choice' => 'W'
    }

    result = run_measure(model, measure, runner, arguments)
    assert_equal("Success", result.value.valueName)
  end

  # Test with bad hourly data
  def test_bad_hourly_data
    model, measure, runner = load_model_and_measure('example_model.osm')

    electric_equipment = model.getElectricEquipments.first

    # Arguments for electric equipment with bad hourly data
    arguments = {
      'load_object' => electric_equipment.handle.to_s,
      'replace_load_value' => true,
      'replace_schedules' => true,
      'invert_load_data' => false,  # No inversion
      'floor_area_selection' => 'None',
      'file_dir' => '.',  # Adjust the path to where the CSV files are located
      'file_name' => 'bad_hourly_values_output.csv',
      'data_columns' => 1,
      'rows_to_skip' => 0,
      'unit_choice' => 'kW'
    }

    # Check that the measure results in failure
    result = run_measure(model, measure, runner, arguments)
    assert_equal("Fail", result.value.valueName)
    assert_includes(result.errors.map(&:logMessage), "The file at path ./bad_hourly_values_output.csv doesn't exist.")
  end

  # Test with leap year hourly data
  def test_leap_year_hourly_data
    model, measure, runner = load_model_and_measure('example_model.osm')

    lights = model.getLightss.first

    # Arguments for lighting with leap year hourly data
    arguments = {
      'load_object' => lights.handle.to_s,
      'replace_load_value' => true,
      'replace_schedules' => true,
      'invert_load_data' => false,  # No inversion
      'floor_area_selection' => 'Whole Building',
      'file_dir' => '.',  # Adjust the path to where the CSV files are located
      'file_name' => 'leap_year_hourly_values.csv',
      'data_columns' => 1,
      'rows_to_skip' => 0,
      'unit_choice' => 'W'
    }

    result = run_measure(model, measure, runner, arguments)
    assert_equal("Success", result.value.valueName)
  end

  # Test with missing file
  def test_missing_file
    model, measure, runner = load_model_and_measure('example_model.osm')

    electric_equipment = model.getElectricEquipments.first

    # Arguments for electric equipment with a missing file
    arguments = {
      'load_object' => electric_equipment.handle.to_s,
      'replace_load_value' => true,
      'replace_schedules' => true,
      'invert_load_data' => false,  # No inversion
      'floor_area_selection' => 'None',
      'file_dir' => '.',  # Adjust the path to where the CSV files are located
      'file_name' => 'non_existent_file.csv',
      'data_columns' => 1,
      'rows_to_skip' => 0,
      'unit_choice' => 'kW'
    }

    # Check that the measure results in failure
    result = run_measure(model, measure, runner, arguments)
    assert_equal("Fail", result.value.valueName)
    assert_includes(result.errors.map(&:logMessage), "The file at path ./non_existent_file.csv doesn't exist.")
  end

  # Test loading arguments from measure_args.json
  def test_loading_arguments_from_json
    model, measure, runner = load_model_and_measure('example_model.osm')

    # Arguments for the first run (this will create the JSON file)
    arguments = {
      'load_object' => model.getElectricEquipments.first.handle.to_s,
      'replace_load_value' => true,
      'replace_schedules' => true,
      'invert_load_data' => false,  # No inversion
      'floor_area_selection' => 'None',
      'file_dir' => '.',  # Adjust the path to where the CSV files are located
      'file_name' => 'hourly_values.csv',
      'data_columns' => 1,
      'rows_to_skip' => 0,
      'unit_choice' => 'kW'
    }

    # Run the measure to create the JSON file
    result = run_measure(model, measure, runner, arguments)
    assert_equal("Success", result.value.valueName)

    # Now run the measure again, leaving file_dir and file_name blank to load from JSON
    arguments = {
      'load_object' => model.getElectricEquipments.first.handle.to_s,
      'replace_load_value' => true,
      'replace_schedules' => true,
      'invert_load_data' => false,  # No inversion
      'floor_area_selection' => 'None',
      'file_dir' => '',  # Leave blank to load from JSON
      'file_name' => '',  # Leave blank to load from JSON
      'data_columns' => 1,
      'rows_to_skip' => 0,
      'unit_choice' => ''  # Leave blank to load from JSON
    }

    result = run_measure(model, measure, runner, arguments)
    assert_equal("Success", result.value.valueName)
    assert_includes(result.info.map(&:logMessage), "Using previous file directory and name from JSON.")

  ensure
    # Clean up the JSON file after the test
    json_path = File.join(File.dirname(__FILE__), '../measure_args.json')
    FileUtils.rm_f(json_path)
  end

  # Test with inversion of load data
  def test_invert_load_data
    model, measure, runner = load_model_and_measure('example_model.osm')
  
    lights = model.getLightss.first
  
    # Arguments for lighting with inverted load data
    arguments = {
      'load_object' => lights.handle.to_s,
      'replace_load_value' => true,
      'replace_schedules' => true,
      'invert_load_data' => true,  # Invert the load data
      'floor_area_selection' => 'None',
      'file_dir' => '.',  # Adjust the path to where the CSV files are located
      'file_name' => 'inverted_hourly_values.csv',  # Use the new inverted_hourly_values.csv file
      'data_columns' => 1,
      'rows_to_skip' => 0,
      'unit_choice' => 'W'
    }
  
    result = run_measure(model, measure, runner, arguments)
    assert_equal("Success", result.value.valueName)
    assert_includes(result.warnings.map(&:logMessage), "The load data has been inverted because 'Invert Load Data' option was selected.")
  end  
end
