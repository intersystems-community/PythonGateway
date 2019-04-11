/// Python shell
Class isc.py.util.Shell
{

/// Start Python Shell.
/// Press enter to quit.
/// do ##class(isc.py.util.Shell).Shell()
ClassMethod Shell()
{
	try {
		#dim multi As %Boolean = $$$NO
		for {
			write $case(multi, $$$YES:"...", :"PY>")
			read command, !
			
			if multi = $$$NO {
				// enter multi mode if line ends on :
				set multi = ($e($zstrip(command,">W"),*)=":")
			} elseif command = "" {
				// leave multi mode
				set multi = $$$NO
				set command = $g(multiCommand) _ $c(10) _ command
				kill multiCommand
			}
			
			if multi {
				set multiCommand = $g(multiCommand) _ $c(10) _ command
			} else {
				quit:(command="quit()")||(command="")
				kill result
				if ((command [ "=") || (command [ $c(10))) {
					set sc = ##class(isc.py.Main).SimpleString(command) //, $p(command, "="), , .result)
				} else {
					if ($zcvt(command, "l")["import") {
						set sc = ##class(isc.py.Main).SimpleString(command)
					} else {
						set sc = ##class(isc.py.Main).SimpleString("zzzresult=" _ command,"zzzresult", , .result)
					}
				}
				if sc {
					write $replace($g(result), $c(10), $$$NL)
				} else {
					write $System.Status.GetErrorText(sc)
				}
				write !
			}
		}
	} catch ex {
		#dim ex As %Exception.General
		write ex.DisplayString(),!
	}
}

}

