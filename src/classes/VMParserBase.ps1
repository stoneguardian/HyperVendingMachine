class VMParserBase
{
    hidden [hashtable] $workingObject = @{}

    VMParserBase() {}

    hidden [void] AddDefaultValueIfMissing([string]$key, [object]$defaultValue)
    {
        if (-not ($this.workingObject.ContainsKey($key)))
        {
            $this.workingObject[$key] = $defaultValue
        }
    }

    hidden [void] ErrorIfKeyIsMissing([string]$key)
    {
        if (-not ($this.workingObject.ContainsKey($key)))
        {
            Write-Error -Message "'$key' is required" -ErrorAction Stop
        }
    }

    hidden [void] CheckOutputForMissingKeys([hashtable] $outputMap)
    {
        $missingKeys = $outputMap.Keys.Where{ $_ -notin $this.workingObject.Keys }

        if ($missingKeys.Count -gt 0)
        {
            Write-Error -Message "Output is missing keys: `n - $($missingKeys.Count)"
        }
    }

    hidden [void] CheckOutputTypes([hashtable] $outputMap)
    {
        foreach ($key in $outputMap.Keys)
        {
            if ($this.workingObject[$key].GetType() -notin $outputMap[$key])
            {
                Write-Error -Message "Key '$key' should have a value of type [$($outputMap[$key] -join ']/[')] but was [$($this.workingObject[$key].GetType())]" -ErrorAction Stop
            }
        }
    }

    [hashtable] Build()
    {
        return $this.workingObject
    }
}