# GG4L

## Disclaimer
These scripts come without warranty of any kind. Use them at your own risk. I assume no liability for the accuracy, correctness, completeness, or usefulness of any information provided by this site nor for any sort of damages using these scripts may cause.
**DO NOT INSTALL THESE SCRIPTS TO A DOMAIN CONTROLLER.**

Create a dedicated VM running Windows Server 2019 or Windows 10 Pro 1809+ for your automation scripts.

## Requirements
Git ````https://git-scm.com/download/win````

Powershell 7 ````https://github.com/PowerShell/powershell/releases````

For Ubuntu ````sudo apt install putty-tools````
## Requirements
You must have the CognosModule installed and configured per the suggested install process here:
https://github.com/AR-k12code/CognosModule

## Suggested Install Process
````
cd \Scripts
git clone https://github.com/AR-k12code/GG4L.git
````

## Settings
Copy the file settings-sample.ps1 and name the new file settings.ps1. DO NOT EDIT settings-sample.ps1. Enter your username and password from connect.gg4l.com.  This can be found by selecting the "Import OneRoster v1.1 SFTP" tile and selecting the key in the top right.

## Configure Sync on GG4L
You must configure school mappings first. There should be link at the top "There is no configured Schools Mapping data. Please check settings by clicking this link."
Select "School Mapping" tab.  If you've already synced before using the Basic Roster then match up the schools. Otherwise, click on "All Missing Schools as New". Click Save.

## Running this script.
````
.\gg4l.ps1
````

## Manually run import on GG4L
Go to the connect.gg4l.com and select the "Import OneRoster v1.1 SFTP" then click on "Run Import"

## To do
- [ ] Students and Teachers do not have State IDs
- [ ] The relationship to parents are not labeled correctly.
- [ ] Currently only including Guardians 1 and 2. Would like to add 3rd.
- [ ] It would be nice if the One Roster files matched the Clever files for sections ids.
- [ ] Userids are reporting an error even though they are accepted.
