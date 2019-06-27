class VMNetAdapter
{
    [ValidateNotNullOrEmpty()]
    [string] $VMName

    [string] $AdapterName = 'Network Adapter'

    [ValidateNotNullOrEmpty()]
    [string] $SwitchName

    [int] $VlanId = 0 # =0 -> Untagged, >0 -> Access

    [ipaddress[]]$IPAddresses

    VMNetAdapter([string]$vmName, [PSCustomObject]$order)
    {
        $this.VMName = $vmName

        $missingMandatoryProperties = $order |
            PSCustomObjectContainsProperty -Name 'SwitchName' |
            Where-Object { $_.PropertyOnObject -eq $false } |
            Select-Object -ExpandProperty 'Name'
        
        if (@($missingMandatoryProperties).Count -gt 0)
        {
            Write-Error -Message "The follow mandatory parameters were not given: `n -$($missingMandatoryProperties -join "`n -")" -ErrorAction Stop
        }

        $this.SwitchName = $order.SwitchName

        if (PSCostomObjectContainsProperty -Name 'AdapterName' -InputObject $order -BoolOuput)
        {
            $this.AdapterName = $order.AdapterName
        }

        if (PSCustomObjectContainsProperty -Name 'VlanId' -InputObject $order -BoolOutput)
        {
            $this.VlanId = $order.VlanId
        }
    }

    VMNetAdapter([string]$vmName)
    {
        $this.VMName = $vmName
        $this.AdapterName = 'unknown'
        $this.SwitchName = 'unknown'
    }

    static [VMNetAdapter[]] Discover([string]$vmName)
    {
        Write-Host "--$vmName--"
        $adapters = Get-VMNetworkAdapter -VMName $vmName

        $output = foreach ($adapter in $adapters)
        {
            $vlan = Get-VMNetworkAdapterVlan -VMName $vmName -VMNetworkAdapterName $adapter.Name
            Write-Host "$(@($vlan).Count) vlans found"

            $out = [VMNetAdapter]::new($vmName)
            $out.AdapterName = $adapter.Name
            $out.SwitchName = $adapter.SwitchName
            $out.VlanId = $vlan.AccessVlanId
            $out.IPAddresses = $adapter.IPAddresses
            $out # Write-Output
        }
        Write-Host "--$vmName--"

        return $output
    }
}