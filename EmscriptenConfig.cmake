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

    target_compile_options(${target_name} PRIVATE
        -g
        -fdebug-compilation-dir="${CMAKE_SOURCE_DIR}"
    )

    target_link_options(${target_name} PRIVATE
        -g
        -gsource-map
        -sUSE_WEBGL2=1
        -sFULL_ES3=1
        -sGL_ENABLE_GET_PROC_ADDRESS=1
        -sALLOW_MEMORY_GROWTH=1
        -sINITIAL_MEMORY=64MB
        -sNO_EXIT_RUNTIME=1
        -sEXIT_RUNTIME=0
        -sMAX_WEBGL_VERSION=2
        -sMIN_WEBGL_VERSION=2
        -sFORCE_FILESYSTEM=1
        -sEXPORTED_RUNTIME_METHODS=FS,ccall,cwrap
        -sEXPORTED_FUNCTIONS=_main,_emscripten_file_dialog_callback,_malloc,_free
    )

    if(ARG_RESOURCE_DIR)
        if(NOT EXISTS "${ARG_RESOURCE_DIR}")
            message(WARNING "setup_emscripten_target(${target_name}): RESOURCE_DIR '${ARG_RESOURCE_DIR}' does not exist")
        endif()
        target_link_options(${target_name} PRIVATE
            "--preload-file=${ARG_RESOURCE_DIR}@resources"
        )
    endif()

    if(ARG_EXTRA_LINK_OPTIONS)
        target_link_options(${target_name} PRIVATE ${ARG_EXTRA_LINK_OPTIONS})
    endif()

    set_target_properties(${target_name} PROPERTIES SUFFIX ".html")
endfunction()