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

require 'csv'
require 'json'

class AddAndApplyLoadAndScheduleFromFile < OpenStudio::Measure::ModelMeasure

  # Human-readable name of the measure
  def name
    return "Add and Apply Load and Schedule from File"
  end

  # Human-readable description of the measure
  def description
    return "This measure imports electric or lighting load data from a CSV file and applies it to a selected load in the OpenStudio model as a ScheduleInterval. The measure offers options to normalize the data by floor area, invert the data if it represents energy consumption as negative values, and replace the existing power or power intensity with the maximum value from the CSV data."
  end

  # Detailed description of the measure for the modeler
  def modeler_description
    return "This measure enhances the flexibility of energy modeling by allowing users to apply real-world load data to their OpenStudio models. It reads a specified column of electric or lighting load data from a CSV file and processes it to create a ScheduleInterval for a selected load object (either ElectricEquipment or Lights). Key features include the ability to normalize the data by the maximum value in the CSV column, adjust for floor area (either the whole building or a specific level), and replace existing design-level values with the maximum value from the CSV.
    Additionally, the measure provides an option to invert the load data, which is particularly useful if the data is reported as negative values when the load is consuming energy, such as in some sub-metered data sets. The measure handles various data intervals, such as hourly, 15-minute, or 1-minute data, and includes comprehensive error handling and logging to ensure the user is informed of any issues or actions taken during the measure's execution.
    The measure also supports the reuse of file paths and names across multiple runs by storing user-defined paths and filenames in a JSON file, making it easier to apply consistent settings across different projects or scenarios."
  end

  # Define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # Load object
    load_object_choices = OpenStudio::StringVector.new
    load_object_display_names = OpenStudio::StringVector.new

    # Get electric equipment loads
    model.getElectricEquipmentDefinitions.each do |equip|
      load_object_choices << equip.handle.to_s
      load_object_display_names << equip.name.get
    end

    # Get lighting loads
    model.getLightsDefinitions.each do |light|
      load_object_choices << light.handle.to_s
      load_object_display_names << light.name.get
    end

    load_object = OpenStudio::Measure::OSArgument::makeChoiceArgument('load_object', load_object_choices, load_object_display_names, true)
    load_object.setDisplayName('Select the Load Object:')
    load_object.setDescription('Select the electric or lighting load object from the model to which the schedule will be applied.')
    load_object.setDefaultValue(load_object_choices[0]) unless load_object_choices.empty?
    args << load_object

    # Replace Load Value
    replace_load_value = OpenStudio::Measure::OSArgument::makeBoolArgument('replace_load_value', true)
    replace_load_value.setDisplayName('Replace existing design/watts per floor area')
    replace_load_value.setDescription('If checked, this will replace the existing design value or watts per floor area with the maximum value from the CSV data.')
    replace_load_value.setDefaultValue(true)
    args << replace_load_value

    # Replace Schedules
    replace_schedules = OpenStudio::Measure::OSArgument::makeBoolArgument('replace_schedules', true)
    replace_schedules.setDisplayName('Override schedules associated with the load')
    replace_schedules.setDescription('If checked, this will override the existing schedule associated with the selected load with the new schedule created from the CSV data.')
    replace_schedules.setDefaultValue(true)
    args << replace_schedules

    # Invert Load Data
    invert_load_data = OpenStudio::Measure::OSArgument::makeBoolArgument('invert_load_data', true)
    invert_load_data.setDisplayName('Invert Load Data')
    invert_load_data.setDescription('Check if your sub-metered data is reported as a negative value when the load is consuming energy.')
    invert_load_data.setDefaultValue(false)
    args << invert_load_data

    # Floor Area Selection
    floor_area_selection = OpenStudio::Measure::OSArgument::makeChoiceArgument('floor_area_selection', ['None', 'Whole Building', 'For a Level'], true)
    floor_area_selection.setDisplayName('Normalize by Floor Area')
    floor_area_selection.setDescription('Choose whether to normalize the load data by the floor area of the whole building or a specific level.')
    floor_area_selection.setDefaultValue('None')
    args << floor_area_selection

    # Level Selection
    level_selection_choices = OpenStudio::StringVector.new
    model.getBuildingStorys.each do |story|
      level_selection_choices << story.name.get
    end
    level_selection = OpenStudio::Measure::OSArgument::makeChoiceArgument('level_selection', level_selection_choices, false)
    level_selection.setDisplayName('Select the Level:')
    level_selection.setDescription('Select the specific level of the building if you have chosen to normalize the load data by floor area for a particular level.')
    level_selection.setDefaultValue(level_selection_choices[0]) unless level_selection_choices.empty?
    args << level_selection

    # Directory of the file
    file_dir = OpenStudio::Measure::OSArgument::makeStringArgument('file_dir', false)
    file_dir.setDisplayName('Enter the path to the directory where the data file is stored')
    file_dir.setDescription("Specify the directory path where the CSV data file is located. Leave this blank in subsequent runtime measures to reuse the same path. Example: 'C:\\Projects\\data'")
    file_dir.setDefaultValue("")
    args << file_dir

    # File name
    file_name = OpenStudio::Measure::OSArgument::makeStringArgument('file_name', false)
    file_name.setDisplayName('Enter the name of the CSV file')
    file_name.setDescription("Specify the name of the CSV file containing the load data. Leave this blank in subsequent runtime measures to reuse the same file name. Example: 'values.csv'")
    file_name.setDefaultValue("")
    args << file_name

    # Data column
    data_columns = OpenStudio::Measure::OSArgument::makeIntegerArgument('data_columns', true)
    data_columns.setDisplayName('Data Column in the CSV File')
    data_columns.setDescription('Specify the column number in the CSV file that contains the load data to be applied.')
    data_columns.setDefaultValue(1)
    args << data_columns

    # Rows to skip
    rows_to_skip = OpenStudio::Measure::OSArgument::makeIntegerArgument('rows_to_skip', true)
    rows_to_skip.setDisplayName('Rows to Skip in the CSV File')
    rows_to_skip.setDescription('Specify the number of rows to skip at the beginning of the CSV file. This is useful if the file has a header row or other non-data rows.')
    rows_to_skip.setDefaultValue(0)
    args << rows_to_skip

    # Unit Choice
    unit_choice = OpenStudio::Measure::OSArgument::makeChoiceArgument('unit_choice', ['','W', 'kW', 'BTU/hr'], true)
    unit_choice.setDisplayName('Units of the data in the CSV column')
    unit_choice.setDescription('Specify the units of the load data in the CSV file. This can be left blank, or you can select from Watts (W), Kilowatts (kW), or BTU/hr.')
    unit_choice.setDefaultValue('')
    args << unit_choice

    return args
  end

  def expand_path_with_env(path)
    # Replace environment variables (e.g., %OneDrive%) with their values
    expanded_path = path.gsub(/%([^%]+)%/) do |match|
      env_var = match[1..-2] # Remove % signs
      (ENV[env_var]).to_s || match.to_s  # Replace with environment value or keep as is if not found
    end
  
    # Resolve the expanded path to an absolute local path
    File.expand_path(expanded_path)
  end

  # Define the run method that will execute the measure
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # Validate the user arguments
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # Extract arguments
    load_object = runner.getOptionalWorkspaceObjectChoiceValue("load_object", user_arguments,model)
    replace_load_value = runner.getBoolArgumentValue("replace_load_value", user_arguments)
    replace_schedules = runner.getBoolArgumentValue("replace_schedules", user_arguments)
    floor_area_selection = runner.getStringArgumentValue("floor_area_selection", user_arguments)
    level_selection = runner.getStringArgumentValue("level_selection", user_arguments)
    file_dir = runner.getOptionalStringArgumentValue('file_dir', user_arguments)
    file_name = runner.getOptionalStringArgumentValue('file_name', user_arguments)
    data_columns = runner.getIntegerArgumentValue("data_columns", user_arguments)
    rows_to_skip = runner.getIntegerArgumentValue("rows_to_skip", user_arguments)
    unit_choice = runner.getOptionalStringArgumentValue('unit_choice', user_arguments)
    invert_load_data = runner.getBoolArgumentValue("invert_load_data", user_arguments)

    runner.registerInfo("Path: #{file_dir}, name: #{file_name}")

    # Define the path for the JSON file to store arguments
    # json_path = json_path.to_s.empty? ? File.join(File.dirname(__FILE__), '../../measure_args.json') : json_path.to_s # this line is an alternative for json_path
    # json_path = File.join(File.dirname(__FILE__), '../../measure_args.json') # this line is an alternative for json_path
    json_path = File.join(File.dirname(__FILE__), 'measure_args.json')
    json_path = json_path.to_s

    # Check if the JSON file exists and update arguments accordingly
    if File.exist?(json_path)
      args_json = JSON.parse(File.read(json_path))

      if file_dir.to_s == "" && file_name.to_s == ""
        if args_json["file_dir"].to_s != "" && args_json["file_name"].to_s != ""
          file_dir = args_json["file_dir"]
          file_name = args_json["file_name"]
          runner.registerInfo("Using previous file directory and name from JSON.")
          runner.registerInfo("Directory: #{file_dir}")
          runner.registerInfo("File Name: #{file_name}")
        else
          runner.registerError("Previous arguments JSON does not contain valid file directory and name.")
          return false
        end
      elsif file_dir.to_s == "" && file_name.to_s != ""
        file_dir = args_json["file_dir"]
        args_json["file_name"] = file_name
        runner.registerInfo("Using previous file directory from JSON and new file name.")
        runner.registerInfo("Directory: #{file_dir}")
        runner.registerInfo("File Name: #{file_name}")
      elsif file_dir.to_s != "" && file_name.to_s == ""
        file_name = args_json["file_name"]
        args_json["file_dir"] = file_dir
        runner.registerInfo("Using new file directory and previous file name from JSON.")
        runner.registerInfo("Directory: #{file_dir}")
        runner.registerInfo("File Name: #{file_name}")
      else
        args_json["file_dir"] = file_dir
        args_json["file_name"] = file_name
        runner.registerInfo("Adding new file directory and name from JSON.")
        runner.registerInfo("Directory: #{file_dir}")
        runner.registerInfo("File Name: #{file_name}")
      end

      # Handle unit_choice retrieval and update
      if unit_choice.to_s == ""
        if args_json["unit_choice"].to_s != ""
          unit_choice = args_json["unit_choice"]
          runner.registerInfo("Using previous unit choice from JSON.")
          runner.registerInfo("Unit Choice: #{unit_choice}")
        else
          unit_choice = 'W'
          runner.registerWarning("No unit choice provided. Defaulting to 'W'. Please update your measure arguments if this is incorrect.")
        end
      else
        args_json["unit_choice"] = unit_choice
      end

      # Update the JSON file with new or retained values
      File.open(json_path, "w") do |f|
        f.write(JSON.pretty_generate(args_json))
      end
      runner.registerInfo("Updated arguments JSON with new file directory, name, and unit choice.")
    else
      runner.registerInfo("Creating arguments file to be used in subsequent measures")
      args_json = {
        "file_dir" => file_dir,
        "file_name" => file_name,
        "data_columns" => data_columns,
        "rows_to_skip" => rows_to_skip,
        "unit_choice" => unit_choice.to_s.empty? ? 'W' : unit_choice # Default to 'W' if empty
      }

      File.open(json_path, "w") do |f|
        f.write(JSON.pretty_generate(args_json))
      end

      if unit_choice.to_s == ""
        unit_choice = 'W'
        runner.registerWarning("No unit choice provided. Defaulting to 'W'. Please update your measure arguments if this is incorrect.")
      end
    end


    # Construct file path
    file_path = File.join(file_dir.to_s, file_name.to_s)
    file_path = expand_path_with_env(file_path)

    # Read CSV file and process data
    if !File.exist?(file_path)
      runner.registerError("The file at path #{file_path} doesn't exist.")
      return false
    else
      runner.registerInfo("Found the specified file at: #{file_path}")
    end

    # Read and store CSV values
    csv_values = []
    CSV.foreach(file_path, headers: false, converters: :float).with_index(1) do |row, line|
      if line > rows_to_skip
        csv_values << row[data_columns - 1]
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
      runner.registerError('This measure does not support non-hourly, non-15 min, non-5 min, or non-1 min interval data. Cast your values as 1-min (525,600 rows), 5-min (105,120 rows), 15-min (35,040 rows), or hourly (8,760 rows) interval data (or the leap year equivalent intervals). See the values template.')
      return false
    end

    # Invert the load data if the option is selected
    if invert_load_data
      csv_values.map! { |val| val * -1 }
      runner.registerWarning("The load data has been inverted because 'Invert Load Data' option was selected.")
    end

    # Initialize variables for statistics
    sum = 0.0
    sum_of_squares = 0.0
    negative_value_count = 0

    # Process Data
    csv_values.each_with_index do |val, i|
      # Handle negative values by setting them to zero
      if val < 0
        csv_values[i] = 0
        negative_value_count += 1
      end
      
      # For calculating statistics
      sum += csv_values[i]
      sum_of_squares += csv_values[i] ** 2
    end

    # Register warning if any negative values were encountered
    if negative_value_count > 0
      runner.registerWarning("#{negative_value_count}/#{csv_values.size} rows contained negative values and were set to zero. Check your data if you didn't expect it to have zeros.")
    end

    # Calculate the max value after handling negative values
    max_value = csv_values.max

    # Calculate statistics
    mean_value = sum / csv_values.size
    variance = (sum_of_squares / csv_values.size) - (mean_value ** 2)
    std_dev = Math.sqrt(variance)
    sorted_values = csv_values.sort
    median_value = sorted_values.size.odd? ? sorted_values[sorted_values.size / 2] : (sorted_values[sorted_values.size / 2 - 1] + sorted_values[sorted_values.size / 2]) / 2.0
    min_value = sorted_values.first

    # Register statistics
    runner.registerInfo("Data statistics before normalization (check for any unexpected outliers or variance):")
    runner.registerInfo(" - Maximum value: #{max_value.round(3)} #{unit_choice.to_s}")
    runner.registerInfo(" - Minimum value: #{min_value.round(3)} #{unit_choice.to_s}")
    runner.registerInfo(" - Mean value: #{mean_value.round(3)} #{unit_choice.to_s}")
    runner.registerInfo(" - Median value: #{median_value.round(3)} #{unit_choice.to_s}")
    runner.registerInfo(" - Standard deviation: #{std_dev.round(3)} #{unit_choice.to_s}")

    # Normalize the data based on the max value
    normalized_data = csv_values.map { |val| val / max_value }
    runner.registerInfo("Normalized data based on the maximum value.")


    # Unit Conversion: Convert the max value to watts if necessary
    case unit_choice.to_s
    when 'kW'
      max_value = max_value * 1000
      runner.registerInfo("Converted maximum value from kW to watts: #{max_value.round(3)} W.")
    when 'BTU/hr'
      max_value = max_value * 0.29307107
      runner.registerInfo("Converted maximum value from BTU/hr to watts: #{max_value.round(3)} W.")
    else
      runner.registerInfo("No conversion needed, maximum value in watts: #{max_value.round(3)} W.")
    end


    # Normalize data by floor area if selected
    if floor_area_selection != 'None'
      if floor_area_selection == 'Whole Building'
        floor_area = model.getBuilding.floorArea
        max_value = max_value / floor_area
        runner.registerInfo("Calculated the power intensity using the floor area of the whole building (#{floor_area.round(1)} m^2), #{max_value.round(3)} W/m^2")
      else
        level = model.getBuildingStoryByName(level_selection).get
        if not level.to_BuildingStory.empty?
          # have to calculate floor area from the individual spaces
          # runner.registerInfo("Level #{level.name.get} has #{level.spaces.length} spaces")
          floor_area = 0.0
          level.spaces.each do |space|
            # runner.registerInfo("Space #{space.name.get} part of floor area: #{space.partofTotalFloorArea}")
            if space.partofTotalFloorArea
              # runner.registerInfo("Space area #{space.floorArea.to_f}")
              floor_area += space.floorArea.to_f
            end
          end
          max_value = max_value / floor_area
        runner.registerInfo("Calculated the power intensity using the floor area of the selected level (#{floor_area.round(1)} m^2): #{level_selection}, #{max_value.round(3)} W/m^2")
        else
          runner.registerError("Selected building story not found.")
          return false
        end
      end
      # normalized_data.map! { |val| val / floor_area } if floor_area
    end

    normalized_data_vector = OpenStudio::Vector.new(normalized_data.size, 0.0) # Create a vector of the appropriate size
    normalized_data.each_with_index do |val, i|
      normalized_data_vector[i] = val # Populate the vector with your normalized data
    end
    # Create a new ScheduleInterval with the normalized data
    startDate = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(1), 1)
    # interval = OpenStudio::Time.new(1, 0)
    timeseries = OpenStudio::TimeSeries.new(startDate, interval, normalized_data_vector, unit_choice.to_s)
    new_schedule = OpenStudio::Model::ScheduleInterval::fromTimeSeries(timeseries, model).get

    # Set the name of the ScheduleInterval based on the load object's name
    schedule_name = "#{load_object.get.name.get.to_s} - Data Loaded Schedule"
    new_schedule.setName(schedule_name)

    runner.registerInfo("Created a new ScheduleInterval named '#{schedule_name}' with the normalized data.")

    # Old version using direct loads and not definitions
    # Find the selected load in the model
    # Check if the object is valid before attempting to cast it
    # if load_object.is_initialized
    #   if not load_object.get.to_Lights.empty?
    #     selected_load = load_object.get.to_Lights.get
    #     runner.registerInfo("Found lighting load: #{selected_load.name.get}")
    #   elsif not load_object.get.to_ElectricEquipment.empty?
    #     selected_load = load_object.get.to_ElectricEquipment.get
    #     runner.registerInfo("Found electric equipment load: #{selected_load.name.get}")
    #   else
    #     runner.registerError("Incompatible load passed to the measure. This is likely a result of a bug in this measure because this shouldn't be possible")
    #     return false
    #   end
    # else
    #   runner.registerError("Couldn't find the specified load type. This is likely a result of a bug in this measure.")
    #   return false
    # end
    if load_object.is_initialized
      if not load_object.get.to_LightsDefinition.empty?
        selected_load = load_object.get.to_LightsDefinition.get
        runner.registerInfo("Found lighting load: #{selected_load.name.get}")
      elsif not load_object.get.to_ElectricEquipmentDefinition.empty?
        selected_load = load_object.get.to_ElectricEquipmentDefinition.get
        runner.registerInfo("Found electric equipment load: #{selected_load.name.get}")
      else
        runner.registerError("Incompatible load passed to the measure. This is likely a result of a bug in this measure because this shouldn't be possible")
        return false
      end
    else
      runner.registerError("Couldn't find the specified load type. This is likely a result of a bug in this measure.")
      return false
    end

    # runner.registerInfo("Found selected load: #{selected_load.get.name.get}")

    # Override Load Power/Intensity if requested
    if replace_load_value
      if floor_area_selection != 'None'
        # Override value for lighting definition
        if selected_load.is_a?(OpenStudio::Model::LightsDefinition)
          selected_load.setWattsperSpaceFloorArea(max_value)
          runner.registerInfo("Replaced the watts per space floor area for the selected lighting load with the calculated power intensity, #{max_value.round(3)} W/m^2.")
        # Override value for electric equipment definition
        elsif selected_load.is_a?(OpenStudio::Model::ElectricEquipmentDefinition)
          selected_load.setWattsperSpaceFloorArea(max_value)
          runner.registerInfo("Replaced the watts per space floor area for the selected electric equipment load with the calculated power intensity, #{max_value.round(3)} W/m^2.")
        end
      else
        # Override value for lighting definition
        if selected_load.is_a?(OpenStudio::Model::LightsDefinition)
          selected_load.setLightingLevel(max_value)
          runner.registerInfo("Replaced the watts per space floor area for the selected lighting load with the maximum power level found in the CSV, #{max_value.round(3)} W.")
        # Override value for electric equipment definition
        elsif selected_load.is_a?(OpenStudio::Model::ElectricEquipmentDefinition)
          selected_load.setDesignLevel(max_value)
          runner.registerInfo("Replaced the watts per space floor area for the selected electric equipment load with the maximum power level found in the CSV, #{max_value.round(3)} W.")
        end
      end
    end

    # Search for the original load object in space types and spaces
    loads_to_update = []
    model.getSpaceTypes.each do |space_type|
      space_type.lights.each do |light|
        if light.lightsDefinition.handle.to_s == selected_load.handle.to_s
          loads_to_update << light
        end
      end
      space_type.electricEquipment.each do |equipment|
        if equipment.electricEquipmentDefinition.handle.to_s == selected_load.handle.to_s
          loads_to_update << equipment
        end
      end
    end

    model.getSpaces.each do |space|
      space.lights.each do |light|
        if light.lightsDefinition.handle.to_s == selected_load.handle.to_s
          loads_to_update << light
        end
      end
      space.electricEquipment.each do |equipment|
        if equipment.electricEquipmentDefinition.handle.to_s == selected_load.handle.to_s
          loads_to_update << equipment
        end
      end
    end

    runner.registerInfo("Found #{loads_to_update.size} instances of the selected load to update.")

    # Override Schedule if requested
    if replace_schedules
      loads_to_update.each do |load|
        load.setSchedule(new_schedule)
        runner.registerInfo("Updated schedule for load: #{load.name.get}")
      end
    end

    # Final condition
    runner.registerFinalCondition("Load and schedule successfully updated from file.")
    return true
  end
end

AddAndApplyLoadAndScheduleFromFile.new.registerWithApplication
