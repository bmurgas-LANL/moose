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
    old_block = '1 2'
    new_block = 'stainless_steel graphite'
  [../]
  [./create_interface]
    type = SideSetsBetweenSubdomainsGenerator
    input = rename_subdomains
    primary_block = stainless_steel
    paired_block = graphite
    new_boundary = 'ssg_interface'
  [../]
  [./delete_block]
    type = BlockDeletionGenerator
    input = create_interface
    block = 3
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
    primary_conductivity = electrical_conductivity
    secondary_conductivity = electrical_conductivity
    boundary = ssg_interface
    user_electrical_contact_conductance = 1.47e5 # as described in Cincotti et al (https://doi.org/10.1002/aic.11102)
  [../]
[]

[Materials]
  #graphite
  [./sigma_graphite]
    type = ADGenericConstantMaterial
    prop_names = 'electrical_conductivity'
    prop_values = 3.33e2
    block = graphite
  [../]

  #stainless_steel
  [./sigma_stainless_steel]
    type = ADGenericConstantMaterial
    prop_names = 'electrical_conductivity'
    prop_values = 1.429e6
    block = stainless_steel
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
  automatic_scaling = true
  nl_rel_tol = 1e-09
[]

[Outputs]
  exodus = true
  perf_graph = true
[]
