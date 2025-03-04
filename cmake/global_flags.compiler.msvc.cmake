set(_WARNS_ENABLED
  4018  # 'expression' : signed/unsigned mismatch
  4265  # 'class' : class has virtual functions, but destructor is not virtual
  4296  # 'operator' : expression is always false
  4431  # missing type specifier - int assumed
)

set(_WARNS_AS_ERROR
  4013  # 'function' undefined; assuming extern returning int
)

set(_WARNS_DISABLED
    # While this warning corresponds to enabled-by-default -Wmacro-redefinition,
    # it floods clog with abundant amount of log lines,
    # as yvals_core.h from Windows SDK redefines certain
    # which macros logically belong to libcxx
    4005  # '__cpp_lib_*': macro redefinition.

    # Ne need to recheck this, but it looks like _CRT_USE_BUILTIN_OFFSETOF still makes sense
    4117  # macro name '_CRT_USE_BUILTIN_OFFSETOF' is reserved, '#define' ignored

    4127  # conditional expression is constant
    4200  # nonstandard extension used : zero-sized array in struct/union
    4201  # nonstandard extension used : nameless struct/union
    4351  # elements of array will be default initialized
    4355  # 'this' : used in base member initializer list
    4503  # decorated name length exceeded, name was truncated
    4510  # default constructor could not be generated
    4511  # copy constructor could not be generated
    4512  # assignment operator could not be generated
    4554  # check operator precedence for possible error; use parentheses to clarify precedence
    4610  # 'object' can never be instantiated - user defined constructor required
    4706  # assignment within conditional expression
    4800  # forcing value to bool 'true' or 'false' (performance warning)
    4996  # The POSIX name for this item is deprecated
    4714  # function marked as __forceinline not inlined
    4197  # 'TAtomic' : top-level volatile in cast is ignored
    4245  # 'initializing' : conversion from 'int' to 'ui32', signed/unsigned mismatch
    4324  # 'ystd::function<void (uint8_t *)>': structure was padded due to alignment specifier
    5033  # 'register' is no longer a supported storage class
)

set (_MSVC_COMMON_C_CXX_FLAGS " \
  /DARCADIA_ROOT=$(SolutionDir.Replace('\\','/')).. \
  /DARCADIA_BUILD_ROOT=$(SolutionDir.Replace('\\','/'))$(Configuration) \
  /DWIN32 \
  /D_WIN32 \
  /D_WINDOWS \
  /D_CRT_SECURE_NO_WARNINGS \
  /D_CRT_NONSTDC_NO_WARNINGS \
  /D_USE_MATH_DEFINES \
  /D__STDC_CONSTANT_MACROS \
  /D__STDC_FORMAT_MACROS \
  /D_USING_V110_SDK71_ \
  /D_LIBCPP_ENABLE_CXX17_REMOVED_FEATURES \
  /DWIN32_LEAN_AND_MEAN \
  /DNOMINMAX \
  /nologo \
  /Zm500 \
  /GR \
  /bigobj \
  /FC \
  /EHs \
  /errorReport:prompt \
  /Zc:inline \
  /utf-8 \
  /permissive- \
  /D_WIN32_WINNT=0x0601 \
  /D_MBCS \
  /DY_UCRT_INCLUDE=\"$(UniversalCRT_IncludePath.Split(';')[0].Replace('\\','/'))\" \
  /DY_MSVC_INCLUDE=\"$(VC_VC_IncludePath.Split(';')[0].Replace('\\','/'))\" \
  /MP \
")

foreach(WARN ${_WARNS_AS_ERROR})
  string(APPEND _MSVC_COMMON_C_CXX_FLAGS " /we${WARN}")
endforeach()

foreach(WARN ${_WARNS_ENABLED})
  string(APPEND _MSVC_COMMON_C_CXX_FLAGS " /w1${WARN}")
endforeach()

foreach(WARN ${_WARNS_DISABLED})
  string(APPEND _MSVC_COMMON_C_CXX_FLAGS " /wd${WARN}")
endforeach()

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${_MSVC_COMMON_C_CXX_FLAGS} \
")

# TODO - '/D_CRT_USE_BUILTIN_OFFSETOF'
# TODO - -DUSE_STL_SYSTEM

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${_MSVC_COMMON_C_CXX_FLAGS} \
  /std:c++latest \
  /Zc:__cplusplus \
")
set(CMAKE_CXX_FLAGS_DEBUG "/Z7")
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "/Z7")

if ((CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64") OR (CMAKE_SYSTEM_PROCESSOR STREQUAL "AMD64"))
  set(CMAKE_C_FLAGS "\
    ${CMAKE_C_FLAGS} \
      /D_WIN64 \
      /DWIN64 \
  ")
  set(CMAKE_CXX_FLAGS "\
    ${CMAKE_CXX_FLAGS} \
      /D_WIN64 \
      /DWIN64 \
  ")
endif()
