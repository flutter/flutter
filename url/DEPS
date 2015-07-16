include_rules = [
  "+jni",

  # Limit files that can depend on icu.
  "-base/i18n",
  "-third_party/icu",
]

specific_include_rules = {
  "url_canon_icu(\.cc|_unittest\.cc)": [
    "+third_party/icu",
  ],
}
