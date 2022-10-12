#Requires -Version 7.1

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
$gg4lhostkey = "02:4c:6d:15:57:59:d0:d6:4b:26:ee:90:b9:0f:74:94"

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
    if (-Not($CognosConfig)) {
        $CognosConfig = 'DefaultConfig'
    }
    Connect-ToCognos -ConfigName $CognosConfig
} catch {
    Write-Host "Error: Failed to connect to Cognos." -ForegroundColor Red
    exit 1
}

$results = $reports | ForEach-Object -Parallel {
    #report title
    $PSitem

    #pull in session to script block
    $CognosSession = $using:CognosSession
    $CognosDSN = $using:CognosDSN
    $CognosProfile = $using:CognosProfile
    $CognosUser = $using:CognosUsername
    
    #Run Cognos Download using incoming options.
    Save-CognosReport -report "$PSItem" -cognosfolder "_Shared Data File Reports\ParentNotices-Transact-GG4L" -savepath "$using:PSScriptRoot\files" -FileName "$($PSItem).csv" -TeamContent -reportparams "p_stu_pass=&p_staff_pass=&p_parent_pass=" #We have to awknowledge the prompts even if we don't answer them directly.
    
} -AsJob -ThrottleLimit 5 | Wait-Job #Please don't overload the Cognos Server.

$results.ChildJobs | Where-Object { $PSItem.State -eq "Completed" } | Receive-Job

#Output any failed jobs information.
$failedJobs = $results.ChildJobs | Where-Object { $PSItem.State -ne "Completed" }
$failedJobs | ForEach-Object {
    $PSItem | Receive-Job
}

if (($failedJobs | Measure-Object).count -ge 1) {
    Write-Host "Failed running", (($failedJobs | Measure-Object).count), "jobs." -ForegroundColor RED
    exit(2)
}

} #close skip download.

if (-Not($SkipUpload)) {
    try {
        Write-Host "Info: Uploading files to GG4L..." -ForegroundColor YELLOW
        $exec = Start-Process -FilePath "$PSScriptRoot\bin\pscp.exe" -ArgumentList "-pw ""$gg4lpassword"" -hostkey $gg4lhostkey -r $PSScriptRoot\files\*.csv $($gg4lusername)@upload.gg4l.com:/" -PassThru -Wait -NoNewWindow
        if ($exec.ExitCode -ge 1) { Throw }
    } catch {
        write-Host "ERROR: Failed to properly upload files to GG4L." -ForegroundColor RED
        Stop-Transcript
        exit(3)
    }
}

Stop-Transcript
exit