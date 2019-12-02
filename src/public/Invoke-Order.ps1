function Invoke-Order
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [hashtable] $Order
    )
    
    begin
    {
        
    }
    
    process
    {
        $actionPlan = GetOrderActions -Order $Order

        foreach ($action in $ActionPlan)
        {
            $functionParams = $action.Parameters

            switch ($action.Command) 
            {
                'NewVM' { New-VM @functionParams }
                'SetVM' { Set-VM @functionParams }
                'StopVM' { Stop-VM @functionParams }
                'StartVM' { Start-VM @functionParams }
            }
        }
    }
    
    end
    {
        
    }
}