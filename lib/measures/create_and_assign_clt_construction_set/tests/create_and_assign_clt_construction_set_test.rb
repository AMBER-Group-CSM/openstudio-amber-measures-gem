require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class CreateAndAssignCLTConstructionSet_Test < Minitest::Test
  def setup
    # Set up a model
    @model = OpenStudio::Model::Model.new

    # Add a building
    @building = @model.getBuilding

    # Add default construction sets
    default_construction_set1 = OpenStudio::Model::DefaultConstructionSet.new(@model)
    default_construction_set1.setName("Default Construction Set 1")
    @building.setDefaultConstructionSet(default_construction_set1)

    default_construction_set2 = OpenStudio::Model::DefaultConstructionSet.new(@model)
    default_construction_set2.setName("Default Construction Set 2")
    space = OpenStudio::Model::Space.new(@model)
    space.setDefaultConstructionSet(default_construction_set2)

    # Assign interior and exterior constructions to one of the construction sets
    interior_surface_constructions = OpenStudio::Model::DefaultSurfaceConstructions.new(@model)
    exterior_surface_constructions = OpenStudio::Model::DefaultSurfaceConstructions.new(@model)

    floor_construction = OpenStudio::Model::Construction.new(@model)
    floor_construction.setName("Interior Floor Construction")
    ceiling_construction = OpenStudio::Model::Construction.new(@model)
    ceiling_construction.setName("Ceiling Construction")

    roof_construction = OpenStudio::Model::Construction.new(@model)
    roof_construction.setName("Roof Construction")
    wall_construction = OpenStudio::Model::Construction.new(@model)
    wall_construction.setName("Wall Construction")

    interior_surface_constructions.setFloorConstruction(floor_construction)
    interior_surface_constructions.setRoofCeilingConstruction(ceiling_construction)
    exterior_surface_constructions.setRoofCeilingConstruction(roof_construction)
    exterior_surface_constructions.setWallConstruction(wall_construction)

    default_construction_set2.setDefaultInteriorSurfaceConstructions(interior_surface_constructions)
    default_construction_set2.setDefaultExteriorSurfaceConstructions(exterior_surface_constructions)

    # Create a runner
    @runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # Create an empty model
    @measure = CreateAndAssignCLTConstructionSet.new
  end

  # Helper method to set arguments for the measure
  def set_arguments(args_hash)
    arguments = @measure.arguments(@model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    args_hash.each do |name, value|
      arg = arguments.detect { |a| a.name == name }
      assert(!arg.nil?, "Argument #{name} not found")
      success = arg.setValue(value)
      puts "Setting #{name} to #{value} was #{success ? 'successful' : 'unsuccessful'}"
      argument_map[name] = arg
    end

    argument_map
  end

  def run_measure(arguments)
    # Run the measure
    @measure.run(@model, @runner, arguments)
    result = @runner.result

    # Show the runner output
    show_output(result)

    result
  end

  def test_number_and_names_of_arguments
    puts "Running test_number_and_names_of_arguments"
    # Get arguments
    arguments = @measure.arguments(@model)

    # Check number of arguments
    assert_equal(15, arguments.size)

    # Check names of arguments
    expected_argument_names = [
      'inner_floor_clt_type',
      'inner_floor_clt_thickness',
      'roof_clt_type',
      'roof_clt_thickness',
      'replace_external_walls',
      'facade_layer',
      'outer_insulation',
      'clt_layer',
      'inner_insulation',
      'inner_wall',
      'exterior_insulation_r_value',
      'interior_insulation_r_value',
      'roof_insulation_r_value',
      'wall_clt_layer_thickness',
      'duplicate_all_sets'
    ]

    argument_names = arguments.map(&:name)
    assert_equal(expected_argument_names.sort, argument_names.sort)
  end

  def test_invalid_argument_values
    puts "Running test_invalid_argument_values"

    # Set invalid argument values using set_arguments helper method
    args_hash = {
      'inner_floor_clt_type' => 'InvalidType',
      'inner_floor_clt_thickness' => -0.1
    }

    argument_map = set_arguments(args_hash)

    # Run the measure with invalid arguments
    result = run_measure(argument_map)

    # Assert that the measure fails
    assert_equal('Fail', result.value.valueName)
    assert(result.errors.size > 0)
  end

  def test_update_only_default_construction_set
    puts "Running test_update_only_default_construction_set"

    # Set valid argument values using set_arguments helper method
    args_hash = {
      'inner_floor_clt_type' => 'SPF',
      'inner_floor_clt_thickness' => 0.1016,
      'roof_clt_type' => 'DF',
      'roof_clt_thickness' => 0.1715,
      'replace_external_walls' => false,
      'duplicate_all_sets' => false
    }

    argument_map = set_arguments(args_hash)

    # Run the measure
    result = run_measure(argument_map)

    # Assert that the measure runs successfully
    assert_equal('Success', result.value.valueName)

    # Check if only the default construction set is updated
    default_construction_set = @model.getBuilding.defaultConstructionSet
    assert(default_construction_set.is_initialized)
    assert(default_construction_set.get.name.get.include?('with CLT'))
  end

  def test_update_all_construction_sets
    puts "Running test_update_all_construction_sets"

    # Set valid argument values using set_arguments helper method
    args_hash = {
      'inner_floor_clt_type' => 'SPF',
      'inner_floor_clt_thickness' => 0.1016,
      'roof_clt_type' => 'DF',
      'roof_clt_thickness' => 0.1715,
      'replace_external_walls' => false,
      'duplicate_all_sets' => true
    }

    argument_map = set_arguments(args_hash)

    # Run the measure
    result = run_measure(argument_map)

    # Assert that the measure runs successfully
    assert_equal('Success', result.value.valueName)

    # Check if all construction sets are updated
    @model.getDefaultConstructionSets.each do |construction_set|
      assert(construction_set.name.get.include?('with CLT'))
    end
  end

  def test_outer_wall_construction
    puts "Running test_outer_wall_construction"

    # Set valid argument values to replace external walls using set_arguments helper method
    args_hash = {
      'inner_floor_clt_type' => 'SPF',
      'inner_floor_clt_thickness' => 0.1016,
      'roof_clt_type' => 'DF',
      'roof_clt_thickness' => 0.1715,
      'replace_external_walls' => true,
      'facade_layer' => 'Brick',
      'outer_insulation' => 'Polyiso',
      'clt_layer' => 'DF',
      'inner_insulation' => 'Spray Foam',
      'inner_wall' => 'Gypsum',
      'exterior_insulation_r_value' => 5.28,
      'interior_insulation_r_value' => 0,
      'roof_insulation_r_value' => 5.28,
      'wall_clt_layer_thickness' => 0.1016,
      'duplicate_all_sets' => true
    }

    argument_map = set_arguments(args_hash)

    # Run the measure
    result = run_measure(argument_map)

    # Assert that the measure runs successfully
    assert_equal('Success', result.value.valueName)

    # Check if the outer wall construction is valid
    @model.getConstructions.each do |construction|
      if construction.name.get.include?('Exterior Wall CLT and Insulation')
        assert_equal(5, construction.layers.size)
      end
    end
  end
end
