function Get-Inventory
{
    [CmdletBinding()]
    param (
    )
    
    begin
    {
        $result = @{
            VMs             = [System.Collections.Generic.List[VM]]::new()
            Disks           = [System.Collections.Generic.List[VMDisk]]::new()
            NetworkAdapters = [System.Collections.Generic.List[VMNetAdapter]]::new()
        }
    }
    
    process
    {
        $allVMs = Get-VM

        foreach ($vm in $allVMs)
        {
            $result.VMs.Add([VM]::Discover($vm.Name))
            $result.Disks.Add([VMDisk]::Discover($vm.Name))
            $result.NetworkAdapters.Add([VMNetAdapter]::Discover($vm.Name))
        }

        $result # Write-Output
    }
    
    end
    {
    }
}