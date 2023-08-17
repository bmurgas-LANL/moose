mu = 0.002
rho = 1.0
advected_interp_method = 'average'
velocity_interp_method = 'rc'

pressure_tag = "pressure_grad"

[Mesh]
  [mesh]
    type = CartesianMeshGenerator
    dim = 3
    dx = '0.2'
    dy = '0.2'
    dz = '0.8'
    ix = '3'
    iy = '3'
    iz = '12'
  []
[]

[GlobalParams]
  rhie_chow_user_object = 'rc'
[]

[Problem]
  nl_sys_names = 'momentum_system pressure_system'
  previous_nl_solution_required = true
  error_on_jacobian_nonzero_reallocation = true
[]

[UserObjects]
  [rc]
    type = INSFVRhieChowInterpolatorSegregated
    u = vel_x
    v = vel_y
    w = vel_z
    pressure = pressure
  []
[]

[Variables]
  [vel_x]
    type = INSFVVelocityVariable
    initial_condition = 0.0
    nl_sys = momentum_system
    two_term_boundary_expansion = false
  []
  [vel_y]
    type = INSFVVelocityVariable
    initial_condition = 0.0
    nl_sys = momentum_system
    two_term_boundary_expansion = false
  []
  [vel_z]
    type = INSFVVelocityVariable
    initial_condition = 0.5
    nl_sys = momentum_system
    two_term_boundary_expansion = false
  []
  [pressure]
    type = INSFVPressureVariable
    nl_sys = pressure_system
    initial_condition = 0.2
    two_term_boundary_expansion = false
  []
[]

[FVKernels]
  [u_advection]
    type = INSFVMomentumAdvection
    variable = vel_x
    advected_interp_method = ${advected_interp_method}
    velocity_interp_method = ${velocity_interp_method}
    rho = ${rho}
    momentum_component = 'x'
  []
  [u_viscosity]
    type = INSFVMomentumDiffusion
    variable = vel_x
    mu = ${mu}
    momentum_component = 'x'
  []
  [u_pressure]
    type = INSFVMomentumPressure
    variable = vel_x
    momentum_component = 'x'
    pressure = pressure
    extra_vector_tags = ${pressure_tag}
  []
  [v_advection]
    type = INSFVMomentumAdvection
    variable = vel_y
    advected_interp_method = ${advected_interp_method}
    velocity_interp_method = ${velocity_interp_method}
    rho = ${rho}
    momentum_component = 'y'
  []
  [v_viscosity]
    type = INSFVMomentumDiffusion
    variable = vel_y
    mu = ${mu}
    momentum_component = 'y'
  []
  [v_pressure]
    type = INSFVMomentumPressure
    variable = vel_y
    momentum_component = 'y'
    pressure = pressure
    extra_vector_tags = ${pressure_tag}
  []
  [w_advection]
    type = INSFVMomentumAdvection
    variable = vel_z
    advected_interp_method = ${advected_interp_method}
    velocity_interp_method = ${velocity_interp_method}
    rho = ${rho}
    momentum_component = 'y'
  []
  [w_viscosity]
    type = INSFVMomentumDiffusion
    variable = vel_z
    mu = ${mu}
    momentum_component = 'z'
  []
  [w_pressure]
    type = INSFVMomentumPressure
    variable = vel_z
    momentum_component = 'z'
    pressure = pressure
    extra_vector_tags = ${pressure_tag}
  []
  [p_diffusion]
    type = FVDiffusion
    variable = pressure
    coeff = "Ainv"
    coeff_interp_method = 'average'
  []
  [p_source]
    type = FVDivergence
    variable = pressure
    vector_field = "HbyA"
    force_boundary_execution = true
  []
[]

[FVBCs]
  [inlet-u]
    type = INSFVInletVelocityBC
    boundary = 'back'
    variable = vel_x
    function = '0'
  []
  [inlet-v]
    type = INSFVInletVelocityBC
    boundary = 'back'
    variable = vel_y
    function = '0'
  []
  [inlet-w]
    type = INSFVInletVelocityBC
    boundary = 'back'
    variable = vel_z
    function = '1.1'
  []
  [walls-u]
    type = INSFVNoSlipWallBC
    boundary = 'left right top bottom '
    variable = vel_x
    function = 0.0
  []
  [walls-v]
    type = INSFVNoSlipWallBC
    boundary = 'left right top bottom'
    variable = vel_y
    function = 0.0
  []
  [walls-w]
    type = INSFVNoSlipWallBC
    boundary = 'left right top bottom'
    variable = vel_z
    function = 0.0
  []
  [outlet_p]
    type = INSFVOutletPressureBC
    boundary = 'front'
    variable = pressure
    function = 1.4
  []
  [zero-grad-pressure]
    type = FVFunctionNeumannBC
    variable = pressure
    boundary = 'back left right top bottom'
    function = 0.0
  []
[]

[Executioner]
  type = SIMPLE
  solve_type = 'NEWTON'
  petsc_options_iname = '-pc_type -pc_hypre_type -pc_factor_shift_type'
  petsc_options_value = 'hypre boomeramg NONZERO'
  nl_max_its = 1
  l_max_its = 400
  l_abs_tol = 1e-8
  l_tol = 1e-8
  line_search = 'none'
  rhie_chow_user_object = 'rc'
  momentum_systems = 'momentum_system'
  pressure_system = 'pressure_system'
  pressure_gradient_tag = ${pressure_tag}
  momentum_equation_relaxation = 0.8
  pressure_variable_relaxation = 0.3
  num_iterations = 60
  pressure_absolute_tolerance = 1e-9
  momentum_absolute_tolerance = 1e-9
  print_fields = false
[]

[Outputs]
  exodus = true
  csv = false
  perf_graph = false
  print_nonlinear_residuals = false
  print_linear_residuals = true
[]
