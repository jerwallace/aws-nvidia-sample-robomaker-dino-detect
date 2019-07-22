#
# Copyright 2010-2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#

# This lambda function simply copies the ML models to the tmp directory, where they can be referenced by RoboMaker-deployed ROS applications 

import time
import shutil
import os

DEST_DIR = "/tmp/trained_models"
SRC_DIR = "/trained_models"

def cpdir(src, dest):
    try:
        shutil.copytree(src, dest)
    except shutil.Error as e:
        print('Could not copy directory. ERROR: %s' % e)
    except OSError as e:
        print('Could not copy directory. ERROR: %s' % e)
        
print("First invoke, clearing models from tmp...")
if os.path.isdir(DEST_DIR):
    shutil.rmtree(DEST_DIR)
   
# When deployed to a Greengrass core, this code will be executed immediately
# as a long-lived lambda function.  The code will enter the infinite while loop
# below.
# If you execute a 'test' on the Lambda Console, this test will fail by hitting the
# execution timeout of three seconds.  This is expected as this function never returns
# a result.

while True:
    print("Checking for new models...")
    
    if os.path.isdir(DEST_DIR):
        print("Models already copied.")
    else:
        print("Models not copied...")
        print("Copying the files from mlModel to tmp.")
        cpdir(SRC_DIR, DEST_DIR)
    
    print("Sleeping for 1 minute.")
    time.sleep(60)
    
# This is a dummy handler and will not be invoked
# Instead the code above will be executed in an infinite loop for our example
def function_handler(event, context):
    return