# Copyright 2025 Gabriel Miguel Flechas
#
# Licensed under the MIT License.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the \"Software\"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Based on a measure developed by NREL, however I can no longer locate the original source on the BCL to site it. 

require 'csv'
require 'json'

class AddAndApplyIntervalScheduleFromFile < OpenStudio::Measure::ModelMeasure

  def name
    return "Add and Apply ScheduleInterval or ScheduleFile From File"
  end

  def description
    return "This measure adds a schedule object from a file of interval data and can replace an existing schedule in the file with it. It also lets you specify which column from the CSV should be read so you can store multiple columns of data in one file. Allows beginning rows to be ignored in case there is header information present."
  end

  def modeler_description
    return "This measure adds a ScheduleInterval object from a user-specified .csv file. The measure supports hourly, 15 min, 5 min, and 1 min interval data for leap and non-leap years. The .csv file must contain only schedule values with 8760, 8784, 35040, 35136, 105120, 105408, 525600, or 527040 rows specified. See the example .csv files in the tests directory of this measure. It also lets you specify which column from the CSV should be read so you can store multiple columns of data in one file. Allows beginning rows to be ignored in case there is header information present."
  end

  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    sch_handles = OpenStudio::StringVector.new
    sch_display_names = OpenStudio::StringVector.new
    sch_handles << model.getBuilding.handle.to_s
    sch_display_names << ""

    schedules_hash = {}
    model.getSchedules.each do |sch|
      schedules_hash[sch.name.to_s] = sch
    end
    schedules_hash.sort.map do |sch_name, sch|
      sch_handles << sch.handle.to_s
      sch_display_names << sch_name
    end

    use_schedule_file = OpenStudio::Measure::OSArgument::makeBoolArgument('use_schedule_file', true)
    use_schedule_file.setDisplayName("Use a Schedule:File object instead of Schedule:Interval?")
    use_schedule_file.setDescription("Schedule:file will load faster. Turn off if the model crashes.")
    use_schedule_file.setDefaultValue(true)
    args << use_schedule_file

    replace_schedule = OpenStudio::Measure::OSArgument::makeBoolArgument('replace_schedule', true)
    replace_schedule.setDisplayName("Replace a schedule in the model?")
    replace_schedule.setDefaultValue(true)
    args << replace_schedule

    old_schedule = OpenStudio::Measure::OSArgument.makeChoiceArgument('old_schedule', sch_handles, sch_display_names, true)
    old_schedule.setDisplayName('If the above box is checked, choose the schedule to be replaced.')
    old_schedule.setDefaultValue("")
    args << old_schedule

    new_schedule_name = OpenStudio::Measure::OSArgument::makeStringArgument('new_schedule_name', true)
    new_schedule_name.setDisplayName("New Schedule Name (if you're not replacing an old schedule):")
    new_schedule_name.setDefaultValue('')
    args << new_schedule_name

    file_dir = OpenStudio::Measure::OSArgument.makeStringArgument('file_dir', false)
    file_dir.setDisplayName('Enter the path to the directory where the data file is stored (Leave this blank in subsequent runtime measures to reuse the same path):')
    file_dir.setDescription("Example: 'C:\\Projects\\data'")
    file_dir.setDefaultValue("")
    args << file_dir

    file_name = OpenStudio::Measure::OSArgument.makeStringArgument('file_name', false)
    file_name.setDisplayName('Enter the name of the CSV file (Leave this blank in subsequent runtime measures to reuse the same name):')
    file_name.setDescription("Example: 'values.csv'")
    file_name.setDefaultValue("")
    args << file_name

    data_column = OpenStudio::Measure::OSArgument.makeIntegerArgument("data_column", true)
    data_column.setDisplayName("Please enter an integer for the column from which you want to read data:")
    data_column.setDescription("(the first column is 1, the second is 2, and so on)")
    data_column.setDefaultValue(1)
    args << data_column

    rows_to_skip = OpenStudio::Measure::OSArgument.makeIntegerArgument("rows_to_skip", true)
    rows_to_skip.setDisplayName("Please enter the number of rows to skip before the data begins:")
    rows_to_skip.setDefaultValue(0)
    args << rows_to_skip

    unit_choice = OpenStudio::StringVector.new
    unit_choice << 'unitless'
    unit_choice << 'C'
    unit_choice << 'W'
    unit_choice << 'm/s'
    unit_choice << 'm^3/s'
    unit_choice << 'kg/s'
    unit_choice << 'Pa'
    unit_choice = OpenStudio::Measure::OSArgument::makeChoiceArgument('unit_choice', unit_choice, true)
    unit_choice.setDisplayName('Choose schedule units:')
    unit_choice.setDefaultValue('unitless')
    args << unit_choice

    return args
  end

  def expand_path_with_env(path)
    # Replace environment variables (e.g., %OneDrive%) with their values
    expanded_path = path.gsub(/%([^%]+)%/) do |match|
      env_var = match[1..-2] # Remove % signs
      ENV[env_var] || match  # Replace with environment value or keep as is if not found
    end
  
    # Resolve the expanded path to an absolute local path
    File.expand_path(expanded_path)
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    use_schedule_file = runner.getBoolArgumentValue("use_schedule_file", user_arguments)
    replace_schedule = runner.getBoolArgumentValue("replace_schedule", user_arguments)
    old_schedule = runner.getOptionalWorkspaceObjectChoiceValue('old_schedule', user_arguments, model)
    new_schedule_name = runner.getStringArgumentValue('new_schedule_name', user_arguments)
    file_dir = runner.getOptionalStringArgumentValue('file_dir', user_arguments)
    file_name = runner.getOptionalStringArgumentValue('file_name', user_arguments)
    data_column = runner.getIntegerArgumentValue("data_column", user_arguments)
    rows_to_skip = runner.getIntegerArgumentValue("rows_to_skip", user_arguments)
    unit_choice = runner.getOptionalStringArgumentValue('unit_choice', user_arguments)

    runner.registerInfo("Path: #{file_dir}, name: #{file_name}")

    args_json_path = File.join(File.dirname(__FILE__), '../../measure_args.json')

    if File.exist?(args_json_path)
      args_json = JSON.parse(File.read(args_json_path))

      if file_dir.to_s == "" && file_name.to_s == ""
        if args_json["file_dir"].to_s != "" && args_json["file_name"].to_s != ""
          file_dir = args_json["file_dir"]
          file_name = args_json["file_name"]
          runner.registerInfo("Using previous file directory and name from JSON: #{file_dir}, #{file_name}")
        else
          runner.registerError("Previous arguments JSON does not contain valid file directory and name.")
          return false
        end
      elsif file_dir.to_s == "" && file_name.to_s != ""
        file_dir = args_json["file_dir"]
        args_json["file_name"] = file_name
        runner.registerInfo("Using previous file directory from JSON: #{file_dir} and new file name: #{file_name}")
      elsif file_dir.to_s != "" && file_name.to_s == ""
        file_name = args_json["file_name"]
        args_json["file_dir"] = file_dir
        runner.registerInfo("Using new file directory: #{file_dir} and previous file name from JSON: #{file_name}")
      else
        args_json["file_dir"] = file_dir
        args_json["file_name"] = file_name
        runner.registerInfo("Using new file directory and name: #{file_dir}, #{file_name}")
      end

      File.open(args_json_path, "w") do |f|
        f.write(JSON.pretty_generate(args_json))
      end
      runner.registerInfo("Updated arguments JSON with new file directory and name.")
    else
      runner.registerInfo("Creating arguments file to be used in subsequent measures")
      args_json = {
        "replace_schedule" => replace_schedule,
        "old_schedule" => old_schedule,
        "new_schedule_name" => new_schedule_name,
        "file_dir" => file_dir,
        "file_name" => file_name,
        "data_column" => data_column,
        "rows_to_skip" => rows_to_skip,
        "unit_choice" => unit_choice
      }
      File.open(args_json_path, "w") do |f|
        f.write(JSON.pretty_generate(args_json))
      end
      runner.registerInfo("Saved current arguments to #{args_json_path}")
    end

    runner.registerInitialCondition("number of Existing Schedule objects = #{model.getSchedules.size}")

    if replace_schedule == true
      runner.registerInfo("Replacing the schedule in the model named - #{old_schedule.get.name.to_s}")
    end

    if replace_schedule != true
      if new_schedule_name == ''
        runner.registerError('Schedule name is blank. Input a schedule name or replace a schedule instead.')
        return false
      end
    end

    file_path = File.join(file_dir.to_s, file_name.to_s)
    file_path = expand_path_with_env(file_path)

    if !File.exist?(file_path)
      runner.registerError("The file at path #{file_path} doesn't exist.")
      return false
    else
      runner.registerInfo("Found the specified file at: #{file_path}")
    end

    csv_values = []
    CSV.foreach(file_path, headers: false, converters: :float).with_index(1) do |row, line|
      if line > rows_to_skip
        csv_values << row[data_column - 1]
      end
    end
    num_rows = csv_values.length
    runner.registerInfo("Found #{num_rows} rows in the CSV file.")

    interval = []
    if (num_rows == 8760) || (num_rows == 8784)
      interval = OpenStudio::Time.new(0, 1, 0)
      minutes_per_item = 60
    elsif (num_rows == 35040) || (num_rows == 35136)
      interval = OpenStudio::Time.new(0, 0, 15)
      minutes_per_item = 15
    elsif (num_rows == 105120) || (num_rows == 105408)
      interval = OpenStudio::Time.new(0, 0, 5)
      minutes_per_item = 5
    elsif (num_rows == 525600) || (num_rows == 527040)
      interval = OpenStudio::Time.new(0, 0, 1)
      minutes_per_item = 1
    else
      runner.registerError('This measure does not support non-hourly, non-15 min, non-5 min, or non-1 min interval data. Cast your values as 1-min (525,600 rows), 5-min (105,120 rows), 15-min (35,040 rows), or hourly (8,760 rows) interval data. See the values template.')
      return false
    end

    if use_schedule_file == true
      runner.registerInfo("Attempting to apply ScheduleFile using the CSV data")
      external_file = OpenStudio::Model::ExternalFile.getExternalFile(model, file_path)
      if external_file.is_initialized
        external_file = external_file.get
      else
        runner.registerError("Could not find the external file to use with ScheduleFile")
        return false
      end

      new_schedule = OpenStudio::Model::ScheduleFile.new(model, file_path, data_column, rows_to_skip)
      new_schedule.setMinutesperItem(minutes_per_item)
    else
      schedule_values = OpenStudio::Vector.new(num_rows, 0.0)
      csv_values.each_with_index do |csv_value, i|
        schedule_values[i] = csv_value
      end

      startDate = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(1), 1)
      timeseries = OpenStudio::TimeSeries.new(startDate, interval, schedule_values, "#{unit_choice}")
      new_schedule = OpenStudio::Model::ScheduleInterval::fromTimeSeries(timeseries, model)
      new_schedule = new_schedule.get
      if not new_schedule.initialized
        runner.registerError("Unable to make schedule from file at '#{file_path}'")
        return false
      end
    end

    num_rep_schs = 0
    if replace_schedule == true
      if new_schedule_name != ""
        runner.registerInfo("Creating a new schedule for the model named: #{new_schedule_name}")
        new_schedule.setName(new_schedule_name)
      else
        old_schedule = old_schedule.get
        new_schedule_name = "#{old_schedule.name}_interval"
        new_schedule.setName(new_schedule_name)
        runner.registerInfo("Using old schedule name to name new schedule: #{new_schedule_name}")
      end

      runner.registerInfo("Replacing the schedule from the model named: #{old_schedule.name.to_s}")
      sources = old_schedule.sources
      sources.each do |s|
        num_fields = s.numFields
        (0..num_fields - 1).each do |i|
          f = s.getField(i)
          if f.to_s == old_schedule.handle.to_s
            s.setPointer(i, new_schedule.handle)
            runner.registerInfo("Updated an occurrence of the old schedule in #{s.name}")
            num_rep_schs += 1
          end
        end
      end
    else
      if new_schedule_name != ""
        runner.registerInfo("Creating a new schedule for the model named: #{new_schedule_name}")
        new_schedule.setName(new_schedule_name)
      else
        runner.registerError("Please enter a name for the schedule or choose to replace a schedule instead")
        return false
      end
    end

    runner.registerFinalCondition("Added schedule #{new_schedule_name} to the model. Updated #{num_rep_schs} existing schedule pointers.")

    return true
  end
end

AddAndApplyIntervalScheduleFromFile.new.registerWithApplication
