cmake_minimum_required(VERSION 3.14)
project(EngineMetaProject)

set(BUILD_SHARED_LIBS ON CACHE BOOL "Build all libraries as shared" FORCE)

add_subdirectory(FenixEngine)


add_subdirectory(Foxcraft)
