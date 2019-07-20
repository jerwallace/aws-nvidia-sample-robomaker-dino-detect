
# Copyright 2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
from setuptools import setup, find_packages

# Package meta-data.
NAME = 'dinobot'
REQUIRES_PYTHON = '>=3.5.0'

setup(
    name=NAME,
    version='0.0.1',
    packages=find_packages(),
    python_requires=REQUIRES_PYTHON,
    install_requires=[
        'Adafruit_SSD1306==1.6.2',
        'boto3==1.9.23',
        'Adafruit_MotorHAT==1.4.0',
        'rospkg==1.1.7'
    ]
)