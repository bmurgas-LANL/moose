mu = 1.1
rho = 1.1
l = 200
U = 1
advected_interp_method = 'upwind'
velocity_interp_method = 'rc'

[GlobalParams]
  rhie_chow_user_object = 'rc'
[]

[UserObjects]
  [rc]
    type = INSFVRhieChowInterpolator
    u = vel_x
    v = vel_y
    pressure = pressure
  []
[]

[Mesh]
  [gen]
    type = GeneratedMeshGenerator
    dim = 2
    xmin = 0
    xmax = 10
    ymin = ${fparse -l / 2}
    ymax = ${fparse l / 2}
    nx = 100
    ny = 20
  []
  uniform_refine = 4
[]

[Variables]
  [vel_x]
    type = INSFVVelocityVariable
    initial_condition = 1
  []
  [vel_y]
    type = INSFVVelocityVariable
    initial_condition = 1
  []
  [pressure]
    type = INSFVPressureVariable
  []
[]

[FVKernels]
  [mass]
    type = INSFVMassAdvection
    variable = pressure
    advected_interp_method = ${advected_interp_method}
    velocity_interp_method = ${velocity_interp_method}
    rho = ${rho}
  []

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
  []
[]

[FVBCs]
  [inlet-u]
    type = INSFVInletVelocityBC
    boundary = 'left'
    variable = vel_x
    function = '${U}'
  []
  [inlet-v]
    type = INSFVInletVelocityBC
    boundary = 'left'
    variable = vel_y
    function = '0'
  []
  [walls-u]
    type = INSFVNoSlipWallBC
    boundary = 'top bottom'
    variable = vel_x
    function = 0
  []
  [walls-v]
    type = INSFVNoSlipWallBC
    boundary = 'top bottom'
    variable = vel_y
    function = 0
  []
  [outlet_p]
    type = INSFVOutletPressureBC
    boundary = 'right'
    variable = pressure
    function = '0'
  []
[]

[Executioner]
  type = Steady
  solve_type = 'NEWTON'
  nl_rel_tol = 1e-12
[]

[Preconditioning]
  active = FSP
  [FSP]
    type = FSP
    # It is the starting point of splitting
    topsplit = 'up' # 'up' should match the following block name
    [up]
      splitting = 'u p' # 'u' and 'p' are the names of subsolvers
      splitting_type  = schur
      # Splitting type is set as schur, because the pressure part of Stokes-like systems
      # is not diagonally dominant. CAN NOT use additive, multiplicative and etc.
      #
      # Original system:
      #
      # | Auu Aup | | u | = | f_u |
      # | Apu 0   | | p |   | f_p |
      #
      # is factorized into
      #
      # |I             0 | | Auu  0|  | I  Auu^{-1}*Aup | | u | = | f_u |
      # |Apu*Auu^{-1}  I | | 0   -S|  | 0  I            | | p |   | f_p |
      #
      # where
      #
      # S = Apu*Auu^{-1}*Aup
      #
      # The preconditioning is accomplished via the following steps
      #
      # (1) p* = f_p - Apu*Auu^{-1}f_u,
      # (2) p = (-S)^{-1} p*
      # (3) u = Auu^{-1}(f_u-Aup*p)

      petsc_options = '-ksp_monitor_true_residual -snes_monitor -ksp_converged_reason -snes_converged_reason'
      petsc_options_iname = '-pc_fieldsplit_schur_fact_type  -pc_fieldsplit_schur_precondition -ksp_gmres_restart -ksp_rtol -ksp_type'
      petsc_options_value = 'full                            selfp                             300		  1e-4	    fgmres'
    []
    [u]
      vars = 'vel_x vel_y'
      petsc_options_iname = '-pc_type -pc_hypre_type -ksp_type -ksp_rtol -ksp_gmres_restart'
      petsc_options_value = 'hypre    boomeramg	     fgmres    1e-1	 300'
    []
    [p]
      vars = 'pressure'
      petsc_options_iname = '-ksp_type -ksp_gmres_restart -ksp_rtol -pc_type'
      petsc_options_value = 'fgmres    300		  1e-1	    jacobi'
    []
  []
  [SMP]
    type = SMP
    full = true
    petsc_options_iname = '-pc_type -pc_factor_shift_type'
    petsc_options_value = 'lu       NONZERO'
  []
[]

[Outputs]
  print_linear_residuals = false
  print_nonlinear_residuals = false
  active = 'perf'
  [out]
    type = Exodus
    hide = 'Re'
  []
  [perf]
    type = PerfGraphOutput
  []
[]

[Postprocessors]
  [Re]
    type = ParsedPostprocessor
    function = '${rho} * ${l} * ${U}'
    pp_names = ''
  []
  [lin]
    type = NumLinearIterations
  []
  [cum_lin]
    type = CumulativeValuePostprocessor
    postprocessor = lin
  []
[]
