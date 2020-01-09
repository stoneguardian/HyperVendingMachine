class VMParserMemory
{
    hidden [hashtable] $workingObject
    static [string[]] $OutputKeys = @('Dynamic', 'Boot', 'Min', 'Max')

    # Expand input like
    # @{
    #    Memory = 1GB
    #}
    VMParserMemory([string] $order)
    {
        $this.workingObject = @{
            Dynamic = $false
            Boot    = $order
        }
        $this.SharedConstructor()
    }

    VMParserMemory([hashtable] $order)
    {
        $this.workingObject = $order
        $this.ValidateMandatoryKeys()
        $this.SharedConstructor()
    }

    hidden [void] SharedConstructor()
    {
        $this.EnsureKeyIsLong('Boot')
        $this.AddMinIfMissing()
        $this.AddMaxIfMissing()
        $this.EnsureKeyIsLong('Min')
        $this.EnsureKeyIsLong('Max')
        $this.ValidateMinMax()
    }

    hidden [void] ValidateMandatoryKeys()
    {
        $missingMandatoryKeys = @('Dynamic', 'Boot').Where{ $_ -notin $this.workingObject.Keys }
        if ($missingMandatoryKeys.Count -gt 0)
        {
            Write-Error -Message "Missing required input: `n - $($missingMandatoryKeys -join "`n - ")" -ErrorAction Stop
        }
    }

    hidden [void] EnsureKeyIsLong([string] $key)
    {
        if ($this.workingObject[$key] -isnot [long])
        {
            $this.workingObject[$key] = [long]$this.workingObject[$key]
        }
    }

    hidden [void] AddMinIfMissing()
    {
        if (-not ($this.workingObject.ContainsKey('Min')))
        {
            # If not set: default to half of boot
            $this.workingObject['Min'] = $this.workingObject['Boot'] / 2
        }
    }

    hidden [void] AddMaxIfMissing()
    {
        if (-not ($this.workingObject.ContainsKey('Max')))
        {
            # If not set: default to double of boot
            $this.workingObject['Max'] = $this.workingObject['Boot'] * 2
        }
    }

    hidden [void] ValidateMinMax()
    {
        $minLessThanOrEqualBoot = $this.workingObject['Min'] -le $this.workingObject['Boot']
        $maxGreaterThanOrEqualBoot = $this.workingObject['Max'] -ge $this.workingObject['Boot']

        if (-not $minLessThanOrEqualBoot)
        {
            Write-Warning "'Min' ($($this.workingObject['Min'] / 1GB)GB) cannot be greater than 'Boot' ($($this.workingObject['Boot'] / 1GB)GB), setting equal to 'Boot'"
            $this.workingObject['Min'] = $this.workingObject['Boot']
        }

        if (-not $maxGreaterThanOrEqualBoot)
        {
            Write-Warning "'Max' ($($this.workingObject['Max'] / 1GB)GB) must be greater than 'Boot' ($($this.workingObject['Boot'] / 1GB)GB), setting equal to 'Boot'"
            $this.workingObject['Max'] = $this.workingObject['Boot']
        }
    }

    [hashtable]ToHashtable()
    {
        $missingKeys = $this.OutputKeys.Where{ $_ -notin $this.workingObject.Keys }

        if ($missingKeys.Count -gt 0)
        {
            Write-Error -Message "Logic error, output is missing the following keys: `n - $($missingKeys -join "`n - ")" -ErrorAction Stop
        }

        return $this.workingObject
    }
}