import irisnative
from notebook.services.contents.manager import ContentsManager
import json
from traitlets import Unicode, Integer, HasTraits, default

class MLContentsManager(ContentsManager, HasTraits):

    port = Integer(
        default_value=51773,
        config=True,
        help="InterSystems IRIS SuperServer port number.",
    )

    host = Unicode(
        default_value='localhost',
        config=True,
        help="InterSystems IRIS server address.",
    )

    namespace = Unicode(
        default_value='USER',
        config=True,
        help="InterSystems IRIS namespace.",
    )

    user = Unicode(
        default_value='_SYSTEM',
        config=True,
        help="InterSystems IRIS User",
    )

    password = Unicode(
        default_value='SYS',
        config=True,
        help='InterSystems IRIS Password',
    )


    @default('checkpoints_class')
    def _checkpoints_class_default(self):
        return MLCheckpoints

    className = 'isc.py.util.Jupyter'

    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        conn = irisnative.createConnection(self.host, self.port, self.namespace, self.user, self.password)
        self.iris = irisnative.createIris(conn)


    def get(self, path, content=True, type=None, format=None):
        '''
        Get the file (bpl) or directory (package) at path.
        '''
        model = self.iris.classMethodValue(self.className, 'Get', path, content, type, format)
        return json.loads(model)

    def save(self, model, path):
        '''
        Save a file or directory model to path.
        '''
        self.iris.classMethodValue(self.className, 'Save', json.dumps(model), path)
        model = self.get(path, content=False)
        model['content'] = None
        model['format'] = None
        return model

    def delete_file(self, path):
        '''
        Delete the file or directory at path.
        '''
        return self.iris.classMethodValue(self.className, 'Delete', path)

    def rename_file(self, old_path, new_path):
        '''
        Rename a file or directory.
        '''
        return self.iris.classMethodValue(self.className, 'Rename', old_path, new_path)

    def file_exists(self, path):
        '''
        Does a file exist at the given path?
        '''
        return self.iris.classMethodValue(self.className, 'Exists', path)

    def dir_exists(self, path):
        '''
        Does a directory exist at the given path?
        '''
        return self.iris.classMethodValue(self.className, 'ExistsDir', path)

    def is_hidden(self, path):
        return False

from notebook.services.contents.checkpoints import (
    Checkpoints,
    GenericCheckpointsMixin,
)

class MLCheckpoints(GenericCheckpointsMixin, Checkpoints):
    className = 'isc.py.util.JupyterCheckpoints'


    """requires the following methods:"""
    def create_file_checkpoint(self, content, format, path):
        """ -> checkpoint model"""
        return self.parent.iris.classMethodValue(self.className, 'CreateFile',  json.dumps(content), format, path)


    def create_notebook_checkpoint(self, nb, path):
        """ -> checkpoint model"""
        return self.parent.iris.classMethodValue(self.className, 'CreateNotebook', json.dumps(nb), path)

    def get_file_checkpoint(self, checkpoint_id, path):
        """ -> {'type': 'file', 'content': <str>, 'format': {'text', 'base64'}}"""
        #return self.parent.iris.classMethodValue(self.className, 'CreateNotebook', nb, path)
        return self.parent.get(path, True, None)

    def get_notebook_checkpoint(self, checkpoint_id, path):
        """ -> {'type': 'notebook', 'content': <output of nbformat.read>}"""
        return self.parent.get(path, True, 'text')

    def delete_checkpoint(self, checkpoint_id, path):
        """deletes a checkpoint for a file"""
        return self.parent.iris.classMethodValue(self.className, 'DeleteCheckpoint', checkpoint_id, path)

    def list_checkpoints(self, path):
        """returns a list of checkpoint models for a given file,
        default just does one per file
        """
        return []

    def rename_checkpoint(self, checkpoint_id, old_path, new_path):
        """renames checkpoint from old path to new path"""
        return self.parent.iris.classMethodValue(self.className, 'RenameCheckpoint', checkpoint_id, old_path, new_path)