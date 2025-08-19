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

# start the measure
class CreateAndConfigureInternalMassDefinitions < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return 'Create and Configure Internal Mass Definitions'
  end

  # human readable description
  def description
    return 'Create a new internal mass definition using a layered construction and assign to matching spaces.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Build an opaque material from user inputs, wrap it in a layered construction, create an InternalMassDefinition, set sizing method, then instantiate and assign InternalMass objects to spaces matching a name pattern.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # Name of the internal mass definition
    definition_name = OpenStudio::Measure::OSArgument::makeStringArgument('definition_name', true)
    definition_name.setDisplayName('Internal Mass Definition Name')
    definition_name.setDefaultValue('Internal Mass Def')
    args << definition_name

    # Material properties for single-layer construction
    mat_name = OpenStudio::Measure::OSArgument::makeStringArgument('material_name', true)
    mat_name.setDisplayName('Opaque Material Name')
    mat_name.setDefaultValue('IM Material')
    args << mat_name

    roughness = OpenStudio::Measure::OSArgument::makeChoiceArgument('roughness', ["VeryRough","Rough","MediumRough","MediumSmooth","Smooth","VerySmooth"], true)
    roughness.setDisplayName('Material Roughness')
    roughness.setDefaultValue('MediumRough')
    args << roughness

    thickness = OpenStudio::Measure::OSArgument::makeDoubleArgument('thickness', true)
    thickness.setDisplayName('Layer Thickness (m)')
    thickness.setDefaultValue(0.2)
    args << thickness

    conductivity = OpenStudio::Measure::OSArgument::makeDoubleArgument('conductivity', true)
    conductivity.setDisplayName('Thermal Conductivity (W/m·K)')
    conductivity.setDefaultValue(0.15)
    args << conductivity

    density = OpenStudio::Measure::OSArgument::makeDoubleArgument('density', true)
    density.setDisplayName('Density (kg/m³)')
    density.setDefaultValue(608)
    args << density

    specific_heat = OpenStudio::Measure::OSArgument::makeDoubleArgument('specific_heat', true)
    specific_heat.setDisplayName('Specific Heat (J/kg·K)')
    specific_heat.setDefaultValue(1630)
    args << specific_heat

    # Sizing values
    surface_area = OpenStudio::Measure::OSArgument::makeDoubleArgument('surface_area', false)
    surface_area.setDisplayName('Surface Area (m²)')
    surface_area.setDefaultValue(0.0)
    args << surface_area

    surface_area_per_floor = OpenStudio::Measure::OSArgument::makeDoubleArgument('surface_area_per_floor_area', false)
    surface_area_per_floor.setDisplayName('Surface Area per Space Floor Area (m²/m²)')
    surface_area_per_floor.setDefaultValue(2.0)
    args << surface_area_per_floor

    surface_area_per_person = OpenStudio::Measure::OSArgument::makeDoubleArgument('surface_area_per_person', false)
    surface_area_per_person.setDisplayName('Surface Area per Person (m²/person)')
    surface_area_per_person.setDefaultValue(0.0)
    args << surface_area_per_person

    # Calculation method
    calc_method = OpenStudio::Measure::OSArgument::makeChoiceArgument('calculation_method', ['Surface Area', 'Surface Area per Space Floor Area', 'Surface Area per Person'], true)
    calc_method.setDisplayName('Sizing Calculation Method')
    calc_method.setDefaultValue('Surface Area per Space Floor Area')
    args << calc_method

    # Multiplier for the InternalMass object
    multiplier = OpenStudio::Measure::OSArgument::makeDoubleArgument('multiplier', true)
    multiplier.setDisplayName('Internal Mass Multiplier')
    multiplier.setDefaultValue(1.0)
    args << multiplier

    # Space name matching pattern (supports * wildcard)
    space_pattern = OpenStudio::Measure::OSArgument::makeStringArgument('space_name_pattern', true)
    space_pattern.setDisplayName('Space Name Pattern')
    space_pattern.setDefaultValue('*')
    args << space_pattern

    # Override internal mass convection coefficients
    override_convection = OpenStudio::Measure::OSArgument::makeBoolArgument('override_convection', false)
    override_convection.setDisplayName('Override Internal Mass Convection Coefficients')
    override_convection.setDescription('If true, the internal mass convection coefficients will be overridden with the a custom SurfacePropertyConvectionCoefficient object.')
    override_convection.setDefaultValue(false)
    args << override_convection

    # Natural convection multiplier for internal mass object inputs
    nat_conv_multiplier = OpenStudio::Measure::OSArgument::makeDoubleArgument('nat_conv_multiplier', false)
    nat_conv_multiplier.setDisplayName('Natural Convection Coefficient Multiplier')
    nat_conv_multiplier.setDescription('Multiplier for the internal mass natural convection coefficient')
    nat_conv_multiplier.setDefaultValue(1.0)
    args << nat_conv_multiplier

    # Scaler for an additional convection coefficient term
    added_conv_scaler = OpenStudio::Measure::OSArgument::makeDoubleArgument('added_conv_scaler', false)
    added_conv_scaler.setDisplayName('Secondary Convection Coefficient Term Scaler for Room Mixing Effects')
    added_conv_scaler.setDescription('Scaler for the additional convection coefficient term to account for room mixing effects')
    added_conv_scaler.setDefaultValue(1.0)
    args << added_conv_scaler

    # Exponential decay factor for the added convection coefficient term
    added_conv_exp = OpenStudio::Measure::OSArgument::makeDoubleArgument('added_conv_exp', false)
    added_conv_exp.setDisplayName('Exponential for Added Convection Coefficient Temperature Difference')
    added_conv_exp.setDescription('Shapes the curve of the secondary convection coefficient term.')
    added_conv_exp.setDefaultValue(0.333)
    args << added_conv_exp

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # Validate user arguments
    unless runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # Retrieve inputs
    name_str = runner.getStringArgumentValue('definition_name', user_arguments)
    mat_name = runner.getStringArgumentValue('material_name', user_arguments)
    roughness = runner.getStringArgumentValue('roughness', user_arguments)
    thickness = runner.getDoubleArgumentValue('thickness', user_arguments)
    conductivity = runner.getDoubleArgumentValue('conductivity', user_arguments)
    density = runner.getDoubleArgumentValue('density', user_arguments)
    specific_heat = runner.getDoubleArgumentValue('specific_heat', user_arguments)

    sa = runner.getDoubleArgumentValue('surface_area', user_arguments)
    sa_floor = runner.getDoubleArgumentValue('surface_area_per_floor_area', user_arguments)
    sa_person = runner.getDoubleArgumentValue('surface_area_per_person', user_arguments)
    method = runner.getStringArgumentValue('calculation_method', user_arguments)
    multiplier = runner.getDoubleArgumentValue('multiplier', user_arguments)
    space_pattern = runner.getStringArgumentValue('space_name_pattern', user_arguments)

    override_convection = runner.getBoolArgumentValue('override_convection', user_arguments)
    nat_conv_multiplier = runner.getDoubleArgumentValue('nat_conv_multiplier', user_arguments)
    added_conv_scaler = runner.getDoubleArgumentValue('added_conv_scaler', user_arguments)
    added_conv_exp = runner.getDoubleArgumentValue('added_conv_exp', user_arguments)

    # Check sizing inputs
    case method
    when 'Surface Area'
      if sa <= 0
        runner.registerError('Surface Area must be > 0 when using Surface Area method.')
        return false
      end
    when 'Surface Area per Space Floor Area'
      if sa_floor <= 0
        runner.registerError('Surface Area per Space Floor Area must be > 0 when selected.')
        return false
      end
    when 'Surface Area per Person'
      if sa_person <= 0
        runner.registerError('Surface Area per Person must be > 0 when selected.')
        return false
      end
    end

    # Report initial conditions
    init_defs = model.getInternalMassDefinitions.size
    init_instances = model.getInternalMasss.size
    runner.registerInitialCondition("Model started with #{init_defs} internal mass definitions and #{init_instances} internal mass objects.")

    # Create opaque material
    material = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    material.setName(mat_name)
    material.setRoughness(roughness)
    material.setThickness(thickness)
    material.setThermalConductivity(conductivity)
    material.setDensity(density)
    material.setSpecificHeat(specific_heat)

    # Create layered construction with the opaque material
    layered_construction = OpenStudio::Model::Construction.new(model)
    layered_construction.setName("#{mat_name}_const")
    layered_construction.insertLayer(0, material)

    # Create internal mass definition
    im_def = OpenStudio::Model::InternalMassDefinition.new(model)
    im_def.setName(name_str)
    im_def.setConstruction(layered_construction)

    # Apply sizing method
    case method
    when 'Surface Area'
      im_def.setSurfaceArea(sa)
    when 'Surface Area per Space Floor Area'
      im_def.setSurfaceAreaperSpaceFloorArea(sa_floor)
    when 'Surface Area per Person'
      im_def.setSurfaceAreaperPerson(sa_person)
    end

    # Build regex from wildcard pattern
    regex_str = '^' + Regexp.escape(space_pattern).gsub('\\*', '.*') + '$'
    regex = Regexp.new(regex_str)

    # Match spaces and create InternalMass objects
    matched_spaces = model.getSpaces.select { |space| space.name.to_s.match(regex) }
    if matched_spaces.empty?
      runner.registerWarning("No spaces matched pattern '#{space_pattern}'.")
    else
      runner.registerInfo("Found #{matched_spaces.size} that match the name pattern passed in.")
    end
    count = 0
    matched_spaces.each do |space|
      im = OpenStudio::Model::InternalMass.new(im_def)
      im_name = "#{name_str}_#{space.name}"
      im.setName(im_name)
      im.setSpace(space)
      im.setMultiplier(multiplier)
      count += 1

      if override_convection
        runner.registerInfo("Overriding convection coefficients for internal mass '#{im_name}' in space '#{space.name}'.")
        # Create a constant schedule for the convection coefficient that the EMS will control
        convection_schedule = OpenStudio::Model::ScheduleConstant.new(model)
        convection_schedule.setName("#{im_name}_ConvectionSchedule")
        convection_schedule.setValue(1)

        # Create SurfacePropertyConvectionCoefficient for internal mass
        convection_coeff = OpenStudio::Model::SurfacePropertyConvectionCoefficients.new(im)
        convection_coeff.setName("#{name_str}_convection")
        convection_coeff.setConvectionCoefficient1Location('Inside')
        convection_coeff.setConvectionCoefficient1Type('Schedule')
        convection_coeff.setConvectionCoefficient1Schedule(convection_schedule)
        
        # Create output variables for zone temperature and sufrace temperature for the EMS sensors to monitor
        # get the zone the mass is in
        zone = space.thermalZone 
        if space.thermalZone.is_initialized
          zone = space.thermalZone.get
        else
          runner.registerWarning("Space '#{space.name}' has no thermal zone; skipping convection coefficient override.")
          next
        end
        zone_name = zone.name.get
        # Create OutputVariable for zone mean air temperature
        zone_temp_var = OpenStudio::Model::OutputVariable.new("Zone Mean Air Temperature", model)
        zone_temp_var.setKeyValue(zone_name)
        zone_temp_var.setReportingFrequency('Timestep')
        # Create OutputVariable for Zone Mean Radiant Temperature
        zone_rad_temp_var = OpenStudio::Model::OutputVariable.new("Zone Mean Radiant Temperature", model)
        zone_rad_temp_var.setKeyValue(zone_name)
        zone_rad_temp_var.setReportingFrequency('Timestep')
        # Create OutputVariable for surface temperature
        im_temp_var = OpenStudio::Model::OutputVariable.new("Surface Inside Face Temperature", model)
        im_temp_var.setKeyValue(im_name)
        im_temp_var.setReportingFrequency('Timestep')
        
        
        # Create our EMS sensors
        zone_temp_sensor_name = zone_name.gsub(" ", "_").gsub("-", "").gsub(",", "").gsub(";", "").gsub(":", "").gsub("&", "").gsub("#", "")
        zone_temp_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, zone_temp_var)
        zone_temp_sensor.setName("#{zone_temp_sensor_name}_MeanAirTemp")
        zone_temp_sensor.setKeyName(zone_name)
        zone_rad_temp_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, zone_rad_temp_var)
        zone_rad_temp_sensor.setName("#{zone_temp_sensor_name}_MeanRadiantTemp")
        zone_rad_temp_sensor.setKeyName(zone_name)
        im_temp_sensor_name = im_name.gsub(" ", "_").gsub("-", "").gsub(",", "").gsub(";", "").gsub(":", "").gsub("&", "").gsub("#", "")
        im_temp_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, im_temp_var)
        im_temp_sensor.setName("#{im_temp_sensor_name}_InsideFaceTemp")
        im_temp_sensor.setKeyName(im_name)

        # Create our global variable for the convection coefficient
        im_name_safe = im_name.gsub(" ", "_").gsub("-", "").gsub(",", "").gsub(";", "").gsub(":", "").gsub("&", "").gsub("#", "")
        h_conv_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "InternalMassConvectionCoefficient")
        h_conv_var.setName("#{im_name_safe}_ConvectionCoefficient")

        # Create the actuator to set the convection coefficient
        actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(convection_schedule, "Schedule:Constant", "Schedule Value")
        actuator.setName("#{im_name_safe}_ConvectionCoefficientActuator")

        # Create the EMS program to control the convection coefficient
        program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
        program.setName("#{im_name_safe}_ConvectionCoefficientProgram")
        # Calcualte the temperature difference
        program.addLine("SET raw_temp_diff = #{im_temp_sensor.handle} - #{zone_temp_sensor.handle}")
        program.addLine("SET raw_rad_temp_diff = #{zone_temp_sensor.handle} - #{zone_rad_temp_sensor.handle}")
        # Use the absolute value of the temperature differences
        program.addLine("SET temp_diff = @Abs raw_temp_diff")
        program.addLine("SET rad_temp_diff = @Abs raw_rad_temp_diff")
        # Set the convection coefficient based on the temperature difference and augmented TARP convection
        # Note: there are definitely physics missing here, but this is a place to start.
        # This line is tarp natural conection with a multiplier
        program.addLine("SET h_conv_nat = #{nat_conv_multiplier} * 1.31 * (temp_diff ** (1/3))")
        # This line is the additional convection coefficient term trying to capture boyant mixing in the space
        program.addLine("SET h_conv_add = #{added_conv_scaler} * (rad_temp_diff ** (#{added_conv_exp}))")
        program.addLine("SET h_conv = h_conv_nat + h_conv_add")
        program.addLine("SET #{h_conv_var.handle} = h_conv")
        
        # Create the program calling manager
        pcm = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
        pcm.setName("#{im_name_safe}_ConvectionCoefficientPCM")
        pcm.setCallingPoint('BeginZoneTimestepBeforeHeatTransfer')
        pcm.addProgram(program)

        runner.registerInfo("Created convection coefficient override for internal mass '#{im_name}' in space '#{space.name}'.")        
      end
    end

    # Report final conditions
    runner.registerFinalCondition("Created internal mass definition '#{name_str}' and assigned to #{count} spaces matching pattern '#{space_pattern}'.")

    return true
  end
end

# register the measure to be used by the application
CreateAndConfigureInternalMassDefinitions.new.registerWithApplication
