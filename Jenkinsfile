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

        stage('Simple DB') {
          steps {
            script {
              def host_ip = '127.0.0.1'
              def cont_port = 389
              def container
              try {
                def test_dir = 'tests/simple-db'
                def volumes = "$WORKSPACE/$test_dir/config:/etc/openldap/config:ro"
                container = docker.image("${IMAGE}").run("-p $host_ip::$cont_port -v $volumes")
                sleep 5
                def host_port = container.port(cont_port).tokenize(':')[1]
                def root_dn = 'cn=admin,dc=example,dc=org'
                def root_pw = 'toor'
                def ldif = "$test_dir/data/example.ldif"
                sh "ldapadd -h $host_ip -p $host_port -D $root_dn -w '$root_pw' -f $ldif"
                def search_base = 'dc=example,dc=org'
                def search_scope = 'sub'
                def search_filter = '(objectClass=inetOrgPerson)'
                sh "ldapsearch -h $host_ip -p $host_port -x -LLL " +
                  "-b $search_base -s $search_scope '$search_filter'"
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
