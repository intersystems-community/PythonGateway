Class isc.py.util.JupyterCheckpoints Extends isc.py.util.Jupyter
{

ClassMethod CreateFile(content, format, path)
{
	do ..Log(,"CreateFile", path, content,, format)
	quit $$$YES
}

ClassMethod CreateNotebook(nb, path)
{
	do ..Log(,"CreateNotebook",path,nb)
	quit $$$YES
}

ClassMethod DeleteCheckpoint(checkpointId, path)
{
	do ..Log(,"DeleteCheckpoint",path, checkpointId)
	quit $$$YES
}

ClassMethod RenameCheckpoint(checkpointId, oldPath, newPath)
{
	do ..Log(,"RenameCheckpoint",oldPath, checkpointId, newPath)
	quit $$$YES
}

}

