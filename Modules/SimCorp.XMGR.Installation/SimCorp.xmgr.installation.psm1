Write-Host "Loading module: SimCorp.XMGR.Installation" -ForegroundColor green

<#============================================= General Functions====================================================#>
<#
.Synopsis

   Displays all alerts from a specific installation.

INPUTS: a single InstallationId

OUTPUTS: A list of alerts from the Service Platform or an error message, if something went wrong.
#>
function Get-XMGRAlerts {
    param(
        [Parameter(Mandatory = $true)]
        [String] $InstallationId

    )
    $Endpoint = "/api/odata/Installations('$InstallationId')/Get.Alerts"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCall $Endpoint "GET"

    if ($request[-1] -eq 1) {
        $request[-3]
        $request[-2]
        1
    }
    else {
        $request.payload
    }
}

<#
.Synopsis

   Displays the current Dependency Model used by the Service Platform of the requested installation.

INPUTS: a single InstallationId

OUTPUTS: A current Dependency MOdel the Service Platform or an error message, if something went wrong.
#>
function Get-XMGRDependencyModel {
    param(
        [Parameter(Mandatory = $true)]
        [String] $InstallationId

    )
    $Endpoint = "/api/odata/Installations('$InstallationId')/Get.DependencyModel"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCall $Endpoint "GET"

    if ($request[-1] -eq 1) {
        $request[-3]
        $request[-2]
        1
    }
    else {
        $dependencyModel = $request.DependencyModelName
        $dependencyModel

    }
}

<#
.Synopsis

   Displays the list of available Dependency Models for the requested installation.

INPUTS: a single InstallationId

OUTPUTS: The list of available models in Service Platform or an error message, if something went wrong.
#>

function Get-XMGRAvailableDependencyModels {
    param(
        [Parameter(Mandatory = $true)]
        [String] $InstallationId
    )

    $Endpoint = "/api/odata/Installations('$InstallationId')/Get.AvailableServicePlatformDependencyModels"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCall $Endpoint "GET"
    
    if ($request[-1] -eq 1) {
        $request[-3]
        $request[-2]
        1
    }
    else {
        $dependencyModels = ($request.value).DependencyModelName
        $dependencyModels
    }
}

<#
.Synopsis

   Displays the status of Service Platform for the requested installation.

INPUTS: a single InstallationId

OUTPUTS: The list of parameters used to check the Service Platform status or an error message, if something went wrong.
#>
function Get-XMGRServicePlatformStatus {
    param(
        [Parameter(Mandatory = $true)]
        [String] $InstallationId
    )

    $Endpoint = "/api/odata/Installations('$InstallationId')/Get.ServicePlatformStatus"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCall $Endpoint "GET"
    
    if ($request[-1] -eq 1) {
        $request[-3]
        $request[-2]
        1
    }
    else {
        $PlatformStatus = $request | Select-Object -Property * -ExcludeProperty "@odata.context"
        $PlatformStatus
    }
}
    
<#
.Synopsis
   Set the Service Platform of the requested installation to use the given DependencyModel if available.

INPUTS: a single InstallationId and the Service Platform model name

OUTPUTS: An error message, if something went wrong.

NOTE: Any changes to the dependency model are applied in Maintenance mode. 
If the SimCorp Dimension installation is not in Maintenance mode, this is applied automatically and the Service Platform is reverted to Production mode after the dependency model changes have been applied.

#>
function Set-XMGRDependencyModel {
    param(
        [Parameter(Mandatory = $true)]
        [String] $InstallationId,
        [Parameter(Mandatory = $true)]
        [String] $ServicePlatformModelName

    )

    $jsonpayload = @"
{
  "DependencyModelName": "$ServicePlatformModelName"
}
"@

    $Endpoint = "/api/odata/Installations('$InstallationId')/Set.ServicePlatformDependencyModel"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCallPOST $Endpoint $jsonpayload

    if ($request[-1] -eq 1) {
        $request[-3]
        $request[-2]
        1
    }
    else {
        $request
    }
}

<#
.Synopsis

   Sets a parameter containing a path to the SimCorp Update Package to one or more Installations and/or Installation Groups.

INPUTS: Mandatory:
    - at least one installationId or InstallationGroupId
    - UNC path for "UpdatePackageLocation"

OUTPUTS: COnfirmation or error message.
#>
function Set-XMGRUpdatePackageLocation {
    param(
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $InstallationIds,
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $InstallationGroupIds,
        [Parameter(Mandatory = $true)]
        [String] $UpdatePackageLocation
    )

    if ([string]::IsNullOrEmpty($InstallationIds) -and [string]::IsNullOrEmpty($InstallationGroupIds) ) {
        Write-XMGRLogMessage -LogLevel 1 -LogMessage "At least one instalaltionId or installation group is requied" -OnScreen $true
        return 1
    }

    if (![string]::IsNullOrEmpty($InstallationIds)) {
        $InstallationIds = $InstallationIds -replace '^.*$', '"$&"' -join ","

        $targetinstallations = @"

  "TargetInstallations": [
    $InstallationIds
  ],

"@


    }

    if (![string]::IsNullOrEmpty($InstallationGroupIds)) {
        $InstallationGroupIds = $InstallationGroupIds -replace '^.*$', '"$&"' -join ","

        $TargetInstallationGroups = @"

 "TargetInstallationGroups": [
    $InstallationGroupIds
  ]

"@


    }

    $UpdatePackageLocation = $UpdatePackageLocation | ConvertTo-Json

    $jsonpayload = @"
{

  "UpdatePackageLocation": $UpdatePackageLocation,
  $targetinstallations
  $TargetInstallationGroups

}
"@



    $apiaddress = "/api/odata/Operations/Set.UpdatePackageLocation"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCallPOST $apiaddress $jsonpayload
    if ($request[-1] -eq 1) {
        $request[-3]
        $request[-2]
        1
    }
    else {
        <#It takes some time for the operation to complete. The script checks every 1 second#>
        $counter = 120
        while ($counter -gt 0) {

            $operationDetails = Get-XMGROperationDetails $request.OperationId
            $operationDetails.StatusText

            <#If Operation is complete, show result#>
            if ($operationDetails.StatusText -eq "Completed") {
                $operationDetails.actions
                $operationDetails.Actions.result.SetUpdatePackageLocationResult
                if ($operationDetails.Actions.result.SetUpdatePackageLocationResult.status -eq "Error") { return 1 }
                break

            }

            <#If CompletedwithWarnings, show details#>
            if ($operationDetails.StatusText -eq "CompletedWithWarnings") {
                $operationDetails.actions
                $operationDetails.actions.warnings
                $operationDetails.Actions.result.SetUpdatePackageLocationResult
                break
            }


            <#If failed, show why#>
            if ($operationDetails.StatusText -eq "Failed") {
                $operationDetails.actions.error
                return 1

            }
            start-Sleep -s 1
            $counter = $counter - 1
        }
    }


}

<#
.Synopsis

   Displays overall statistics of message queues with statuses that are available on the given installation.

INPUTS: a single InstallationId
    OPTIONAL: MessageQueueFilterName, the message queue name that you are looking for, this will display onli Message Queues with given name (if any)
              MessageQueueFilterStatus, the message queue status that you are looking for, this will display onli Message Queues with given status (if any)

OUTPUTS: The list of message queues with relative informations or an error message, if something went wrong.
#>
function Get-XMGRMessageQueues {
    param(
        [Parameter(Mandatory = $true)]
        [String] $InstallationId,
        [Parameter(Mandatory = $false)]
        [String] $MessageQueueFilterName,
        [Parameter(Mandatory = $false)]
        [String] $MessageQueueFilterStatus
    )
    $Endpoint = "/api/odata/Installations('$InstallationId')/Get.MessageQueues"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCall $Endpoint "GET"

    if ($request[-1] -eq 1) {
        $request[-3]
        $request[-2]
        1
    }
    else {

        $FilterName="*"
        $FilterStatus="*" 

        if (![string]::IsNullOrEmpty($MessageQueueFilterName)) { $FilterName = $MessageQueueFilterName }
        if (![string]::IsNullOrEmpty($MessageQueueFilterStatus)) { $FilterStatus = $MessageQueueFilterStatus }
        
        $request.value | Where-Object { $_.MessageQueue -like $FilterName -and $_.MessageStatus -like $FilterStatus}
        
    }
}

<#
.Synopsis

   Starts a Check-Before-Update procedure for one or multiple SCD installations.

INPUTS: Mandatory:
    - at least one installationId or InstallationGroupId

OUTPUTS: CBU results per installation can be seen in SCD Portal in the usual Window.
#>
function Start-XMGRPerformCBU {
    param(
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $InstallationIds,
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $InstallationGroupIds

    )

    if ([string]::IsNullOrEmpty($InstallationIds) -and [string]::IsNullOrEmpty($InstallationGroupIds) ) {
        Write-XMGRLogMessage -LogLevel 1 -LogMessage "At least one instalaltionId or installation group is requied" -OnScreen $true
        return 1
    }

    if (![string]::IsNullOrEmpty($InstallationIds)) {
        $InstallationIds = $InstallationIds -replace '^.*$', '"$&"' -join ","

        $targetinstallations = @"

  "TargetInstallations": [
    $InstallationIds
  ],

"@


    }

    if (![string]::IsNullOrEmpty($InstallationGroupIds)) {
        $InstallationGroupIds = $InstallationGroupIds -replace '^.*$', '"$&"' -join ","

        $TargetInstallationGroups = @"

 "TargetInstallationGroups": [
    $InstallationGroupIds
  ]

"@


    }



    $jsonpayload = @"
{
  $targetinstallations
  $TargetInstallationGroups
}
"@



    $apiaddress = "/api/odata/Operations/Start.PerformCbu"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCallPOST $apiaddress $jsonpayload
    if ($request[-1] -eq 1) {
        $request[-3]
        $request[-2]
        1
    }
    else {
        Get-XMGROperationDetails $request.OperationId
    }


}

<#
.Synopsis

   Initiates Edge Service restart for one installation. This request initiates a restart of all Edge service instances for installation. 
   WARNING: restarting the Edge Services will interrupt all other running commands that utilize them

INPUTS: Mandatory:
    - a single installationId

OUTPUTS: An error if any. The operation returns success as soon as restart is initiated and does not verify any completion.

#>
function Start-XMGRRestartEdgeService {
    param(
        [Parameter(Mandatory = $true)]
        [Collections.Generic.List[String]] $InstallationId

    )

    $apiaddress = "/api/odata/Installations('$InstallationId')/Restart.EdgeService"

    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCallPOST $apiaddress " "

    if ($request[-1] -eq 1) {
          $request[-3]
          $request[-2]
          1
      }
      else {
          $request
      } 
}

<#============================================= Operations with Database User Schema ====================================================#>


<#
.Synopsis

   Set a the given password for the given Database User Schema in the provided installation.

INPUTS: a single InstallationId, a single Database User Schema and the password for the schema

OUTPUTS: An error message, if something went wrong.
#>
function Set-XMGRDatabaseUserSchemaPassword {
    param(
        [Parameter(Mandatory = $true)]
        [String] $InstallationId,
        [Parameter(Mandatory = $true)]
        [String] $DatabaseUserSchemaName,
        [Parameter(Mandatory = $true)]
        [String] $DatabaseUserSchemaPassword
    )

    $jsonpayload=@"
{

  "Schema": "$DatabaseUserSchemaName",
  "Password": "$DatabaseUserSchemaPassword"

}
"@

    $Endpoint = "/api/odata/Installations('$InstallationId')/Set.DatabaseUserSchemaPassword"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCallPOST $Endpoint $jsonpayload
    
     if ($request[-1] -eq 1) {
        $request[-3]
        $request[-2]
        1
    }
    else {
        $request 
    }
}

<#
.Synopsis
   Displays a list of Database User Schemas for the given installation.

INPUTS: a single InstallationId

OUTPUTS: A list of Database User Schemas or an error message, if something went wrong.
#>
function Get-XMGRDatabaseUserSchemas {
    param(
        [Parameter(Mandatory = $true)]
        [String] $InstallationId
    )
    
    $Endpoint = "/api/odata/Installations('$InstallationId')/Get.DatabaseUserSchemas"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCall $Endpoint "GET"
    
    if ($request[-1] -eq 1) {
        $request[-3]
        $request[-2]
        1
    }
    else {
         $request | Select-Object -Property * -ExcludeProperty '@odata.context'
    }
}

<#
.Synopsis

   Display the result of the validation with a boolean that indicate if the Database User Schema is valid or not.

INPUTS: a single InstallationId, a single Database User Schema and the password for the schema

OUTPUTS: The result of the validation with a boolean output or an error message, if something went wrong.
#>
function Start-XMGRVerifyDatabaseUserSchema {
    param(
        [Parameter(Mandatory = $true)]
        [String] $InstallationId,
        [Parameter(Mandatory = $true)]
        [String] $DatabaseUserSchemaName
    )

    $jsonpayload=@"
{
  "schema": "$DatabaseUserSchemaName"
}
"@

    $Endpoint = "/api/odata/Installations('$InstallationId')/Verify.DatabaseUserSchema?schema=$DatabaseUserSchemaName"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCall $Endpoint "GET"

    if ($request[-1] -eq 1) {
        $request[-3]
        $request[-2]
        1
    }
    else {
        $request.ok
    }

}


<#============================================= Operations Bring installation online/down ====================================================#>

<#
.Synopsis

   Start bring installation down operation - will stop the MUCS and Service Agents

INPUTS: Mandatory:
    - at least one installationId or InstallationGroupId

OUTPUTS: Status "Completed", if successful. Error message, if not.
#>
function Start-XMGRBringInstallationDown {
    param(
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $InstallationIds,
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $InstallationGroupIds
    )

    if ([string]::IsNullOrEmpty($InstallationIds) -and [string]::IsNullOrEmpty($InstallationGroupIds) ) {
        Write-XMGRLogMessage -LogLevel 1 -LogMessage "At least one instalaltionId or installation group is requied" -OnScreen $true
        return 1
    }

    if (![string]::IsNullOrEmpty($InstallationIds)) {
        if ($InstallationIds.Count -eq 1) {
            $d = $InstallationIds | ConvertTo-Json
            $c = "[$d]"
        }
        else {
            $c = $InstallationIds | ConvertTo-Json
        }
        $targetInstallations = "TargetInstallations" + ":" + " " + $c
    }

    if (![string]::IsNullOrEmpty($InstallationGroupIds)) {
        if ($InstallationGroupIds.Count -eq 1) {
            $e = $InstallationGroupIds | ConvertTo-Json
            $b = "[$e]"
        }
        else {
            $b = $InstallationGroupIds | ConvertTo-Json
        }
        $targetInstallationGroups = "TargetInstallationGroups" + ":" + " " + $b
        if (![string]::IsNullOrEmpty($InstallationIds)) { $targetInstallationGroups = $targetInstallationGroups + "," }
    }

    $jsonpayload = @"
{
$targetInstallationGroups
$targetInstallations
}
"@

    $Endpoint = "/api/odata/Operations/Start.BringInstallationDown"

    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCallPOST $Endpoint $jsonpayload
    if ($request[-1] -eq 1) {
        $request[-3]
        $request[-2]
        1
    }
    else {
        while ($true) {
            $operationDetails = Get-XMGROperationDetails $request.OperationId
            $operationDetails.StatusText

            if ($operationDetails.StatusText -ne "InProgress") {
                $operationDetails.actions.result.BringInstallationDownResult.Messages
                break
            }
            start-Sleep -s 1
        }
    }
}

<#
.Synopsis

    Start bring installation online operation - starts MUSC and Service Agents

INPUTS: Mandatory:
    - at least one installationId or InstallationGroupId

OUTPUTS: Status "Completed", if successful. Error message, if not
#>
function Start-XMGRBringInstallationOnline {
    param(
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $InstallationIds,
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $InstallationGroupIds
    )

    if ([string]::IsNullOrEmpty($InstallationIds) -and [string]::IsNullOrEmpty($InstallationGroupIds) ) {
        Write-XMGRLogMessage -LogLevel 1 -LogMessage "At least one instalaltionId or installation group is requied" -OnScreen $true
        return 1
    }

    if (![string]::IsNullOrEmpty($InstallationIds)) {
        if ($InstallationIds.Count -eq 1) {
            $d = $InstallationIds | ConvertTo-Json
            $c = "[$d]"
        }
        else {
            $c = $InstallationIds | ConvertTo-Json
        }
        $targetInstallations = "TargetInstallations" + ":" + " " + $c
    }

    if (![string]::IsNullOrEmpty($InstallationGroupIds)) {
        if ($InstallationGroupIds.Count -eq 1) {
            $e = $InstallationGroupIds | ConvertTo-Json
            $b = "[$e]"
        }
        else {
            $b = $InstallationGroupIds | ConvertTo-Json
        }
        $targetInstallationGroups = "TargetInstallationGroups" + ":" + " " + $b
        if (![string]::IsNullOrEmpty($InstallationIds)) { $targetInstallationGroups = $targetInstallationGroups + "," }
    }

    $jsonpayload = @"
{
$targetInstallationGroups
$targetInstallations
}
"@

    $Endpoint = "/api/odata/Operations/Start.BringInstallationOnline"

    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCallPOST $Endpoint $jsonpayload
    if ($request[-1] -eq 1) {
        $request[-3]
        $request[-2]
        1
    }
    else {
        while ($true) {
            $operationDetails = Get-XMGROperationDetails $request.OperationId
            $operationDetails.StatusText

            if ($operationDetails.StatusText -ne "InProgress") {

                $operationDetails.actions.result.BringInstallationOnlineResult.Messages
                break
            }
            start-Sleep -s 1
        }
    }
}

<#============================================= Installations Credentials Configuration ====================================================#>
<#
.Synopsis

    Adds SCD installation credentials to XMGR register.

INPUTS: CredentialsJsonPath - path to a file with credentials to add

OUTPUTS: OK result - if added successfully, error - if something goes wrong

Example:
Add-InstallationCredentials -CredentialsJsonPath PayloadTemplates\InstallationCredentials.json
#>
function Add-XMGRInstallationCredentials {
    param(
        [Parameter(Mandatory = $true)]
        [String] $CredentialsJsonPath
    )
    $Endpoint = "/api/odata/InstallationsCredentials"
    $jsonpayload = Get-Content $CredentialsJsonPath | Out-String
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCallPOST $Endpoint $jsonpayload
    if ($request[-1] -eq 1) {
        $request
        1
    }
    else {
        $request
    }
}

<#
.Synopsis

    Lists all the installations credentials currently available in XMGR register.

INPUTS: NONE

OUTPUTS: An arraylist with Installations credentials and their details. None if no installations are found in XMGR register. Will not list the passwords.

Example:
Get-InstallationsCredentials
#>
function Get-XMGRInstallationsCredentials {
    $Endpoint = "/api/odata/InstallationsCredentials"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $t = Connect-XMGRApiCall $Endpoint "GET"
    if ($t[-1] -eq 1) {
        $t[-2]
        1
    }
    else {
        $t.value
    }
}

<#
.Synopsis

    Removes installation credentials from XMGR register.

INPUTS: name of the installation

OUTPUTS: none if successful, error message if no given InstallationId was found
#>
function Remove-XMGRInstallationCredentials {
    param(
        [Parameter(Mandatory = $true)]
        [String] $InstallationId
    )
    $apiaddress = "/api/odata/InstallationsCredentials"
    $Endpoint = $apiaddress + "('$InstallationId')"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $t = Connect-XMGRApiCall $Endpoint "DELETE"
    if ($t[-1] -eq 1) {
        $t[-3]
        $t[-2]
        1
    }
    else {
        Write-XMGRLogMessage -LogLevel 0 -OnScreen $true -LogMessage "Credentials for $InstallationId deleted"

    }
}

<#============================================= Operations Open/Close installations for normal users ====================================================#>

<#
.Synopsis

   Start "open installation for normal users" operation. Normal users will be allowed to log in to SCD.

INPUTS: A list of InstallationIds or/and InstallationGroupIds - at least one installation is required.

OUTPUTS: Result of operation or an error message


#>
function Open-XMGRInstallationsForNormalUsers {
    param(
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $InstallationIds,
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $InstallationGroupIds
    )

    if ([string]::IsNullOrEmpty($InstallationIds) -and [string]::IsNullOrEmpty($InstallationGroupIds) ) {
        Write-XMGRLogMessage -LogLevel 1 -LogMessage "At least one instalaltionId or installation group is requied" -OnScreen $true
        return 1
    }

    if (![string]::IsNullOrEmpty($InstallationIds)) {
        if ($InstallationIds.Count -eq 1) {
            $d = $InstallationIds | ConvertTo-Json
            $c = "[$d]"
        }
        else {
            $c = $InstallationIds | ConvertTo-Json
        }
        $targetInstallations = "TargetInstallations" + ":" + " " + $c
    }

    if (![string]::IsNullOrEmpty($InstallationGroupIds)) {
        if ($InstallationGroupIds.Count -eq 1) {
            $e = $InstallationGroupIds | ConvertTo-Json
            $b = "[$e]"
        }
        else {
            $b = $InstallationGroupIds | ConvertTo-Json
        }
        $targetInstallationGroups = "TargetInstallationGroups" + ":" + " " + $b
        if (![string]::IsNullOrEmpty($InstallationIds)) { $targetInstallationGroups = $targetInstallationGroups + "," }
    }

    $jsonpayload = @"
{
$targetInstallationGroups
$targetInstallations
}
"@


    $Endpoint = "/api/odata/Operations/Open.InstallationsForNormalUsers"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCallPOST $Endpoint $jsonpayload
    if ($request[-1] -eq 1) {
        $request[-3]
        $request[-2]
        1
    }
    else {
        while ($true) {
            $operationDetails = Get-XMGROperationDetails $request.OperationId
            $operationDetails.StatusText

            if ($operationDetails.StatusText -ne "InProgress") {
                $operationDetails.actions.result.OpenInstallationsForNormalUsersResult
                break
            }
            start-Sleep -s 1
        }
    }
}

<#
.Synopsis

   Closes the passed-in installation for normal users. They will be forcefully logged-out and will not be able to log back in, until the installation is not opened for normal users.

INPUTS: Mandatory:
        - A list of InstallationIds or/and InstallationGroupIds - at least one installation is required.
        - CloseInstallationsReasonMessage: The message thet will be displayed to users as a pop-up warning/explanation.
        Optional: A number of seconds the users have to finish and save their work ("LogoutInterval") - 45 seconds by default.
OUTPUTS: Result of operation or an error message


#>
function Close-XMGRInstallationsForNormalUsers {
    param(
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $InstallationIds,
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $InstallationGroupIds,
        [Parameter(Mandatory = $false)]
        [int] $LogoutInterval = 45,
        [Parameter(Mandatory = $True)]
        [String] $CloseInstallationsReasonMessage
    )

    if ([string]::IsNullOrEmpty($InstallationIds) -and [string]::IsNullOrEmpty($InstallationGroupIds) ) {
        Write-XMGRLogMessage -LogLevel 1 -LogMessage "At least one instalaltionId or installation group is requied" -OnScreen $true
        return 1
    }

    if (![string]::IsNullOrEmpty($InstallationIds)) {
        $allInstallationDetails = New-Object System.Collections.ArrayList

        foreach ($Installation in $InstallationIds) {
            $content = @"
{
"Id": "$Installation",
"LogoutInterval": $LogoutInterval
}
"@
            $null = $allInstallationDetails.Add($content)
        }

        $allInstallationDetails = $allInstallationDetails -join ","
        $targetInstallations = "TargetInstallations" + ":" + "[$allInstallationDetails]"
    }

    if (![string]::IsNullOrEmpty($InstallationGroupIds)) {
        $allInstallationGroupDetails = New-Object System.Collections.ArrayList

        foreach ($Installationgroup in $InstallationGroupIds) {
            $content = @"
{
"Id": "$Installationgroup",
"LogoutInterval": $LogoutInterval
}
"@
            $null = $allInstallationGroupDetails.Add($content)
        }

        $allInstallationGroupDetails = $allInstallationGroupDetails -join ","
        $targetInstallationGroups = "TargetInstallationGroups" + ":" + "[$allInstallationGroupDetails]"

        if (![string]::IsNullOrEmpty($InstallationIds)) { $targetInstallationGroups = $targetInstallationGroups + "," }
    }

    $jsonpayload = @"
{
"CloseInstallationsReasonMessage": "$CloseInstallationsReasonMessage",
$targetInstallationGroups
$targetInstallations
}
"@


    $Endpoint = "/api/odata/Operations/Close.InstallationsForNormalUsers"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCallPOST $Endpoint $jsonpayload
    if ($request[-1] -eq 1) {
        $request[-3]
        $request[-2]
        1
    }
    else {
        while ($true) {
            $operationDetails = Get-XMGROperationDetails $request.OperationId
            $operationDetails.StatusText

            if ($operationDetails.StatusText -ne "InProgress") {
                $operationDetails.actions.result.CloseInstallationsForNormalUsersResult.Messages
                break
            }

            if ($operationDetails.StatusText -eq "Failed") {
                $operationDetails.actions.result
                break
            }

            start-Sleep -s 1
        }
    }
}

<#
.Synopsis

    Updates the INS file of the SCD installations and updates the installations accordingly. Might take from a few few minutes to multiple hours. Recommended running in a separate PowerShell thread.

INPUTS:
		-- InstallationFilePath (path to installation file with ".ini" extension);
		-- A list of InstallationIds oo/and InstallationGroupIds - at least one installation is required.
OUTPUTS: OK result - if executed successfully, error - if something went wrong
#>
function Start-XMGRUpdateInstallationFile {
    param(
        [Parameter(Mandatory = $true)]
        [String] $InstallationFilePath,
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $InstallationIds,
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $InstallationGroupIds
    )


    if ([string]::IsNullOrEmpty($InstallationIds) -and [string]::IsNullOrEmpty($InstallationGroupIds) ) {
        Write-XMGRLogMessage -LogLevel 1 -LogMessage "At least one instalaltionId or installation group is requied" -OnScreen $true
        return 1
    }

    if (![string]::IsNullOrEmpty($InstallationIds)) {
        if ($InstallationIds.Count -eq 1) {
            $d = $InstallationIds | ConvertTo-Json
            $c = "[$d]"
        }
        else {
            $c = $InstallationIds | ConvertTo-Json
        }
        $targetInstallations = '"TargetInstallations"' + ":" + " " + $c
    }

    if (![string]::IsNullOrEmpty($InstallationGroupIds)) {
        if ($InstallationGroupIds.Count -eq 1) {
            $e = $InstallationGroupIds | ConvertTo-Json
            $b = "[$e]"
        }
        else {
            $b = $InstallationGroupIds | ConvertTo-Json
        }
        $targetInstallationGroups = '"TargetInstallationGroups"' + ":" + " " + $b
        if (![string]::IsNullOrEmpty($InstallationIds)) { $targetInstallationGroups = $targetInstallationGroups + "," }
    }

    $jsonpayload = @"
{
$targetInstallationGroups
$targetInstallations
}
"@



    $Endpoint = "/api/odata/Operations/Update.InstallationFile"

    add-type -AssemblyName System.Net.Http

    $body = New-Object System.Net.Http.MultipartFormDataContent
    $body.Add((New-Object System.Net.Http.ByteArrayContent(, [System.IO.File]::ReadAllBytes($InstallationFilePath))), "installationFile", "installationFile.ini")



    $stringContent = New-Object System.Net.Http.StringContent($jsonpayload, [System.Text.Encoding]::UTF8, "application/json");
    $body.Add($stringContent, "updateIniFileWrapper.UpdateInstallationFileModelDetails")

    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand

    $t = Connect-ApiCallMultipart $Endpoint $body

    if ($t[-1] -eq 1) {
        $t[-3]
        $t[-2]
        1
    }
    else {
        while ($true) {
            $resultApiAdress = $t.Result.Headers.Location.ToString()
            $pos = $resultApiAdress.IndexOf("(")

            $rawOperationId = $resultApiAdress.Substring($pos + 1)
            $operationId = $rawOperationId.Substring(0, $rawOperationId.Length - 1)


            $n = Get-XMGROperationDetails $operationId

            $n.StatusText

            if ($n.StatusText -eq "Failed") {
                $n.actions.error
                break
            }
            if ($n.StatusText -eq "Completed") {
                $n.actions.Result.UpdatedInstallationFileResult
                break
            }
            start-Sleep -s 120
        }
    }
}

<#
.Synopsis
    Starts Update operation.
INPUTS:
		- InstallationFilePath (path to installation file with ".ini" extension);
		- InstallationID
        - Path to the location of the Update Package
OUTPUTS: OK result - if executed successfully, error - if something went wrong
#>
function Start-XMGRUpdate {
    param(
        [Parameter(Mandatory = $true)]
        [String] $InstallationFilePath,
        [Parameter(Mandatory = $true)]
        [String]$InstallationId,
        [Parameter(Mandatory = $true)]
        [String]$UpdatePackageLocation
    )
    $Endpoint = "/api/odata/Operations/Start.Update"

    add-type -AssemblyName System.Net.Http

    $body = New-Object System.Net.Http.MultipartFormDataContent

    if ($InstallationFilePath) {
        $body.Add((New-Object System.Net.Http.ByteArrayContent(, [System.IO.File]::ReadAllBytes($InstallationFilePath))), "installationFile", "installationFile.ini")
    }

    $UpdatePackageLocationMod = $UpdatePackageLocation | ConvertTo-Json

    $jsonpayload = @"
{
"InstallationId" : "$InstallationId",
"UpdatePackageLocation" : $UpdatePackageLocationMod
}
"@
    $stringContent = New-Object System.Net.Http.StringContent($jsonpayload, [System.Text.Encoding]::UTF8, "application/json");
    $body.Add($stringContent, "startUpdateModelWrapper.StartUpdateModelDetails")


    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand

    $t = Connect-ApiCallMultipart $Endpoint $body

    if ($t[-1] -eq 1) {
        $t[-3]
        $t[-2]
        1
    }
    else {
        while ($true) {
            $resultApiAdress = $t.Result.Headers.Location.ToString()
            $pos = $resultApiAdress.IndexOf("(")

            $rawOperationId = $resultApiAdress.Substring($pos + 1)
            $operationId = $rawOperationId.Substring(0, $rawOperationId.Length - 1)

            $n = Get-XMGROperationDetails $operationId
            Write-Output "OperationID: $operationId"

            $n.StatusText

            if ($n.StatusText -ne "InProgress") {
                $n.actions | ConvertTo-json -Depth 10
                break
            }
            start-Sleep -s 20
        }
    }
}

Export-ModuleMember -Function *