//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#pragma once

#include "MeshGenerator.h"
#include "libmesh/elem.h"

namespace RGMB
{

// General global quantities for mesh building
static const std::string mesh_dimensions = "mesh_dimensions";
static const std::string mesh_geometry = "mesh_geometry";
static const std::string top_boundary_id = "top_boundary_id";
static const std::string bottom_boundary_id = "bottom_boundary_id";
static const std::string radial_boundary_id = "radial_boundary_id";
static const std::string axial_mesh_intervals = "axial_mesh_intervals";
static const std::string axial_mesh_sizes = "axial_mesh_sizes";
static const std::string reactor_params_name = "reactor_params_name";
static const std::string is_single_pin = "is_single_pin";
static const std::string is_homogenized = "is_homogenized";
static const std::string extruded = "extruded";
static const std::string generate_metadata = "generate_rgmb_metadata";
static const std::string pin_region_ids = "pin_region_ids";
static const std::string pin_block_names = "pin_block_names";
static const std::string pin_region_id_map = "pin_region_id_map";
static const std::string pin_block_name_map = "pin_block_name_map";
static const std::string pin_map_type_to_name = "pin_map_type_to_name";

// Geometrical quantities
static const std::string pitch = "pitch";
static const std::string assembly_pitch = "assembly_pitch";
static const std::string ring_radii = "ring_radii";
static const std::string duct_halfpitches = "duct_halfpitches";
static const std::string peripheral_ring_radius = "peripheral_ring_radius";
static const std::string lattice = "lattice";

// Quantities related to region ids, type ids, and block names
static const std::string pin_type = "pin_type";
static const std::string pin_types = "pin_types";
static const std::string assembly_type = "assembly_type";
static const std::string assembly_types = "assembly_types";
static const std::string ring_region_ids = "ring_region_ids";
static const std::string background_region_id = "background_region_id";
static const std::string background_block_name = "background_block_name";
static const std::string duct_region_ids = "duct_region_ids";
static const std::string duct_block_names = "duct_block_names";
static const std::string peripheral_ring_region_id = "peripheral_ring_region_id";

}

/**
 * A base class that contains common members for Reactor Geometry Mesh Builder mesh generators.
 */
class ReactorGeometryMeshBuilderBase : public MeshGenerator
{
public:
  static InputParameters validParams();

  ReactorGeometryMeshBuilderBase(const InputParameters & parameters);

protected:
  /**
   * Initializes extra element integer from id name for a given mesh and throws an error
   * if it should exist but cannot be found within the mesh
   * @param input_mesh input mesh
   * @param extra_int_name extra element id name
   * @param should_exist whether extra element integer should already exist in mesh
   * @return extra element integer
   */
  unsigned int getElemIntegerFromMesh(MeshBase & input_mesh,
                                      std::string extra_int_name,
                                      bool should_exist = false);

  /**
   * Initializes and checks validity of ReactorMeshParams mesh generator object
   * @param reactor_param_name name of ReactorMeshParams mesh generator
   */
  void initializeReactorMeshParams(const std::string reactor_param_name);

  /**
   * Declares global reactor-level metadata onto current ReactorGeometryMeshBuilder object
   * @param prefix prefix to preprend to add metadata names
   */
  void generateGlobalReactorMetadata(const std::string prefix);

  /**
   * Copies pin-level metadata to current ReactorGeometryMeshBuilder object
   * @param input_name name of input mesh generator object to copy metadata from
   * @param pin_type_id pin_type_id of pin to query metadata of
   */
  void copyPinMetadata(const std::string input_name, const unsigned int pin_type_id);

  /**
   * Copies assembly-level metadata to current ReactorGeometryMeshBuilder object
   * @param input_name name of input mesh generator object to copy metadata from
   * @param assembly_type_id assembly_type_id of pin to query metadata of
   */
  void copyAssemblyMetadata(const std::string input_name, const unsigned int assembly_type_id);

  /**
   * Print metadata associated with ReactorGeometryMeshBuilder object
   * @param metadata_prefix Prefix associated with metadata
   * @param whether this is the original function call, which will trigger additional output
   * messages
   */
  void printReactorMetadata(const std::string metadata_prefix,
                            const bool first_function_call = true);

  /**
   * Print core-level metadata associated with ReactorGeometryMeshBuilder object
   * @param prefix Prefix associated with metadata
   * @param whether this is the original function call, which will trigger additional output
   * messages
   */
  void printCoreMetadata(const std::string prefix, const bool first_function_call);

  /**
   * Print assembly-level metadata associated with ReactorGeometryMeshBuilder object
   * @param prefix Prefix associated with metadata
   * @param whether this is the original function call, which will trigger additional output
   * messages
   */
  void printAssemblyMetadata(const std::string prefix, const bool first_function_call);

  /**
   * Print pin-level metadata associated with ReactorGeometryMeshBuilder object
   * @param prefix Prefix associated with metadata
   */
  void printPinMetadata(const std::string prefix);

  /**
   * Print global ReactorMeshParams metadata associated with ReactorGeometryMeshBuilder object
   * @param prefix Prefix associated with metadata
   */
  void printGlobalReactorMetadata(const std::string prefix);

  /**
   * Print metadata in the form "<prefix>_<name> to console output
   * @tparam T datatype of metadata value to output
   * @param prefix Prefix associated with metadata name
   * @param name Base name of metadata to output
   */
  template <typename T>
  void printMetadataToConsole(const std::string prefix, const std::string name);

  /**
   * Print metadata in the form "<prefix>_<name> with data stype std::vector<std::vector<T>> to
   * console output
   * @tparam T datatype of elements in 2-D vector to output
   * @param prefix Prefix associated with metadata name
   * @param name Base name of metadata to output
   */
  template <typename T>
  void print2dMetadataToConsole(const std::string prefix, const std::string name);

  /**
   * Copy reactor metadata from source mesh to current mesh
   * @tparam T datatype of metadata value to copy
   * @param prefix Prefix associated with metadata name
   * @param name Base name of metadata to copy
   * @param source_mesh Name of mesh containing metadata to copy from
   */
  template <typename T>
  T &
  copyReactorMetadata(const std::string prefix, const std::string name, std::string source_mesh);

  /**
   * Releases the mesh obtained in _reactor_params_mesh.
   *
   * This _must_ be called in any object that derives from this one, because
   * the MeshGenerator system requires that all meshes that are requested from
   * the system are moved out of the MeshGenerator system and into the MeshGenerator
   * that requests them. In our case, we move it into this MeshGenerator and then
   * release (delete) it.
   */
  void freeReactorMeshParams();

  /**
   * Checks whether parameter is defined in ReactorMeshParams metadata
   * @tparam T datatype of metadata value associated with metadata name
   * @param param_name name of ReactorMeshParams parameter
   * @return whether parameter is defined in ReactorMeshParams metadata
   */
  template <typename T>
  bool hasReactorParam(const std::string param_name);

  /**
   * Returns reference of parameter in ReactorMeshParams object
   * @tparam T datatype of metadata value associated with metadata name
   * @param param_name name of ReactorMeshParams parameter
   * @return reference to parameter defined in ReactorMeshParams metadata
   */
  template <typename T>
  const T & getReactorParam(const std::string & param_name);

  /**
   * Updates the block names and ids of the element in an input mesh according
   * to a map of block name to block ids. Updates the map if the block name is not in the map
   * @param input_name input mesh
   * @param elem iterator to mesh element
   * @param name_id_map map of name-id pairs used in mesh
   * @param elem_block_name block name to set for element
   * @param next_free_id next free block id to use if block name does not exist in map
   */
  void updateElementBlockNameId(MeshBase & input_mesh,
                                Elem * elem,
                                std::map<std::string, SubdomainID> & name_id_map,
                                std::string elem_block_name,
                                SubdomainID & next_free_id);

  ///The ReactorMeshParams object that is storing the reactor global information for this reactor geometry mesh
  MeshGeneratorName _reactor_params;

private:
  /// The dummy param mesh that we need to clear once we've generated (in freeReactorMeshParams)
  std::unique_ptr<MeshBase> * _reactor_params_mesh;
};

template <typename T>
bool
ReactorGeometryMeshBuilderBase::hasReactorParam(const std::string param_name)
{
  return hasMeshProperty<T>(param_name, _reactor_params);
}

template <typename T>
const T &
ReactorGeometryMeshBuilderBase::getReactorParam(const std::string & param_name)
{
  return getMeshProperty<T>(param_name, _reactor_params);
}
