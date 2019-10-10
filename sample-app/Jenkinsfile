pipeline {

  environment {
    PROJECT = "REPLACE_WITH_YOUR_PROJECT_ID"
    APP_NAME = "gceme"
    FE_SVC_NAME = "${APP_NAME}-frontend"
    CLUSTER = "jenkins-cd"
    CLUSTER_ZONE = "us-east1-d"
    IMAGE_TAG = "gcr.io/${PROJECT}/${APP_NAME}:${env.BRANCH_NAME}.${env.BUILD_NUMBER}"
    JENKINS_CRED = "${PROJECT}"
  }

  agent {
    kubernetes {
      label 'sample-app'
      defaultContainer 'jnlp'
      yaml """
apiVersion: v1
kind: Pod
metadata:
labels:
  component: ci
spec:
  # Use service account that can deploy to all namespaces
  serviceAccountName: cd-jenkins
  containers:
  - name: golang
    image: golang:1.10
    command:
    - cat
    tty: true
  - name: gcloud
    image: gcr.io/cloud-builders/gcloud
    command:
    - cat
    tty: true
  - name: kubectl
    image: gcr.io/cloud-builders/kubectl
    command:
    - cat
    tty: true
"""
}
  }
  stages {
    stage('Test') {
      steps {
        container('golang') {
          sh """
            ln -s `pwd` /go/src/sample-app
            cd /go/src/sample-app
            go test
          """
        }
      }
    }
    stage('Build and push image with Container Builder') {
      steps {
        container('gcloud') {
          sh "PYTHONUNBUFFERED=1 gcloud builds submit -t ${IMAGE_TAG} ."
        }
      }
    }
    stage('Deploy Canary') {
      // Canary branch
      when { branch 'canary' }
      steps {
        container('kubectl') {
          // Change deployed image in canary to the one we just built
          sh("sed -i.bak 's#gcr.io/cloud-solutions-images/gceme:1.0.0#${IMAGE_TAG}#' ./k8s/canary/*.yaml")
          step([$class: 'KubernetesEngineBuilder', namespace:'production', projectId: env.PROJECT, clusterName: env.CLUSTER, zone: env.CLUSTER_ZONE, manifestPattern: 'k8s/services', credentialsId: env.JENKINS_CRED, verifyDeployments: false])
          step([$class: 'KubernetesEngineBuilder', namespace:'production', projectId: env.PROJECT, clusterName: env.CLUSTER, zone: env.CLUSTER_ZONE, manifestPattern: 'k8s/canary', credentialsId: env.JENKINS_CRED, verifyDeployments: true])
          sh("echo http://`kubectl --namespace=production get service/${FE_SVC_NAME} -o jsonpath='{.status.loadBalancer.ingress[0].ip}'` > ${FE_SVC_NAME}")
        }
      }
    }
    stage('Deploy Production') {
      // Production branch
      when { branch 'master' }
      steps{
        container('kubectl') {
        // Change deployed image in canary to the one we just built
          sh("sed -i.bak 's#gcr.io/cloud-solutions-images/gceme:1.0.0#${IMAGE_TAG}#' ./k8s/production/*.yaml")
          step([$class: 'KubernetesEngineBuilder', namespace:'production', projectId: env.PROJECT, clusterName: env.CLUSTER, zone: env.CLUSTER_ZONE, manifestPattern: 'k8s/services', credentialsId: env.JENKINS_CRED, verifyDeployments: false])
          step([$class: 'KubernetesEngineBuilder', namespace:'production', projectId: env.PROJECT, clusterName: env.CLUSTER, zone: env.CLUSTER_ZONE, manifestPattern: 'k8s/production', credentialsId: env.JENKINS_CRED, verifyDeployments: true])
          sh("echo http://`kubectl --namespace=production get service/${FE_SVC_NAME} -o jsonpath='{.status.loadBalancer.ingress[0].ip}'` > ${FE_SVC_NAME}")
        }
      }
    }
    stage('Deploy Dev') {
      // Developer Branches
      when {
        not { branch 'master' }
        not { branch 'canary' }
      }
      steps {
        container('kubectl') {
          // Create namespace if it doesn't exist
          sh("kubectl get ns ${env.BRANCH_NAME} || kubectl create ns ${env.BRANCH_NAME}")
          // Don't use public load balancing for development branches
          sh("sed -i.bak 's#LoadBalancer#ClusterIP#' ./k8s/services/frontend.yaml")
          sh("sed -i.bak 's#gcr.io/cloud-solutions-images/gceme:1.0.0#${IMAGE_TAG}#' ./k8s/dev/*.yaml")
          step([$class: 'KubernetesEngineBuilder', namespace: "${env.BRANCH_NAME}", projectId: env.PROJECT, clusterName: env.CLUSTER, zone: env.CLUSTER_ZONE, manifestPattern: 'k8s/services', credentialsId: env.JENKINS_CRED, verifyDeployments: false])
          step([$class: 'KubernetesEngineBuilder', namespace: "${env.BRANCH_NAME}", projectId: env.PROJECT, clusterName: env.CLUSTER, zone: env.CLUSTER_ZONE, manifestPattern: 'k8s/dev', credentialsId: env.JENKINS_CRED, verifyDeployments: true])
          echo 'To access your environment run `kubectl proxy`'
          echo "Then access your service via http://localhost:8001/api/v1/proxy/namespaces/${env.BRANCH_NAME}/services/${FE_SVC_NAME}:80/"
        }
      }
    }
  }
}
