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

    # Print out arguments for debugging
    arguments.each do |arg_name, arg|
      puts "#{arg_name}: #{arg}"
    end

    result
  end

  def test_invalid_argument_values
    puts "Running test_invalid_argument_values"

    # Set invalid argument values using set_arguments helper method
    args_hash = {
      "inner_floor_clt_type" => "InvalidType",
      "inner_floor_clt_thickness" => -0.1,
      "roof_clt_type" => "SPF",
      "roof_clt_thickness" => 0.1715,
      "replace_external_walls" => false,
      "facade_layer" => "None",
      "outer_insulation" => "Polyiso",
      "clt_layer" => "SPF",
      "inner_insulation" => "None",
      "inner_wall" => "None",
      "exterior_insulation_r_value" => 5.28,
      "interior_insulation_r_value" => 0,
      "roof_insulation_r_value" => 5.28,
      "wall_clt_layer_thickness" => 0.1016,
      "duplicate_all_sets" => true
    }

    argument_map = set_arguments(args_hash)

    # Run the measure with invalid arguments
    result = run_measure(argument_map)

    # Print runner output
    show_output(result)

    # Assert that the measure fails
    assert_equal('Fail', result.value.valueName)
    assert(result.errors.size > 0)
  end
end

CreateAndAssignCLTConstructionSet_Test.new('test_invalid_argument_values').run
