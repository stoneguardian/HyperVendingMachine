# Load required files
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
        $result = [VMParserMemory]::new($value).ToHashtable()
        'Min' | Should -BeIn $result.Keys
        'Max' | Should -BeIn $result.Keys
    }

    It 'Ensures number-values are of type [long]' {
        $result = [VMParserMemory]::new('1GB').ToHashtable()
        $result.Boot | Should -BeOfType [long]
        $result.Min | Should -BeOfType [long]
        $result.Max | Should -BeOfType [long]
    }

    It 'Ensures "Max" is not less than "Boot"' {
        $order = @{
            Dynamic = $true
            Boot    = 1GB
            Max     = 512MB
        }
        $result = [VMParserMemory]::new($order).ToHashtable()
        $result.Max | Should -Be $order.Boot
    }

    It 'Ensures "Min" is not greater than "Boot"' {
        $order = @{
            Dynamic = $true
            Boot    = 1GB
            Min     = 2GB
        }
        $result = [VMParserMemory]::new($order).ToHashtable()
        $result.Min | Should -Be $order.Boot
    }
}

# Reset warning-output
$WarningPreference = $_currentWarningPreference