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


# The documentation for the ZoneCapacitanceMultiplier object: https://bigladdersoftware.com/epx/docs/24-2/input-output-reference/group-simulation-parameters.html#zonecapacitancemultiplierresearchspecial
# Inputs
# Field: Name

# The name of the ZoneCapacitanceMultiplier:ResearchSpecial object.
# Field: Zone or ZoneList Name

# This field is the name of the thermal zone (ref: Zone) and attaches a particular zone capacitance multiplier to a thermal zone or set of thermal zones in the building. When the ZoneList option is used then capacity multiplier is applied to each of the zones in the zone list.
# Field: Temperature Capacity Multiplier

# This field is used to alter the effective heat capacitance of the zone air volume. This affects the transient calculations of zone air temperature. Values greater than 1.0 have the effect of smoothing or damping the rate of change in the temperature of zone air from timestep to timestep. Note that sensible heat capacity can also be modeled using internal mass surfaces.
# Field: Humidity Capacity Multiplier

# This field is used to alter the effective moisture capacitance of the zone air volume. This affects the transient calculations of zone air humidity ratio. Values greater than 1.0 have the effect of smoothing, or damping, the rate of change in the water content of zone air from timestep to timestep.
# Field: Carbon Dioxide Capacity Multiplier

# This field is used to alter the effective carbon dioxide capacitance of the zone air volume. This affects the transient calculations of zone air carbon dioxide concentration. Values greater than 1.0 have the effect of smoothing or damping the rate of change in the carbon dioxide level of zone air from timestep to timestep.
# Field: Generic Contaminant Capacity Multiplier

# This field is used to alter the effective generic contaminant capacitance of the zone air volume. This affects the transient calculations of zone air generic contaminant concentration. Values greater than 1.0 have the effect of smoothing or damping the rate of change in the generic contaminant level of zone air from timestep to timestep.

# start the measure
class CreateAndConfigureZoneCapacitanceMultiplier < OpenStudio::Measure::EnergyPlusMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Create and Configure ZoneCapacitanceMultiplier'
  end

  # human readable description
  def description
    return 'Creates ZoneCapacitanceMultiplier fully configurable objects for the requested zones. If you a user needs different capacitance multiplier values for different zones, use multiple measures in a workflow and request objects for the different zone names.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Creates ZoneCapacitanceMultiplier fully configurable objects for the requested zones. If you a user needs different capacitance multiplier values for different zones, use multiple measures in a workflow and request objects for the different zone names.

Description of this object from the documentation:
"This object is an advanced feature that can be used to control the effective storage capacity of the zone. Capacitance multipliers of 1.0 indicate the capacitance is that of the (moist) air in the volume of the specified zone. This multiplier can be increased if the zone air capacitance needs to be increased for stability of the simulation or to allow modeling higher or lower levels of damping of behavior over time. The multipliers are applied to the base value corresponding to the total capacitance for the zone’s volume of air at current zone (moist) conditions."'
  end

  # define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Measure::OSArgumentVector.new

    zone_name = OpenStudio::Measure::OSArgument.makeStringArgument('zone_name', true)
    zone_name.setDisplayName('Zone Name/Names')
    zone_name.setDescription('The name of the zone to which the capacitance multiplier will be applied. If you want to apply the same multiplier to multiple zones, use a ZoneList object. Supports Regex. * to apply the multiplier to all zones.')
    zone_name.setDefaultValue('*')
    args << zone_name

    temperature_capacity_multiplier = OpenStudio::Measure::OSArgument.makeDoubleArgument('temperature_capacity_multiplier', true)
    temperature_capacity_multiplier.setDisplayName('Temperature Capacity Multiplier')
    temperature_capacity_multiplier.setDescription('This field is used to alter the effective heat capacitance of the zone air volume. This affects the transient calculations of zone air temperature. Values greater than 1.0 have the effect of smoothing or damping the rate of change in the temperature of zone air from timestep to timestep.')
    temperature_capacity_multiplier.setDefaultValue(1.0)
    args << temperature_capacity_multiplier

    humidity_capacity_multiplier = OpenStudio::Measure::OSArgument.makeDoubleArgument('humidity_capacity_multiplier', true)
    humidity_capacity_multiplier.setDisplayName('Humidity Capacity Multiplier')
    humidity_capacity_multiplier.setDescription('This field is used to alter the effective moisture capacitance of the zone air volume. This affects the transient calculations of zone air humidity ratio. Values greater than 1.0 have the effect of smoothing, or damping, the rate of change in the water content of zone air from timestep to timestep.')
    humidity_capacity_multiplier.setDefaultValue(1.0)
    args << humidity_capacity_multiplier  

    carbon_dioxide_capacity_multiplier = OpenStudio::Measure::OSArgument.makeDoubleArgument('carbon_dioxide_capacity_multiplier', true)
    carbon_dioxide_capacity_multiplier.setDisplayName('Carbon Dioxide Capacity Multiplier')
    carbon_dioxide_capacity_multiplier.setDescription('This field is used to alter the effective carbon dioxide capacitance of the zone air volume. This affects the transient calculations of zone air carbon dioxide concentration. Values greater than 1.0 have the effect of smoothing or damping the rate of change in the carbon dioxide level of zone air from timestep to timestep.')
    carbon_dioxide_capacity_multiplier.setDefaultValue(1.0)
    args << carbon_dioxide_capacity_multiplier  

    generic_contaminant_capacity_multiplier = OpenStudio::Measure::OSArgument.makeDoubleArgument('generic_contaminant_capacity_multiplier', true)
    generic_contaminant_capacity_multiplier.setDisplayName('Generic Contaminant Capacity Multiplier')
    generic_contaminant_capacity_multiplier.setDescription('This field is used to alter the effective generic contaminant capacitance of the zone air volume. This affects the transient calculations of zone air generic contaminant concentration. Values greater than 1.0 have the effect of smoothing or damping the rate of change in the generic contaminant level of zone air from timestep to timestep.')
    generic_contaminant_capacity_multiplier.setDefaultValue(1.0)
    args << generic_contaminant_capacity_multiplier 

    return args
  end

  # define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)  # Do **NOT** remove this line

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(workspace), user_arguments)
      return false
    end

    # assign the user inputs to variables
    zone_name = runner.getStringArgumentValue('zone_name', user_arguments)
    temperature_capacity_multiplier = runner.getDoubleArgumentValue('temperature_capacity_multiplier', user_arguments)
    humidity_capacity_multiplier = runner.getDoubleArgumentValue('humidity_capacity_multiplier', user_arguments)
    carbon_dioxide_capacity_multiplier = runner.getDoubleArgumentValue('carbon_dioxide_capacity_multiplier', user_arguments)
    generic_contaminant_capacity_multiplier = runner.getDoubleArgumentValue('generic_contaminant_capacity_multiplier', user_arguments)

    # check the user inputs for reasonableness
    if temperature_capacity_multiplier <= 0.0
      runner.registerError('Temperature capacity multiplier must be greater than 0.0.')
      return false
    end 
    if humidity_capacity_multiplier <= 0.0
      runner.registerError('Humidity capacity multiplier must be greater than 0.0.')
      return false
    end
    if carbon_dioxide_capacity_multiplier <= 0.0
      runner.registerError('Carbon dioxide capacity multiplier must be greater than 0.0.')
      return false
    end
    if generic_contaminant_capacity_multiplier <= 0.0
      runner.registerError('Generic contaminant capacity multiplier must be greater than 0.0.')
      return false
    end

    # check the user_name for reasonableness
    if zone_name.empty?
      runner.registerError('Empty zone name was entered.')
      return false
    end

    # get all thermal zones in the starting model
    zones = workspace.getObjectsByType('Zone'.to_IddObjectType)
    # filter zones based on the user input

    # build a Regex from the user string (allowing * as wildcard)
    pattern = zone_name.gsub('*','.*')
    begin
      regex = Regexp.new("^#{pattern}$")
    rescue RegexpError => e
      runner.registerError("Invalid zone name pattern '#{zone_name}'. Regex error: #{e.message}")
      return false
    end

    # grab all Zone object names from the IDF and filter by that regex
    matched = workspace
      .getObjectsByType('Zone'.to_IddObjectType)
      .map    { |obj| obj.getString(0).get rescue nil }  # field 0 is “Name”
      .compact
      .select { |nm| nm =~ regex }

    if matched.empty?
      runner.registerError("No thermal zones match pattern '#{zone_name}'.")
      return false
    end

    # decide on a target reference name: either a single zone or a new ZoneList
    if matched.size == 1
      target_ref = matched.first
    else
      # create a ZoneList IDF object
      list_name = "#{zone_name}_ZoneList"
      zone_list = OpenStudio::IdfObject.new('ZoneList'.to_IddObjectType)
      zone_list.setString(0, list_name)

      matched.each_with_index do |zn, i|
        # fields 1,2,3… of ZoneList are the zone names
        zone_list.setString(i+1, zn)
      end

      # add the ZoneList to the workspace
      workspace.addObject(zone_list)
      target_ref = list_name

      runner.registerInfo("Created ZoneList '#{list_name}' with zones: #{matched.join(', ')}")
    end

    # now you can build your ZoneCapacitanceMultiplier object against `target_ref`
    capobj = OpenStudio::IdfObject.new('ZoneCapacitanceMultiplier:ResearchSpecial'.to_IddObjectType)
    capobj.setString(0, "#{zone_name}_CapacitanceMultiplier")  # Name
    capobj.setString(1, target_ref)
    capobj.setDouble(2, temperature_capacity_multiplier)
    capobj.setDouble(3, humidity_capacity_multiplier)
    capobj.setDouble(4, carbon_dioxide_capacity_multiplier)
    capobj.setDouble(5, generic_contaminant_capacity_multiplier)

    # add the object to the workspace
    workspace.addObject(capobj)

    # report final condition
    runner.registerFinalCondition("Created ZoneCapacitanceMultiplier for zones matching '#{zone_name}' with multipliers: Temperature=#{temperature_capacity_multiplier}, Humidity=#{humidity_capacity_multiplier}, CO2=#{carbon_dioxide_capacity_multiplier}, Generic Contaminant=#{generic_contaminant_capacity_multiplier}.")
    return true
  end
end

# register the measure to be used by the application
CreateAndConfigureZoneCapacitanceMultiplier.new.registerWithApplication
