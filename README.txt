author: james flores

===== Quarterly-Import =====

To run (run on a computer that has the Group Policy module installed):

	Set-ExecutionPolicy Bypass Process
	.\Quarterly-Import.ps1

Optional Parameters:

	-Comment : Adds a comment for each newly imported GPO. Default value is set to "This GPO is from the DISA STIG GPO Package.".

To check if the correct module is installed or not, run:

	Import-Module GroupPolicy
	Get-Module GroupPolicy





++ DESCRIPTION ++

** Please drop the .zip that you downloaded from DISA in the same directory as this script. **

	Unpack-Zip : This function will run even if the Group Policy module is not loaded. Expands the archive and then moves the ADMX/ADML, .mof, and GPO files to their own directories in .\Files.

	#############################################
	#                                           #
	# Requires Group Policy Module to be loaded #
	#                                           #
	#############################################

	Cleanup-NewGPO : Accepts a parameter called RemoveKeywords. This function will compare the current GPOs to the new GPOs. Will remove any dupes in the new GPOs. The RemoveKeywords parameters allows you to specify an string array of keywords you want to avoid. For example, "'2012', '2008'" would match any GPO that had either of those years in it's name and removes them from the directory.

	#############################################
	#                                           #
	# Requires Group Policy Module to be loaded #
	#                                           #
	#############################################

	Import-NewGPO : This function will copy the cleaned up directory from the previous function and copy it over to your Desktop. It then imports the new GPOs with the prefix "NEW -" so you can easily identify them in Group Policy. It then will get those new GPOs and append the comment you specified earlier to them.


