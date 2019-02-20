#ifndef SUPERSONICINLET_H
#define SUPERSONICINLET_H

#include "FlowBoundary.h"

class SupersonicInlet;

template <>
InputParameters validParams<SupersonicInlet>();

/**
 *
 */
class SupersonicInlet : public FlowBoundary
{
public:
  SupersonicInlet(const InputParameters & parameters);

  virtual void addMooseObjects() override;

protected:
  virtual void check() const override;
};

#endif /* SUPERSONICINLET_H */
