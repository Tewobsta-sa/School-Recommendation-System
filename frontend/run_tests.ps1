#!/usr/bin/env pwsh
<#
Run all Flutter tests for the frontend package.
Usage: .\run_tests.ps1
#>
Param()

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location (Join-Path $scriptDir)
Write-Host "Running flutter tests in frontend/..."
flutter test
