"""Evaluate the checked-in authentic job gate across public/fork contexts offline."""
import ast,itertools,re,unittest
from pathlib import Path
class WorkflowSafety(unittest.TestCase):
 def test_actions_are_commit_pinned_and_private_inputs_not_uploaded(self):
  self.assertIn('* text=auto eol=lf',(Path(__file__).resolve().parents[1]/'.gitattributes').read_text(encoding='utf-8'))
  workflows=Path(__file__).resolve().parents[1]/'.github/workflows'
  for path in workflows.glob('*.yml'):
   text=path.read_text(encoding='utf-8')
   for action in re.findall(r'uses:\s*([^\s#]+)',text):
    if not action.startswith('./'):
     self.assertRegex(action,r'^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+@[0-9a-f]{40}$')
   self.assertNotIn('pull_request_target',text)
   self.assertIn('persist-credentials: false',text)
  private=(workflows/'authentic.yml').read_text(encoding='utf-8')
  self.assertNotIn('actions/upload-artifact',private)
  synthetic=(workflows/'ci.yml').read_text(encoding='utf-8')
  self.assertRegex(synthetic,r'path: artifacts/tool/')
 def test_private_upstream_only(self):
  text=(Path(__file__).resolve().parents[1]/'.github/workflows/authentic.yml').read_text(encoding='utf-8')
  predicate=re.search(r'^    if: (.+)$',text,re.M)[1]
  for repository,private,fork in itertools.product(['tkgo11/undertale-routekeeper','other/undertale-routekeeper'],[False,True],[False,True]):
   expression=predicate.replace('github.repository',repr(repository)).replace('github.event.repository.private',repr(private)).replace('github.event.repository.fork',repr(fork)).replace('true','True').replace('false','False').replace('&&',' and ')
   tree=ast.parse(expression,mode='eval')
   self.assertTrue(all(isinstance(n,(ast.Expression,ast.Compare,ast.BoolOp,ast.And,ast.Eq,ast.Constant)) for n in ast.walk(tree)))
   self.assertEqual(eval(compile(tree,'<workflow gate>','eval'),{'__builtins__':{}}),repository=='tkgo11/undertale-routekeeper' and private and not fork)
if __name__=='__main__':unittest.main()
