#ifndef INLETDENSITYVELOCITY_H
#define INLETDENSITYVELOCITY_H

#include "FlowBoundary.h"

class InletDensityVelocity;

template <>
InputParameters validParams<InletDensityVelocity>();

/**
 * Boundary condition with prescribed density and velocity for pipes
 *
 */
class InletDensityVelocity : public FlowBoundary
{
public:
  InletDensityVelocity(const InputParameters & params);

  virtual void addMooseObjects() override;

protected:
  virtual void check() const override;

  /// True to allow the flow to reverse, otherwise false
  bool _reversible;

  void setup1Phase();
  void setup2Phase();
  void setup2PhaseNCG();
};

#endif /* INLETDENSITYVELOCITY_H */
