Import-Module PSWindowsUpdate
# Add -NotTitle "regex" or -NotKBArticleID "KBXXXXXXX" to skip specific updates.
# -NotTitle takes a regex, not a glob: use "BIOS" not "*BIOS*".
# Always skip BIOS firmware updates when running remotely.
Install-WindowsUpdate -AcceptAll -AutoReboot *>> $PSScriptRoot\WUUpdate.log
