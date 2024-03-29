# This test simulates biaxial tensile test with the material being anisotropic
# in terms of elasticity and creep.
#
# -------------------
# ANALYTICAL SOLUTION
# -------------------
# https://mooseframework.inl.gov/source/materials/HillCreepStressUpdate.html
# q = [F(S22-S33)^2 + G(S33-S11)^2 + H(S11-S22)^2 + 2L(S23)^2 + 2M(S13)^2 + 2N(S12)^2]^0.5
# S11 = 40 Pa and S22 = 40 MPa; other compoenents of stress are zero since it is a biaxial test
# F=0.5 G=0.25 H=0.3866 L=1.6413 M=1.6413 N=1.2731 (as used in this test)
# Substituting the values of stress components and F, G, H, L, M and N we obtain
# q = 34.64101615137755 Pa
#
# Equivalent_creep_strain_rate = A(q)^n (power law creep rate used in this test)
# Substituting A=1e-15 and n=9, and q as calculated above, we obtain
# Equivalent_creep_strain_rate = 0.07183161109149655
#
# The 11 (xx) and 22 (yy) components of creep_strain_tensor are calculated as below:
#
# creep_strain_tensor_11 = (Equivalent_creep_strain_rate / q) *
#                        (H * (S11 - S22) - G * (S33 - S11)) * time_increment
# creep_strain_tensor_22 = (Equivalent_creep_strain_rate / q) *
#                        (F * (S22 - S33) - H * (S11 - S22)) * time_increment
#
# Substituting the values and time_increment as 0.001 we obtain the analytical solution.
#
#                             MOOSE         Analytical
# creep_strain_tensor_11  2.073327e-06   2.0733271530122e-06
# creep_strain_tensor_22  4.147473e-06   4.147472838877e-06
#
# -----------------------------------------
# PYTHON SCRIPT FOR THE ANALYTICAL SOLUTION
# -----------------------------------------
# import math
# F=0.5; G=0.25; H=0.3866; L=1.6413; M=1.6413; N=1.2731
# S11=40; S22=40; S33=0; S23=0; S13=0; S12=0
# q = math.sqrt(F*(S22-S33)**2 + G*(S33-S11)**2 + H*(S11-S22)**2 + 2*L*(S23)**2 + 2*M*(S13)**2 + 2*N*(S12)**2)
# print(q)
# A=1e-15; n=9; time=0.0001
# equivalent_creep_strain_rate = A*(q**n)
# print(equivalent_creep_strain_rate)
# equivalent_creep_strain_rate_11=(equivalent_creep_strain_rate / q) * (H * (S11 - S22) - G * (S33 - S11)) * time
# equivalent_creep_strain_rate_22=(equivalent_creep_strain_rate / q) * (F * (S22 - S33) - H * (S11 - S22)) * time
# print(equivalent_creep_strain_rate_11, equivalent_creep_strain_rate_22)

[Mesh]
  [gen]
    type = GeneratedMeshGenerator
    dim = 3
    nx = 5
    ny = 5
    nz = 5
    xmin = 0.0
    ymin = 0.0
    zmin = 0.0

    xmax = 1.0
    ymax = 1.0
    zmax = 1.0
  []
[]

[GlobalParams]
  displacements = 'disp_x disp_y disp_z'
  volumetric_locking_correction = true
[]

[AuxVariables]
  [hydrostatic_stress]
    order = CONSTANT
    family = MONOMIAL
  []
  [creep_strain_xx]
    order = CONSTANT
    family = MONOMIAL
  []
  [creep_strain_xy]
    order = CONSTANT
    family = MONOMIAL
  []
  [creep_strain_yy]
    order = CONSTANT
    family = MONOMIAL
  []
[]

[AuxKernels]
  [hydrostatic_stress]
    type = ADRankTwoScalarAux
    variable = hydrostatic_stress
    rank_two_tensor = stress
    scalar_type = Hydrostatic
  []
  [creep_strain_xx]
    type = ADRankTwoAux
    rank_two_tensor = creep_strain
    variable = creep_strain_xx
    index_i = 0
    index_j = 0
  []
  [creep_strain_xy]
    type = ADRankTwoAux
    rank_two_tensor = creep_strain
    variable = creep_strain_xy
    index_i = 0
    index_j = 1
  []
  [creep_strain_yy]
    type = ADRankTwoAux
    rank_two_tensor = creep_strain
    variable = creep_strain_yy
    index_i = 1
    index_j = 1
  []
  [sigma_xx]
    type = ADRankTwoAux
    rank_two_tensor = stress
    variable = stress_xx
    index_i = 0
    index_j = 0
  []
  [sigma_yy]
    type = ADRankTwoAux
    rank_two_tensor = stress
    variable = stress_yy
    index_i = 1
    index_j = 1
  []
  [sigma_zz]
    type = ADRankTwoAux
    rank_two_tensor = stress
    variable = stress_zz
    index_i = 2
    index_j = 2
  []
[]

[Functions]
  [pull]
    type = PiecewiseLinear
    x = '0 1.0e-9 1.0'
    y = '0 -40 -40'
  []
[]

[Modules/TensorMechanics/Master]
  [all]
    strain = FINITE
    generate_output = 'elastic_strain_xx stress_xx elastic_strain_yy stress_yy elastic_strain_zz stress_zz'
    use_automatic_differentiation = true
    add_variables = true
  []
[]

[Materials]
  [elasticity_tensor]
    type = ADComputeElasticityTensor
    C_ijkl = '2925.433 391.979 391.979 2127.590 322.280 2127.590 1805.310 3.96 3.96'
    fill_method = symmetric9
  []

  [elastic_strain]
    type = ADComputeMultipleInelasticStress
    inelastic_models = "trial_creep"
    max_iterations = 50
    absolute_tolerance = 1e-16
  []

  [hill_tensor]
    type = ADHillConstants
    # F G H L M N
    hill_constants = "0.5 0.25 0.3866 1.6413 1.6413 1.2731"
  []

  [trial_creep]
    type = ADHillCreepStressUpdate
    coefficient = 1e-15 # 1e-16
    n_exponent = 9
    m_exponent = 0
    activation_energy = 0
    max_inelastic_increment = 0.00003
    absolute_tolerance = 1e-20
    relative_tolerance = 1e-20
    # Force it to not use integration error
    max_integration_error = 100.0
    anisotropic_elasticity = true
  []
[]

[BCs]
  [no_disp_x]
    type = ADDirichletBC
    variable = disp_x
    boundary = left
    value = 0.0
  []

  [no_disp_y]
    type = ADDirichletBC
    variable = disp_y
    boundary = bottom
    value = 0.0
  []

  [no_disp_z]
    type = ADDirichletBC
    variable = disp_z
    boundary = back
    value = 0.0
  []

  [Pressure]
    [Side1]
      boundary = 'right'
      function = pull
    []
    [Side2]
      boundary = 'top'
      function = pull
    []
  []

[]

[Executioner]
  type = Transient

  solve_type = PJFNK
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_package -mat_mffd_err'
  petsc_options_value = 'lu     superlu_dist                    1e-5'

  nl_rel_tol = 1.0e-14
  nl_abs_tol = 1.0e-14
  l_max_its = 10
  num_steps = 2
  dt = 1.0e-4
  start_time = 0
  automatic_scaling = true
[]

[Postprocessors]
  [matl_ts_min]
    type = MaterialTimeStepPostprocessor
  []
  [max_disp_x]
    type = ElementExtremeValue
    variable = disp_x
  []
  [max_disp_y]
    type = ElementExtremeValue
    variable = disp_y
  []
  [max_hydro]
    type = ElementAverageValue
    variable = hydrostatic_stress
  []
  [dt]
    type = TimestepSize
  []
  [num_lin]
    type = NumLinearIterations
    outputs = console
  []
  [num_nonlin]
    type = NumNonlinearIterations
    outputs = console
  []
  [creep_strain_xx]
    type = ElementalVariableValue
    variable = creep_strain_xx
    execute_on = 'TIMESTEP_END'
    elementid = 109
  []
  [elastic_strain_xx]
    type = ElementalVariableValue
    variable = elastic_strain_xx
    execute_on = 'TIMESTEP_END'
    elementid = 109
  []
  [sigma_xx]
    type = ElementalVariableValue
    variable = stress_xx
    execute_on = 'TIMESTEP_END'
    elementid = 109
  []
  [creep_strain_yy]
    type = ElementalVariableValue
    variable = creep_strain_yy
    execute_on = 'TIMESTEP_END'
    elementid = 109
  []
  [elastic_strain_yy]
    type = ElementalVariableValue
    variable = elastic_strain_yy
    execute_on = 'TIMESTEP_END'
    elementid = 109
  []
  [sigma_yy]
    type = ElementalVariableValue
    variable = stress_yy
    execute_on = 'TIMESTEP_END'
    elementid = 109
  []
  [elastic_strain_zz]
    type = ElementalVariableValue
    variable = elastic_strain_zz
    execute_on = 'TIMESTEP_END'
    elementid = 109
  []
  [sigma_zz]
    type = ElementalVariableValue
    variable = stress_zz
    execute_on = 'TIMESTEP_END'
    elementid = 109
  []
[]

[Outputs]
  csv = true
  exodus = false
  perf_graph = true
  # unnecessary output variables
  hide = 'matl_ts_min max_disp_x max_disp_y max_hydro dt num_lin num_nonlin elastic_strain_zz sigma_zz'
[]
