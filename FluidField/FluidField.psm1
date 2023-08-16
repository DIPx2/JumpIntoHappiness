    # 4 - Ëîêàëüíûé êàòàëîã íå ñóùåñòâóåò
    # 8 - Íåò ôàéëîâ â êàòàëîãå îòïðàâêè
    # 12 - Îòïðàâêà èç ëîêàëüíîãî êàòàëîãà íà FTP ïðîèçîøëà
    # 16 - Ôàéë â êàòàëîãå îòïðàâêè íå ñîîòâåòñòâóåò øàáëîíó îòïðàâêè
    # 20 - Ëîãèí èëè ïàðîëü íåêîððåêòíû
    # 24 - Ñåðâåð íå îòâå÷àåò
    # 28 - FTP-êàòàëîã áåç ôàéëîâ 
    # 32 - Ôàéë íà FTP, íå ñîîòâåòñòâóåò øàáëîíó ïîëó÷åíèÿ
    # 36 - Çàãðóçêà ôàéëà èç êàòàëîãà FTP-ñåðâåðà â ëîêàëüíûé êàòàëîã ïðîèçîøëà
    # 40 - Ôàéë èç êàòàëîãà FTP-ñåðâåðà â ëîêàëüíûé êàòàëîã íå ìîæåò áûòü ïðèíÿò
    # 44 - Ôàéë èç êàòàëîãà FTP-ñåðâåðà óäàëåí ïîñëå ïîëó÷åíèÿ
    # 48 - Ïðîãðàììà "FM" íå óñòàíîâëåíà èëè óñòàíîâëåíà íåêîððåêòíî
    # 52 - Íåò êàòàëîãà èëè ôàéëà íà FTP


Function EmitterIP{
param( [Parameter(Mandatory=$true)] [string] $site )
try{ Test-Connection -Protocol DCOM -ComputerName $site -Count 2 | Out-Null
     Write-Output $true 
    } catch {Write-Output $false}
} #********************************************************************************************
Function Run-Give {

param(  [Parameter(Mandatory=$true)] [string] $Site,
        [Parameter(Mandatory=$true)] [string] $User,
        [Parameter(Mandatory=$true)] [string] $Password,
        [Parameter(Mandatory=$true)] [string] $FtpDirectory,
        [Parameter(Mandatory=$true)] [string] $localPath,
        [Parameter(Mandatory=$true)] [string] $LocalFilePattern
)

$report = @()
# 4 - Ëîêàëüíûé êàòàëîã íå ñóùåñòâóåò
if ( (Test-Path -Path $localPath) -eq $false ) { return $report += ( "4"+"|"+"*" ) }
$dump = Get-ChildItem -Path $localPath -Name -File
# 8 - Íåò ôàéëîâ â êàòàëîãå îòïðàâêè
if ( $dump.Length -eq 0 ) { return $report += ( "8"+"|"+"*" ) }
    foreach ( $I in $dump ){
        if ($I.trim() -match $LocalFilePattern){ 
            $xf = Send-FtpFile  -Site $Site `
                                -User $User `
                                -Password $Password `
                                -FtpDirectory $FtpDirectory `
                                -localPath $LocalPath `
                                -FtpFileName $I.Trim()
            
            if ( $xf -match "successfully copied") { 
                 Remove-Item -Path  ( Join-Path $localPath $I )
                 $report += ( "12"+"|"+ $i)  # 12 - Îòïðàâêà èç ëîêàëüíîãî êàòàëîãà íà FTP ïðîèçîøëà
            }

        } else {
            # 16 - Ôàéë â êàòàëîãå îòïðàâêè íå ñîîòâåòñòâóåò øàáëîíó îòïðàâêè
            $report += ( "16"+"|"+ $i )        }
    }

return $report
} #********************************************************************************************
Function Run-Get {

param(  [Parameter(Mandatory=$true)] [string] $Site,
        [Parameter(Mandatory=$true)] [string] $User,
        [Parameter(Mandatory=$true)] [string] $Password,
        [Parameter(Mandatory=$true)] [string] $FtpDirectory,
        [Parameter(Mandatory=$true)] [string] $FTPFile,
        [Parameter(Mandatory=$true)] [string] $localPath
)

$report = @()

Function Get-List_FILES { Param ([Parameter(Mandatory=$true)] [string[]] $Dump) 
return ($Dump[$Dump.Count..1]) -match "FILE" | % {($_.Remove($_.IndexOf("("), $_.Length - $_.IndexOf("("))).Remove(0,7)} }

# 4 - Ëîêàëüíûé êàòàëîã íå ñóùåñòâóåò
if ( (Test-Path -Path $localPath) -eq $false ) { return $report += ( "4"+"|"+"*" ) }

$BigDump = Show-FtpFile -Site $Site -User $User -Password $Password -FtpDirectory $FtpDirectory -ftpFileName "*"

if ( $BigDump -match "no such file or directory" ) { return $report += ( "52"+"|" +"*") }
if ( $BigDump -match "Login or Password incorrect." ) { return $report += ( "20"+"|"+"*" ) }
if ( $BigDump -match "Timed out trying to connect!" ) { return $report += ( "24"+"|" +"*") }

$OnlyFILE = Get-List_FILES -Dump ( $BigDump )

Write-Output $OnlyFILE

# 28 - FTP-êàòàëîã áåç ôàéëîâ 
if ($OnlyFILE.count -eq 0){ return $report += ( "28"+"|"+"*" ) } 
    else  { foreach ( $j in $OnlyFILE ) {
                # 32 - Ôàéë íà FTP, ñîîòâåòñòâóåò øàáëîíó ïîëó÷åíèÿ
                #if ( $j.Trim() -notmatch $FTPFile ) { return $report += ( "32"+"|"+$j.Trim() ) }
                if ( $j.Trim() -notmatch $FTPFile ) { $report += ( "32"+"|"+$j.Trim() ) }
                if ( $j.Trim() -match $FTPFile ) {
                    [string]$e = Get-FtpFile -site $Site -user $User -password $Password -ftpDirectory $FtpDirectory -ftpFileName $j.Trim() -LocalPath $localPath
                    # 36 - Çàãðóçêà ôàéëà èç êàòàëîãà FTP-ñåðâåðà â ëîêàëüíûé êàòàëîã ïðîèçîøëà
                    if ($e -match "successfully downloaded to"){ $report += ( "36"+"|"+$j.Trim() ) }
                    # 40 - Ôàéë èç êàòàëîãà FTP-ñåðâåðà â ëîêàëüíûé êàòàëîã íå ìîæåò áûòü ïðèíÿò
                    if ($e -match "No files were found"){ return $report += ( "40"+"|"+$j.Trim() ); continue }
                    $q = Remove-FtpFile -site $Site -user $User -password $Password -ftpDirectory $FtpDirectory -ftpFileName $j.Trim()
                    # 44 - Ôàéë èç êàòàëîãà FTP-ñåðâåðà óäàëåí ïîñëå ïîëó÷åíèÿ
                    if ($q -match "successfully deleted"){ $report += ( "44"+"|"+$j.Trim() ) }
                } 
           }
     }
Write-Output $report
} #********************************************************************************************
Function Relay_Tr { Param ( [Parameter(Mandatory=$true)] [xml] $abibas )


$TreasuryClientPatternRecive = ( "{0}{1}{2}{3}" -f "[emldv]", $abibas.ini.TreasuryClient.PayRegNum, "[0-9]*\.", $abibas.ini.TreasuryClient.TreasCode )
$TreasuryClientPatternSend = ( "{0}{1}{2}{3}" -f "[fpqhw]", $abibas.ini.TreasuryClient.TreasCode, "[0-9]*\.", $abibas.ini.TreasuryClient.PayRegNum )

    #----------
    $argument_3 = @{}
    $report_3 = Run-Get  -Site $abibas.ini.FTP_Sever.IP_FTP`
                         -User $abibas.ini.FTP_Sever.FTPUserName`
                         -Password $abibas.ini.FTP_Sever.FTPUserPassword`
                         -FtpDirectory $abibas.ini.TreasuryClient.FTPDIRout`
                         -localPath $abibas.ini.TreasuryClient.MailIn`
                         -FTPFile $TreasuryClientPatternRecive
                         

    $argument_3.add( "localPath", $abibas.ini.TreasuryClient.MailIn )
    $argument_3.add( "FtpDirectory", $abibas.ini.TreasuryClient.FTPDIRout )
    $argument_3.add( "Description", "IT" ) # èíôî-ôàéë äëÿ Êëèåíòà-ÒÊ

    Blogging -event $report_3 -argument $argument_3

    #----------
    $argument_2 = @{}
    $report_2 = Run-Get  -Site $abibas.ini.FTP_Sever.IP_FTP`
                         -User $abibas.ini.FTP_Sever.FTPUserName`
                         -Password $abibas.ini.FTP_Sever.FTPUserPassword`
                         -FtpDirectory $abibas.ini.TreasuryClient.FTPDIRout`
                         -FTPFile "[CLTK][0-9]*\.UPD"`
                         -localPath $abibas.ini.TreasuryClient.MailIn

    $argument_2.add( "localPath", $abibas.ini.TreasuryClient.MailIn )
    $argument_2.add( "FtpDirectory", $abibas.ini.TreasuryClient.FTPDIRout )
    $argument_2.add( "Description", "UT" ) # îáíîâëåíèå äëÿ Êëèåíòà-ÒÊ

    Blogging -event $report_2 -argument $argument_2
    #----------
    $argument_A = @{}
    $report_A = Run-Give    -Site $abibas.ini.FTP_Sever.IP_FTP`
                            -User $abibas.ini.FTP_Sever.FTPUserName`
                            -Password $abibas.ini.FTP_Sever.FTPUserPassword`
                            -FtpDirectory $abibas.ini.TreasuryClient.FTPDIRin`
                            -localPath $abibas.ini.TreasuryClient.MailOut`
                            -LocalFilePattern $TreasuryClientPatternSend

    $argument_A.add( "localPath", $abibas.ini.TreasuryClient.MailOut )
    $argument_A.add( "FtpDirectory", $abibas.ini.TreasuryClient.FTPDIRin )
    $argument_A.add( "Description", "TKi" ) # îò Êëèåíòà-ÒÊ

    Blogging -event $report_A -argument $argument_A
} #********************************************************************************************
Function Relay_Fi { Param ( [Parameter(Mandatory=$true)] [xml] $abibas )

$FinanceClientPatternRecive = ( "{0}-{1}-{2}{3}" -f $abibas.ini.FinanceClient.DistrictCode, $abibas.ini.FinanceClient.PayRegNumFin, $abibas.ini.FinanceClient.TreasAccNum,"[A-Za-z0-9]{0,5}\.que" ) 
$FinanceClientPatternSend = ( "{0}-{1}-{2}{3}" -f $abibas.ini.FinanceClient.DistrictCode, $abibas.ini.FinanceClient.TreasAccNum, $abibas.ini.FinanceClient.PayRegNumFin, "[A-Za-z0-9]{0,5}\.que" )

$FMpth = ( Get-ChildItem -Path HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\ |`
           where {$_.Name -match "Ïðèëîæåíèå Êîìïëåêñ çàäà÷ «Ãëàâíûé ðàñïîðÿäèòåë" } |`
           Get-ItemProperty ).'Inno Setup: App Path'

if ( $FMpth -like "" ) { Blogging -event "48|*" }

    #----------
    $argument_0 = @{}
    $report_0 = Run-Get  -Site $abibas.ini.FTP_Sever.IP_FTP`
                         -User $abibas.ini.FTP_Sever.FTPUserName`
                         -Password $abibas.ini.FTP_Sever.FTPUserPassword`
                         -FtpDirectory $abibas.ini.FinanceClient.FTPDIRout`
                         -localPath $abibas.ini.FinanceClient.MailIn`
                         -FTPFile $FinanceClientPatternRecive
                         

    $argument_0.add( "localPath", $abibas.ini.FinanceClient.MailIn )
    $argument_0.add( "FtpDirectory", $abibas.ini.FinanceClient.FTPDIRout )
    $argument_0.add( "Description", "IG" ) # èíôî-ôàéë äëÿ ÃÐÑ

    Blogging -event $report_0 -argument $argument_0

    #----------
    $argument_1 = @{}
    $report_1 = Run-Get  -Site $abibas.ini.FTP_Sever.IP_FTP`
                         -User $abibas.ini.FTP_Sever.FTPUserName`
                         -Password $abibas.ini.FTP_Sever.FTPUserPassword`
                         -FtpDirectory $abibas.ini.FinanceClient.FTPDIRout`
                         -FTPFile "Update\d*\.rar"`
                         -localPath $abibas.ini.FinanceClient.MailIn

    $argument_1.add( "localPath", $abibas.ini.FinanceClient.MailIn )
    $argument_1.add( "FtpDirectory", $abibas.ini.FinanceClient.FTPDIRout )
    $argument_1.add( "Description", "UG" ) # îáíîâëåíèå äëÿ ÃÐÑ

    Blogging -event $report_1 -argument $argument_1

    foreach ($b in  $report_1) { 
        if ($b.count -ne 0) { 
            if ( $FMpth -and $b.StartsWith("36") ) { Set-Location $FMpth; Start-Process -FilePath ( Join-Path $FMpth "Update.exe") -ArgumentList a }
        }
    } 

    #----------
    $argument_B = @{}
    $report_B = Run-Give -Site $abibas.ini.FTP_Sever.IP_FTP`
                         -User $abibas.ini.FTP_Sever.FTPUserName`
                         -Password $abibas.ini.FTP_Sever.FTPUserPassword`
                         -FtpDirectory $abibas.ini.FinanceClient.FTPDIRin`
                         -localPath $abibas.ini.FinanceClient.MailOut`
                         -LocalFilePattern $FinanceClientPatternSend

    $argument_B.add("localPath", $abibas.ini.FinanceClient.MailOut)
    $argument_B.add( "FtpDirectory", $abibas.ini.FinanceClient.FTPDIRin )
    $argument_B.add( "Description", "FMi" ) # èç FM

    Blogging -event $report_B -argument $argument_B
    #----------

    Write-Output ""

} #********************************************************************************************
