class VMDisk
{
    [ValidateNotNullOrEmpty()]
    [string] $VMName

    [string] $Path

    [ValidateRange(0, 500GB)]
    [long] $SizeInBytes = 0

    [ValidateSet('Fixed', 'Dynamic', 'Differencing')]
    [string] $Type

    [long] $SizeInBytesOnDisk = 0

    VMDisk([string]$vmName, [PSCustomObject]$order)
    {
        $this.VMName = $vmName
        
        if (-not ('SizeInBytes' -in $order.PSObject.Properties.Name))
        {
            Write-Error -Message "SizeInBytes is a required parameter" -ErrorAction Stop
        }

        $this.SizeInBytes = $order.SizeInBytes

        if ('Type' -in $order.PSObject.Properties.Name)
        {
            $this.Type = $order.Type
        }
    }

    VMDisk([string]$vmName)
    {
        $this.VMName = $vmName
    }

    static [VMDisk[]] Discover($vmName)
    {
        $disks = Get-VMHardDiskDrive -VMName $vmName

        $output = foreach ($disk in $disks)
        {
            $vhdProperties = Get-VHD -Path $disk.Path

            $out = [VMDisk]::new($vmName)
            $out.Path = $disk.Path
            $out.SizeInBytes = $vhdProperties.Size
            $out.Type = $vhdProperties.VhdType
            $out.SizeInBytesOnDisk = $vhdProperties.FileSize
            $out # Write-Output
        }

        return $output
    }
}