def _get_feature(name):
    import __future__
    # fall back to a unique fake object for earlier Python versions or Python 3
    return getattr(__future__, name, object())

unicode_literals = _get_feature("unicode_literals")
with_statement = _get_feature("with_statement")
division = _get_feature("division")
print_function = _get_feature("print_function")
absolute_import = _get_feature("absolute_import")
nested_scopes = _get_feature("nested_scopes")  # dummy
generators = _get_feature("generators")  # dummy

del _get_feature
