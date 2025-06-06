﻿@{
	# Script module or binary module file associated with this manifest
	RootModule        = 'PowershellProfileSetup.psm1'
	
	# Version number of this module.
	ModuleVersion     = '1.0.0'
	
	# ID used to uniquely identify this module
	GUID              = 'd221bf4e-1971-4da5-9227-0611d1efca31'
	
	# Author of this module
	Author            = 'redjax'
	
	# Company or vendor of this module
	CompanyName       = 'MyCompany'
	
	# Copyright statement for this module
	Copyright         = 'Copyright (c) 2025 redjax'
	
	# Description of the functionality provided by this module
	Description       = 'Module to aid with setup/configuration for my PowershellProfile module.'
	
	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion = '5.0'
	
	# Modules that must be imported into the global environment prior to importing this module
	# RequiredModules = @(@{ ModuleName='PSFramework'; ModuleVersion='1.12.346' })
	
	# Assemblies that must be loaded prior to importing this module
	# RequiredAssemblies = @('bin\PowershellProfileSetup.dll')
	
	# Type files (.ps1xml) to be loaded when importing this module
	# Expensive for import time, no more than one should be used.
	# TypesToProcess = @('xml\PowershellProfileSetup.Types.ps1xml')
	
	# Format files (.ps1xml) to be loaded when importing this module.
	# Expensive for import time, no more than one should be used.
	# FormatsToProcess = @('xml\PowershellProfileSetup.Format.ps1xml')
	
	# Functions to export from this module
	FunctionsToExport = @(
		'Get-ProfileConfig',
		'Invoke-ModuleManifestUpdate',
		'Set-PowershellProfile',
		'Invoke-BaseProfileInstall',
		'Install-ProfileModule',
		'Install-CustomModules',
		'Invoke-CustomModulesPathInit',
		'Set-CustomPSModulesPath',
		'Remove-CustomModules'
	)
	
	# Cmdlets to export from this module
	CmdletsToExport   = ''
	
	# Variables to export from this module
	VariablesToExport = ''
	
	# Aliases to export from this module
	AliasesToExport   = ''
	
	# List of all files packaged with this module
	FileList          = @()
	
	# Private data to pass to the module specified in ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData       = @{
		
		#Support for PowerShellGet galleries.
		PSData = @{
			
			# Tags applied to this module. These help with module discovery in online galleries.
			# Tags = @()
			
			# A URL to the license for this module.
			# LicenseUri = ''
			
			# A URL to the main website for this project.
			# ProjectUri = ''
			
			# A URL to an icon representing this module.
			# IconUri = ''
			
			# ReleaseNotes of this module
			# ReleaseNotes = ''
			
		} # End of PSData hashtable
		
	} # End of PrivateData hashtable
}