# Copyright 2026 Gabriel Miguel Flechas
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

require 'csv'

class ConfigureSpaceInfiltrationDesignFlowRate < OpenStudio::Measure::ModelMeasure
  def name
    return 'Configure Space Infiltration Design Flow Rate'
  end

  def description
    return "Configures Space Infiltration Design Flow Rate objects for all spaces in zones with at least one exterior surface. The user can either provide their own design flow coefficients or use NIST-derived coefficients (NIST technical report <a href='https://doi.org/10.6028/NIST.TN.2221'>'Implementing NIST Infiltration Correlations'</a>, Ng et al., 2021) based on building type, climate zone, and air barrier. The measure creates paired HVAC-on and HVAC-off infiltration objects per exterior space, with separate coefficients and schedules for each."
  end

  def modeler_description
    return "This measure removes existing infiltration objects if requested, determines which thermal zones have exterior exposure, constructs HVAC ON and OFF schedules from user input or by inferring from the largest air loop and/or building hours of operation, optionally rescales a user-supplied design infiltration value from a measured pressure to a reference pressure, and creates new SpaceInfiltrationDesignFlowRate objects for spaces in external thermal zones. For each qualifying space, two infiltration objects are created: one active when the HVAC is on (using a binary HVAC ON schedule and the HVAC-on ABCD coefficients) and one active when the HVAC is off (using a complementary HVAC OFF schedule and the HVAC-off ABCD coefficients). Coefficients may be explicitly provided or automatically looked up from NIST infiltration correlations."
  end

  # NIST building types
  def nist_building_types
    building_types = OpenStudio::StringVector.new
    building_types << 'SecondarySchool'
    building_types << 'PrimarySchool'
    building_types << 'SmallOffice'
    building_types << 'MediumOffice'
    building_types << 'SmallHotel'
    building_types << 'LargeHotel'
    building_types << 'RetailStandalone'
    building_types << 'RetailStripmall'
    building_types << 'Hospital'
    building_types << 'MidriseApartment'
    building_types << 'HighriseApartment'
    return building_types
  end

  def infer_nist_building_type(model)
    if model.getBuilding.standardsBuildingType.is_initialized
      model_building_type = model.getBuilding.standardsBuildingType.get
    else
      model_building_type = ''
    end

    case model_building_type
    when 'Office', 'SmallOffice', 'SmallOfficeDetailed', 'MediumOffice', 'MediumOfficeDetailed', 'LargeOffice', 'LargeOfficeDetailed', 'Outpatient', 'OfS', 'OfL', 'SmallDataCenterLowITE', 'SmallDataCenterHighITE', 'LargeDataCenterLowITE', 'LargeDataCenterHighITE'
      floor_area = model.getBuilding.floorArea
      if floor_area < 2750.0
        nist_building_type = 'SmallOffice'
      else
        nist_building_type = 'MediumOffice'
      end
    when 'Retail'
      building_name = model.getBuilding.name.get
      if building_name.include? 'RetailStandalone'
        nist_building_type = 'RetailStandalone'
      else
        nist_building_type = 'RetailStripmall'
      end
    when 'RetailStripmall', 'StripMall', 'Warehouse', 'QuickServiceRestaurant', 'FullServiceRestaurant', 'RtS', 'RSD', 'RFF', 'SCn', 'SUn', 'WRf'
      nist_building_type = 'RetailStripmall'
    when 'RetailStandalone', 'SuperMarket', 'RtL', 'Rt3'
      nist_building_type = 'RetailStandalone'
    when 'PrimarySchool', 'EPr'
      nist_building_type = 'PrimarySchool'
    when 'SecondarySchool', 'ESe'
      nist_building_type = 'SecondarySchool'
    when 'SmallHotel', 'Mtl'
      nist_building_type = 'SmallHotel'
    when 'LargeHotel', 'Htl'
      nist_building_type = 'LargeHotel'
    when 'Hospital', 'Hsp'
      nist_building_type = 'Hospital'
    when 'MidriseApartment'
      nist_building_type = 'MidriseApartment'
    when 'HighriseApartment'
      nist_building_type = 'HighriseApartment'
    when 'TallBuilding', 'SuperTallBuilding'
      nist_building_type = 'LargeHotel'
    when 'College', 'Laboratory'
      nist_building_type = 'SecondarySchool'
    when 'Courthouse'
      nist_building_type = 'MediumOffice'
    else
      nist_building_type = model_building_type
    end

    results = {}
    results['model_building_type'] = model_building_type
    results['nist_building_type'] = nist_building_type
    return results
  end

  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # --- Design flowrate calculation method ---
    method_choices = OpenStudio::StringVector.new
    OpenStudio::Model::SpaceInfiltrationDesignFlowRate.validDesignFlowRateCalculationMethodValues.each do |m|
      method_choices << m
    end

    design_flow_rate_calculation_method = OpenStudio::Measure::OSArgument.makeChoiceArgument('design_flow_rate_calculation_method', method_choices, true)
    design_flow_rate_calculation_method.setDisplayName('Design Flow Rate Calculation Method')
    design_flow_rate_calculation_method.setDescription("Select the design flow rate calculation method for the SpaceInfiltrationDesignFlowRate objects (e.g., Flow/Zone [m^3/s], Flow/Area [m^3/s-m^2], Flow/ExteriorSurfaceArea [m^3/s-m^2], Flow/ExteriorWallArea [m^3/s-m^2], AirChanges/Hour [1/h]).")
    design_flow_rate_calculation_method.setDefaultValue(method_choices[0]) if method_choices.size > 0
    args << design_flow_rate_calculation_method

    # --- Design flow value & pressures ---
    design_flow_value = OpenStudio::Measure::OSArgument.makeDoubleArgument('design_flow_value', true)
    design_flow_value.setDisplayName('Design Flow Value for Selected Method')
    design_flow_value.setDescription("Numeric design flow value consistent with the chosen calculation method. If your design flow is given in (cfm/ft^2) at a given pressure, convert to (m^3/h-m^2) by multiplying by 18.288 (m-min/ft-hr); then, if needed, convert hours to seconds.")
    design_flow_value.setDefaultValue(0.0003)
    args << design_flow_value

    measured_pressure = OpenStudio::Measure::OSArgument.makeDoubleArgument('measured_pressure', false)
    measured_pressure.setDisplayName('Measured Pressure for Design Flow (Pa)')
    measured_pressure.setDescription('Pressure at which the design flow value was measured (e.g., from a pressurization test). Used only if "Scale Design Flow to Reference Pressure" is enabled.')
    measured_pressure.setDefaultValue(75.0)
    args << measured_pressure

    reference_pressure = OpenStudio::Measure::OSArgument.makeDoubleArgument('reference_pressure', false)
    reference_pressure.setDisplayName('Reference (Design) Pressure for Simulation (Pa)')
    reference_pressure.setDescription('Reference pressure at which the design infiltration value should be applied in the simulation. If your design flow is given in (cfm/ft^2) at a given pressure, first convert to (m^3/h-m^2) by multiplying by 18.288 (m-min/ft-hr), then convert to (m^3/s-m^2) as needed, and finally scale between pressures if desired.')
    reference_pressure.setDefaultValue(4.0)
    args << reference_pressure

    scale_to_reference_pressure = OpenStudio::Measure::OSArgument.makeBoolArgument('scale_to_reference_pressure', false)
    scale_to_reference_pressure.setDisplayName('Scale Design Flow from Measured Pressure to Reference Pressure?')
    scale_to_reference_pressure.setDescription('If true, the design flow value is scaled from the measured pressure to the reference pressure using a power-law relationship (exponent ~0.65).')
    scale_to_reference_pressure.setDefaultValue(false)
    args << scale_to_reference_pressure

    # --- NIST coefficient selection ---
    use_nist_coefficients = OpenStudio::Measure::OSArgument.makeBoolArgument('use_nist_coefficients', false)
    use_nist_coefficients.setDisplayName('Use NIST Infiltration Correlation Coefficients?')
    use_nist_coefficients.setDescription('If true, HVAC on/off infiltration coefficients (A, B, C, D) are looked up from NIST correlations based on building type, climate zone, and air barrier; user-provided coefficients are ignored.')
    use_nist_coefficients.setDefaultValue(false)
    args << use_nist_coefficients

    cz_choices = OpenStudio::StringVector.new
    cz_choices << '1A'
    cz_choices << '1B'
    cz_choices << '2A'
    cz_choices << '2B'
    cz_choices << '3A'
    cz_choices << '3B'
    cz_choices << '3C'
    cz_choices << '4A'
    cz_choices << '4B'
    cz_choices << '4C'
    cz_choices << '5A'
    cz_choices << '5B'
    cz_choices << '5C'
    cz_choices << '6A'
    cz_choices << '6B'
    cz_choices << '7A'
    cz_choices << '8A'
    cz_choices << 'Lookup From Model'

    climate_zone = OpenStudio::Measure::OSArgument.makeChoiceArgument('climate_zone', cz_choices, false)
    climate_zone.setDisplayName('Climate Zone for NIST Coefficients')
    climate_zone.setDescription('ASHRAE climate zone to use for NIST infiltration correlations. "Lookup From Model" will attempt to infer from the model climate zones (ASHRAE or mapped from CEC).')
    climate_zone.setDefaultValue('Lookup From Model')
    args << climate_zone

    bt_choices = nist_building_types
    bt_choices << 'Lookup From Model'
    building_type = OpenStudio::Measure::OSArgument.makeChoiceArgument('building_type', bt_choices, false)
    building_type.setDisplayName('Building Type for NIST Coefficients')
    building_type.setDescription('Building type to use for NIST infiltration correlations. "Lookup From Model" will infer the closest matching NIST prototype from the model standards building type and floor area.')
    building_type.setDefaultValue('Lookup From Model')
    args << building_type

    air_barrier = OpenStudio::Measure::OSArgument.makeBoolArgument('air_barrier', false)
    air_barrier.setDisplayName('Building Has Air Barrier? (For NIST Coefficients)')
    air_barrier.setDescription('If true, use NIST coefficients for buildings with an air barrier. If false, use coefficients for buildings without an air barrier.')
    air_barrier.setDefaultValue(false)
    args << air_barrier

    # --- Coefficients A-D for HVAC ON (user-provided) ---
    constant_term_coefficient_on = OpenStudio::Measure::OSArgument.makeDoubleArgument('constant_term_coefficient_on', true)
    constant_term_coefficient_on.setDisplayName('HVAC ON: Constant Term Coefficient (A_on)')
    constant_term_coefficient_on.setDescription('Constant term coefficient in the infiltration correlation when HVAC is ON. Ignored if NIST coefficients are used.')
    constant_term_coefficient_on.setDefaultValue(1.0)
    args << constant_term_coefficient_on

    temperature_term_coefficient_on = OpenStudio::Measure::OSArgument.makeDoubleArgument('temperature_term_coefficient_on', true)
    temperature_term_coefficient_on.setDisplayName('HVAC ON: Temperature Term Coefficient (B_on)')
    temperature_term_coefficient_on.setDescription('Temperature term coefficient in the infiltration correlation when HVAC is ON. Ignored if NIST coefficients are used.')
    temperature_term_coefficient_on.setDefaultValue(0.0)
    args << temperature_term_coefficient_on

    velocity_term_coefficient_on = OpenStudio::Measure::OSArgument.makeDoubleArgument('velocity_term_coefficient_on', true)
    velocity_term_coefficient_on.setDisplayName('HVAC ON: Velocity Term Coefficient (C_on)')
    velocity_term_coefficient_on.setDescription('Wind speed term coefficient in the infiltration correlation when HVAC is ON. Ignored if NIST coefficients are used.')
    velocity_term_coefficient_on.setDefaultValue(0.0)
    args << velocity_term_coefficient_on

    velocity_squared_term_coefficient_on = OpenStudio::Measure::OSArgument.makeDoubleArgument('velocity_squared_term_coefficient_on', true)
    velocity_squared_term_coefficient_on.setDisplayName('HVAC ON: Velocity Squared Term Coefficient (D_on)')
    velocity_squared_term_coefficient_on.setDescription('Wind speed squared term coefficient in the infiltration correlation when HVAC is ON. Ignored if NIST coefficients are used.')
    velocity_squared_term_coefficient_on.setDefaultValue(0.0)
    args << velocity_squared_term_coefficient_on

    # --- Coefficients A-D for HVAC OFF (user-provided) ---
    constant_term_coefficient_off = OpenStudio::Measure::OSArgument.makeDoubleArgument('constant_term_coefficient_off', true)
    constant_term_coefficient_off.setDisplayName('HVAC OFF: Constant Term Coefficient (A_off)')
    constant_term_coefficient_off.setDescription('Constant term coefficient in the infiltration correlation when HVAC is OFF. Ignored if NIST coefficients are used.')
    constant_term_coefficient_off.setDefaultValue(1.0)
    args << constant_term_coefficient_off

    temperature_term_coefficient_off = OpenStudio::Measure::OSArgument.makeDoubleArgument('temperature_term_coefficient_off', true)
    temperature_term_coefficient_off.setDisplayName('HVAC OFF: Temperature Term Coefficient (B_off)')
    temperature_term_coefficient_off.setDescription('Temperature term coefficient in the infiltration correlation when HVAC is OFF. Ignored if NIST coefficients are used.')
    temperature_term_coefficient_off.setDefaultValue(0.0)
    args << temperature_term_coefficient_off

    velocity_term_coefficient_off = OpenStudio::Measure::OSArgument.makeDoubleArgument('velocity_term_coefficient_off', true)
    velocity_term_coefficient_off.setDisplayName('HVAC OFF: Velocity Term Coefficient (C_off)')
    velocity_term_coefficient_off.setDescription('Wind speed term coefficient in the infiltration correlation when HVAC is OFF. Ignored if NIST coefficients are used.')
    velocity_term_coefficient_off.setDefaultValue(0.0)
    args << velocity_term_coefficient_off

    velocity_squared_term_coefficient_off = OpenStudio::Measure::OSArgument.makeDoubleArgument('velocity_squared_term_coefficient_off', true)
    velocity_squared_term_coefficient_off.setDisplayName('HVAC OFF: Velocity Squared Term Coefficient (D_off)')
    velocity_squared_term_coefficient_off.setDescription('Wind speed squared term coefficient in the infiltration correlation when HVAC is OFF. Ignored if NIST coefficients are used.')
    velocity_squared_term_coefficient_off.setDefaultValue(0.0)
    args << velocity_squared_term_coefficient_off

    # --- Schedule arguments ---
    schedule_name_choices = OpenStudio::StringVector.new
    schedule_name_choices << 'Lookup From Model'

    model.getScheduleRulesets.each { |sch| schedule_name_choices << sch.name.to_s }
    model.getScheduleConstants.each { |sch| schedule_name_choices << sch.name.to_s }
    model.getScheduleFixedIntervals.each { |sch| schedule_name_choices << sch.name.to_s }

    hvac_operating_schedule = OpenStudio::Measure::OSArgument.makeChoiceArgument('hvac_operating_schedule', schedule_name_choices, false, true)
    hvac_operating_schedule.setDisplayName('HVAC Operating (Availability) Schedule')
    hvac_operating_schedule.setDescription('Schedule that represents when the HVAC system is available/operating. "Lookup From Model" will use the availability schedule from the system serving the largest floor area or the building hours-of-operation schedule.')
    hvac_operating_schedule.setDefaultValue('Lookup From Model')
    args << hvac_operating_schedule

    hvac_off_schedule_choices = OpenStudio::StringVector.new
    hvac_off_schedule_choices << 'Infer From HVAC Operating Schedule'
    hvac_off_schedule_choices << 'Always On'
    schedule_name_choices.each { |sn| hvac_off_schedule_choices << sn unless sn == 'Lookup From Model' }

    hvac_non_operating_schedule = OpenStudio::Measure::OSArgument.makeChoiceArgument('hvac_non_operating_schedule', hvac_off_schedule_choices, false, true)
    hvac_non_operating_schedule.setDisplayName('HVAC Non-Operating (OFF) Schedule')
    hvac_non_operating_schedule.setDescription('Schedule used for infiltration when the HVAC system is off. You may select a schedule directly, use "Always On", or choose "Infer From HVAC Operating Schedule" to create an inverse of the HVAC ON schedule.')
    hvac_non_operating_schedule.setDefaultValue('Infer From HVAC Operating Schedule')
    args << hvac_non_operating_schedule

    remove_existing_infiltration = OpenStudio::Measure::OSArgument.makeBoolArgument('remove_existing_infiltration', false)
    remove_existing_infiltration.setDisplayName('Remove All Existing Infiltration Objects?')
    remove_existing_infiltration.setDescription('If true, all existing SpaceInfiltrationDesignFlowRate and SpaceInfiltrationEffectiveLeakageArea objects will be removed before creating new ones.')
    remove_existing_infiltration.setDefaultValue(true)
    args << remove_existing_infiltration

    return args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    method = runner.getStringArgumentValue('design_flow_rate_calculation_method', user_arguments)
    design_flow_value = runner.getDoubleArgumentValue('design_flow_value', user_arguments)

    measured_pressure = runner.getDoubleArgumentValue('measured_pressure', user_arguments)
    reference_pressure = runner.getDoubleArgumentValue('reference_pressure', user_arguments)
    scale_to_reference_pressure = runner.getBoolArgumentValue('scale_to_reference_pressure', user_arguments)

    use_nist_coefficients = runner.getBoolArgumentValue('use_nist_coefficients', user_arguments)
    climate_zone_arg = runner.getStringArgumentValue('climate_zone', user_arguments)
    building_type_arg = runner.getStringArgumentValue('building_type', user_arguments)
    air_barrier = runner.getBoolArgumentValue('air_barrier', user_arguments)

    a_on = runner.getDoubleArgumentValue('constant_term_coefficient_on', user_arguments)
    b_on = runner.getDoubleArgumentValue('temperature_term_coefficient_on', user_arguments)
    c_on = runner.getDoubleArgumentValue('velocity_term_coefficient_on', user_arguments)
    d_on = runner.getDoubleArgumentValue('velocity_squared_term_coefficient_on', user_arguments)

    a_off = runner.getDoubleArgumentValue('constant_term_coefficient_off', user_arguments)
    b_off = runner.getDoubleArgumentValue('temperature_term_coefficient_off', user_arguments)
    c_off = runner.getDoubleArgumentValue('velocity_term_coefficient_off', user_arguments)
    d_off = runner.getDoubleArgumentValue('velocity_squared_term_coefficient_off', user_arguments)

    hvac_operating_schedule_choice = runner.getStringArgumentValue('hvac_operating_schedule', user_arguments)
    hvac_non_operating_schedule_choice = runner.getStringArgumentValue('hvac_non_operating_schedule', user_arguments)

    remove_existing_infiltration = runner.getBoolArgumentValue('remove_existing_infiltration', user_arguments)

    if design_flow_value < 0.0
      runner.registerError("Design flow value must be non-negative; got #{design_flow_value}.")
      return false
    elsif design_flow_value == 0.0
      runner.registerWarning('Design flow value is zero. New infiltration objects will be created with zero design flow.')
    end

    if scale_to_reference_pressure
      if measured_pressure <= 0.0
        runner.registerError("Measured pressure must be positive when scaling is enabled; got #{measured_pressure}.")
        return false
      end
      if reference_pressure <= 0.0
        runner.registerError("Reference pressure must be positive when scaling is enabled; got #{reference_pressure}.")
        return false
      end
    end

    runner.registerInfo("Selected design flow rate calculation method: #{method}.")
    runner.registerInfo("Initial design flow value: #{design_flow_value} (units consistent with #{method}).")

    if use_nist_coefficients
      runner.registerInfo('Using NIST infiltration correlations to determine HVAC ON/OFF coefficients. User-entered coefficients will be ignored.')
    else
      runner.registerInfo("HVAC ON coefficients (user):  A_on=#{a_on}, B_on=#{b_on}, C_on=#{c_on}, D_on=#{d_on}.")
      runner.registerInfo("HVAC OFF coefficients (user): A_off=#{a_off}, B_off=#{b_off}, C_off=#{c_off}, D_off=#{d_off}.")
    end

    existing_infil = model.getSpaceInfiltrationDesignFlowRates
    existing_leakage = model.getSpaceInfiltrationEffectiveLeakageAreas

    runner.registerInitialCondition("Model started with #{existing_infil.size} SpaceInfiltrationDesignFlowRate object(s) and #{existing_leakage.size} SpaceInfiltrationEffectiveLeakageArea object(s).")

    if remove_existing_infiltration
      existing_infil.each(&:remove)
      existing_leakage.each(&:remove)
      runner.registerInfo("Removed #{existing_infil.size} SpaceInfiltrationDesignFlowRate object(s) and #{existing_leakage.size} SpaceInfiltrationEffectiveLeakageArea object(s).")
    else
      runner.registerInfo('Existing infiltration objects have been left in place. Be aware of potential double counting if they overlap with new infiltration assignments.')
    end

    zone_exterior_area_m2 = {}
    total_exterior_area_m2 = 0.0
    model.getThermalZones.each { |tz| zone_exterior_area_m2[tz] = 0.0 }

    model.getSurfaces.each do |s|
      next unless s.outsideBoundaryCondition == 'Outdoors'
      space_opt = s.space
      next if space_opt.empty?
      space = space_opt.get
      zone_opt = space.thermalZone
      next if zone_opt.empty?
      zone = zone_opt.get
      zone_mult = zone.multiplier
      area = s.grossArea * zone_mult
      zone_exterior_area_m2[zone] += area
      total_exterior_area_m2 += area
    end

    external_zones = []
    zone_exterior_area_m2.each do |zone, area|
      if area > 0.0
        external_zones << zone
        runner.registerInfo("Thermal zone '#{zone.name}' classified as EXTERNAL; exterior area = #{area.round(2)} m^2.")
      else
        runner.registerInfo("Thermal zone '#{zone.name}' classified as INTERIOR; exterior area = #{area.round(2)} m^2.")
      end
    end

    runner.registerInfo("Total exterior area across all zones (accounting for zone multipliers) is #{total_exterior_area_m2.round(2)} m^2.")
    if external_zones.empty?
      runner.registerWarning('No thermal zones with exterior surfaces were found. No infiltration objects will be created.')
      return true
    end

    # --- Resolve HVAC schedules (raw) ---
    hvac_on_schedule = resolve_hvac_operating_schedule(model, runner, hvac_operating_schedule_choice)
    hvac_off_schedule = resolve_hvac_non_operating_schedule(model, runner, hvac_non_operating_schedule_choice, hvac_on_schedule)

    # Fallbacks if schedules are nil
    if hvac_on_schedule.nil? && hvac_off_schedule.nil?
      runner.registerWarning('Both HVAC operating and non-operating schedules were nil; treating HVAC as always off and infiltration as always on.')
      on_const = OpenStudio::Model::ScheduleConstant.new(model)
      on_const.setName('HVAC Always Off (Inferred)')
      on_const.setValue(0.0)
      off_const = OpenStudio::Model::ScheduleConstant.new(model)
      off_const.setName('Infiltration HVAC Off Schedule (Always On Inferred)')
      off_const.setValue(1.0)
      hvac_on_schedule = on_const
      hvac_off_schedule = off_const
    elsif hvac_on_schedule.nil?
      runner.registerWarning("HVAC operating schedule was nil; treating HVAC as always off and using provided/off schedule '#{hvac_off_schedule.name}' for off periods.")
      on_const = OpenStudio::Model::ScheduleConstant.new(model)
      on_const.setName('HVAC Always Off (Inferred)')
      on_const.setValue(0.0)
      hvac_on_schedule = on_const
    elsif hvac_off_schedule.nil?
      runner.registerWarning("HVAC non-operating schedule was nil; creating inverse of HVAC operating schedule '#{hvac_on_schedule.name}'.")
      hvac_off_schedule = invert_schedule_any(model, runner, hvac_on_schedule, 'Infiltration HVAC Off Schedule (Inferred)')
    end

    # --- Binarize HVAC ON schedule for infiltration use ---
    hvac_on_schedule = make_binary_on_schedule(model, runner, hvac_on_schedule, 'Infiltration HVAC On Schedule')

    runner.registerInfo("Final HVAC ON schedule (binary for infiltration): '#{hvac_on_schedule.name}'.")
    runner.registerInfo("Final HVAC OFF schedule: '#{hvac_off_schedule.name}'.")

    # --- Effective design flow value ---
    effective_design_flow_value = design_flow_value
    if scale_to_reference_pressure
      exponent = 0.65
      factor = (reference_pressure / measured_pressure)**exponent
      effective_design_flow_value = design_flow_value * factor
      runner.registerInfo("Scaling design flow from measured pressure #{measured_pressure} Pa to reference pressure #{reference_pressure} Pa using exponent #{exponent}.")
      runner.registerInfo("Scaled design flow: #{design_flow_value} -> #{effective_design_flow_value} (units consistent with #{method}).")
    else
      runner.registerInfo('Scaling from measured pressure to reference pressure is disabled; using design flow value as provided.')
    end

    # --- NIST coefficients, if used ---
    if use_nist_coefficients
      climate_zone = climate_zone_arg
      if climate_zone == 'Lookup From Model'
        climate_zone = ''
        model.getClimateZones.climateZones.each do |cz|
          next if cz.value == ''
          cz_institution = cz.institution
          if cz_institution == 'ASHRAE'
            climate_zone = cz.value
            climate_zone = climate_zone.gsub('ASHRAE 169-2006-', '')
            climate_zone = climate_zone.gsub('ASHRAE 169-2013-', '')
            climate_zone = climate_zone.gsub('ASHRAE 169-2020-', '')
            climate_zone = climate_zone.gsub('ASHRAE 169-2021-', '')
          elsif cz_institution == 'CEC'
            california_cz = cz.value.gsub('CEC', '')
            case california_cz
            when '1'
              climate_zone = '4B'
            when '2', '3', '4', '5', '6'
              climate_zone = '3C'
            when '7', '8', '9', '10', '11', '12', '13', '14'
              climate_zone = '3B'
            when '15'
              climate_zone = '2B'
            when '16'
              climate_zone = '5B'
            end
            runner.registerWarning("Using ASHRAE climate zone #{climate_zone} for California climate zone #{california_cz}.")
          end
        end

        if climate_zone == ''
          runner.registerError('Unable to determine an ASHRAE climate zone for the model for NIST coefficients.')
          return false
        end
        runner.registerInfo("Using climate zone #{climate_zone} from model for NIST coefficients.")
      else
        runner.registerInfo("Using climate zone #{climate_zone} from user arguments for NIST coefficients.")
      end

      climate_zone_number = climate_zone.delete('^0-9').to_i

      bt_choice = building_type_arg
      bt_final = nil
      bt_list = []
      nist_building_types.each { |bt| bt_list << bt }

      if bt_choice == 'Lookup From Model'
        bt_data = infer_nist_building_type(model)
        model_bt = bt_data['model_building_type']
        nist_bt = bt_data['nist_building_type']
        bt_final = nist_bt

        unless bt_list.include?(nist_bt)
          runner.registerError("NIST coefficients are not available for model building type '#{nist_bt}'.")
          return false
        end

        if model_bt == nist_bt
          runner.registerInfo("Using building type '#{bt_final}' from model for NIST coefficients.")
        else
          runner.registerWarning("Using NIST building type '#{bt_final}' for model building type '#{model_bt}'.")
        end
      else
        bt_final = bt_choice
        unless bt_list.include?(bt_final)
          runner.registerError("Building type '#{bt_final}' is not supported by the NIST correlations.")
          return false
        end
        runner.registerInfo("Using building type '#{bt_final}' from user arguments for NIST coefficients.")
      end

      nist_infiltration_correlations_csv = "#{File.dirname(__FILE__)}/resources/Data-NISTInfiltrationCorrelations.csv"
      unless File.file?(nist_infiltration_correlations_csv)
        runner.registerError("Unable to find NIST infiltration correlations file: #{nist_infiltration_correlations_csv}")
        return false
      end

      coefficients_tbl = CSV.table(nist_infiltration_correlations_csv)
      coefficients_hsh = coefficients_tbl.map(&:to_hash)

      coeffs = coefficients_hsh.select { |r| (r[:building_type] == bt_final) && (r[:climate_zone] == climate_zone_number) }
      if coeffs.empty?
        runner.registerError("No NIST infiltration coefficients found for building type '#{bt_final}' and climate zone #{climate_zone_number}.")
        return false
      end

      if air_barrier
        coeffs = coeffs.select { |r| r[:air_barrier] == 'yes' }
        runner.registerInfo('Using NIST coefficients for buildings WITH air barrier.')
      else
        coeffs = coeffs.select { |r| r[:air_barrier] == 'no' }
        runner.registerInfo('Using NIST coefficients for buildings WITHOUT air barrier.')
      end

      if coeffs.empty?
        runner.registerError("NIST coefficients not found for building type '#{bt_final}', climate zone #{climate_zone_number}, air_barrier=#{air_barrier}.")
        return false
      end

      on_coefficients = coeffs.select { |r| r[:hvac_status] == 'on' }
      off_coefficients = coeffs.select { |r| r[:hvac_status] == 'off' }

      if on_coefficients.empty?
        runner.registerError("NIST ON coefficients not found for building type '#{bt_final}', climate zone #{climate_zone_number}, air_barrier=#{air_barrier}.")
        return false
      end

      a_on = on_coefficients[0][:a]
      b_on = on_coefficients[0][:b]
      d_on = on_coefficients[0][:d]

      if off_coefficients.empty?
        runner.registerWarning('NIST OFF coefficients are not explicitly defined; using ON coefficients as fallback.')
        a_off = a_on
        b_off = b_on
        d_off = d_on
      else
        a_off = off_coefficients[0][:a].nil? ? a_on : off_coefficients[0][:a]
        b_off = off_coefficients[0][:b].nil? ? b_on : off_coefficients[0][:b]
        d_off = off_coefficients[0][:d].nil? ? d_on : off_coefficients[0][:d]
      end

      c_on = 0.0
      c_off = 0.0

      runner.registerInfo("NIST HVAC ON coefficients:  A_on=#{a_on}, B_on=#{b_on}, C_on=#{c_on}, D_on=#{d_on}.")
      runner.registerInfo("NIST HVAC OFF coefficients: A_off=#{a_off}, B_off=#{b_off}, C_off=#{c_off}, D_off=#{d_off}.")
    end

    # --- Create infiltration objects (per exterior space) ---
    num_created = 0
    zone_has_flow_zone_infil = {}

    model.getSpaces.each do |space|
      zone_opt = space.thermalZone
      if zone_opt.empty?
        runner.registerInfo("Space '#{space.name}' is not in a thermal zone; skipping.")
        next
      end
      zone = zone_opt.get

      if !zone_exterior_area_m2.key?(zone) || zone_exterior_area_m2[zone] <= 0.0
        next
      end

      if space.exteriorArea <= 0.0
        next
      end

      case method
      when 'Flow/Zone'
        if zone_has_flow_zone_infil[zone]
          runner.registerInfo("Zone '#{zone.name}' already has a Flow/Zone infiltration pair; skipping additional space '#{space.name}'.")
          next
        end
        zone_has_flow_zone_infil[zone] = true

        on_infil = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
        on_infil.setName("#{zone.name} HVAC On Infiltration")
        on_infil.setSpace(space)
        on_infil.setDesignFlowRate(effective_design_flow_value)
        on_infil.setSchedule(hvac_on_schedule)
        on_infil.setConstantTermCoefficient(a_on)
        on_infil.setTemperatureTermCoefficient(b_on)
        on_infil.setVelocityTermCoefficient(c_on)
        on_infil.setVelocitySquaredTermCoefficient(d_on)

        off_infil = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
        off_infil.setName("#{zone.name} HVAC Off Infiltration")
        off_infil.setSpace(space)
        off_infil.setDesignFlowRate(effective_design_flow_value)
        off_infil.setSchedule(hvac_off_schedule)
        off_infil.setConstantTermCoefficient(a_off)
        off_infil.setTemperatureTermCoefficient(b_off)
        off_infil.setVelocityTermCoefficient(c_off)
        off_infil.setVelocitySquaredTermCoefficient(d_off)

        num_created += 2
        runner.registerInfo("Created Flow/Zone HVAC On/Off infiltration pair for zone '#{zone.name}' attached to representative space '#{space.name}' with design flow #{effective_design_flow_value}.")

      when 'Flow/Area', 'Flow/ExteriorSurfaceArea', 'Flow/ExteriorWallArea', 'AirChanges/Hour'
        on_infil = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
        on_infil.setName("#{space.name} HVAC On Infiltration")
        on_infil.setSpace(space)
        case method
        when 'Flow/Area'
          on_infil.setFlowperSpaceFloorArea(effective_design_flow_value)
        when 'Flow/ExteriorSurfaceArea'
          on_infil.setFlowperExteriorSurfaceArea(effective_design_flow_value)
        when 'Flow/ExteriorWallArea'
          on_infil.setFlowperExteriorWallArea(effective_design_flow_value)
        when 'AirChanges/Hour'
          on_infil.setAirChangesperHour(effective_design_flow_value)
        end
        on_infil.setSchedule(hvac_on_schedule)
        on_infil.setConstantTermCoefficient(a_on)
        on_infil.setTemperatureTermCoefficient(b_on)
        on_infil.setVelocityTermCoefficient(c_on)
        on_infil.setVelocitySquaredTermCoefficient(d_on)

        off_infil = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
        off_infil.setName("#{space.name} HVAC Off Infiltration")
        off_infil.setSpace(space)
        case method
        when 'Flow/Area'
          off_infil.setFlowperSpaceFloorArea(effective_design_flow_value)
        when 'Flow/ExteriorSurfaceArea'
          off_infil.setFlowperExteriorSurfaceArea(effective_design_flow_value)
        when 'Flow/ExteriorWallArea'
          off_infil.setFlowperExteriorWallArea(effective_design_flow_value)
        when 'AirChanges/Hour'
          off_infil.setAirChangesperHour(effective_design_flow_value)
        end
        off_infil.setSchedule(hvac_off_schedule)
        off_infil.setConstantTermCoefficient(a_off)
        off_infil.setTemperatureTermCoefficient(b_off)
        off_infil.setVelocityTermCoefficient(c_off)
        off_infil.setVelocitySquaredTermCoefficient(d_off)

        num_created += 2
        runner.registerInfo("Created HVAC On/Off infiltration pair for exterior space '#{space.name}' in zone '#{zone.name}' using method '#{method}' and design value #{effective_design_flow_value}.")
      else
        runner.registerError("Unsupported design flow rate calculation method: '#{method}'.")
        return false
      end
    end

    final_infil = model.getSpaceInfiltrationDesignFlowRates.size
    runner.registerFinalCondition("Model now has #{final_infil} SpaceInfiltrationDesignFlowRate object(s). #{num_created} new infiltration object(s) were created for spaces in #{external_zones.size} external thermal zone(s).")

    return true
  end

  # -------------------- Helper methods --------------------

  def resolve_hvac_operating_schedule(model, runner, choice)
    if choice == 'Lookup From Model'
      runner.registerInfo('HVAC operating schedule set to "Lookup From Model"; inferring from HVAC systems and building schedules.')
      return infer_hvac_schedule_from_model(model, runner)
    end

    sch_opt = model.getScheduleByName(choice)
    unless sch_opt.is_initialized
      runner.registerError("HVAC operating schedule '#{choice}' was not found in the model.")
      return nil
    end
    sch = sch_opt.get
    runner.registerInfo("Using user-specified HVAC operating schedule '#{sch.name}'.")
    return sch
  end

  def infer_hvac_schedule_from_model(model, runner)
    hvac_schedule = nil
    largest_area = 0.0

    update_winner = lambda do |schedule, area, descr|
      if area > largest_area
        hvac_schedule = schedule
        largest_area = area
        runner.registerInfo("Candidate HVAC schedule '#{schedule.name}' from #{descr} serves #{area.round(1)} m^2 and is now the largest.")
      end
    end

    model.getAirLoopHVACs.each do |air_loop|
      area = 0.0
      air_loop.thermalZones.each { |tz| area += tz.floorArea * tz.multiplier }
      next if area <= 0.0
      schedule = air_loop.availabilitySchedule
      update_winner.call(schedule, area, "AirLoop '#{air_loop.name}'")
    end

    model.getAirLoopHVACUnitarySystems.each do |unitary|
      next unless unitary.thermalZone.is_initialized
      tz = unitary.thermalZone.get
      area = tz.floorArea * tz.multiplier
      schedule = if unitary.availabilitySchedule.is_initialized
                   unitary.availabilitySchedule.get
                 else
                   model.alwaysOnDiscreteSchedule
                 end
      update_winner.call(schedule, area, "Unitary System '#{unitary.name}'")
    end

    model.getAirLoopHVACUnitaryHeatPumpAirToAirs.each do |unitary|
      next unless unitary.controllingZone.is_initialized
      tz = unitary.controllingZone.get
      area = tz.floorArea * tz.multiplier
      if unitary.availabilitySchedule.is_initialized
        update_winner.call(unitary.availabilitySchedule.get, area, "HeatPumpAirToAir '#{unitary.name}'")
      end
    end

    model.getAirLoopHVACUnitaryHeatPumpAirToAirMultiSpeeds.each do |unitary|
      next unless unitary.controllingZoneorThermostatLocation.is_initialized
      tz = unitary.controllingZoneorThermostatLocation.get
      area = tz.floorArea * tz.multiplier
      schedule = if unitary.availabilitySchedule.is_initialized
                   unitary.availabilitySchedule.get
                 else
                   model.alwaysOnDiscreteSchedule
                 end
      update_winner.call(schedule, area, "HeatPumpAirToAirMultiSpeed '#{unitary.name}'")
    end

    model.getFanZoneExhausts.each do |fan|
      next unless fan.thermalZone.is_initialized
      tz = fan.thermalZone.get
      area = tz.floorArea * tz.multiplier
      schedule = if fan.availabilitySchedule.is_initialized
                   fan.availabilitySchedule.get
                 else
                   model.alwaysOnDiscreteSchedule
                 end
      update_winner.call(schedule, area, "FanZoneExhaust '#{fan.name}'")
    end

    building_area = model.getBuilding.floorArea
    if largest_area < (0.05 * building_area)
      runner.registerWarning("Largest HVAC-related schedule serves #{largest_area.round(1)} m^2, which is less than 5% of building area #{building_area.round(1)} m^2. Attempting to use building Hours of Operation schedule instead.")
      default_schedule_set = model.getBuilding.defaultScheduleSet
      if default_schedule_set.is_initialized
        dss = default_schedule_set.get
        hoo = dss.hoursofOperationSchedule
        if hoo.is_initialized
          hvac_schedule = hoo.get
          largest_area = building_area
          runner.registerInfo("Using building Hours of Operation schedule '#{hvac_schedule.name}' as HVAC operating schedule.")
        else
          runner.registerWarning('Building default schedule set does not define Hours of Operation. Unable to infer HVAC operating schedule from building.')
        end
      else
        runner.registerWarning('Building does not have a default schedule set. Unable to infer HVAC operating schedule from building.')
      end
    end

    if hvac_schedule.nil?
      runner.registerWarning('No HVAC operating schedule could be inferred from the model.')
      return nil
    end

    area_fraction = 100.0 * largest_area / [building_area, 0.0001].max
    runner.registerInfo("Final inferred HVAC operating schedule is '#{hvac_schedule.name}', serving #{largest_area.round(1)} m^2 (#{area_fraction.round(0)}% of building area).")
    return hvac_schedule
  end

  def resolve_hvac_non_operating_schedule(model, runner, choice, hvac_on_schedule)
    if choice == 'Infer From HVAC Operating Schedule'
      runner.registerInfo('HVAC non-operating schedule set to "Infer From HVAC Operating Schedule"; constructing inverse of HVAC ON schedule.')
      if hvac_on_schedule.nil?
        runner.registerWarning('Cannot infer HVAC non-operating schedule because HVAC ON schedule is nil. Using Always On for HVAC OFF.')
        return model.alwaysOnDiscreteSchedule
      end
      return invert_schedule_any(model, runner, hvac_on_schedule, 'Infiltration HVAC Off Schedule')
    elsif choice == 'Always On'
      runner.registerInfo('HVAC non-operating schedule set to Always On.')
      return model.alwaysOnDiscreteSchedule
    end

    sch_opt = model.getScheduleByName(choice)
    unless sch_opt.is_initialized
      runner.registerError("HVAC non-operating schedule '#{choice}' was not found in the model.")
      return nil
    end
    sch = sch_opt.get
    runner.registerInfo("Using user-specified HVAC non-operating schedule '#{sch.name}'.")
    return sch
  end

  # Invert a general schedule: used for HVAC OFF if not explicitly provided.
  def invert_schedule_any(model, runner, hvac_schedule, base_name)
    # Ruleset schedule: use existing invert helper
    if hvac_schedule.to_ScheduleRuleset.is_initialized
      sr = hvac_schedule.to_ScheduleRuleset.get
      inv = invert_schedule_ruleset(sr, base_name)
      runner.registerInfo("Created inverted ruleset schedule '#{inv.name}' from '#{sr.name}'.")
      return inv

    # Constant schedule: 0 -> 1, non-zero -> 0
    elsif hvac_schedule.to_ScheduleConstant.is_initialized
      sc = hvac_schedule.to_ScheduleConstant.get
      new_sch = OpenStudio::Model::ScheduleConstant.new(model)
      new_sch.setName(base_name)
      new_value = (sc.value > 0.0 ? 0.0 : 1.0)
      new_sch.setValue(new_value)
      runner.registerInfo("Created inverted constant schedule '#{new_sch.name}' from '#{sc.name}' (#{sc.value} -> #{new_value}).")
      return new_sch

    # FixedInterval schedule: create OFF schedule where original <= 0 → 1, >0 → 0
    elsif hvac_schedule.to_ScheduleFixedInterval.is_initialized
      sfi = hvac_schedule.to_ScheduleFixedInterval.get
      off_sch = make_inverted_fixed_interval_off_schedule(model, runner, sfi, base_name)

      if off_sch
        runner.registerInfo("Using FixedInterval OFF schedule '#{off_sch.name}' as HVAC non-operating schedule derived from '#{sfi.name}'.")
        return off_sch
      else
        runner.registerWarning("Failed to create inverted FixedInterval schedule from '#{sfi.name}'; using Always On as HVAC OFF schedule.")
        return model.alwaysOnDiscreteSchedule
      end

    # Unsupported schedule type: fall back
    else
      runner.registerWarning("Schedule '#{hvac_schedule.name}' is not a Ruleset, Constant, or FixedInterval; using Always On for HVAC OFF schedule.")
      return model.alwaysOnDiscreteSchedule
    end
  end

  # Create a binary ON schedule (1 where original > 0, else 0) for infiltration use
  def make_binary_on_schedule(model, runner, schedule, new_name)
    return nil if schedule.nil?

    # Constant schedule: just threshold the single value
    if schedule.to_ScheduleConstant.is_initialized
      sc = schedule.to_ScheduleConstant.get
      new_sch = OpenStudio::Model::ScheduleConstant.new(model)
      new_sch.setName(new_name)
      new_sch.setValue(sc.value > 0.0 ? 1.0 : 0.0)
      runner.registerInfo("Created binary HVAC ON constant schedule '#{new_sch.name}' from '#{sc.name}' (#{sc.value} -> #{new_sch.value}).")
      return new_sch
    end

    # Ruleset schedule: binarize each day schedule
    if schedule.to_ScheduleRuleset.is_initialized
      sr = schedule.to_ScheduleRuleset.get
      bin = binarize_schedule_ruleset(sr, new_name)
      runner.registerInfo("Created binary HVAC ON ruleset schedule '#{bin.name}' from '#{sr.name}'.")
      return bin
    end

    # FixedInterval schedule: check if already binary, otherwise build new 0/1 schedule
    if schedule.to_ScheduleFixedInterval.is_initialized
      sfi = schedule.to_ScheduleFixedInterval.get
      ts = sfi.timeSeries
      values = ts.values
      n = values.size

      # Check if the existing interval schedule is already 0/1
      already_binary = true
      (0...n).each do |i|
        v = values[i]
        unless (v == 0.0) || (v == 1.0)
          already_binary = false
          break
        end
      end

      if already_binary
        runner.registerInfo("FixedInterval schedule '#{sfi.name}' is already binary (0/1); using it directly as HVAC ON schedule for infiltration.")
        return sfi
      end

      # Not binary: build a new 0/1 ON schedule
      on_sch = make_binary_fixed_interval_on_schedule(model, runner, sfi, new_name)
      if on_sch.nil?
        runner.registerWarning("Binary conversion of FixedInterval schedule '#{sfi.name}' failed; using original schedule for HVAC ON infiltration instead of a new binary schedule.")
        return sfi
      else
        return on_sch
      end
    end

    # Unknown schedule type: just use as-is
    runner.registerWarning("Schedule '#{schedule.name}' is not a Constant, Ruleset, or FixedInterval schedule. Using it directly as HVAC ON schedule without binarization.")
    return schedule
  end

  # invert day schedule: 0 -> 1, non-zero -> 0
  def invert_schedule_day(old_schedule_day, new_schedule_day, new_schedule_name)
    new_schedule_day.setName(new_schedule_name)
    old_schedule_day.times.each_with_index do |time, index|
      old_value = old_schedule_day.values[index]
      new_value = (old_value == 0.0 ? 1.0 : 0.0)
      new_schedule_day.addValue(time, new_value)
    end
    return new_schedule_day
  end

  # binarize day: non-zero -> 1, 0 -> 0
  def binarize_schedule_day(old_schedule_day, new_schedule_day, new_schedule_name)
    new_schedule_day.setName(new_schedule_name)
    old_schedule_day.times.each_with_index do |time, index|
      old_value = old_schedule_day.values[index]
      new_value = (old_value > 0.0 ? 1.0 : 0.0)
      new_schedule_day.addValue(time, new_value)
    end
    return new_schedule_day
  end

  def invert_schedule_ruleset(schedule_ruleset, new_schedule_name)
    model = schedule_ruleset.model
    new_schedule = OpenStudio::Model::ScheduleRuleset.new(model, 0.0)
    new_schedule.setName(new_schedule_name)

    summer = schedule_ruleset.summerDesignDaySchedule
    new_summer = OpenStudio::Model::ScheduleDay.new(model)
    invert_schedule_day(summer, new_summer, "#{new_schedule_name} Summer Design Day Schedule")
    new_schedule.setSummerDesignDaySchedule(new_summer)

    winter = schedule_ruleset.winterDesignDaySchedule
    new_winter = OpenStudio::Model::ScheduleDay.new(model)
    invert_schedule_day(winter, new_winter, "#{new_schedule_name} Winter Design Day Schedule")
    new_schedule.setWinterDesignDaySchedule(new_winter)

    default_day = schedule_ruleset.defaultDaySchedule
    new_default_day = new_schedule.defaultDaySchedule
    invert_schedule_day(default_day, new_default_day, "#{new_schedule_name} Default Day Schedule")

    schedule_ruleset.scheduleRules.each_with_index do |rule, i|
      old_day = rule.daySchedule
      new_day = OpenStudio::Model::ScheduleDay.new(model)
      invert_schedule_day(old_day, new_day, "#{new_schedule_name} Schedule Day #{i}")
      new_rule = OpenStudio::Model::ScheduleRule.new(new_schedule, new_day)
      new_rule.setName("#{new_day.name} Rule")
      new_rule.setApplySunday(rule.applySunday)
      new_rule.setApplyMonday(rule.applyMonday)
      new_rule.setApplyTuesday(rule.applyTuesday)
      new_rule.setApplyWednesday(rule.applyWednesday)
      new_rule.setApplyThursday(rule.applyThursday)
      new_rule.setApplyFriday(rule.applyFriday)
      new_rule.setApplySaturday(rule.applySaturday)
    end

    return new_schedule
  end

  def binarize_schedule_ruleset(schedule_ruleset, new_schedule_name)
    model = schedule_ruleset.model
    new_schedule = OpenStudio::Model::ScheduleRuleset.new(model, 0.0)
    new_schedule.setName(new_schedule_name)

    summer = schedule_ruleset.summerDesignDaySchedule
    new_summer = OpenStudio::Model::ScheduleDay.new(model)
    binarize_schedule_day(summer, new_summer, "#{new_schedule_name} Summer Design Day Schedule")
    new_schedule.setSummerDesignDaySchedule(new_summer)

    winter = schedule_ruleset.winterDesignDaySchedule
    new_winter = OpenStudio::Model::ScheduleDay.new(model)
    binarize_schedule_day(winter, new_winter, "#{new_schedule_name} Winter Design Day Schedule")
    new_schedule.setWinterDesignDaySchedule(new_winter)

    default_day = schedule_ruleset.defaultDaySchedule
    new_default_day = new_schedule.defaultDaySchedule
    binarize_schedule_day(default_day, new_default_day, "#{new_schedule_name} Default Day Schedule")

    schedule_ruleset.scheduleRules.each_with_index do |rule, i|
      old_day = rule.daySchedule
      new_day = OpenStudio::Model::ScheduleDay.new(model)
      binarize_schedule_day(old_day, new_day, "#{new_schedule_name} Schedule Day #{i}")
      new_rule = OpenStudio::Model::ScheduleRule.new(new_schedule, new_day)
      new_rule.setName("#{new_day.name} Rule")
      new_rule.setApplySunday(rule.applySunday)
      new_rule.setApplyMonday(rule.applyMonday)
      new_rule.setApplyTuesday(rule.applyTuesday)
      new_rule.setApplyWednesday(rule.applyWednesday)
      new_rule.setApplyThursday(rule.applyThursday)
      new_rule.setApplyFriday(rule.applyFriday)
      new_rule.setApplySaturday(rule.applySaturday)
    end

    return new_schedule
  end

  # Create a binary (0/1) ScheduleFixedInterval for HVAC ON from an existing ScheduleFixedInterval.
  # Returns the new ON schedule or nil if something goes wrong.
  def make_binary_fixed_interval_on_schedule(model, runner, src_sfi, new_name)
    src_name = src_sfi.name.get
    runner.registerInfo("Creating binary HVAC ON FixedInterval schedule '#{new_name}' from '#{src_name}'.")

    ts = src_sfi.timeSeries
    values = ts.values
    n = values.size

    if n == 0
      runner.registerWarning("FixedInterval schedule '#{src_name}' has zero data points; cannot generate binary ON schedule.")
      return nil
    end

    # Build binary ON values: >0 → 1, <=0 → 0
    on_values = OpenStudio::Vector.new(n, 0.0)
    (0...n).each do |i|
      on_values[i] = values[i] > 0.0 ? 1.0 : 0.0
    end

    interval_opt = ts.intervalLength
    unless interval_opt.is_initialized
      runner.registerWarning("TimeSeries for FixedInterval schedule '#{src_name}' has no intervalLength; falling back to original schedule.")
      return nil
    end
    interval_length = interval_opt.get

    start_dt   = ts.startDateTime
    start_date = start_dt.date
    units      = ts.units

    begin
      on_ts = OpenStudio::TimeSeries.new(start_date, interval_length, on_values, units)
    rescue StandardError => e
      runner.registerWarning("Failed to construct ON TimeSeries for FixedInterval schedule '#{src_name}': #{e}.")
      return nil
    end

    on_sfi = OpenStudio::Model::ScheduleFixedInterval.new(model)
    on_sfi.setTimeSeries(on_ts)
    on_sfi.setName(new_name)

    if src_sfi.scheduleTypeLimits.is_initialized
      on_sfi.setScheduleTypeLimits(src_sfi.scheduleTypeLimits.get)
    end

    begin
      on_sfi.setOutOfRangeValue(src_sfi.outOfRangeValue)
    rescue StandardError
    end

    begin
      on_sfi.setStartMonth(src_sfi.startMonth)
      on_sfi.setStartDay(src_sfi.startDay)
      on_sfi.setIntervalLength(src_sfi.intervalLength)
    rescue StandardError
    end

    runner.registerInfo("Created binary HVAC ON FixedInterval schedule '#{on_sfi.name}' from '#{src_name}'.")
    return on_sfi
  end

  # Create an inverted (HVAC OFF) ScheduleFixedInterval from an existing ScheduleFixedInterval.
  # OFF = 1 when original <= 0, OFF = 0 when original > 0.
  # Returns the new OFF schedule or nil if something goes wrong.
  def make_inverted_fixed_interval_off_schedule(model, runner, src_sfi, new_name)
    src_name = src_sfi.name.get
    runner.registerInfo("Creating inverted HVAC OFF FixedInterval schedule '#{new_name}' from '#{src_name}'.")

    ts = src_sfi.timeSeries
    values = ts.values
    n = values.size

    if n == 0
      runner.registerWarning("FixedInterval schedule '#{src_name}' has zero data points; cannot generate OFF schedule.")
      return nil
    end

    off_values = OpenStudio::Vector.new(n, 0.0)
    (0...n).each do |i|
      off_values[i] = values[i] > 0.0 ? 0.0 : 1.0
    end

    interval_opt = ts.intervalLength
    unless interval_opt.is_initialized
      runner.registerWarning("TimeSeries for FixedInterval schedule '#{src_name}' has no intervalLength; falling back to Always On OFF schedule.")
      return nil
    end
    interval_length = interval_opt.get

    start_dt   = ts.startDateTime
    start_date = start_dt.date
    units      = ts.units

    begin
      off_ts = OpenStudio::TimeSeries.new(start_date, interval_length, off_values, units)
    rescue StandardError => e
      runner.registerWarning("Failed to construct OFF TimeSeries for FixedInterval schedule '#{src_name}': #{e}.")
      return nil
    end

    off_sfi = OpenStudio::Model::ScheduleFixedInterval.new(model)
    off_sfi.setTimeSeries(off_ts)
    off_sfi.setName(new_name)

    if src_sfi.scheduleTypeLimits.is_initialized
      off_sfi.setScheduleTypeLimits(src_sfi.scheduleTypeLimits.get)
    end

    begin
      off_sfi.setOutOfRangeValue(src_sfi.outOfRangeValue)
    rescue StandardError
    end

    begin
      off_sfi.setStartMonth(src_sfi.startMonth)
      off_sfi.setStartDay(src_sfi.startDay)
      off_sfi.setIntervalLength(src_sfi.intervalLength)
    rescue StandardError
    end

    runner.registerInfo("Created HVAC OFF FixedInterval schedule '#{off_sfi.name}' from '#{src_name}'.")
    return off_sfi
  end
end

ConfigureSpaceInfiltrationDesignFlowRate.new.registerWithApplication
