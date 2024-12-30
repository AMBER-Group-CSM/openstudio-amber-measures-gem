class CreateAndAssignCLTConstructionSet < OpenStudio::Measure::ModelMeasure
  # Human-readable name
  def name
    return 'Create and Assign CLT Construction Set'
  end

  # Human-readable description
  def description
    return 'This measure allows a modeler to change the construction set in their model for a CLT construction set. The measure includes options for CLT exterior walls, CLT interior floors, and roof. It also provides options to infer insulation levels from existing constructions, replace external walls, and specify custom thickness for CLT layers. Additionally, it allows duplicating existing construction sets to preserve originals and includes detailed R-value calculations in construction names.'
  end

  # Human-readable description of modeling approach
  def modeler_description
    return 'This measure enables the assignment of CLT construction sets to a model. Features include specifying CLT types and plies for inner floors, roofs, and walls, with the option to use custom thicknesses. The measure can infer insulation levels based on existing constructions, splitting required R-values between exterior and interior insulation if specified. It supports duplicating existing construction sets for preservation and ensures that inner floors and ceilings share the same construction. The measure also calculates and includes the effective R-value in the construction names.'
  end

  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # String argument for excluding construction sets
    exclude_construction_sets = OpenStudio::Measure::OSArgument::makeStringArgument('exclude_construction_sets', false)
    exclude_construction_sets.setDisplayName('Exclude Construction Sets')
    exclude_construction_sets.setDescription('Comma-separated list of strings to match construction set names against. If a match is found, those construction sets will be excluded from modification.')
    exclude_construction_sets.setDefaultValue('')
    args << exclude_construction_sets

    # Boolean for duplicating all construction sets
    duplicate_all_sets = OpenStudio::Measure::OSArgument::makeBoolArgument('duplicate_all_sets', true)
    duplicate_all_sets.setDisplayName('Duplicate All Construction Sets')
    duplicate_all_sets.setDescription('If true, all existing construction sets will be duplicated and modified, preserving the originals.')
    duplicate_all_sets.setDefaultValue(true)
    args << duplicate_all_sets

    # Boolean for using custom thickness for Inner Floor
    use_custom_inner_floor_thickness = OpenStudio::Measure::OSArgument::makeBoolArgument('use_custom_inner_floor_thickness', true)
    use_custom_inner_floor_thickness.setDisplayName('Use Custom Inner Floor Thickness')
    use_custom_inner_floor_thickness.setDescription('If true, the specified custom thickness will be used for the inner floor CLT. Otherwise, the thickness will be calculated based on the selected ply.')
    use_custom_inner_floor_thickness.setDefaultValue(false)
    args << use_custom_inner_floor_thickness

    # Boolean for using custom thickness for Roof
    use_custom_roof_thickness = OpenStudio::Measure::OSArgument::makeBoolArgument('use_custom_roof_thickness', true)
    use_custom_roof_thickness.setDisplayName('Use Custom Roof Thickness')
    use_custom_roof_thickness.setDescription('If true, the specified custom thickness will be used for the roof CLT. Otherwise, the thickness will be calculated based on the selected ply.')
    use_custom_roof_thickness.setDefaultValue(false)
    args << use_custom_roof_thickness

    # Checkbox for replacing external walls
    replace_external_walls = OpenStudio::Measure::OSArgument::makeBoolArgument('replace_external_walls', true)
    replace_external_walls.setDisplayName('Replace External Walls with CLT')
    replace_external_walls.setDescription('If true, the external walls will be replaced with CLT constructions.')
    replace_external_walls.setDefaultValue(false)
    args << replace_external_walls

    # Boolean for using custom thickness for Wall
    use_custom_wall_thickness = OpenStudio::Measure::OSArgument::makeBoolArgument('use_custom_wall_thickness', true)
    use_custom_wall_thickness.setDisplayName('Use Custom Wall Thickness')
    use_custom_wall_thickness.setDescription('If true, the specified custom thickness will be used for the wall CLT. Otherwise, the thickness will be calculated based on the selected ply.')
    use_custom_wall_thickness.setDefaultValue(false)
    args << use_custom_wall_thickness
    
    # Boolean for inferring insulation levels from existing constructions
    infer_insulation_levels = OpenStudio::Measure::OSArgument::makeBoolArgument('infer_insulation_levels', true)
    infer_insulation_levels.setDisplayName('Infer Insulation Levels from Existing Constructions')
    infer_insulation_levels.setDescription('If true, the measure will analyze existing wall and roof constructions to infer insulation levels and apply them to the new CLT constructions.')
    infer_insulation_levels.setDefaultValue(false)
    args << infer_insulation_levels

    # Dropdown for Inner Floor CLT Type
    inner_floor_clt_type = OpenStudio::Measure::OSArgument::makeChoiceArgument('inner_floor_clt_type', ['SPF', 'DF'], true)
    inner_floor_clt_type.setDisplayName('Inner Floor CLT Type')
    inner_floor_clt_type.setDescription('Select the type of CLT for the inner floor.')
    inner_floor_clt_type.setDefaultValue('SPF')
    args << inner_floor_clt_type

    # Dropdown for Inner Floor CLT Ply
    inner_floor_clt_ply = OpenStudio::Measure::OSArgument::makeChoiceArgument('inner_floor_clt_ply', ['3', '5', '7', '9', '11'], true)
    inner_floor_clt_ply.setDisplayName('Inner Floor CLT Ply')
    inner_floor_clt_ply.setDescription('Select the number of plies for the inner floor CLT.')
    inner_floor_clt_ply.setDefaultValue('3')
    args << inner_floor_clt_ply

    # Double for Inner Floor CLT Thickness
    inner_floor_clt_thickness = OpenStudio::Measure::OSArgument::makeDoubleArgument('inner_floor_clt_thickness', true)
    inner_floor_clt_thickness.setDisplayName('Custom Inner Floor CLT Thickness')
    inner_floor_clt_thickness.setDescription('Specify the custom thickness for the inner floor CLT if "Use Custom Inner Floor Thickness" is true.')
    inner_floor_clt_thickness.setDefaultValue(0.1016)
    args << inner_floor_clt_thickness

    # Dropdown for Roof CLT Type
    roof_clt_type = OpenStudio::Measure::OSArgument::makeChoiceArgument('roof_clt_type', ['SPF', 'DF'], true)
    roof_clt_type.setDisplayName('Roof CLT Type')
    roof_clt_type.setDescription('Select the type of CLT for the roof.')
    roof_clt_type.setDefaultValue('SPF')
    args << roof_clt_type

    # Dropdown for Roof CLT Ply
    roof_clt_ply = OpenStudio::Measure::OSArgument::makeChoiceArgument('roof_clt_ply', ['3', '5', '7', '9', '11'], true)
    roof_clt_ply.setDisplayName('Roof CLT Ply')
    roof_clt_ply.setDescription('Select the number of plies for the roof CLT.')
    roof_clt_ply.setDefaultValue('3')
    args << roof_clt_ply

    # Double for Roof CLT Thickness
    roof_clt_thickness = OpenStudio::Measure::OSArgument::makeDoubleArgument('roof_clt_thickness', true)
    roof_clt_thickness.setDisplayName('Custom Roof CLT Thickness')
    roof_clt_thickness.setDescription('Specify the custom thickness for the roof CLT if "Use Custom Roof Thickness" is true.')
    roof_clt_thickness.setDefaultValue(0.1715)
    args << roof_clt_thickness

    # Double for Roof insulation R-value
    roof_insulation_r_value = OpenStudio::Measure::OSArgument::makeDoubleArgument('roof_insulation_r_value', true)
    roof_insulation_r_value.setDisplayName('Roof Insulation R-value')
    roof_insulation_r_value.setDescription('Specify the R-value for the roof insulation.')
    roof_insulation_r_value.setDefaultValue(5.28)
    args << roof_insulation_r_value

    # Dropdown for Facade Layer with default 'None'
    facade_layer = OpenStudio::Measure::OSArgument::makeChoiceArgument('facade_layer', ['None', 'Brick', 'Stucco', 'Metal Surface'], true)
    facade_layer.setDisplayName('Facade Layer')
    facade_layer.setDescription('Select the facade layer to be applied on the exterior walls.')
    facade_layer.setDefaultValue('None')
    args << facade_layer

    # Dropdown for Outer Insulation
    outer_insulation = OpenStudio::Measure::OSArgument::makeChoiceArgument('outer_insulation', ['None', 'Mineral Fiberboard', 'Polyiso'], true)
    outer_insulation.setDisplayName('Exterior Insulation')
    outer_insulation.setDescription('Select the type of outer insulation for the exterior walls.')
    outer_insulation.setDefaultValue('Polyiso')
    args << outer_insulation

    # Double for Exterior insulation R-value
    exterior_insulation_r_value = OpenStudio::Measure::OSArgument::makeDoubleArgument('exterior_insulation_r_value', true)
    exterior_insulation_r_value.setDisplayName('Exterior Insulation R-value')
    exterior_insulation_r_value.setDescription('Specify the R-value for the exterior insulation.')
    exterior_insulation_r_value.setDefaultValue(5.28)
    args << exterior_insulation_r_value

    # Dropdown for CLT Layer
    clt_layer = OpenStudio::Measure::OSArgument::makeChoiceArgument('clt_layer', ['None', 'SPF', 'DF'], true)
    clt_layer.setDisplayName('CLT Layer')
    clt_layer.setDescription('Select the type of CLT layer to be used.')
    clt_layer.setDefaultValue('SPF')
    args << clt_layer

    # Dropdown for Wall CLT Ply
    wall_clt_ply = OpenStudio::Measure::OSArgument::makeChoiceArgument('wall_clt_ply', ['3', '5', '7', '9', '11'], true)
    wall_clt_ply.setDisplayName('Wall CLT Ply')
    wall_clt_ply.setDescription('Select the number of plies for the wall CLT.')
    wall_clt_ply.setDefaultValue('3')
    args << wall_clt_ply

    # Double for Wall CLT Layer Thickness
    wall_clt_layer_thickness = OpenStudio::Measure::OSArgument::makeDoubleArgument('wall_clt_layer_thickness', true)
    wall_clt_layer_thickness.setDisplayName('Custom Wall CLT Layer Thickness')
    wall_clt_layer_thickness.setDescription('Specify the custom thickness for the wall CLT if "Use Custom Wall Thickness" is true.')
    wall_clt_layer_thickness.setDefaultValue(0.1016)
    args << wall_clt_layer_thickness

    # Dropdown for Inner Insulation with default 'None'
    inner_insulation = OpenStudio::Measure::OSArgument::makeChoiceArgument('inner_insulation', ['None', 'Fiberglass Batt', 'Spray Foam'], true)
    inner_insulation.setDisplayName('Inner Insulation')
    inner_insulation.setDescription('Select the type of inner insulation for the interior walls.')
    inner_insulation.setDefaultValue('None')
    args << inner_insulation

    # Double for Interior insulation R-value
    interior_insulation_r_value = OpenStudio::Measure::OSArgument::makeDoubleArgument('interior_insulation_r_value', true)
    interior_insulation_r_value.setDisplayName('Interior Insulation R-value')
    interior_insulation_r_value.setDescription('Specify the R-value for the interior insulation.')
    interior_insulation_r_value.setDefaultValue(0)
    args << interior_insulation_r_value

    # Dropdown for Inner Wall with default 'None'
    inner_wall = OpenStudio::Measure::OSArgument::makeChoiceArgument('inner_wall', ['None', 'Gypsum'], true)
    inner_wall.setDisplayName('Inner Wall Face Layer')
    inner_wall.setDescription('Select the type of inner wall face layer.')
    inner_wall.setDefaultValue('None')
    args << inner_wall

    return args
  end

  def validate_arguments(runner, user_arguments)
    errors = []
    use_custom_inner_floor_thickness = runner.getBoolArgumentValue('use_custom_inner_floor_thickness', user_arguments)
    inner_floor_clt_thickness = runner.getDoubleArgumentValue('inner_floor_clt_thickness', user_arguments)
    use_custom_roof_thickness = runner.getBoolArgumentValue('use_custom_roof_thickness', user_arguments)
    roof_clt_thickness = runner.getDoubleArgumentValue('roof_clt_thickness', user_arguments)
    use_custom_wall_thickness = runner.getBoolArgumentValue('use_custom_wall_thickness', user_arguments)
    wall_clt_layer_thickness = runner.getDoubleArgumentValue('wall_clt_layer_thickness', user_arguments)
    exterior_insulation_r_value = runner.getDoubleArgumentValue('exterior_insulation_r_value', user_arguments)
    interior_insulation_r_value = runner.getDoubleArgumentValue('interior_insulation_r_value', user_arguments)
    roof_insulation_r_value = runner.getDoubleArgumentValue('roof_insulation_r_value', user_arguments)

    runner.registerInfo("Validating arguments...")

    if use_custom_inner_floor_thickness && inner_floor_clt_thickness <= 0
      errors << "Invalid inner_floor_clt_thickness: #{inner_floor_clt_thickness}"
    end

    if use_custom_roof_thickness && roof_clt_thickness <= 0
      errors << "Invalid roof_clt_thickness: #{roof_clt_thickness}"
    end

    if use_custom_wall_thickness && wall_clt_layer_thickness <= 0
      errors << "Invalid wall_clt_layer_thickness: #{wall_clt_layer_thickness}"
    end

    if exterior_insulation_r_value < 0
      errors << "Invalid exterior_insulation_r_value: #{exterior_insulation_r_value}"
    end

    if interior_insulation_r_value < 0
      errors << "Invalid interior_insulation_r_value: #{interior_insulation_r_value}"
    end

    if roof_insulation_r_value < 0
      errors << "Invalid roof_insulation_r_value: #{roof_insulation_r_value}"
    end

    errors.each { |error| runner.registerError(error) }

    return errors
  end

  def create_material(model, name, roughness, thickness, conductivity, density, specific_heat, thermal_absorptance = 0.9, solar_absorptance = 0.7, visible_absorptance = 0.7)
    material = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    material.setName(name)
    material.setRoughness(roughness)
    material.setThickness(thickness)
    material.setConductivity(conductivity)
    material.setDensity(density)
    material.setSpecificHeat(specific_heat)
    material.setThermalAbsorptance(thermal_absorptance)
    material.setSolarAbsorptance(solar_absorptance)
    material.setVisibleAbsorptance(visible_absorptance)
    material
  end

  def define_material_properties
    {
      'SPF' => ["CLT - SPF", "Rough", 0.18, 0.101, 426, 1236],
      'DF' => ["CLT - DF", "Rough", 0.18, 0.111, 477, 1236],
      'Lightweight Concrete' => ["Lightweight Concrete", "MediumRough", 0.0508, 0.53, 1280, 840],
      'Polyiso' => ["Polyiso Insulation", "Rough", 0.0508, 0.02, 32, 920],
      'Brick' => ["Exterior Brick", "MediumRough", 0.1016, 0.89, 1920, 790],
      'Stucco' => ["Stucco", "Smooth", 0.0254, 0.72, 1856, 840],
      'Metal Surface' => ["Exterior Metal surface", "Smooth", 0.0008, 45.28, 7824, 500],
      'Mineral Fiberboard' => ["Mineral fiberboard", "Rough", 0.025, 0.037, 160, 800],
      'Gypsum' => ["Exterior Gypsum Board", "MediumSmooth", 0.019, 0.16, 800, 1090],
      'Spray Foam' => ["Cellular Polyurethane", "Rough", 0.025, 0.0245, 24, 1590],
      'Fiberglass Batt' => ["Fiberglass Batt", "VeryRough", 0.0894, 0.05, 19, 960]
    }
  end

  def get_or_create_material(model, runner, material_name, material_properties, created_materials, custom_name = nil, thickness: nil, r_value: nil)
    return nil if material_name == 'None'
    name_to_use = custom_name || material_name

    # chekcing to make sure we don't have r_value and thickness for creating our material
    if r_value != nil && thickness != nil
      runner.registerError("Passed values for thickness and r_value for creating a material, choose one or the other. This should be a developer only bug.")
    end

    unless created_materials.key?(name_to_use)
      # material = model.getMaterialByName(name_to_use)
      # if material.empty?
      properties = material_properties[material_name]
      runner.registerInfo("Creating material: #{name_to_use}")
      created_materials[name_to_use] = create_material(model, name_to_use, *properties[1..-1])
      if r_value != nil
        thickness = r_value * created_materials[name_to_use].conductivity
        runner.registerInfo("Calculated thickness #{thickness.round(2)} for material #{name_to_use} based on target R-value of #{r_value.round(2)}")
      end
      if thickness != nil
        runner.registerInfo("Updating #{name_to_use} with custom thickness #{thickness.round(2)}")
        created_materials[name_to_use].setThickness(thickness)
      end
      # end
    else
      material = model.getMaterialByName(name_to_use)
      runner.registerInfo("Using existing material: #{name_to_use}")
      created_materials[name_to_use] = material.get
    end
    
    return created_materials[name_to_use]
  end

  def create_construction(model, name, layers)
    construction = OpenStudio::Model::Construction.new(model)
    construction.setName(name)
    layers.each_with_index do |layer, index|
      construction.insertLayer(index, layer)
      runner.registerInfo("Added layer #{layer.name} to construction #{name}")
    end
    construction
  end

  def report_initial_conditions(model, runner)
    num_materials = model.getMaterials.size
    num_constructions = model.getConstructions.size
    num_construction_sets = model.getDefaultConstructionSets.size
    default_construction_set_name = model.getBuilding.defaultConstructionSet.is_initialized ? model.getBuilding.defaultConstructionSet.get.name.get : "None"

    runner.registerInitialCondition("The model started with #{num_materials} materials, #{num_constructions} constructions, and #{num_construction_sets}. The default construction set was '#{default_construction_set_name}'.")
  end

  def report_final_conditions(model, runner, any_construction_updated)
    num_materials = model.getMaterials.size
    num_constructions = model.getConstructions.size
    num_construction_sets = model.getDefaultConstructionSets.size
    default_construction_set_name = model.getBuilding.defaultConstructionSet.is_initialized ? model.getBuilding.defaultConstructionSet.get.name.get : "None"

    message = "The model ended with #{num_materials} materials, #{num_constructions} constructions, and #{num_construction_sets}. The default construction set is now '#{default_construction_set_name}'."
    if any_construction_updated
      message += " Created new CLT constructions and assigned them to new construction sets."
    else
      message += " No construction sets were updated."
    end

    runner.registerFinalCondition(message)
  end

  # Helper method to clone a construction set manually
  def clone_construction_set(model, runner, original_set, cloned_set)
    if original_set.defaultExteriorSurfaceConstructions.is_initialized
      original_exterior_constructions = original_set.defaultExteriorSurfaceConstructions.get
      cloned_exterior_constructions = original_exterior_constructions.clone(model).to_DefaultSurfaceConstructions.get
      cloned_set.setDefaultExteriorSurfaceConstructions(cloned_exterior_constructions)
    end

    if original_set.defaultInteriorSurfaceConstructions.is_initialized
      original_interior_constructions = original_set.defaultInteriorSurfaceConstructions.get
      cloned_interior_constructions = original_interior_constructions.clone(model).to_DefaultSurfaceConstructions.get
      cloned_set.setDefaultInteriorSurfaceConstructions(cloned_interior_constructions)
    end

    if original_set.defaultGroundContactSurfaceConstructions.is_initialized
      original_ground_contact_constructions = original_set.defaultGroundContactSurfaceConstructions.get
      cloned_ground_contact_constructions = original_ground_contact_constructions.clone(model).to_DefaultSurfaceConstructions.get
      cloned_set.setDefaultGroundContactSurfaceConstructions(cloned_ground_contact_constructions)
    end

    if original_set.defaultExteriorSubSurfaceConstructions.is_initialized
      original_exterior_sub_constructions = original_set.defaultExteriorSubSurfaceConstructions.get
      cloned_exterior_sub_constructions = original_exterior_sub_constructions.clone(model).to_DefaultSubSurfaceConstructions.get
      cloned_set.setDefaultExteriorSubSurfaceConstructions(cloned_exterior_sub_constructions)
    end

    if original_set.defaultInteriorSubSurfaceConstructions.is_initialized
      original_interior_sub_constructions = original_set.defaultInteriorSubSurfaceConstructions.get
      cloned_interior_sub_constructions = original_interior_sub_constructions.clone(model).to_DefaultSubSurfaceConstructions.get
      cloned_set.setDefaultInteriorSubSurfaceConstructions(cloned_interior_sub_constructions)
    end
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # Use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      runner.registerError("User arguments validation failed.")
      return false
    end

    # Report initial conditions
    report_initial_conditions(model, runner)

    # Assign the user inputs to variables
    exclude_construction_sets = runner.getStringArgumentValue('exclude_construction_sets', user_arguments)
    inner_floor_clt_type = runner.getStringArgumentValue('inner_floor_clt_type', user_arguments)
    inner_floor_clt_ply = runner.getStringArgumentValue('inner_floor_clt_ply', user_arguments)
    use_custom_inner_floor_thickness = runner.getBoolArgumentValue('use_custom_inner_floor_thickness', user_arguments)
    inner_floor_clt_thickness = runner.getDoubleArgumentValue('inner_floor_clt_thickness', user_arguments)
    roof_clt_type = runner.getStringArgumentValue('roof_clt_type', user_arguments)
    roof_clt_ply = runner.getStringArgumentValue('roof_clt_ply', user_arguments)
    use_custom_roof_thickness = runner.getBoolArgumentValue('use_custom_roof_thickness', user_arguments)
    roof_clt_thickness = runner.getDoubleArgumentValue('roof_clt_thickness', user_arguments)
    replace_external_walls = runner.getBoolArgumentValue('replace_external_walls', user_arguments)
    facade_layer = runner.getStringArgumentValue('facade_layer', user_arguments)
    outer_insulation = runner.getStringArgumentValue('outer_insulation', user_arguments)
    clt_layer = runner.getStringArgumentValue('clt_layer', user_arguments)
    inner_insulation = runner.getStringArgumentValue('inner_insulation', user_arguments)
    inner_wall = runner.getStringArgumentValue('inner_wall', user_arguments)
    exterior_insulation_r_value = runner.getDoubleArgumentValue('exterior_insulation_r_value', user_arguments)
    interior_insulation_r_value = runner.getDoubleArgumentValue('interior_insulation_r_value', user_arguments)
    roof_insulation_r_value = runner.getDoubleArgumentValue('roof_insulation_r_value', user_arguments)
    wall_clt_ply = runner.getStringArgumentValue('wall_clt_ply', user_arguments)
    use_custom_wall_thickness = runner.getBoolArgumentValue('use_custom_wall_thickness', user_arguments)
    wall_clt_layer_thickness = runner.getDoubleArgumentValue('wall_clt_layer_thickness', user_arguments)
    duplicate_all_sets = runner.getBoolArgumentValue('duplicate_all_sets', user_arguments)
    infer_insulation_levels = runner.getBoolArgumentValue('infer_insulation_levels', user_arguments)

    # Validate argument values
    errors = validate_arguments(runner, user_arguments)
    unless errors.empty?
      errors.each { |error| runner.registerError(error) }
      return false
    end

    runner.registerInfo("All argument values are valid.")

    # Define material properties
    material_properties = define_material_properties
    created_materials = {}

    # Parse exclude construction sets argument
    exclude_construction_sets_list = exclude_construction_sets.split(',').map(&:strip).map(&:downcase)

    # Function to calculate thickness based on ply
    def calculate_thickness(ply, custom_thickness, use_custom_thickness)
      if use_custom_thickness
        custom_thickness
      else
        ply.to_i * 0.035
      end
    end

    # Function to calculate required insulation R-value
    def calculate_required_insulation_r_value(existing_r_value, clt_thickness, clt_conductivity)
      clt_r_value = clt_thickness / clt_conductivity
      [0, existing_r_value - clt_r_value].max
    end

    # Process construction sets
    construction_sets_hash = {}
    existing_construction_sets = model.getDefaultConstructionSets
    if existing_construction_sets.empty?
      runner.registerInfo("Model does not have a default construction set. Creating a new construction set and assigning it as the default construction set for the building.")
      new_construction_set = OpenStudio::Model::DefaultConstructionSet.new(model)
      new_construction_set.setName("CLT Construction Set")
      construction_sets_hash["Default"] = new_construction_set
      model.getBuilding.setDefaultConstructionSet(new_construction_set)
    else
      if duplicate_all_sets
        runner.registerInfo("Duplicating existing construction sets to leave the original in place for comparison.")
        existing_construction_sets.each do |construction_set|
          next if exclude_construction_sets_list.any? { |exclude| construction_set.name.get.downcase.include?(exclude) }
          cloned_set = OpenStudio::Model::DefaultConstructionSet.new(model)
          cloned_set.setName("#{construction_set.name.get} with CLT")
          clone_construction_set(model, runner, construction_set, cloned_set)
          construction_sets_hash[construction_set.name.get] = cloned_set
        end
      else
        runner.registerInfo("Modifying the existing construction sets in place with CLT constructions.")
        existing_construction_sets.each do |construction_set|
          next if exclude_construction_sets_list.any? { |exclude| construction_set.name.get.downcase.include?(exclude) }
          construction_sets_hash[construction_set.name.get] = construction_set
        end
      end
    end

    any_construction_updated = false

    # Ensure only cloned sets are modified if duplicating sets
    inner_floor_construction = model.getConstructionByName("Inner Floor CLT and Concrete")
    inner_ceiling_construction = model.getConstructionByName("Inner Ceiling Concrete and CLT")

    if inner_floor_construction.empty?
      inner_floor_construction = nil
    else
      inner_floor_construction = inner_floor_construction.get
    end

    if inner_ceiling_construction.empty?
      inner_ceiling_construction = nil
    else
      inner_ceiling_construction = inner_ceiling_construction.get
    end

    construction_sets_hash.each do |original_set_name, construction_set|
      runner.registerInfo("Creating or Modifying #{original_set_name} with CLT")
      construction_set.setName("#{original_set_name} with CLT")

      # Material creation within the construction set loop
      inner_floor_thickness = calculate_thickness(inner_floor_clt_ply, inner_floor_clt_thickness, use_custom_inner_floor_thickness)
      inner_floor_clt_material = get_or_create_material(model, runner, inner_floor_clt_type, material_properties, created_materials, "CLT - #{inner_floor_clt_type} Floor", thickness: inner_floor_thickness)
      # inner_floor_clt_material.setThickness(inner_floor_thickness)
      # runner.registerInfo("Created material #{inner_floor_clt_material.name} with thickness #{inner_floor_thickness}")

      roof_thickness = calculate_thickness(roof_clt_ply, roof_clt_thickness, use_custom_roof_thickness)
      roof_clt_material = get_or_create_material(model, runner, roof_clt_type, material_properties, created_materials, "CLT - #{roof_clt_type} Roof", thickness: roof_thickness)
      # roof_clt_material.setThickness(roof_thickness)
      # runner.registerInfo("Created material #{roof_clt_material.name} with thickness #{roof_thickness}")

      wall_thickness = calculate_thickness(wall_clt_ply, wall_clt_layer_thickness, use_custom_wall_thickness)
      wall_clt_material = get_or_create_material(model, runner, clt_layer, material_properties, created_materials, "CLT - #{clt_layer} Wall", thickness: wall_thickness)
      # wall_clt_material.setThickness(wall_thickness)
      # runner.registerInfo("Created material #{wall_clt_material.name} with thickness #{wall_thickness}")

      # Logic for replacing exterior walls if the user opts to do so
      exterior_wall_layers = []
      wall_layers_hash = {}
      if replace_external_walls
        # Collect layers for the exterior wall construction
        # Add facade layer if specified
        if facade_layer != 'None'
          facade_material = get_or_create_material(model, runner, facade_layer, material_properties, created_materials)
          # exterior_wall_layers << facade_material
          wall_layers_hash[0] = facade_material
          runner.registerInfo("Added facade layer #{facade_material.name} to exterior wall construction")
        end

        # Add CLT layer
        if clt_layer != 'None'
          # exterior_wall_layers << wall_clt_material
          wall_layers_hash[2] = wall_clt_material
          runner.registerInfo("Added CLT layer #{wall_clt_material.name} to exterior wall construction")
        end

        # Add inner wall layer if specified
        if inner_wall != 'None'
          inner_wall_material = get_or_create_material(model, runner, inner_wall, material_properties, created_materials)
          # exterior_wall_layers << inner_wall_material
          wall_layers_hash[4] = inner_wall_material
          runner.registerInfo("Added inner wall layer #{inner_wall_material.name} to exterior wall construction")
        end   
      end

      # Insulation calculations
      if infer_insulation_levels
        # Analyze existing wall and roof constructions for insulation levels
        if construction_set.defaultExteriorSurfaceConstructions.is_initialized
          exterior_surface_constructions = construction_set.defaultExteriorSurfaceConstructions.get
          if exterior_surface_constructions.wallConstruction.is_initialized
            wall_construction = exterior_surface_constructions.wallConstruction.get
            wall_r_value = 1.0 / wall_construction.thermalConductance.to_f
            # required_r_value = calculate_required_insulation_r_value(wall_r_value, wall_thickness, wall_clt_material.conductivity)

            # calculate the current R value of the layers we've selected
            current_layers_R_value = 0
            wall_layers_hash.each do |ind, layer|
              current_layers_R_value += layer.thickness / layer.conductivity
            end   
            # calculate the remaining r-value we need
            required_insulation_r_value = wall_r_value - current_layers_R_value
            runner.registerInfo("Initial Wall R: #{wall_r_value.round(2)}, Current Layer Selection R: #{current_layers_R_value.round(2)}, Remaining R: #{required_insulation_r_value.round(2)}")

            if replace_external_walls && outer_insulation != 'None' && inner_insulation != 'None'
              outer_insulation_r_value = required_insulation_r_value / 2.0
              inner_insulation_r_value = required_insulation_r_value / 2.0
            elsif outer_insulation != 'None'
              outer_insulation_r_value = required_insulation_r_value
              inner_insulation_r_value = 0.0
            else
              outer_insulation_r_value = 0.0
              inner_insulation_r_value = required_insulation_r_value
            end

            if outer_insulation != 'None'
              outer_insulation_name = "Outer #{outer_insulation} Insulation #{outer_insulation_r_value.round(2)} R-value"
              # outer_insulation_thickness = outer_insulation_r_value * outer_insulation_material.conductivity
              outer_insulation_material = get_or_create_material(model, runner, outer_insulation, material_properties, created_materials, outer_insulation_name, r_value: outer_insulation_r_value)
              # outer_insulation_material.setThickness(outer_insulation_r_value * outer_insulation_material.conductivity)
              # runner.registerInfo("Created material #{outer_insulation_material.name} with thickness #{outer_insulation_material.thickness}")
              wall_layers_hash[1] = outer_insulation_material
              runner.registerInfo("Added outer insulation layer #{outer_insulation_material.name} to exterior wall construction")
            end

            
            if inner_insulation != 'None'
              inner_insulation_name = "Inner #{inner_insulation} Insulation #{inner_insulation_r_value.round(2)} R-value"
              # inner_insulation_thickness = inner_insulation_r_value * inner_insulation_material.conductivity
              inner_insulation_material = get_or_create_material(model, runner, inner_insulation, material_properties, created_materials, inner_insulation_name, r_value: inner_insulation_r_value)
              # inner_insulation_material.setThickness(inner_insulation_r_value * inner_insulation_material.conductivity)
              # runner.registerInfo("Created material #{inner_insulation_material.name} with thickness #{inner_insulation_material.thickness}")
              wall_layers_hash[3] = inner_insulation_material
              runner.registerInfo("Added inner insulation layer #{inner_insulation_material.name} to exterior wall construction")
            end
          end

          if exterior_surface_constructions.roofCeilingConstruction.is_initialized
            roof_construction = exterior_surface_constructions.roofCeilingConstruction.get
            roof_r_value = 1.0 / roof_construction.thermalConductance.to_f
            required_roof_r_value = calculate_required_insulation_r_value(roof_r_value, roof_thickness, roof_clt_material.conductivity)

            # roof_insulation_thickness = required_roof_r_value * roof_insulation.conductivity
            roof_insulation = get_or_create_material(model, runner, 'Polyiso', material_properties, created_materials, "Roof Insulation #{required_roof_r_value.round(2)} R-value", r_value: required_roof_r_value)
            # roof_insulation.setThickness(required_roof_r_value * roof_insulation.conductivity)
            # runner.registerInfo("Created material #{roof_insulation.name} with thickness #{roof_insulation.thickness}")

          end
        end
      else
        # Use user-provided insulation R-values
        if outer_insulation != 'None'
          outer_insulation_name = "Outer #{outer_insulation} Insulation #{exterior_insulation_r_value.round(2)} R-value"
          # outer_insulation_thickness = exterior_insulation_r_value * outer_insulation_material.conductivity
          outer_insulation_material = get_or_create_material(model, runner, outer_insulation, material_properties, created_materials, outer_insulation_name, r_value: exterior_insulation_r_value)
          # outer_insulation_material.setThickness(exterior_insulation_r_value * outer_insulation_material.conductivity)
          # runner.registerInfo("Created material #{outer_insulation_material.name} with thickness #{outer_insulation_material.thickness}")
          wall_layers_hash[1] = outer_insulation_material
          runner.registerInfo("Added outer insulation layer #{outer_insulation_material.name} to exterior wall construction")
        end

        if inner_insulation != 'None'
          inner_insulation_name ="Inner #{inner_insulation} Insulation #{interior_insulation_r_value.round(2)} R-value"
          # inner_insulation_thickness =interior_insulation_r_value * inner_insulation_material.conductivity
          inner_insulation_material = get_or_create_material(model, runner, inner_insulation, material_properties, created_materials, inner_insulation_name, r_value: interior_insulation_r_value)
          # inner_insulation_material.setThickness(interior_insulation_r_value * inner_insulation_material.conductivity)
          # runner.registerInfo("Created material #{inner_insulation_material.name} with thickness #{inner_insulation_material.thickness}")
          wall_layers_hash[3] = inner_insulation_material
          runner.registerInfo("Added inner insulation layer #{inner_insulation_material.name} to exterior wall construction")
        end

        roof_insulation_name = "Roof Insulation #{roof_insulation_r_value.round(2)} R-value"
        # roof_insulation_thickness = roof_insulation_r_value * roof_insulation.conductivity
        roof_insulation = get_or_create_material(model, runner, 'Polyiso', material_properties, created_materials, roof_insulation_name, r_value: roof_insulation_r_value)
        # roof_insulation.setThickness(roof_insulation_r_value * roof_insulation.conductivity)
        # runner.registerInfo("Created material #{roof_insulation.name} with thickness #{roof_insulation.thickness}")
      end

      # Create the new roof construction
      roof_construction = OpenStudio::Model::Construction.new(model)
      roof_index = 0
      unless roof_insulation.nil? # Checks for the case where roof_insulation hasn't been created and doesn't exist
        roof_construction.insertLayer(roof_index, roof_insulation)
        roof_index += 1
      end
      roof_construction.insertLayer(roof_index, roof_clt_material)
      roof_r_value = 1.0 / roof_construction.thermalConductance.to_f
      roof_construction.setName("Roof CLT and Insulation - R-#{roof_r_value.round(2)}")
      runner.registerInfo("Created roof construction #{roof_construction.name}")

      # sorting the hash into an array with the layers in order
      wall_layers_hash.sort.map do |index,layer|
        exterior_wall_layers << layer
      end

      # Create the exterior wall construction and add the collected layers if required
      if replace_external_walls
        exterior_wall_construction = OpenStudio::Model::Construction.new(model)
        exterior_wall_layers.each_with_index do |layer, index|
          exterior_wall_construction.insertLayer(index, layer)
        end
        wall_r_value = 1.0 / exterior_wall_construction.thermalConductance.to_f
        exterior_wall_construction.setName("Exterior Wall CLT and Insulation - R-#{wall_r_value.round(2)}")
        runner.registerInfo("Created exterior wall construction #{exterior_wall_construction.name}")
      end

      # Check if inner floor/ceiling constructions already exist
      unless inner_floor_construction
        inner_floor_construction = OpenStudio::Model::Construction.new(model)
        inner_floor_construction.setName("Inner Floor CLT and Concrete")
        inner_floor_construction.insertLayer(0, inner_floor_clt_material)
        inner_floor_construction.insertLayer(1, get_or_create_material(model, runner, 'Lightweight Concrete', material_properties, created_materials))
        runner.registerInfo("Created inner floor construction #{inner_floor_construction.name}")
      end

      unless inner_ceiling_construction
        inner_ceiling_construction = OpenStudio::Model::Construction.new(model)
        inner_ceiling_construction.setName("Inner Ceiling Concrete and CLT")
        inner_ceiling_construction.insertLayer(0, get_or_create_material(model, runner, 'Lightweight Concrete', material_properties, created_materials))
        inner_ceiling_construction.insertLayer(1, inner_floor_clt_material)
        runner.registerInfo("Created inner ceiling construction #{inner_ceiling_construction.name}")
      end

      # Assign the new constructions to the construction set
      if construction_set.defaultInteriorSurfaceConstructions.is_initialized
        construction_set.defaultInteriorSurfaceConstructions.get.setFloorConstruction(inner_floor_construction)
        construction_set.defaultInteriorSurfaceConstructions.get.setRoofCeilingConstruction(inner_ceiling_construction)
        runner.registerInfo("Assigned inner floor and ceiling constructions to defaultInteriorSurfaceConstructions for '#{original_set_name} with CLT'")
      else
        default_interior_surface_constructions = OpenStudio::Model::DefaultSurfaceConstructions.new(model)
        default_interior_surface_constructions.setFloorConstruction(inner_floor_construction)
        default_interior_surface_constructions.setRoofCeilingConstruction(inner_ceiling_construction)
        construction_set.setDefaultInteriorSurfaceConstructions(default_interior_surface_constructions)
        runner.registerInfo("Created and assigned defaultInteriorSurfaceConstructions for '#{original_set_name} with CLT' with new inner floor and ceiling constructions")
      end

      # Assign the new roof construction to the construction set
      if construction_set.defaultExteriorSurfaceConstructions.is_initialized
        construction_set.defaultExteriorSurfaceConstructions.get.setRoofCeilingConstruction(roof_construction)
        runner.registerInfo("Assigned roof construction to defaultExteriorSurfaceConstructions for '#{original_set_name} with CLT'")
      else
        default_roof_set = OpenStudio::Model::DefaultSurfaceConstructions.new(model)
        default_roof_set.setRoofCeilingConstruction(roof_construction)
        construction_set.setDefaultExteriorSurfaceConstructions(default_roof_set)
        runner.registerInfo("Created and assigned defaultExteriorSurfaceConstructions for '#{original_set_name} with CLT' with new roof construction")
      end

      # Assign the new exterior wall construction to the construction set
      if replace_external_walls
        if construction_set.defaultExteriorSurfaceConstructions.is_initialized
          construction_set.defaultExteriorSurfaceConstructions.get.setWallConstruction(exterior_wall_construction)
          runner.registerInfo("Assigned exterior wall construction to defaultExteriorSurfaceConstructions for '#{original_set_name} with CLT'")
        else
          default_exterior_wall_set = OpenStudio::Model::DefaultSurfaceConstructions.new(model)
          default_exterior_wall_set.setWallConstruction(exterior_wall_construction)
          construction_set.setDefaultExteriorSurfaceConstructions(default_exterior_wall_set)
          runner.registerInfo("Created and assigned defaultExteriorSurfaceConstructions for '#{original_set_name} with CLT' with new exterior wall construction")
        end
      end

      # Apply the new construction set to every object referencing the old one
      if model.getBuilding.defaultConstructionSet.get.name.get == original_set_name
        model.getBuilding.setDefaultConstructionSet(construction_set)
        runner.registerInfo("Updated Default Building Construction Set to use #{construction_set.name.get}")
      end
      model.getSpaces.each do |space|
        unless space.defaultConstructionSet.empty?
          if space.defaultConstructionSet.get.name.get == original_set_name
            space.setDefaultConstructionSet(construction_set)
            runner.registerInfo("Updated #{space.name.get} Space to use #{construction_set.name.get}")
          end
        end
      end
      model.getSpaceTypes.each do |spaceType|
        unless spaceType.defaultConstructionSet.empty?
          if spaceType.defaultConstructionSet.get.name.get == original_set_name
            spaceType.setDefaultConstructionSet(construction_set)
            runner.registerInfo("Updated #{spaceType.name.get} Space Type to use #{construction_set.name.get}")
          end
        end
      end

      any_construction_updated = true
    end

    # Report final conditions
    report_final_conditions(model, runner, any_construction_updated)

    return true
  end
end

# Register the measure to be used by the application
CreateAndAssignCLTConstructionSet.new.registerWithApplication
