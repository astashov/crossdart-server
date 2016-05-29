#!/bin/bash

# Create templates and instance groups with index and package generators
gcloud compute instance-templates create crossdart-server \
    --boot-disk-size 30GB \
    --boot-disk-type pd-standard \
    --image ubuntu-14-04 \
    --machine-type n1-standard-2 \
    --metadata-from-file startup-script=boot.sh \
    --scopes storage-full,compute-ro \
    --tags crossdartserver

gcloud compute instance-groups managed create crossdart-servers \
    --base-instance-name crossdart-servers \
    --size 1 \
    --template crossdart-server \
    --zone us-central1-f
