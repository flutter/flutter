# Implementing a new language feature

When a new language feature is approved, a tracking issue will be created in
order to track the work required in the `analyzer` package. Separate issues are
created to track the work in the `analysis_server`, `dartdoc`, and `linter`
packages.

Below is a template for the list of analyzer features that need to be reviewed
to see whether they need to be enhanced in order to work correctly with the new
feature. In almost all cases new tests will need to be written to ensure that
the feature isn't broken when run over code that uses the new language feature.
In some cases, new support will need to be added.

Separate issues should be created for each of the items in the list.

## Template

The following is a list of the individual features that need to be considered.
The features are listed roughly in dependency order.

- [ ] AST enhancements
- [ ] Element model
- [ ] Type system updates
- [ ] Summary support
- [ ] Resolution
- [ ] Constant evaluation
- [ ] Index and search
