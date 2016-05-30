#!/bin/bash

# Create templates and instance groups with index and package generators
gcloud compute instance-templates create crossdart-server-server \
    --boot-disk-size 30GB \
    --boot-disk-type pd-standard \
    --image ubuntu-14-04 \
    --machine-type n1-standard-2 \
    --metadata-from-file startup-script=boot_server.sh \
    --scopes storage-full,compute-ro \
    --tags crossdartserver

gcloud compute instance-templates create crossdart-server-generator \
    --boot-disk-size 30GB \
    --boot-disk-type pd-standard \
    --image ubuntu-14-04 \
    --machine-type n1-standard-2 \
    --metadata-from-file startup-script=boot_generator.sh \
    --scopes storage-full,compute-ro

gcloud compute instance-groups managed create crossdart-server-servers \
    --base-instance-name crossdart-server-servers \
    --size 1 \
    --template crossdart-server-server \
    --zone us-central1-f

gcloud compute instance-groups managed create crossdart-server-generators \
    --base-instance-name crossdart-server-generators \
    --size 0 \
    --template crossdart-server-generator \
    --zone us-central1-f

