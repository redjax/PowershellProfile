function Show-TermColors {
    # [Enum]::GetValues([ConsoleColor])

    $colors = [enum]::GetValues([System.ConsoleColor])
    foreach ($bgcolor in $colors) {
        foreach ($fgcolor in $colors) { Write-Output "$fgcolor|" -ForegroundColor $fgcolor -BackgroundColor $bgcolor -NoNewline }
        Write-Output " on $bgcolor"
    }
}