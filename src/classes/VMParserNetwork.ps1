class VMParserNetwork : VMParserBase
{
    static [hashtable] $OutputMap = @{
        Switch = [string]
        Vlan   = @([int], [bool])
    }

    VMParserNetwork([string] $order)
    {
        $this.workingObject['Switch'] = $order
        $this.CommonConstructor()
    }

    VMParserNetwork([hashtable] $order)
    {
        $this.workingObject = $order
        $this.CommonConstructor()
    }

    hidden [void] CommonConstructor() 
    {
        $this.ErrorIfKeyIsMissing('Switch')
        $this.AddDefaultValueIfMissing('Vlan', $false)
        $this.CheckOutputForMissingKeys([VMParserNetwork]::OutputMap)
        $this.CheckOutputTypes([VMParserNetwork]::OutputMap)
    }
}