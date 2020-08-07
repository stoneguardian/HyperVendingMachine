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

    # Check if key is of type, if it is not try to cast it to that type
    hidden [void] EnsureKeyIsOfType([string] $key, [System.Reflection.TypeInfo] $type)
    {
        if ($this.workingObject[$key] -isnot $type)
        {
            $this.workingObject[$key] = ($this.workingObject[$key] -as $type)
        }
    }

    hidden [void] CheckForRequiredKeys([string[]]$keys)
    {
        $missingRequiredKeys = $keys.Where{ $_ -notin $this.workingObject.Keys }

        if ($missingRequiredKeys.Count -ne 0)
        {
            Write-Error -Message "Missing required keys:`n - $($missingRequiredKeys -join "`n - ")" -ErrorAction Stop
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