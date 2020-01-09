class VMParserDisks
{
    [System.Management.Automation.HiddenAttribute()]
    [hashtable[]] $workingObject = @()

    [System.Management.Automation.HiddenAttribute()]
    [string] $VMName

    [System.Management.Automation.HiddenAttribute()]
    [bool] $VMExists

    VMParserDisks([string]$vmName)
    {
        $this.VMName = $vmName
        $this.VMExists = $null -ne (Get-VM -Name $vmName -ErrorAction SilentlyContinue)
    }

    [VMParserDisks]WithInput([object[]] $order)
    {
        if ($order.Count -eq 0)
        {
            $this.workingObject = @()
            return $this
        }

        # Just "Passthru" if VM exists
        if ($this.VMExists)
        {
            $this.workingObject = foreach ($item in $order)
            {
                [VMParserSingleDisk]::new($item).Build() # Write-Output -> $this.workingObject
            }
        }
        else 
        {
            $initial = foreach ($item in $order)
            {
                [VMParserSingleDisk]::new($item) # Write-Output -> $initial
            }

            $initial = @($initial) # Force list-type

            # Ensure one disk has ['System'] = $true
            $hasSystemDisk = $initial.Where{ $_.workingObject.System -eq $true }.Count -gt 0

            if (-not $hasSystemDisk)
            {
                # Convert first to system-disk
                $initial[0] = $initial[0].AsSystemDisk($this.VMName)
            }

            $this.workingObject = foreach ($item in $initial)
            {
                $item.Build() # Write-Output -> $this.workingObject
            }
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

class VMParserSingleDisk
{
    # Map of keys and types for output object
    static [hashtable] $OutputMap = @{
        'System' = [bool]
        'Name'   = [string]
        'Size'   = [long]
    }

    [System.Management.Automation.HiddenAttribute()]
    [hashtable] $workingObject

    # Output
    [hashtable] Build()
    {
        $missingKeys = $this.OutputMap.Keys.Where{ $_ -notin $this.workingObject.Keys }

        if ($missingKeys.Count -gt 0)
        {
            Write-Error -Message "Logic error, output is missing the following keys: `n - $($missingKeys -join "`n - ")" -ErrorAction Stop
        }

        return $this.workingObject
    }

    # Builder-pattern
    [VMParserSingleDisk] AsSystemDisk([string] $VMName)
    {
        $this.workingObject['System'] = $true
        $this.workingObject['Name'] = $VMName
        return $this
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
        if (-not $this.workingObject.ContainsKey('Size'))
        {
            Write-Error -Message "'Size' is required" -ErrorAction Stop
        }
        $this.CommonConstructor()
    }

    [System.Management.Automation.HiddenAttribute()]
    [void] CommonConstructor()
    {
        $this.EnsureKeyIsLong('Size')
        $this.GenerateNameIfMissing()
        $this.AddSystemIfMissing()
    }

    [System.Management.Automation.HiddenAttribute()]
    [void] EnsureKeyIsLong([string] $key)
    {
        if ($this.workingObject[$key] -isnot [long])
        {
            $this.workingObject[$key] = [long]$this.workingObject[$key]
        }
    }

    [System.Management.Automation.HiddenAttribute()]
    [void] GenerateNameIfMissing()
    {
        if (-not ($this.workingObject.ContainsKey('Name')))
        {
            $this.workingObject['Name'] = "$([Guid]::NewGuid())"
        }
    }

    [System.Management.Automation.HiddenAttribute()]
    [void] AddSystemIfMissing()
    {
        if (-not ($this.workingObject.ContainsKey('System')))
        {
            $this.workingObject['System'] = $false
        }
    }
}