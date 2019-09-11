exec(open("MLContentsManager.py").read())

c.NotebookApp.contents_manager_class = MLContentsManager

c.MLContentsManager.port = 51776
