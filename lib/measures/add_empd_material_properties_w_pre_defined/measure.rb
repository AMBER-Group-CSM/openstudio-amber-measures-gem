# Copyright 2025 Gabriel Miguel Flechas
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

# Revised version of the measure found in the NREL Model Articulation GEM: 
# https://github.com/NREL/openstudio-model-articulation-gem/tree/2fda610057274205e7663be95ec6b59f97e1c151/lib/measures/add_empd_material_properties

# Helper function to load IDF files
def load_idf_file(path)
  # Loads the objects from the idf and then returns the idf
  if File.exist?(path)
    # load IDF
    source_idf = OpenStudio::IdfFile.load(OpenStudio::Path.new(path)).get
    return source_idf
  else
    return false
  end
end

# start the measure
class AddEMPDMaterialPropertiesWPreDefined < OpenStudio::Measure::ModelMeasure
  # human readable name 
  def name
    return "Add EMPD Material Properties PreDefined"
  end

  # human readable description
  # 
  def description
    return "Adds effective moisture penetration depth (EMPD) Heat Balance Model properties for a selected material in the model."
  end

  # human readable description of modeling approach
  def modeler_description
    return   <<~DESC
      Adds the properties for the 'MoisturePenetrationDepthConductionTransferFunction' or effective moisture penetration depth (EMPD) Heat Balance Model with inputs for penetration depths. Using the values a=0, b=1, c=0, and d=1 results in a non-absorbant material and is useful for adding properties to a material in a zone so that you can use the algorithm, but for a zone/material that doesn't participate in the moisture balance.
      Leaving 'Change heat balance algorithm?' blank will use the current OpenStudio heat balance algorithm setting.
      At least 1 interior material in every zone needs to have moisture penetration depth properties set to use the EMPD heat balance algorithm.
      Moisture properties are drawn from a modified idf of the EnergyPlus MoistureProperties.idf dataset file. The modified file has moisture properties for SPF and DF cross-laminated timber based on the research study by Kordziel et al. 'Hygrothermal characterization and modeling of cross-laminated timber in the building envelope'.
    DESC
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # find the available materials
    list_materials = model.getStandardOpaqueMaterials
    # list_materials = list_materials + model.getMasslessOpaqueMaterials
    mat_names = Array.new()
    list_materials.each do |v|
      mat_names.append(v.name.to_s)
    end
    mat_names.sort!

    # Create arguments for material selection (Choice)
    selected_material = OpenStudio::Measure::OSArgument.makeChoiceArgument('selected_material',mat_names, true, false)
    selected_material.setDisplayName("Select Material")
    if !mat_names.empty?
      selected_material.setDefaultValue(mat_names[0])
    else
      selected_material.setDefaultValue("No Materials In Model!")
    end
    args << selected_material

    # Create an optional string argument for a material name if it's been added in a measure workflow, leave empty to use the selected material
    opt_custom_material = OpenStudio::Measure::OSArgument.makeStringArgument('opt_custom_material', false)
    opt_custom_material.setDisplayName("Optional Custom Material Name")
    opt_custom_material.setDescription("If you have added a custom material in a measure workflow, you can enter the name here. Leave empty to use the selected material.")
    args << opt_custom_material

    # Load in materials from the Moisture Materials Resource idf file
    moisture_properties_idf_path = File.join(__dir__,"resources","EMPDMoistureMaterials_wCLT.idf")
    moisture_properties_file = load_idf_file(moisture_properties_idf_path)
    if moisture_properties_file != false
      idf_materials = moisture_properties_file.getObjectsByType("MaterialProperty:MoisturePenetrationDepth:Settings".to_IddObjectType)
    else
      idf_materials = ["No material properties file found."]
    end
    idf_mat_names = []
    idf_materials.each do |m|
      idf_mat_names.push(m.getField(0).to_s)
    end
    idf_mat_names.sort!
    # creating material properties choices
    moisture_material_choice = OpenStudio::Measure::OSArgument.makeChoiceArgument('moisture_material_choice',idf_mat_names, true, false)
    moisture_material_choice.setDisplayName("Select the closest material here to the one in your model")
    moisture_material_choice.setDefaultValue(idf_mat_names[0])
    args << moisture_material_choice

    cust_waterDiffFact = OpenStudio::Measure::OSArgument.makeBoolArgument("cust_waterDiffFact", true)
    cust_waterDiffFact.setDisplayName("Override PreDefined Material's Water Vapor Diffusion Resistance Factor?")
    cust_waterDiffFact.setDefaultValue(false)
    args << cust_waterDiffFact

    # create argument for Water Vapor Diffusion Resistance Factor 
    waterDiffFact = OpenStudio::Measure::OSArgument.makeDoubleArgument('waterDiffFact', true)
    waterDiffFact.setDisplayName("Set value for Water Vapor Diffusion Resistance Factor")
    waterDiffFact.setDefaultValue(0)
    args << waterDiffFact

    cust_coeffs = OpenStudio::Measure::OSArgument.makeBoolArgument("cust_coeffs", true)
    cust_coeffs.setDisplayName("Override PreDefined Material's Moisture Equation Coefficients (a-d)?")
    cust_coeffs.setDefaultValue(false)
    args << cust_coeffs

    # create argument for Coefficient A
    coefA = OpenStudio::Measure::OSArgument.makeDoubleArgument('coefA', true)
    coefA.setDisplayName("Set value for Moisture Equation Coefficient A")
    coefA.setDefaultValue(0)
    args << coefA

    # create argument for Coefficient B
    coefB = OpenStudio::Measure::OSArgument.makeDoubleArgument('coefB', true)
    coefB.setDisplayName("Set value for Moisture Equation Coefficient B")
    coefB.setDefaultValue(1)
    args << coefB

    # create argument for Coefficient C
    coefC = OpenStudio::Measure::OSArgument.makeDoubleArgument('coefC', true)
    coefC.setDisplayName("Set value for Moisture Equation Coefficient C")
    coefC.setDefaultValue(0)
    args << coefC

    # create argument for Coefficient D
    coefD = OpenStudio::Measure::OSArgument.makeDoubleArgument('coefD', true)
    coefD.setDisplayName("Set value for Moisture Equation Coefficient D")
    coefD.setDefaultValue(1)
    args << coefD

    cust_surfacePenetration = OpenStudio::Measure::OSArgument.makeBoolArgument("cust_surfacePenetration", true)
    cust_surfacePenetration.setDisplayName("Override PreDefined Material's Surface Layer Penetration Depth?")
    cust_surfacePenetration.setDefaultValue(false)
    args << cust_surfacePenetration

    # create argument for Surface Layer Penetration Depth
    surfacePenetration = OpenStudio::Measure::OSArgument.makeStringArgument('surfacePenetration', true)
    surfacePenetration.setDisplayName("Set value for Surface Layer Penetration Depth")
    surfacePenetration.setDefaultValue("Auto")
    args << surfacePenetration

    cust_deepPenetration = OpenStudio::Measure::OSArgument.makeBoolArgument("cust_deepPenetration", true)
    cust_deepPenetration.setDisplayName("Override PreDefined Material's Deep Layer Penetration Depth?")
    cust_deepPenetration.setDefaultValue(false)
    args << cust_deepPenetration

    # create argument for Deep Layer Penetration Depth
    deepPenetration = OpenStudio::Measure::OSArgument.makeStringArgument('deepPenetration', false)
    deepPenetration.setDisplayName("Set value for Deep Layer Penetration Depth")
    deepPenetration.setDefaultValue("Auto")
    args << deepPenetration

    cust_coating = OpenStudio::Measure::OSArgument.makeBoolArgument("cust_coating", true)
    cust_coating.setDisplayName("Override PreDefined Material's Coating Layer Thickness?")
    cust_coating.setDefaultValue(false)
    args << cust_coating

    # create argument for Coating layer Thickness
    coating = OpenStudio::Measure::OSArgument.makeDoubleArgument('coating', true)
    coating.setDisplayName("Set value for Coating Layer Thickness")
    coating.setDefaultValue(0)
    args << coating

    cust_coatingRes = OpenStudio::Measure::OSArgument.makeBoolArgument("cust_coatingRes", true)
    cust_coatingRes.setDisplayName("Override PreDefined Material's Coating Layer Resistance Factor")
    cust_coatingRes.setDefaultValue(false)
    args << cust_coatingRes

    # create argument for Coating layer Resistance
    coatingRes = OpenStudio::Measure::OSArgument.makeDoubleArgument('coatingRes', true)
    coatingRes.setDisplayName("Set value for Coating Layer Resistance Factor")
    coatingRes.setDefaultValue(0)
    args << coatingRes

    # create argument for heat balance algorithm
    algs = ["", "MoisturePenetrationDepthConductionTransferFunction",
        "ConductionTransferFunction"]
    algorithm = OpenStudio::Measure::OSArgument.makeChoiceArgument('algorithm', algs, false, false)
    algorithm.setDisplayName("Change heat balance algorithm?")
    algorithm.setDefaultValue(algs[0])
    args << algorithm

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    selected_material = runner.getStringArgumentValue('selected_material', user_arguments)
    opt_custom_material = runner.getOptionalStringArgumentValue('opt_custom_material', user_arguments)
    moisture_material_choice = runner.getStringArgumentValue('moisture_material_choice', user_arguments)
    cust_waterDiffFact = runner.getBoolArgumentValue('cust_waterDiffFact',user_arguments)
    waterDiffFact = runner.getDoubleArgumentValue('waterDiffFact', user_arguments)
    cust_coeffs = runner.getBoolArgumentValue('cust_coeffs',user_arguments)
    coefA = runner.getDoubleArgumentValue('coefA', user_arguments)
    coefB = runner.getDoubleArgumentValue('coefB', user_arguments)
    coefC = runner.getDoubleArgumentValue('coefC', user_arguments)
    coefD = runner.getDoubleArgumentValue('coefD', user_arguments)
    cust_surfacePenetration = runner.getBoolArgumentValue('cust_surfacePenetration',user_arguments)
    surfacePenetration = runner.getStringArgumentValue('surfacePenetration', user_arguments)
    auto_values = ["Auto","auto","autocalculate"]
    if !auto_values.include?(surfacePenetration)
      surfacePenetration = surfacePenetration.to_f
    end    
    cust_deepPenetration = runner.getBoolArgumentValue('cust_deepPenetration',user_arguments)
    deepPenetration = runner.getStringArgumentValue('deepPenetration', user_arguments)
    if !auto_values.include?(deepPenetration)
      deepPenetration = deepPenetration.to_f
    end    
    cust_coating = runner.getBoolArgumentValue('cust_coating',user_arguments)
    coating = runner.getDoubleArgumentValue('coating', user_arguments)
    cust_coatingRes = runner.getBoolArgumentValue('cust_coatingRes',user_arguments)
    coatingRes = runner.getDoubleArgumentValue('coatingRes', user_arguments)
    algorithm = runner.getStringArgumentValue('algorithm', user_arguments)

    #---------------------------------------------------------------------------
    # Validate arguments
    if waterDiffFact == 0 && cust_waterDiffFact
      runner.registerError("The Water Vapor Diffusion Resistance Factor needs to be greater than 0.")
      return false
    end
    if coefA == 0 && cust_coeffs
        runner.registerWarning("The Moisture Equation Coefficient A has been left as 0. This is usally a non-zero value.")
    end
    if coefB == 1 && cust_coeffs
        runner.registerWarning("The Moisture Equation Coefficient B has been left as 1. This is usally a non-zero value and not exactly 1.")
    end
    if coefC == 0 && cust_coeffs
        runner.registerWarning("The Moisture Equation Coefficient C has been left as 0. This is usally a non-zero value.")
    end
    if coefD == 1 && cust_coeffs
        runner.registerWarning("The Moisture Equation Coefficient D has been left as 1. This is usally a non-zero value and not exactly 1.")
    end
    #---------------------------------------------------------------------------

    # Check if a custom material name is provided, use that instead of the selected material if so
    if opt_custom_material.is_initialized && !opt_custom_material.get.empty?
      selected_material = opt_custom_material.get
      runner.registerInfo("Using custom material name: #{selected_material}")
    else
      runner.registerInfo("Using selected material: #{selected_material}")
    end

    # Get os object for selected material
    mats = model.getStandardOpaqueMaterials
    # mats = mats + model.getMaterials
    mat = ""
    mats.each do |m|
      if m.name.to_s == selected_material
        mat = m
      end
    end
    if mat.is_a?(String)
      runner.registerError("Material not found in model, this error is likely the result of a bug in the measure or the custom named material not being added to the model. Please check the material name and ensure it exists in the model.")
    end

    # report initial condition of model
    runner.registerInitialCondition("The building has #{mats.size} materials.")

    # Check the requested material from the IDF
    moisture_properties_idf_path = File.join(__dir__,"resources","EMPDMoistureMaterials_wCLT.idf")
    moisture_properties_file = load_idf_file(moisture_properties_idf_path)
    if moisture_properties_file != false
      idf_materials = moisture_properties_file.getObjectsByType("MaterialProperty:MoisturePenetrationDepth:Settings".to_IddObjectType)
    else
      runner.registerError("No properties found in the resources Moisture Material IDF. Did it get moved or altered?")
    end
    moisture_mat = ""
    idf_materials.each do |m|
      if m.getField(0).to_s == moisture_material_choice
        moisture_mat = m
      end
    end
    if moisture_mat.is_a?(String)
      runner.registerError("Moisture material not found in the IDF materials. This error is likely the result of a bug in the measure.")
    end

    # Setting variables based on the moisture material when custom value isn't selected
    if !cust_waterDiffFact
      waterDiffFact = moisture_mat.getField(1).get.to_f
    end
    if !cust_coeffs
      coefA = moisture_mat.getField(2).get.to_f
      coefB = moisture_mat.getField(3).get.to_f
      coefC = moisture_mat.getField(4).get.to_f
      coefD = moisture_mat.getField(5).get.to_f
    end
    if !cust_surfacePenetration
      surfacePenetration = moisture_mat.getField(6).get
    end
    if !cust_deepPenetration
      deepPenetration = moisture_mat.getField(7).get
    end
    if !cust_coating
      coating = moisture_mat.getField(8).get.to_f
    end
    if !cust_coatingRes
      coatingRes = moisture_mat.getField(9).get.to_f
    end

    runner.registerInfo("Water Diffusion Resistance Factor set to: #{waterDiffFact}")
    runner.registerInfo("Coefficients set to: a=#{coefA}, b=#{coefB}, c=#{coefC}, d=#{coefD}")
    runner.registerInfo("Penetration depth settings set to: Surface Depth=#{surfacePenetration}, Deep Depth=#{deepPenetration}")
    runner.registerInfo("Coating settings set to: Coating Thickness=#{coating}, Coating Resistance Factor=#{coatingRes}")


    # Add moisture properties object and make changes to model
    empd_mat = OpenStudio::Model::MaterialPropertyMoisturePenetrationDepthSettings.new(mat,waterDiffFact,coefA,coefB,coefC,coefD,coating,coatingRes)

    # check if the surface penetration is being autocalculated, and if not set the depth
    if surfacePenetration.to_f > 0 && !auto_values.include?(surfacePenetration)
      empd_mat.setSurfaceLayerPenetrationDepth(surfacePenetration)
      runner.registerInfo("Surface layer penetration depth set to: #{surfacePenetration}")
    else
      empd_mat.autocalculateSurfaceLayerPenetrationDepth()
      runner.registerInfo("Surface layer penetration depth set to: AutoCalculate")
    end


    # check if the deep penetration is being autocalculated, and if not set the depth
    if deepPenetration.to_f > 0 && !auto_values.include?(surfacePenetration)
      empd_mat.setDeepLayerPenetrationDepth(deepPenetration)
      runner.registerInfo("Deep layer penetration depth set to: #{surfacePenetration}")
    else
      empd_mat.autocalculateDeepLayerPenetrationDepth()
      if deepPenetration.to_f <= 0
        runner.registerInfo("Deep layer penetration depth is <= 0, setting to auto calculate.")
      end
      runner.registerInfo("Deep layer penetration depth set to: AutoCalculate")
    end

    #---------------------------------------------------------------------------
    # Set algorithm and report to users
    if algorithm != ""
      alg = model.getHeatBalanceAlgorithm
      alg.setAlgorithm(algorithm)
      runner.registerInfo("Heat Balance Algorithm Set to : #{algorithm}")
    end
    #---------------------------------------------------------------------------


    # report final condition of model
    runner.registerFinalCondition("Moisture properties were added to #{selected_material}.")

    return true
  end
end

# register the measure to be used by the application
AddEMPDMaterialPropertiesWPreDefined.new.registerWithApplication
