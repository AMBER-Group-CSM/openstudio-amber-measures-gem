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

require 'fileutils'

class ExportModelWithMeasureChanges < OpenStudio::Measure::ReportingMeasure

  # define the name that a user will see
  def name
    return 'Export Model with Measure Changes'
  end

  # human readable description
  def description
    return 'This measure exports the in.osm file created for the simulation, moves it to a specified directory, and renames it. The default name is {name_of_parent_model}_wMeasures.osm, but a custom name can be specified.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This measure is useful for archiving the modified OSM file after measures have been applied and simulations have been run. The exported file can be saved to the OpenStudio "reports" directory or a custom path. A custom name for the exported file can also be specified, with an option to add an incrementing version number.'
  end

  # define arguments
  def arguments(model = nil)
    args = OpenStudio::Measure::OSArgumentVector.new

    # custom file name argument
    custom_name = OpenStudio::Measure::OSArgument.makeStringArgument('custom_name', false)
    custom_name.setDisplayName('Custom File Name')
    custom_name.setDescription('Specify a custom name for the exported OSM file. Do not include the .osm extension. If left blank, the default name will be used.')
    args << custom_name

    # destination directory argument
    destination_choices = OpenStudio::StringVector.new
    destination_choices << 'Generated Files Directory'
    destination_choices << 'Custom Path'

    destination_dir = OpenStudio::Measure::OSArgument.makeChoiceArgument('destination_dir', destination_choices, true)
    destination_dir.setDisplayName('Destination Directory')
    destination_dir.setDefaultValue('Generated Files Directory')
    args << destination_dir

    # custom path argument
    custom_path = OpenStudio::Measure::OSArgument.makeStringArgument('custom_path', false)
    custom_path.setDisplayName('Custom Path')
    custom_path.setDescription('Specify a custom path for the exported OSM file. This is used if "Custom Path" is selected as the destination directory.')
    args << custom_path

    # versioning argument
    use_versioning = OpenStudio::Measure::OSArgument.makeBoolArgument('use_versioning', true)
    use_versioning.setDisplayName('Use Versioning')
    use_versioning.setDescription('If selected, the exported file will have a version number appended to its name.')
    use_versioning.setDefaultValue(false)
    args << use_versioning

    # version suffix argument
    version_suffix = OpenStudio::Measure::OSArgument.makeStringArgument('version_suffix', false)
    version_suffix.setDisplayName('Version Suffix')
    version_suffix.setDescription('Specify a suffix to use before the version number. For example, "_v". This is used if versioning is enabled.')
    version_suffix.setDefaultValue('')
    args << version_suffix

    return args
  end

  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(nil), user_arguments)
      return false
    end

    # Debugging: Print the current working directory
    # puts "Current Directory: #{Dir.pwd}"

    # get the custom name argument
    custom_name = runner.getOptionalStringArgumentValue('custom_name', user_arguments)
    unless custom_name.empty?
      extension = File.extname(custom_name.to_s)
      # remove .osm extension if present
      unless extension.empty?
        custom_name = File.basename(custom_name, extension)
      end
    end
    
    # get the destination directory argument
    destination_dir = runner.getStringArgumentValue('destination_dir', user_arguments)

    # get the custom path argument
    custom_path = runner.getOptionalStringArgumentValue('custom_path', user_arguments)
    unless custom_path.empty?
      if destination_dir == 'Generated Files Directory'
        runner.registerWarning('You passed a custom file path, however the measure is set to save the model to the "Generated Files Directory", please switch this to "Custom Path" if you want the measure to use your provided path.')
      end
    end

    # get the versioning arguments
    use_versioning = runner.getBoolArgumentValue('use_versioning', user_arguments)
    version_suffix = runner.getOptionalStringArgumentValue('version_suffix', user_arguments)

    # get the current model
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError('No model loaded.')
      return false
    end
    model = model.get

    # find the parent model file in the directory above the absolute root directory, excluding temp_measure_manager.osm
    # parent_dir = File.expand_path('../../../', __dir__)
    parent_dir = File.dirname(runner.workflow.absoluteRootDir.to_s)
    # parent_dir = File.dirname(runner.workflow.absoluteRunDir.to_s)
    # puts "Parent directory is #{parent_dir}" # debugging
    runner.registerInfo("Parent directory is #{parent_dir}")
    parent_model_files = Dir.glob(File.join(parent_dir, '*.osm')).reject { |f| File.basename(f) == 'temp_measure_manager.osm' }

    if parent_model_files.empty?
      runner.registerError('No parent model file found in the expected directory.')
      return false
    else
      parent_model_path = parent_model_files.first
      parent_model_name = File.basename(parent_model_path, '.*')
      runner.registerInfo("Found a parent model named '#{parent_model_name}'")
    end

    # define the default file name
    default_name = "#{parent_model_name}_wMeasures.osm"

    # set the file name to custom name if provided, otherwise use the default
    file_name = custom_name.empty? ? default_name : "#{custom_name}.osm"

    puts "Current osw dir #{runner.workflow.oswDir}"
    # determine the destination directory path
    case destination_dir
    when 'Generated Files Directory'
      # destination_dir_path = runner.workflow.filePaths[0].to_s # This does works in regular use but fails in my testing environment for some reason
      destination_dir_path = File.join(runner.workflow.oswDir.to_s,"generated_files")
    when 'Custom Path'
      if custom_path.empty?
        runner.registerError('Custom Path was selected as the destination directory, but no custom path was provided.')
        return false
      end
      # Using Pathname.new().cleanpath.to_s to clean the path
      runner.registerInfo("Custom path passed: #{custom_path.to_s}")
      destination_dir_path = File.expand_path(custom_path.to_s)
      runner.registerInfo("Processed Destination path: #{destination_dir_path}")
    else
      runner.registerError("Invalid destination directory option: #{destination_dir}")
      return false
    end

    # determine the final file name with versioning if enabled
    if use_versioning
      base_name = File.basename(file_name, '.osm')
      version_number = 1

      # Using Pathname.new().cleanpath.to_s to fix any path mismatches
      search_pattern = File.join(destination_dir_path, "#{base_name}#{version_suffix}*.osm")

      matching_files = Dir.glob(search_pattern)
      num_files_found = matching_files.size

      runner.registerInfo("Found #{num_files_found} previous model versions")

      matching_files.each do |file|
        # runner.registerInfo("Looking at the file #{file} for a match")
        if match = file.match(/#{base_name}#{version_suffix}(\d+)\.osm$/)
          version_number = [version_number, match[1].to_i + 1].max
        end
      end
      file_name = "#{base_name}#{version_suffix}#{version_number}.osm"
      runner.registerInfo("Found previous model version, new version is #{version_suffix}#{version_number}")
      runner.registerInfo("Versioned filename will be #{file_name}")
    end

    destination_path = File.join(destination_dir_path, file_name)

    # check if the source file exists
    # source_path = File.join(runner.workflow.absoluteRootDir.to_s,'run', 'in.osm')
    source_path = File.join(runner.workflow.absoluteRunDir.to_s, "in.osm")
    runner.registerInfo("Source model path: #{source_path}")
    runner.registerInfo("Destination path: #{destination_path}")

    unless File.exist?(source_path)
      runner.registerError("The source file '#{source_path}' does not exist.")
      return false
    end

    # copy and rename the file, overwrite if it exists
    begin
      FileUtils.cp(source_path, destination_path)
      runner.registerInfo("Copied and renamed the OSM file to '#{destination_path}'")
    rescue StandardError => e
      runner.registerError("Failed to copy and rename the OSM file: #{e.message}")
      return false
    end

    return true
  end
end

# register the measure to be used by the application
ExportModelWithMeasureChanges.new.registerWithApplication