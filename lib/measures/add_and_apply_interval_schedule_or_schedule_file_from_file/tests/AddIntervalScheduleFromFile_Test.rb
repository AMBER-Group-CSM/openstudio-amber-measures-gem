require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'
require 'json'

class AddAndApplyIntervalScheduleFromFile_Test < MiniTest::Test

  def setup
    # Create a temporary directory for the test files
    @temp_dir = File.join(File.dirname(__FILE__), 'temp')
    FileUtils.mkdir_p(@temp_dir)
    @json_path = File.join(@temp_dir, 'measure_args.json')
  end

  def teardown
    # Clean up the temporary directory
    FileUtils.rm_rf(@temp_dir)
  end

  def setup_test(model)
    schedule_ruleset = OpenStudio::Model::ScheduleRuleset.new(model)
    schedule_ruleset.setName('Dummy Schedule')
    default_day_schedule = schedule_ruleset.defaultDaySchedule
    default_day_schedule.addValue(OpenStudio::Time.new(0, 24, 0, 0), 1.0)
    schedule_rule = OpenStudio::Model::ScheduleRule.new(schedule_ruleset)
    day_schedule = schedule_rule.daySchedule
    day_schedule.addValue(OpenStudio::Time.new(0, 24, 0, 0), 1.0)
    return schedule_ruleset
  end

  def test_number_of_arguments_and_argument_names
    measure = AddAndApplyIntervalScheduleFromFile.new
    model = OpenStudio::Model::Model.new
    arguments = measure.arguments(model)
    assert_equal(9, arguments.size)
    assert_equal('use_schedule_file', arguments[0].name)
    assert_equal('replace_schedule', arguments[1].name)
    assert_equal('old_schedule', arguments[2].name)
    assert_equal('new_schedule_name', arguments[3].name)
    assert_equal('file_dir', arguments[4].name)
    assert_equal('file_name', arguments[5].name)
    assert_equal('data_column', arguments[6].name)
    assert_equal('rows_to_skip', arguments[7].name)
    assert_equal('unit_choice', arguments[8].name)
  end

  def test_good_hourly_values_with_schedule_file
    measure = AddAndApplyIntervalScheduleFromFile.new
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    model = OpenStudio::Model::Model.new
    setup_test(model)
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure::OSArgumentMap.new

    use_schedule_file = arguments[0].clone
    assert(use_schedule_file.setValue(true))
    argument_map['use_schedule_file'] = use_schedule_file

    replace_schedule = arguments[1].clone
    assert(replace_schedule.setValue(false))
    argument_map['replace_schedule'] = replace_schedule

    old_schedule = arguments[2].clone
    assert(old_schedule.setValue(model.getSchedules.first.handle.to_s))
    argument_map['old_schedule'] = old_schedule

    new_schedule_name = arguments[3].clone
    assert(new_schedule_name.setValue('Hourly Values'))
    argument_map['new_schedule_name'] = new_schedule_name

    file_dir = arguments[4].clone
    assert(file_dir.setValue(File.dirname(__FILE__)))
    argument_map['file_dir'] = file_dir

    file_name = arguments[5].clone
    csv_file = 'hourly_values.csv'
    assert(File.exist?(File.join(File.dirname(__FILE__), csv_file)))
    assert(file_name.setValue(csv_file))
    argument_map['file_name'] = file_name

    data_column = arguments[6].clone
    assert(data_column.setValue(1))
    argument_map['data_column'] = data_column

    rows_to_skip = arguments[7].clone
    assert(rows_to_skip.setValue(0))
    argument_map['rows_to_skip'] = rows_to_skip

    unit_choice = arguments[8].clone
    assert(unit_choice.setValue('W'))
    argument_map['unit_choice'] = unit_choice

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)

    assert(result.value.valueName == 'Success')
    assert(result.warnings.size == 0)
    assert(result.errors.size == 0)
  end

  def test_good_hourly_values_with_schedule_interval
    measure = AddAndApplyIntervalScheduleFromFile.new
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    model = OpenStudio::Model::Model.new
    setup_test(model)
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure::OSArgumentMap.new

    use_schedule_file = arguments[0].clone
    assert(use_schedule_file.setValue(false))
    argument_map['use_schedule_file'] = use_schedule_file

    replace_schedule = arguments[1].clone
    assert(replace_schedule.setValue(false))
    argument_map['replace_schedule'] = replace_schedule

    old_schedule = arguments[2].clone
    assert(old_schedule.setValue(model.getSchedules.first.handle.to_s))
    argument_map['old_schedule'] = old_schedule

    new_schedule_name = arguments[3].clone
    assert(new_schedule_name.setValue('Hourly Values'))
    argument_map['new_schedule_name'] = new_schedule_name

    file_dir = arguments[4].clone
    assert(file_dir.setValue(File.dirname(__FILE__)))
    argument_map['file_dir'] = file_dir

    file_name = arguments[5].clone
    csv_file = 'hourly_values.csv'
    assert(File.exist?(File.join(File.dirname(__FILE__), csv_file)))
    assert(file_name.setValue(csv_file))
    argument_map['file_name'] = file_name

    data_column = arguments[6].clone
    assert(data_column.setValue(1))
    argument_map['data_column'] = data_column

    rows_to_skip = arguments[7].clone
    assert(rows_to_skip.setValue(0))
    argument_map['rows_to_skip'] = rows_to_skip

    unit_choice = arguments[8].clone
    assert(unit_choice.setValue('W'))
    argument_map['unit_choice'] = unit_choice

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)

    assert(result.value.valueName == 'Success')
    assert(result.warnings.size == 0)
    assert(result.errors.size == 0)
  end

  def test_bad_hourly_values_with_schedule_file
    measure = AddAndApplyIntervalScheduleFromFile.new
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    model = OpenStudio::Model::Model.new
    setup_test(model)
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure::OSArgumentMap.new

    use_schedule_file = arguments[0].clone
    assert(use_schedule_file.setValue(true))
    argument_map['use_schedule_file'] = use_schedule_file

    replace_schedule = arguments[1].clone
    assert(replace_schedule.setValue(false))
    argument_map['replace_schedule'] = replace_schedule

    old_schedule = arguments[2].clone
    assert(old_schedule.setValue(model.getSchedules.first.handle.to_s))
    argument_map['old_schedule'] = old_schedule

    new_schedule_name = arguments[3].clone
    assert(new_schedule_name.setValue('Bad Hourly Values'))
    argument_map['new_schedule_name'] = new_schedule_name

    file_dir = arguments[4].clone
    assert(file_dir.setValue(File.dirname(__FILE__)))
    argument_map['file_dir'] = file_dir

    file_name = arguments[5].clone
    csv_file = 'bad_hourly_values.csv'
    assert(File.exist?(File.join(File.dirname(__FILE__), csv_file)))
    assert(file_name.setValue(csv_file))
    argument_map['file_name'] = file_name

    data_column = arguments[6].clone
    assert(data_column.setValue(1))
    argument_map['data_column'] = data_column

    rows_to_skip = arguments[7].clone
    assert(rows_to_skip.setValue(0))
    argument_map['rows_to_skip'] = rows_to_skip

    unit_choice = arguments[8].clone
    assert(unit_choice.setValue('W'))
    argument_map['unit_choice'] = unit_choice

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)

    assert(result.value.valueName == 'Fail')
    assert(result.errors.size > 0)
  end

  def test_bad_hourly_values_with_schedule_interval
    measure = AddAndApplyIntervalScheduleFromFile.new
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    model = OpenStudio::Model::Model.new
    setup_test(model)
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure::OSArgumentMap.new

    use_schedule_file = arguments[0].clone
    assert(use_schedule_file.setValue(false))
    argument_map['use_schedule_file'] = use_schedule_file

    replace_schedule = arguments[1].clone
    assert(replace_schedule.setValue(false))
    argument_map['replace_schedule'] = replace_schedule

    old_schedule = arguments[2].clone
    assert(old_schedule.setValue(model.getSchedules.first.handle.to_s))
    argument_map['old_schedule'] = old_schedule

    new_schedule_name = arguments[3].clone
    assert(new_schedule_name.setValue('Bad Hourly Values'))
    argument_map['new_schedule_name'] = new_schedule_name

    file_dir = arguments[4].clone
    assert(file_dir.setValue(File.dirname(__FILE__)))
    argument_map['file_dir'] = file_dir

    file_name = arguments[5].clone
    csv_file = 'bad_hourly_values.csv'
    assert(File.exist?(File.join(File.dirname(__FILE__), csv_file)))
    assert(file_name.setValue(csv_file))
    argument_map['file_name'] = file_name

    data_column = arguments[6].clone
    assert(data_column.setValue(1))
    argument_map['data_column'] = data_column

    rows_to_skip = arguments[7].clone
    assert(rows_to_skip.setValue(0))
    argument_map['rows_to_skip'] = rows_to_skip

    unit_choice = arguments[8].clone
    assert(unit_choice.setValue('W'))
    argument_map['unit_choice'] = unit_choice

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)

    assert(result.value.valueName == 'Fail')
    assert(result.errors.size > 0)
  end

  def test_bad_path_with_schedule_file
    measure = AddAndApplyIntervalScheduleFromFile.new
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    model = OpenStudio::Model::Model.new
    setup_test(model)
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure::OSArgumentMap.new

    use_schedule_file = arguments[0].clone
    assert(use_schedule_file.setValue(true))
    argument_map['use_schedule_file'] = use_schedule_file

    replace_schedule = arguments[1].clone
    assert(replace_schedule.setValue(false))
    argument_map['replace_schedule'] = replace_schedule

    old_schedule = arguments[2].clone
    assert(old_schedule.setValue(model.getSchedules.first.handle.to_s))
    argument_map['old_schedule'] = old_schedule

    new_schedule_name = arguments[3].clone
    assert(new_schedule_name.setValue('Hourly Values'))
    argument_map['new_schedule_name'] = new_schedule_name

    file_dir = arguments[4].clone
    assert(file_dir.setValue(File.dirname(__FILE__)))
    argument_map['file_dir'] = file_dir

    file_name = arguments[5].clone
    assert(file_name.setValue('does_not_exist.csv'))
    argument_map['file_name'] = file_name

    data_column = arguments[6].clone
    assert(data_column.setValue(1))
    argument_map['data_column'] = data_column

    rows_to_skip = arguments[7].clone
    assert(rows_to_skip.setValue(0))
    argument_map['rows_to_skip'] = rows_to_skip

    unit_choice = arguments[8].clone
    assert(unit_choice.setValue('W'))
    argument_map['unit_choice'] = unit_choice

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)

    assert(result.value.valueName == 'Fail')
    assert(result.errors.size > 0)
  end

  def test_bad_path_with_schedule_interval
    measure = AddAndApplyIntervalScheduleFromFile.new
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    model = OpenStudio::Model::Model.new
    setup_test(model)
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure::OSArgumentMap.new

    use_schedule_file = arguments[0].clone
    assert(use_schedule_file.setValue(false))
    argument_map['use_schedule_file'] = use_schedule_file

    replace_schedule = arguments[1].clone
    assert(replace_schedule.setValue(false))
    argument_map['replace_schedule'] = replace_schedule

    old_schedule = arguments[2].clone
    assert(old_schedule.setValue(model.getSchedules.first.handle.to_s))
    argument_map['old_schedule'] = old_schedule

    new_schedule_name = arguments[3].clone
    assert(new_schedule_name.setValue('Hourly Values'))
    argument_map['new_schedule_name'] = new_schedule_name

    file_dir = arguments[4].clone
    assert(file_dir.setValue(File.dirname(__FILE__)))
    argument_map['file_dir'] = file_dir

    file_name = arguments[5].clone
    assert(file_name.setValue('does_not_exist.csv'))
    argument_map['file_name'] = file_name

    data_column = arguments[6].clone
    assert(data_column.setValue(1))
    argument_map['data_column'] = data_column

    rows_to_skip = arguments[7].clone
    assert(rows_to_skip.setValue(0))
    argument_map['rows_to_skip'] = rows_to_skip

    unit_choice = arguments[8].clone
    assert(unit_choice.setValue('W'))
    argument_map['unit_choice'] = unit_choice

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)

    assert(result.value.valueName == 'Fail')
    assert(result.errors.size > 0)
  end

  def test_load_both_from_json
    json_data = {
      "replace_schedule" => false,
      "old_schedule" => "",
      "new_schedule_name" => "Loaded From JSON",
      "file_dir" => File.dirname(__FILE__),
      "file_name" => 'hourly_values.csv',
      "data_column" => 1,
      "rows_to_skip" => 0,
      "unit_choice" => 'W'
    }
    File.open(@json_path, 'w') { |f| f.write(JSON.pretty_generate(json_data)) }

    measure = AddAndApplyIntervalScheduleFromFile.new
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    model = OpenStudio::Model::Model.new
    setup_test(model)
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure::OSArgumentMap.new

    use_schedule_file = arguments[0].clone
    assert(use_schedule_file.setValue(true))
    argument_map['use_schedule_file'] = use_schedule_file

    replace_schedule = arguments[1].clone
    assert(replace_schedule.setValue(false))
    argument_map['replace_schedule'] = replace_schedule

    old_schedule = arguments[2].clone
    assert(old_schedule.setValue(model.getSchedules.first.handle.to_s))
    argument_map['old_schedule'] = old_schedule

    new_schedule_name = arguments[3].clone
    assert(new_schedule_name.setValue('Loaded From JSON'))
    argument_map['new_schedule_name'] = new_schedule_name

    file_dir = arguments[4].clone
    assert(file_dir.setValue(''))
    argument_map['file_dir'] = file_dir

    file_name = arguments[5].clone
    assert(file_name.setValue(''))
    argument_map['file_name'] = file_name

    data_column = arguments[6].clone
    assert(data_column.setValue(1))
    argument_map['data_column'] = data_column

    rows_to_skip = arguments[7].clone
    assert(rows_to_skip.setValue(0))
    argument_map['rows_to_skip'] = rows_to_skip

    unit_choice = arguments[8].clone
    assert(unit_choice.setValue('W'))
    argument_map['unit_choice'] = unit_choice

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)

    assert(result.value.valueName == 'Success')
    assert(result.warnings.size == 0)
    assert(result.errors.size == 0)
  end

  def test_load_one_from_json
    json_data = {
      "replace_schedule" => false,
      "old_schedule" => "",
      "new_schedule_name" => "Loaded From JSON",
      "file_dir" => File.dirname(__FILE__),
      "file_name" => 'hourly_values.csv',
      "data_column" => 1,
      "rows_to_skip" => 0,
      "unit_choice" => 'W'
    }
    File.open(@json_path, 'w') { |f| f.write(JSON.pretty_generate(json_data)) }

    measure = AddAndApplyIntervalScheduleFromFile.new
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    model = OpenStudio::Model::Model.new
    setup_test(model)
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure::OSArgumentMap.new

    use_schedule_file = arguments[0].clone
    assert(use_schedule_file.setValue(true))
    argument_map['use_schedule_file'] = use_schedule_file

    replace_schedule = arguments[1].clone
    assert(replace_schedule.setValue(false))
    argument_map['replace_schedule'] = replace_schedule

    old_schedule = arguments[2].clone
    assert(old_schedule.setValue(model.getSchedules.first.handle.to_s))
    argument_map['old_schedule'] = old_schedule

    new_schedule_name = arguments[3].clone
    assert(new_schedule_name.setValue('Loaded From JSON'))
    argument_map['new_schedule_name'] = new_schedule_name

    file_dir = arguments[4].clone
    assert(file_dir.setValue(''))
    argument_map['file_dir'] = file_dir

    file_name = arguments[5].clone
    assert(file_name.setValue('hourly_values.csv'))
    argument_map['file_name'] = file_name

    data_column = arguments[6].clone
    assert(data_column.setValue(1))
    argument_map['data_column'] = data_column

    rows_to_skip = arguments[7].clone
    assert(rows_to_skip.setValue(0))
    argument_map['rows_to_skip'] = rows_to_skip

    unit_choice = arguments[8].clone
    assert(unit_choice.setValue('W'))
    argument_map['unit_choice'] = unit_choice

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)

    assert(result.value.valueName == 'Success')
    assert(result.warnings.size == 0)
    assert(result.errors.size == 0)
  end

  def test_load_another_one_from_json
    json_data = {
      "replace_schedule" => false,
      "old_schedule" => "",
      "new_schedule_name" => "Loaded From JSON",
      "file_dir" => File.dirname(__FILE__),
      "file_name" => 'hourly_values.csv',
      "data_column" => 1,
      "rows_to_skip" => 0,
      "unit_choice" => 'W'
    }
    File.open(@json_path, 'w') { |f| f.write(JSON.pretty_generate(json_data)) }

    measure = AddAndApplyIntervalScheduleFromFile.new
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    model = OpenStudio::Model::Model.new
    setup_test(model)
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure::OSArgumentMap.new

    use_schedule_file = arguments[0].clone
    assert(use_schedule_file.setValue(true))
    argument_map['use_schedule_file'] = use_schedule_file

    replace_schedule = arguments[1].clone
    assert(replace_schedule.setValue(false))
    argument_map['replace_schedule'] = replace_schedule

    old_schedule = arguments[2].clone
    assert(old_schedule.setValue(model.getSchedules.first.handle.to_s))
    argument_map['old_schedule'] = old_schedule

    new_schedule_name = arguments[3].clone
    assert(new_schedule_name.setValue('Loaded From JSON'))
    argument_map['new_schedule_name'] = new_schedule_name

    file_dir = arguments[4].clone
    assert(file_dir.setValue(File.dirname(__FILE__)))
    argument_map['file_dir'] = file_dir

    file_name = arguments[5].clone
    assert(file_name.setValue(''))
    argument_map['file_name'] = file_name

    data_column = arguments[6].clone
    assert(data_column.setValue(1))
    argument_map['data_column'] = data_column

    rows_to_skip = arguments[7].clone
    assert(rows_to_skip.setValue(0))
    argument_map['rows_to_skip'] = rows_to_skip

    unit_choice = arguments[8].clone
    assert(unit_choice.setValue('W'))
    argument_map['unit_choice'] = unit_choice

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)

    assert(result.value.valueName == 'Success')
    assert(result.warnings.size == 0)
    assert(result.errors.size == 0)
  end
end
