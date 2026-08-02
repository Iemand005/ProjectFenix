cmake_minimum_required(VERSION 3.16)

# Nuke Windows API-set injection from the ground up — must be BEFORE project()
set(CMAKE_USER_MAKE_RULES_OVERRIDE_CXX "${CMAKE_CURRENT_SOURCE_DIR}/cxx_override.cmake")

project(EngineMetaProject)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(MSVC)
    # Forceer de vlaggen leeg op Windows/MSVC niveau
    set(CMAKE_CXX_FLAGS "" CACHE STRING "" FORCE)
    set(CMAKE_CXX_FLAGS_DEBUG "" CACHE STRING "" FORCE)
    set(CMAKE_CXX_FLAGS_RELEASE "" CACHE STRING "" FORCE)
    
    # Voeg alleen de absolute basis toe (Waarschuwingen GEEN fouten, normale waarschuwingen)
    add_compile_options(/W3 /WX-)

    # --- Compile-time optimizations for MSVC ---
    # Multiprocessor compilation (cl /MP) — parallelizes compilation within a target
    add_compile_options(/MP)
    # Conformant preprocessor everywhere so PCH + sources never disagree
    # (only on MSVC 19.25+ / VS2019 16.5+; v141/14.16 doesn't support it)
    if(MSVC_VERSION GREATER_EQUAL 1925)
        add_compile_options(/Zc:preprocessor)
    endif()
    # Disable MSVC module scanning overhead (no C++20 modules are used)
    set(CMAKE_CXX_SCAN_FOR_MODULES OFF)
    # Skip minimal-rebuild bookkeeping
    add_compile_options(/Gm-)
    # Large objects (needed once unity builds merge many .cpp files)
    add_compile_options(/bigobj)

    # Exclude Windows 10-only default libs that pull in api-ms-win DLLs
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /NODEFAULTLIB:onecore.lib /NODEFAULTLIB:onecoreuap.lib /NODEFAULTLIB:mincore.lib /NODEFAULTLIB:api-ms-win-core-libraryloader-l1-2-0.lib" CACHE STRING "" FORCE)
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} /NODEFAULTLIB:onecore.lib /NODEFAULTLIB:onecoreuap.lib /NODEFAULTLIB:mincore.lib /NODEFAULTLIB:api-ms-win-core-libraryloader-l1-2-0.lib" CACHE STRING "" FORCE)
endif()

# Target Windows 7 for ALL subprojects — prevents api-ms-win-* DLL imports
# by telling the Windows 10 SDK headers/libs to use kernel32.dll directly.
add_compile_definitions(
    _WIN32_WINNT=0x0601
    WINVER=0x0601
    NTDDI_VERSION=0x06010000
)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# set(FE_INCLUDE_OPENVR ON CACHE BOOL "Include OpenVR" FORCE)

# Force a consistent MSVC runtime across all subprojects to avoid
# linker mismatches (LNK2038) between static and dynamic CRTs.
if(MSVC)
	# Use dynamic CRT for Release and Debug (uses /MD for Release and /MDd for Debug)
	# set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL" CACHE STRING "MSVC runtime" FORCE)
	set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>" CACHE STRING "MSVC runtime" FORCE)
endif()

# set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build all libraries as shared" FORCE)

# Windows 7 compatibility shim — forwards api-ms-win imports to kernel32.dll
add_subdirectory(FenixEngine/external/win7compat)

# Prepend our custom kernel32_win7.lib directory so the linker finds it FIRST,
# before the Windows 10 SDK's kernel32.lib (which forwards through api-ms-win DLLs).
if(MSVC)
    link_directories(BEFORE "${CMAKE_BINARY_DIR}/FenixEngine/external/win7compat")
endif()

# Don't add FenixEngine directly here — each project adds it via if(NOT TARGET Engine),
# so the first project to run controls whether Jolt is included.

add_subdirectory(Foxcraft)
add_subdirectory(Cake)
add_subdirectory(Tunnel)
add_subdirectory(ShaderSavers)
add_subdirectory(Atmosphere)
add_subdirectory(Labyrinth)
add_subdirectory(FoxRacing)
add_subdirectory(FenixWeb)
if(Qt6_FOUND)
	add_subdirectory(FenixEditor)
else()
	message(WARNING "Qt6 was not found. Skipping the Qt-dependent project, but configuring everything else.")
endif()
# add_subdirectory(Tunnel)


if(MSVC)
    # Verwijdert /WX en /Wall hardhandig uit de globale build-vlaggen
    string(REPLACE "/WX" "" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
    string(REPLACE "/Wall" "/W3" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}" CACHE STRING "" FORCE)
endif()