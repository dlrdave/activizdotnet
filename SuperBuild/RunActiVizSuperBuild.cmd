@rem #########################################################################
@rem   Assumptions:
@rem   - it's ok to blow away "%build_dir%" and start fresh
@rem   - you put the source tree in "%root_dir%\%source_dir%" at the right
@rem       commit manually before running this batch file
@rem   - hard-coded paths on this machine are ok: this script is short &
@rem       sweet, and others who want to use it can edit the file before use
@rem   - CMake 2.8.6 or later is the installed CMake
@rem   - msys git 1.7.3 or later is the installed git
@rem   - this should eventually be converted to use a ctest -S dashboard
@rem       script and submitted to a useful CDash server
@rem #########################################################################

@echo off
setlocal

rem   Grandparent directory of this SuperBuild dir is the default root_dir,
rem   but you can override that by setting AVSB_ROOT_DIR in the environment
rem   prior to invoking this script:

if "%AVSB_ROOT_DIR%" equ "" (
  for /f "usebackq delims=" %%d in (`echo %~dp0..\..`) do set root_dir=%%~fd
) else (
  set root_dir=%AVSB_ROOT_DIR%
)

if not exist "%root_dir%" (
  echo.
  echo.  WARNING: "%root_dir%" does not exist
  echo.
)

set build_dir=bld\avsb
set cmake_bin_dir=C:\Program Files (x86)\CMake 2.8\bin
set cmake_exe=%cmake_bin_dir%\cmake.exe
set ctest_exe=%cmake_bin_dir%\ctest.exe
set generator=Visual Studio 9 2008
set git_bin_dir=C:\Program Files (x86)\Git\bin
set git_exe=%git_bin_dir%\git.exe
set key_file=%AVSB_SNKEYFILE%
set source_dir=activizdotnet
set tail_exe=%git_bin_dir%\tail.exe

if not exist "%cmake_exe%" (
  echo.
  echo.  WARNING: cmake not found at "%cmake_exe%"
  echo.
)

if not exist "%git_exe%" (
  echo.
  echo.  WARNING: git not found at "%git_exe%"
  echo.
)

if not exist "%root_dir%\%source_dir%" (
  echo.
  echo.  WARNING: source directory not found at "%root_dir%\%source_dir%"
  echo.
)

echo.
echo Starting build in "%build_dir%"... - %DATE% %TIME%
if "%key_file%" equ "" (
  echo.
  echo.  WARNING: Environment variable AVSB_SNKEYFILE is empty!
  echo.  Set it to the full path of a strong name signing key file or
  echo.  the mummy and ActiViz builds will not be strong name signed...
  echo.
)
pushd "%root_dir%"

echo.
echo Removing old build... - %DATE% %TIME%
rmdir /q /s "%build_dir%"
mkdir "%build_dir%"

echo.
echo Recording source state... - %DATE% %TIME%
pushd "%root_dir%\%source_dir%"
"%git_exe%" status > "%root_dir%\%build_dir%\avgit.log"
echo.>> "%root_dir%\%build_dir%\avgit.log"
echo # At>> "%root_dir%\%build_dir%\avgit.log"
"%git_exe%" log -1 >> "%root_dir%\%build_dir%\avgit.log"
echo.>> "%root_dir%\%build_dir%\avgit.log"
echo # Described as>> "%root_dir%\%build_dir%\avgit.log"
"%git_exe%" describe --tags >> "%root_dir%\%build_dir%\avgit.log"
echo.
type "%root_dir%\%build_dir%\avgit.log"
popd

echo.
echo Configuring... - %DATE% %TIME%
pushd "%root_dir%\%build_dir%"
echo.
"%cmake_exe%" "-DAVSB_SNKEYFILE=%key_file%" -G "%generator%" ^
  "%root_dir%\%source_dir%\SuperBuild" ^
  > "%root_dir%\%build_dir%\avconfigure.log" 2>&1
set AVSB_SNKEYFILE=
set key_file=
type "%root_dir%\%build_dir%\avconfigure.log"

echo.
echo Building... - %DATE% %TIME%
echo   ...monitor progress in avbuild.log
echo avbuild.log: > "%root_dir%\%build_dir%\avbuild.log"
start "avbuild.log" /D "%root_dir%\%build_dir%" "%tail_exe%" -f avbuild.log
"%cmake_exe%" ^
  --build . --config Release >> "%root_dir%\%build_dir%\avbuild.log" 2>&1

echo.
echo Testing... - %DATE% %TIME%
echo   ...monitor progress in avtest.log
echo avtest.log: > "%root_dir%\%build_dir%\avtest.log"
start "avtest.log" /D "%root_dir%\%build_dir%" "%tail_exe%" -f avtest.log
"%ctest_exe%" -C Release --output-on-failure ^
  >> "%root_dir%\%build_dir%\avtest.log" 2>&1
popd

echo.
echo Done - %DATE% %TIME%
popd

endlocal
