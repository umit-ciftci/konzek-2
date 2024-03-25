docker build --force-rm -t "${IMAGE_TAG_BACKEND_SERVER}" "${WORKSPACE}/backend-server"
docker build --force-rm -t "${IMAGE_TAG_FRONTEND_SERVER}" "${WORKSPACE}/frontend-server"
docker build --force-rm -t "${IMAGE_TAG_DATABASE_SERVER}" "${WORKSPACE}/database-server"