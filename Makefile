.PHONY: all setup build build_robot build_simulation bundle bundle_robot bundle_simulation clean clean_robot_build clean_robot_bundle clean_simulation_build clean_simulation_bundle
.DEFAULT_GOAL := all

all: bundle

# This forces each step in 'ci' to run in serial, but each step will run all of its commands in parallel
ci:
	$(MAKE) setup
	$(MAKE) build
	$(MAKE) bundle

setup:
	scripts/setup.sh

build: build_robot build_simulation

build_robot:
	aws ssm send-command --document-name "AWS-RunShellScript" --document-version "1" --targets "Key=instanceids,Values=i-02ce0a5de7e8db1a7" --parameters '{"workingDirectory":["/home/ubuntu/"],"executionTimeout":["3600"],"commands":["./build.sh -b rootfs-nano/"]}' --timeout-seconds 600 --max-concurrency "50" --max-errors "0" --output-s3-bucket-name "dinobot-robomaker-assets" --output-s3-key-prefix "build-logs" --region us-west-2

build_simulation:
	scripts/build.sh ./simulation_ws

bundle: bundle_robot bundle_simulation

bundle_robot: build_robot
	scripts/bundle.sh ./robot_ws

bundle_simulation: build_simulation
	scripts/bundle.sh ./simulation_ws

clean: clean_robot_build clean_robot_bundle clean_simulation_build clean_simulation_bundle

clean_robot_build:
	rm -rf ./robot_ws/build ./robot_ws/install

clean_robot_bundle:
	rm -rf ./robot_ws/bundle

clean_simulation_build:
	rm -rf ./simulation_ws/build ./simulation_ws/install

clean_simulation_bundle:
	rm -rf ./simulation_ws/bundle
