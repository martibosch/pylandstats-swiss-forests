from setuptools import find_packages, setup

_descr = 'Analysis of forest evolution in some Swiss cantons with PyLandStats'
setup(
    name='swiss-forests',
    packages=['swiss_forests'],
    version='0.1.0',
    description=_descr,
    author='Martí Bosch',
    license='GPL-3.0',
)
