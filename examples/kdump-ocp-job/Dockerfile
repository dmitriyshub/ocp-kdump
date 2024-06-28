FROM quay.med.one:8443/openshift/ubi8/ubi
LABEL io.k8s.description="ubi8 kdump vmcore upload service" \
      io.k8s.display-name="kdump-vmcore-upload-service" \
      io.openshift.tags="kdump-vmcore-upload-service"


# Install AWS CLI
RUN yum install -y aws-cli

# Copy the script into the image
COPY upload-kdump-vmcore-to-s3.sh /usr/local/bin/upload-vmcore-to-s3.sh

# Make the script executable
RUN chmod +x /usr/local/bin/upload-kdump-vmcore-to-s3.sh

USER 1001

# Set the entrypoint to the script
ENTRYPOINT ["/usr/local/bin/upload-vmcore-to-s3.sh"]