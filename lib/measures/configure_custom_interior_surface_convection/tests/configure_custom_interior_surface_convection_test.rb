require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require 'fileutils'
require 'set'

require_relative '../measure'

class ConfigureCustomInteriorSurfaceConvectionTest < Minitest::Test
  def setup
    # Load example model and set up measure instance
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = "#{File.dirname(__FILE__)}/example_model.osm"
    loaded_model = translator.loadModel(path)
    assert(loaded_model.is_initialized, 'Test model failed to load.')

    @model = loaded_model.get
    @measure = ConfigureCustomInteriorSurfaceConvection.new
  end

  def test_argument_names
    # Verify argument interface (names and count)
    args = @measure.arguments(@model)
    names = args.map(&:name)

    assert_equal(8, names.size)
    assert_equal(
      %w[target_surface_type coeff_base coeff_reduced power_base power_reduced overwrite_existing report_hconv internal_mass_enhanced_branch],
      names
    )
  end

  def test_runs_twice_without_ems_global_conflicts
    # Walls then floors: globals reused and counts stable
    # First pass: apply to walls
    result1 = run_measure(@measure, @model, {
                            'target_surface_type' => 'Walls',
                            'coeff_base' => 0.655,
                            'coeff_reduced' => 0.76,
                            'power_base' => 1.0 / 3.0,
                            'power_reduced' => 1.0 / 3.0,
                            'overwrite_existing' => true,
                            'report_hconv' => false
                          })
    show_output(result1)
    assert_equal('Success', result1.value.valueName)
    assert_empty(result1.stepErrors)

    # Second pass: apply to floors on the same model (replicates user workflow)
    measure2 = ConfigureCustomInteriorSurfaceConvection.new
    result2 = run_measure(measure2, @model, {
                            'target_surface_type' => 'Floors',
                            'coeff_base' => 0.76,
                            'coeff_reduced' => 0.38,
                            'power_base' => 1.0 / 3.0,
                            'power_reduced' => 1.0 / 3.0,
                            'overwrite_existing' => true,
                            'report_hconv' => false
                          })
    show_output(result2)
    assert_equal('Success', result2.value.valueName)
    assert_empty(result2.stepErrors)

    # EMS globals should be reused, not duplicated
    globals = @model.getEnergyManagementSystemGlobalVariables.map(&:nameString)
    assert_equal(%w[DT HORIZ_ORIENT H_OUT RAW_DT].sort, globals.sort)

    # Verify at least one wall and one floor have an Inside schedule-driven coefficient
    wall = @model.getSurfaces.detect { |s| s.surfaceType == 'Wall' }
    floor = @model.getSurfaces.detect { |s| s.surfaceType == 'Floor' }
    refute_nil(wall, 'Test model missing a Wall surface')
    refute_nil(floor, 'Test model missing a Floor surface')

    assert(surface_has_inside_schedule?(wall))
    assert(surface_has_inside_schedule?(floor))

    FileUtils.mkdir_p("#{File.dirname(__FILE__)}/output")
    @model.save("#{File.dirname(__FILE__)}/output/twice_no_collision.osm", true)
  end

  def test_ceilings_detected_and_configured
    # Ceilings should be found and configured
    ceilings = @model.getSurfaces.select { |s| s.surfaceType == 'RoofCeiling' }
    ceiling_count = ceilings.size
    baseline_pcm = @model.getEnergyManagementSystemProgramCallingManagers.size

    skip 'Test model has no ceilings' if ceiling_count.zero?

    result = run_measure(@measure, @model, {
                           'target_surface_type' => 'Ceilings',
                           'coeff_base' => 0.76,
                           'coeff_reduced' => 0.38,
                           'power_base' => 1.0 / 3.0,
                           'power_reduced' => 1.0 / 3.0,
                           'overwrite_existing' => true,
                           'report_hconv' => false
                         })
    show_output(result)
    assert_equal('Success', result.value.valueName)

    # One PCM per ceiling surface
    assert_equal(baseline_pcm + ceiling_count, @model.getEnergyManagementSystemProgramCallingManagers.size)
    # At least one ceiling should have an inside schedule-driven coefficient
    assert(ceilings.any? { |s| surface_has_inside_schedule?(s) })
  end

  def test_rerun_same_type_refreshes_in_place
    # Two wall passes: refresh in place (no count growth) and pick up new coeff
    walls = @model.getSurfaces.select { |s| s.surfaceType == 'Wall' }
    target_walls = walls.reject { |s| air_boundary_surface?(s) }
    wall_count = target_walls.size
    baseline_pcm = @model.getEnergyManagementSystemProgramCallingManagers.size
    baseline_schedules = count_matching(@model.getScheduleConstants, /_Hconv_Schedule/)

    first_coeff = 0.9
    second_coeff = 1.5

    result1 = run_measure(@measure, @model, {
                            'target_surface_type' => 'Walls',
                            'coeff_base' => first_coeff,
                            'coeff_reduced' => 0.76,
                            'power_base' => 1.0 / 3.0,
                            'power_reduced' => 1.0 / 3.0,
                            'overwrite_existing' => true,
                            'report_hconv' => false
                          })
    show_output(result1)
    assert_equal('Success', result1.value.valueName)

    expected_pcm = baseline_pcm + wall_count
    assert_equal(expected_pcm, @model.getEnergyManagementSystemProgramCallingManagers.size)
    assert_equal(baseline_schedules + wall_count, count_matching(@model.getScheduleConstants, /_Hconv_Schedule/))

    # Rerun for walls with updated coefficient; counts should not grow
    measure2 = ConfigureCustomInteriorSurfaceConvection.new
    result2 = run_measure(measure2, @model, {
                            'target_surface_type' => 'Walls',
                            'coeff_base' => second_coeff,
                            'coeff_reduced' => 0.76,
                            'power_base' => 1.0 / 3.0,
                            'power_reduced' => 1.0 / 3.0,
                            'overwrite_existing' => true,
                            'report_hconv' => false
                          })
    show_output(result2)
    assert_equal('Success', result2.value.valueName)
    assert_equal(expected_pcm, @model.getEnergyManagementSystemProgramCallingManagers.size)
    assert_equal(baseline_schedules + wall_count, count_matching(@model.getScheduleConstants, /_Hconv_Schedule/))

    sample_wall = target_walls.first
    base = ems_safe(sample_wall.nameString)
    prog = @model.getEnergyManagementSystemPrograms.find { |p| p.nameString == "#{base}_Hconv_Prog" }
    refute_nil(prog, 'Expected refreshed EMS program for wall')
    assert_includes(prog.body, format('%.10f', second_coeff))
  end

  def test_air_boundary_walls_are_skipped
    # AirBoundary walls should be skipped (no EMS artifacts)
    wall = @model.getSurfaces.find { |s| s.surfaceType == 'Wall' }
    skip 'Test model has no walls' unless wall

    air_wall = OpenStudio::Model::ConstructionAirBoundary.new(@model)
    wall.setConstruction(air_wall)

    result = run_measure(@measure, @model, {
                           'target_surface_type' => 'Walls',
                           'coeff_base' => 0.9,
                           'coeff_reduced' => 0.76,
                           'power_base' => 1.0 / 3.0,
                           'power_reduced' => 1.0 / 3.0,
                           'overwrite_existing' => true,
                           'report_hconv' => false
                         })
    show_output(result)
    assert_equal('Success', result.value.valueName)

    base = ems_safe(wall.nameString)
    refute(@model.getEnergyManagementSystemSensors.any? { |s| s.nameString == "#{base}_InsideFaceTemp" },
           'AirBoundary wall should not receive EMS sensors')
  end

  def test_existing_spcc_respected_when_overwrite_false
    # overwrite=false: existing SPCC should block EMS creation
    wall = @model.getSurfaces.find { |s| s.surfaceType == 'Wall' && !air_boundary_surface?(s) }
    skip 'Test model has no suitable walls' unless wall

    spcc = OpenStudio::Model::SurfacePropertyConvectionCoefficients.new(wall)
    spcc.setConvectionCoefficient1Location('Inside')
    spcc.setConvectionCoefficient1Type('Value')
    spcc.setConvectionCoefficient1(1.23)

    result = run_measure(@measure, @model, {
                           'target_surface_type' => 'Walls',
                           'coeff_base' => 0.9,
                           'coeff_reduced' => 0.76,
                           'power_base' => 1.0 / 3.0,
                           'power_reduced' => 1.0 / 3.0,
                           'overwrite_existing' => false,
                           'report_hconv' => false
                         })
    show_output(result)
    assert_equal('Success', result.value.valueName)

    base = ems_safe(wall.nameString)
    refute(@model.getEnergyManagementSystemPrograms.any? { |p| p.nameString == "#{base}_Hconv_Prog" },
           'overwrite_existing=false should not create EMS program for a wall with an existing SPCC')
    refute(@model.getEnergyManagementSystemProgramCallingManagers.any? { |pcm| pcm.nameString == "#{base}_Hconv_PCM" },
           'overwrite_existing=false should not create PCM for a wall with an existing SPCC')
  end

  def test_sensor_keys_exist_in_translated_idf
    # Rename surfaces (spaces/hyphens/long) then FT and confirm sensors point to real surfaces
    target_walls = @model.getSurfaces.select { |s| s.surfaceType == 'Wall' }.first(4)
    rename_map = [
      'L1BreakroomDiningWall180a',
      'L1 Breakroom-Dining-Wall180-b',
      'L1 Breakroom-Dining-Wall270-b',
      'L1 Conference 1-Wall090-a'
    ]
    target_walls.each_with_index do |srf, idx|
      srf.setName(rename_map[idx])
    end

    result = run_measure(@measure, @model, {
                           'target_surface_type' => 'Walls',
                           'coeff_base' => 1.1,
                           'coeff_reduced' => 0.7,
                           'power_base' => 1.0 / 3.0,
                           'power_reduced' => 1.0 / 3.0,
                           'overwrite_existing' => true,
                           'report_hconv' => false
                         })
    show_output(result)
    assert_equal('Success', result.value.valueName)

    idf = forward_translate(@model)
    surface_names = idf_surface_and_internal_mass_names(idf)

    sensors = idf.objects.select { |obj| obj.iddObject.name == 'EnergyManagementSystem:Sensor' }
    missing = missing_sensor_keys(sensors, surface_names)
    assert(missing.empty?, "Expected EMS sensors to reference existing IDF surface names; missing keys: #{missing.join(', ')}")
  end

  def test_internal_mass_convection_is_configured
    # Create or reuse an internal mass object and ensure the measure configures it
    im = ensure_internal_mass(@model)

    result = run_measure(@measure, @model, {
                           'target_surface_type' => 'InternalMass',
                           'coeff_base' => 0.8,
                           'coeff_reduced' => 0.5,
                           'power_base' => 1.0 / 3.0,
                           'power_reduced' => 1.0 / 3.0,
                           'overwrite_existing' => true,
                           'report_hconv' => false
                         })
    show_output(result)
    assert_equal('Success', result.value.valueName)

    spcc_opt = im.surfacePropertyConvectionCoefficients
    assert(spcc_opt.is_initialized, 'Internal mass should have SPCC after measure run')
    spcc = spcc_opt.get
    assert_equal('Inside', spcc.convectionCoefficient1Location.get)
    assert_equal('Schedule', spcc.convectionCoefficient1Type.get)
    base = ems_safe(im.nameString)
    assert_includes(spcc.convectionCoefficient1Schedule.get.nameString, "#{base}_Hconv_Schedule")

    idf = forward_translate(@model)
    names = idf_surface_and_internal_mass_names(idf)
    sensors = idf.objects.select { |obj| obj.iddObject.name == 'EnergyManagementSystem:Sensor' }
    missing = missing_sensor_keys(sensors, names)
    assert(missing.empty?, "Expected EMS sensors to reference existing IDF surface/internal mass names; missing keys: #{missing.join(', ')}")
  end

  def test_internal_mass_single_branch_mode
    # Internal mass with single branch (like walls): program should omit HORIZ_ORIENT logic
    im = ensure_internal_mass(@model)

    result = run_measure(@measure, @model, {
                           'target_surface_type' => 'InternalMass',
                           'coeff_base' => 1.2,
                           'coeff_reduced' => 0.6,
                           'power_base' => 1.0 / 3.0,
                           'power_reduced' => 1.0 / 3.0,
                           'overwrite_existing' => true,
                           'report_hconv' => false,
                           'internal_mass_enhanced_branch' => false
                         })
    show_output(result)
    assert_equal('Success', result.value.valueName)

    base = ems_safe(im.nameString)
    prog = @model.getEnergyManagementSystemPrograms.find { |p| p.nameString == "#{base}_Hconv_Prog" }
    refute_nil(prog, 'Expected EMS program for internal mass')
    refute_includes(prog.body, 'HORIZ_ORIENT', 'Single-branch internal mass should not include enhanced/reduced switch')
  end

  private

  def build_argument_map(measure, model, args_hash)
    # Helper: convert hash to argument map
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.key?(arg.name)
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    argument_map
  end

  def run_measure(measure, model, args_hash)
    # Helper: run measure with a fresh runner
    osw = OpenStudio::WorkflowJSON.new
    runner = OpenStudio::Measure::OSRunner.new(osw)
    argument_map = build_argument_map(measure, model, args_hash)
    measure.run(model, runner, argument_map)
    runner.result
  end

  def surface_has_inside_schedule?(surface)
    # Does the surface have an inside schedule-driven convection coefficient?
    spcc_opt = surface.surfacePropertyConvectionCoefficients
    return false unless spcc_opt.is_initialized

    spcc = spcc_opt.get
    slot1_inside = spcc.convectionCoefficient1Location.is_initialized && spcc.convectionCoefficient1Location.get == 'Inside'
    slot2_inside = spcc.convectionCoefficient2Location.is_initialized && spcc.convectionCoefficient2Location.get == 'Inside'

    slot1_schedule = spcc.convectionCoefficient1Type.is_initialized && spcc.convectionCoefficient1Type.get == 'Schedule'
    slot2_schedule = spcc.convectionCoefficient2Type.is_initialized && spcc.convectionCoefficient2Type.get == 'Schedule'

    (slot1_inside && slot1_schedule) || (slot2_inside && slot2_schedule)
  end

  def count_matching(objects, regex)
    objects.count { |obj| obj.nameString.match?(regex) }
  end

  def forward_translate(model)
    # Forward translate to IDF for sensor key validation
    ft = OpenStudio::EnergyPlus::ForwardTranslator.new
    idf = ft.translateModel(model)
    refute_nil(idf, 'Forward translation failed')
    idf
  end

  def idf_surface_and_internal_mass_names(idf)
    surf_names = idf.objects.select { |obj| obj.iddObject.name == 'BuildingSurface:Detailed' }.map { |obj| obj.getString(0).get }
    im_names = idf.objects.select { |obj| obj.iddObject.name == 'InternalMass' }.map { |obj| obj.getString(0).get }
    Set.new(surf_names + im_names)
  end

  def missing_sensor_keys(sensor_objs, surface_names)
    sensor_objs.map do |obj|
      var_name_opt = obj.getString(1)
      next nil unless var_name_opt.is_initialized
      next nil unless var_name_opt.get == 'Surface Inside Face Temperature'

      key_opt = obj.getString(2)
      next nil unless key_opt.is_initialized

      key = key_opt.get
      surface_names.include?(key) ? nil : key
    end.compact.uniq
  end

  def ems_safe(str)
    s = str.to_s.gsub(/[^\w]/, '_')
    s = "N_#{s}" unless s[0] =~ /[A-Za-z]/
    s[0, 78]
  end

  def air_boundary_surface?(srf)
    cons = srf.construction
    return false unless cons.is_initialized

    c = cons.get
    return true if c.respond_to?(:to_ConstructionAirBoundary) && c.to_ConstructionAirBoundary.is_initialized

    c.nameString.downcase.include?('air wall')
  end

  def ensure_internal_mass(model)
    existing = model.getInternalMasss
    return existing.first unless existing.empty?

    space = model.getSpaces.first
    material = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    material.setName('IM Test Material')
    material.setRoughness('MediumRough')
    material.setThickness(0.1)
    material.setThermalConductivity(0.5)
    material.setDensity(800.0)
    material.setSpecificHeat(1200.0)

    constr = OpenStudio::Model::Construction.new(model)
    constr.insertLayer(0, material)

    im_def = OpenStudio::Model::InternalMassDefinition.new(model)
    im_def.setName('IM Test Def')
    im_def.setConstruction(constr)
    im_def.setSurfaceAreaperSpaceFloorArea(0.5)

    im = OpenStudio::Model::InternalMass.new(im_def)
    im.setName('IM_Test_Object')
    im.setSpace(space) if space
    im
  end
end
