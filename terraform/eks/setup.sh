#!/bin/bash

#Run after terraform to add support for kub dashboard

#Metric server
wget -O v0.3.7.tar.gz https://codeload.github.com/kubernetes-sigs/metrics-server/tar.gz/v0.3.7 \
&& tar -xzf v0.3.7.tar.gz \
&& kubectl apply -f metrics-server-0.3.7/deploy/1.8+/

#Kub dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.4/aio/deploy/recommended.yaml
kubectl apply -f ./eks-admin-service-account.yaml
##Return token for login
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user-token | awk '{print $1}')

