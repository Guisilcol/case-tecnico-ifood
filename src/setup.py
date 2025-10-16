"""Setup configuration for shared module."""

from setuptools import setup, find_packages

setup(
    name="shared",
    version="0.1.0",
    description="Shared utilities for data processing",
    packages=find_packages(include=["shared", "shared.*"]),
    python_requires=">=3.8",
    install_requires=[],
)
