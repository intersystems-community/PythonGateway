/// Python shell
Class isc.py.util.Shell
{

/// Start Python Shell.
/// Press enter to quit.
/// do ##class(isc.py.util.Shell).Shell()
ClassMethod Shell()
{
	try {
		for {
			write "PY>"
			read command, !
			quit:(command="quit()")||(command="")
			kill result
			if (command [ "=") {
				set sc = ##class(isc.py.Main).SimpleString(command) //, $p(command, "="), , .result)
			} else {
				set sc = ##class(isc.py.Main).SimpleString("zzzresult=" _ command,"zzzresult", , .result)
			}
			if sc {
				write $g(result)
			} else {
				write $System.Status.GetErrorText(sc)
			}
			write !
		}
	} catch ex {
		#dim ex As %Exception.General
		write ex.DisplayString(),!
	}
}

}

