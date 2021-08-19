//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#pragma once
#include "Calculators.h"
#include "NormalDistribution.h"
#include "StochasticToolsUtils.h"

#include "Shuffle.h"
#include "MooseTypes.h"
#include "MooseObject.h"
#include "MooseEnum.h"
#include "MooseError.h"
#include "MooseRandom.h"

#include "libmesh/auto_ptr.h"
#include "libmesh/parallel.h"
#include "libmesh/parallel_sync.h"

#include <vector>

class MooseEnum;
class MooseEnumItem;
class MooseRandom;

namespace StochasticTools
{
template <typename InType, typename OutType>
class Calculator;

/*
 * Return available bootstrap statistics calculators.
 */
MooseEnum makeBootstrapCalculatorEnum();

/**
 * Base class for computing bootstrap confidence level intervals. These classes follow the same
 * design pattern as those Statistics.h.
 * @param other ParallelObject that is providing the Communicator
 * @param levels The bootstrap confidence level intervals to compute in range (0, 1)
 * @param replicates Number of bootstrap replicates to perform
 * @param seed Seed for random number generator
 */
template <typename InType, typename OutType>
class BootstrapCalculator : public libMesh::ParallelObject
{
public:
  BootstrapCalculator(const libMesh::ParallelObject & other,
                      const std::string & name,
                      const std::vector<Real> & levels,
                      unsigned int replicates,
                      unsigned int seed,
                      StochasticTools::Calculator<InType, OutType> & calc);
  virtual std::vector<OutType> compute(const InType &, const bool) = 0;
  const std::string & name() const { return _name; }

protected:
  // Compute Bootstrap estimates of a statistic
  std::vector<OutType> computeBootstrapEstimates(const InType &, const bool);

  // Confidence levels to compute in range (0, 1)
  const std::vector<Real> _levels;

  // Number of bootstrap replicates
  const unsigned int _replicates;

  // Random seed for creating bootstrap replicates
  const unsigned int _seed;

  // The Calculator that computes the statistic of interest
  StochasticTools::Calculator<InType, OutType> & _calc;

private:
  const std::string _name;
};

/*
 * Implement percentile method of Efron and Tibshirani (2003), Chapter 13.
 */
template <typename InType, typename OutType>
class Percentile : public BootstrapCalculator<InType, OutType>
{
public:
  using BootstrapCalculator<InType, OutType>::BootstrapCalculator;
  virtual std::vector<OutType> compute(const InType &, const bool) override;
};

/*
 * This is placeholder class for BCa with general data types. Will throw an error if
 * used. Actual implementation is with OutType = Real which can be seen below.
 */
template <typename InType, typename OutType>
class BiasCorrectedAccelerated : public BootstrapCalculator<InType, OutType>
{
public:
  using BootstrapCalculator<InType, OutType>::BootstrapCalculator;
  virtual std::vector<OutType> compute(const InType &, const bool) override
  {
    mooseError(
        "Cannot compute bias corrected accelerated statistics with calculator output value type ",
        MooseUtils::prettyCppType<OutType>(),
        ".");
  }
};

/*
 * Implement BCa method of Efron and Tibshirani (2003), Chapter 14.
 */
template <typename InType>
class BiasCorrectedAccelerated<InType, Real> : public BootstrapCalculator<InType, Real>
{
public:
  using BootstrapCalculator<InType, Real>::BootstrapCalculator;
  virtual std::vector<Real> compute(const InType &, const bool) override;

private:
  // Compute the acceleration, see Efron and Tibshirani (2003), Ch. 14, Eq. 14.15, p 186.
  Real acceleration(const InType &, const bool);
};

template <typename InType, typename OutType>
BootstrapCalculator<InType, OutType>::BootstrapCalculator(
    const libMesh::ParallelObject & other,
    const std::string & name,
    const std::vector<Real> & levels,
    unsigned int replicates,
    unsigned int seed,
    StochasticTools::Calculator<InType, OutType> & calc)
  : libMesh::ParallelObject(other),
    _levels(levels),
    _replicates(replicates),
    _seed(seed),
    _calc(calc),
    _name(name)
{
  mooseAssert(*std::min_element(levels.begin(), levels.end()) > 0,
              "The supplied levels must be greater than zero.");
  mooseAssert(*std::max_element(levels.begin(), levels.end()) < 1,
              "The supplied levels must be less than one");
}

template <typename InType, typename OutType>
std::vector<OutType>
BootstrapCalculator<InType, OutType>::computeBootstrapEstimates(const InType & data,
                                                                const bool is_distributed)
{
  MooseRandom generator;
  generator.seed(0, _seed);

  // Compute replicate statistics
  std::vector<OutType> values(_replicates);
  auto calc_update = [this](const typename InType::value_type & val) { _calc.update(val); };
  for (std::size_t i = 0; i < _replicates; ++i)
  {
    _calc.initialize();
    MooseUtils::resampleAct(
        data, calc_update, generator, 0, is_distributed ? &this->_communicator : nullptr);
    _calc.finalize(is_distributed);
    values[i] = _calc.get();
  }
  inplaceSort(values);
  return values;
}

// PERCENTILE //////////////////////////////////////////////////////////////////////////////////////
template <typename InType, typename OutType>
std::vector<OutType>
Percentile<InType, OutType>::compute(const InType & data, const bool is_distributed)
{
  // Bootstrap estimates
  const std::vector<OutType> values = this->computeBootstrapEstimates(data, is_distributed);

  // Extract percentiles
  std::vector<OutType> output;
  if (this->processor_id() == 0)
    for (const Real & level : this->_levels)
    {
      long unsigned int index = std::lrint(level * (this->_replicates - 1));
      output.push_back(values[index]);
    }

  return output;
}

// BIASCORRECTEDACCELERATED ////////////////////////////////////////////////////////////////////////
template <typename InType>
std::vector<Real>
BiasCorrectedAccelerated<InType, Real>::compute(const InType & data, const bool is_distributed)
{
  if (is_distributed)
    mooseError("Due to the computational demands, the BiasCorrectedAccelerated does not work with "
               "distributed data.");

  // Bootstrap estimates
  const std::vector<Real> values = this->computeBootstrapEstimates(data, is_distributed);

  // Compute bias-correction, Efron and Tibshirani (2003), Eq. 14.14, p. 186
  const Real value = this->_calc.compute(data, is_distributed);
  const Real count = std::count_if(values.begin(), values.end(), [&value](Real v) {
    return v < value;
  }); // use Real for non-integer division below
  const Real bias = NormalDistribution::quantile(count / this->_replicates, 0, 1);

  // Compute Acceleration, Efron and Tibshirani (2003), Eq. 14.15, p. 186
  const Real acc = data.empty() ? 0. : acceleration(data, is_distributed);

  // Compute intervals, Efron and Tibshirani (2003), Eq. 14.10, p. 185
  std::vector<Real> output;
  for (const Real & level : this->_levels)
  {
    const Real z = NormalDistribution::quantile(level, 0, 1);
    const Real x = bias + (bias + (bias + z) / (1 - acc * (bias + z)));
    const Real alpha = NormalDistribution::cdf(x, 0, 1);

    long unsigned int index = std::lrint(alpha * (this->_replicates - 1));
    output.push_back(values[index]);
  }
  return output;
}

template <typename InType>
Real
BiasCorrectedAccelerated<InType, Real>::acceleration(const InType & data, const bool is_distributed)
{
  // Jackknife statistics
  InType theta_i(data.size());

  // Total number of data entries
  Real count = data.size();

  // Compute jackknife estimates, Ch. 11, Eq. 11.2, p. 141
  InType data_not_i(data.size() - 1);
  for (std::size_t i = 0; i < count; ++i)
  {
    std::copy(data.begin(), data.begin() + i, data_not_i.begin());
    std::copy(data.begin() + i + 1, data.end(), data_not_i.begin() + i);
    theta_i[i] = this->_calc.compute(data_not_i, is_distributed);
  }

  // Compute jackknife sum, Ch. 11, Eq. 11.4, p. 141
  Real theta_dot = std::accumulate(theta_i.begin(), theta_i.end(), 0.);
  theta_dot /= count;

  // Acceleration, Ch. 14, Eq. 14.15, p. 185
  Real numerator = 0.;
  Real denomenator = 0;
  for (const auto & jk : theta_i)
  {
    numerator += std::pow(theta_dot - jk, 3);
    denomenator += std::pow(theta_dot - jk, 2);
  }

  mooseAssert(denomenator != 0, "The acceleration denomenator must not be zero.");
  return numerator / (6 * std::pow(denomenator, 3. / 2.));
}

// makeBootstrapCalculator /////////////////////////////////////////////////////////////////////////
template <typename InType, typename OutType>
std::unique_ptr<BootstrapCalculator<InType, OutType>>
makeBootstrapCalculator(const MooseEnum & item,
                        const libMesh::ParallelObject & other,
                        const std::vector<Real> & levels,
                        unsigned int replicates,
                        unsigned int seed,
                        StochasticTools::Calculator<InType, OutType> & calc)
{
  std::unique_ptr<BootstrapCalculator<InType, OutType>> ptr = nullptr;
  if (item == "percentile")
    ptr = libmesh_make_unique<Percentile<InType, OutType>>(
        other, item, levels, replicates, seed, calc);
  else if (item == "bca")
    ptr = libmesh_make_unique<BiasCorrectedAccelerated<InType, OutType>>(
        other, item, levels, replicates, seed, calc);

  if (!ptr)
    ::mooseError("Failed to create Statistics::BootstrapCalculator object for ", item);

  return ptr;
}

template <typename InType, typename OutType>
std::unique_ptr<BootstrapCalculator<InType, OutType>>
makeBootstrapCalculator(const MooseEnum &,
                        const libMesh::ParallelObject &,
                        const std::vector<Real> &,
                        unsigned int,
                        unsigned int,
                        StochasticTools::Calculator<InType, OutType> & calc);

#define createBootstrapCalculators(InType, OutType)                                                \
  template class Percentile<InType, OutType>;                                                      \
  template class BiasCorrectedAccelerated<InType, OutType>;                                        \
  template std::unique_ptr<BootstrapCalculator<InType, OutType>>                                   \
  makeBootstrapCalculator<InType, OutType>(const MooseEnum &,                                      \
                                           const libMesh::ParallelObject &,                        \
                                           const std::vector<Real> &,                              \
                                           unsigned int,                                           \
                                           unsigned int,                                           \
                                           StochasticTools::Calculator<InType, OutType> &)
} // namespace
