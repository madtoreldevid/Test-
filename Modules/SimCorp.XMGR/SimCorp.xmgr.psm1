Write-Host "Loading module: SimCorp.XMGR " -ForegroundColor green

<#============================================= Classes===================================#>
#region
Class Installation {
    [String] $WebApiUrl
    [String] $InstallationId


    Installation ([String] $InstallationId, [String] $WebAPiUrl) {
        $this.InstallationId = $InstallationId
        if(![String]::IsNullOrEmpty($WebAPiUrl)){
            $this.WebApiUrl = $WebAPiUrl
        }
    }
}

Class Claim {
    [String] $SecurityName

    Claim ([String] $SecurityName) {
        $this.SecurityName = $SecurityName
    }
}

#endregion

<#============================================= General Functions=========================#>
#region

function Get-XMGRHelloWorld {
    write-host "Hello World ..."
}

<#
 .Synopsis
  todo

 .Description
  todo

 .Parameter Start
 todo

 .Parameter End
  todo

 .Example
   todo
#>
function Write-XMGRLogMessage {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet(0, 1, 2)]
        [string] $LogLevel = [int]::Empty,
        [Parameter(Mandatory = $true)]
        [string] $LogMessage = [string]::Empty,
        [Parameter(Mandatory = $true)]
        [bool] $OnScreen = $true
    )


    $LogLine = get-date -Format 'yyyy-MM-dd HH:mm:ss  '
    $tmp = $global:SimCorpXMGR.currentUser
    $LogLine += ($env:COMPUTERNAME + ":" + $tmp).padright(35, " ")

    $pForeColor = ""
    switch ($LogLevel) {
        0 {
            $LogLine = $LogLine + 'Info    '
            $pForeColor = "gray"
        }
        1 {
            $LogLine = $LogLine + 'Warn    '
            $pForeColor = "yellow"
        }
        2 {
            $LogLine = $LogLine + 'Error   '
            $pForeColor = "red"
        }
    }
    $LogLine = $LogLine + $LogMessage

    try {
        $LogLine | Out-File -FilePath $global:SimCorpXMGR.logFile -Append

        if ($OnScreen) {
            Write-Host $LogLine -ForegroundColor $pForeColor
        }
    }
    catch { $global:SimCorpXMGR.errorReturnValue }

}

function InternalRequestCheck {
    param(
        [Parameter(Mandatory = $true)]
        [Object]$pRequest,
        [Parameter(Mandatory = $false)]
        [String] $pLogMessage
    )

    if ($pRequest[-1] -eq 1) {
        $global:SimCorpXMGR.errorReturnValue
        if ($pRequest[-3].length -gt 0) {
            $pRequest[-3]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $pRequest[-3]
        }
        if ($pRequest[-2].length -gt 0) {
            $pRequest[-2]
            Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $pRequest[-2]
        }
    }
    else {
        if ($pLogMessage.Length -gt 0) { Write-XMGRLogMessage -LogLevel 0 -OnScreen $true -LogMessage $pLogMessage }
        else {
            if ($prequest.value.length -gt 0) { $prequest.value }
            else { $prequest }
        }
    }
}

#endregion

<#============================================= General API CALL Functions================#>
#region

<#
.Synopsis
    General purpose REST PATCH function used to communicate with XMGR Service. Encapsulates: Logging, Errorhandling and UTF-8 coding. Not userd directly, only in higher order functions.

INPUTS:  Address or a POST REST API, valid JSONPayload

OUTPUTS: Returns an array with the XMGR-Service response. In case of RequestError, the whole error message is returned with addidion of 1 at position [-1].

#>
function Connect-XMGRApiCallPOST {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Endpoint,
        [Parameter(Mandatory = $true)]
        [String]$jsonpayload
    )
    Write-XMGRLogMessage -LogLevel 0  -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand

    $apiAddress = $Global:SimCorpXMGR.websocket + $Endpoint
    $user = $global:SimCorpXMGR.currentUser
    try {
        Write-XMGRLogMessage -LogLevel 0  -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage "Calling URL : $apiAddress Type: $Method by $user"
        Invoke-Restmethod -Uri $apiaddress -UseDefaultCredentials -Method Post -Body $jsonpayload -ContentType 'application/json; charset=utf-8'
    }
    catch {
        $streamreader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        $ErrorResponse = $streamreader.ReadToEnd() | ConvertFrom-Json
        $streamreader.Close()
        $RequestError = $ErrorResponse.error.message + " " + $ErrorResponse.error.details.message
        $RequestError
        Write-XMGRLogMessage -LogLevel 2 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage "Call of URL: $apiaddress Type: POST by $user could not be performed. $RequestError JSON: $jsonpayload"
        Write-XMGRLogMessage -LogLevel 2 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $RequestError
        1
    }
}

<#
.Synopsis

    General purpose REST PATCH function used to communicate with XMGR Service. Encapsulates: Logging, Errorhandling and UTF-8 coding. Not userd directly, only in higher order functions.

INPUTS:  Address of the PATCH API, valid JSON

OUTPUTS: Returns an array with the XMGR-Service response. In case of RequestError, the whole error message is returned with addidion of 1 at position [-1].

#>
function Connect-XMGRApiCallPATCH {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Endpoint,
        [Parameter(Mandatory = $true)]
        [String]$jsonpayload
    )
    Write-XMGRLogMessage -LogLevel 0  -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand

    $apiAddress = $Global:SimCorpXMGR.websocket + $Endpoint
    $user = $global:SimCorpXMGR.currentUser
    try {
        Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage "Calling URL : $apiAddress Type: $Method by $user"
        Invoke-Restmethod -Uri $apiaddress -UseDefaultCredentials -Method Patch -Body $jsonpayload -ContentType 'application/json; charset=utf-8'
    }
    catch {
        $streamreader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        $ErrorResponse = $streamreader.ReadToEnd() | ConvertFrom-Json
        $streamreader.Close()
        $RequestError = $ErrorResponse.error.message + " " + $ErrorResponse.error.details.message
        $RequestError
        Write-XMGRLogMessage -LogLevel 2 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage "Call of URL: $apiaddress Type: POST by $user could not be performed.  $RequestError JSON: $jsonpayload"
        1
    }
}

<#
.Synopsis

    General purpose REST GET and DELETE function used to communicate with XMGR Service. Encapsulates: Logging, Errorhandling and UTF-8 coding. Not userd directly, only in higher order functions.

INPUTS:  Mandaroty: Address of the REST API, type of a call: DELETE or GET. Optionally: an Odata Filter Expression

OUTPUTS: Returns an array with the XMGR-Service response. In case of RequestError, the whole error message is returned with addidion of 1 at position [-1].

#>
function Connect-XMGRApiCall {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Endpoint,
        [Parameter(Mandatory = $true)]
        [ValidateSet("GET", "DELETE")]
        [String]$Method,
        [Parameter(Mandatory = $false)]
        [String]$Filter,
        [Parameter(Mandatory = $false)]
        [String]$OrderBy,
        [string]$OutFile
    )
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand

    $apiAddress = $Global:SimCorpXMGR.websocket + $Endpoint

    if (![string]::IsNullOrEmpty("$Filter")) {

        $encodedFilter = [uri]::EscapeDataString($filter)
        $apiAddress = $apiAddress + '&%24filter=' + $encodedFilter
    }
    if (![string]::IsNullOrEmpty("$OrderBy")) {

        $encodedOrderBy = [uri]::EscapeUriString($OrderBy)
        $apiAddress = $apiAddress + '&%24orderby=' + $encodedOrderBy
    }

    $user = $global:SimCorpXMGR.currentUser
    try {
        Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage "Calling URL : $apiAddress Type: $Method by $user"
        Invoke-RestMethod -UseDefaultCredentials -Method $Method $apiAddress
        if (![string]::IsNullOrEmpty("$OutFile")) {

            Invoke-RestMethod -UseDefaultCredentials -Method $Method $apiAddress -OutFile $OutFile
        }
    }
    catch {
        $streamreader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        $ErrorResponse = $streamreader.ReadToEnd() | Convertfrom-json
        $streamreader.Close()
        $RequestError = $ErrorResponse.error.message + " " + $ErrorResponse.error.details.message
        $RequestError
        Write-XMGRLogMessage -LogLevel 2 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage "Call of URL : $apiAddress Type: $Method by $user could not be performed. $RequestError"
        1
    }
}

<#
.Synopsis
    General purpose REST POST function used to communicate with XMGR Service. Encapsulates: Logging, Errorhandling and UTF-8 coding. Not userd directly, only in higher order functions.
INPUTS:  Address of the POST API, valid MultipartFormDataContent
OUTPUTS: Returns an array with the XMGR-Service response. In case of Error, the whole error message is returned with addidion of 1 at position [-1].
#>
function Connect-ApiCallMultipart {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Endpoint,
        [Parameter(Mandatory = $true)]
        [System.Net.Http.MultipartFormDataContent]$multipartBody
    )
    $apiAddress = $Global:SimCorpXMGR.websocket + $Endpoint
    $user = $Global:SimCorpXMGR.currentUser

    $handler = New-Object System.Net.Http.HttpClientHandler
    $handler.UseDefaultCredentials = $true

    $client = New-Object System.Net.Http.HttpClient($handler)
    Write-XMGRLogMessage -LogLevel 0  -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    Write-XMGRLogMessage -LogLevel 0  -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage "Calling URL : $apiAddress Type: MULTIPART by $user"

    $request = $client.PostAsync($apiAddress, $multipartBody).GetAwaiter().GetResult()
    $response = $request.Content.ReadAsStringAsync().Result | ConvertFrom-Json

    if ($request.IsSuccessStatusCode -eq $true) {
        $response
    }
    else {
        Write-XMGRLogMessage -LogLevel 2 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage "Call of URL: $apiaddress Type: MULTIPART by $user could not be performed. $RequestError JSON: $jsonpayload"
        if($response.error.details.message){
        $errorMessage = $response.error.details.message
        }else{
        $errorMessage = $response.error.message  
        }
        Write-XMGRLogMessage -LogLevel 2 -OnScreen $true -LogMessage $errorMessage
        1     

    }




}

#endregion

<#============================================= Installations Configuration===============#>
#region
<#
.Synopsis

    Lists all the installations currently in XMGR register.

INPUTS: NONE

OUTPUTS: An arraylist with Installations and their details. None if no installations are found in XMGR register.

#>
function Get-XMGRInstallations {
    $Endpoint = "/api/odata/installations"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCall $Endpoint "GET"
    InternalRequestCheck $request
}


<#
.Synopsis

    For security reasons, function "Get-installations", which lists all installations linked to XMGR is available to administrators only.
    This function is accessible to all users. It lists the available installations, where the user has the specified permissions.


INPUTS: Selected permission from the list

OUTPUTS: A list of installations where the user has the permissions granted.

#>
function Get-XMGRMyInstallations {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("ViewInstallationConfigurationElements", "ExportConfiguration", "ImportConfiguration", "DeleteInstallationConfigurationElements" )]
        [String] $Permission

    )


    $jsonpayload = @"
{
  "Permissions": [
    $Permissions
  ]
}
"@

    $Endpoint = "/api/odata/GetAllowedInstallations"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCallPOST -Endpoint $Endpoint -jsonpayload $jsonpayload
    InternalRequestCheck $request
}

<#
.Synopsis

    Lists the details of an installation with a given InstallationId

INPUTS:  InstalaltionId

OUTPUTS: Details of the requested installation, if the installation does not exist in the register

#>
function Get-XMGRInstallation {
    param(
        [Parameter(Mandatory = $true)]
        [String] $InstallationId
    )
    $Endpoint = "/api/odata/installations"
    $uri = $Endpoint + "('$InstallationId')"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCall $uri "GET"
    InternalRequestCheck $request
}

<#
.Synopsis

    Adds an SCD installation to XMGR register.

INPUTS: Both InstallationID and WebAPiUrl must be unique values. WebApiUrl must begin with "https://"

OUTPUTS: Details of the operation and confirmation of instalaltion creation or a specific error message.

#>
function Add-XMGRInstallation {
    param(
        [Parameter(Mandatory = $true)]
        [String] $InstallationId,
        [Parameter(Mandatory = $false)]
        [String] $WebApiUrl
    )
    $Endpoint = "/api/odata/installations"
    $jsonpayload = New-Object Installation ([String] $InstallationId, [String] $WebApiUrl) | ConvertTo-Json
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $CreationRequest = Connect-XMGRApiCallPOST $Endpoint $jsonpayload
    InternalRequestCheck $CreationRequest "Installation < $InstallationId > added"
}

<#
.Synopsis

    Changes the WebAPiUrl of an installation

INPUTS:  InstallationID of an installation we want to change and a new WebApiURL. WebApiUrl must begin with "https://"

OUTPUTS: Details of the updated installation or an error message if the installationID was not found or new WebApiUrl is invalid

#>
function Update-XMGRInstallation {
    param(
        [Parameter(Mandatory = $true)]
        [String] $InstallationId,
        [Parameter(Mandatory = $true)]
        [String] $WebAPIUrl
    )

    $jsonpayload = @"
{
"WebApiUrl": "$WebAPIUrl"
}
"@

    $Endpoint = "/api/odata/installations('$InstallationId')"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCallPATCH $Endpoint $jsonpayload
    InternalRequestCheck $request "Installation < $InstallationId > updated"
}

<#
.Synopsis

    Removes an installation from XMGR register. It also removes it from any installation groups and realms it was a member of.

INPUTS: name of the installation

OUTPUTS: none if successful, error message if no given InstallationId was found

#>
function Remove-XMGRInstallation {
    param(
        [Parameter(Mandatory = $true)]
        [String] $InstallationId
    )
    $apiaddress = "/api/odata/installations"
    $Endpoint = $apiaddress + "('$InstallationId')"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCall $Endpoint "DELETE"

    <#If request failed, show the erorr message and error details#>
    InternalRequestCheck $request "Installation < $InstallationId > removed"
}
#endregion

<#============================================= Installation groups=======================#>
#region
<#
.Synopsis

    Lists all available Installation Groups

INPUTS:  NONE

OUTPUTS: A list and details of all available Installation Groups. None if none are available.

#>
function Get-XMGRInstallationGroups {
    $Endpoint = "/api/odata/InstallationGroups"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCall $Endpoint "GET"
    InternalRequestCheck $request
}

<#
.Synopsis

    Shows details of a specific Installation group.

INPUTS: Name of the Installation Group.

OUTPUTS: Details of the requested Installation Group or a message that it does not exist.

#>
function Get-XMGRInstallationGroup {
    param(
        [Parameter(Mandatory = $true)]
        [String]$InstallationGroupId
    )
    $Endpoint = "/api/odata/InstallationGroups('$InstallationGroupId')"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCall $Endpoint "GET"
    InternalRequestCheck $request
}

<#
.Synopsis

    InstallationGroups can contain Installations as well as other Installation Groups. If the nested group structure is complex, it might be hard to determine all the installations that are members of it.
    This function returns all the InstallationIDs that are members of a given installtion group.

INPUTS: Installation Group ID

OUTPUTS: List of InstallationIDs

#>
function Get-XMGRAllGroupInstallations {
    param(
        [Parameter(Mandatory = $true)]
        [String]$InstallationGroupId
    )
    $Endpoint = "/api/odata/InstallationGroups('$InstallationGroupId')/GroupsService.GetAllInstallations"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCall $Endpoint "GET"
    InternalRequestCheck $request
}

<#
.Synopsis

    Removes an Installation Group from XMGR register. Removes the Installation Group from Installtion groups where it was a member. It does NOT affect any member Installations.

INPUTS: Installaion Group Id

OUTPUTS: None if successful, RequestError if InstalationGroupId does not exist in the register

#>
function Remove-XMGRInstallationGroup {
    param(
        [Parameter(Mandatory = $true)]
        [String]$InstallationGroupId
    )
    $Endpoint = "/api/odata/InstallationGroups('$InstallationGroupId')"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCall $Endpoint "DELETE"
    InternalRequestCheck $request "Installation group < $InstallationGroupId > removed"
}

<#
.Synopsis

    Creates an Installation Group. It requires a unique ID and can (does not have to) contain Installations or other Installation Groups.
    These can be added and removed later on.

INPUTS: A unique InstallationGroupId is mandatory, lists of installtionIds and InstallationGroupIds are optional

OUTPUTS: Details of a newly created Installation Group or an error message if a group with a given ID already exists.

#>
function Add-XMGRInstallationGroup {
    param(
        [Parameter(Mandatory = $true)]
        [String]$InstallationGroupId,
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $InstallationIds,
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $ChildGroupIds
    )

    $b = "[]"
    $c = "[]"

    if ($PSBoundParameters.ContainsKey('ChildGroupIds')) {
        if ($ChildGroupIds.Count -eq 1) {
            $d = $ChildGroupIds | ConvertTo-Json
            $c = "[$d]"
        }
        else {
            $c = $ChildGroupIds | ConvertTo-Json
        }
    }

    if ($PSBoundParameters.ContainsKey('InstallationIds')) {
        if ($InstallationIds.Count -eq 1) {
            $e = $InstallationIds | ConvertTo-Json
            $b = "[$e]"
        }
        else {
            $b = $InstallationIds | ConvertTo-Json
        }
    }

    $jsonpayload = @"
{
"GroupId": "$InstallationGroupId",
"InstallationIds": $b,
"ChildGroupIds": $c
}
"@

    $apiaddress = "/api/odata/InstallationGroups"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCallPOST $apiaddress $jsonpayload
    InternalRequestCheck $request "Installation group < $InstallationGroupId > containing < $InstallationIds $ChildGroupIds > created"
}

<#
.Synopsis
    Installation Groups allow for a nested setup. This function adds a specific installation (or a list of installations) and/or Installation Group (or a list of instalaltion groups) to a given InstallationGroup

INPUTS: Id of the Installation group, lists of installationIDs and/or InstallationGroupIds.

OUTPUTS: Details of a newly modified Installationgroup or a specific error message

#>
function Add-XMGRInstallationsToGroup {
    param(
        [Parameter(Mandatory = $true)]
        [String]$InstallationGroupId,
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $InstallationIds,
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $ChildGroupIds
    )

    $b = "[]"
    $c = "[]"

    if ($PSBoundParameters.ContainsKey('ChildGroupIds')) {
        if ($ChildGroupIds.Count -eq 1) {
            $d = $ChildGroupIds | ConvertTo-Json
            $c = "[$d]"
        }
        else {
            $c = $ChildGroupIds | ConvertTo-Json
        }
    }

    if ($PSBoundParameters.ContainsKey('InstallationIds')) {
        if ($InstallationIds.Count -eq 1) {
            $e = $InstallationIds | ConvertTo-Json
            $b = "[$e]"
        }
        else {
            $b = $InstallationIds | ConvertTo-Json
        }
    }

    $jsonpayload = @"
{
"InstallationIds": $b,
"ChildGroupIds": $c
}
"@

    $apiaddress = "/api/odata/InstallationGroups('$InstallationGroupId')/GroupsService.AddGroupInfo"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCallPOST $apiaddress $jsonpayload
    InternalRequestCheck $request "$InstallationIds $ChildGroupIds added to group < $InstallationGroupId >"
}

<#
.Synopsis

    Installation Groups allow for a nested setup. This function removes a specific installation (or a list of installations) and/or Installation Group (or a list of instalaltion groups) from a given InstallationGroup

INPUTS: Id of the Installation group, lists of installationIDs and/or InstallationGroupIds.

OUTPUTS: Details of a newly modified Installationgroup or a specific error message

#>
function Remove-XMGRInstallationsFromGroup {
    param(
        [Parameter(Mandatory = $true)]
        [String]$InstallationGroupId,
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $InstallationIds,
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $ChildGroupIds
    )

    $b = "[]"
    $c = "[]"

    if ($PSBoundParameters.ContainsKey('ChildGroupIds')) {
        if ($ChildGroupIds.Count -eq 1) {
            $d = $ChildGroupIds | ConvertTo-Json
            $c = "[$d]"
        }
        else {
            $c = $ChildGroupIds | ConvertTo-Json
        }
    }

    if ($PSBoundParameters.ContainsKey('InstallationIds')) {
        if ($InstallationIds.Count -eq 1) {
            $e = $InstallationIds | ConvertTo-Json
            $b = "[$e]"
        }
        else {
            $b = $InstallationIds | ConvertTo-Json
        }
    }

    $jsonpayload = @"
{
"InstallationIds": $b,
"ChildGroupIds": $c
}
"@

    $apiaddress = "/api/odata/InstallationGroups('$InstallationGroupId')/GroupsService.RemoveGroupInfo"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCallPOST $apiaddress $jsonpayload
    InternalRequestCheck $request "Installation(s) < $InstallationIds > removed from group < $InstallationGroupId >"
}

<#
.Synopsis

    Function has two purposes - validate user input and output the member installationIds of installationGroupIds.
    User inputs a list of installationIDs and/or InstalaltionGroupIds and the function returns the installationIds that are found within
    the groups - with no duplicates. If user inputs non-existing InstallationIds,InstalaltionGroupIds then they will be omitted.

INPUTS: InstallationIds/InstallationGroupIds and the permission that the user need to access the installation

OUTPUTS: A list of InstallationIds that are available in the XMGR register and match the input criteria

#>
function Get-XMGRValidInstallations {
    param(
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]]$InstallationIds,
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]]$InstallationGroupIds,
        [Parameter(Mandatory = $true)]
        [String]$InstallationPermission
    )

    $availableGroups = Get-XMGRInstallationGroups
    $availableGroups = $availableGroups.GroupId

    $availableInstallationsWithPermission = Get-XMGRMyInstallations -Permission $InstallationPermission

    $validInstallations = New-Object Collections.Generic.List[String]

    if (![String]::IsNullOrEmpty($InstallationGroupIds)) {
        foreach ($group in $InstallationGroupIds) {
            if ($group -in $availableGroups) {
                $memberInstallations = Get-XMGRAllGroupInstallations -InstallationGroupId $group
                $memberInstallations = $memberInstallations.InstallationId
                foreach ($memberInstallation in $memberInstallations) { if($memberInstallation -in $availableInstallationsWithPermission){ $null = $validInstallations.Add($memberInstallation)} }
            }
        }
    }

    if (![String]::IsNullOrEmpty($InstallationIds)) {
        foreach ($installation in $InstallationIds) {
            if ($installation -in $availableInstallationsWithPermission) { $null = $validInstallations.Add($installation) }
        }
    }

    return  $validInstallations | Sort-Object | Get-Unique


}
#endregion

<#============================================= Realms====================================#>
#region
<#
.Synopsis

    Lists all the available permissions available for the Realm setup

INPUTS: NONE

OUTPUTS: A list of available permissions

#>
function Get-XMGRPermissions {
    $Endpoint = "/api/odata/GetAllPermissions"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCall $Endpoint "GET"
    (InternalRequestCheck $request) | Sort-Object Permission
}

<#
.Synopsis

    Lists all the Realms from the XMGR register

INPUTS: NONE

OUTPUTS: List and details of all the available Realms

#>
function Get-XMGRRealms {
    $Endpoint = "/api/odata/realms"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCall $Endpoint "GET"
    InternalRequestCheck $request
}

<#
.Synopsis

    Presents the details of a specific Realm

INPUTS: RealmId

OUTPUTS: Details of the requested Realm.

#>
function Get-XMGRRealm {
    param(
        [Parameter(Mandatory = $true)]
        [String] $RealmId
    )
    $Endpoint = "/api/odata/realms"
    $uri = $Endpoint + "('$RealmId')"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCall $uri "GET"
    InternalRequestCheck $request

}

<#
.Synopsis

    Lists all the Realms where a specific Claim (AD-User or AD-Group) is a member of.

INPUTS: ClaimID in form of SID or AD-GroupName or AD-UserName

OUTPUTS: List of Realms which include the specified Claim

#>
function Get-XMGRRealmsByClaim {
    param(
        [Parameter(Mandatory = $true)]
        [String] $Claim
    )
    $Endpoint = "/api/odata/RealmsBySecurityId"
    $uri = $Endpoint + "(id='$Claim')"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCall $uri "GET"
    InternalRequestCheck $request
}

<#
.Synopsis

    Lists all the Realms where a requested InstalltionId is a member of

INPUTS: InstalationId

OUTPUTS: List of Realms which include the specified InstallationId

#>
function Get-XMGRRealmsByInstId {
    param(
        [Parameter(Mandatory = $true)]
        [String] $InstallationId
    )
    $Endpoint = "/api/odata/RealmsByInstallationId"
    $uri = $Endpoint + "(id='$InstallationId')"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCall $uri "GET"
    InternalRequestCheck $request
}

<#
.Synopsis

   Lists all the Claims associated with a specific Realm

INPUTS: RealmId

OUTPUTS: SIDs and SecurityNames of all the associated Claims

#>
function Get-XMGRClaimsByRealmId {
    param(
        [Parameter(Mandatory = $true)]
        [String] $RealmId
    )
    $Endpoint = "/api/odata/realms"
    $uri = $Endpoint + "('$RealmId')/RealmService.GetClaims"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCall $uri "GET"
    InternalRequestCheck $request
}

<#
.Synopsis

    Lists all Installations which are members of the specified Realm

INPUTS: RealmId

OUTPUTS: List of InstallationIds or a specific error message if the RealmId does not exist

#>
function Get-XMGRInstallationsByRealmId {
    param(
        [Parameter(Mandatory = $true)]
        [String] $RealmId
    )
    $Endpoint = "/api/odata/Realms"
    $uri = $Endpoint + "('$RealmId')/RealmService.GetInstallationIds"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCall $uri "GET"
    InternalRequestCheck $request

}

<#
.Synopsis

    Creates an XMGR Realm

INPUTS: a unique RealmId, a list of Claims (in format of SID or AD-groupNames) and selction of the Role (Permissions) are mandatory (To create a realm without permission use the Empty value, this will create a realm with "AddTag" permission that will be removed after the creation).
Optionally, it is posisble to include installations or Installation Groups - one can add them later as well using "Add-InstalltionstoRealm" and "Add-InstalltionGroupstoRealm".

OUTPUTS: Details of the newly created Realm or a specific error message

#>
function Add-XMGRRealm {
    param(
        [Parameter(Mandatory = $true)]
        [String]$RealmId,
        [Parameter(Mandatory = $true)]
        [Collections.Generic.List[String]] $Claims,
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $InstallationIds,
        [Parameter(Mandatory = $false)]
        [Collections.Generic.List[String]] $InstallationGroupIds,
        [Parameter(Mandatory = $true)]
        [ValidateSet("Full", "ReadOnly", "PackageImport", "PackageExport","Empty")]
        [string] $Permissions
    )



    $PermissionSet = switch ($Permissions) {
        'Full' {
            ("ExportConfiguration",
            "ImportConfiguration",
            "TransferConfiguration",
            "SimpleTransferConfiguration",
            "ViewOperations",
            "ViewOperationDetails",
            "ViewPackageList",
            "ViewPackageEntities",
            "ViewPackageObjects",
            "DownloadPackage",
            "UploadPackage",
            "ComparePackages",
            "ViewPackageDefinitions",
            "PackageDefinitionConfiguration",
            "ApplyPackage",
            "UploadAndSignPackage",
            "ViewPackageCompareResultRaw",
            "ViewPackageCompareResultEntities",
            "ViewPackageCompareResultObjects",
            "ViewInstallationConfigurationElements",
            "JoinDependencies",
            "MarkPackages",
            "ViewAuditRecords",
            "ForceDownloadPackage",
            "ForceImportConfiguration",
            "ApplyTags",
            "GetDependencyModel",
            "ChangeAccessibilityStatus",
            "PerformCbu",
            "SetUpdatePackageLocation",
            "UpdateInstallationFile",
            "UpdateInstallation",
            "ChangeInstallationState",
            "ReadAlerts",
            "ViewLogs",
            "ManageInstallationCredentials",
            "ServicePlatformMonitoring",
            "ManageServicePlatformDependencyModel",
            "ExecuteBatchJobGroup",
            "MergeAuthorizationProfiles",
            "DeleteInstallationConfigurationElements",
            "MonitorMessageQueues")
        }
        'ReadOnly' {
            ("ViewOperations",
            "ViewOperationDetails",
            "ViewPackageList",
            "ViewPackageEntities",
            "ViewPackageObjects",
            "DownloadPackage",
            "ViewPackageDefinitions",
            "ViewPackageCompareResultRaw",
            "ViewPackageCompareResultEntities",
            "ViewPackageCompareResultObjects",
            "ViewInstallationConfigurationElements",
            "JoinDependencies",
            "ViewAuditRecords",
            "GetDependencyModel",
            "ViewLogs",
            "ReadAlerts")
        }
        'PackageImport' {
            ("ImportConfiguration",
            "ViewOperations",
            "ViewOperationDetails",
            "ViewPackageList",
            "ViewPackageEntities",
            "ViewPackageObjects",
            "UploadPackage",
            "ComparePackages",
            "ViewPackageDefinitions",
            "UploadAndSignPackage",
            "ViewPackageCompareResultRaw",
            "ViewPackageCompareResultEntities",
            "ViewPackageCompareResultObjects",
            "ViewInstallationConfigurationElements",
            "ViewAuditRecords"
            )
        }
        'PackageExport' {
            ("ExportConfiguration",
            "ViewOperations",
            "ViewOperationDetails",
            "ViewPackageList",
            "ViewPackageEntities",
            "ViewPackageObjects",
            "DownloadPackage",
            "ComparePackages",
            "ViewPackageDefinitions",
            "PackageDefinitionConfiguration",
            "ViewPackageCompareResultRaw",
            "ViewPackageCompareResultEntities",
            "ViewPackageCompareResultObjects",
            "ViewInstallationConfigurationElements",
            "JoinDependencies",
            "ViewAuditRecords",
            "ApplyTags"
            )
        }
        'Empty'{
            ("ApplyTags")
        }
    }
    

    if($PermissionSet.GetType().name -eq "String"){
        $empty = $true
        $toberemoved = $PermissionSet
    }

    if($PermissionSet.count -gt 1){
        $PermissionSet = $PermissionSet | ConvertTo-Json
    }else{
        $PermissionSet = "["+($PermissionSet | ConvertTo-Json)+"]"
    }

    $claimsSet = New-Object System.Collections.Generic.List[string]
    foreach ($claim in $Claims) {
        $claim = $claim | ConvertTo-Json
        $entry = @"
 {
 "SecurityName": $claim
 }
"@

        $claimsSet.Add($entry) > $null
    }

    $claimsSet = $claimsSet -join ","

    $InstallationIds = $InstallationIds | ConvertTo-Json
    $InstallationIds = $InstallationIds -replace '\[', ''
    $InstallationIds = $InstallationIds -replace '\]', ''

    $InstallationGroupIds = $InstallationGroupIds | ConvertTo-Json
    $InstallationGroupIds = $InstallationGroupIds -replace '\[', ''
    $InstallationGroupIds = $InstallationGroupIds -replace '\]', ''

    $jsonpayload = @"
{
    "RealmId": "$RealmId",
    "Claims": [
            $claimsSet
    ],
    "InstallationIds": [
        $InstallationIds
    ],
    "InstallationGroupIds": [
        $InstallationGroupIds
    ],
    "Permissions": 
            $PermissionSet
    
}
"@


    $Endpoint = "/api/odata/realms"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCallPOST $Endpoint -jsonpayload $jsonpayload
    $request = InternalRequestCheck $request "Realm < $RealmId > created"
   
    if([String]::IsNullOrEmpty($request) -and $empty){Remove-XMGRPermissionsFromRealm -RealmId $RealmId -Permissions $toberemoved}

    $request
}

<#
.Synopsis

    Removes the specified Realm from XMGR register. Does not delete any Installations or Installation Groups that are members of it.

INPUTS: RealmId

OUTPUTS: None if successful, specific error message if the given RealmId was not found.

#>
function Remove-XMGRRealm {
    param(
        [Parameter(Mandatory = $true)]
        [String] $RealmId
    )
    $apiaddress = "/api/odata/realms"
    $uri = $apiaddress + "('$RealmId')"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCall $uri "DELETE"
    InternalRequestCheck $request "Realm < $RealmId > removed"
}

<#
.Synopsis

    Adds a list of installations to the specified Realm

INPUTS: RealmId and a list of InstallationIds

OUTPUTS: Details of the newly modified Realm or a specific error message

#>
function Add-XMGRInstalltionstoRealm {
    param(
        [Parameter(Mandatory = $true)]
        [String]$RealmId,
        [Parameter(Mandatory = $true)]
        [Collections.Generic.List[String]] $InstallationIds
    )

    $b = $InstallationIds | ConvertTo-Json

    if ($InstallationIds.Count -eq 1) {
        $jsonpayload = @"
{"InstallationIds": [$b]}
"@
    }
    else {
        $jsonpayload = @"
{"InstallationIds": $b}
"@
    }
    $apiaddress = "/api/odata/realms"
    $uri = $apiaddress + "('$RealmId')/RealmService.AddInstallations"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCallPOST $uri $jsonpayload
    InternalRequestCheck $request "Installation(s) < $InstallationIds > added to realm < $RealmId >"
}

<#
.Synopsis

    Adds a list of installation groups to the specified Realm

INPUTS:  RealmId and a list of InstallationGroupIds

OUTPUTS: Details of the newly modified Realm or a specific error message

#>
function Add-XMGRInstalltionGroupstoRealm {
    param(
        [Parameter(Mandatory = $true)]
        [String]$RealmId,
        [Parameter(Mandatory = $true)]
        [Collections.Generic.List[String]] $InstallationGroupIds
    )

    $b = $InstallationGroupIds | ConvertTo-Json

    if ($InstallationGroupIds.Count -eq 1) {
        $jsonpayload = @"
{
"InstallationGroupIds": [$b]}
"@
    }
    else {
        $jsonpayload = @"
{"InstallationGroupIds": $b}
"@
    }

    $apiaddress = "/api/odata/realms"
    $uri = $apiaddress + "('$RealmId')/RealmService.AddInstallationGroups"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCallPOST $uri $jsonpayload
    InternalRequestCheck $request "InstallationGroup(s) < $InstallationGroupIds > added to realm < $RealmId >"
}

<#
.Synopsis

    Adds a list of permissions to a specified Realm. See: get-permissions for details

INPUTS: RealmId and a list of permissions to add

OUTPUTS: Details of the modified Realm

#>
function Add-XMGRPermissionsToRealm {
    param(
        [Parameter(Mandatory = $true)]
        [String]$RealmId,
        [Parameter(Mandatory = $true)]
        [Collections.Generic.List[String]] $Permissions
    )

    $b = $Permissions | ConvertTo-Json

    if ($Permissions.Count -eq 1) {
        $jsonpayload = @"
{"Permissions": [$b]}
"@
    }
    else {
        $jsonpayload = @"
{"Permissions": $b}
"@
    }


    $Endpoint = "/api/odata/realms"
    $uri = $Endpoint + "('$RealmId')/RealmService.AddPermissions"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCallPOST $uri $jsonpayload
    InternalRequestCheck $request "Permission(s) < $Permissions > added to realm < $RealmId >"
}

<#
.Synopsis

    Adds a list of Claims (SIDs or Ad-GroupNames/AD-Usernames) to the specified Realm

INPUTS:  RealmId and a list of Claims

OUTPUTS: Details of the newly modified Realm or a specific error message

#>
function Add-XMGRClaimstoRealm {
    param(
        [Parameter(Mandatory = $true)]
        [String]$RealmId,
        [Parameter(Mandatory = $true)]
        [Collections.Generic.List[String]] $Claims
    )
    $list = New-Object System.Collections.ArrayList

    foreach ($Claim in $Claims) {
        $singleClaim = New-Object Claim ($Claim)
        $null = $list.Add($singleClaim)
    }
    $ClaimsInJSON = $list | ConvertTo-Json

    if ($list.Count -eq 1) {
        $jsonpayload = @"
{"Claims": [$ClaimsInJSON]}
"@
    }
    else {
        $jsonpayload = @"
{"Claims": $ClaimsInJSON}
"@
    }
    $apiaddress = "/api/odata/realms"
    $uri = $apiaddress + "('$RealmId')/RealmService.AddClaims"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCallPOST $uri $jsonpayload
    InternalRequestCheck $request "Claim(s) < $Claims > added to realm < $RealmId >"
}



function Remove-XMGRPermissionsFromRealm {
    param(
        [Parameter(Mandatory = $true)]
        [String]$RealmId,
        [Parameter(Mandatory = $true)]
        [Collections.Generic.List[String]] $Permissions
    )

    $b = $Permissions | ConvertTo-Json

    if ($Permissions.Count -eq 1) {
        $jsonpayload = @"
{"Permissions": [$b]}
"@
    }
    else {
        $jsonpayload = @"
{"Permissions": $b}
"@
    }


    $Endpoint = "/api/odata/realms('$RealmId')/RealmService.RemovePermissions"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCallPOST $Endpoint $jsonpayload
    InternalRequestCheck $request "Permission(s) < $Permissions > removed from < $RealmId >"
}

<#
.Synopsis

    Removes a list of installation groups from the specified Realm

INPUTS:  RealmId and a list of InstallationGroupIds

OUTPUTS: Details of the newly modified Realm or a specific error message

#>
function Remove-XMGRInstallationGroupsFromRealm {
    param(
        [Parameter(Mandatory = $true)]
        [String]$RealmId,
        [Parameter(Mandatory = $true)]
        [Collections.Generic.List[String]] $InstallationGroupIds
    )

    $b = $InstallationGroupIds | ConvertTo-Json

    if ($InstallationGroupIds.Count -eq 1) {
        $jsonpayload = @"
{
"InstallationGroupIds": [$b]}
"@
    }
    else {
        $jsonpayload = @"
{"InstallationGroupIds": $b}
"@
    }


    $apiaddress = "/api/odata/realms('$RealmId')/RealmService.RemoveInstallationGroups"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCallPOST $apiaddress $jsonpayload
    InternalRequestCheck $request "$InstallationGroupIds removed from $RealmId"
}

<#
.Synopsis

    Removes a list of installations from the specified Realm

INPUTS: RealmId and a list of InstallationIds

OUTPUTS: Details of the newly modified Realm or a specific error message

#>
function Remove-XMGRInstallationsFromRealm {
    param(
        [Parameter(Mandatory = $true)]
        [String]$RealmId,
        [Parameter(Mandatory = $true)]
        [Collections.Generic.List[String]] $InstallationIds
    )

    $b = $InstallationIds | ConvertTo-Json

    if ($InstallationIds.Count -eq 1) {
        $jsonpayload = @"
{"InstallationIds": [$b]}
"@
    }
    else {
        $jsonpayload = @"
{"InstallationIds": $b}
"@
    }

    $apiaddress = "/api/odata/realms('$RealmId')/RealmService.RemoveInstallations"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCallPOST $apiaddress $jsonpayload
    InternalRequestCheck $request "DONE"
}

<#
.Synopsis

    Removes a list of Claims (SIDs or SecurityNames) from the specified Realm

INPUTS:  RealmId and a list of Claims

OUTPUTS: Details of the newly modified Realm or a specific error message

#>
function Remove-XMGRClaimsFromRealm {
    param(
        [Parameter(Mandatory = $true)]
        [String]$RealmId,
        [Parameter(Mandatory = $true)]
        [Collections.Generic.List[String]] $Claims
    )
    $list = New-Object System.Collections.ArrayList

    foreach ($Claim in $Claims) {
        $singleClaim = New-Object Claim ($Claim)
        $null = $list.Add($singleClaim)
    }
    $ClaimsInJSON = $list | ConvertTo-Json

    if ($list.Count -eq 1) {
        $jsonpayload = @"
{"Claims": [$ClaimsInJSON]}
"@
    }
    else {
        $jsonpayload = @"
{"Claims": $ClaimsInJSON}
"@
    }
    $apiaddress = "/api/odata/realms('$RealmId')/RealmService.RemoveClaims"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCallPOST $apiaddress $jsonpayload
    InternalRequestCheck $request "DONE"
}

<#
.Synopsis

    List all missing permissions (compared with Get-XMGRPermissions) for the specified Realm

INPUTS:  
    -Mandatory:
        -RealmId: The ID of the interested realm

OUTPUTS: List of all missing permissions (comparing realm permissions with Get-XMGRPermissions) and their relative Description

#>
function Get-XMGRMissingRealmPermissions {
    param(
        [Parameter(Mandatory = $true)]
        [String]$RealmId
    )

    [System.Collections.ArrayList]$allPermissions = (Get-XMGRPermissions).Permission

    $realmPermissions = Get-XMGRRealm $RealmId 

    if($realmPermissions[0] -eq $Global:SimCorpXMGR.errorReturnValue){
        Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage "A realm with id '$RealmId' does not exist."
        return $Global:SimCorpXMGR.errorReturnValue
    }

    $realmPermissions = $realmPermissions.permissions

    foreach($permission in $realmPermissions){     
        $allPermissions.Remove($permission)
    }

    $result = New-Object System.Collections.ArrayList

    $desciptions = Get-XMGRPermissions 

    if($allPermissions.Count -eq 0){
        Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage "The realm '$RealmId' have all the permissions available"
    }

    foreach($permission in $allPermissions){
        $null = $result.add(($desciptions | Where-Object Permission -eq $permission))
    }

    return $result 

}

#endregion

<#============================================= XMGR Status, Settings and Logs============#>
#region
<#
.Synopsis

    Shows the version of XMGR used

INPUTS:NONE

OUTPUTS: Version of XMGR

#>
function Get-XMGRInfo {
    $Endpoint = "/api/odata/Info"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCall $Endpoint "GET"
    $tmp = InternalRequestCheck $request
    $columnsToSelect = @('BuildVersion', 'Copyright', 'UserInfo')
    $tmp | Select-Object $columnsToSelect | Format-Table
}

<#
.Synopsis

    Gets the status of XMGR-Service

INPUTS: NONE

OUTPUTS: Status of XMGR-Service

#>
function Get-XMGRStatus {
    $Endpoint = "/api/odata/health"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCall $Endpoint "GET"
    InternalRequestCheck $request
}

<#
.Synopsis

    Lists the details of XMGR Settings

INPUTS: NONE

OUTPUTS: Details of the XMGE Settings

#>
function Get-XMGRSettings {
    $Endpoint = "/api/odata/Settings"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCall $Endpoint "GET"
    $tmp = InternalRequestCheck $request
    $tmp.Settings | ConvertTo-Json
}

<#
.Synopsis

    Displays the XMGR Audit trail. One can filter by an InstallationId and a User
    or get a specific Operation by passing in an ID (which invalidates other selection criteria)

INPUTS: filtering criteria

OUTPUTS: List of audited XMGR operations, orderedBy by "CreatedAt" (newest on the bottom)

#>
function Get-XMGRAudit {
    param(
        [Parameter(Mandatory = $false)]
        [String] $InstallationId,

        [Parameter(Mandatory = $false)]
        [String] $UserName,

        [Parameter(Mandatory = $false)]
        [String] $Id
    )

    if (![STRING]::IsNullOrEmpty($InstallationId)) {
        $FilterExpression = "InstallationId eq '$InstallationId'"
    }

    if (![STRING]::IsNullOrEmpty($UserName)) {
        $FilterExpression = "UserName eq '$UserName'"
    }

    if (![STRING]::IsNullOrEmpty($InstallationId) -and ![STRING]::IsNullOrEmpty($UserName)) {
        $FilterExpression = "InstallationId eq '$InstallationId'" + " and " + "UserName eq '$UserName'"
    }

    if (![STRING]::IsNullOrEmpty($Id)) {
        $FilterExpression = "Id eq $id"
    }

    <#Order by Creation Date, ascending - latest on the bottom#>
    $orderby = "CreatedAt asc"

    $Endpoint = "/api/odata/AuditRecords?api-version=1.0"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $AuditRequest = Connect-XMGRApiCall -Endpoint $Endpoint -Method "GET" -Filter $FilterExpression -OrderBy $orderby

    foreach($AuditElement in $AuditRequest){
        
        $AuditElement.InputParams = $AuditElement.InputParams.value
        $AuditElement.PSObject.Properties.Remove("NATSSubject")
        $AuditElement.PSObject.Properties.Remove("InstallationUrl")
        $AuditElement.PSObject.Properties.Remove("UserSid")

    }  

    $AuditRequest
}


#endregion

<#============================================= Large Objects=============================#>
#region
<#
.Synopsis

    Results of some operations are too large to store/display directly - they are stored as large objects. This function lists all the available large-objects.
    Since most of the higher-order functions automatically get the large object they generated, this function is mostly obsolete.

INPUTS:NONE

OUTPUTS: a list of all available large objects

#>
function Get-XMGRLargeObjects {
    $Endpoint = "/api/odata/LargeObjects"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCall $Endpoint "GET"
    InternalRequestCheck $request
}

<#
.Synopsis

    Results of some operations are too large to store/display directly - they are stored as separate large objects. This function is used to display the content of a specific large object.
    Not used directly, used mostly by higher-order functions to display the result of another function.

INPUTS: ID of the large Object

OUTPUTS: Contents of the specified large object or a specific error message

#>
function Get-XMGRLargeObject {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ObjectId
    )
    $Endpoint = "/api/odata/LargeObjects($ObjectId)/LargeObjectsService.RetrieveLargeObject"
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $request = Connect-XMGRApiCall $Endpoint "GET"
    InternalRequestCheck $request
}
#endregion

<#============================================= Managing Operations=======================#>
#region

<#
.Synopsis

   Displays a list of all the XMGR operations. For a more detailed information use "get-OperationsDetails"

INPUTS: NONE

OUTPUTS: A list of XMGR operations

#>
function Get-XMGROperations {
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $Endpoint = "/api/odata/Operations?api-version=1.0&%24orderby=StartedAt&%24count=true"
    $request = Connect-XMGRApiCall $Endpoint "GET"
    InternalRequestCheck $request
}

<#
.Synopsis

    Displays a detailed list of all the XMGR operations

INPUTS: NONE

OUTPUTS: A detailed list of XMGR operations

#>
function Get-XMGROperationsDetails {
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $Endpoint = "/api/odata/OperationsDetails?api-version=1.0&%24orderby=StartedAt&%24count=true"
    $request = Connect-XMGRApiCall $Endpoint "GET"
    InternalRequestCheck $request
}

<#
.Synopsis

    Displays details of a specified XMGR Operation

INPUTS: OperationId

OUTPUTS: Details of the specified XMGR Operation

#>
function Get-XMGROperationDetails {
    param(
        [Parameter(Mandatory = $true)]
        [String] $OperationId
    )
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $Endpoint = "/api/odata/OperationsDetails"
    $uri = $Endpoint + "($OperationId)"
    $request = Connect-XMGRApiCall $uri "GET"
    InternalRequestCheck $request
}

<#
.Synopsis

    Displays a specific XMGR Operation. For a more detailed information use "get-OperationDetails"

INPUTS: OperationId

OUTPUTS: Basic Information about an XMGR Operation

#>
function Get-XMGROperation {
    param(
        [Parameter(Mandatory = $true)]
        [String] $OperationId
    )
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $Endpoint = "/api/odata/operations"
    $uri = $Endpoint + "($OperationId)"
    $request = Connect-XMGRApiCall $uri "GET"
    InternalRequestCheck $request
}

<#
.Synopsis

    Lists all XMGR operations associated with a specified Installation.
    For a more detailed information use "Get-XMGROpsDetailsByInstId"

INPUTS: InstallationId

OUTPUTS: A list of XMGR operations associated with a specific installationId

#>
function Get-XMGROperationsByInstId {
    param(
        [Parameter(Mandatory = $true)]
        [String] $InstallationId
    )
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $Endpoint = "/api/odata/Operations/Get.ByInstallationId(Id='$InstallationId')"
    $request = Connect-XMGRApiCall $Endpoint "GET"
    InternalRequestCheck $request
}

<#
.Synopsis

    Lists all XMGR operations with details associated with a specified Installation.

INPUTS: InstallationId

OUTPUTS: A list of XMGR operations with details, associated with a specific installationId

#>
function Get-XMGROperationsDetailsByInstId {
    param(
        [Parameter(Mandatory = $true)]
        [String] $InstallationId
    )
    Write-XMGRLogMessage -LogLevel 0 -OnScreen $global:SimCorpXMGR.logOnScreen -LogMessage $MyInvocation.Mycommand
    $Endpoint = "/api/odata/OperationsDetails/Get.ByInstallationId(id='$InstallationId')"
    $request = Connect-XMGRApiCall $Endpoint "GET"
    InternalRequestCheck $request
}
#endregion

#region Synchronisation

<#=================================================Synchronise Installations================================================#>

function Sync-XMGRInstallations {
    $Configfile = join-path -path $pSimCorpModulePath -childpath "XMGRConfig.json"
    $json_content = Get-Content $Configfile | ConvertFrom-Json
    $installations = $json_content.Installations

    foreach ($inst in $installations) {

        Remove-XMGRInstallation -InstallationId $inst.InstallationId
        Add-XMGRInstallation -InstallationId $inst.InstallationId -WebApiUrl $inst.WebApi
    }
}

<#=================================================Synchronise InstallationGroups================================================#>

function Sync-XMGRInstallationGroups {
    $Configfile = join-path -path $pSimCorpModulePath -childpath "XMGRConfig.json"
    $json_content = Get-Content $Configfile | ConvertFrom-Json
    $instgroups = $json_content.InstallationGroups

    foreach ($ingr in $instgroups) {

        Remove-XMGRInstallationGroup -InstallationGroupId $ingr.InstallationGroupId
        Add-XMGRInstallationGroup -InstallationGroupId $ingr.InstallationGroupId


        if ($ingr.InstallationIds) {

            Add-XMGRInstallationsToGroup -InstallationGroupI $ingr.InstallationGroupId -InstallationIds $ingr.InstallationIds
        }
        if ($ingr.ChildGroupIds) {
            Add-XMGRInstallationsToGroup -InstallationGroupId $ingr.InstallationGroupId -ChildGroupIds $ingr.ChildGroupIds
        }

    }
}

<#=================================================Synchronise Realms================================================#>
function Sync-XMGRRealms {
    $Configfile = join-path -path $pSimCorpModulePath -childpath "XMGRConfig.json"
    $json_content = Get-Content $Configfile | ConvertFrom-Json
    $Realms = $json_content.Realms


    foreach ($realm in $Realms) {
        Remove-XMGRRealm $realm.RealmId
        Add-XMGRRealm -RealmId $realm.RealmId -Claims $realm.ClaimIds -InstallationGroupIds $realm.InstalationGroupIds -Permissions $realm.Permissions
    }
}
#endregion

Import-Module $PSScriptRoot"\7zip4powershell\7Zip4Powershell.psd1" -Global

Export-ModuleMember -Function *