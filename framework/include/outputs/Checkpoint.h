//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#pragma once

// MOOSE includes
#include "FileOutput.h"

#include <deque>
#include <filesystem>

/**
 * Enumerated type for determining what type of checkpoint this is.
 * SYSTEM_CREATED: This type of checkpoint is created automatically by the
 *   system for the purpose of writing checkpoints at regularly scheduled
 *   walltime intervals or when sent a signal.
 * USER_CREATED: Checkpoint is requested by the user in the input
 *   file, and can be used by the system to also output at walltime intervals or
 *   when sent a signal.
 */
enum CheckpointType : unsigned short
{
  NONE,
  SYSTEM_CREATED,
  USER_CREATED
};

class MaterialPropertyStorage;

/**
 * A structure for storing the various output files associated with checkpoint output
 */
struct CheckpointFileNames
{
  /// Filename for CheckpointIO file (the mesh)
  std::string checkpoint;

  /// Filenames for restartable data
  std::vector<std::filesystem::path> restart;
};

/**
 * Writes out three things:
 *
 * 1. A restart file with a `.rd` extendsion that contains a single Backup that has been serialized
 * 2. Mesh file(s) in the form of a libMesh Checkpoint file(s)
 * 3. Mesh meta-data file... this will be underneath the directory that the Checkpoint mesh creates
 *
 * These files are written to a directory called output_prefix + _ + "_cp"
 */
class Checkpoint : public FileOutput
{
public:
  static InputParameters validParams();

  /**
   * Class constructor
   * @param parameters
   */
  Checkpoint(const InputParameters & parameters);

  /**
   * Returns the base filename for the checkpoint files
   */
  virtual std::string filename() override;

  /**
   * Retrieve the checkpoint output directory
   * @return String containing the checkpoint output directory
   */
  std::string directory() const;

  /// Output all necessary data for a single timestep.
  virtual void outputStep(const ExecFlagType & type) override;

  /// Sets the autosave flag manually if the object has already been initialized.
  void setAutosaveFlag(CheckpointType flag) { _checkpoint_type = flag; }

protected:
  /**
   * Outputs a checkpoint file.
   * Each call to this function creates various files associated with
   */
  virtual void output() override;

  /// Determines if the checkpoint should write out to a file.
  virtual bool shouldOutput() override;

private:
  void updateCheckpointFiles(CheckpointFileNames file_struct);

  /// Determines if this checkpoint is an autosave, and what kind of autosave it is.
  CheckpointType _checkpoint_type;

  /// Max no. of output files to store
  unsigned int _num_files;

  /// Directory suffix
  const std::string _suffix;

  /// Vector of checkpoint filename structures
  std::deque<CheckpointFileNames> _file_names;
};
