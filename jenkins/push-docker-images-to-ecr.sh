# Provide credentials for Docker to login the AWS ECR and push the images
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY} 
docker push "${IMAGE_TAG_FRONTEND_SERVER}"
docker push "${IMAGE_TAG_BACKEND_SERVER}"
docker push "${IMAGE_TAG_DATABASE_SERVER}"