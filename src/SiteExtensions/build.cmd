@ECHO OFF
SET RepoRoot=%~dp0..\..

ECHO Building Microsoft.AspNetCore.Runtime.SiteExtension
CALL %RepoRoot%\build.cmd -arch x64 -projects %~dp0Runtime\Microsoft.AspNetCore.Runtime.SiteExtension.pkgproj /bl:artifacts/log/SiteExtensions-Runtime-x64.binlog %*
CALL %RepoRoot%\build.cmd -arch x86 -projects %~dp0Runtime\Microsoft.AspNetCore.Runtime.SiteExtension.pkgproj /bl:artifacts/log/SiteExtensions-Runtime-x86.binlog %*

IF %ERRORLEVEL% NEQ 0 (
   EXIT /b %ErrorLevel%
)

ECHO Building Dependencies
REM The Site Extension needs the hosting startup assembly to be built and packaged (the CI does this)
REM We don't need to build a specific arch because this is just managed code. The LoggingBranch build later will handle generating the store (and crossgening)
REM We need the packages *specifically* which is why the standard MSBuild dependency doesn't work.
CALL %RepoRoot%\build.cmd -pack -projects %RepoRoot%src\Azure\AzureAppServicesIntegration\src\Microsoft.AspNetCore.AzureAppServicesIntegration.csproj
CALL %RepoRoot%\build.cmd -pack -projects %RepoRoot%src\Azure\AzureAppServices.HostingStartup\src\Microsoft.AspNetCore.AzureAppServices.HostingStartup.csproj

ECHO Building LoggingBranch
REM /p:DisableTransitiveFrameworkReferences=true is needed to prevent SDK from picking up transitive references to Microsoft.AspNetCore.App as framework references https://github.com/dotnet/sdk/pull/3221
CALL %RepoRoot%\build.cmd -forceCoreMsbuild -arch x64 -pack -projects %~dp0LoggingBranch\LB.csproj /p:DisableTransitiveFrameworkReferences=true /bl:artifacts/log/SiteExtensions-LoggingBranch-x64.binlog %*
CALL %RepoRoot%\build.cmd -forceCoreMsbuild -arch x86 -pack -projects %~dp0LoggingBranch\LB.csproj /p:DisableTransitiveFrameworkReferences=true /bl:artifacts/log/SiteExtensions-LoggingBranch-x86.binlog %*

IF %ERRORLEVEL% NEQ 0 (
   EXIT /b %ErrorLevel%
)

ECHO Building Microsoft.AspNetCore.AzureAppServices.SiteExtension
CALL %RepoRoot%\build.cmd -forceCoreMsbuild -projects %~dp0LoggingAggregate\src\Microsoft.AspNetCore.AzureAppServices.SiteExtension\Microsoft.AspNetCore.AzureAppServices.SiteExtension.csproj /bl:artifacts/log/SiteExtensions-LoggingAggregate.binlog %*

IF %ERRORLEVEL% NEQ 0 (
   EXIT /b %ErrorLevel%
)

ECHO SiteExtensions successfully built!
