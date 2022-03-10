Write-Host "Loading module: SimCorp.XMGR.clientX" -ForegroundColor green

function Get-XMGRHelloWorld{
    SimCorp.XMGR\Get-XMGRHelloWorld
    write-host "... also from the client"
} 


Export-ModuleMember -Function '*'