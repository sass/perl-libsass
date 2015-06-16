Custom Action to trigger WM_SETTINGCHANGE
========================================

Taken from https://github.com/Kajabity/Setup.Projects

Windows Installer (WiX) for Apache Maven
========================================

This project folder contains a C++ Wix Custom Action project which, initially, consists of a
method to broadcast WM_SETTINGCHANGE (ANSII and Unicode versions so Win 8 works) to trigger
Windows and applications to update environment variables.

Change Log
==========

27-SEP-2013

	Added a custom action (C++ and a C# version I've deleted) to broadcast a WM_SETTINGCHANGE
	to tell Windows programs the Environment variables have changed.
	Soon after added modified to add both ANSII and Unicode to support Win 8.
	Changed to use "set" instead of "create" to force update of M2_HOME and M2.

