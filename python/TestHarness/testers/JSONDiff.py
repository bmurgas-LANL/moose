#* This file is part of the MOOSE framework
#* https://www.mooseframework.org
#*
#* All rights reserved, see COPYRIGHT for full restrictions
#* https://github.com/idaholab/moose/blob/master/COPYRIGHT
#*
#* Licensed under LGPL 2.1, please see LICENSE for details
#* https://www.gnu.org/licenses/lgpl-2.1.html

from SchemaDiff import SchemaDiff
from TestHarness import util
class JSONDiff(SchemaDiff):

    @staticmethod
    def validParams():
        params = SchemaDiff.validParams()
        params.addRequiredParam('jsondiff',   [], "A list of JSON files to compare.")
        params.addParam('skip_keys', [],"Deprecated. Items in the JSON that the differ will ignore. This is functionally identical to ignored_items inside of SchemaDiff.")
        return params

    def __init__(self, name, params):
        params['schemadiff'] = params['jsondiff']
        params['ignored_items'] += params['skip_keys']
        SchemaDiff.__init__(self, name, params)

    def prepare(self, options):
        if self.specs['delete_output_before_running'] == True:
            util.deleteFilesAndFolders(self.getTestDir(), self.specs['jsondiff'])

    def load_file(self, path1):
        import json
        with open(path1,"r") as f:
            return json.loads(f.read())
