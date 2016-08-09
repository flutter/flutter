{
  'conditions': [
    # Handle build types.
    ['buildtype=="Dev"', {
      'includes': ['internal/release_impl.gypi'],
    }],
    ['buildtype=="Dev" and incremental_chrome_dll==1', {
      'msvs_settings': {
        'VCLinkerTool': {
          # Enable incremental linking and disable conflicting link options:
          # http://msdn.microsoft.com/en-us/library/4khtbfyf.aspx
          'LinkIncremental': '2',
          'OptimizeReferences': '1',
          'EnableCOMDATFolding': '1',
          'Profile': 'false',
        },
      },
    }],
    ['buildtype=="Official"', {
      'includes': ['internal/release_impl_official.gypi'],
    }],
    # TODO(bradnelson): may also need:
    #     checksenabled
    #     coverage
    #     dom_stats
    #     pgo_instrument
    #     pgo_optimize
  ],
}
