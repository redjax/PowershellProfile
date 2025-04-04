function Convert-ToLowercase {
    <#
        .SYNOPSIS
        Convert a string to all lowercase.

        .PARAM InputString
        The string to convert to lowercase.

        .EXAMPLE
        Convert-ToLowercase -InputString "Hello World"
    #>
    param(
        $InputString = $null
    )

    if (-not $InputString) {
        Write-Warning "Missing an -InputString to set to lowercase"
    }

    ## Return lowercased string
    "$($InputString)".ToLower()
}

function Convert-ToUppercase {
    <#
        .SYNOPSIS
        Convert a string to all uppercase.

        .PARAM InputString
        The string to convert to uppercase.

        .EXAMPLE
        Convert-ToUppercase -InputString "Hello World"
    #>
    param(
        $InputString = $null
    )

    if (-not $InputString) {
        Write-Warning "Missing an -InputString to set to uppercase"
    }

    ## Return uppercased string
    "$($InputString)".ToUpper()
}

function Convert-ToTitlecase {
    <#
        .SYNOPSIS
        Convert a string to titlecase.  

        .PARAM InputString
        The string to convert to titlecase.

        .EXAMPLE
        Convert-ToTitlecase -InputString "hello world"
    #>
    param(
        $InputString = $null
    )

    if (-not $InputString) {
        Write-Warning "Missing an -InputString to set to title case"
    }

    ## Extract and format text from string
    $culture = [System.Globalization.CultureInfo]::CurrentCulture
    $textInfo = $culture.TextInfo

    ## Return title-cased string
    $textInfo.ToTitleCase($InputString.ToLower())
}

function Get-NewGuid {
    return [guid]::NewGuid().ToString()
}
