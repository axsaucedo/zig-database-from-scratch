# Configuration file for the Sphinx documentation builder.

project = 'Building a Database in Zig'
copyright = '2024, DB Tutorial Zig'
author = 'DB Tutorial Zig Contributors'
release = '1.0.0'

extensions = [
    'sphinx.ext.autodoc',
    'sphinx.ext.viewcode',
]

templates_path = ['_templates']
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']

html_theme = 'alabaster'
html_static_path = ['_static']
html_theme_options = {
    'description': 'Building a Database from Scratch in Zig',
    'github_user': 'db-tutorial',
    'github_repo': 'db_tutorial_zig',
}

# Allow literalinclude from parent directory
import os
import sys
sys.path.insert(0, os.path.abspath('..'))
