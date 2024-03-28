### Helm, Kubernetes için bir paket yöneticisi ve uygulama dağıtım platformudur. Kubernetes'e kurulum, yapılandırma ve yönetim işlemlerini kolaylaştırmak için kullanılır. Helm, "chart" adı verilen paketler aracılığıyla Kubernetes uygulamalarını tanımlar ve yönetir.
#Helm'in temel bileşenleri şunlardır:
#Charts: Bir Helm paketi olan "chart"lar, Kubernetes uygulamalarını tanımlar. Her bir chart, uygulamanın kurulumunu, yapılandırmasını ve yönetimini tanımlayan dosyaları içerir. Bu dosyalar genellikle YAML formatında olup, Kubernetes kaynaklarını (örneğin, Deployment'lar, Service'ler, ConfigMap'ler vb.) tanımlar.
#Helm CLI (Command Line Interface): Helm CLI, kullanıcıların Helm komutlarını kullanarak chartları yönetmelerini sağlar. Bu komutlar aracılığıyla chartları arama, yükleme, kurulum, güncelleme ve kaldırma gibi işlemler gerçekleştirilebilir.
#Helm Repositories: Helm repositories, Helm chartlarının depolandığı yerlerdir. Resmi Helm repositories'ler yanı sıra kullanıcılar kendi özel repositories'lerini oluşturabilirler.
# Release: Bir chart'ın bir Kubernetes kümesindeki bir örneğine "release" denir. Bir release, belirli bir chart'ın belirli bir Kubernetes ortamına kurulumunu temsil eder. Her release, chart'ın kurulumunu ve yapılandırmasını temsil eden bir dizi Kubernetes kaynağına karşılık gelir.
#Helm, karmaşık Kubernetes uygulamalarının dağıtımını kolaylaştırırken, yapılandırma yönetimini ve sürüm kontrolünü de sağlar. Bu da geliştiricilere ve sistem yöneticilerine uygulamalarını daha hızlı ve güvenilir bir şekilde dağıtmalarına yardımcı olur.


helm create konzek_chart
#k8s-helm içinde bu komutu çalıştırıp helm chartları oluşturacağız.


rm -r konzek_chart/templates/*
# konzek_chart/templates oluşunca altındaki tüm dosyaları sileceğiz.

kompose convert -f docker-compose.yml -o konzek_chart/templates
#docker-compose.yml'i dönüştürerek k8s-helm/konzek_chart/templates oluşturulacak.
# Bu adımlar sayesinde chartlar oluştu ve şimdi bu chartlar için AWS S3 de chart repo oluşturacağız.


# S3de bir bucket oluşturup  stable/myapp adında bir klasör oluşturun. Bu modeldeki örnek,
# s3://konzek-helm-charts-konzek/stable/myapp adresini hedef chart reposu olarak kullanır.

aws s3api create-bucket --bucket konzek-helm-charts-konzek --region us-east-1
aws s3api put-object --bucket konzek-helm-charts-konzek --key stable/myapp/


# Install the helm-s3 plugin for Amazon S3.

helm plugin install https://github.com/hypnoglow/helm-s3.git

# On some systems we need to install ``Helm S3 plugin`` as Jenkins user to be able to use S3 with pipeline script.

sudo su -s /bin/bash jenkins
export PATH=$PATH:/usr/local/bin
helm version
helm plugin install https://github.com/hypnoglow/helm-s3.git
exit

#  ``Initialize`` the Amazon S3 Helm repository.

AWS_REGION=us-east-1 helm s3 init s3://konzek-helm-charts-konzek/stable/myapp 


#Komut, belirtilen konumda saklanan tüm grafik bilgilerini izlemek için bir index.yaml dosyası oluşturur.
#Oluşturulan index.yaml dosyasının varlığını doğrulayın.
aws s3 ls s3://konzek-helm-charts-konzek/stable/myapp/


# Add the Amazon S3 repository to Helm on the client machine. 
helm repo ls
AWS_REGION=us-east-1 helm repo add stable-konzekapp s3://konzek-helm-charts-konzek/stable/myapp/

# Update `version` and `appVersion` field of `k8s/konzek_chart/Chart.yaml` file as below for testing.

```yaml
version: 0.0.1
appVersion: 0.1.0
```

# ``Package`` the local Helm chart.

cd k8s
helm package konzek_chart/ 

# Store the local package in the Amazon S3 Helm repository.

HELM_S3_MODE=3 AWS_REGION=us-east-1 helm s3 push ./konzek_chart-0.0.1.tgz stable-konzekapp

# Push the new version to the Helm repository in Amazon S3.

HELM_S3_MODE=3 AWS_REGION=us-east-1 helm s3 push ./konzek_chart-0.0.2.tgz stable-konzekapp

# Verify the updated Helm chart.

helm repo update
helm search repo stable-konzekapp


### Bu kısımda Helm'in nasıl yapılacağını belirttim , kendim Mid-level taskini  yaparken uygulamadım fakat her adımın  yapılışını gösterdim .