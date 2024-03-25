
docker tag frontend-server:latest ${ECR_REGISTRY}/${APP_REPO_NAME}:frontend-server-v1

docker tag backend-server:latest ${ECR_REGISTRY}/${APP_REPO_NAME}:backend-server-v1

docker tag database-server:latest ${ECR_REGISTRY}/${APP_REPO_NAME}:database-server-v1

