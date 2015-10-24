# The GN build definitions for these variables are in scripts.gni.
{
    'variables': {
        'scripts_for_in_files': [
            # jinja2/__init__.py contains version string, so sufficient as
            # dependency for whole jinja2 package
            '<(DEPTH)/third_party/jinja2/__init__.py',
            '<(DEPTH)/third_party/markupsafe/__init__.py',  # jinja2 dep
            'hasher.py',
            'in_file.py',
            'in_generator.py',
            'license.py',
            'name_macros.py',
            'name_utilities.py',
            'template_expander.py',
            'templates/macros.tmpl',
        ],
        'make_event_factory_files': [
            '<@(scripts_for_in_files)',
            'make_event_factory.py',
        ],
        'make_names_files': [
            '<@(scripts_for_in_files)',
            'make_names.py',
            'templates/MakeNames.cpp.tmpl',
            'templates/MakeNames.h.tmpl',
        ],
        'conditions': [
            ['OS=="win"', {
                'gperf_exe': '<(DEPTH)/third_party/gperf/bin/gperf.exe',
                'bison_exe': '<(DEPTH)/third_party/bison/bin/bison.exe',
              },{
                'gperf_exe': 'gperf',
                'bison_exe': 'bison',
              }],
         ],
    },
}
