kubectl apply -f backend-deployment.yaml
kubectl apply -f frontend-deployment.yaml
kubectl apply -f database-deployment.yaml
kubectl apply -f frontend-hpa.yaml
kubectl apply -f backend-hpa.yaml
kubectl apply -f database-hpa.yaml