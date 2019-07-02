param(
    [Parameter()]
    [string] $Path = "D:\HyperVendingMachine\Host\$($env:COMPUTERNAME)"
)

if (-not (Test-Path $Path))
{
    $null = New-Item -Path $Path -ItemType 'Directory'
}

Get-HVMAvailableResources |
ConvertTo-Json |
Out-File -FilePath "$Path\resources.json"

