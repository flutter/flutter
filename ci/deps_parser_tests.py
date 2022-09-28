import os
import sys
import unittest
from deps_parser import VarImpl

SCRIPT_DIR = os.path.dirname(sys.argv[0])
CHECKOUT_ROOT = os.path.realpath(os.path.join(SCRIPT_DIR, '..'))
DEPS = os.path.join(CHECKOUT_ROOT, 'DEPS')
UPSTREAM_PREFIX = 'upstream_'


class TestDepsParserMethods(unittest.TestCase):

  # extract both mirrored dep names and URLs &
  # upstream names and URLs from DEPs file
  def setUp(self):
    with open(DEPS) as file:
      local_scope_upstream = {}
      global_scope_upstream = {'Var': lambda x: x}  # dummy lambda
      # Read the content.
      with open(DEPS, 'r') as file:
        deps_content = file.read()

      # Eval the content.
      exec(deps_content, global_scope_upstream, local_scope_upstream)

      # Extract the upstream URLs
      # vars contains more than just upstream URLs
      # however the upstream URLs are prefixed with 'upstream_'
      upstream = local_scope_upstream.get('vars')
      self.upstream_urls = upstream

      local_scope_mirror = {}
      var = VarImpl(local_scope_mirror)
      global_scope_mirror = {
          'Var': var.lookup,
          'deps_os': {},
      }

      # Eval the content.
      exec(deps_content, global_scope_mirror, local_scope_mirror)

      # Extract the deps and filter.
      deps = local_scope_mirror.get('deps', {})
      filtered_deps = []
      for _, dep in deps.items():
        # We currently do not support packages or cipd which are represented
        # as dictionaries.
        if isinstance(dep, str):
          filtered_deps.append(dep)

      self.deps = filtered_deps

  def test_each_dep_has_upstream_url(self):
    # for each DEP in the deps file, check for an associated upstream URL in deps file
    for dep in self.deps:
      dep_repo = dep.split('@')[0]
      dep_name = dep_repo.split('/')[-1].split('.')[0]
      # vulkan-deps and khronos do not have one upstream URL
      # all other deps should have an associated upstream URL for vuln scanning purposes
      if dep_name not in ('vulkan-deps', 'khronos'):
        # add the prefix on the dep name when searching for the upstream entry
        self.assertTrue(
            UPSTREAM_PREFIX + dep_name in self.upstream_urls,
            msg=dep_name + ' not found in upstream URL list'
        )

  def test_each_upstream_url_has_dep(self):

    # parse DEPS into dependency names
    deps_names = []
    for dep in self.deps:
      dep_repo = dep.split('@')[0]
      dep_name = dep_repo.split('/')[-1].split('.')[0]
      deps_names.append(dep_name)

    # for each upstream URL dep, check it exists as in DEPS
    for upsream_dep in self.upstream_urls:
      # only test on upstream deps in vars section which start with the upstream prefix
      if upsream_dep.startswith(UPSTREAM_PREFIX):
        # strip the prefix to check that it has a corresponding dependency in the DEPS file
        self.assertTrue(
            upsream_dep[len(UPSTREAM_PREFIX):] in deps_names,
            msg=upsream_dep + ' from upstream list not found in DEPS'
        )


if __name__ == '__main__':
  unittest.main()
