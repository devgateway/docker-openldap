#!/usr/bin/env groovy
pipeline {
  agent any

  environment {
    HTTP_PROXY  = 'http://proxy.devgateway.org:3128/'
    HTTPS_PROXY = 'http://proxy.devgateway.org:3128/'
    THIS_JOB = "<${env.BUILD_URL}|${env.JOB_NAME} ${env.BUILD_NUMBER}>"
    APP_NAME = 'openldap'
    IMAGE = "devgateway/${APP_NAME}:${env.BRANCH_NAME}"
  }

  stages {

    stage('Build') {
      steps {
        script {
          def image = docker.build("${IMAGE}")
          docker.withRegistry('http://localhost:5000') {
            image.push()
          }
        }
      }
    } // stage

    stage('Test') {
      failFast true
      parallel {

        stage('Test A') {
          steps {
            script {
              docker.withRegistry('http://localhost:5000') {
                def image = docker.image("${IMAGE}")
                image.withRun("-v ${env.WORKSPACE}/tests/a:/var/lib/ldap:rw") {
                }
              }
            }
          }
        }

      } // parallel
    } // Test

  } // stages

  post {
    success {
      slackSend(message: "Built ${THIS_JOB}", color: "good")
    }

    failure {
      slackSend(message: "Failed ${THIS_JOB}", color: "danger")
    }
  }
}
