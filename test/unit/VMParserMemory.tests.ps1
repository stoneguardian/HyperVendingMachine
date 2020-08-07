# Load required files
. $PSScriptRoot\..\..\src\classes\VMParserBase.ps1
. $PSScriptRoot\..\..\src\classes\VMParserMemory.ps1

# Silence warning-output
$_currentWarningPreference = "$WarningPreference"
$WarningPreference = 'SilentlyContinue'

Describe 'Class: VMParserMemory' {
    $constructorInputTestCases = @(
        @{type = [string]; value = '1GB' }
        @{type = [hashtable]; value = @{Dynamic = $true; Boot = 1GB } }
    )

    It 'Accepts <type> as input' -TestCases $constructorInputTestCases {
        param($value)
        [VMParserMemory]::new($value) # Should "NotThrow"
    }

    It 'Throws if input is missing mandatory keys ([hashtable])' {
        { [VMParserMemory]::new(@{ Dynamic = $true }) } | Should -Throw "Boot"
        { [VMParserMemory]::new(@{ Boot = 1GB }) } | Should -Throw "Dynamic"
    }

    $genTestCases = @(
        @{type = [string]; value = '1GB' }
        @{type = [hashtable]; value = @{Dynamic = $true; Boot = 1GB } }
    )

    It 'Generates "Min" and "Max"-keys if not given (<type>)' -TestCases $genTestCases {
        param($value)
        $result = [VMParserMemory]::new($value).Build()
        'Min' | Should -BeIn $result.Keys
        'Max' | Should -BeIn $result.Keys
    }

    $outputTypeTestCases = [VMParserMemory]::OutputMap.Keys | 
        ForEach-Object { @{ Key = $_; Type = [VMParserMemory]::OutputMap[$_] } }

    It "Ensures key '<Key>' is of type <Type>" -TestCases $outputTypeTestCases {
        param($Key, $Type)
        $result = [VMParserMemory]::new('1GB').Build()
        $result[$Key] | Should -BeOfType $Type
    }

    It 'Ensures "Max" is not less than "Boot"' {
        $order = @{
            Dynamic = $true
            Boot    = 1GB
            Max     = 512MB
        }
        $result = [VMParserMemory]::new($order).Build()
        $result.Max | Should -Be $order.Boot
    }

    It 'Ensures "Min" is not greater than "Boot"' {
        $order = @{
            Dynamic = $true
            Boot    = 1GB
            Min     = 2GB
        }
        $result = [VMParserMemory]::new($order).Build()
        $result.Min | Should -Be $order.Boot
    }
}

# Reset warning-output
$WarningPreference = $_currentWarningPreference