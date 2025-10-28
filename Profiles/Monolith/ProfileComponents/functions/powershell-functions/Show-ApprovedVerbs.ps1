function Show-ApprovedVerbs {
    # Get all approved verbs
    $verbs = Get-Verb

    # Format and display the verbs in a table
    $verbs | Sort-Object Verb | Format-Table -Property Verb, Group-Object -AutoSize
}