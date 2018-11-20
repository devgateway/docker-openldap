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

        stage('Smoke test') {
          steps {
            script {
              def host_ip = '127.0.0.1'
              def cont_port = 389
              def container
              try {
                container = docker.image("${IMAGE}").run("-p $host_ip::$cont_port")
                sleep 5
                def host_port = container.port(cont_port).tokenize(':')[1]
                sh "ldapsearch -h $host_ip -p $host_port -x -LLL -b cn=Subschema -s base " +
                  '\'(objectClass=subschema)\' createTimestamp modifyTimestamp objectClass'
              } finally {
                container.stop()
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
