function Invoke-Order
{
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
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
            Write-Debug -Message $($action | ConvertTo-Json)

            $functionParams = $action.Parameters

            if ($action.Command -eq 'NewVM')
            {
                if ($PSCmdlet.ShouldProcess($action.Parameters.Name, "Creating VM"))
                {
                    New-VM @functionParams
                }
            }
            elseif ($action.Command -eq 'SetVM')
            {
                if ($PSCmdlet.ShouldProcess($action.Parameters.Name, "Altering $($action.Parameters.Keys.Count - 1) properties on VM"))
                {
                    Set-VM @functionParams
                }
            }
            elseif ($action.Command -eq 'StopVM')
            {
                if ($PSCmdlet.ShouldProcess($action.Parameters.Name, "Stopping VM"))
                {
                    Stop-VM @functionParams
                }
            }
            elseif ($action.Command -eq 'StartVM')
            {
                if ($PSCmdlet.ShouldProcess($action.Parameters.Name, "Starting VM"))
                {
                    Start-VM @functionParams
                }
            }
        }
    }
    
    end
    {
        
    }
}