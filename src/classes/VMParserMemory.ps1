class VMParserMemory : VMParserBase
{
    static [hashtable] $OutputMap = @{
        Dynamic = [bool]
        Boot    = [long]
        Min     = [long]
        Max     = [long]
    }

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
        $this.CommonConstructor()
    }

    VMParserMemory([hashtable] $order)
    {
        $this.workingObject = $order
        $this.CheckForRequiredKeys(@('Dynamic', 'Boot'))
        $this.CommonConstructor()
    }

    hidden [void] CommonConstructor()
    {
        $this.EnsureKeyIsOfType('Boot', [VMParserMemory]::OutputMap['Boot'])
        $this.AddDefaultValueIfMissing('Min', ($this.workingObject['Boot'] / 2))
        $this.AddDefaultValueIfMissing('Max', ($this.workingObject['Boot'] * 2))
        $this.EnsureKeyIsOfType('Min', [VMParserMemory]::OutputMap['Min'])
        $this.EnsureKeyIsOfType('Max', [VMParserMemory]::OutputMap['Max'])
        $this.ValidateMinMax()
        $this.CheckOutputForMissingKeys([VMParserMemory]::OutputMap)
        $this.CheckOutputTypes([VMParserMemory]::OutputMap)
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
}