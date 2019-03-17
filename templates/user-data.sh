#!/bin/bash

# Setup ECS container agent
echo ">>> Attach ECS instance to [${ecs_cluster}]" >&2
cat > /etc/ecs/ecs.config <<-EOF
ECS_CLUSTER=${ecs_cluster}
ECS_INSTANCE_ATTRIBUTES=${ecs_attributes}
EOF

# It may take some time to attach the EBS volume
for i in {1..20} ; do
    if [ -e "${ebs_volume}" ] ; then
        break;
    fi

    echo ">>> Waiting for EBS volume attachment...[$i]" >&2
    sleep 1s
done

# Attach EBS volume
if [ -e "${ebs_volume}" ] ; then
    fs_type=$(file -s ${ebs_volume} | awk '{print $2}')

    echo ">>> Mount volume [${ebs_volume}] to [${ecs_volume}]" >&2

    if [ "$fs_type" = "data" ] ; then
        echo "Creating file system on [${ebs_volume}]" >&2
        mkfs -t ext4 ${ebs_volume}
    fi

    mkdir -p "${ecs_volume}"
    mount ${ebs_volume} "${ecs_volume}"
    echo  ${ebs_volume} "${ecs_volume}" ext4 defaults,nofail 0 2 >> /etc/fstab
else
    echo ">>> No EBS volume [${ebs_volume}] found for [${ecs_volume}]" >&2
fi

# Initialize OpenVPN server
/usr/bin/openvpn build-server
