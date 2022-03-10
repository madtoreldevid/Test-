# Use the locally installed Git, if available.
$gitExecutable = Get-Command git.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
if ($gitExecutable -eq $null) {
    $gitExecutable = "$PSScriptRoot\PortableGit\bin\git.exe"
    #$gitExecutable = "C:\Users\Education_20\Desktop\PSClient\Modules\SimCorp.XMGR.Git\PortableGit\bin\git.exe"
}

function internalinvokegit {
<#
.Synopsis
Wrapper function that deals with Powershell's peculiar error output when Git uses the error stream.

.Example
Invoke-Git ThrowError
$LASTEXITCODE

#>
    [CmdletBinding()]
    param(
        [parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Arguments
    )

    & {
        [CmdletBinding()]
        param(
            [parameter(ValueFromRemainingArguments=$true)]
            [string[]]$InnerArgs
        )
        &$gitExecutable $InnerArgs
    } -ErrorAction SilentlyContinue -ErrorVariable fail @Arguments

    if ($fail) {
        $fail.Exception
    }

}

Set-Alias -Name git -Value Invoke-Git
Set-Alias -Name git.exe -Value Invoke-Git

function Invoke-XMGRGitClone{
    param(
        [Parameter(Mandatory = $true)]
        [String] $DestinationFolder,
        [Parameter(Mandatory = $true)]
        [String] $SourceGitRepository
    )

    internalinvokegit -arguments "clone",$SourceGitRepository,$DestinationFolder

    cd -Path $DestinationFolder
}

#da capire come spostarsi sul branch non master per fare il pull
function Invoke-XMGRGitPull{
    param(
        [Parameter(Mandatory = $false)]
        [String] $GitBranch = ""
    )

    internalinvokegit -Arguments "pull",$GitBranch

}

function Invoke-XMGRGitPush{
    param(
        [Parameter(Mandatory = $true)]
        [String] $sourceFolder,
        [Parameter(Mandatory = $true)]
        [String] $destinationBranch,
        [Parameter(Mandatory = $true)]
        [String] $commitMesage
    )
    
    if(Test-Path $sourceFolder){
        $branchCheck = internalinvokegit -Arguments "checkout",$destinationBranch
        if($branchCheck -contains "error"){
            internalinvokegit -Arguments "checkout","-b",$destinationBranch
        }
        internalinvokegit -Arguments "add",$sourceFolder
        internalinvokegit -Arguments "commit","-m",$commitMesage
        internalinvokegit -Arguments "push","origin",$destinationBranch
    }
}