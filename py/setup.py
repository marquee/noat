from setuptools import setup

setup(
        name                = 'noat',
        version             = '1.0.0',
        description         = 'Non-overlapping annotation HTML tag insertion.',
        long_description    = file('README.md').read(),
        url                 = 'https://github.com/droptype/noat',
        author              = 'Alec Perkins',
        author_email        = 'alec@droptype.com',
        license             = 'UNLICENSE',
        packages            = ['noat'],
        zip_safe            = False,
        keywords            = 'html tags tagging annotations annotation text',
        classifiers         = [
            'Development Status :: 5 - Production/Stable',
            'Intended Audience :: Developers',
            'License :: Public Domain',
            'Programming Language :: Python :: 3',
            'Programming Language :: Python :: 2',
            'Programming Language :: Python :: Implementation :: CPython',
            'Programming Language :: Python :: Implementation :: PyPy',
            'Topic :: Internet :: WWW/HTTP :: Dynamic Content',
            'Topic :: Text Processing :: Markup :: HTML',
        ],
    )