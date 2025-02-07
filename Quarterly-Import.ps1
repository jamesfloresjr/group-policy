param (
	[Parameter(HelpMessage="Enter a comment for the newly imported GPOs.")]
	[string]$Comment = "This GPO is from the DISA STIG GPO Package."
)

function Unpack-Zip{
	# Locate .zip
	$zip = Get-ChildItem -Path . -Filter "*.zip"
	$gpoDir = "$($zip.Directory)\Files\$($zip.BaseName)"

	# Unzip
	mkdir $gpoDir >$null
	Expand-Archive -Path $zip.FullName -DestinationPath $gpoDir -ErrorAction SilentlyContinue >$null

	# Gather ADMX and ADML files
	$admx = Get-ChildItem -Path "$gpoDir\ADMX Templates\" -Filter "*.admx" -Recurse
	$adml = Get-ChildItem -Path "$gpoDir\ADMX Templates\" -Filter "*.adml" -Recurse

	# Move ADM(X/L) files
	mkdir .\Files\PolicyDefinitions\en-US\ >$null
	$admx.FullName | ForEach-Object {mv $_ .\Files\PolicyDefinitions\}
	$adml.FullName | ForEach-Object {mv $_ .\Files\PolicyDefinitions\en-US\}
	
	Write-Host "`nADMX and ADML files placed in '.\Files\PolicyDefinitions'"
	
	# Gather WMI Filter files
	$mof = Get-ChildItem -Path "$gpoDir" -Filter "*.mof" -Recurse
	
	# Move WMI Filter files
	mkdir .\Files\WMI_Filters >$null
	$mof.FullName | ForEach-Object {mv $_ .\Files\WMI_Filters}
	
	Write-Host "`nWMI filters placed in '.\Files\WMI_Filters'`n"

	# Gather all of the gporeport.xml files
	$xmlGpoReports = Get-ChildItem -Path $gpoDir -Filter "gpreport.xml" -Recurse

	# Separate the user/group GPO into their own
	$xmlGpoReports | ForEach-Object {
		$dir = $_.DirectoryName		# parent dir
		$full = $_.FullName			# full dir

		[xml]$xmlContent = Get-Content $full
		$gpoName = $xmlContent.GPO.Name
		
		try {
			mkdir .\Files\GPO\$gpoName -ErrorAction Stop >$null
		} catch [System.IO.IOException] {
			Write-Error "Directory already exist."
		}
		
		mv $dir .\Files\GPO\$gpoName
		
		Write-Host "Moved '$gpoName' to '.\Files\GPO'"
	}
}

function Cleanup-NewGPO{
	#############################################
	#                                           #
	# Requires Group Policy Module to be loaded #
	#                                           #
	#############################################
	
	param (
		[string[]]$RemoveKeywords
	)
	
	# Output all of the current GPO
	(Get-GPO -All).DisplayName >> ".\Files\Current_GPO.txt"
	
	# Compare current GPO to new GPO
	$curGPO = Get-Content ".\Files\Current_GPO.txt"
	$newGPO = (Get-ChildItem -Path ".\Files\GPO\").FullName
	
	foreach($gpo in $curGPO){
		$match = $newGPO -like "*$gpo"
		
		if($match.Length -eq 1){
			Remove-Item -Path $match -Recurse
		}
	}
	
	foreach($keyword in $RemoveKeywords){
		# Refreshes the list after removal
		$newGPO = (Get-ChildItem -Path ".\Files\GPO\").FullName
		
		$match = $newGPO -like "*$keyword*"
		
		$match | ForEach-Object {
			Remove-Item -Path $_ -Recurse
		}
	}
}

function Import-NewGPO{
	#############################################
	#                                           #
	# Requires Group Policy Module to be loaded #
	#                                           #
	#############################################
	
	$dest = Get-Date -Format "MMMyyyy_GPO"
	
	# Copy GPO to DC
	Copy-Item -Path ".\Files\GPO" -Destination "~\Desktop\$dest" -Recurse
	
	# Import GPO
	Get-ChildItem "~\Desktop\$dest\" | ForEach-Object {
		Import-GPO -Path $_.FullName -BackupGpoName $_.BaseName -TargetName "NEW - $($_.BaseName)" -CreateIfNeeded
	}
	
	# Adding comment
	$newGPO = Get-GPO -All | Where-Object DisplayName -like "NEW -*"
	$newGpos | ForEach-Object { $_.Description = $Comment }
}

# Tries to load Group Policy Module
Import-Module GroupPolicy -ErrorAction SilentlyContinue

$gpMod = Get-Module GroupPolicy
$gpModEnabled = $False

# List any keywords below for removal
$remove = "local", "2013"

if ($gpMod.Count -eq 0){ Write-Warning -Message "Only running Unpack-Zip because the Group Policy module is not loaded. Please login to a server with Group Policy and run this script again to import the new GPOs." }
else { $gpModEnabled = $True }

Unpack-Zip

if ($gpModEnabled){	
	# Comment confirmation
	$change = Read-Host -Prompt "The comment set for new GPOs is '$Comment'.`n`nWould you like to change it? y/n"

	if($change -like "*y*"){
		$Comment = Read-Host -Prompt "Enter your new comment"
	}
	
	Cleanup-NewGPO -RemoveKeywords $remove
	Import-NewGPO
}