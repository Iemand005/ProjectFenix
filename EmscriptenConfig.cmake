# Protect against multiple inclusions
if(TARGET emscripten_wasm_settings)
    return()
endif()


function(setup_emscripten_target target_name)
    if(NOT EMSCRIPTEN)
        return()
    endif()

    set(oneValueArgs RESOURCE_DIR)
    set(multiValueArgs EXTRA_LINK_OPTIONS)
    cmake_parse_arguments(ARG "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Debug: symbols + source maps
    target_compile_options(${target_name} PRIVATE
        $<$<CONFIG:Debug>:-g -fdebug-compilation-dir="${CMAKE_SOURCE_DIR}">
    )
    target_link_options(${target_name} PRIVATE
        $<$<CONFIG:Debug>:-g -gsource-map>
    )

    # Release: maximum size optimization, no debug info
    target_compile_options(${target_name} PRIVATE
        $<$<CONFIG:Release>:-Oz -flto>
    )
    target_link_options(${target_name} PRIVATE
        $<$<CONFIG:Release>:-Oz -flto --closure 1 -sASSERTIONS=0>
    )

    # Common link flags
    target_link_options(${target_name} PRIVATE
        -sUSE_WEBGL2=1
        -sFULL_ES3=1
        -sGL_ENABLE_GET_PROC_ADDRESS=1
        -sALLOW_MEMORY_GROWTH=1
        -sINITIAL_MEMORY=128MB
        -sNO_EXIT_RUNTIME=1
        -sEXIT_RUNTIME=0
        -sMAX_WEBGL_VERSION=2
        -sMIN_WEBGL_VERSION=2
        -sFORCE_FILESYSTEM=1
        -sEXPORTED_RUNTIME_METHODS=FS,ccall,cwrap,HEAPF32,HEAPU8
        -sEXPORTED_FUNCTIONS=_main,_emscripten_file_dialog_callback,_malloc,_free
    )

    if(ARG_RESOURCE_DIR)
        if(NOT EXISTS "${ARG_RESOURCE_DIR}")
            message(WARNING "setup_emscripten_target(${target_name}): RESOURCE_DIR '${ARG_RESOURCE_DIR}' does not exist")
        endif()
        file(TO_CMAKE_PATH "${ARG_RESOURCE_DIR}" _res_cmake_path)
        target_link_options(${target_name} PRIVATE
            "--preload-file=${_res_cmake_path}@resources"
        )
    endif()

    if(ARG_EXTRA_LINK_OPTIONS)
        target_link_options(${target_name} PRIVATE ${ARG_EXTRA_LINK_OPTIONS})
    endif()

    set_target_properties(${target_name} PROPERTIES SUFFIX ".html")
endfunction()
