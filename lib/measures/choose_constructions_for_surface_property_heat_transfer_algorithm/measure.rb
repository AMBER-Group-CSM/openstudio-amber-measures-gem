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

require 'openstudio/measure/ShowRunnerOutput'

class ChooseConstructionsForHTAlgorithm < OpenStudio::Measure::EnergyPlusMeasure
  def name
    'Choose Constructions for SurfaceProperty:HeatTransferAlgorithm'
  end

  def description
    'Presents a checkbox for each Construction in the model so you can pick which ones to tag with a SurfaceProperty:HeatTransferAlgorithm:Construction and which algorithm to use.'
  end

  def modeler_description
    'Loops through all Construction objects, makes one Bool argument per construction, and then in run() adds a SurfaceProperty:HeatTransferAlgorithm:Construction for each checked construction using the chosen algorithm.'
  end

  def arguments(workspace)
    args = OpenStudio::Measure::OSArgumentVector.new

    # 1) One Bool argument per Construction
    constructions = workspace.getObjectsByType('Construction'.to_IddObjectType)
    constructions.each do |const|
      const_name = const.getString(0).to_s
      bool_arg = OpenStudio::Measure::OSArgument.makeBoolArgument(const_name, false)
      bool_arg.setDisplayName("Set '#{const_name}'?")
      bool_arg.setDefaultValue(false)
      args << bool_arg
    end

    # Add argument for comma seperated list of construction names if they're added in a measure workflow
    custom_constructions = OpenStudio::Measure::OSArgument.makeStringArgument('custom_constructions', false)
    custom_constructions.setDisplayName("Optional Comma Separated List of Custom Constructions")
    custom_constructions.setDescription("If you have added custom constructions in a measure workflow, you can enter the names here. Those are searched for in addition to the ones checked above.")
    args << custom_constructions

    # 2) Choice of algorithm
    algs = [
      'MoisturePenetrationDepthConductionTransferFunction',
      'CombinedHeatAndMoistureFiniteElement',
      'ConductionFiniteDifference',
      'ConductionTransferFunction'
    ]
    algorithm = OpenStudio::Measure::OSArgument.makeChoiceArgument('algorithm', algs, true)
    algorithm.setDisplayName('Select Heat Transfer Algorithm')
    algorithm.setDefaultValue(algs.first)
    args << algorithm

    # Let's grab the timestep already used in the model and set that as the default
    timestep = OpenStudio::Measure::OSArgument.makeIntegerArgument("timestep",required=false)
    # timestep.setDefaultValue(current_timestep)
    timestep.setDisplayName("Change the Timesteps per Hour?")
    timestep.setDescription("Sets a new timestep, leave blank for no change.")
    args << timestep

    args
  end

  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)
    return false unless runner.validateUserArguments(arguments(workspace), user_arguments)

    timestep = runner.getOptionalIntegerArgumentValue("timestep",user_arguments)

    # Check if the user provided a custom constructions list
    custom_constructions = runner.getOptionalStringArgumentValue('custom_constructions', user_arguments)
    if custom_constructions.is_initialized && !custom_constructions.get.empty?
      # Split the string by commas and strip whitespace
      custom_construction_list = custom_constructions.get.split(',').map(&:strip)
    end

    # Gather which constructions the user checked
    constructions = workspace.getObjectsByType('Construction'.to_IddObjectType)
    to_tag = []
    constructions.each do |const|
      name = const.getString(0).to_s
      if runner.getBoolArgumentValue(name, user_arguments)
        to_tag << name
      else
        # If the user provided a custom constructions list, check if the name is in that list
        if custom_constructions.is_initialized && custom_construction_list.include?(name)
          to_tag << name
          runner.registerInfo("Adding custom construction '#{name}' to the list of constructions.")
        end
      end
    end



    alg = runner.getStringArgumentValue('algorithm', user_arguments)

    if to_tag.empty?
      runner.registerInfo('No constructions were selected; no changes made.')
      return true
    end

    runner.registerInitialCondition("Model has #{constructions.size} constructions; tagging #{to_tag.size} of them.")

    # E+ crashes if every surface has a SurfaceProperty:Heattransferalgorithm assigned to it -_-, so gotta account for that I guess
    if to_tag.length() == constructions.length()
      alg = workspace.getObjectsByType("HeatBalanceAlgorithm".to_IddObjectType)
      alg = alg[0] # HeatBalanceAlgorithm is unique so we know we'll only get one, but it still returns and array so we need to get the element
      alg.setString(0, algorithm)
      runner.registerInfo("Every construction in the model was checked, setting the global HT Algorithm to #{algorithm} to avoid E+ crashing by setting each to SurfaceProperty:HeatTransferAlgorithm objects.")
    else
      # Inject one SurfaceProperty:HeatTransferAlgorithm:Construction per selected construction
      surf_prop_const_idf_string = "SurfaceProperty:HeatTransferAlgorithm:Construction,\n  ,  !- Name\n  ,  !- Algorithm\n  ;  !- Construction Name\n"
      surf_prop_construction_obj = OpenStudio::IdfObject.load(surf_prop_const_idf_string).get
      to_tag.each do |const_name|
        alg_surf_prop_construction = surf_prop_construction_obj.clone
        alg_surf_prop_construction.setString(0,"HT-Alg for #{const_name}") # giving it a name
        alg_surf_prop_construction.setString(1,alg) # setting the algorithm choice
        alg_surf_prop_construction.setString(2,const_name)     # Setting the construction name to assign it to
        workspace.addObject(alg_surf_prop_construction)
        runner.registerInfo("Added HT algorithm '#{alg}' to construction '#{const_name}'.")
      end
    end

    #---------------------------------------------------------------------------
    # Setting the timestep
    if !timestep.empty?
      timestep_obj = workspace.getObjectsByType("Timestep".to_IddObjectType)[0]
      timestep_obj.setString(0,timestep.to_s) # I guess it is coming in as an integer
      runner.registerInfo("Set the Timestep to #{timestep}")
    end

    runner.registerFinalCondition("Added SurfaceProperty:HeatTransferAlgorithm:Construction for #{to_tag.size} constructions.")
    true
  end
end

# register the measure with the application
ChooseConstructionsForHTAlgorithm.new.registerWithApplication
