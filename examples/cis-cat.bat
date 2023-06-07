@echo off

set OpenResult=1
if [%1]==[] set OpenResult=0

set LocalPath=C:\CIS-CAT
set NetworkShare=\\smbserver\CIS
set BenchmarkCustomFile=Example_Org_Inc_tailored_-_Microsoft_Windows_10_Stand-alone_v1.0.1_0.1-xccdf.xml
set BenchmarkProfile=xccdf_org.cisecurity.benchmarks_profile_Level_1_L1_-_CorporateEnterprise_Environment_general_use
set CCPDUrl=http://ciscat.example.org/CCPD/api/reports/upload
set CCPDToken=abcdefghijklmnopqrstuvwxxyz12345

set CurrentTime=%TIME: =0%-%DATE: =-%
set CurrentTime=%CurrentTime::=-%
set CurrentTime=%CurrentTime:.=-%
set CurrentTime=%CurrentTime:/=-%

echo Started: %CurrentTime% %COMPUTERNAME%

if NOT exist %LocalPath% ( mkdir %LocalPath% && echo Directory '%LocalPath%' created )
if NOT exist %LocalPath%\temp ( mkdir %LocalPath%\temp && echo Directory '%LocalPath%\temp' created )
if NOT exist %LocalPath%\sess ( mkdir %LocalPath%\sess && echo Directory '%LocalPath%\sess' created )

set LogFile=%LocalPath%\temp\cis-cat-log-%CurrentTime%.log

echo LogFile: %LogFile%
echo Started: %CurrentTime% %COMPUTERNAME% >> %LogFile%

pushd .
for /f "tokens=2" %%i IN ('net use ^| findstr /c:"%NetworkShare%"') do set Drive=%%i
pushd %Drive%
if NOT %ERRORLEVEL% == 0 goto ERROR_PUSHD_DRIVE
popd

:: The %ProgramW6432% environment variable is only set on 64-bit systems.
echo %ProgramW6432% | findstr /C:"Program Files" > nul 2> nul
if %ERRORLEVEL% == 0 set JavaPath=%Drive%\Java64\jre\bin
if %ERRORLEVEL% == 1 set JavaPath=%Drive%\Java\jre\bin

set AssessorPath=%Drive%\Assessor
set AssessorJarFile="%AssessorPath%\Assessor-CLI.jar"
set BenchmarkFile="%AssessorPath%\benchmarks\%BenchmarkCustomFile%"
set PropertiesFile="%AssessorPath%\config\sessions.properties"

if NOT EXIST %JavaPath%\java.exe goto ERROR_JAVA_EXE_FILE
if NOT EXIST %AssessorJarFile%   goto ERROR_ASSESSOR_JAR_FILE
if NOT EXIST %BenchmarkFile%     goto ERROR_BENCHMARK_FILE
if NOT EXIST %PropertiesFile%    goto ERROR_PROPERTIES_FILE

echo NetworkShare: %NetworkShare% >> %LogFile%
echo Drive: %Drive% >> %LogFile%
echo JavaPath: %JavaPath% >> %LogFile%
echo AssessorJarFile: %AssessorJarFile% >> %LogFile%
echo BenchmarkFile: %BenchmarkFile% >> %LogFile%
echo PropertiesFile: %PropertiesFile% >> %LogFile%
echo BenchmarkProfile: %BenchmarkProfile% >> %LogFile%
echo CCPDUrl: %CCPDUrl% >> %LogFile%
echo CCPDToken: %CCPDToken% >> %LogFile%

set CommandToRun=%JavaPath%\java.exe -Xmx2048M -jar %AssessorJarFile% -ui -html -rd %LocalPath% -b %BenchmarkFile% -u %CCPDUrl% -D ciscat.post.parameter.ccpd.token=%CCPDToken% -p %BenchmarkProfile% -sessions %PropertiesFile%

echo CommandToRun: %CommandToRun%
echo CommandToRun: %CommandToRun% >> %LogFile%

del /q /f %LocalPath%\*.html > nul 2> nul
del /q /f %LocalPath%\*.xml > nul 2> nul
del /q /f %LocalPath%\*.log > nul 2> nul
%CommandToRun% >> %LogFile% 2>&1

net use %Drive% /delete > nul
popd

for %%F in (%LocalPath%\*.html) do (
        set HtmlReportFile=%%F
	copy /y %%F %LocalPath%\temp\ > nul
	goto BREAK_COPY
)
:BREAK_COPY

echo Finished: %CurrentTime% %COMPUTERNAME%
echo Finished: %CurrentTime% %COMPUTERNAME% >> %LogFile%

copy /y %LogFile% %LocalPath%\ > nul

for /f "tokens=1" %%i IN ('dir /a:-d /s /b %LocalPath%\temp ^| find /c ":"') do set Count=%%i
if %Count% GEQ 22 del /q /f %LocalPath%\temp\*.* > nul

if %OpenResult% == 1 start "" %HtmlReportFile%
if %OpenResult% == 1 pause

exit

:ERROR_PUSHD_DRIVE
echo Critical Error: Unable to use share (%NetworkShare%) as drive (%Drive%)
echo ERROR_PUSHD_DRIVE >> %LogFile%
goto EXIT_SCRIPT

:ERROR_JAVA_EXE_FILE
echo Critical Error: Java bin can not be found (%JavaPath%\java.exe)
echo ERROR_JAVA_EXE_FILE >> %LogFile%
goto EXIT_SCRIPT

:ERROR_ASSESSOR_JAR_FILE
echo Critical Error: Assessor 'jar' file can not be found (%AssessorJarFile%)
echo ERROR_ASSESSOR_JAR_FILE >> %LogFile%
goto EXIT_SCRIPT

:ERROR_BENCHMARK_FILE
echo Critical Error: Benchmark file can not be found (%BenchmarkFile%)
echo ERROR_BENCHMARK_FILE >> %LogFile%
goto EXIT_SCRIPT

:ERROR_PROPERTIES_FILE
echo Critical Error: Properties file can not be found (%PropertiesFile%)
echo ERROR_PROPERTIES_FILE >> %LogFile%

:EXIT_SCRIPT
net use %Drive% /delete > nul
popd
