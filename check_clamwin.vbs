set objShell = createobject("wscript.shell")

REM Anwendung: cscript c:\Users\administrator\Desktop\check_clamwin.vbs //NoLogo

strParams = "%comspec% /c NSlookup -querytype=TXT current.cvd.clamav.net"
Set objExecObj = objShell.exec(strParams)

Do While Not objExecObj.StdOut.AtEndOfStream
﻿  strText = objExecObj.StdOut.Readline()
﻿  If instr(strText, "Server") then
﻿  ﻿  strServer = trim(replace(strText,"Server:",""))
﻿  Elseif instr (strText, "0.97") Then
﻿  ﻿  strTxt = trim(replace(strText, chr(34), ""))
﻿  ﻿  
﻿  End if
Loop

arrVersion = Split(strTxt, ":")

REM for each x in arrVersion
    REM Wscript.echo(x)
REM next
REM WScript.echo arrVersion(2)

REM Wscript.echo "Parameter: " &strParams
REM Wscript.echo "Server: " &strServer
REM Wscript.echo "Text: " & strText
REM Wscript.echo "TXT: " & strTxt
REM Wscript.echo "Online-Version: " & arrVersion(2)
REM Wscript.echo "################################"


REM ################lokale Definitionsdatei prüfen

set locobjShell = createobject("wscript.shell")

REM Path to installed clam binary.
clam_exe  = Chr(34) & "C:\Program Files (x86)\ClamWin\bin\clamscan.exe" & Chr(34) & " -V -d C:\Users\AllUse~1\.clamwin\db"
REM Path to installed clam DB.
REM clam_db = Chr(34) & "C:\Users\All Users\.clamwin\db" & Chr(34)

strParams = "%comspec% /c " & clam_exe
REM & " -V -d " & clam_db
Set objExecObj = locobjShell.exec(strParams)

Do While Not objExecObj.StdOut.AtEndOfStream
﻿  strlocText = objExecObj.StdOut.Readline()
﻿  If instr(strlocText, "ClamAV") then
﻿  ﻿  strlocServer = trim(replace(strlocText,"ClamAV",""))
﻿  ﻿  strlocTxt = trim(replace(strlocServer, Chr(34), "."))
﻿  REM Elseif instr (strlocText, "0.97") Then
﻿  ﻿  REM strlocTxt = trim(replace(strlocText, Chr(34), "."))
﻿  ﻿  
﻿  End if
Loop

arrlocVersion = Split(strlocTxt, "/")
REM Wscript.echo "Array"
REM for each xloc in arrlocVersion
    REM Wscript.echo(xloc)
REM next
REM WScript.echo arrlocVersion(1)
REM Wscript.echo "/Array"

REM Wscript.echo "Parameter: " &strParams
REM Wscript.echo "Server: " &strlocServer
REM Wscript.echo "Text: " & strlocText
REM Wscript.echo "TXT: " & strlocTxt
REM Wscript.echo "Installierte Version: " & arrlocVersion(1)

set cdb1 = createobject("wscript.shell")

versiononline = arrVersion(2)
versionlokal = arrlocVersion(1)
versionwarn = 3
versioncrit = 5

REM versiononline = 20
REM versionlokal = 17
if versiononline<versionlokal Then
REM﻿  Wscript.echo "o<l"
﻿  versiondiff = versionlokal - versiononline
ElseIf versiononline>versionlokal Then
REM﻿  Wscript.echo "l<o"
﻿  versiondiff = versiononline - versionlokal
﻿  REM -- = +
Else
REM﻿  Wscript.echo "o=l"
﻿  versiondiff = 0
End If
REM Wscript.echo "Versionsunterschied: " & versiondiff
REM Wscript.echo "Versiononline: " & versiononline
REM Wscript.echo "Versionlokal: " & versionlokal

pd_text = versiononline & ";" & versionlokal & ";" & versionwarn & ";" & versioncrit
﻿  if versiondiff = 0 Then
﻿  ﻿  exit_text = "OK - Installierte Definition ist aktuell"
﻿  ElseIf versiondiff >= versioncrit Then
﻿  ﻿  exit_text = "CRITICAL - Installierte Definition um " & versiondiff & " veraltet"
﻿  ElseIf versiondiff >= versionwarn Then
﻿  ﻿  exit_text = "WARNING - Installierte Definition um " & versiondiff & " veraltet"
﻿  ElseIf versiondiff < versionwarn Then
﻿  ﻿  exit_text = "OK - Installierte Definition um " & versiondiff & " veraltet"
﻿  End If
﻿  REM Wscript.echo versiononline & " ist grösser als " & versionlokal
﻿  REM exit_text = "Installierte Definition ist veraltet"


Wscript.echo exit_text & "|" & pd_text
