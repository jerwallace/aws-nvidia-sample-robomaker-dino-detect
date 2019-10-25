# AWS Robomaker + SparkFun NVidia JetBot ROS Application

This sample ROS1 Melodic application leverages AWS SageMaker and AWS IoT 

## Setup your AWS RoboMaker Development and Build Environment 

First, sign into the AWS Management Console and click on AWS RoboMaker. Create a new development environment using the default settings.

1. Clone this repository into your Cloud9 environment.
    ``` 
        git clone https://github.com/jerwallace/aws-nvidia-sample-robomaker-dino-detect
        cd aws-nvidia-sample-robomaker-dino-detect
    ```
1. Before we get started, you will need an S3 bucket to store your assets. Run the following command in Cloud9
    ``` 
        aws s3 mb <YOUR_BUCKET_NAME>
    ``` 
1. Copy the `roboMakerSettings.json.template` file to `roboMakerSettings.json`
```
    cp roboMakerSettings.json.template roboMakerSettings.json
    # Edit roboMakerSettings.json and replace where prompts exist
```
1. Next, we need to create a set of IoT credentials, so our application can communicate with AWS IoT. Run the following shell script to generate these:
    ``` 
        sudo chmod -R +x scripts/*.sh
        . scripts/generate_certs.sh
    ``` 
1. Now, we are ready to create our cross-compiler docker image. First, open the file cross-compiler/Dockerfile in the Cloud9 editor window. At the top of the file you will see a few arguments. 
1. In Cloud9, open a seperate terminal window as this command will take a while.
    ``` 
        cd cross-jetson-nano/
        docker build ./
    ``` 

### Congratulations! You are ready to start building ROS Melodic applications.
