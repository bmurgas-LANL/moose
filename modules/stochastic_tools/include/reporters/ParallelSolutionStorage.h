//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#pragma once

#include "GeneralReporter.h"

class ParallelSolutionStorage : public GeneralReporter
{
public:
  static InputParameters validParams();
  ParallelSolutionStorage(const InputParameters & parameters);
  virtual void initialSetup() override;
  virtual void initialize() override{};
  virtual void execute() override{};
  virtual void finalize() override {}

  void addEntry(const VariableName & vname,
                const std::vector<std::unique_ptr<std::vector<Real>>> & solutions);

protected:
  std::map<VariableName, std::vector<std::unique_ptr<std::vector<Real>>>> & _distributed_solutions;
};
