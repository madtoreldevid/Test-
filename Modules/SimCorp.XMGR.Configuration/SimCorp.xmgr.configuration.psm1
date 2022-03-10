Write-Host "Loading module: SimCorp.XMGR.Configuration" -ForegroundColor green

<#============================================= Classes ==============================================#>
#region

Class Package {
    [System.Collections.ArrayList]$Entities

    Package () {
        $this.Entities = New-Object System.Collections.ArrayList
    }

    removeTypesWithNoKeys() {
        $tosave = New-Object System.Collections.ArrayList
        foreach ($entity in $this.Entities) {
            if ([string]::IsNullOrEmpty($entity.Keys) -eq $False) {
                $null = $tosave.Add($entity)
            }
        }

        $this.Entities = $tosave
    }

}

Class TypeDef {
    [String] $Type
    [Collections.Generic.List[String]] $Keys

    TypeDef ([String] $Type, [Collections.Generic.List[String]] $Keys) {
        $this.Type = $Type
        $this.Keys = $Keys
    }

    removeAllKeys() {
        $this.Keys = $null
    }

    setKeys ([Collections.Generic.List[String]] $Keys) {
        $this.Keys = $Keys
    }

}

#endregion



<#============================================= Package Definition ===================================#>
#region

<#
.Synopsis

 Lists all the Configuration Types available for export on specified installation

INPUTS: InstallationID

OUTPUTS: A list of Configuration Types with details

#>
function Get-XMGRConfigTypes {
    param(
        [Parameter(Mandatory = $true)]
        [String] $InstallationId
    )
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $x = get-xmgrinstallation $InstallationId
    if ($x[-1] -eq 1) {
        if ($x[-3].length -gt 0) { Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $x[-3] }
        if ($x[-2].length -gt 0) { Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $x[-2] }

        $global:SimCorpXMGR.errorReturnValue
    }
    else {
        $Endpoint = "/api/odata/installations"
        $uri = $Endpoint + "('$InstallationId')" + "/ConfigurationTypes"
        $request = Connect-XMGRApiCall $uri "GET"
        if ($request[-1] -eq 1) {
            $global:SimCorpXMGR.errorReturnValue
            if ($request[-3].length -gt 0) {
                $request[-3]
                Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
            }
            if ($request[-2].length -gt 0) {
                $request[-2]
                Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
            }
        }
        else {
            $configTypes = $request.value
            $configTypes
        }
    }
}

<#
.Synopsis

    Lists all the Keys for a specified Type (=Entities) on a given installation

INPUTS: InstallationId and a list of Configuration Types

OUTPUTS: A list of all exportable entities of a given type from a specified installation

#>
function Get-XMGRInstancesOfConfigType {
    param(
        [Parameter(Mandatory = $true)]
        [String] $InstallationId,
        [Parameter(Mandatory = $true)]
        [String] $ConfigurationType
    )
    $Endpoint = "/api/odata/installations"
    $uri = $Endpoint + "('$InstallationId')" + "/ConfigurationTypes" + "('$ConfigurationType')" + "/Entities"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCall $uri "GET"
    if ($request[-1] -eq 1) {
        $global:SimCorpXMGR.errorReturnValue
        if ($request[-3].length -gt 0) {
            $request[-3]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
        }
        if ($request[-2].length -gt 0) {
            $request[-2]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
        }
    }
    else {
        $instancesOfConfigType = $request.value
        $instancesOfConfigType
    }
}

<#
.Synopsis

    Lists all available package definitions along their basic details. Allows to filter by 'CreatedBy" and "PackageDefinitionName" and "Project" using wildcards ('?' and '*')
    Example: Get-PackageDefinitions -PackageDefinitionName test* -CreatedBy GS\*    - will get all packagedefinitions with names startign with "test" and created by users from GS domain.

INPUTS: Optional:
        - CreatedBy - ADName of the PackageDefinition creator
        - PackageDefinitionName - part of the package definition name combined with wildcards
        - Project - a project the definition belongs to
        - Info  - package definition description


OUTPUTS: A list of all existing package definitions or these that match the filtering criteria.

#>
function Get-XMGRPackageDefinitions {
    param(
        [Parameter(Mandatory = $false)]
        [String]$PackageDefinitionName,
        [Parameter(Mandatory = $false)]
        [String]$CreatedBy,
        [Parameter(Mandatory = $false)]
        [String] $Project,
        [Parameter(Mandatory = $false)]
        [String] $Info
    )


    $Endpoint = "/api/odata/PackageDefinitions"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCall $Endpoint "GET"
    if ($request[-1] -eq 1) {
        $global:SimCorpXMGR.errorReturnValue
        if ($request[-3].length -gt 0) {
            $request[-3]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
        }
        if ($request[-2].length -gt 0) {
            $request[-2]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
        }
    }
    else {
        $packageDefinitions = $request.value

        $name = "*"
        $creator = "*"
        $projectFilter = "*"
        $infoFilter = "*"

        if (![string]::IsNullOrEmpty($PackageDefinitionName)) { $name = $PackageDefinitionName }
        if (![string]::IsNullOrEmpty($CreatedBy)) { $creator = $CreatedBy }
        if (![string]::IsNullOrEmpty($Project)) { $projectFilter = $Project }
        if (![string]::IsNullOrEmpty($Info)) { $infoFilter = $info }

        return $packageDefinitions | Where-Object { $_.CreatedBy -like $creator -and $_.Name -like $name -and $_.Info.Project -like $projectFilter -and $_.Info.Info -like $infoFilter }
    }
}

<#
.Synopsis

    Displays the specific package definition with details

INPUTS: name of the package definition

OUTPUTS: Details of the package definition, including a list of all the entities inside

#>
function Get-XMGRPackageDefinition {
    param(
        [Parameter(Mandatory = $true)]
        [String] $PackageDefinitionName
    )
    $Endpoint = "/api/odata/PackageDefinitions"
    $uri = $Endpoint + "('$PackageDefinitionName')"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCall $uri "GET"
    if ($request[-1] -eq 1) {
        $global:SimCorpXMGR.errorReturnValue
        if ($request[-3].length -gt 0) {
            $request[-3]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
        }
        if ($request[-2].length -gt 0) {
            $request[-2]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
        }
    }
    else {
        $packageDefinition = $request
        $packageDefinition
        Write-Output "Entities:"
        $packageDefinition.Entities | ConvertTo-Json

    }
}

<#
.Synopsis

    Function creates an XMGR package definition. It does perform a validation of the configuration types that are passed-in. It can be set to include the dependencies of the objects passed-in.
    By default, it does allow for using wildcards: "?" for single character and "*" for multiple characters. If you want to specify items containig these characters set the switch "EvaluateWildcardValidateKeys" to False.

INPUTS:

        Mandatory:
                - Package Definition Name (has to be unique)
                - InstallationId - needs to have all the Configuration Types that are being included in the definition
                - a list of Entities (objects). A list of lists, where each list consists of a configuration type followed by one or multiple keys.
                    Example : (("CURRENCY", "USD", "EUR", "CZK"),("BATCHJOBGRPS", "WMBATCH"))
                - "PackageDefinitionInfo" - description of the package definition
                - Project - information to which development process does the definition belong to (used for organisational and filtering purposes)
        Optional:
                - "AddDependencies" - a switch, if set to "YES" it will perform a "join-xmgrdependencies" function on each entity and add the results to the package definition.
                - "EvaluateWildcardValidateKeys" - by default "?" and "*" are evauluated. Setting to False deactivates it.


OUTPUTS: Details of the created package definition, any errors in the process and a list of all entities included

#>
function Add-XMGRPackageDefinition {
    param(
        [Parameter(Mandatory = $true)]
        [String] $PackageDefinitionName,
        [Parameter(Mandatory = $false)]
        [String] $InstallationId,
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Entities,
        [Parameter(Mandatory = $true)]
        [String] $PackageDefinitionInfo,
        [Parameter(Mandatory = $true)]
        [String] $Project,
        [Parameter(Mandatory = $false)]
        [ValidateSet($TRUE, $FALSE)]
        $AddDependencies = $False,
        [ValidateSet($TRUE, $FALSE)]
        $EvaluateWildcardValidateKeys = $True
    )


    if ($EvaluateWildcardValidateKeys -eq $True) {
        if ([STRING]::IsNullOrEmpty($InstallationId)) {
            Write-Output "Provide an InstallationId, if you want to validate Types and evaluate wildcards."
            1
            break
        }
    }

    if ($EvaluateWildcardValidateKeys -eq $false) {
        $AddDependencies = $false
    }


    $PackageObject = New-Object Package
    $Types = New-Object System.Collections.ArrayList


    <#The usual input for Entities should be an arraylist of lists. However, if an arraylist with single list is passed in (a single Entity), it gets autocasted into a list of strings, which causes an error. The below codeblock handles this case:#>
    if ($Entities[0].GetType().Name -eq "String") {
        [String]$Type = $Entities[0]
        $null = $Types.add($Type)
        [System.Collections.ArrayList]$Keys = $Entities.Clone()

        $Keys.Remove($Type)
        if ($keys.Count -lt 1) {
            throw "$Type. A Type and at least one Key is required"
        }

        <#If 2+ Keys were available in $Keys they were recasted to a single string further on. This is a workaround#>
        $keyList = New-Object Collections.Generic.List[String]
        foreach ($key in $Keys) {
            $null = $keyList.Add($key)
        }

        $TypeDefinition = New-Object TypeDef ($Type, $keyList)
        $null = $PackageObject.Entities.add($TypeDefinition)

    }

    else {
        <#if multiple lists were passed in Entities:#>

        foreach ($ent in $Entities) {
            [String]$Type = $ent[0]
            $null = $Types.add($Type)
            [Collections.Generic.List[String]]$Keys = $ent.clone()
            if ($keys.Count -lt 1) {
                throw "$Type. A Type and at least one Key is required"
            }
            $null = $Keys.remove($Type)
            $keyList = New-Object Collections.Generic.List[String]
            foreach ($key in $keys) { $null = $keylist.add($key) }
            $TypeDefinition = New-Object TypeDef ($Type, $keyList)
            $null = $PackageObject.Entities.add($TypeDefinition)
        }

    }




    <#============================================Optionally, evaluate wildcards and check types against a specific installation =========================================#>
    if ($EvaluateWildcardValidateKeys -eq $True) {
        <#Validation if Types that were passed-in exist on specific installation.If not, display which ones and it ends the process#>
        $request = internalValidateConfigTypes $InstallationId $Types
        if ($request[-1] -eq 1) {
            $global:SimCorpXMGR.errorReturnValue
            if ($request[-3].length -gt 0) {
                $request[-3]
                Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
            }
            if ($request[-2].length -gt 0) {
                $request[-2]
                Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
            }
            break
        }
        $configTypes = internaladdentitiesFromWildCards $PackageObject $InstallationId
        if ($configTypes[-1] -eq 1) {
            Write-Output "Warnings:"
            $configTypes[-2]
            Return "Found no valid TYPE-KEY pairs on this installation. Check your spelling and/or wildcards usage or use a different installation"
        }
        if ($configTypes[-2] -eq 2) {
            Write-Output "Warnings:"
            $configTypes[-3]
        }
        $PackageObject = $configTypes[-1]
    }
    <#============================================Optionally, add dependencies=========================================#>
    if ($AddDependencies -eq $True) {
        <#Create a single flat array with all dependencies. Join-XMGRdependencies API returns also original entities#>
        $allDependencies = New-Object System.Collections.ArrayList

        foreach ($ent in $PackageObject.entities) {
            $dependencies = Join-XMGRDependencies -InstallationId $InstallationId -Type $ent.type -Keys $ent.keys
            if ($dependencies[-1] -eq 1) {
                Write-Output "Dependencies error by TYPE:" $ent.type
                throw $dependencies[-2]
            }
            else {

                $dependencies = $dependencies[-1] | ConvertFrom-Json
                foreach ($item in $dependencies) {
                    $null = $allDependencies.add($item)
                }
            }
        }
        <#======================Remove duplicates====================#>
        $dependenciesNoDuplicates = New-Object System.Collections.ArrayList
        <#Get Non duplicated values#>
        $nonDuplicated = $allDependencies | Group-Object -Property "TYPE" | Where-Object { $_.count -eq 1 }
        foreach ($item in $nonduplicated.group) {
            $null = $dependenciesNoDuplicates.Add($item)
        }
        <#Get Duplicated Types#>
        $duplicated = $allDependencies | Group-Object -Property "TYPE" | Where-Object { $_.count -gt 1 }

        foreach ($group in $duplicated) {
            $type = $group.name
            $keys = $group.group.keys | Sort-Object | get-unique
            $TypeDef = New-Object TypeDef ($Type, $keys)
            $null = $dependenciesNoDuplicates.add($TypeDef)
        }
        <#Overwrite the existing objects with: existing objects+dependencies#>
        $PackageObject = New-Object Package

        foreach ($entity in $dependenciesNoDuplicates) {
            $TypeDef = New-Object TypeDef ($entity.type, $entity.keys)
            $null = $PackageObject.Entities.add($TypeDef)
        }


    }


    <#Genereate JSONPayload for the API#>
    $entitiesInJSON = $PackageObject.entities | convertto-json
    $date = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"


    if ($PackageObject.Entities.Count -eq 1) {

        $jsonpayload = @"
{
"Name": "$PackageDefinitionName",
"Info": {"Info" : "$PackageDefinitionInfo", "Created" : "$date", "Project" : "$Project"},
"Entities": [$entitiesInJSON]
}
"@
    }
    else {
        $jsonpayload = @"
{
"Name": "$PackageDefinitionName",
"Info": {"Info" : "$PackageDefinitionInfo", "Created" : "$date", "Project" : "$Project"},
"Entities": $entitiesInJSON
}
"@
    }

    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $Endpoint = "/api/odata/PackageDefinitions"
    $request = Connect-XMGRApiCallPOST $Endpoint $jsonpayload
    if ($request[-1] -eq 1) {
        $global:SimCorpXMGR.errorReturnValue
        if ($request[-3].length -gt 0) {
            $request[-3]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
        }
        if ($request[-2].length -gt 0) {
            $request[-2]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
        }
    }
    else {
        $creationConfirmation = $request
        $creationConfirmation
        Write-Output "Entities: "
        $creationConfirmation.Entities | ConvertTo-Json
    }

}

<#
.Synopsis

    Deletes a specific package definition.

INPUTS: name of the package definition

OUTPUTS: Confirmation if successful, error

#>
function Remove-XMGRPackageDefinition {
    param(
        [Parameter(Mandatory = $true)]
        [String] $PackageDefinitionName
    )

    <#If set-up, specific users can delete only their own package-definitions#>
    $usersEditingOwnPackagesOnly = $global:SimCorpXMGR.usersEditingOwnPackagesOnly
    $user = $Global:SimCorpXMGR.currentUser

    if ($user -in $usersEditingOwnPackagesOnly) {

        $packageDefinitionToDelete = Get-XMGRPackageDefinition $PackageDefinitionName
        $packageDefinitionCreator = $packageDefinitionToDelete.CreatedBy

        if (![STRING]::IsNullOrEmpty($packageDefinitionCreator) -and ($packageDefinitionCreator -ne $user)) {
            Write-Output "You are only allowed to delete Package Definitions created by you."
            break
        }

    }

    $Endpoint = "/api/odata/PackageDefinitions"
    $uri = $Endpoint + "('$PackageDefinitionName')"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCall $uri "DELETE"
    if ($request[-1] -eq 1) {
        $global:SimCorpXMGR.errorReturnValue
        if ($request[-3].length -gt 0) {
            $request[-3]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
        }
        if ($request[-2].length -gt 0) {
            $request[-2]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
        }
    }
    else {
        $deletionConfirmation = $request
        $deletionConfirmation
        Write-Output "Package Definiton $PackageDefinitionName was deleted"
    }
}

<#
.Synopsis

    Internal tooling function. Equivalent of Test-Json from PowerShell 7

INPUTS: String

OUTPUTS: True if String is a valid JSON, False if not.

#>
function internalvalidatejson{
param(
[Parameter(Mandatory = $true)]
[string]$InputString
)


try {
    $powershellRepresentation = ConvertFrom-Json $InputString -ErrorAction Stop;
    $validJson = $true;
} catch {
    $validJson = $false;
}

if ($validJson) {
    $true
} else {
    $false
}
}
<#
.Synopsis

    Function checks if specified Types are available on a specific installation

INPUTS: InstallationID and a list of Configuration Types

OUTPUTS: A list of invalid types, "All Types valid" if all Types are available on the installation.

#>
function internalValidateConfigTypes {
    param(
        [Parameter(Mandatory = $true)]
        [String] $InstallationId,
        [Parameter(Mandatory = $true)]
        [Collections.Generic.List[String]] $ConfigurationItems
    )
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = get-XMGRinstallation $InstallationId
    if ($request[-1] -eq 1) {
        $global:SimCorpXMGR.errorReturnValue
        if ($request[-3].length -gt 0) {
            $request[-3]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
        }
        if ($request[-2].length -gt 0) {
            $request[-2]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
        }
    }
    else {
        $configTypes = Get-XMGRConfigTypes($InstallationId)
        [Collections.Generic.List[String]] $listOfAllTypes = $configTypes.type
        [Collections.Generic.List[String]] $typesToValidate = $ConfigurationItems.clone()


        foreach ($configitem in $ConfigurationItems) {
            foreach ($item in $listOfAllTypes) {
                if ($configitem -eq $item) {
                    $null = $typesToValidate.remove($configitem)
                }
            }

        }
        if ($typesToValidate.Count -cnotmatch 0) {

            write-output "On installation $InstallationId, following types are not available: $typesToValidate"
            return 1
        }
    }
    write-output "All Types valid"
}

<#
.Synopsis

    Internal function, which is responsible for processing wildcard characters in Powershell "-like" Syntax: "?" - single character, "*" - multiple characters

INPUTS: a Package Object with Keys containing wildcard characters

OUTPUTS: Package Object containing Keys resulting from wildcard search - if wildcard search results in Types with no Keys, such Types will be removed.
#>
function internaladdentitiesFromWildCards {
    param(
        [Parameter(Mandatory = $true)]
        [Package]$Package,
        [Parameter(Mandatory = $true)]
        [String] $InstallationId
    )
    $warnings = New-Object Collections.Generic.List[String]

    foreach ($entity in $Package.Entities) {
        $keySet = Get-XMGRInstancesOfConfigType -installationId $InstallationId -ConfigurationType $entity.Type

        <#If the Type is available, but there is zero available Keys - abort#>
        if ($keyset.count -eq 0) {
            $errorMessage = "No matching Keys found for Type " + $entity.Type
            $null = $warnings.Add($errorMessage)
            Write-Output $errorMessage
            $null = $entity.removeAllKeys()
        }
        else {
            <#When 1+ KEYS are available for the TYPE, proceed #>
            $keyset = $keyset.Key
            $matchSet = New-Object Collections.Generic.List[String]
            foreach ($entityKey in $entity.Keys) {
                $matchingKeys = $keyset -like $entityKey
                if ($matchingKeys -eq $true) {
                    # this means that there is only one key found, so only one configuration in the system
                    $null = $matchset.Add($keyset)
                }
                else {
                    foreach ($match in $matchingKeys) { $null = $matchset.Add($match) }
                }

            }
            <#Multiple wildcards can be passed-in, which can result in duplicated KEYS - which need to be removed #>
            $matchSet = $matchSet | Sort-Object | Get-Unique

            <#If no matchingKeys were found matching the pattern, inform the operator#>
            if ([string]::IsNullOrEmpty($matchset)) {
                $errorMessage = "No matching Keys found for Type " + $entity.Type
                $null = $warnings.Add($errorMessage)
                Write-Output $errorMessage
            }

            <#Remove the wildcards passed in as Keys#>
            $null = $entity.removeAllKeys()
            <#Replace them with the results of pattern matching#>
            $null = $entity.setKeys($matchSet)

        }
    }
    <#Remove Types which are left with no KEYS from the Package#>
    $Package.removeTypesWithNoKeys()
    if ($Package.Entities.Count -eq 0) {
        $warnings | ConvertTo-Json
        return 1
    }
    if ($warnings.Count -ge 1) {
        $warnings | ConvertTo-Json
        2
    }

    return $Package
}


<#
.Synopsis

    Internal search and filtering function. Used to retrieve a list of package hashes that match the passed-in criteria. At least one filtering criterium must be passed-in, otherwise functions does not return anything.

INPUTS:
        Optional:
            - all the general filtering is available (see: get-packages)

OUTPUTS: a list of package hashes that matchingKeys the filters passed-in. None if no criteria passed-in
#>
function internalgetfilteredhashes {
    param(
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [Collections.Generic.List[String]] $PackagesWithTags,

        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $PackagesWithHashes,

        [Parameter(Mandatory = $false)]
        [String]$CreatedBy,
        [Parameter(Mandatory = $false)]
        [String]$Version,
        [Parameter(Mandatory = $false)]
        [String] $Project,
        [Parameter(Mandatory = $false)]
        [String] $Info,

        [Parameter(Mandatory = $false)]
        [String] $CreationDateGE,
        [Parameter(Mandatory = $false)]
        [String] $CreationDateLE,

        [Parameter(Mandatory = $false)]
        [ValidateSet("AtLeastOneTagFromList", "AllTagsFromList")]
        [String]$PackagesWithTagsLogic = "AtLeastOneTagFromList",

        [Parameter(Mandatory = $false)]
        [ValidateSet("No", "Outdated", "Broken", "All")]
        [String]$SelectBrokenAndOutdated = "No"

    )

    $hashes = New-Object Collections.Generic.List[String]

    if (![string]::IsNullOrEmpty($Version) -or ![string]::IsNullOrEmpty($CreatedBy) -or ![string]::IsNullOrEmpty($PackagesWithTags) -or ![string]::IsNullOrEmpty($Project) -or ![string]::IsNullOrEmpty($PackagesWithHashes) -or ![string]::IsNullOrEmpty($CreationDateGE) -or ![string]::IsNullOrEmpty($CreationDateLE)) {
        $searchResults = Get-XMGRPackages -PackagesWithTagsLogic $PackagesWithTagsLogic -PackagesWithTags $PackagesWithTags -CreatedBy $CreatedBy `
            -Version $Version -Project $Project -SelectBrokenAndOutdated $SelectBrokenAndOutdated -PackagesWithHashes $PackagesWithHashes -CreationDateGE $CreationDateGE -CreationDateLE $CreationDateLE -Info $Info


        return $searchResults.hash
    }
}

<#
.Synopsis

    List all entities (objects) in a specified package

INPUTS: PackageHash of a single package

OUTPUTS: a list of objects contained in the package in JSON format

#>
function Get-XMGRPackageEntities {
    param(
        [Parameter(Mandatory = $true)]
        [String] $PackageHash
    )
    $Endpoint = "/api/odata/packages('$PackageHash')/PackagesService.ListEntitiesInPackage"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCall $Endpoint "GET"
    if ($request[-1] -eq 1) {
        $global:SimCorpXMGR.errorReturnValue
        if ($request[-3].length -gt 0) {
            $request[-3]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
        }
        if ($request[-2].length -gt 0) {
            $request[-2]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
        }
    }
    else {
        $packageEntities = $request.value
        $uniqueTypes = $packageEntities.type | Sort-Object -Unique

        $sortedEntities = @{}

        foreach ($uniqueType in $uniqueTypes) {
            $keys = New-Object System.Collections.ArrayList
            foreach ($item in $packageEntities) {
                if ($item.type -eq $uniqueType) {
                    $null = $keys.Add($item.key)
                }

            }
            $sortedEntities.Add($uniqueType, $keys)
        }
        return $sortedEntities
    }
}

<#
.Synopsis

    Get details of a specific object in a specific package

INPUTS: Package Hash to identify the package and a Type and Key to identify the object

OUTPUTS: Details of the specific package object

#>
function Get-XMGRPackageObject {
    param(
        [Parameter(Mandatory = $true)]
        [String] $PackageHash,
        [Parameter(Mandatory = $true)]
        [String] $Type,
        [Parameter(Mandatory = $true)]
        [String] $Key
    )
    $Endpoint = "/api/odata/packages('$PackageHash')/PackagesService.ListObjectsInEntity?Key=$Key&Type=$Type"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCall $Endpoint "GET"
    if ($request[-1] -eq 1) {
        $global:SimCorpXMGR.errorReturnValue
        if ($request[-3].length -gt 0) {
            $request[-3]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
        }
        if ($request[-2].length -gt 0) {
            $request[-2]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
        }
    }
    else {
        $packageObject = $request
        $packageObject
    }
}

<#
.Synopsis

   Generates the dependency model for a specific Type and a set of keys (for a single installation).
   In practice, to get the list of dependencies use "Join-XMGRDependencies"

INPUTS: InstallationId, a Type and a list of Keys

OUTPUTS: Dependencies with a dependency model

#>
function Get-XMGRDependencies {
    param(
        [Parameter(Mandatory = $true)]
        [String] $InstallationId,
        [Parameter(Mandatory = $true)]
        [String] $Type,
        [Parameter(Mandatory = $true)]
        [Collections.Generic.List[String]] $Keys
    )

    $keysInJSON = $keys | ConvertTo-Json

    if ($Keys.Count -eq 1) {
        $jsonpayload = @"
{
"From": "$InstallationId",
"Entities":[
{ "Type": "$Type",
  "Keys": [$keysInJSON]
}]
}
"@
    }
    else {
        $jsonpayload = @"
{
"From": "$InstallationId",
"Entities":[
{ "Type": "$Type",
  "Keys": $keysInJSON
}]
}
"@
    }
    $Endpoint = "/api/odata/Operations/Get.Dependencies"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCallPOST $Endpoint $jsonpayload
    if ($request[-1] -eq 1) {
        $global:SimCorpXMGR.errorReturnValue
        if ($request[-3].length -gt 0) {
            $request[-3]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
        }
        if ($request[-2].length -gt 0) {
            $request[-2]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
        }
    }
    else {
        <#Timeout set for 2 minutes#>
        $counter = 120
        while ($counter -gt 0) {
            $operationDetails = Get-XMGROperationdetails $request.OperationId
            $operationDetails.StatusText
            if ($operationDetails.StatusText -eq "Completed") {
                if ($operationDetails.actions.result.dependencies.LargeObjectId) {
                    $LargeObject = get-xmgrlargeobject $operationDetails.actions.result.dependencies.LargeObjectId
                    if ($LargeObject.NonCyclicDependencyResults) {
                        Write-Output "Non-Cyclic Dependencies:"
                        $LargeObject.NonCyclicDependencyResults
                    }
                    if ($LargeObject.CyclicDependencyResults) {
                        Write-Output "Cyclic Dependencies:"
                        $LargeObject.CyclicDependencyResults
                    }
                    break

                }
                else {
                    $operationDetails.actions.result.dependencies
                    break
                }
                if ($operationDetails.StatusText -eq "Failed") {
                    $operationDetails.actions.error
                    1
                    break
                }
            }
            start-Sleep -s 1
            $counter = $counter - 1
        }
    }
}

<#
.Synopsis

    Creates a package(=export) from a specific installation (installationId). Package can be created either from a predefined package definition (PackageDefinitionName) or by directly providing a list of objects (Entities).
    If PackageDefinitionName is passed-in, other inputs like Entities and AddDependencies will not be evaluated.
    Some descriptive information is required(PackageInfo and at least one Tag). By default, when inputing Entities, one can use "?" and "*" wildcards in KEYS to get multiple objects at once.
    Passing-in "EvaluateWildcards=$False" deactivates the wildcards - used when exporting objects containing wildcard characters in their KEYS.

INPUTS: Mandatory:
        InstallationId - installation from which are we exporting PackageDefinitionName and PackageInfo are mandatory, a list of Tags is optional
        PackageInfo - some description is required
        Tags - a list of Tags, at least one is required

        Optional:
        PackageDefinitionName - when we want to use predefined definiton
        Entities - when we want to input the entities directly - a nested list, where the first string is the TYPE, followed by one or more KEYS.
                   Examples: -Entities ("CURRENCY", "PLN", "EUR") ; -Entities (("CURRENCY,"PLN"), (BATCHJOBGRPS", "BATCHBJOBGROUP1"))
        One has to use one of the above


        EvaluateWildcards - set to false to not evaluate wildcards
        AddDependencies - if "TRUE" it will add dependencies to all Entities that were passed in (dependencies are added after wildcards evaluation)

OUTPUTS: Details of a newly created package, a list of entities included and/or any possible errors - for example when not all objects from a package definiton are avialable on the installation.

#>
function Add-XMGRPackage {
    param(
        [Parameter(Mandatory = $false)]
        [String] $FromPackageDefinition,
        [Parameter(Mandatory = $true)]
        [String] $InstallationId,
        [Parameter(Mandatory = $true)]
        [Collections.Generic.List[String]] $Tags,
        [Parameter(Mandatory = $false)]
        [System.Collections.ArrayList]$Entities,
        [Parameter(Mandatory = $true)]
        [String] $PackageInfo,
        [Parameter(Mandatory = $true)]
        [String] $Version,
        [Parameter(Mandatory = $true)]
        [String] $Project,
        [Parameter(Mandatory = $false)]
        [ValidateSet($TRUE, $FALSE)]
        $AddDependencies = $False,
        [ValidateSet($TRUE, $FALSE)]
        $EvaluateWildcards = $True,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Import", "Skip")]
        [String] $RBAPoliciesAll = "Skip",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Import", "ImportIfPresent", "Skip")]
        [String] $RBAPoliciesGeneral = "Skip",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Import", "ImportIfPresent", "Skip")]
        [String] $RBAPoliciesUser = "Skip"
    )

    <#
.Synopsis

    Internal Function. Creates a package from a package definition by taking data from a specified installation (InstallationId). Packages must include some description (PackageInfo) and might include a list of Tags (at least one is mandatory).

INPUTS: InstallationId, FromPackageDefinition, at least one Tag and PackageInfo are mandatory.

OUTPUTS: Details of a newly created package, a list of entities included and/or any possible errors - for example when not all objects from a package definiton are avialable on the installation.

#>
    function Add-XMGRPackageFromDefinition {
        param(
            [Parameter(Mandatory = $true)]
            [String] $InstallationId,
            [Parameter(Mandatory = $true)]
            [String] $FromPackageDefinition,
            [Parameter(Mandatory = $true)]
            [String] $PackageInfo,
            [Parameter(Mandatory = $true)]
            [String] $Version,
            [Parameter(Mandatory = $true)]
            [String] $Project,
            [Parameter(Mandatory = $true)]
            [Collections.Generic.List[String]] $Tags,

            [Parameter(Mandatory = $false)]
            [ValidateSet("Import", "Skip")]
            [String] $RBAPoliciesAll = "Skip",

            [Parameter(Mandatory = $false)]
            [ValidateSet("Import", "ImportIfPresent", "Skip")]
            [String] $RBAPoliciesGeneral = "Skip",

            [Parameter(Mandatory = $false)]
            [ValidateSet("Import", "ImportIfPresent", "Skip")]
            [String] $RBAPoliciesUser = "Skip"
        )


        if ($PSBoundParameters.ContainsKey("Tags")) {
            if ($Tags.Count -eq 1) {
                $TagsInJSON = $Tags | ConvertTo-Json
                $TagsInJSON = "[$TagsInJSON]"
            }
            else {
                $TagsInJSON = $Tags | ConvertTo-Json
            }
            $tgs = '"PackageTags":' + $TagsInJSON + ","
        }

        $date = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
        $creator = ($global:SimCorpXMGR.currentUser | ConvertTo-Json)

            #To allow for sub-attributes, values need to be checked if they are a simple string or a JSON array. JSON array is without apostrophes.
if(!(internalvalidatejson $Project)){
$Project = '"'+$Project+'"'
}

if(!(internalvalidatejson $PackageInfo)){
$PackageInfo = '"'+$PackageInfo+'"'
}

if(!(internalvalidatejson $Version)){
$version = '"'+$Version+'"'
}

        $jsonpayload = @"
{
$tgs
"RbaImportPolicies": {
"All": "$RBAPoliciesAll",
"General": "$RBAPoliciesGeneral",
"User": "$RBAPoliciesUser"
},
"From": "$InstallationId",
"PackageDefinitionName": "$FromPackageDefinition",
"PackageInfo": {"Info" : $PackageInfo, "Version" : $Version, "Created" : "$date", "CreatedBy" : $creator, "Project" : $Project}
}
"@
        $Endpoint = "/api/odata/operations/start.export"
        Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
        $request = Connect-XMGRApiCallPOST $Endpoint $jsonpayload
        if ($request[-1] -eq 1) {
            $global:SimCorpXMGR.errorReturnValue
            if ($request[-3].length -gt 0) {
                $request[-3]
                Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
            }
            if ($request[-2].length -gt 0) {
                $request[-2]
                Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
            }
        }
        else {
            <#It takes some time for the operation to complete. The script checks every 1 second#>
            $counter = 600
            while ($counter -gt 0) {

                $operationDetails = Get-XMGROperationdetails $request.OperationId
                $operationDetails.StatusText

                <#If Operation is complete, show result#>
                if ($operationDetails.StatusText -eq "Completed") {
                    $operationDetails.actions
                    <#If Completed but with errors, show the errors#>
                    if ($operationDetails.result.ExportErrorDetails) {
                        $operationDetails.result.ExportErrorDetails
                    }
                    <#Show the entities in the new package#>
                    Write-Output "Package Entities:"
                    Get-XMGRPackageEntities -PackageHash $operationDetails.actions.result.PackageHash | ConvertTo-Json
                    break
                }

                <#If CompletedwithWarnings, show details#>
                if ($operationDetails.StatusText -eq "CompletedWithWarnings") {
                    $operationDetails.actions
                    $operationDetails.actions.warnings
                    <#Show the errors#>
                    if ($operationDetails.actions.result.ExportErrorDetails) {
                        if ($operationDetails.actions.Result.ExportErrorDetails.LargeObjectId) {
                            Get-XMGRLargeObject $operationDetails.actions.Result.ExportErrorDetails.LargeObjectId
                        }
                        else {
                            $operationDetails.actions.result.ExportErrorDetails
                        }
                    }

                    <#Show the entities in the new partially-complete package#>
                    Write-Output "Package Entities:"
                    Get-XMGRPackageEntities -PackageHash $operationDetails.actions.result.PackageHash | ConvertTo-Json
                    break
                }


                <#If package creation failed, show why#>
                if ($operationDetails.StatusText -eq "Failed") {
                    $operationDetails.actions.error
                    1
                    break
                }
                start-Sleep -s 1
                $counter = $counter - 1
            }
        }
    }

    if ($PackageInfo -eq "Package_Definitions") {
        return Write-XMGRLogMessage -LogLevel 1 -LogMessage "'Package_Definitions' is a system reserved value, please use a different one"
    }
    <#Package can be created EITHER from a definiton or directly by listing the Entities - both parameters are optional. Display an error if none or both are provided#>
    if (  (![String]::IsNullOrEmpty($FromPackageDefinition) -and ![String]::IsNullOrEmpty($Entities)) -or ([String]::IsNullOrEmpty($FromPackageDefinition) -and [String]::IsNullOrEmpty($Entities))  ) {
        Write-Output "Provide a PackageDefinitonName OR a list of Entities to create a package from"
        return 1
        break
    }


    <#simplest case - when we want to create a package from a package definiton and not take wildcards into account#>
    if (![String]::IsNullOrEmpty($FromPackageDefinition) -and ($EvaluateWildcards -eq $false)) {
        return Add-XMGRPackageFromDefinition -installationId $InstallationId -FromPackageDefinition $FromPackageDefinition -PackageInfo $PackageInfo -Tags $Tags -Version $Version -Project $Project -RBAPoliciesAll $RBAPoliciesAll -RBAPoliciesGeneral $RBAPoliciesGeneral -RBAPoliciesUser $RBAPoliciesUser

    }

    <#When we want to create a package from a wildcard-containing package definition#>
    if (![String]::IsNullOrEmpty($FromPackageDefinition) -and $EvaluateWildcards -eq $true) {

        $packageDefinition = Get-XMGRPackageDefinition $FromPackageDefinition
        if ($packageDefinition[-1] -eq 1) {
            Write-Output "Package Definition $FromPackageDefinition does not exist"
            1
            break
        }
        $packageDefinition = $packageDefinition[-1] | ConvertFrom-Json
        $Package = New-Object Package
        $Types = New-Object System.Collections.ArrayList

        foreach ($TypeWithKeys in $packageDefinition) {
            $TypeDefinition = New-Object TypeDef ($TypeWithKeys.Type, $TypeWithKeys.Keys)
            $null = $Types.Add($TypeWithKeys.Type)
            $null = $Package.Entities.add($TypeDefinition)
        }
    }

    <#When we want to create a package by directly inputing the entities#>
    if (![String]::IsNullOrEmpty($Entities)) {

        $Package = New-Object Package
        $Types = New-Object System.Collections.ArrayList


        <#The usual input for Entities should be an arraylist of lists. However, if an arraylist with single list is passed in (a single Entity), it gets autocasted into a list of strings, which causes an error. The below codeblock handles this case:#>
        if ($Entities[0].GetType().Name -eq "String") {
            [String]$Type = $Entities[0]
            $null = $Types.add($Type)
            [System.Collections.ArrayList]$Keys = $Entities.Clone()

            $Keys.Remove($Type)
            if ($keys.Count -lt 1) {
                throw "$Type. A Type and at least one Key is required"
            }

            <#If 2+ Keys were available in $Keys they were recasted to a single string further on. This is a workaround#>
            $keyList = New-Object Collections.Generic.List[String]
            foreach ($key in $Keys) {
                $null = $keyList.Add($key)
            }

            $TypeDefinition = New-Object TypeDef ($Type, $keyList)
            $null = $Package.Entities.add($TypeDefinition)

        }

        else {
            <#if multiple lists were passed in Entities:#>

            foreach ($ent in $Entities) {
                [String]$Type = $ent[0]
                $null = $Types.add($Type)
                [Collections.Generic.List[String]]$Keys = $ent.clone()
                if ($keys.Count -lt 1) {
                    throw "$Type. A Type and at least one Key is required"
                }
                $null = $Keys.remove($Type)
                $keyList = New-Object Collections.Generic.List[String]
                foreach ($key in $keys) { $null = $keylist.add($key) }
                $TypeDefinition = New-Object TypeDef ($Type, $keyList)
                $null = $Package.Entities.add($TypeDefinition)
            }

        }

    }


    <#Validation if Types that were passed-in exist on specific installation.If not, display which ones and it ends the process#>
    if ($EvaluateWildcards -eq $True) {
        $request = internalvalidateConfigTypes $InstallationId $Types
        if ($request[-1] -eq 1) {
            $global:SimCorpXMGR.errorReturnValue
            if ($request[-3].length -gt 0) {
                $request[-3]
                Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
            }
            if ($request[-2].length -gt 0) {
                $request[-2]
                Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
            }
            break
        }



        <#============================================Optionally, evaluate wildcards=========================================#>

        $configTypes = internaladdentitiesFromWildCards $Package $InstallationId
        if ($configTypes[-1] -eq 1) {
            Write-Output "Warnings:"
            $configTypes[-2]
            Return "Found no valid TYPE-KEY pairs on this installation. Check your spelling and/or wildcards usage or use a different installation"
        }
        if ($configTypes[-2] -eq 2) {
            Write-Output "Warnings:"
            $configTypes[-3]
        }
        $Package = $configTypes[-1]
    }




    <#============================================Optionally, add dependencies=========================================#>
    if ($AddDependencies -eq $true) {
        <#Create a single flat array with all dependencies. Join-dependencies API returns also original entities#>
        $allDependencies = New-Object System.Collections.ArrayList

        foreach ($ent in $Package.entities) {
            $dependencies = Join-XMGRDependencies -InstallationId $InstallationId -Type $ent.type -Keys $ent.keys
            if ($dependencies[-1] -eq 1) {
                Write-Output "Dependencies error by TYPE:" $ent.type
                throw $dependencies[-2]
            }
            else {

                $dependencies = $dependencies[-1] | ConvertFrom-Json
                foreach ($item in $dependencies) {
                    $null = $allDependencies.add($item)
                }
            }
        }
        <#======================Remove duplicates====================#>
        $dependenciesNoDuplicates = New-Object System.Collections.ArrayList
        <#Get Non duplicated values#>
        $nonDuplicated = $allDependencies | Group-Object -Property "TYPE" | Where-Object { $_.count -eq 1 }
        foreach ($item in $nonduplicated.group) {
            $null = $dependenciesNoDuplicates.Add($item)
        }
        <#Get Duplicated Types#>
        $duplicated = $allDependencies | Group-Object -Property "TYPE" | Where-Object { $_.count -gt 1 }

        foreach ($group in $duplicated) {
            $type = $group.name
            $keys = $group.group.keys | Sort-Object | get-unique
            $TypeDef = New-Object TypeDef ($Type, $keys)
            $null = $dependenciesNoDuplicates.add($TypeDef)
        }
        <#Overwrite the existing objects with: existing objects+dependencies#>
        $Package = New-Object Package

        foreach ($entity in $dependenciesNoDuplicates) {
            $TypeDef = New-Object TypeDef ($entity.type, $entity.keys)
            $null = $Package.Entities.add($TypeDef)
        }


    }

    <#Genereate JSONPayload for the API#>

    if ($PSBoundParameters.ContainsKey("Tags")) {
        if ($Tags.Count -eq 1) {
            $TagsInJSON = $Tags | ConvertTo-Json
            $TagsInJSON = "[$TagsInJSON]"
        }
        else {
            $TagsInJSON = $Tags | ConvertTo-Json
        }
        $tgs = '"PackageTags":' + $TagsInJSON + ","
    }

    $date = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    $creator = ($global:SimCorpXMGR.currentUser | ConvertTo-Json)
    $listOfEntities = $Package.entities | convertto-json


    #To allow for sub-attributes, values need to be checked if they are a simple string or a JSON array. JSON array is without apostrophes.
if(!(internalvalidatejson $Project)){
$Project = '"'+$Project+'"'
}

if(!(internalvalidatejson $PackageInfo)){
$PackageInfo = '"'+$PackageInfo+'"'
}

if(!(internalvalidatejson $Version)){
$version = '"'+$Version+'"'
}


    if ($Package.Entities.Count -eq 1) {
        $jsonpayload = @"
{
$tgs
"RbaImportPolicies": {
"All": "$RBAPoliciesAll",
"General": "$RBAPoliciesGeneral",
"User": "$RBAPoliciesUser"
},
"From": "$InstallationId",
"PackageInfo": {"Info" : $PackageInfo, "Version" : $Version, "Created" : "$date", "CreatedBy" : $creator, "Project" : $Project},
"Entities": [$listOfEntities]
}
"@
    }
    else {
        $jsonpayload = @"
{
$tgs
"RbaImportPolicies": {
"All": "$RBAPoliciesAll",
"General": "$RBAPoliciesGeneral",
"User": "$RBAPoliciesUser"
},
"From": "$InstallationId",
"PackageInfo": {"Info" : $PackageInfo, "Version" : $Version, "Created" : "$date", "CreatedBy" : $creator, "Project" : $Project},
"Entities": $listOfEntities
}
"@
    }



    $Endpoint = "/api/odata/operations/start.export"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCallPOST $Endpoint $jsonpayload
    if ($request[-1] -eq 1) {
        if ($request[-3].length -gt 0) {
            $request[-3]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
        }
        if ($request[-2].length -gt 0) {
            $request[-2]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
        }
        $global:SimCorpXMGR.errorReturnValue
    }
    else {
        <#It takes some time for the operation to complete. The script checks every 1 second#>
        $counter = 600
        while ($counter -gt 0) {

            $operationDetails = Get-XMGROperationdetails $request.OperationId

            <#If Operation is complete, show result#>
            if ($operationDetails.StatusText -eq "Completed") {
                Write-Output $request.OperationId
                $operationDetails.actions
                <#If Completed but with errors, show the errors#>
                if ($operationDetails.result.ExportErrorDetails) {
                    $operationDetails.result.ExportErrorDetails
                }
                <#Show the entities in the new package#>
                Write-Output "Package Entities:"
                Get-XMGRPackageEntities -PackageHash $operationDetails.actions.result.PackageHash | ConvertTo-Json
                break
            }

            <#If CompletedwithWarnings, show details#>
            if ($operationDetails.StatusText -in ("CompletedWithWarnings", "CompletedPartially")) {
                Write-Output $request.OperationId
                $operationDetails.actions

                <#Show the errors#>
                if ($operationDetails.actions.result.ExportErrorDetails) {
                    if (($operationDetails.actions.Result.ExportErrorDetails.LargeObjectId).Length -gt 10) {
                                    (Get-XMGRLargeObject -ObjectId $operationDetails.actions.Result.ExportErrorDetails.LargeObjectId).ExportedEntityResults
                    }
                    else {
                        $operationDetails.actions.result.ExportErrorDetails
                        $operationDetails.actions.Warnings

                    }
                }


                <#Show the entities in the new partially-complete package#>
                Write-Output "Package Entities:"
                Get-XMGRPackageEntities -PackageHash $operationDetails.actions.result.PackageHash | ConvertTo-Json
                break
            }


            <#If package creation failed, show why#>
            if ($operationDetails.StatusText -eq "Failed") {
                Write-Output $request.OperationId
                $operationDetails.actions.error
                1
                break
            }
            start-Sleep -s 2
            $counter = $counter - 2
        }
    }
}

<#
.Synopsis

    General funtion to mark packages with Tags. It can mark with system tags "BROKEN" and "OUTDATED" as well with custom tags.

INPUTS:
    Packages to mark: Select the packages to mark by using standard filtering (see: get-help get-packages) or/and providing a list of hashes directly ("PackagesWithHashes")
    Mark with what: "WithSystemTag" - if selected, will mark with selected system tag, or tags from a list passed-in within "WithCustomTags"

OUTPUTS: Details of the modified packages
#>
function Add-XMGRTagsToPackages {
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet("Broken", "Outdated")]
        [String]$MarkWithSystemTag,
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $MarkWithCustomTags,
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $PackagesWithHashes,
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $PackagesWithTags,
        [Parameter(Mandatory = $false)]
        [String] $Version,
        [Parameter(Mandatory = $false)]
        [String] $Project,
        [Parameter(Mandatory = $false)]
        [String] $Info,
        [Parameter(Mandatory = $false)]
        [String] $CreatedBy,
        [Parameter(Mandatory = $false)]
        [String] $CreationDateGE,
        [Parameter(Mandatory = $false)]
        [String] $CreationDateLE,
        [Parameter(Mandatory = $false)]
        [ValidateSet("AtLeastOneTagFromList", "AllTagsFromList")]
        [String]$PackagesWithTagsLogic = "AtLeastOneTagFromList"
    )

    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand

    <#====================================Internal Functions================================#>
    #region
    function Mark-PackagesWithTags {
        param(
            [Parameter(Mandatory = $true)]
            [Collections.Generic.List[String]] $PackagesWithHashes,
            [Parameter(Mandatory = $true)]
            [Collections.Generic.List[String]] $Tags
        )
        $Endpoint = "/api/odata/Packages/PackagesService.AddTags"

        $hashes = "[]"
        $packageTags = "[]"


        if ($PackagesWithHashes.Count -eq 1) {
            $d = $PackagesWithHashes | ConvertTo-Json
            $hashes = "[$d]"
        }
        else {
            $hashes = $PackagesWithHashes | ConvertTo-Json
        }


        if ($Tags.Count -eq 1) {
            $d = $Tags | ConvertTo-Json
            $packageTags = "[$d]"
        }
        else {
            $packageTags = $Tags | ConvertTo-Json
        }

        $jsonpayload = @"
{
"Hashes": $hashes,
"Tags": $packageTags
}
"@


        Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
        $request = Connect-XMGRApiCallPOST $Endpoint $jsonpayload
        if ($request[-1] -eq 1) {
            $global:SimCorpXMGR.errorReturnValue
            if ($request[-3].length -gt 0) {
                $request[-3]
                Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
            }
            if ($request[-2].length -gt 0) {
                $request[-2]
                Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
            }
        }
        else {
            $markedPackages = $request.value
            $markedPackages
        }
    }
    function Mark-PackagesAsOutdated {
        param(
            [Parameter(Mandatory = $true)]
            [Collections.Generic.List[String]] $PackagesWithHashes
        )
        $Endpoint = "/api/odata/Packages/PackagesService.MarkAsOutdated"

        $hashes = $PackagesWithHashes | ConvertTo-Json

        if ($PackagesWithHashes.Count -eq 1) {
            $jsonpayload = @"
{"Hashes": [$hashes]}
"@
        }
        else {
            $jsonpayload = @"
{"Hashes": $hashes}
"@

        }
        Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
        $request = Connect-XMGRApiCallPOST $Endpoint $jsonpayload
        if ($request[-1] -eq 1) {
            $global:SimCorpXMGR.errorReturnValue
            if ($request[-3].length -gt 0) {
                $request[-3]
                Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
            }
            if ($request[-2].length -gt 0) {
                $request[-2]
                Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
            }
        }
        else {
            $markedPackages = $request.value
            $markedPackages
        }
    }
    function Mark-PackagesAsBroken {
        param(
            [Parameter(Mandatory = $true)]
            [Collections.Generic.List[String]] $PackagesWithHashes
        )

        $hashes = $PackagesWithHashes | ConvertTo-Json

        if ($PackagesWithHashes.Count -eq 1) {
            $jsonpayload = @"
{
"Hashes": [$hashes]

}
"@
        }
        else {
            $jsonpayload = @"
{
"Hashes": $hashes
}
"@

        }
        $Endpoint = "/api/odata/Packages/PackagesService.MarkAsBroken"
        Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
        $request = Connect-XMGRApiCallPOST $Endpoint $jsonpayload
        if ($request[-1] -eq 1) {
            $global:SimCorpXMGR.errorReturnValue
            if ($request[-3].length -gt 0) {
                $request[-3]
                Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
            }
            if ($request[-2].length -gt 0) {
                $request[-2]
                Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
            }
        }
        else {
            $markedPackages = $request.value
            $markedPackages
        }
    }
    #endregion

    <#======================================================================================#>

    <#At least one package selection criterion muss be passed-in#>
    if ([string]::IsNullOrEmpty($PackagesWithTags) -and [string]::IsNullOrEmpty($PackagesWithHashes) -and [string]::IsNullOrEmpty($Version) -and [string]::IsNullOrEmpty($Project) -and [string]::IsNullOrEmpty($CreatedBy) -and [string]::IsNullOrEmpty($CreationDateGE) -and [string]::IsNullOrEmpty($CreationDateLE)) {
        write-output "Pass-in at least one package selection criterion"
        break
    }

    <#At least one marking mode must be selected#>

    if ((![string]::IsNullOrEmpty($MarkWithCustomTags) -and ![string]::IsNullOrEmpty($MarkWithSystemTag)) -or ([string]::IsNullOrEmpty($MarkWithCustomTags) -and [string]::IsNullOrEmpty($MarkWithSystemTag)) ) {
        write-output "Select 'MarkWithCustomTags' OR 'MarkWithSystemTag'"
        break
    }

    <#Get the list of hashes for packages matching the criteria. Evaluate if users can omdify their packages only #>
    $usersEditingOwnPackagesOnly = $global:SimCorpXMGR.usersEditingOwnPackagesOnly
    $user = $global:SimCorpXMGR.currentUser

    if ($user -in $UsersEditingOwnPackagesOnly) {
        $CreatedBy = $global:SimCorpXMGR.currentUser
    }

    $packagestomark = internalgetfilteredhashes -CreatedBy $CreatedBy -Version $Version -PackagesWithHashes $PackagesWithHashes -PackagesWithTags $PackagesWithTags `
        -Project $Project -PackagesWithTagsLogic $PackagesWithTagsLogic -SelectBrokenAndOutdated No -CreationDateGE $CreationDateGE -CreationDateLE $CreationDateLE -Info $Info


    <#Abort if no packages were passed-in to mark#>
    if ($packagestomark.Count -eq 0) {
        Write-Output "No Packages selected to mark or matching selection criteria. You might also not be allowed to edit packages created by other users."
        break
    }

    <#=======================Mark packages according to input#==================================>

<#Marking with system tags#>
    if ($PSBoundParameters.ContainsKey("MarkWithSystemTag")) {

        if ($MarkWithSystemTag -eq "Broken") {

            Mark-PackagesAsBroken $packagestomark
        }
        if ($MarkWithSystemTag -eq "Outdated") {
            Mark-PackagesAsOutdated $packagestomark
        }
    }

    <#Marking with a custom tag#>
    if ($PSBoundParameters.ContainsKey("MarkWithCustomTags")) {
        Mark-PackagesWithTags -PackagesWithHashes $packagestomark -Tags $MarkWithCustomTags
    }
}

<#
.Synopsis

    General funtion to remove Tags from Packages. It can remove both system tags "BROKEN" and "OUTDATED" as well as custom tags.

INPUTS:
        Packages to unmark: Select the packages to unmark by using standard filtering (see: get-help get-packages) or/and providing a list of hashes directly ("PackagesWithHashes"). If you want to remove system tags,
the function will select only from packages that have them.

        Tags to remove: "RemoveSystemTag" - if selected, will remove selected system tag, or tags from a list "RemoveCustomTags"

OUTPUTS: Details of the modified packages

#>
function Remove-XMGRTagsFromPackages {
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet("Broken", "Outdated")]
        [String]$RemoveSystemTag,
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $RemoveCustomTags,
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $PackagesWithHashes,
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $PackagesWithTags,
        [Parameter(Mandatory = $false)]
        [String] $Version,
        [Parameter(Mandatory = $false)]
        [String] $Project,
        [Parameter(Mandatory = $false)]
        [String] $Info,
        [Parameter(Mandatory = $false)]
        [String] $CreatedBy,
        [Parameter(Mandatory = $false)]
        [String] $CreationDateGE,
        [Parameter(Mandatory = $false)]
        [String] $CreationDateLE,
        [Parameter(Mandatory = $false)]
        [ValidateSet("AtLeastOneTagFromList", "AllTagsFromList")]
        [String]$PackagesWithTagsLogic = "AtLeastOneTagFromList"
    )

    <#====================================Internal Functions================================#>
    #region
    function Unmark-PackagesAsBroken {
        param(
            [Parameter(Mandatory = $true)]
            [Collections.Generic.List[String]] $PackageHashes
        )

        $hashes = $PackageHashes | ConvertTo-Json

        if ($PackageHashes.Count -eq 1) {
            $jsonpayload = @"
{
"Hashes": [$hashes]

}
"@
        }
        else {
            $jsonpayload = @"
{
"Hashes": $hashes
}
"@

        }
        $Endpoint = "/api/odata/Packages/PackagesService.UnMarkAsBroken"
        Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
        $request = Connect-XMGRApiCallPOST $Endpoint $jsonpayload
        if ($request[-1] -eq 1) {
            $global:SimCorpXMGR.errorReturnValue
            if ($request[-3].length -gt 0) {
                $request[-3]
                Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
            }
            if ($request[-2].length -gt 0) {
                $request[-2]
                Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
            }
        }
        else {
            $unmarkedPackages = $request.value
            $unmarkedPackages
        }
    }
    function UnMark-PackagesAsOutdated {
        param(
            [Parameter(Mandatory = $true)]
            [Collections.Generic.List[String]] $PackageHashes
        )
        $Endpoint = "/api/odata/Packages/PackagesService.UnMarkAsOutdated"

        $hashes = $PackageHashes | ConvertTo-Json

        if ($PackageHashes.Count -eq 1) {
            $jsonpayload = @"
{"Hashes": [$hashes]}
"@
        }
        else {
            $jsonpayload = @"
{"Hashes": $hashes}
"@

        }
        Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
        $request = Connect-XMGRApiCallPOST $Endpoint $jsonpayload
        if ($request[-1] -eq 1) {
            $global:SimCorpXMGR.errorReturnValue
            if ($request[-3].length -gt 0) {
                $request[-3]
                Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
            }
            if ($request[-2].length -gt 0) {
                $request[-2]
                Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
            }
        }
        else {
            $unmarkedPackages = $request.value
            $unmarkedPackages
        }
    }
    function UnMark-PackagesWithTags {
        param(
            [Parameter(Mandatory = $true)]
            [Collections.Generic.List[String]] $PackageHashes,
            [Parameter(Mandatory = $true)]
            [Collections.Generic.List[String]] $Tags
        )
        $Endpoint = "/api/odata/Packages/PackagesService.RemoveTags"

        $hashes = "[]"
        $packageTags = "[]"


        if ($PackageHashes.Count -eq 1) {
            $d = $PackageHashes | ConvertTo-Json
            $hashes = "[$d]"
        }
        else {
            $hashes = $PackageHashes | ConvertTo-Json
        }


        if ($Tags.Count -eq 1) {
            $d = $Tags | ConvertTo-Json
            $packageTags = "[$d]"
        }
        else {
            $packageTags = $Tags | ConvertTo-Json
        }

        $jsonpayload = @"
{
"Hashes": $hashes,
"Tags": $packageTags
}
"@


        Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
        $request = Connect-XMGRApiCallPOST $Endpoint $jsonpayload
        if ($request[-1] -eq 1) {
            $global:SimCorpXMGR.errorReturnValue
            if ($request[-3].length -gt 0) {
                $request[-3]
                Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
            }
            if ($request[-2].length -gt 0) {
                $request[-2]
                Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
            }
        }
        else {
            $unmarkedPackages = $request.value
            $unmarkedPackages
        }
    }
    #endregion

    <#======================================================================================#>
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand

    <#At least one package selection criterion muss be passed-in#>
    if ([string]::IsNullOrEmpty($PackagesWithTags) -and [string]::IsNullOrEmpty($PackagesWithHashes) -and [string]::IsNullOrEmpty($Version) -and [string]::IsNullOrEmpty($Project) -and [string]::IsNullOrEmpty($CreatedBy) -and [string]::IsNullOrEmpty($CreationDateGE) -and [string]::IsNullOrEmpty($CreationDateLE)) {
        write-output "Pass-in at least one package selection criterion"
        break
    }

    <#One marking mode must be selected#>
    if ((![string]::IsNullOrEmpty($RemoveCustomTags) -and ![string]::IsNullOrEmpty($RemoveSystemTag)) -or ([string]::IsNullOrEmpty($RemoveCustomTags) -and [string]::IsNullOrEmpty($RemoveSystemTag)) ) {
        write-output "Select 'RemoveCustomTags' OR 'RemoveSystemTag'"
        break
    }


    <#Unmark packages according to input.Evaluate if users can omdify their packages only#>
    $usersEditingOwnPackagesOnly = $global:SimCorpXMGR.usersEditingOwnPackagesOnly
    $user = $global:SimCorpXMGR.currentUser

    if ($user -in $UsersEditingOwnPackagesOnly) {
        $CreatedBy = $global:SimCorpXMGR.currentUser
    }



    <#Removing system tags#>
    if ($PSBoundParameters.ContainsKey("RemoveSystemTag")) {


        if ($RemoveSystemTag -eq "Broken") {

            <#Create a list of broken packages to unmark#>
            $packagestounmark = internalgetfilteredhashes -CreatedBy $CreatedBy -Version $Version -PackagesWithHashes $PackagesWithHashes -PackagesWithTags $PackagesWithTags `
                -Project $Project -PackagesWithTagsLogic $PackagesWithTagsLogic -SelectBrokenAndOutdated Broken -CreationDateGE $CreationDateGE -CreationDateLE $CreationDateLE -Info $Info


            <#Abort if no packages were passed-in to unmark#>
            if ($packagestounmark.Count -eq 0) {
                Write-Output "No Packages selected to unmark.You might also not be allowed to edit packages owned by other users"
                break
            }
            Unmark-PackagesAsBroken $packagestounmark
        }
        if ($RemoveSystemTag -eq "Outdated") {

            <#Create a list of outdated packages to unmark#>
            $packagestounmark = internalgetfilteredhashes -CreatedBy $CreatedBy -Version $Version -PackagesWithHashes $PackagesWithHashes -PackagesWithTags $PackagesWithTags `
                -Project $Project -PackagesWithTagsLogic $PackagesWithTagsLogic -SelectBrokenAndOutdated Outdated -CreationDateGE $CreationDateGE -CreationDateLE $CreationDateLE -Info $info


            <#Abort if no packages were passed-in to unmark#>
            if ($packagestounmark.Count -eq 0) {
                Write-Output "No Packages selected to unmark.You might also not be allowed to edit packages owned by other users"
                break
            }

            UnMark-PackagesAsOutdated $packagestounmark
        }
    }

    <#=================Removing custom tags==================================================#>
    if ($PSBoundParameters.ContainsKey("RemoveCustomTags")) {

        <#Create a list of packages to unmark - exclude broken and outdated. Evaluate if users can omdify their packages only#>
        $packagestounmark = internalgetfilteredhashes -CreatedBy $CreatedBy -Version $Version -PackagesWithHashes $PackagesWithHashes -PackagesWithTags $PackagesWithTags `
            -Project $Project -PackagesWithTagsLogic $PackagesWithTagsLogic -SelectBrokenAndOutdated No -CreationDateGE $CreationDateGE -CreationDateLE $CreationDateLE -info $info


        <#Abort if no packages were passed-in to unmark#>
        if ($packagestounmark.Count -eq 0) {
            Write-Output "No Packages selected to unmark.You might also not be allowed to edit packages owned by other users"
            break
        }

        UnMark-PackagesWithTags -PackageHashes $packagestounmark -Tags $RemoveCustomTags
    }
}
<#
.Synopsis

    Imports a list of packages from XMGR repository to a list of installations and/or installation groups.
    Can perform a test import ("dry run") if "DryRun" paramteres is set to true - nothing will be imported, but any possible pre-check errors will be shown

INPUTS: All arguments are optional

        A list of packages to import:   standard filtering (see: get-help get-xmgrpackages) or/and providing a list of hashes directly ("PackagesWithHashes")
        Import where to:                a list of installations (TargetInstallationIds) and/or a list of InstallationGroups (TargetInstallationGroupIds)

        OUTPUTS: Details of the import process
#>
function Import-XMGRPackages {
    param(
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $PackagesWithHashes,
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $PackagesWithTags,
        [Parameter(Mandatory = $false)]
        [String]$CreatedBy,
        [Parameter(Mandatory = $false)]
        [String]$Version,
        [Parameter(Mandatory = $false)]
        [String] $Project,
        [Parameter(Mandatory = $false)]
        [String] $Info,
        [Parameter(Mandatory = $false)]
        [String] $CreationDateGE,
        [Parameter(Mandatory = $false)]
        [String] $CreationDateLE,
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $TargetInstallationIds,
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $TargetInstallationGroupIds,
        [Parameter(Mandatory = $false)]
        [ValidateSet("AtLeastOneTagFromList", "AllTagsFromList")]
        [String]$PackagesWithTagsLogic = "AtLeastOneTagFromList",
        [ValidateSet($false, $true)]
        $AuditAndRollback = $true,
        [ValidateSet($false, $true)]
        $DryRun = $false
    )

    $hashes = internalgetfilteredhashes -CreatedBy $CreatedBy -Version $Version -PackagesWithHashes $PackagesWithHashes -PackagesWithTags $PackagesWithTags -Project $Project `
        -PackagesWithTagsLogic $PackagesWithTagsLogic -SelectBrokenAndOutdated No -CreationDateGE $CreationDateGE -CreationDateLE $CreationDateLE -Info $info


    if ($hashes.count -ge 1) {
        $out = "Count of packages to import:" + $hashes.count
        #    Write-Output $out
    }
    else {
        Write-Output "No packages selected for import"
        return $global:SimCorpXMGR.errorReturnValue
    }

    if ($PSBoundParameters.ContainsKey("TargetInstallationIds")) {
        if ($TargetInstallationIds.Count -eq 1) {
            $i = $TargetInstallationIds | ConvertTo-Json
            $i = "[$i]"
        }
        else {
            $i = $TargetInstallationIds | ConvertTo-Json
        }
        $installations = '"TargetInstallations":' + $i + ","
    }

    if ($PSBoundParameters.ContainsKey("TargetInstallationGroupIds")) {
        if ($TargetInstallationGroupIds.Count -eq 1) {
            $g = $TargetInstallationGroupIds | ConvertTo-Json
            $g = "[$g]"
        }
        else {
            $g = $TargetInstallationGroupIds | ConvertTo-Json
        }
        $installationGroups = '"TargetInstallationGroups":' + $g + ","
    }

    if ($AuditAndRollback -eq $true) {
        $allInstallations = Get-XMGRValidInstallations -InstallationIds $TargetInstallationIds -InstallationGroupIds $TargetInstallationGroupIds -InstallationPermission "ImportConfiguration"
    }

    $Endpoint = "/api/odata/Operations/Start.Import"
    foreach ($hash in $hashes) {

        if ($AuditAndRollback -eq $true) {
            <#Get a list of objects from the package we are importing#>
            $entities = New-Object System.Collections.ArrayList

            $packageEntities = Get-XMGRPackageEntities $hash
            foreach ($Type in $packageEntities.GetEnumerator().name) {
                $list = New-Object Collections.Generic.List[String]
                $null = $list.Add($type)
                foreach ($key in $packageEntities.$type) { $null = $list.Add($key) }
                $null = $entities.add($list)
            }



            if ($DryRun -eq $true) {

                $AuditAndRollback = $false
                $Endpoint = "/api/odata/Operations/Start.ImportDryRun"
            }
            else {


                <#Create a package with the same contents as the package being imported - as base for audit and comparison#>
                foreach ($installation in $allInstallations) {
                    $desc = "CreatedBeforeImporting: " + $hash
                    $auditPackage = Add-XMGRPackage -InstallationId $installation -Tags ("sys", "audit", "rollback") -Entities $entities -PackageInfo "audit_rollback" -Version $desc -Project $installation  -EvaluateWildcards False -AddDependencies False
                }
            }
        }



        $jsonpayload = @"
{
$installations
$installationGroups
"PackageHash": "$hash"
}
"@




        Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
        $request = Connect-XMGRApiCallPOST $Endpoint $jsonpayload
        if ($request[-1] -eq 1) {
            $global:SimCorpXMGR.errorReturnValue
            if ($request[-3].length -gt 0) {
                $request[-3]
                Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
            }
            if ($request[-2].length -gt 0) {
                $request[-2]
                Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
            }

        }
        else {
            <#timeout for operation set for 15minutes #>
            $counter = 1800
            while ($counter -gt 0) {
                $operationDetails = Get-XMGROperationDetails $request.OperationId
                if ($operationDetails.StatusText -eq "Completed") {

                    if ($DryRun -eq $true) {
                        write-output $operationDetails.actions
                        write-output $operationDetails.actions.result.ImportDryRunResult
                        break
                    }
                    else {
                        if ($AuditAndRollback -eq $true) { $null = Add-XMGRTagsToPackages -MarkWithSystemTag Outdated -PackagesWithTags("sys", "audit", "rollback") -PackagesWithTagsLogic AllTagsFromList }
                        write-output $operationDetails.actions
                        break
                    }

                }
                if ($operationDetails.StatusText -eq "Failed") {

                    if ($DryRun -eq $true) {
                        $global:SimCorpXMGR.errorReturnValue
                        $operationDetails.actions
                        $operationDetails.actions.error
                        write-output $operationDetails.actions.result.ImportDryRunResult
                        break
                    }
                    else {
                        $global:SimCorpXMGR.errorReturnValue
                        $operationDetails.actions
                        $operationDetails.actions.error
                        write-output $operationDetails.actions.result.ImportResult.PreCheckErrors
                        break

                    }
                }

                <#If CompletedwithWarnings, show details#>
                if ($operationDetails.StatusText -eq "CompletedWithWarnings" -or $operationDetails.StatusText -eq "CompletedPartially") {
                    if ($AuditAndRollback -eq $true) { $null = Add-XMGRTagsToPackages -MarkWithSystemTag Outdated -PackagesWithTags("sys", "audit", "rollback") -PackagesWithTagsLogic AllTagsFromList }
                    write-output $operationDetails.actions
                    if($operationDetails.actions.Warnings -like "*large object*"){
                        Write-Output "Large Objects:"
                        Write-output (Get-XMGRLargeObject $operationDetails.Actions.result.ImportResult.LargeObjectId).ImportedEntityResults 
                    }
                    break
                    <#Show the errors#>
                    if ($operationDetails.actions.result.ExportErrorDetails) {
                        if ($AuditAndRollback -eq $true) { $null = Add-XMGRTagsToPackages -MarkWithSystemTag Outdated -PackagesWithTags("sys", "audit", "rollback") -PackagesWithTagsLogic AllTagsFromList }
                        write-output $operationDetails.actions.result.ExportErrorDetails
                        break
                    }

                }

                start-Sleep -s 1
                $counter = $counter - 1
            }
        }
    }

}


<#
.Synopsis

 As prerequisites you need to create two packages with authorisation profiles (TYPE = "AUTPROFILES") - the first one (Provider Package) can contain only a single profile.
 The second (Client Package) can contain multiple profiles.
 With the MergeType variable you decide if you want to intersect or union the provider profile with each of the client profiles.
 The function creates a new package, that contains the the results - merged client profiles. The package with be created with standard descriptions.

INPUTS: two package hashes and description parameters


OUTPUTS: a new package

#>
function Merge-XMGRAuthorisationProfiles {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ProviderPackageHash,
        [Parameter(Mandatory = $true)]
        [String]$ClientPackageHash,
        [Parameter(Mandatory = $false)]
        [ValidateSet("Union", "Intersection")]
        [String]$MergeType = "Intersection",
        [Parameter(Mandatory = $true)]
        [Collections.Generic.List[String]] $Tags,
        [Parameter(Mandatory = $true)]
        [String] $PackageInfo,
        [Parameter(Mandatory = $true)]
        [String] $Version,
        [Parameter(Mandatory = $true)]
        [String] $Project
    )

    if ($PSBoundParameters.ContainsKey("Tags")) {
        if ($Tags.Count -eq 1) {
            $TagsInJSON = $Tags | ConvertTo-Json
            $TagsInJSON = "[$TagsInJSON]"
        }
        else {
            $TagsInJSON = $Tags | ConvertTo-Json
        }
        $tgs = '"PackageTags":' + $TagsInJSON + ","
    }

    $date = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    $creator = ($global:SimCorpXMGR.currentUser  | ConvertTo-Json)

    $jsonpayload = @"
{
$tgs
"ProviderPackageHash": "$ProviderPackageHash",
"ClientPackageHash": "$ClientPackageHash",
"MergeType": "$MergeType",
"SignPackage": false,
"PackageInfo": {"Info" : "$PackageInfo", "Version" : "$Version", "Created" : "$date", "CreatedBy" : $creator, "Project" : "$Project"}
}
"@

    $Endpoint = "/api/odata/Operations/Start.BasicMergeAuthorizationProfiles"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCallPOST $Endpoint $jsonpayload
    if ($request[-1] -eq 1) {
        $global:SimCorpXMGR.errorReturnValue
        if ($request[-3].length -gt 0) {
            $request[-3]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
        }
        if ($request[-2].length -gt 0) {
            $request[-2]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
        }
    }
    else {
        <#It takes some time for the operation to complete. The script checks every 1 second#>
        $counter = 120
        while ($counter -gt 0) {

            $operationDetails = Get-XMGROperationdetails $request.OperationId
            $operationDetails.StatusText

            <#If Operation is complete, show result#>
            if ($operationDetails.StatusText -eq "Completed") {
                $operationDetails.actions
                get-xmgrpackages -PackagesWithHashes $operationDetails.Actions.result.MergeAuthorizationProfilesPackageResult.PackageHash
                break
            }
            if ($operationDetails.StatusText -eq "Failed") {
                $operationDetails.actions
                break
            }
            start-Sleep -s 1
            $counter = $counter - 1
        }

    }

}

<#
.Synopsis

    Allows to remove one or multiple objects of a specified TYPE from one or multiple installations/installation groups

INPUTS: TYPE and at least one KEY, one or multiple InstallationIds or InstallationGroupIds


OUTPUTS: a status report on each deletion attempt

#>
function Start-XMGRDeleteObjects {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Type,
        [Parameter(Mandatory = $true)]
        [Collections.Generic.List[String]]$Keys,
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]]$TargetInstallationIds,
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]]$TargetInstallationGroupIds
    )

    if ([String]::IsNullOrEmpty($TargetInstallationIds) -and ([String]::IsNullOrEmpty($TargetInstallationGroupIds))) {
        Write-Output "At least one Target Installation is required"
        break
    }

    $Keys = $Keys -replace '^.*$', '"$&"' -join ","


    if ([String]::IsNullOrEmpty($TargetInstallationIds)) {
        $TargetInstallationGroupIds = $TargetInstallationGroupIds -replace '^.*$', '"$&"' -join ","

        $jsonpayload = @"
{
"TargetInstallationGroups" : [ $TargetInstallationGroupIds ],
"Entity":
{
             "Type" : "$Type",
             "Keys" : [$keys]

}
}
"@

    }
    if ([String]::IsNullOrEmpty($TargetInstallationGroupIds)) {
        $TargetInstallationIds = $TargetInstallationIds -replace '^.*$', '"$&"' -join ","

        $jsonpayload = @"
{
"TargetInstallations" : [ $TargetInstallationIds ],
"Entity":
{
             "Type" : "$Type",
             "Keys" : [$keys]

}
}
"@

    }
    if (![String]::IsNullOrEmpty($TargetInstallationIds) -and ![String]::IsNullOrEmpty($TargetInstallationGroupIds)) {
        $TargetInstallationIds = $TargetInstallationIds -replace '^.*$', '"$&"' -join ","
        $TargetInstallationGroupIds = $TargetInstallationGroupIds -replace '^.*$', '"$&"' -join ","
        $jsonpayload = @"
{
"TargetInstallations" : [ $TargetInstallationIds ],
"TargetInstallationGroups" : [ $TargetInstallationGroupIds ],
"Entity":
{
             "Type" : "$Type",
             "Keys" : [$keys]

}
}
"@
    }



    $Endpoint = "/api/odata/Operations/Start.Delete"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCallPOST -Endpoint $Endpoint -jsonpayload $jsonpayload
    if ($request[-1] -eq 1) {
        $global:SimCorpXMGR.errorReturnValue
        if ($request[-3].length -gt 0) {
            $request[-3]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
        }
        if ($request[-2].length -gt 0) {
            $request[-2]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
        }
    }
    else {
        <#It takes some time for the operation to complete. The script checks every 1 second#>
        $counter = 120
        while ($counter -gt 0) {

            $operationDetails = Get-XMGROperationdetails $request.OperationId
            $operationDetails.StatusText

            <#If Operation is complete, show result#>
            if ($operationDetails.StatusText -in ("Completed", "CompletedWithWarnings", "CompletedPartially")) {
                $operationDetails.actions
                $operationDetails.Actions.result
                break
            }

            start-Sleep -s 1
            $counter = $counter - 1
        }

    }
}

<#
.Synopsis

    Merges two packages into a single one. The two packages are unaffected, a third, being a sum is created.The new package must be marked with PakcageInfo and a list of Tags (at least one).

INPUTS: Mandatory: SourcePackageHash, TargetPackageHash, PackageInfo, at least one Tag

OUTPUTS: PackageHash of a newly created merge package, the PackageType is "applied package"

#>
function Merge-XMGRPackages {
    param(
        [Parameter(Mandatory = $true)]
        [String] $SourcePackageHash,
        [Parameter(Mandatory = $true)]
        [String] $TargetPackageHash,
        [Parameter(Mandatory = $true)]
        [String] $PackageInfo = "",
        [Parameter(Mandatory = $true)]
        [Collections.Generic.List[String]] $Tags
    )

    if ($PSBoundParameters.ContainsKey("Tags")) {
        if ($Tags.Count -eq 1) {
            $i = $Tags | ConvertTo-Json
            $i = "[$i]"
        }
        else {
            $i = $Tags | ConvertTo-Json
        }
        $packageTags = '"PackageTags":' + $i + ","
    }


    $jsonpayload = @"
{
$packageTags
"SourcePackageHash": "$SourcePackageHash",
"TargetPackageHash": "$TargetPackageHash",
"PackageInfo": {
            "Info": "$PackageInfo"
        }
}
"@


    $Endpoint = "/api/odata/Operations/Apply.Package"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCallPOST $Endpoint $jsonpayload
    if ($request[-1] -eq 1) {
        $global:SimCorpXMGR.errorReturnValue
        if ($request[-3].length -gt 0) {
            $request[-3]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
        }
        if ($request[-2].length -gt 0) {
            $request[-2]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
        }
    }
    else {
        $counter = 120
        while ($counter -gt 0) {
            $operationDetails = Get-XMGROperationDetails $request.OperationId
            $operationDetails.StatusText
            if ($operationDetails.StatusText -eq "Completed") {
                $operationDetails.actions.result
                break
            }
            if ($operationDetails.StatusText -eq "Failed") {
                $operationDetails.actions.error
                1
                break
            }
            start-Sleep -s 1
            $counter = $counter - 1
        }
    }
}

<#
.Synopsis

    Generates the list of dependencies for a specific Type and a set of keys (for a single installation).

INPUTS: InstallationId, Type and a list of Keys

OUTPUTS: A list of dependencies in JSON format

#>
function Join-XMGRDependencies {
    param(
        [Parameter(Mandatory = $true)]
        [String] $InstallationId,
        [Parameter(Mandatory = $true)]
        [String] $Type,
        [Parameter(Mandatory = $true)]
        [Collections.Generic.List[String]] $Keys
    )

    $keysInJSON = $keys | ConvertTo-Json

    if ($Keys.Count -eq 1) {
        $jsonpayload = @"
{
"From": "$InstallationId",
"Entities":[
{ "Type": "$Type",
  "Keys": [$keysInJSON]
}]
}
"@
    }
    else {
        $jsonpayload = @"
{
"From": "$InstallationId",
"Entities":[
{ "Type": "$Type",
  "Keys": $keysInJSON
}]
}
"@

    }
    $Endpoint = "/api/odata/Operations/Join.Dependencies"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCallPOST $Endpoint $jsonpayload
    if ($request[-1] -eq 1) {
        $global:SimCorpXMGR.errorReturnValue
        if ($request[-3].length -gt 0) {
            $request[-3]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
        }
        if ($request[-2].length -gt 0) {
            $request[-2]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
        }
    }
    else {
        <#Timeout set for 2 minutes#>
        $counter = 120
        while ($counter -gt 0) {
            $operationDetails = Get-XMGROperationDetails $request.OperationId
            $operationDetails.StatusText
            if ($operationDetails.StatusText -in ("Completed", "CompletedPartially")) {
                if ($operationDetails.actions.result.joineddependencies.LargeObjectId) {
                    $largeObject = Get-XMGRLargeObjects $operationDetails.actions.result.joineddependencies.LargeObjectId
                    return $largeObject.Dependencies | ConvertTo-Json

                }
                else {
                    return $operationDetails.actions.result.joineddependencies.Dependencies | ConvertTo-json

                }
            }
            if ($operationDetails.StatusText -eq "Failed") {
                $operationDetails.actions.error
                1
                break
            }
            start-Sleep -s 1
            $counter = $counter - 1
        }
    }
}

#endregion

<#============================================= PACKAGE MANAGEMENT ===================================#>
#region
<#
.Synopsis

    THE GENERAL PACKAGE FILTERING FUNCTION
    This function is used for package selection in other functions (import-packages, mark-packages, export-packagesFromXMGR etc), so the selection logic is unified accross the system.

    List the available packages matching passes-in selection criteria. It can include broken and outdated packages (set "SelectBrokenAndOutdated" accordingly) as well as filter per:
    Package Tags ("PackagesWithTags") Version, Project and Package creator AD-NAme (CreatedBy) and a range of dates of package creation.
    Version, CreatedBy and Project allow using wildcards - "?" for a single character and "*" for multiple. One can also pass-in a list of Package hashes ("PackagesWithHashes")
    Packages are filtered out by Tags and hashes first and then by other criteria. The output is ordered by Creation Date, ascending.


    Examples:
    get-xmgrpackages - diplays all packages that are not broken or outdated

    get-xmgrpackages -version 1 - gets all packages that are not broken or outdated, but of version 1

    get-xmgrpackages -CreatedBy "scd/john*" -PackagesWithTags "current" -Project DEV - displays packages of project "DEV", marked with tag "current" and created by users "scd/john_doe" and "scd/john_smith"

    Get-XMGRPackages -CreationDateGE 2021-09-18 -PackagesWithTags adtrtest -CreationDateLE 2021-09-18 - all packages with tag "adtrtest" created on 18 september 2021

    get-xmgrpackages -PackagesWithTags ("current","patch") -PackagesWithTagsLogic AllTagsFromList - will get all packages that are not broken or outdated, but are tagged with BOTH "current" and "patch" tags.

    get-xmgrpackages -PackagesWithHashes ("V194X5XLB291QTRP2U6WAT9QHKSZN7AFDQBHMS6JE2", "V1RU3SXXCSPYH59JTF3NAMFNUKVEEVBRC8MCF9S282","V1SAEUZV2VTE77W6PUPVSRAU6H52YZGZERVG1FHZC4","V1SN2PEHSEKKV689RAQSAD9FRKQVVFVA2ZSF392U9Z") -Project dev -Version 1 - will query the details of the four packages and return only these of Project "dev" and Version "1" which are not "broken" or "outdated".

INPUTS (all are optional):

        - PackagesWithTags: a list of Package Tags, will display only packages marked with the tags. Pass-in "NULL" (capital letters) to display packages with no tags at all
        - PackagesWithTagsLogic - when multiple PackagesWithTags are passed-in, by default (AtLeastOneTagFromList) at least one tag must be present to select the package. If set to "AllTagsFromList". The package must have all the listed Tags to be selected.
        - CreatedBy - filter by AD-Name of the package creator
        - Version - filter by the content of the version field
        - Info - filter by the content of the "info" field of the PackageInfo section
        - Project - filter by the content of the project field
        - CreationDateGE - get packages with date of creation greater-or-equal to YYYY-MM-DD
        - CreationDateLE - get packages with date of creation less-or-equal to YYY-MM-DD
        - PackagesWithHashes - select packages by their hashes
        - SelectBrokenAndOutdated - by default broken and outdated packages are filtered out. Can be selectively added.

OUTPUTS: a list of packages that match the filtering criteria passed-in.
#>
function Get-XMGRPackages {
    param(
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [Collections.Generic.List[String]] $PackagesWithTags,

        [Parameter(Mandatory = $false)]
        [String]$CreatedBy,
        [Parameter(Mandatory = $false)]
        [String]$Version,
        [Parameter(Mandatory = $false)]
        [String] $Project,
        [Parameter(Mandatory = $false)]
        [String] $Info,

        [Parameter(Mandatory = $false)]
        [String] $CreationDateGE,
        [Parameter(Mandatory = $false)]
        [String] $CreationDateLE,

        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $PackagesWithHashes,

        [Parameter(Mandatory = $false)]
        [ValidateSet("AtLeastOneTagFromList", "AllTagsFromList")]
        [String]$PackagesWithTagsLogic = "AtLeastOneTagFromList",

        [Parameter(Mandatory = $false)]
        [ValidateSet("No", "Outdated", "Broken", "All")]
        [String]$SelectBrokenAndOutdated = "No"
    )

    $Endpoint = "/api/odata/packages?api-version=1.0"

    <#Set up filtering variables#>

    $versionFilter = "*"
    $creatorFilter = "*"
    $projectFilter = "*"
    $infoFilter = "*"

    if (![STRING]::IsNullOrEmpty($Version)) { $versionFilter = $Version }
    if (![STRING]::IsNullOrEmpty($CreatedBy)) { $creatorFilter = $CreatedBy }
    if (![STRING]::IsNullOrEmpty($Project)) { $projectFilter = $Project }
    if (![STRING]::IsNullOrEmpty($Info)) { $infoFilter = $Info }



    <# First found of filtering. Get-packages with specific tags #>
    if (![STRING]::IsNullOrEmpty($PackagesWithTags)) {

        if ($PackagesWithTagsLogic -eq "AtLeastOneTagFromList") {

            $filter = $PackagesWithTags -replace '^.*$', '"$&"' -join ","
            $filterExpression = "Tags/any(tag : tag in($filter))"
        }
        if ($PackagesWithTagsLogic -eq "AllTagsFromList") {

            $filterExpression = $PackagesWithTags -replace '^.*$', "Tags/any(t: t eq '$&')" -join " and "
        }

    }


    <#Use a different API to get Broken and Outdated Packages. Add filter accordingly#>
    if ($SelectBrokenAndOutdated -ne "No") {
        $Endpoint = "/api/odata/packages/Get.All?api-version=1.0"

        if ($SelectBrokenAndOutdated -eq "Broken") { $extraFilter = "Tags/any(t: t eq 'sys:broken')" }
        if ($SelectBrokenAndOutdated -eq "Outdated") { $extraFilter = "Tags/any(t: t eq 'sys:outdated')" }
        if ($SelectBrokenAndOutdated -eq "All") { $extraFilter = '' }

        if ([STRING]::IsNullOrEmpty($filterExpression)) {
            $filterExpression = $extraFilter
        }
        else {
            if (![STRING]::IsNullOrEmpty($extraFilter)) { $filterExpression = $filterExpression + " and " + $extraFilter }
        }
    }

    <#Special case - get packages with no tags by passing in "NULL"#>
    if ($PackagesWithTags -ceq "NULL") {

        if ($SelectBrokenAndOutdated -eq "No") { $filterExpression = "Tags/all(t: t eq null)" }
        if ($SelectBrokenAndOutdated -eq "Broken") { $filterExpression = "Tags/all(t: t eq 'sys:broken') and Tags/any()" }
        if ($SelectBrokenAndOutdated -eq "Outdated") { $filterExpression = "Tags/all(t: t eq 'sys:outdated') and Tags/any()" }
        if ($SelectBrokenAndOutdated -eq "All") { $filterExpression = 'Tags/all(tag: tag in ("sys:broken","sys:outdated")) and Tags/any()' }


    }

    <#If Package Hashes were passed in - add them to the filter#>
    if (![STRING]::IsNullOrEmpty($PackagesWithHashes)) {

        $hashFilter = $PackagesWithHashes -replace '^.*$', '"$&"' -join ","
        $hashFilter = "Hash in($hashfilter)"
        if ([STRING]::IsNullOrEmpty($filterExpression)) { $filterExpression = $hashFilter }else { $filterExpression = $filterExpression + " and " + $hashFilter }

    }

    if (![STRING]::IsNullOrEmpty($CreationDateGE)) {
        $offset = get-date -UFormat "%Z:00"

        $CreationDateGEFilter = "CreationDate ge " + $CreationDateGE + "T00:00:00.0000000" + $offset
        if ([STRING]::IsNullOrEmpty($filterExpression)) { $filterExpression = $CreationDateGEFilter }else { $filterExpression = $filterExpression + " and " + $CreationDateGEFilter }
    }

    if (![STRING]::IsNullOrEmpty($CreationDateLE)) {
        $offset = get-date -UFormat "%Z:00"

        $CreationDateLEFilter = "CreationDate le " + $CreationDateLE + "T23:59:59.9999999" + $offset
        if ([STRING]::IsNullOrEmpty($filterExpression)) { $filterExpression = $CreationDateLEFilter }else { $filterExpression = $filterExpression + " and " + $CreationDateLEFilter }
    }





    <#Order by Creation Date, ascending - latest on the bottom#>
    $orderby = "CreationDate asc"

    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCall $Endpoint "GET" -Filter $filterExpression -OrderBy $orderby
    if ($request[-1] -eq 1) {
        $global:SimCorpXMGR.errorReturnValue
        if ($request[-3].length -gt 0) {
            $request[-3]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
        }
        if ($request[-2].length -gt 0) {
            $request[-2]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
        }
    }
    else {
        $PackagesMatchingTagCriteria = $request.value
        <#Second round of filtering#>
        return $PackagesMatchingTagCriteria | Where-Object { $_.PackageInfo.CreatedBy -like "$creatorFilter" -and $_.PackageInfo.Version -like "$versionFilter" -and $_.PackageInfo.Project -like "$projectFilter" -and $_.packageInfo.Info -like "$infoFilter" }

    }
}



#endregion

<#============================================= PACKAGE COMPARE ======================================#>
#region
<#
.Synopsis

    Compares two packages. The common objects (identical in both packages) are ignored. If some objects were modified, the differences are shown in detail.

INPUTS: Two package hashes

OUTPUTS: A detailed raport of the comparison, "Contents are Identical" if there are no differences.

#>
function Compare-XMGRPackages {
    param(
        [Parameter(Mandatory = $true)]
        [String] $LeftPackageHash,
        [Parameter(Mandatory = $true)]
        [String] $RightPackageHash,
        [ValidateSet($TRUE, $FALSE)]
        $returnObject = $false
    )

    <#Private function for displaying the differences between updated entities#>
    function display-updateDetails {
        param(
            [Parameter(Mandatory = $true)]
            [String]$ComparedPackageID
        )

        $compareResults = Get-XMGRPackageCompareResults $ComparedPackageID

        if ("Updated" -in $compareResults.value.modificationtype) {
            Write-Output "UPDATE DETAILS:"
        }

        for ($i = $compareResults.value.count; $i -ge 0; $i--) {
            if ($compareResults.value[$i].ModificationType -eq "Updated") {
                Write-output "==================================================================================="

                $label = "TYPE: " + $compareResults.value[$i].Type + " Key: " + $compareResults.value[$i].Key
                write-output $label
                $compareDetails = Get-XMGRPackageCompareDetails -PackageHash $ComparedPackageID -Type $compareResults.value[$i].Type -Key $compareResults.value[$i].Key
                $properties = $compareDetails | get-member -MemberType NoteProperty


                foreach ($property in $properties.name) {
                    $prop = "Property: " + $property
                    Write-Output $prop
                    Write-output $compareDetails.$property | Format-Table -AutoSize -Wrap
                }

                write-output "==================================================================================="
            }
        }
    }

    function returnObject {
     param(
            [Parameter(Mandatory = $true)]
            [String]$ComparedPackageID
        )

        $compareResults = Get-XMGRPackageCompareResults $ComparedPackageID

        $result = [System.Collections.ArrayList]::new()

        foreach($compare in $compareResults.value){

            $compareDetails = Get-XMGRPackageCompareDetails -PackageHash $ComparedPackageID -Type $compare.Type -Key $compare.Key

            $HashFirstPackage = ($ComparedPackageID.Split('_'))[0]
            $HashSecondPackage = ($ComparedPackageID.Split('_'))[1]


            
            foreach($Attribute in (($compareDetails.Attributes[0])| get-member -MemberType NoteProperty).Name){

                if(($compare.ModificationType) -eq "Added"){
                    
                    $AttributeName = $Attribute
                    $AttributeValue = ($compareDetails.Attributes[0]).$Attribute

                    $CompareObj = [PSCustomObject]@{
                        Type = ($compare.Type)
                        Entity = ($compare.Key)
                        Action = ($compare.ModificationType)
                        Attribute = $AttributeName
                        FirstPackageHash = $HashFirstPackage
                        FirstPackageValue = "Not present"
                        SecondPackageHash = $HashSecondPackage
                        SecondPackageValue = $AttributeValue
                    }

                    $null = $result.add($CompareObj)
                        
                }elseif(($compare.ModificationType) -eq "Deleted"){
                    
                    $AttributeName = $Attribute
                    $AttributeValue = ($compareDetails.Attributes[0]).$Attribute

                    $CompareObj = [PSCustomObject]@{
                        Type = ($compare.Type)
                        Entity = ($compare.Key)
                        Action = ($compare.ModificationType)
                        Attribute = $AttributeName
                        FirstPackageHash = $HashFirstPackage
                        FirstPackageValue = $AttributeValue
                        SecondPackageHash = $HashSecondPackage
                        SecondPackageValue = "Not present"
                    }

                    $null = $result.add($CompareObj)
                
                }else{
                    
                    $AttributeName = $Attribute
                    $AttributeValue = (($compareDetails.Attributes[0]).$Attribute)[0]
                    $AttributeValueSecondPackage = (($compareDetails.Attributes[0]).$Attribute)[-1]

                    $CompareObj = [PSCustomObject]@{
                        Type = ($compare.Type)
                        Entity = ($compare.Key)
                        Action = ($compare.ModificationType)
                        Attribute = $AttributeName
                        FirstPackageHash = $HashFirstPackage
                        FirstPackageValue = $AttributeValue
                        SecondPackageHash = $HashSecondPackage
                        SecondPackageValue = $AttributeValueSecondPackage
                    }

                    $null = $result.add($CompareObj)

                }
            
           }
            <#
            $CompareObj = [PSCustomObject]@{
                Type = ($compare.Type)
                Entity = ($compare.Key)
                Action = ($compare.ModificationType)
                HashFirstPackage = $HashFirstPackage
                
                HashSecondPackage = $HashSecondPackage
                          
            }
            #ValueFirstPackage = {if($compare.ModificationType -eq "Added" -or $compare.ModificationType -eq "Updated"){}}

            "Compare"
            $compare
            "Compare Details"
            $compareDetails
            "CompareObj"
            $CompareObj
            "----------------------"
            #>

            
        }
        $result | Format-Table
    }


    $jsonpayload = @"
{
"LeftPackageHash": "$LeftPackageHash",
"RightPackageHash": "$RightPackageHash"
}
"@


    $Endpoint = "/api/odata/Operations/Start.Compare"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCallPOST $Endpoint $jsonpayload
    if ($request[-1] -eq 1) {
        $global:SimCorpXMGR.errorReturnValue
        if ($request[-3].length -gt 0) {
            $request[-3]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
        }
        if ($request[-2].length -gt 0) {
            $request[-2]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
        }
    }
    else {
        $PackageID = $LeftPackageHash + "_" + $RightPackageHash
        start-sleep -Seconds 2
        $compareResults = Get-XMGRPackageCompareResults $PackageID
        if ($compareResults.value) {
            if($returnObject){return (returnObject $PackageID);break}
            $compareResults.value | Select-Object -Property Type, Key, ModificationType
            start-sleep -Seconds 2
            write-output "==================================================================================="
            display-updateDetails $PackageID
        }
        else {
            Write-Output "Contents are Identical"
        }
    }
}

<#
.Synopsis

    After two packages are compared using Compare-Packages function, an object containing all the data is created.
    The object has the ID of LeftPackageHash_RightPackageHash.
    This function allows to see the data stored in the object

INPUTS: PackageID from Compare-Package function (in format: LeftPackageHash_RightPackageHash)

OUTPUTS: Details of the comparison

#>
function Get-XMGRPackageCompareResults {
    param(
        [Parameter(Mandatory = $true)]
        [String] $PackageId
    )
    $Endpoint = "/api/odata/PackageCompareResults('$PackageId')/PackageCompareResultService.RetrieveModifiedEntities"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCall $Endpoint "GET"

    if ($request[-1] -eq 1) {
        $global:SimCorpXMGR.errorReturnValue
        if ($request[-3].length -gt 0) {
            $request[-3]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
        }
        if ($request[-2].length -gt 0) {
            $request[-2]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
        }
    }
    else {
        $request
    }

}

<#
.Synopsis

    After two packages are compared using Compare-Packages function, an object containing all the data is created.
    The object has the ID of LeftPackageHash_RightPackageHash and contains data about differences between configuration objects.
    This function allows to see the details of the differences between configuration objects in the packages.

INPUTS: PackageID from Compare-Package function (in format: LeftPackageHash_RightPackageHash), Type and Key of the object we want to examine in detail

OUTPUTS: Details of the modified configuration object

#>
function Get-XMGRPackageCompareDetails {
    param(
        [Parameter(Mandatory = $true)]
        [String] $PackageHash,
        [Parameter(Mandatory = $true)]
        [String] $Type,
        [Parameter(Mandatory = $true)]
        [String] $Key
    )
    $Endpoint = "/api/odata/PackageCompareResults('$PackageHash')/PackageCompareResultService.DiffObject?Key=$Key&Type=$Type&api-version=1.0"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCall $Endpoint "GET"

    if ($request[-1] -eq 1) {
        $global:SimCorpXMGR.errorReturnValue
        if ($request[-3].length -gt 0) {
            $request[-3]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
        }
        if ($request[-2].length -gt 0) {
            $request[-2]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
        }
    }
    else {
        $compareDetails = $request
        $compareDetails
    }
}


<#
.Synopsis

    An advanced configuration comparison function. For initial check (just a list of objects) "Check- configurations" is recommended as it can check multiple installations at once and is faster.

    Function compares given fragments of configuration on two SCD Installations in detail. Specific entities to compare mut be first defined in a package definition (package definition can contain wildcards).
    In the background, two packages will be exported based on the provided definition and compared. Coparison result will be shown to the user. Each difference will be listed separately.
    Afterwards the created packages will be diposed - marked a "broken" and with custom tags: "compare","todelete","temporary".

INPUTS: Package Definition Name and two Installation IDs

OUTPUTS: Details of comparison.

#>
function Compare-XMGRConfigurationDetails {
    param(
        [Parameter(Mandatory = $true)]
        [String] $PackageDefinitionName,

        [ValidateSet($TRUE, $FALSE)]
        $EvaluateWildcards = $True,
        [Parameter(Mandatory = $true)]
        [String] $First_InstallationId,
        [Parameter(Mandatory = $true)]
        [String] $Second_InstallationId
    )

    $PackageDefinition = Get-XMGRPackageDefinition $PackageDefinitionName

    if ($PackageDefinition[-1] -eq 1) {
        $errorMEssage = $PackageDefinition[-2]
        write-output $errorMEssage
        break
    }

    $firstPackage = Add-XMGRPackage -FromPackageDefinition $PackageDefinitionName -InstallationId $First_InstallationId -Tags ("compare", "todelete", "temporary") -PackageInfo temporary -Version temp -Project comparisonPackage -EvaluateWildcards $EvaluateWildcards
    $secondPackage = Add-XMGRPackage -FromPackageDefinition $PackageDefinitionName -InstallationId $Second_InstallationId -Tags ("compare", "todelete", "temporary") -PackageInfo temporary -Version temp -Project comparisonPackage -EvaluateWildcards $EvaluateWildcards

    $counter = 600

    while ($counter -gt 0) {
        if (![STRING]::IsNullOrEmpty($firstPackage.result.packagehash) -and ![STRING]::IsNullOrEmpty($secondPackage.result.packagehash) ) { break }

        sleep -Seconds 2
        $counter = $counter - 2
    }
    if ($counter -eq 0) {
        Write-Output "Time-out"
        break
    }

    Compare-XMGRPackages -LeftPackageHash $firstPackage.result.packagehash -RightPackageHash $secondPackage.result.packagehash

    $removeTemporatyPackages = Add-XMGRTagsToPackages -MarkWithSystemTag Broken -PackagesWithHashes ($firstPackage.result.packagehash, $secondPackage.result.packagehash)

}

<#
.Synopsis

    Function serves as an initial configuration comparison check.
    Generates a list of objects based on a Package Definition (Package Definition can contain wildcards!) from one or multiple installations and/or Installation groups.
    The objects are then listed in format :"Type_Key : [list of installationIds where this object is present]"
    To compare the details of objects (possible only for 2 installations at once and more resource instensive) use "Check-ConfigurationDetails"

INPUTS: Mandatory: a Package Definition Name, at least one InstallationID or InstallationGroupId.
        Optionally: Set the "Output" accordingly.

OUTPUTS: A Dictionary with configuration overview. Error message if mandatory Parameters are wrong.

#>
function Compare-XMGRConfigurations {
    param(
        [Parameter(Mandatory = $true)]
        [String] $PackageDefinitionName,
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]]$InstallationIds,
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]]$InstallationGroupIds,
        [ValidateSet("FullConfiguration", "DifferencesOnly")]
        $Output = "FullConfiguration"
    )

    Function Merge-Hashtables($listWithDictionaries) {
        $Output = @{}
        ForEach ($Hashtable in $listWithDictionaries) {
            If ($Hashtable -is [Hashtable]) {
                ForEach ($Key in $Hashtable.Keys) { $Output.$Key = If ($Output.ContainsKey($Key)) { @($Output.$Key) + $Hashtable.$Key } Else { $Hashtable.$Key } }
            }
        }
        If ($Operator) { ForEach ($Key in @($Output.Keys)) { $_ = @($Output.$Key); $Output.$Key = Invoke-Command $Operator } }
        $Output
    }

    $installations = Get-XMGRValidInstallations -InstallationIds $InstallationIds -InstallationGroupIds $InstallationGroupIds -InstallationPermission "ExportConfiguration"


    <#Validate, that at least one installation was passed-in#>
    if ($installations.Count -eq 0) {
        Write-Output "No installation were selected for comparison"
        return 1
    }

    <#Validate that the passed-in Package Definiton exists#>
    $packageDefinition = Get-XMGRPackageDefinition $PackageDefinitionName
    if ($packageDefinition[-1] -eq 1) {
        Write-Output "Package Definition $PackageDefinitionName does not exist"
        return 1
    }

    $packageDefinition = $packageDefinition[-1] | ConvertFrom-Json

    $Types = New-Object Collections.Generic.List[String]
    $dictionaryList = New-Object System.Collections.ArrayList

    <#Generate the entity list for each Installations#>
    foreach ($installationId in $installations) {

        $Package = New-Object Package
        $Types = New-Object System.Collections.ArrayList

        foreach ($TypeWithKeys in $packageDefinition) {
            $TypeDefinition = New-Object TypeDef ($TypeWithKeys.Type, $TypeWithKeys.Keys)
            $null = $Types.Add($TypeWithKeys.Type)
            $null = $Package.Entities.add($TypeDefinition)
        }

        $configuration = internaladdentitiesFromWildCards -Package $Package -InstallationId $installationId


        $configuration = $configuration.Entities

        $dict = @{}
        foreach ($TypeWithKeys in $configuration) {
            foreach ($key in $TypeWithKeys.Keys) {
                $name = $TypeWithKeys.Type + "_" + $key
                $dict.add("$name", "$installationId")
            }

        }
        $null = $dictionaryList.add($dict)

    }
    $mergedDictionary = Merge-Hashtables $dictionaryList

    Write-Output "Evaluating following installations: $installations"

    <#If Only one installations is being evaluated, only full configuration can be shown#>
    if ($installations.count -eq 1 -and $output -eq "DifferencesOnly") {
        $Output = "FullConfiguration"
        Write-Output "Single installation is being evaluated. Changing output to 'FullConfiguration'"
    }

    if ($output -eq "FullConfiguration") { return $mergedDictionary }
    if ($output -eq "DifferencesOnly") {
        $differences = $mergedDictionary.GetEnumerator() | Where-Object { $_.Value.count -lt $installations.count }
        return $differences
    }
}


<#
.Synopsis

    Compares the details of objects available in the input package with these objects present on the input installation (or show "added/deleted" if the objects are not present in both places)
    This translates to showing the changes that will be introduced by importing the  package to that installation.
    Comparison result will be shown to the user. Each difference will be listed separately.
    To perform the comparison, in the background an additional package is created (from the input installation)
    Afterwards this package is being diposed of - marked a "broken" and with custom tags: "compare","todelete","temporary".

INPUTS: PackageHash and InstallationId

OUTPUTS: Details of comparison.

#>
function Compare-XMGRPackageAndInstallation{
param(
  [Parameter(Mandatory = $true)]
  [String] $PackageHash,
  [Parameter(Mandatory = $true)]
  [String] $InstallationId
)

    $PackageHashValidation = internalgetfilteredhashes -PackagesWithHashes $PackageHash

    if(!$PackageHashValidation){
    $Global:SimCorpXMGR.errorReturnValue
    return Write-Output "Package with Hash: $PackageHash is not available."
    }


        $installationValidation = Get-XMGRValidInstallations -InstallationIds $InstallationId -InstallationPermission "ImportConfiguration"


    <#Validate, that at least one installation was passed-in#>
    if (!$installationValidation) {
        $Global:SimCorpXMGR.errorReturnValue
        return Write-Output "Installation $InstallationId does not exist"

    }


            <#Get a list of objects from the package importing#>
            $entities = New-Object System.Collections.ArrayList

            $packageEntities = Get-XMGRPackageEntities $PackageHash
            foreach ($Type in $packageEntities.GetEnumerator().name) {
                $list = New-Object Collections.Generic.List[String]
                $null = $list.Add($type)
                foreach ($key in $packageEntities.$type) { $null = $list.Add($key) }
                $null = $entities.add($list)
            }

$comparepackage = Add-XMGRPackage -Entities $entities -InstallationId $InstallationId -Tags ("compare", "todelete", "temporary") -PackageInfo temporary -Version temp -Project comparisonPackage -EvaluateWildcards $false

if($comparepackage[-1] -eq 1){
    
    $Global:SimCorpXMGR.errorReturnValue
    return $comparepackage[-2]

}

    $counter = 600

    while ($counter -gt 0) {
        if (![STRING]::IsNullOrEmpty($comparepackage.result.packagehash)) { break }

        sleep -Seconds 2
        $counter = $counter - 2
    }
    if ($counter -eq 0) {
        Write-Output "Time-out"
        break
    }

        Compare-XMGRPackages -LeftPackageHash $PackageHash  -RightPackageHash $comparepackage.result.packagehash

    $removeTemporatyPackages = Add-XMGRTagsToPackages -MarkWithSystemTag Broken -PackagesWithHashes $comparepackage.result.packagehash

}
#endregion

<#============================================= Additional functions =================================#>
#region

<#
.Synopsis

    Generates a list of all the exportable objects from a given installation. The function takes between 5 and 10 minutes to complete. It is recommended to launch it in a separate PowerShell session

INPUTS: an InstallationId of the installation for which do we want to get a list for

OUTPUTS: a CSV file in the predefined EXPORT folder

#>
function Write-XMGRDictionary {
    param(
        [Parameter(Mandatory = $true)]
        [String] $InstallationId
    )

    [System.Collections.ArrayList] $types = Get-XMGRConfigTypes $InstallationId
    sleep -Seconds 5
    $resultlist = New-Object System.Collections.ArrayList


    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand

    foreach ($type in $types) {
        Write-XMGRLogMessage -LogLevel 0 -OnScreen $true -LogMessage $type.type
        $keys = Get-XMGRInstancesOfConfigType -installationId $InstallationId -ConfigurationType $type.type
        foreach ($key in $keys) {
            if ($type.folder -ne $null) {
                $key.folder = $type.folder
            }
            $null = $resultlist.add($key)
        }

        $file = $Global:SimCorpXMGR.exportFolder + "\XMGRDictionary_" + $InstallationId + ".csv"
    }
    $resultlist = $resultlist | ConvertTo-Csv | Out-File $file
}

function Get-XMGRModifiedObjects {
    param(
        [Parameter(Mandatory = $true)]
        [String] $InstallationId,
        [Parameter(Mandatory = $true)]
        [int] $DaysinThePast,
        [Parameter(Mandatory = $false)]
        [ValidateSet($True, $false)]
        [String]$GeneratePackageWithChanges = $false,
        [Parameter(Mandatory = $false)]
        [String] $LastChangedBy,
        [Parameter(Mandatory = $false)]
        [System.Collections.ArrayList]$InputTypes,
        [Parameter(Mandatory = $false)]
        [bool]$WriteToDisk = $true
    )

    $filterDate = (Get-Date).AddDays( - ($DaysinThePast))
    $types = Get-XMGRConfigTypes $InstallationId

    if (![String]::IsNullOrEmpty($InputTypes)) {
        $types = $types | Where-Object { $_.type -in $InputTypes }
    }

    $changesList = New-Object System.Collections.ArrayList

    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand

    $defaultCreateDate = (get-date).AddYears(-20)

    foreach ($type in $types) {
        Write-XMGRLogMessage -LogLevel 0 -OnScreen $true -LogMessage $type.type
        $TypeAndKeys = New-Object System.Collections.Generic.List[Object]
        $keys = Get-XMGRInstancesOfConfigType -installationId $InstallationId -ConfigurationType $type.type
        foreach ($key in $keys) {
            if ($key.LastChangedAt -eq $null) {
                $key.LastChangedAt = $defaultCreateDate
            }
            [datetime]$createdDate = $key.LastChangedAt

            if (![String]::IsNullOrEmpty($LastChangedBy)) {
                if (($key.LastChangedBy -eq $LastChangedBy) -and ($createdDate -ge $filterDate)) {
                    $null = $TypeAndKeys.add($key)
                }
            }
            else {
                if ($createdDate -ge $filterDate) {
                    $null = $TypeAndKeys.add($key)

                }
            }

        }
        if ($TypeAndKeys.Count -gt 0) { $null = $changesList.Add($TypeAndKeys) }


    }

    if ($WriteToDisk) {
        <#Output the list to a CSV File#>
        $date = [string]$filterDate.Day + "-" + [string]$filterDate.Month + "-" + [string]$filterDate.Year
        $file = $global:SimCorpXMGR.exportFolder + "Changes_since_" + $Date + "_" + $InstallationId + ".csv"
        $outputList = [System.Collections.Generic.List[object]]::new()
        foreach ($list in $changesList) {
            foreach ($item in $list) { $null = $outputList.add($item) }

        }
        $outputList | ConvertTo-Csv | Out-File $file
    }

    <#If selected, create a package containing modified objects#>
    if ($GeneratePackageWithChanges -eq $true) {
        $entities = [System.Collections.ArrayList]::new()

        foreach ($list in $changesList) {
            $typeWithKeys = [Collections.Generic.List[String]]::new()
            $null = $typeWithKeys.Add($list[0].type)
            foreach ($object in $list) {
                $null = $typeWithKeys.add($object.key)
            }

            $null = $entities.Add($typeWithKeys)
        }

        Add-XMGRPackage -InstallationId $InstallationId -Tags ("modobj", "changes") -Entities $entities -PackageInfo "changes_since_$filterDate_$LastChangedBy" -Project $InstallationId -Version "modifiedObjects" -EvaluateWildcards False
    }
    $changesList
}

<#
.Synopsis

     Helper function, used to upload manually manipulated data.

INPUTS: a path to a CSV file contatining (possibly, among others) columns "TYPE" and "KEY"


OUTPUTS: An arraylist containing lists of strings where first string is the TYPE, followed by KEYS. Can be passed in to "Create-Package" or "Create-PackageDefinition" as value for "-Entities" parameter

EXAMPLE: "$entities = load-entitiesFromCSV $FilePath" , followed by "Create-PackageDefinition -InstallationId xx -Entities $entities -Tags demo"

#>
function Get-XMGRentitiesFromCSV {
    param(
        [Parameter(Mandatory = $true)]
        [String] $FilePath
    )

    $FileContent = get-content -Encoding UTF8 $FilePath | ConvertFrom-Csv

    $types = $FileContent.Type | Sort-Object -Unique

    $entities = New-Object System.Collections.ArrayList

    foreach ($type in $types) {
        $TypeandKeys = New-Object Collections.Generic.List[String]
        $null = $TypeandKeys.Add($type)

        foreach ($item in $FileContent) {
            if ($item.type -eq $type) {
                $null = $TypeandKeys.Add($item.key)
            }
        }
        $null = $entities.add($TypeandKeys)
    }
    return [System.Collections.ArrayList]$entities
}

<#
.Synopsis

  Function generates a changelog based on the audit log (ID from Get-XMGRAudit) and pre-existing rollback package.
  If one triggered multiple identical import operations within minutes, then manually selecting the rollback package
  might be necessary.


INPUTS: ID, a rollback package ID if multiple import attempts were made in short time span.

OUTPUTS: Detailed raport of all changes made by the specified import

#>
function Get-XMGRChangelog {
    param(
        [Parameter(Mandatory = $true)]
        [int]$AuditLogId,
        [Parameter(Mandatory = $false)]
        [string]$RollbackPackageHash

    )

    $logEntry = Get-XMGRAudit -Id $AuditLogId
    if (!$logEntry.id) {
        Write-XMGRLogMessage -LogLevel 1 -OnScreen $true -LogMessage "AuditLog Entry $AuditLogId not found"
    }

    if (![STRING]::IsNullOrEmpty($RollbackPackageHash)) {
        Compare-XMGRPackages -LeftPackageHash $RollbackPackageHash -RightPackageHash $logEntry.PackageHash
        break
    }

    # Get the right rollback package
    $version = "CreatedBeforeImporting: " + $logEntry.PackageHash
    $CreatedBy = $logEntry.UserName
    $InstallationId = $logEntry.InstallationId



    [datetime]$dateFilterPlus = ([datetime]$logEntry.CreatedAt).AddMinutes(-10)

    $rollbackPackage = Get-XMGRPackages -SelectBrokenAndOutdated Outdated -PackagesWithTags "rollback" -Version $version -CreatedBy $CreatedBy -Project $InstallationId | Where-Object -Property CreationDate -GT $dateFilterPlus

    if ($rollbackPackage.count -gt 1) {
        Write-XMGRLogMessage -LogLevel 1 -LogMessage "Found multiple possible rollback packages. Select the appropiate one and run the function again with the -RollbackPackageHash parameter"
        $rollbackPackage
        break
    }

    if (!$rollbackPackage.hash) {
        Write-XMGRLogMessage -LogLevel 1 -OnScreen $true -LogMessage "Found no Rollback Package for this import operation. No changelog is available"
        break
    }

    $PackageHash = $logEntry.PackageHash
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $true -LogMessage "Changelog for Installation < $InstallationId > and < $packagehash > "
    Compare-XMGRPackages -LeftPackageHash $rollbackPackage.Hash -RightPackageHash $logEntry.PackageHash


}
#endregion

<#============================================= Import and Export of Packages between XMGRs ==========#>
#region
<#
.Synopsis

    Used to export packages from XMGR to external systems. Depending on the "ExportFormat" can output the package in an XMGR importable format (ExportFormat = Package)
    or a package in human readable format (ExportFormat = HumanReadable).
    The function get the binary content from the XMGR repository and creates files for each selected package in the predefined EXPORT Folder.

INPUTS: Optional:
        - standard set of filtering paramters for package selection (for details run: get-help get-packages)
        - ExportFormat - is set to "Package" by default

OUTPUTS: All packages that match the filtering criteria will be exported to files in predefined Export folder, named with Package hashes.
         Human readable packages will be output in "HumanReadable" Folder in Export folder.

#>
function Export-XMGRPackagesFromXMGR {
    param(
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $PackagesWithHashes,
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $PackagesWithTags,
        [Parameter(Mandatory = $false)]
        [String]$CreatedBy,
        [Parameter(Mandatory = $false)]
        [String]$Version,
        [Parameter(Mandatory = $false)]
        [String] $Project,
        [Parameter(Mandatory = $false)]
        [String] $Info,
        [Parameter(Mandatory = $false)]
        [String] $CreationDateGE,
        [Parameter(Mandatory = $false)]
        [String] $CreationDateLE,
        [Parameter(Mandatory = $false)]
        [ValidateSet("Package", "HumanReadable")]
        [String]$ExportFormat = "Package",

        [Parameter(Mandatory = $false)]
        [ValidateSet("AtLeastOneTagFromList", "AllTagsFromList")]
        [String]$PackagesWithTagsLogic = "AtLeastOneTagFromList"

    )

    <#Get a list of PackageHashes that correspond to packages matching the filtering criteria#>
    $hashes = internalgetfilteredhashes -CreatedBy $CreatedBy -Version $Version -PackagesWithHashes $PackagesWithHashes -PackagesWithTags $PackagesWithTags `
        -Project $Project -PackagesWithTagsLogic $PackagesWithTagsLogic -SelectBrokenAndOutdated No -CreationDateGE $CreationDateGE -CreationDateLE $CreationDateLE -Info $Info

    if ($hashes) {
        $out = "Count of packages to export:" + $hashes.count
        Write-Output $out
    }
    else {
        Write-Output "No packages were selected for export. Check the filtering criteria."
        break
    }


    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand

    foreach ($PackageHash in $hashes) {

        if ($ExportFormat -eq "Package") {


            $filepath = join-path -path $global:SimCorpXMGR.exportFolder -childpath $PackageHash
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
            $Endpoint = "/api/odata/packages('$PackageHash')/PackagesService.RetrievePackage"



            $request = Connect-XMGRApiCall -Endpoint $Endpoint -Method GET -OutFile $filepath

            if ($request[-1] -eq 1) {
                $global:SimCorpXMGR.errorReturnValue
                if ($request[-3].length -gt 0) {
                    $request[-3]
                    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
                }
                if ($request[-2].length -gt 0) {
                    $request[-2]
                    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
                }
            }


            Write-Output "Exported to file:" $filepath

        }

        if ($ExportFormat -eq "HumanReadable") {

            $filepath = (New-TemporaryFile).FullName
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
            $Endpoint = "/api/odata/packages('$PackageHash')/PackagesService.RetrievePackage"
            $request = Connect-XMGRApiCall -Endpoint $Endpoint -Method GET -OutFile $filepath

            if ($request[-1] -eq 1) {
                $global:SimCorpXMGR.errorReturnValue
                if ($request[-3].length -gt 0) {
                    $request[-3]
                    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
                }
                if ($request[-2].length -gt 0) {
                    $request[-2]
                    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
                }
            }

            $humanReadableFolder = join-path $global:SimCorpXMGR.exportFolder -childpath "HumanReadable"
            if (!(Test-Path -LiteralPath $humanReadableFolder)) { $null = New-Item -Path $humanReadableFolder -ItemType "directory" }

            Rename-Item -Path $filepath -NewName "$filepath.zip" -Force

            $packageFolder = join-path -path $humanReadableFolder -childpath $PackageHash
            Expand-Archive -LiteralPath "$filepath.zip" -DestinationPath $packageFolder -Force
            Remove-Item "$filepath.zip" -Force
            Write-Output "Exported to folder:" $packageFolder


        }

    }
}

<#
.Synopsis

    Made to work in conjunction with Start-XMGRUploadPackages to allow for integration with GIT.
    Set your Import and Export folder to be the same one.
    The functions map the "Project" property of the packages to sub-Root folder and "Info" property to sub-sub-Root folder.
    You pass in the package selection criteria and the package is saved in folder corresponding to its "Project" folder in folder named like its "PackageInfo". This can be
    overwritten with "Destination" parameter.
    Since, there can be multiple packages with the same Project and Info, only one package can be downloaded at once - if multiple are selected the latest only is downloaded.

INPUTS: Optional:


OUTPUTS: Operation Details, folder where the package was saved

#>
function Start-XMGRDownloadPackage {
    param(
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $PackagesWithHashes,
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $PackagesWithTags,
        [Parameter(Mandatory = $false)]
        [String]$CreatedBy,
        [Parameter(Mandatory = $false)]
        [String]$Version,
        [Parameter(Mandatory = $false)]
        [String] $Project,
        [Parameter(Mandatory = $false)]
        [String] $Info,
        [Parameter(Mandatory = $false)]
        [String] $CreationDateGE,
        [Parameter(Mandatory = $false)]
        [String] $CreationDateLE,

        [Parameter(Mandatory = $false)]
        [ValidateSet("AtLeastOneTagFromList", "AllTagsFromList")]
        [String]$PackagesWithTagsLogic = "AtLeastOneTagFromList",
        [Parameter(Mandatory = $false)]
        [string] $Destination

    )
    <#Get a list of packages that correspond to packages matching the filtering criteria#>
    $package = Get-XMGRPackages -Project $Project -Info $info -PackagesWithTags $PackagesWithTags -CreatedBy $CreatedBy -Version $Version -CreationDateGE $CreationDateGE -CreationDateLE $CreationDateLE -PackagesWithHashes $PackagesWithHashes -PackagesWithTagsLogic $PackagesWithTagsLogic

    if (!$package) {
        Write-Output "No package were selected for export. Check the selection criteria."
        break
    }
    if ($package.count -gt 1) {
        $out = "There are " + $package.count + " packages matching these criteria. Only the latest will be exported"
        Write-Output $out
        $package = $package[-1]
    }



    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand

    $filepath = (New-TemporaryFile).FullName
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $hash = $Package.Hash
    $Endpoint = "/api/odata/packages('$hash')/PackagesService.RetrievePackage"
    $request = Connect-XMGRApiCall -Endpoint $Endpoint -Method GET -OutFile $filepath

    if ($request[-1] -eq 1) {
        if ($request[-3].length -gt 0) {
            $request[-3]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
        }
        if ($request[-2].length -gt 0) {
            $request[-2]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
        }
        $global:SimCorpXMGR.errorReturnValue
    }


    Rename-Item -Path $filepath -NewName "$filepath.zip" -Force

    $packageFolder = Join-Path (join-path -path $global:SimCorpXMGR.exportFolder -childpath $Package.PackageInfo.Project) -ChildPath $Package.PackageInfo.Info

    if (![string]::IsNullOrEmpty($Destination)) {
        $packageFolder = $Destination
    }
    Remove-Item -Path $packageFolder -Force -ErrorAction Ignore -Recurse

    Expand-Archive -LiteralPath "$filepath.zip" -DestinationPath $packageFolder -Force
    Remove-Item "$filepath.zip" -Force


    Write-Output "Downloaded to folder:" $packageFolder
}


<#
.Synopsis

    Made to work in conjunction with Start-XMGRDownloadPackages to allow for integration with VCS.
    Set your Import and Export folder to be the same one.
    The functions map the "Project" property of the packages to sub-Root folder and "Info" property to sub-sub-Root folder.
    It excludes the "Package_Definitions" folder.
    You pass in project, tags to mark the new packages with and optionally info (if no info, then all packages for that project are uploaded) and that automatically gets the right files.

    Optionally, you can delete the files after successful import.
#>
function Start-XMGRUploadPackages {
    param(
        [Parameter(Mandatory = $false)]
        [String] $Project,
        [Parameter(Mandatory = $false)]
        [String] $Info,
        [Parameter(Mandatory = $true)]
        [String[]] $MarkUploadedPackagesWithTags,
        [ValidateSet($True, $False)]
        $DeleteAfterImport = $False,
        [Parameter(Mandatory = $false)]
        [String] $SourceFolder
    )

    function internaluploadpackages {
        param(
            [Parameter(Mandatory = $true)]
            [String] $SourceFolder,
            [Parameter(Mandatory = $true)]
            [String[]] $MarkUploadedPackagesWithTags,
            [ValidateSet($True, $False)]
            $DeleteAfterImport = $False
        )


        if ($MarkUploadedPackagesWithTags.Count -eq 1) {
            $Tags = $MarkUploadedPackagesWithTags | ConvertTo-Json
            $Tags = "[$Tags]"
        }
        else {
            $Tags = $MarkUploadedPackagesWithTags | ConvertTo-Json
        }
        $TagsInJSON = '"Tags":' + $Tags



        $jsonpayload = @"
{
  $TagsInJSON
}
"@
        $Endpoint = "/api/odata/Packages/PackagesService.StorePackage"
        $fieldName = 'packageFile'

        $filepath = (New-TemporaryFile).FullName + ".zip"
        $startingLocation = Get-Location

        Set-Location (split-path $filepath)
        #tar -a -cf $filepath -C $SourceFolder *
        Compress-7Zip -ArchiveFileName $filepath -Path $SourceFolder
        Set-location $startingLocation
        Add-Type -AssemblyName System.Net.Http

        $multipartBody = New-Object System.Net.Http.MultipartFormDataContent
        $fileStream = [System.IO.File]::OpenRead($filePath)
        $fileName = [System.IO.Path]::GetFileName($filePath)
        $fileContent = New-Object System.Net.Http.StreamContent($fileStream)

        $payloadContent = New-Object System.Net.Http.StringContent $jsonpayload

        $multipartBody.Add($fileContent, $fieldName, $fileName)
        $multipartBody.Add($payloadContent, 'packageModelWrapper.StorePackageModel')

        Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
        $Request = Connect-ApiCallMultipart $Endpoint $multipartBody
        if ($request[-1] -eq 1) {

            if ($request[-3].length -gt 0) {
                $request[-3]
                Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
            }
            if ($request[-2].length -gt 0) {
                $request[-2]
                Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
            }
            $global:SimCorpXMGR.errorReturnValue
        }
        else {
            Write-Output "Uploaded package:"

            Write-Output ("Source         : " + $SourceFolder)

            $Request

            if ($DeleteAfterImport -eq $true) {
                Remove-Item $SourceFolder -Recurse -Force
                Write-Output "Deleted $SourceFolder`n"
            }
        }

    }

    if (![string]::IsNullOrEmpty($SourceFolder)) {
        return internaluploadpackages -SourceFolder $SourceFolder -MarkUploadedPackagesWithTags $MarkUploadedPackagesWithTags -DeleteAfterImport $DeleteAfterImport
    }

    if ([string]::IsNullOrEmpty($Project) -and ![string]::IsNullOrEmpty($Info)) {
        Write-XMGRLogMessage -LogMessage "When providing 'Info' provide 'Project' parameter as well or none -  to upload all packages from the import folder." -LogLevel 1 -OnScreen $true
        return 1
    }

    if (![string]::IsNullOrEmpty($Project) -and ![string]::IsNullOrEmpty($Info)) {
        $SourceFolder = join-path -Path (Join-Path -path $Global:SimCorpXMGR.importFolder -ChildPath $Project) -ChildPath $Info
        return internaluploadpackages -SourceFolder $SourceFolder -MarkUploadedPackagesWithTags $MarkUploadedPackagesWithTags -DeleteAfterImport $DeleteAfterImport
    }

    if ([string]::IsNullOrEmpty($Project)) {
        $projectsFolder = (Get-ChildItem -Directory -Path $Global:SimCorpXMGR.importFolder).FullName
        $packagePaths = New-Object System.Collections.Generic.List[string]
        foreach ($ProjectFolder in $projectsFolder) {
            Get-ChildItem -Path $ProjectFolder -Directory -Exclude "Package_Definitions" | foreach { $packagePaths.add($_.FullName) }
        }
        foreach ($packagePath in $packagePaths) {
            internaluploadpackages -SourceFolder $packagePath -MarkUploadedPackagesWithTags $MarkUploadedPackagesWithTags -DeleteAfterImport $DeleteAfterImport
        }

    }

    if (![string]::IsNullOrEmpty($Project)) {
        $ProjectFolder = Join-Path -path $Global:SimCorpXMGR.importFolder -ChildPath $Project
        $packagePaths = (Get-ChildItem -Path $ProjectFolder -Directory -Exclude "Package_Definitions").FullName

        foreach ($packagePath in $packagePaths) {
            internaluploadpackages -SourceFolder $packagePath -MarkUploadedPackagesWithTags $MarkUploadedPackagesWithTags -DeleteAfterImport $DeleteAfterImport
        }
    }
}



<#
.Synopsis

    Lists the packages elligible for import to XMGR. Uploadable packages can be either in XMGR format (42 character name, beginning with V1, no file extension) placed directly in the import folder,or
    packages in human readable folder placed in individual foldres in the import folder

INPUTS: Optional:
                - InPackageFormat. Can display only packages in XMGR format ("Package"), packages in human readable format ("HumanReadable") or all ("All")
                - OutputInJson. Outputs the above lists in JSON format, useful to reliably pass the output to other functions. Turned off by default.

OUTPUTS: Lists of packages according to chosen filter and format
#>
function Get-XMGRUploadablePackages {
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet("Package", "HumanReadable", "All")]
        [String]$InPackageFormat = "All",
        [ValidateSet($True, $False)]
        $OutputInJson = $False

    )

    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand

    $XmgrFormatPackages = Get-Childitem $global:SimCorpXMGR.importFolder | Where-Object { $_.PSIsContainer -eq $false -and $_.Extension -eq "" }
    $HumarReadablePackages = Get-Childitem (join-path $global:SimCorpXMGR.importFolder "HumanReadable") | Where-Object { $_.PSIsContainer -eq $true } | Select-Object -Property Name


    <#
.Synopsis

    Internal function. Lists available uploadable packages in XMGR format

INPUTS: Optional:
                - OutputInJson. Outputs the above lists in JSON format, useful to reliably pass the output to other functions.

OUTPUTS: Lists of packages according to chosen filter
#>
    function output-package {
        param(
            [ValidateSet($True, $False)]
            $OutputInJson = $False
        )

        if ($OutputInJson) {
            write-output $XmgrFormatPackages.name | ConvertTo-Json
        }
        else {
            Write-Host "`n"
            Write-Output "Import folder contains following valid packages in XMGR format:"
            Write-Host "`n"
            if ($XmgrFormatPackages.count -eq 0) { Write-Output "No packages in XMGR format available" }else {
                write-output $XmgrFormatPackages.name
            }
        }
    }


    <#
.Synopsis

    Internal function. Lists available uploadable packages in human readable format

INPUTS: Optional:
                - OutputInJson. Outputs the above lists in JSON format, useful to reliably pass the output to other functions.

OUTPUTS: Lists of packages according to chosen filter
#>
    function output-humanReadable {
        param(
            [ValidateSet($True, $False)]
            $OutputInJson = $False
        )

        if ($OutputInJson) {
            write-output $HumarReadablePackages.name | ConvertTo-Json
        }
        else {
            Write-Output "Import folder contains following human readabale packages:"
            Write-Host "`n"
            if ($HumarReadablePackages.count -eq 0) { Write-Output "No human readable packages available" }else {
                write-output $HumarReadablePackages.name
            }
        }
    }


    if ($InPackageFormat -eq "All") {
        output-package -OutputInJson $OutputInJson
        Write-Output "`n"
        output-humanReadable -OutputInJson $OutputInJson
    }

    if ($InPackageFormat -eq "Package") { output-package -OutputInJson $OutputInJson }
    if ($InPackageFormat -eq "HumanReadable") { output-humanReadable -OutputInJson $OutputInJson }

}

<#
.Synopsis

  Upload packages (exported from another XMGR) to XMGR repository. Packages must be copied to IMPORT folder first. Packages can be in XMGR format (single file, no extension) or in human readable format
  (placed in a folder within the import folder). One can specify the names of the packages ("PackageNamesToImport") or import everything available at once ("importAll") in specific format
  ("InPackageFormat" set to XMGR or Humanreadable) or both at once.
  For permormace and clarity reasons, packages should be marked with at least one Tag ("MarkImportedPackagesWithTags"). If we would like to sign the package on import with the preconfigured XMGR certificate,
  set the "SignWithCertificate" to TRUE.


INPUTS: All inputs are optional:

    - "PackageNamesToImport" a list of package names, when we want to import only specific packages, where many are available.
    - "MarkImportedPackagesWithTags" a list of pakcage tags that we want to mark the imported packages with
    - "DeleteAfterImport" a switch to delete the packages from IMPORT folder after successful import
    - "ImportAll", a switch to import all packages available in IMPORT folder (instead of listing the names)
    - "InPackageFormat" - select the package format you want to use.
    - "SignWithCertificate" - by defaut, packages are not signed with pre-configured certificate on import.

OUTPUTS: Details of each import operation

#>
function Start-XMGRUploadPackagesV2 {
    param(
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $PackageNamesToImport,

        [Parameter(Mandatory = $true)]
        [Collections.Generic.List[String]] $MarkImportedPackagesWithTags,

        [ValidateSet("XMGR", "HumanReadable")]
        [Parameter(Mandatory = $true)]
        [String]$InPackageFormat,

        [ValidateSet($True, $False)]
        $DeleteAfterImport = $False,

        [ValidateSet($True, $False)]
        $ImportAll = $False,


        [ValidateSet($True, $False)]
        $SignWithCertificate = $false
    )


    function Upload-HumanReadablePackages {
        param(

            [Parameter(Mandatory = $false)]
            [Collections.Generic.List[String]] $PackageNamesToImport,

            [Parameter(Mandatory = $False)]
            [Collections.Generic.List[String]] $MarkImportedPackagesWithTags,

            [ValidateSet($True, $False)]
            $DeleteAfterImport = $False,

            [ValidateSet($True, $False)]
            $ImportAll = $False,

            [ValidateSet($True, $False)]
            $SignWithCertificate = $false
        )

        if ($ImportAll) {
            $PackageNamesToImport = Get-XMGRUploadablePackages -InPackageFormat HumanReadable -OutputInJson True | ConvertFrom-Json
        }

        if (![string]::IsNullOrEmpty("$MarkImportedPackagesWithTags")) {
            if ($MarkImportedPackagesWithTags.Count -eq 1) {
                $Tags = $MarkImportedPackagesWithTags | ConvertTo-Json
                $Tags = "[$Tags]"
            }
            else {
                $Tags = $MarkImportedPackagesWithTags | ConvertTo-Json
            }
            $TagsInJSON = '"Tags":' + $Tags
        }



        if ([string]::IsNullOrEmpty($PackageNamesToImport)) {
            Write-Output "No packages selected or available for import"
            break
        }

        $currentDirectory = (Get-Location).Path

        foreach ($packageToImport in $PackageNamesToImport) {

            $PackageFiles = Join-Path -Path $Global:SimCorpXMGR.importFolder -childpath $packageToImport

            $filepath = (New-TemporaryFile).FullName + ".zip"
            $startingLocation = Get-Location

            Set-Location $Global:SimCorpXMGR.importFolder
            #tar -a -cf $filepath -C $PackageFiles *
            Compress-7Zip -ArchiveFileName $filepath -Path $PackageFiles

            Set-location $startingLocation


            $jsonpayload = @"
{
  $TagsInJSON
}
"@

            $Endpoint = "/api/odata/Packages/PackagesService.StoreAndSignPackage"
            $fieldName = 'packageFile'

            Add-Type -AssemblyName System.Net.Http

            $content = New-Object System.Net.Http.MultipartFormDataContent
            $fileStream = [System.IO.File]::OpenRead($filePath)
            $fileName = [System.IO.Path]::GetFileName($filePath)
            $fileContent = New-Object System.Net.Http.StreamContent($fileStream)

            $payloadContent = New-Object System.Net.Http.StringContent $jsonpayload

            $content.Add($fileContent, $fieldName, $fileName)
            $content.Add($payloadContent, 'packageModelWrapper.StorePackageModel')

            if ($SignWithCertificate -eq $false) {
                $Endpoint = "/api/odata/Packages/PackagesService.StorePackage"
            }

            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
            $Request = Connect-ApiCallMultipart $Endpoint $content
            if ($request[-1] -eq 1) {
                $global:SimCorpXMGR.errorReturnValue
                if ($request[-3].length -gt 0) {
                    $request[-3]
                    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
                }
                if ($request[-2].length -gt 0) {
                    $request[-2]
                    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
                }
            }
            else {
                $importConfirmation = $Request
                $importConfirmation
                if ($DeleteAfterImport) {
                    Remove-Item $PackageFiles -Recurse -Force
                }

            }

        }
    }

    function Upload-PackagesInXMGRFormat {
        param(

            [Parameter(Mandatory = $false)]
            [Collections.Generic.List[String]] $PackageNamesToImport,

            [Parameter(Mandatory = $False)]
            [Collections.Generic.List[String]] $MarkImportedPackagesWithTags,

            [ValidateSet($True, $False)]
            $DeleteAfterImport = $False,

            [ValidateSet($True, $False)]
            $ImportAll = $False,

            [ValidateSet($True, $False)]
            $SignWithCertificate = $false
        )

        if ($ImportAll) {
            $PackageNamesToImport = Get-XMGRUploadablePackages -InPackageFormat Package -OutputInJson True | ConvertFrom-Json
        }

        if (![string]::IsNullOrEmpty("$MarkImportedPackagesWithTags")) {
            if ($MarkImportedPackagesWithTags.Count -eq 1) {
                $Tags = $MarkImportedPackagesWithTags | ConvertTo-Json
                $Tags = "[$Tags]"
            }
            else {
                $Tags = $MarkImportedPackagesWithTags | ConvertTo-Json
            }
            $TagsInJSON = '"Tags":' + $Tags
        }



        if ([string]::IsNullOrEmpty($PackageNamesToImport)) {
            Write-Output "No packages selected or available for import"
            break
        }

        foreach ($packageToImport in $PackageNamesToImport) {

            $Filepath = Join-Path -path $global:SimCorpXMGR.importFolder -childpath $packageToImport

            $jsonpayload = @"
{
  $TagsInJSON
}
"@

            $Endpoint = "/api/odata/Packages/PackagesService.StoreAndSignPackage"
            $fieldName = 'packageFile'

            Add-Type -AssemblyName System.Net.Http

            $content = New-Object System.Net.Http.MultipartFormDataContent
            $fileStream = [System.IO.File]::OpenRead($filePath)
            $fileName = [System.IO.Path]::GetFileName($filePath)
            $fileContent = New-Object System.Net.Http.StreamContent($fileStream)

            $payloadContent = New-Object System.Net.Http.StringContent $jsonpayload

            $content.Add($fileContent, $fieldName, $fileName)
            $content.Add($payloadContent, 'packageModelWrapper.StorePackageModel')

            if ($SignWithCertificate -eq $false) {
                $Endpoint = "/api/odata/Packages/PackagesService.StorePackage"
            }

            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
            $Request = Connect-ApiCallMultipart $Endpoint $content
            if ($request[-1] -eq 1) {
                $global:SimCorpXMGR.errorReturnValue
                if ($request[-3].length -gt 0) {
                    $request[-3]
                    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
                }
                if ($request[-2].length -gt 0) {
                    $request[-2]
                    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
                }
            }
            else {
                $importConfirmation = $Request
                Write-Output "Upload of $Filepath successful"

                if ($DeleteAfterImport) {
                    Remove-item $Filepath -Force
                }

            }

        }
    }

    if ($InPackageFormat -eq "XMGR") {
        Upload-PackagesInXMGRFormat -PackageNamesToImport $PackageNamesToImport -MarkImportedPackagesWithTags $MarkImportedPackagesWithTags -DeleteAfterImport $DeleteAfterImport -ImportAll $ImportAll -SignWithCertificate $SignWithCertificate

    }

    if ($InPackageFormat -eq "HumanReadable" ) {
        Upload-HumanReadablePackages -PackageNamesToImport $PackageNamesToImport -MarkImportedPackagesWithTags $MarkImportedPackagesWithTags -DeleteAfterImport $DeleteAfterImport -ImportAll $ImportAll -SignWithCertificate $SignWithCertificate
    }

}

<#
.Synopsis

    Saves the Package Definitons that match the seletion criteria as JSON files.
    Filename is the same as the name of the package definition and it is saved in folder matching the "Project" property, in subfolder "Package_Definitions"

INPUTS: Optional:
        - Name - name of the Package Definiton
        - Project - a project the definition belongs to
        - CreatedBy - ADName of the PackageDefinition creator
        - Info - info section of the Package Definition

OUTPUTS: Details of the download operation or error message
#>
function Start-XMGRDownloadPackageDefinition {
    param(
        [Parameter(Mandatory = $false)]
        [String]$Name,
        [Parameter(Mandatory = $false)]
        [String]$CreatedBy,
        [Parameter(Mandatory = $false)]
        [String] $Project,
        [Parameter(Mandatory = $false)]
        [String] $Info,
        [Parameter(Mandatory = $false)]
        [string] $Destination

    )

    function internaldownloadpackagedefinition {
        param(
            [Parameter(Mandatory = $true)]
            [String]$Name,
            [Parameter(Mandatory = $true)]
            [String]$DestinationFolder
        )

        $Endpoint = "/api/odata/PackageDefinitions('$Name')/Retrieve.PackageDefinition"

        if (!(Test-Path -Path $DestinationFolder)) {
            New-Item -ItemType Directory -Force -Path $DestinationFolder > $null
        }
        $filepath = join-path -Path $DestinationFolder -ChildPath "$Name.json"

        Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
        $request = Connect-XMGRApiCall -Endpoint $Endpoint -Method GET -OutFile $filepath
        if ($request[-1] -eq 1) {
            if ($request[-3].length -gt 0) {
                $request[-3]
                Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
            }
            if ($request[-2].length -gt 0) {
                $request[-2]
                Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
            }
            $global:SimCorpXMGR.errorReturnValue
        }
        else {
            Write-XMGRLogMessage -LogMessage "Downloaded PackageDefinition $Name to $filepath" -LogLevel 0 -OnScreen $true
        }

    }

    <#Get a list of package definitions that match the filtering criteria#>
    $packageDefinitions = Get-XMGRPackageDefinitions -PackageDefinitionName $Name -CreatedBy $CreatedBy -Project $Project -Info $Info

    if (!$packageDefinitions) {
        return Write-Output "No package definitions were selected for download. Check the selection criteria."
    }

    foreach ($packageDefinition in $packageDefinitions) {

        $project = $packagedefinition[0].info.project
        $name = $packagedefinition[0].name
        $destinationFolder = Join-Path -path (Join-Path -path $Global:SimCorpXMGR.exportFolder -ChildPath $Project) -ChildPath "Package_Definitions"

        internaldownloadpackagedefinition -Name $name -DestinationFolder $destinationFolder
    }

}

<#
.Synopsis

    Uploads the JSON files containing downloaded Package Definitions to XMGR repository, based on provided selection criteria.
    File names correspond to Package Definition names. Upload fails if XMGR already contains a Package Definitions with the same name.
    If only Name is provided, than all "Package_Definitions" folders in Import Folder will be searched.
    If Project is provided, then all Package Definitions within it are uploaded.

    One can also import from a specific file, providing a Filepath argument with an absolute path to a single JSON file.
    It overwrites other selection criteria, if provided.


INPUTS: Optional:
        - Name
        - Project
        - Filepath

OUTPUTS: Details of the download operation or error message
#>
function Start-XMGRUploadPackageDefinition {
    param(
        [Parameter(Mandatory = $false)]
        [String]$Name,
        [Parameter(Mandatory = $false)]
        [String] $Project,
        [Parameter(Mandatory = $false)]
        [String]$FilePath
    )

    function internaluploadpackagedefinition {
        param(
            [Parameter(Mandatory = $true)]
            [String]$FilePath
        )

        Add-Type -AssemblyName System.Net.Http

        $Endpoint = "/api/odata/PackageDefinitions/Store.PackageDefinition"

        $multipartBody = New-Object System.Net.Http.MultipartFormDataContent
        $fileStream = [System.IO.File]::OpenRead($filePath)
        $fileName = [System.IO.Path]::GetFileName($filePath)
        $fileContent = New-Object System.Net.Http.StreamContent($fileStream)

        $fieldName = 'packageDefinitionFile'
        $multipartBody.Add($fileContent, $fieldName, $fileName)
        Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
        $Request = Connect-ApiCallMultipart $Endpoint $multipartBody
        if ($request[-1] -eq 1) {
            if ($request[-3].length -gt 0) {
                $request[-3]
                Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
            }
            if ($request[-2].length -gt 0) {
                $request[-2]
                Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
            }
            $global:SimCorpXMGR.errorReturnValue
        }
        else {
            $name = $Request.name
            $details = $Request.info
            Write-Output "Uploaded package definition: $name"
            Write-output "$details `n"


            if ($DeleteAfterImport -eq $true) {
                Remove-Item $filePath -Force
                Write-Output "Deleted $filepath`n"
            }
        }


    }

    if (![string]::IsNullOrEmpty($FilePath)) {
        return internaluploadpackagedefinition -FilePath $FilePath
    }

    if ([string]::IsNullOrEmpty($Name) -and ([string]::IsNullOrEmpty($Project))) {
        return Write-XMGRLogMessage -LogLevel 1 -OnScreen $true -LogMessage "Provide Package Definition selection criteria"

    }

    if (![string]::IsNullOrEmpty($Name) -and ([string]::IsNullOrEmpty($Project))) {
        $fileName = "$name.json"
        $filesWithCorrectName = (Get-ChildItem -Path $Global:SimCorpXMGR.exportFolder -Recurse -filter $fileName | Where-Object -Property FullName -Like  "*\Package_Definitions\$filename").FullName

        if ($filesWithCorrectName.count -gt 1) {
            return Write-XMGRLogMessage -LogLevel 1 -OnScreen $true -LogMessage "Package Definiton name must be unique. Multiple Package Definitions with identical name were found: $filesWithCorrectName"
        }

        if ($filesWithCorrectName.count -eq 0) {
            $importFolder = $Global:SimCorpXMGR.importFolder
            return Write-XMGRLogMessage -LogLevel 1 -OnScreen $true -LogMessage "Package Definition named $name not found in $importFolder and its subfolders"
        }

        Write-XMGRLogMessage -LogMessage "Uploading: $filesWithCorrectName" -OnScreen $true -LogLevel 0
        internaluploadpackagedefinition -FilePath $filesWithCorrectName

    }

    if ([string]::IsNullOrEmpty($Name) -and (![string]::IsNullOrEmpty($Project))) {
        $projectPath = join-path -path (Join-Path -Path $Global:SimCorpXMGR.importFolder -ChildPath $Project) -ChildPath "Package_Definitions"
        $packageDefinitionPaths = (Get-ChildItem -Path $projectPath -Filter "*.json").FullName

        foreach ($packageDefinitionPath in $packageDefinitionPaths) {
            internaluploadpackagedefinition -FilePath $packageDefinitionPath
        }
    }

}

<#
.Synopsis

Made to work in conjunction with Start-XMGRUploadPakcages/Start-XMGRDownloadPackages and Start-XMGRUploadPackageDefinition/Start-XMGRDownloadPackageDefinition.
A preexisiting GIT repository is required and the prompt should be set on its location.
It performs a git pull, parses a changelog and updates the packages and package definitions where any modifications occured.
Packages are marked with a tag "c-commit Id"., old packages are markded as outdated. Old Package Definitions are deleted.

OUTPUTS: Details of the operation

#>
function Sync-XMGRGIT {

    $gitPullLog = git pull

    if ($gitPullLog -eq "Already up to date.") {
        return $gitPullLog
    }

    $log = ($gitPullLog[0].Split(" "))[1]

    $PackageFoldersModified = git diff-tree --diff-filter=M --name-only -t $log | Where-Object { ($_ -notlike "*.json") -and ($_ -notlike "*.xml") -and ($_ -notlike "*.all") -and (($_.split("/")).count -eq 2) -and ($_.split("/")[1] -ne "Package_Definitions") }
    $PackageFoldersDeleted = git diff-tree --diff-filter=D --name-only -t $log | Where-Object { ($_ -notlike "*.json") -and ($_ -notlike "*.xml") -and ($_ -notlike "*.all") -and (($_.split("/")).count -eq 2) -and ($_.split("/")[1] -ne "Package_Definitions") }

    $PackageDefinitionsDeleted = git diff-tree --diff-filter=D --name-only -t $log | Where-Object { (($_.split("/"))[1] -eq "Package_Definitions") -and $_ -like "*.json" }
    $PackageDefinitionsModified = git diff --diff-filter=MRAC --name-only  $log | Where-Object { (($_.split("/"))[1] -eq "Package_Definitions") -and $_ -like "*.json" }

    foreach ($deletedDefinition in $PackageDefinitionsDeleted) {

        $PackageDefinitionName = ($deletedDefinition.split("/")[-1]).split(".")[0]
        Write-Output "Deleted $deletedDefinition`n"
        Remove-XMGRPackageDefinition -PackageDefinitionName $PackageDefinitionName
    }

    foreach ($modifiedDefinition in $PackageDefinitionsModified) {
        $PackageDefinitionName = ($modifiedDefinition.split("/")[-1]).split(".")[0]
        Write-Output "Modified $modifiedDefinition`n"
        Remove-XMGRPackageDefinition -PackageDefinitionName $PackageDefinitionName > $null
        Start-XMGRUploadPackageDefinition -FilePath $modifiedDefinition

    }

    foreach ($modifiedPackage in $PackageFoldersModified) {
        $project = $modifiedPackage.split("/")[0]
        $info = $modifiedPackage.split("/")[1]

        $tag = "c-" + ($gitPullLog[0].Split(" ")[1]).split("..")[-1]

        $obsoletePackages = internalgetfilteredhashes -Project $project -Info $info
        Write-Output "Modified $modifiedPackage"
        $upload = Start-XMGRUploadPackages -Project $project -Info $info -MarkUploadedPackagesWithTags $tag

        if ($upload[-1] -ne 1) {
            $upload
            if ($obsoletePackages.Count -ge 1) {
                Write-Output "Previous versions of uploaded packages were tagged as obsolete:`n"
                Add-XMGRTagsToPackages -MarkWithSystemTag Outdated -PackagesWithHashes $obsoletePackages
            }
        }
        else {
            $upload
        }

    }

    foreach ($deletedPackage in $PackageFoldersDeleted) {

        $project = $deletedPackage.split("/")[0]
        $info = $deletedPackage.split("/")[1]
        Write-Output "Deleted package: $project\$info`n"
        $obsoletePackages = internalgetfilteredhashes -Project $project -Info $info

        if ($obsoletePackages.count -ge 1) {
            Write-Output "Tagging all existing versions of the package as obsolete:"
            Add-XMGRTagsToPackages -MarkWithSystemTag Outdated -PackagesWithHashes $obsoletePackages
        }
        else {
            Write-Output "No active version of the package is present in XMGR repository"

        }
    }
}

#endregion

<#============================================= Entities Rename ======================================#>
#region

<#
.Synopsis

    Rename a list of entities (replacing the actual key with the given one) of one or more Installations/InstallationGroups

INPUTS: 
    -Mandatory: -Entities, a list of entities build in a list of list of 3 strings. The first item of each list of string is the actual entity type, the second one is the actual key of the Entity meanwhile the last one is the new Entity key that will be use for the rename.
                    For example: (("BATCHJOBGRPS","BATCH1","BATCH1NEWKEY"),("BATCHJOBS","JOB1","JOB1NewName"))
                    In this case the function will look for the Entity with Type BATCHJOBGRPS and key BATCH1 renaming the key from BATCH1 to BATCH1NEWKEY.
                    It will also do the same for the other Entity listed: look for the Entity with Type BATCHJOBS and key JOB1 renaming the key from BATCH1 to JOB1NewName.

    -Optional: -TargetInstallationIds, The list of installation IDs where the function will look for entities. For Example ("InstallationA") or ("InstallationB","InstallationC")
    -Optional: -TargetInstallationGroupIds, The list of installation Group IDs where the function will look for entities. For Example ("GroupA") or ("GroupB","GroupC")

                Note that atleast a Installation ID or Installation group need to be provided

OUTPUTS: The details of the operations.

#>

function Start-XMGREntitiesRename{
    param(
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $TargetInstallationIds,
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $TargetInstallationGroupIds,
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Entities
    )

    <# Checking if atleast and installation or Installation group has been provided #>
    if([String]::IsNullOrEmpty($TargetInstallationIds) -and [String]::IsNullOrEmpty($TargetInstallationGroupIds)){
        $global:SimCorpXMGR.errorReturnValue 
        return Write-XMGRLogMessage -LogLevel 2 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage "Atleast an installation or installation group must be inserted"
    }

    <#Parsin JSON Payload for Installations#>
    if (![String]::IsNullOrEmpty($TargetInstallationIds)) {
        if ($TargetInstallationIds.Count -eq 1) {
            $i = $TargetInstallationIds | ConvertTo-Json
            $i = "[$i]"
        }
        else {
            $i = $TargetInstallationIds | ConvertTo-Json
        }
        $installations = '"TargetInstallations":' + $i + ","
    }

    <#Parsin JSON Payload for Installation groups#>
    if (![String]::IsNullOrEmpty($TargetInstallationGroupIds)) {
        if ($TargetInstallationGroupIds.Count -eq 1) {
            $g = $TargetInstallationGroupIds | ConvertTo-Json
            $g = "[$g]"
        }
        else {
            $g = $TargetInstallationGroupIds | ConvertTo-Json
        }
        $installationGroups = '"TargetInstallationGroups":' + $g + ","
    }

    <#The usual input for Entities should be an arraylist of lists. However, if an arraylist with single list is passed in (a single Attribute List), it gets autocasted into a list of strings, which causes an error. The below codeblock handles this case:#>
    $EntitiesArray = New-Object System.Collections.ArrayList
    if($Entities[0].GetType().Name -eq "String"){   
        $null = ($EntitiesArray.Add($Entities))
    }else{
        $EntitiesArray = $Entities
    }

    <# Parsing input strings to define EntitiesList objects 
       The object required from APIs is componed by a list of Entities, where each Entity has it's own Type (First element in input string list), it's own key (Second element in input string list) and the new key (Last element in input string)
    #>
    $EntitiesList = New-Object System.Collections.ArrayList
    foreach($Entity in $EntitiesArray){
        
        if($Entity.count -eq 3){

            $EntityObject = [PSCustomObject]@{
                Type     = $Entity[0]
                Key      = $Entity[1]  
            }
            $EntityWithNewKey= [PSCustomObject]@{
                Entity     = $EntityObject
                NewKey      = $Entity[2]  
            }

            $null = $EntitiesList.Add($EntityWithNewKey)

        }else{
            $global:SimCorpXMGR.errorReturnValue
            return Write-XMGRLogMessage -LogLevel 2 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage "Entity must have 3 values, Entity Type, Entity Key and new Entity Key. Given are $Entity"

        }
    
    
    }

    #compining Entities Json Payload
    $EntitiesJSON = $EntitiesList | ConvertTo-Json
    if($EntitiesList.Count -eq 1){
    
        $EntitiesJSON="[$EntitiesJSON]"

    }

    #Building JSON Payload for APIs call
    $jsonpayload = @"
{
$installations
$installationGroups
"Entities": $EntitiesJSON
}
"@
    
    $Endpoint = "/api/odata/Operations/Start.Rename"

    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCallPOST $Endpoint $jsonpayload
    if ($request[-1] -eq 1) {
        $global:SimCorpXMGR.errorReturnValue
        if ($request[-3].length -gt 0) {
            $request[-3]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-3]
        }
        if ($request[-2].length -gt 0) {
            $request[-2]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $request[-2]
        }
    }
    else {
        <#It takes some time for the operation to complete. The script checks every 1 second with a timout of 5 minutes#>
        $counter = 300
        while ($counter -gt 0) {

            $operationDetails = Get-XMGROperationdetails $request.OperationId

            <#If Operation is complete, show result#>
            if ($operationDetails.StatusText -eq "Completed") {
                Write-Output $request.OperationId
                $operationDetails.actions
                <#If Completed but with errors, show the errors#>
                if ($operationDetails.result.ExportErrorDetails) {
                    $operationDetails.result.ExportErrorDetails
                }
                break
            }

            <#If CompletedwithWarnings, show details#>
            if ($operationDetails.StatusText -in ("CompletedWithWarnings", "CompletedPartially")) {
                Write-Output $request.OperationId
                $operationDetails.actions
                <#Show the errors#>
                if ($operationDetails.actions.result.ExportErrorDetails) {
                    if (($operationDetails.actions.Result.ExportErrorDetails.LargeObjectId).Length -gt 10) {
                                    (Get-XMGRLargeObject -ObjectId $operationDetails.actions.Result.ExportErrorDetails.LargeObjectId).ExportedEntityResults
                    }
                    else {
                        $operationDetails.actions.result.ExportErrorDetails
                        $operationDetails.actions.Warnings
                    }
                }
                break
            }
            <#If operation failed, show why#>
            if ($operationDetails.StatusText -eq "Failed") {
                $global:SimCorpXMGR.errorReturnValue
                Write-Output $request.OperationId
                $operationDetails.actions.error
                break
            }
            start-Sleep -s 2
            $counter = $counter - 2
        }
        if($counter -lt 0){
        
            $global:SimCorpXMGR.errorReturnValue
            Write-Output $request.OperationId
            Write-Output $operationDetails.actions
            Write-Output "Operation Timeout"
        } 
    }

}

#endregion

Export-ModuleMember -Function *-*