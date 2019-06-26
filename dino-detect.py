#!/usr/bin/env python3
import torch
import torchvision
import torch.nn.functional as F
import time
import logging
import datetime
import numpy as np
import cv2
import torchvision.transforms as transforms
import PIL.Image
import base64
import json
import random
from jetbot import Camera, Robot
from AWSIoTPythonSDK.MQTTLib import AWSIoTMQTTClient

DEBUG = True
FORMAT = '%(asctime)-15s %(message)s'
device = None
config = None
settings = {
    "normalize": None,
    "mean_roadfollow": None,
    "std_roadfollow": None
}
angle = 0.0
angle_last = 0.0

def preprocess(camera_value):
    global device, settings
    x = camera_value
    x = cv2.cvtColor(x, cv2.COLOR_BGR2RGB)
    x = x.transpose((2, 0, 1))
    x = torch.from_numpy(x).float()
    x = settings.normalize(x)
    x = x.to(device)
    x = x[None, ...]
    return x

def preprocess_roadfollow(image):
    global device, settings
    image = PIL.Image.fromarray(image)
    image = transforms.functional.to_tensor(image).to(device).half()
    image.sub_(settings.mean_roadfollow[:, None, None]).div_(settings.std_roadfollow[:, None, None])
    return image[None, ...]

def find_dino(change):
    x = change['new'] 
    x = preprocess(x)
    y = model_dinodet(x)
    y_dino = F.softmax(y, dim=1)
    topk = y_dino.cpu().topk(1)
    return (e.data.numpy().squeeze().tolist() for e in topk)

def move_bot(image, robot_stop):
    global angle, angle_last    
    if robot_stop:
        robot.stop()
        robot.left_motor.value=0
        robot.left_motor.value=0
        time.sleep(2)
        robot_stop = False
    else:
        xy = model_roadfollow(preprocess_roadfollow(image)).detach().float().cpu().numpy().flatten()
        x = xy[0]
        y = (0.5 - xy[1]) / 2.0
        angle = np.arctan2(x, y)
        pid = angle * config.steering_gain_slider + (angle - angle_last) * config.steering_dgain_slider
        angle_last = angle
        steering_slider = pid + config.steering_bias_slider
        robot.left_motor.value = max(min(config.speed_gain_slider + steering_slider, 1.0), 0.0)
        robot.right_motor.value = max(min(config.speed_gain_slider - steering_slider, 1.0), 0.0)

def dino_app()    
    global config, settings, device

    # Pull in the app arguments. Today, this is just the logging level. 
    # TODO: Add other configuration settings. 
    if (DEBUG):
        logging.basicConfig(format=FORMAT, level=logging.DEBUG)
        logger = logging.getLogger('dino-detect')
        ddlogger.info("Set logger to DEBUG mode.")
    else:
        logging.basicConfig(level=logging.ERROR)
        logger.info("Set logger to ERROR mode.")

    # Load in the log config files from a local config as well as the default greengrass config.
    ddlogger.info("Loading app config file...")
    with open('config.json') as json_config_file:
        config = json.load(json_config_file)

    ddlogger.info("Loading greengrass config file...")
    with open('/greengrass/config/config.json') as json_gg_config_file:
        gg_config = json.load(json_gg_config_file)

    # Initialize the JetBot Robot.
    ddlogger.info("Starting cuda...")
    device = torch.device('cuda')
    ddlogger.info("Initializing robot on I2C Bus %i...", config.i2c_bus)
    robot = Robot(i2c_bus=config.i2c_bus)
    camera = Camera.instance(width=config.image_size[0], height=config.image_size[1])
    mean = config.np_value * np.array(config.mean_values)
    stdev = config.np_value * np.array(config.std_values)
    settings.mean_roadfollow = torch.Tensor(config.mean_values).cuda().half()
    settings.std_roadfollow = torch.Tensor(config.std_values).cuda().half()

    ddlogger.info("Initializing ML models...")
    ddlogger.info("Road following model...")
    model_roadfollow = torchvision.models.resnet18(pretrained=False)
    model_roadfollow.fc = torch.nn.Linear(512, 2)
    model_roadfollow.load_state_dict(torch.load(config.road_following_model))
    
    model = model_roadfollow.to(device)
    model = model_roadfollow.eval().half()

    ddlogger.info("Dino detection model...")
    model_dinodet = torchvision.models.resnet18(pretrained=False)
    model_dinodet.fc = torch.nn.Linear(512, 6)
    model_dinodet.load_state_dict(torch.load(config.dino_detect_model))

    model_dinodet = model_dinodet.to(device)
    model_dinodet = model_dinodet.eval()

    prev_class = config.prev_class

    # Initialize the AWS IoT Connection based on AWS Greengrass config. 
    ddlogger.info("Initializing AWS IoT...")
    logger = logging.getLogger("AWSIoTPythonSDK.core")
    streamHandler = logging.StreamHandler()
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    streamHandler.setFormatter(formatter)
    logger.addHandler(streamHandler)
    
    iotClient = None
    iotClient = AWSIoTMQTTClient('jetbot'+random.randint(1,101))
    iotClient.configureEndpoint(gg_config.coreThing.iotHost, 8843)
    iotClient.configureCredentials(gg_config.coreThing.caPath, gg_config.coreThing.keyPath, gg_config.coreThing.certPath)
    iotClient.connect()

    ddlogger.info("Starting application loop...")
    while True:
        settings.normalize = torchvision.transforms.Normalize(mean, stdev)
        img = camera.value
        robot_stop = False
        probs, classes = find_dino({'new': img}) 
        if probs > 0.6 and prev_class != classes:
            prev_class = classes
            robot_stop = True
            if classes == 5:
                ddlogger.info("Found unknown dinosaur...")
                message = {
                    "dinosaur": "unknown",
                    "confidence": str(probs),
                    "image": base64.b64encode(img)
                }
            else:
                ddlogger.info("Found %s...", config.dino_names[classes])
                message = {
                    "dinosaur": config.dino_names[classes],
                    "confidence": str(probs),
                    "image": base64.b64encode(img)
                }
            iotClient.publish(config.topic, json.dumps(message), 1)
        move_bot(img, robot_stop)

if __name__ == main():
    dino_app()
