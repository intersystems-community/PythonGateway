import irisnative
from notebook.services.contents.manager import ContentsManager
import json
from traitlets import Unicode, Integer, HasTraits

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
        return True

    def rename_file(self, old_path, new_path):
        '''
        Rename a file or directory.
        '''
        return True

    def file_exists(self, path):
        '''
        Does a file exist at the given path?
        '''
        return True

    def dir_exists(self, path):
        '''
        Does a directory exist at the given path?
        '''
        return True

    def is_hidden(self, path):
        return False

