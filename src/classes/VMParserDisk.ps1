class VMParserDisks
{
    [System.Management.Automation.HiddenAttribute()]
    [hashtable[]] $workingObject = @()

    [System.Management.Automation.HiddenAttribute()]
    [string] $VMName

    [System.Management.Automation.HiddenAttribute()]
    [bool] $VMExists

    VMParserDisks([string]$vmName, [bool]$vmExists)
    {
        $this.VMName = $vmName
        $this.VMExists = $vmExists
    }

    [VMParserDisks]WithInput([object[]] $order)
    {
        if ($order.Count -eq 0)
        {
            $this.workingObject = @()
            return $this
        }

        $singleDisks = foreach ($item in $order)
        {
            [VMParserSingleDisk]::new($item)
        }
        

        # If the VM does not exist, ensure a system disk exists
        if (-not $this.VMExists)
        {
            $systemDisk = @($singleDisks).Where{ $_.workingObject.System -eq $true } | Select-Object -First 1
            if ($systemDisk.Count -eq 0)
            {
                # Convert first disk to system-disk
                $singleDisks[0].AsSystemDisk($this.VMname)
            }
            else 
            {
                # Ensure Name == VMName
                $systemDisk.AsSystemDisk($this.VMName)
            }
        }

        $this.workingObject = foreach ($disk in $singleDisks)
        {
            $disk.Build() # Write-Output -> $this.workingObject
        }
        return $this # "Fluent"
    }

    # Extra validation and output
    [hashtable[]]Build()
    {
        # Only one ['System'] = $true disk allowed
        $systemDiskCount = $this.workingObject.Where{ $_.System -eq $true }.Count
        if ($systemDiskCount -gt 1)
        {
            Write-Error -Message "Only one ['System']-disk allowed, found $systemDiskCount" -ErrorAction Stop
        }

        # Ensure ['System']-disk is first object in list
        if (($systemDiskCount -eq 1) -and ($this.workingObject[0].System -eq $false))
        {
            $_systemDisk = $this.workingObject.Where{ $_.System -eq $true }
            $_otherDisks = $this.workingObject.Where{ $_.System -ne $true }
            return @($_systemDisk + $_otherDisks)
        }
        else
        {
            return $this.workingObject
        }
    }
}

class VMParserSingleDisk : VMParserBase
{
    # Map of keys and types for output object
    static [hashtable] $OutputMap = @{
        'System' = [bool]
        'Name'   = [string]
        'Size'   = [long]
    }

    # Constructors and helpers
    VMParserSingleDisk([string] $order)
    {
        $this.workingObject = @{
            Size = $order
        }
        $this.CommonConstructor()
    }

    VMParserSingleDisk([int] $order)
    {
        $this.workingObject = @{
            Size = $order
        }
        $this.CommonConstructor()
    }
    
    VMParserSingleDisk([long] $order)
    {
        $this.workingObject = @{
            Size = $order
        }
        $this.CommonConstructor()
    }
    
    VMParserSingleDisk([hashtable] $order)
    {
        $this.workingObject = $order
        $this.CheckForRequiredKeys('Size')
        $this.CommonConstructor()
    }

    hidden [void] CommonConstructor()
    {
        $this.EnsureKeyIsOfType('Size', [VMParserSingleDisk]::OutputMap['Size'])
        $this.AddDefaultValueIfMissing('Name', [Guid]::NewGuid().ToString())
        $this.AddDefaultValueIfMissing('System', $false)
        $this.CheckOutputForMissingKeys([VMParserSingleDisk]::OutputMap)
        $this.CheckOutputTypes([VMParserSingleDisk]::OutputMap)
    }

    # Builder-pattern
    [VMParserSingleDisk] AsSystemDisk([string] $VMName)
    {
        $this.workingObject['System'] = $true
        $this.workingObject['Name'] = $VMName
        $this.CheckOutputForMissingKeys([VMParserSingleDisk]::OutputMap)
        $this.CheckOutputTypes([VMParserSingleDisk]::OutputMap)
        return $this
    }
}