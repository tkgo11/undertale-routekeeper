"""Evaluate the checked-in authentic job gate across public/fork contexts offline."""
import ast,itertools,re,unittest
from pathlib import Path
class WorkflowSafety(unittest.TestCase):
 def test_private_upstream_only(self):
  text=(Path(__file__).resolve().parents[1]/'.github/workflows/authentic.yml').read_text()
  predicate=re.search(r'^    if: (.+)$',text,re.M)[1]
  for repository,private,fork in itertools.product(['tkgo11/undertale-routekeeper','other/undertale-routekeeper'],[False,True],[False,True]):
   expression=predicate.replace('github.repository',repr(repository)).replace('github.event.repository.private',repr(private)).replace('github.event.repository.fork',repr(fork)).replace('true','True').replace('false','False').replace('&&',' and ')
   tree=ast.parse(expression,mode='eval')
   self.assertTrue(all(isinstance(n,(ast.Expression,ast.Compare,ast.BoolOp,ast.And,ast.Eq,ast.Constant)) for n in ast.walk(tree)))
   self.assertEqual(eval(compile(tree,'<workflow gate>','eval'),{'__builtins__':{}}),repository=='tkgo11/undertale-routekeeper' and private and not fork)
if __name__=='__main__':unittest.main()
