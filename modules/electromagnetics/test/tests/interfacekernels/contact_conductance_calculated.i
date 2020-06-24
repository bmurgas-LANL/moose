[Mesh]
  [./box]
    type = CartesianMeshGenerator
    dim = 2
    dx = '0.5 0.5'
    dy = '0.25 0.5 0.25'
    ix = '20 20'
    iy = '10 20 10'
    subdomain_id = '1 1
                    2 3
                    1 1'
  [../]
  [./rename_subdomains]
    type = RenameBlockGenerator
    input = box
    old_block_id = '1 2'
    new_block_name = 'stainless_steel graphite'
  [../]
  [./create_interface]
    type = SideSetsBetweenSubdomainsGenerator
    input = rename_subdomains
    master_block = stainless_steel
    paired_block = graphite
    new_boundary = 'ssg_interface'
  [../]
  [./delete_block]
    type = BlockDeletionGenerator
    input = create_interface
    block_id = 3
  [../]
[]

[Problem]
  coord_type = RZ
[]

[Variables]
  [./potential_graphite]
    block = graphite
  [../]
  [./potential_stainless_steel]
    block = stainless_steel
  [../]
[]

[Kernels]
  [./electric_graphite]
    type = ConductivityLaplacian
    variable = potential_graphite
    conductivity_coefficient = electrical_conductivity
    block = graphite
  [../]
  [./electric_stainless_steel]
    type = ConductivityLaplacian
    variable = potential_stainless_steel
    conductivity_coefficient = electrical_conductivity
    block = stainless_steel
  [../]
[]

[BCs]
  [./elec_top]
    type = DirichletBC
    variable = potential_stainless_steel
    boundary = top
    value = 1
  [../]
  [./elec_bottom]
    type = DirichletBC
    variable = potential_stainless_steel
    boundary = bottom
    value = 0
  [../]
[]

[InterfaceKernels]
  [./electrostatic_contact]
    type = ElectrostaticContactCondition
    variable = potential_stainless_steel
    neighbor_var = potential_graphite
    boundary = ssg_interface
    primary_conductivity = ad_electrical_conductivity
    secondary_conductivity = ad_electrical_conductivity
    mean_hardness = mean_hardness
    mechanical_pressure = 8.52842e10  # resulting contact conductance should be ~1.47e5 as described in Cincotti et al (https://doi.org/10.1002/aic.11102)
  [../]
[]

[Materials]
  #graphite
  [./sigma_graphite]
    type = GenericConstantMaterial
    prop_names = 'electrical_conductivity'
    prop_values = 3.33e2
    block = graphite
  [../]
  [./ad_conversion_graphite]
    type = MaterialConverter
    reg_props_in = 'electrical_conductivity'
    ad_props_out = 'ad_electrical_conductivity'
    block = graphite
  [../]

  #stainless_steel
  [./sigma_stainless_steel]
    type = GenericConstantMaterial
    prop_names = 'electrical_conductivity'
    prop_values = 1.429e6
    block = stainless_steel
  [../]
  [./ad_conversion_stainless_steel]
    type = MaterialConverter
    reg_props_in = 'electrical_conductivity'
    ad_props_out = 'ad_electrical_conductivity'
    block = stainless_steel
  [../]

  #mean hardness
  [./harmonic_mean_hardness]
    type = ADGenericConstantMaterial
    prop_names = 'mean_hardness'
    prop_values = 2.4797e9
  [../]
[]

[Preconditioning]
  [./SMP]
    type = SMP
    full = true
  [../]
[]

[Executioner]
  type = Steady
  solve_type = PJFNK
  petsc_options_iname = '-pc_type -ksp_grmres_restart -sub_ksp_type -sub_pc_type -pc_asm_overlap'
  petsc_options_value = 'asm         101   preonly   ilu      1'
  #petsc_options = '-snes_test_jacobian'
  automatic_scaling = true
[]

[Outputs]
  exodus = true
  perf_graph = true
[]
