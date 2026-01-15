@REM ----------------------------------------------------------------------------
@REM Licensed to the Apache Software Foundation (ASF) under one
@REM or more contributor license agreements.  See the NOTICE file
@REM distributed with this work for additional information
@REM regarding copyright ownership.  The ASF licenses this file
@REM to you under the Apache License, Version 2.0 (the
@REM "License"); you may not use this file except in compliance
@REM with the License.  You may obtain a copy of the License at
@REM
@REM    http://www.apache.org/licenses/LICENSE-2.0
@REM
@REM Unless required by applicable law or agreed to in writing,
@REM software distributed under the License is distributed on an
@REM "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
@REM KIND, either express or implied.  See the License for the
@REM specific language governing permissions and limitations
@REM under the License.
@REM ----------------------------------------------------------------------------

@REM ----------------------------------------------------------------------------
@REM Maven Start Up Batch script
@REM
@REM Required ENV vars:
@REM JAVA_HOME - location of a JDK home dir
@REM
@REM Optional ENV vars
@REM MAVEN_BATCH_ECHO - set to 'on' to enable the echoing of the batch commands
@REM MAVEN_BATCH_PAUSE - set to 'on' to wait for a key stroke before ending
@REM MAVEN_OPTS - parameters passed to the Java VM when running Maven
@REM     e.g. to debug Maven itself, use
@REM set MAVEN_OPTS=-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=8000
@REM MAVEN_SKIP_RC - flag to disable loading of mavenrc files
@REM ----------------------------------------------------------------------------

@IF "%MAVEN_BATCH_ECHO%" == "on"  echo %MAVEN_BATCH_ECHO%

@setlocal

@set ERROR_CODE=0

@REM To isolate internal variables from possible pre-existing env vars, reset them to empty
@set MAVEN_MAIN_CLASS=
@set MAVEN_JAR=
@set MAVEN_BASEDIR=
@set MAVEN_COMMAND_LINE_ARGS=

@REM ==== START VALIDATION ====
@if not "%JAVA_HOME%" == "" goto OkJHome

@echo.
@echo Error: JAVA_HOME is set to an invalid directory.
@echo JAVA_HOME = "%JAVA_HOME%"
@echo Please set the JAVA_HOME variable in your environment to match the
@echo location of your Java installation.
@goto error

:OkJHome
@if exist "%JAVA_HOME%\bin\java.exe" goto init

@echo.
@echo Error: JAVA_HOME is set to an invalid directory.
@echo JAVA_HOME = "%JAVA_HOME%"
@echo Please set the JAVA_HOME variable in your environment to match the
@echo location of your Java installation.
@goto error

:init

@REM Find the project base dir, i.e. the directory that contains the folder ".mvn".
@REM Fallback to current working directory if not found.

@set MAVEN_BASEDIR=%~dp0
:findBaseDir
@if exist "%MAVEN_BASEDIR%\.mvn" goto baseDirFound
@set "MAVEN_BASEDIR=%MAVEN_BASEDIR%..\"
@if "%MAVEN_BASEDIR%" == "..\" goto baseDirNotFound
@goto findBaseDir

:baseDirNotFound
@set MAVEN_BASEDIR=%cd%

:baseDirFound

@set MAVEN_JAR="%MAVEN_BASEDIR%\.mvn\wrapper\maven-wrapper.jar"
@set MAVEN_MAIN_CLASS=org.apache.maven.wrapper.MavenWrapperMain

@REM Extension to allow automatically downloading the maven-wrapper.jar from the server
@set WRAPPER_PROPERTIES="%MAVEN_BASEDIR%\.mvn\wrapper\maven-wrapper.properties"

@if exist %MAVEN_JAR% goto run

@echo .mvn/wrapper/maven-wrapper.jar not found, downloading it...

@set WRAPPER_URL=
@for /f "tokens=2 delims==" %%i in ('findstr /i "wrapperUrl" %WRAPPER_PROPERTIES%') do @set WRAPPER_URL=%%i

@if "%WRAPPER_URL%" == "" (
    @echo Error: Could not find wrapperUrl in %WRAPPER_PROPERTIES%
    @goto error
)

@set DOWNLOAD_COMMAND=powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object Net.WebClient).DownloadFile('%WRAPPER_URL%', '%MAVEN_JAR%')}"
@%DOWNLOAD_COMMAND%

@if not exist %MAVEN_JAR% (
    @echo Error: Could not download %MAVEN_JAR%
    @goto error
)

:run
@set MAVEN_COMMAND_LINE_ARGS=%*

@"%JAVA_HOME%\bin\java.exe" %MAVEN_OPTS% "-Dmaven.multiModuleProjectDirectory=%MAVEN_BASEDIR%." -classpath %MAVEN_JAR% %MAVEN_MAIN_CLASS% %MAVEN_COMMAND_LINE_ARGS%
@if  ERRORLEVEL 1 goto error
@goto end

:error
@set ERROR_CODE=1

:end
@exit /B %ERROR_CODE%
