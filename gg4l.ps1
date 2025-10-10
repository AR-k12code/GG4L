#Requires -Version 7.1
#Requires -Modules CognosModule

<#
GG4L Automation Script
Craig Millsap
Gentry Public Schools
 ___ _____ ___  ___   ___   ___    _  _  ___ _____         
/ __|_   _/ _ \| _ \ |   \ / _ \  | \| |/ _ \_   _|        
\__ \ | || (_) |  _/ | |) | (_) | | .` | (_) || |          
|___/ |_| \___/|_|   |___/ \___/  |_|\_|\___/ |_|
 ___ ___ ___ _____   _____ _  _ ___ ___   ___ ___ _    ___ 
| __|   \_ _|_   _| |_   _| || |_ _/ __| | __|_ _| |  | __|
| _|| |) | |  | |     | | | __ || |\__ \ | _| | || |__| _| 
|___|___/___| |_|     |_| |_||_|___|___/ |_| |___|____|___|
   
Please see https://github.com/AR-k12code/GG4L for more information.
#>

Param(
    [parameter(Mandatory=$false,HelpMessage="Do not download new Cognos Reports")][switch]$SkipDownload,
	[parameter(Mandatory=$false,HelpMessage="Download from Cognos but do not upload the files to GG4L.")][switch]$SkipUpload
)

#get host key by running .\bin\pscp.exe -v .\ fakeuser@upload.gg4l.com:\
$gg4lhostkey = "b7:a7:63:26:04:ce:ac:48:a2:3f:a0:a1:c3:40:08:df"

Start-Transcript "$PSScriptRoot\gg4l-log.log" -Force

#Check for Settings File
if (-Not(Test-Path $PSScriptRoot\settings.ps1)) {
    write-host "Error: Failed to find the settings.ps1 file. You can use the sample_settings.ps1 file as an example." -ForegroundColor Red
    exit(1)
} else {
    . $PSScriptRoot\settings.ps1
}

#Required folders
if (-Not(Test-Path "$PSScriptRoot\files")) { New-Item -Path $PSScriptRoot\files -ItemType directory }

if (-Not($SkipDownload)) { #Skip downloading of new reports.

    $reports = @('users','orgs','academicSessions','courses','classes','enrollments','demographics') #,'manifest')

    #Establish Cognos Session.
    try {
        Connect-ToCognos
    } catch {
        Write-Host "Error: Failed to connect to Cognos." -ForegroundColor Red
        exit 1
    }

    try {
        $reports | ForEach-Object {
            #start all of the reports on the cognos server so they can be processing.
            Start-CognosReport -report "$PSItem" -cognosfolder "_Shared Data File Reports\ParentNotices-Transact-GG4L" -TeamContent -reportparams "p_stu_pass=&p_staff_pass=&p_parent_pass=" #We have to awknowledge the prompts even if we don't answer them directly.
        } | ForEach-Object {
            #retrieve them one at a time.
            Save-CognosReport -conversationID $PSitem.conversationID -savepath "$PSScriptRoot\files" -FileName "$($PSItem.Report).csv"
        }
    } catch {
        $PSItem
        exit 2
    }

} #close skip download.

if (-Not($SkipUpload)) {
    try {
        Write-Host "Info: Uploading files to GG4L..." -ForegroundColor YELLOW
        $exec = Start-Process -FilePath "$PSScriptRoot\bin\pscp.exe" -ArgumentList "-pw ""$gg4lpassword"" -hostkey $gg4lhostkey -r $PSScriptRoot\files\*.csv $($gg4lusername)@sftp.gg4l.com:/" -PassThru -Wait -NoNewWindow
        if ($exec.ExitCode -ne 0) { Throw }
    } catch {
        write-Host "ERROR: Failed to properly upload files to GG4L." -ForegroundColor RED
        Stop-Transcript
        exit ($exec.ExitCode ?? 3)
    }
}

Stop-Transcript
exit
