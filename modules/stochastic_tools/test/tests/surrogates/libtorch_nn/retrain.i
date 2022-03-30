[StochasticTools]
[]

[Samplers]
  [sample]
    type = CartesianProduct
    linear_space_items = '0 0.0125 5
                          0 0.0125 5
                          0 0.0125 5'
  []
  [test]
    type = CartesianProduct
    linear_space_items = '0 0.05 2
                          0 0.05 2
                          0 0.05 2'
  []
[]

[VectorPostprocessors]
  [values]
    type = GFunction
    sampler = sample
    q_vector = '0 0 0'
    execute_on = INITIAL
    outputs = none
  []
[]

[Trainers]
  [train]
    type = LibtorchSimpleNNTrainer
    sampler = sample
    response = values/g_values
    num_epochs = 40
    num_batches = 10
    num_hidden_layers = 2
    num_neurons_per_layer = '64 32'
    learning_rate = 0.001
    filename = mynet.pt
    read_from_file = false
    print_epoch_loss = 10
  []
[]

[Surrogates]
  [surr]
    type = LibtorchSimpleNNSurrogate
    trainer = train
  []
[]

[Reporters]
  [results]
    type = EvaluateSurrogate
    model = surr
    sampler = test
    execute_on = FINAL
    parallel_type = ROOT
  []
[]

[Outputs]
  csv=true
  execute_on = FINAL
[]
