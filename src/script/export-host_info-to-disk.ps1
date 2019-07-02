param(
    [Parameter()]
    [string] $Path = "D:\HyperVendingMachine\Host\$($env:COMPUTERNAME)"
)

if (-not (Test-Path $Path))
{
    $null = New-Item -Path $Path -ItemType 'Directory'
}

$resources = Get-HVMAvailableResources 

$resources.CPU |
ConvertTo-Json |
Out-File -FilePath "$Path\cpu.json"

$resources.Memory |
ConvertTo-Json |
Out-File -FilePath "$Path\memory.json"

$resources.Disk |
ConvertTo-Json |
Out-File -FilePath "$Path\disk.json"