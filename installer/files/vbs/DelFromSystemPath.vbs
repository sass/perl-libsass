Sub DelFromSystemPath (strnewPath)

	Set WshShell = WScript.CreateObject("WScript.Shell")

	On Error Resume Next

	'Read the system path. Exit on errors.
	strPath = WshShell.RegRead("HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\Path")

	If Err.Number <> 0 Then Exit Sub

	strnewPath = strnewPath & ";"

	If Instr(strPath, strnewPath) > 0 Then

		strPath = Replace(strPath,strnewPath,"")

		WshShell.RegWrite "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\Path", strPath, "REG_EXPAND_SZ"

		If Err.Number = 0 Then
			WScript.Echo "System path updated to:" & vbCrLf & strPath
		Else
			WScript.Echo "Path not updated - no updates necessary."
		End If

	Else
		Wscript.Echo "Not in the global path: " & strnewPath
	End if

End Sub

Set args = WScript.Arguments
DelFromSystemPath(args(0))

WinSendMessage(HWND_BROADCAST, WM_SETTINGCHANGE, (WPARAM)NULL, (LPARAM)"Environment");