param(
    [Parameter()]
    [string] $Path = 'D:\HyperVendingMachine\Inventory'
)

if (-not (Test-Path $Path))
{
    $null = New-Item -Path $Path -ItemType 'Directory'
}

$inventory = Get-HVMInventory

foreach ($key in $inventory.Keys)
{
    $inventory.$key | 
        ConvertTo-Json -Depth 5 |
        Out-File -FilePath "$Path\$key.json"
}
