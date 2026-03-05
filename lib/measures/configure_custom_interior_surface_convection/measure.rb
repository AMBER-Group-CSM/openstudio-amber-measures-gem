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

class ConfigureCustomInteriorSurfaceConvection < OpenStudio::Measure::ModelMeasure
  def name
    'Configure Custom Interior Surface Convection'
  end

  def description
    'Sets inside-face convection for selected surfaces using h = C · |ΔT|^n, with a second (reduced) coefficient and exponent for horizontal surfaces. Walls always use the baseline C,n. Floors/Ceilings switch between baseline vs reduced by the sign of ΔT. Recommended starting points (TARP-inspired): Walls C≈1.31, Horizontal enhanced C≈1.52, Horizontal reduced C≈0.76, n≈1/3.'
  end

  def modeler_description
    return "For selected opaque surfaces (interior+exterior), this attaches SurfaceProperty:ConvectionCoefficients on the INSIDE face and drives them via EMS. Law: h = C · |(T_si - T_air)|^n. Walls always use (C_base, n_base). Floors use (C_base, n_base) when RAW_DT>0 (surface warmer than air), else (C_red, n_red). Ceilings use (C_base, n_base) when RAW_DT<0 (surface cooler than air), else (C_red, n_red). Suggested seeds: Walls C≈1.31, Horizontal enhanced C≈1.52, Horizontal reduced C≈0.76, with n≈1/3. Choose C_base according to the surface category you're targeting."
  end

  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # What surface category to target (mutually exclusive per run)
    surface_choice = OpenStudio::Measure::OSArgument.makeChoiceArgument(
      'target_surface_type', ['Walls', 'Floors', 'Ceilings', 'InternalMass'], true
    )
    surface_choice.setDisplayName('Target Surface Category')
    surface_choice.setDefaultValue('Walls')
    args << surface_choice

    # Coefficients and exponents for the convection correlation
    coeff_base = OpenStudio::Measure::OSArgument.makeDoubleArgument('coeff_base', true)
    coeff_base.setDisplayName('Baseline Coefficient C_base (W/m2-K / K^n_base)')
    coeff_base.setDescription('Walls use this. Floors/Ceilings use this in the “enhanced” branch.')
    coeff_base.setDefaultValue(1.31)
    args << coeff_base

    coeff_red = OpenStudio::Measure::OSArgument.makeDoubleArgument('coeff_reduced', true)
    coeff_red.setDisplayName('Reduced Coefficient for Horizontal C_red (W/m2-K / K^n_red)')
    coeff_red.setDescription('Used only by Floors/Ceilings in the “reduced” branch.')
    coeff_red.setDefaultValue(0.76)
    args << coeff_red

    power_base = OpenStudio::Measure::OSArgument.makeDoubleArgument('power_base', true)
    power_base.setDisplayName('Exponent n_base')
    power_base.setDefaultValue(1.0 / 3.0)
    args << power_base

    power_reduced = OpenStudio::Measure::OSArgument.makeDoubleArgument('power_reduced', true)
    power_reduced.setDisplayName('Exponent n_red (reduced branch)')
    power_reduced.setDefaultValue(1.0 / 3.0)
    args << power_reduced

    overwrite = OpenStudio::Measure::OSArgument.makeBoolArgument('overwrite_existing', true)
    overwrite.setDisplayName('Update Inside Coefficient if SPCC Already Exists?')
    overwrite.setDefaultValue(true)
    args << overwrite

    report_hconv = OpenStudio::Measure::OSArgument.makeBoolArgument('report_hconv', false)
    report_hconv.setDisplayName('Report H_OUT, RAW_DT, and DT?')
    report_hconv.setDefaultValue(false)
    args << report_hconv

    im_enhanced = OpenStudio::Measure::OSArgument.makeBoolArgument('internal_mass_enhanced_branch', false)
    im_enhanced.setDisplayName('Internal Mass: Use Enhanced/Reduced Branch (like Floors/Ceilings)?')
    im_enhanced.setDescription('If true, internal mass uses enhanced vs reduced convection based on temperature direction (like floors/ceilings). If false, it uses the fixed (walls) branch.')
    im_enhanced.setDefaultValue(true)
    args << im_enhanced

    args
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    # Read inputs
    target_type        = runner.getStringArgumentValue('target_surface_type', user_arguments)
    coeff_base         = runner.getDoubleArgumentValue('coeff_base', user_arguments)
    coeff_red          = runner.getDoubleArgumentValue('coeff_reduced', user_arguments)
    power_base         = runner.getDoubleArgumentValue('power_base', user_arguments)
    power_reduced      = runner.getDoubleArgumentValue('power_reduced', user_arguments)
    overwrite_existing = runner.getBoolArgumentValue('overwrite_existing', user_arguments)
    report_hconv       = runner.getBoolArgumentValue('report_hconv', user_arguments)
    im_enhanced_branch = runner.getBoolArgumentValue('internal_mass_enhanced_branch', user_arguments)

    # ------- Scan & report inventory -------
    all_surfs = model.getSurfaces
    walls     = all_surfs.count { |s| s.surfaceType == 'Wall' }
    floors    = all_surfs.count { |s| s.surfaceType == 'Floor' }
    ceilings  = all_surfs.count { |s| s.surfaceType == 'RoofCeiling' }
    internal_mass = model.getInternalMasss.size

    runner.registerInitialCondition(
      "Args → target='#{target_type}', C_base=#{coeff_base}, C_red=#{coeff_red}, n_base=#{power_base}, n_red=#{power_reduced}, " \
      "overwrite_existing=#{overwrite_existing}, report_hconv=#{report_hconv}, internal_mass_enhanced_branch=#{im_enhanced_branch}. " \
      "Inventory: Walls=#{walls}, Floors=#{floors}, Ceilings≈#{ceilings}, InternalMass=#{internal_mass}. " \
      "CallingPoint=BeginZoneTimestepAfterInitHeatBalance."
    )

    # ------- Choose targets -------
    candidates =
      case target_type
      when 'Walls'
        model.getSurfaces.select { |srf| srf.surfaceType == 'Wall' }
      when 'Floors'
        model.getSurfaces.select { |srf| srf.surfaceType == 'Floor' }
      when 'Ceilings'
        model.getSurfaces.select { |srf| srf.surfaceType == 'RoofCeiling' }
      when 'InternalMass'
        model.getInternalMasss
      else
        []
      end

    if candidates.empty?
      runner.registerAsNotApplicable("No #{target_type.downcase} found — measure did nothing.")
      return true
    end
    runner.registerInfo("Target selection complete: #{candidates.size} #{target_type.downcase} surfaces to process.")

    # ------- Declare/reuse shared globals -------
    # RAW_DT, DT, H_OUT, HORIZ_ORIENT are global EMS variables reused across surfaces.
    existing_globals = model.getEnergyManagementSystemGlobalVariables
    created_globals = 0
    reused_globals = 0

    %w[RAW_DT DT H_OUT HORIZ_ORIENT].each do |n|
      if existing_globals.any? { |g| g.nameString == n }
        reused_globals += 1
        next
      end
      OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, n)
      created_globals += 1
    end
    runner.registerInfo("EMS globals prepared: created=#{created_globals}, reused=#{reused_globals} (RAW_DT, DT, H_OUT, HORIZ_ORIENT).")

    # ------- Iterate & apply -------
    applied = 0
    skipped_no_zone = 0
    skipped_spcc_locked = 0
    skipped_existing_conservative = 0
    skipped_air_boundary = 0

    # Limit detailed per-surface logging to first few items
    sample_log_limit = 6
    sample_logs = 0
    zone_air_sensors = {}

    candidates.each do |srf|
      is_internal_mass = srf.is_a?(OpenStudio::Model::InternalMass)

      # AirBoundary/Air Wall surfaces have no inside face temperature; skip them (not applicable to InternalMass)
      if !is_internal_mass && air_boundary_surface?(srf)
        skipped_air_boundary += 1
        runner.registerInfo("Skip: '#{srf.nameString}' is an AirBoundary/AirWall construction (no inside face temperature).") if sample_logs < sample_log_limit
        sample_logs += 1
        next
      end

      space = is_internal_mass ? srf.space : srf.space
      if space.empty? || space.get.thermalZone.empty?
        skipped_no_zone += 1
        runner.registerInfo("Skip: '#{srf.nameString}' has no space/zone.") if sample_logs < sample_log_limit
        sample_logs += 1
        next
      end
      zone = space.get.thermalZone.get

      # Attach / reuse SPCC: inside slot only
      spcc_opt = srf.surfacePropertyConvectionCoefficients
      spcc = nil
      inside_slot = nil

      if spcc_opt.is_initialized
        unless overwrite_existing
          skipped_existing_conservative += 1
          runner.registerInfo("Skip: '#{srf.nameString}' SPCC exists and overwrite=false.") if sample_logs < sample_log_limit
          sample_logs += 1
          next
        end
        spcc = spcc_opt.get
        loc1 = spcc.convectionCoefficient1Location.is_initialized ? spcc.convectionCoefficient1Location.get : nil
        loc2 = spcc.convectionCoefficient2Location.is_initialized ? spcc.convectionCoefficient2Location.get : nil

        # Find or free the Inside slot; otherwise skip if both are occupied
        if loc1 == 'Inside'
          inside_slot = 1
        elsif loc2 == 'Inside'
          inside_slot = 2
        elsif loc1.nil?
          inside_slot = 1
        elsif loc2.nil?
          inside_slot = 2
        else
          skipped_spcc_locked += 1
          runner.registerInfo("Skip: '#{srf.nameString}' SPCC slots full; no Inside slot free.") if sample_logs < sample_log_limit
          sample_logs += 1
          next
        end
      else
        spcc = OpenStudio::Model::SurfacePropertyConvectionCoefficients.new(srf)
        inside_slot = 1
      end

      base = ems_safe(srf.nameString)
      surface_key = srf.nameString[0, 100]

      # Clear out any prior run artifacts for this surface so a rerun replaces, not duplicates
      remove_surface_program_stack(model, base)
      purge_surface_outputs(model, base)

      # Constant schedule that EMS will overwrite each timestep
      sch = ensure_constant_schedule(model, base)

      spcc.setName("#{base}_Convection")
      if inside_slot == 1
        spcc.setConvectionCoefficient1Location('Inside')
        spcc.setConvectionCoefficient1Type('Schedule')
        spcc.setConvectionCoefficient1Schedule(sch)
      else
        spcc.setConvectionCoefficient2Location('Inside')
        spcc.setConvectionCoefficient2Type('Schedule')
        spcc.setConvectionCoefficient2Schedule(sch)
      end

      # OutputVariables FIRST, then Sensors bound to them
      zone_name = zone.nameString[0, 100]

      ov_zone_air = ensure_output_variable(model, 'Zone Mean Air Temperature', zone_name)
      ov_surf_ti = ensure_output_variable(model, 'Surface Inside Face Temperature', surface_key)

      sens_zone_air = ensure_zone_sensor(model, zone_name, zone_air_sensors, ov_zone_air)
      sens_surf_ti = ensure_surface_sensor(model, base, ov_surf_ti, surface_key)

      # Actuator on schedule value
      act = ensure_actuator(model, sch, base)

      # Per-surface program
      prog = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
      prog.setName("#{base}_Hconv_Prog")

      body = []
      body << "SET RAW_DT = #{sens_surf_ti.handle} - #{sens_zone_air.handle}"
      body << 'SET DT = @Abs RAW_DT'

      dual_branch = (target_type == 'Floors') || (target_type == 'Ceilings') || (target_type == 'InternalMass' && im_enhanced_branch)

      if target_type == 'Walls' || (target_type == 'InternalMass' && !im_enhanced_branch)
        body << "SET H_OUT = #{format('%.10f', coeff_base)} * (DT ^ #{format('%.10f', power_base)})"
      else
        # Floors/Ceilings: baseline vs reduced based on sign( RAW_DT * HORIZ_ORIENT )
        horiz_orient =
          case target_type
          when 'Floors'
            1
          when 'Ceilings'
            -1
          else
            1 # InternalMass: treat like floors (enhanced when surface warmer than air)
          end
        body << "SET HORIZ_ORIENT = #{horiz_orient}"
        body << 'IF ((RAW_DT * HORIZ_ORIENT) > 0)'
        body << "  SET H_OUT = #{format('%.10f', coeff_base)} * (DT ^ #{format('%.10f', power_base)})"
        body << 'ELSE'
        body << "  SET H_OUT = #{format('%.10f', coeff_red)} * (DT ^ #{format('%.10f', power_reduced)})"
        body << 'ENDIF'
      end

      body << "SET #{act.handle} = H_OUT"
      prog.setBody(body.join("\n"))

      # Call before surface heat balance with temps initialized
      pcm = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
      pcm.setName("#{base}_Hconv_PCM")
      pcm.setCallingPoint('BeginZoneTimestepAfterInitHeatBalance')
      pcm.addProgram(prog)

      if sample_logs < sample_log_limit
        runner.registerInfo("Configured surface '#{srf.nameString}'.")
      end
      sample_logs += 1

      if report_hconv
        ems_h = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, 'H_OUT')
        ems_h.setName("#{base}_Hconv_Coefficient")
        ems_h.setTypeOfDataInVariable('Averaged')
        ems_h.setUpdateFrequency('ZoneTimestep')
        ems_h.setEMSProgramOrSubroutineName(prog)
        ems_h.setUnits('W/m2-K')
        OpenStudio::Model::OutputVariable.new("#{base}_Hconv_Coefficient", model).tap { |ov| ov.setKeyValue('*'); ov.setReportingFrequency('Timestep') }

        ems_rawdt = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, 'RAW_DT')
        ems_rawdt.setName("#{base}_RAW_DT")
        ems_rawdt.setTypeOfDataInVariable('Averaged')
        ems_rawdt.setUpdateFrequency('ZoneTimestep')
        ems_rawdt.setEMSProgramOrSubroutineName(prog)
        ems_rawdt.setUnits('K')
        OpenStudio::Model::OutputVariable.new("#{base}_RAW_DT", model).tap { |ov| ov.setKeyValue('*'); ov.setReportingFrequency('Timestep') }

        ems_dt = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, 'DT')
        ems_dt.setName("#{base}_DT")
        ems_dt.setTypeOfDataInVariable('Averaged')
        ems_dt.setUpdateFrequency('ZoneTimestep')
        ems_dt.setEMSProgramOrSubroutineName(prog)
        ems_dt.setUnits('K')
        OpenStudio::Model::OutputVariable.new("#{base}_DT", model).tap { |ov| ov.setKeyValue('*'); ov.setReportingFrequency('Timestep') }

        runner.registerInfo("Added reporting outputs for '#{srf.nameString}' (H_OUT, RAW_DT, DT).") if sample_logs <= sample_log_limit
      end

      applied += 1
    end

    # Summarize outcomes
    runner.registerInfo("Complete: applied=#{applied}, skipped_no_zone=#{skipped_no_zone}, skipped_spcc_locked=#{skipped_spcc_locked}, skipped_existing_conservative=#{skipped_existing_conservative}, skipped_air_boundary=#{skipped_air_boundary}.")

    msg = []
    msg << "EMS inside convection configured for #{applied} #{target_type.downcase} surfaces."
    msg << "#{skipped_no_zone} skipped (no space/zone)." if skipped_no_zone > 0
    msg << "#{skipped_spcc_locked} skipped (SPCC both slots used; no Inside free)." if skipped_spcc_locked > 0
    msg << "#{skipped_existing_conservative} skipped (existing SPCC and overwrite_existing=false)." if skipped_existing_conservative > 0
    msg << "#{skipped_air_boundary} skipped (AirBoundary/Air Wall surfaces — no inside face temperature)." if skipped_air_boundary > 0
    msg << "Outputs enabled (per-surface) for H_OUT, RAW_DT, DT." if report_hconv
    runner.registerFinalCondition(msg.join(' '))

    true
  end

  private

  # EMS-safe token (leading letter, alnum+_, clamp)
  def ems_safe(str)
    s = str.to_s.gsub(/[^\w]/, '_')
    s = "N_#{s}" unless s[0] =~ /[A-Za-z]/
    s[0, 78]
  end

  def ensure_output_variable(model, variable_name, key_value)
    ov = model.getOutputVariables.find do |existing|
      existing.variableName == variable_name && existing.keyValue == key_value
    end
    ov ||= OpenStudio::Model::OutputVariable.new(variable_name, model)
    ov.setKeyValue(key_value)
    ov.setReportingFrequency('Timestep')
    ov
  end

  def ensure_zone_sensor(model, zone_name, cache, ov_zone_air)
    cache[zone_name] ||= begin
      existing = model.getEnergyManagementSystemSensors.find { |s| s.nameString == "#{ems_safe(zone_name)}_MeanAirTemp" }
      sensor = existing || OpenStudio::Model::EnergyManagementSystemSensor.new(model, ov_zone_air)
      sensor.setName("#{ems_safe(zone_name)}_MeanAirTemp")
      sensor.setKeyName(zone_name)
      sensor
    end
  end

  def ensure_surface_sensor(model, base, ov_surf_ti, surface_name)
    existing = model.getEnergyManagementSystemSensors.find { |s| s.nameString == "#{base}_InsideFaceTemp" }
    sensor = existing || OpenStudio::Model::EnergyManagementSystemSensor.new(model, ov_surf_ti)
    sensor.setName("#{base}_InsideFaceTemp")
    sensor.setKeyName(surface_name)
    sensor
  end

  def ensure_constant_schedule(model, base)
    sch_name = "#{base}_Hconv_Schedule"
    model.getScheduleConstants.select { |s| s.nameString.start_with?(sch_name) }.each(&:remove)
    sch = OpenStudio::Model::ScheduleConstant.new(model)
    sch.setName(sch_name)
    sch.setValue(1.0)
    sch
  end

  def ensure_actuator(model, schedule, base)
    act_name = "#{base}_Hconv_Act"
    model.getEnergyManagementSystemActuators.select { |a| a.nameString.start_with?(act_name) }.each(&:remove)
    act = OpenStudio::Model::EnergyManagementSystemActuator.new(schedule, 'Schedule:Constant', 'Schedule Value')
    act.setName(act_name)
    act
  end

  def remove_surface_program_stack(model, base)
    model.getEnergyManagementSystemProgramCallingManagers.select { |pcm| pcm.nameString.start_with?("#{base}_Hconv_PCM") }.each(&:remove)
    model.getEnergyManagementSystemPrograms.select { |prog| prog.nameString.start_with?("#{base}_Hconv_Prog") }.each(&:remove)
  end

  def purge_surface_outputs(model, base)
    model.getEnergyManagementSystemSensors.select { |s| s.nameString.start_with?("#{base}_InsideFaceTemp") }.each(&:remove)

    %w[Hconv_Coefficient RAW_DT DT].each do |suffix|
      name = "#{base}_#{suffix}"
      model.getEnergyManagementSystemOutputVariables.select { |o| o.nameString.start_with?(name) }.each(&:remove)
      model.getOutputVariables.select { |ov| ov.variableName.start_with?(name) }.each(&:remove)
    end
  end

  def air_boundary_surface?(srf)
    cons = srf.construction
    return false unless cons.is_initialized

    c = cons.get
    return true if c.respond_to?(:to_ConstructionAirBoundary) && c.to_ConstructionAirBoundary.is_initialized

    c.nameString.downcase.include?('air wall')
  end
end

ConfigureCustomInteriorSurfaceConvection.new.registerWithApplication
