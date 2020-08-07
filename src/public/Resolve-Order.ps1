function Resolve-Order
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [hashtable] $Order
    )
    
    begin
    {
        
    }
    
    process
    {
        $Order | ParseOrder
    }
    
    end
    {
        
    }
}