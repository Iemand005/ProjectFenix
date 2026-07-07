cmake_minimum_required(VERSION 3.14)
project(EngineMetaProject)

set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build all libraries as shared" FORCE)

add_subdirectory(FenixEngine)


add_subdirectory(Foxcraft)
add_subdirectory(Cake)
