# Script to increment the version number of a specified solution in a particular environment
param(
    $serverURL,
    $username,
    $password,
    $clientId,
    $clientSecret,
    $solutionUniqueName,
    [bool]$incrementBuild,
    [bool]$incrementRevision,
    $startingFilePath = ".\Build\Scripts" # Default path to the script location, modify if necessary
)
$ErrorActionPreference = 'Stop'
try{
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
}
catch {
    Write-Host $_
}

Install-Module Rnwood.Dataverse.Data.PowerShell -Scope CurrentUser -Force -AllowClobber -RequiredVersion 1.1.3 -Verbose -Repository "PSGallery"
Import-Module -Name Rnwood.Dataverse.Data.PowerShell -Verbose

$connection = $null
if ($null -ne $username -and $null -ne $password){
    Write-Host "Connecting to Dataverse environment at" $serverURL "using Username" $username
    $connection = Get-DataverseConnection -Url $serverURL -Username $username -Password $password
}
elseif ($null -ne $clientId -and $null -ne $clientSecret){
    Write-Host "Connecting to Dataverse environment at" $serverURL "using ClientId" $clientId
    $connection = Get-DataverseConnection -Url $serverURL -ClientId $clientId -ClientSecret $clientSecret
}
else{
    throw "Invalid combination of credentials specified"
}
Write-Host "Successfully connected to Dataverse"
Write-Host "Retrieving current version of" $solutionUniqueName "solution"
$columns = "solutionid", "uniquename", "friendlyname", "version" 
$solution = Get-DataverseRecord -Connection $connection -TableName "solution" -FilterValues @{uniquename="$solutionUniqueName"} -Columns $columns

$solutionRecord = $solution
$currentVersion = $solutionRecord.version

Write-Host "Current Version: " $currentVersion

$currentLocation = Get-Location
Write-Host "Current Directory: " $currentLocation
if (!$currentLocation.Path.EndsWith("Scripts")){
    Write-Host "Changing Directory"
    Set-Location -Path $startingFilePath
    $currentLocation = Get-Location
    Write-Host "Current Directory: " $currentLocation
}

$versionComponents = $currentVersion.Split(".")
Write-Host "Current Major: " $versionComponents[0]
Write-Host "Current Minor: " $versionComponents[1]
Write-Host "Current Build: " $versionComponents[2]
Write-Host "Current Revision: " $versionComponents[3]

$newMajor = "1"
$newMinor = "0"
$newbuild = "0"
$newRevision = "0"

if (Test-Path -LiteralPath "../Solutions/$solutionUniqueName/Other/Solution.xml"){ # Modify the path as necessary depending on where in the repository the unpacked solution is located
    $solutionXml = [xml](Get-Content -LiteralPath "../Solutions/$solutionUniqueName/Other/Solution.xml") # Modify the path as necessary depending on where in the repository the unpacked solution is located
    $latestVersion = $solutionXml.ImportExportXml.SolutionManifest.Version

    Write-Host "Latest Version: " $latestVersion
    $latestVersionComponents = $latestVersion.Split(".")

    Write-Host "Latest Major: " $latestVersionComponents[0]
    Write-Host "Latest Minor:" $latestVersionComponents[1]
    Write-Host "Latest Build: " $latestVersionComponents[2]
    Write-Host "Latest Revision" $latestVersionComponents[3]
    $newMajor = $versionComponents[0]
    $newMinor = $versionComponents[1]
    if ($incrementBuild -eq $true){
        if (($latestVersionComponents[0] -ne $versionComponents[0]) -or ($latestVersionComponents[1] -ne $versionComponents[1]))
        {
            $newBuild = "0"
        }
        else{
            $newBuild = [string](([int]$latestVersionComponents[2]) + 1)
        }
        
        $newRevision = "0"
    }
    elseif ($incrementRevision -eq $true){
        $newBuild = $latestVersionComponents[2]
        $newRevision = [string](([int]$latestVersionComponents[3]) + 1)
    }
    
}

$fullVersion = $newMajor + "." + $newMinor + "." + $newBuild + "." + $newRevision

Write-Host "New Major: " $newMajor
Write-Host "New Minor: " $newMinor
Write-Host "New Build: " $newBuild
Write-Host "New Revision: " $newRevision
Write-Host "New Version: " $fullVersion

Write-Host "##vso[task.setvariable variable=newSolutionVersion]$fullVersion"