function Convert-ToLowercase {
    Param(
        $InputString = $null
    )

    If ( -Not $InputString ) {
        Write-Warning "Missing an -InputString to set to lowercase"
    }

    ## Return lowercased string
    "$($InputString)".ToLower()
}

function Convert-ToUppercase {
    Param(
        $InputString = $null
    )

    If ( -Not $InputString ) {
        Write-Warning "Missing an -InputString to set to uppercase"
    }

    ## Return uppercased string
    "$($InputString)".ToUpper()
}

function Convert-ToTitlecase {
    Param(
        $InputString = $null
    )

    If ( -Not $InputString ) {
        Write-Warning "Missing an -InputString to set to title case"
    }

    ## Extract and format text from string
    $culture = [System.Globalization.CultureInfo]::CurrentCulture
    $textInfo = $culture.TextInfo

    ## Return title-cased string
    $textInfo.ToTitleCase($InputString.ToLower())
}