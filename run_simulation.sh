echo "###############################################################################"
echo " RUN SIMULATION "
echo "###############################################################################"

BUCKET_SOURCE=borospotsource
JOB_ROLE=arn:aws:iam::448733523991:role/tborospotrole
ROBOT_APPLICATION=arn:aws:robomaker:us-west-2:448733523991:robot-application/Spot1/1608564193018
SIMULATION_APPLICATION=arn:aws:robomaker:us-west-2:448733523991:simulation-application/Spot1_sim/1608130519861
MAX_JOB_DURATION=3600
BASE_DIR=`pwd`
ROS_SIM_DIR=$BASE_DIR/simulation_ws
ROS_APP_DIR=$BASE_DIR/robot_ws

./build_robot.sh
./build_simulation.sh

echo "Copy the robot application source bundle to your Amazon S3 bucket"

aws s3 cp $ROS_APP_DIR/bundle/output.tar s3://$BUCKET_SOURCE/spot1.tar

aws robomaker create-robot-application --name Spot1 --sources s3Bucket=$BUCKET_SOURCE,s3Key=spot1.tar,architecture=X86_64 --robot-software-suite name=ROS,version=Melodic


echo "Copy the simulation application source bundle to your Amazon S3 bucket"

aws s3 cp $ROS_SIM_DIR/bundle/output.tar s3://$BUCKET_SOURCE/spot1_sim.tar


aws robomaker create-simulation-application --name Spot1_sim --sources s3Bucket=$bucket_source,s3Key=spot1_sim.tar,architecture=X86_64 --robot-software-suite name=ROS,version=Melodic --simulation-software-suite name=Gazebo,version=9 --rendering-engine name=OGRE,version=1.x


echo "###############################################################################"
echo " Create simulation job "
echo "###############################################################################"


aws robomaker create-simulation-job --max-job-duration-in-seconds $MAX_JOB_DURATION --iam-role $JOB_ROLE --output-location s3Bucket=borospotoutput,s3Prefix=job --robot-applications application=$ROBOT_APPLICATION,launchConfig='{packageName=rs_inverse,launchFile=inverse.launch}' --simulation-applications application=$SIMULATION_APPLICATION,launchConfig='{packageName=rs_gazebo,launchFile=HQ.launch}'
