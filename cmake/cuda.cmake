if (HAVE_CUDA)
  if(${CMAKE_VERSION} VERSION_LESS "3.17.0")
      message(FATAL_ERROR "Build with CUDA requires at least cmake 3.17.0")
  endif()

  enable_language(CUDA)

  include(global_flags)
  include(common)

  function(get_cuda_flags_from_cxx_flags OutCudaFlags CxxFlags)
    # OutCudaFlags is an output string
    # CxxFlags is a string

    set(skipList
      -gline-tables-only
      # clang coverage
      -fprofile-instr-generate
      -fcoverage-mapping
      /Zc:inline # disable unreferenced functions (kernel registrators) remove
      -Wno-c++17-extensions
      -flto
      -faligned-allocation
      -fsized-deallocation
      # While it might be reasonable to compile host part of .cu sources with these optimizations enabled,
      # nvcc passes these options down towards cicc which lacks x86_64 extensions support.
      -msse2
      -msse3
      -mssse3
      -msse4.1
      -msse4.2
    )

    set(skipPrefixRegexp
      "(-fsanitize=|-fsanitize-coverage=|-fsanitize-blacklist=|--system-header-prefix|(/|-)std(:|=)c\\+\\+).*"
    )

    string(FIND "${CMAKE_CUDA_HOST_COMPILER}" clang hostCompilerIsClangPos)
    string(COMPARE NOTEQUAL ${hostCompilerIsClangPos} -1 isHostCompilerClang)


    function(separate_arguments_with_special_symbols Output Src)
      string(REPLACE ";" "$<SEMICOLON>" LocalOutput "${Src}")
      separate_arguments(LocalOutput NATIVE_COMMAND ${LocalOutput})
      set(${Output} ${LocalOutput} PARENT_SCOPE)
    endfunction()

    separate_arguments_with_special_symbols(Separated_CxxFlags "${CxxFlags}")

    set(localCudaCommonFlags "") # non host compiler options
    set(localCudaCompilerOptions "")

    while (Separated_CxxFlags)
      list(POP_FRONT Separated_CxxFlags cxxFlag)
      if ((cxxFlag IN_LIST ${skipList}) OR (cxxFlag MATCHES ${skipPrefixRegexp}))
        continue()
      endif()
      if ((cxxFlag STREQUAL -fopenmp=libomp) AND (NOT isHostCompilerClang))
        list(APPEND localCudaCompilerOptions -fopenmp)
        continue()
      endif()
      if ((NOT isHostCompilerClang) AND (cxxFlag MATCHES "^\-\-target=.*"))
        continue()
      endif()
      if (cxxFlag MATCHES "^[-/](D|I).*")
        string(LENGTH cxxFlag cxxFlagLength)
        if (${cxxFlagLength} EQUAL 2)
          list(POP_FRONT Separated_CxxFlags value)
          list(APPEND localCudaCommonFlags "${cxxFlag}${value}")
        else()
          list(APPEND localCudaCommonFlags ${cxxFlag})
        endif()
        continue()
      endif()
      if (cxxFlag MATCHES "^(--compiler-options|-Xcompiler).*")
        string(LENGTH cxxFlag cxxFlagLength)
        if (${cxxFlag} IN_LIST --compiler-options -Xcompiler)
          list(POP_FRONT Separated_CxxFlags value)
          # because it already contains compiler option prefix
          list(APPEND localCudaCommonFlags "${cxxFlag}${value}")
        else()
          # because it already contains compiler option prefix
          list(APPEND localCudaCommonFlags ${cxxFlag})
        endif()
        continue()
      endif()
      list(APPEND localCudaCompilerOptions ${cxxFlag})
    endwhile()

    if (isHostCompilerClang)
      # nvcc concatenates the sources for clang, and clang reports unused
      # things from .h files as if they they were defined in a .cpp file.
      list(APPEND localCudaCommonFlags -Wno-unused-function -Wno-unused-parameter)
    endif()

    list(JOIN localCudaCommonFlags " " joinedLocalCudaCommonFlags)
    string(REPLACE "$<SEMICOLON>" ";" joinedLocalCudaCommonFlags "${joinedLocalCudaCommonFlags}")
    list(JOIN localCudaCompilerOptions , joinedLocalCudaCompilerOptions)
    set(${OutCudaFlags} "${joinedLocalCudaCommonFlags} --compiler-options ${joinedLocalCudaCompilerOptions}" PARENT_SCOPE)
  endfunction()

  get_cuda_flags_from_cxx_flags(CMAKE_CUDA_FLAGS "${CMAKE_CXX_FLAGS}")

  set(NVCC_STD_VER 14)
  if(MSVC)
    set(NVCC_STD "/std:c++${NVCC_STD_VER}")
  else()
    set(NVCC_STD "-std=c++${NVCC_STD_VER}")
  endif()
  string(APPEND CMAKE_CUDA_FLAGS " --compiler-options ${NVCC_STD}")

  string(APPEND CMAKE_CUDA_FLAGS " -DTHRUST_IGNORE_CUB_VERSION_CHECK")

  if(MSVC)
    # default CMake flags differ from our configuration
    set(CMAKE_CUDA_FLAGS_DEBUG "--compiler-options /Ob0,/Od,/D_DEBUG")
    set(CMAKE_CUDA_FLAGS_RELEASE "--compiler-options /Ox,/Ob2,/Oi,/DNDEBUG")
  endif()

  # use versions from contrib, standard libraries from CUDA distibution are incompatible with MSVC and libcxx
  set(CUDA_EXTRA_INCLUDE_DIRECTORIES
    ${CMAKE_SOURCE_DIR}/contrib/libs/nvidia/thrust
    ${CMAKE_SOURCE_DIR}/contrib/libs/nvidia/cub
  )

  find_package(CUDAToolkit REQUIRED)

  if(${CMAKE_CUDA_COMPILER_VERSION} VERSION_GREATER_EQUAL "11.2")
    string(APPEND CMAKE_CUDA_FLAGS " --threads 0")
  endif()

  enable_language(CUDA)

  function(target_cuda_flags Tgt)
    set_property(TARGET ${Tgt} APPEND PROPERTY
      CUDA_FLAGS ${ARGN}
    )
  endfunction()

  function(target_cuda_cflags Tgt)
    if (NOT ("${ARGN}" STREQUAL ""))
      string(JOIN "," OPTIONS ${ARGN})
      set_property(TARGET ${Tgt} APPEND PROPERTY
        CUDA_FLAGS --compiler-options ${OPTIONS}
      )
    endif()
  endfunction()

  function(target_cuda_sources Tgt Scope)
    # add include directories on per-CMakeLists file level because some non-CUDA source files may want to include calls to CUDA libs
    include_directories(${CUDA_EXTRA_INCLUDE_DIRECTORIES})

    set_source_files_properties(${ARGN} PROPERTIES
      COMPILE_OPTIONS "$<JOIN:$<TARGET_GENEX_EVAL:${Tgt},$<TARGET_PROPERTY:${Tgt},CUDA_FLAGS>>,;>"
    )
    target_sources(${Tgt} ${Scope} ${ARGN})
  endfunction()

endif()
