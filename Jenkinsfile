#!/usr/bin/env groovy
pipeline {
  agent any

  environment {
    HTTP_PROXY  = 'http://proxy.devgateway.org:3128/'
    HTTPS_PROXY = 'http://proxy.devgateway.org:3128/'
    APP_NAME = 'openldap'
    IMAGE = "devgateway/$APP_NAME:$BRANCH_NAME"
    LOCALHOST = '127.0.0.1'
    LDAP_PORT = 389
    ROOT_DN = 'cn=admin,dc=example,dc=org'
    ROOT_PW = 'toor'
  }

  stages {

    stage('Build') {
      steps {
        script {
          def image = docker.build("$IMAGE")
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
              def search_base = 'cn=Subschema'
              def search_scope = 'base'
              def search_filter = '(objectClass=subschema)'
              def search_attrs = 'createTimestamp modifyTimestamp objectClass'
              def container
              try {
                container = docker.image("$IMAGE").run("-p $LOCALHOST::$LDAP_PORT")
                sleep 5
                def mapped_port = container.port(env.LDAP_PORT.toInteger()).tokenize(':')[1]
                sh "ldapsearch -h $LOCALHOST -p $mapped_port -x -LLL " +
                  "-b $search_base -s $search_scope '$search_filter' $search_attrs"
              } finally {
                container.stop()
              }
            }
          }
        }

        stage('Simple DB') {
          steps {
            script {
              def search_base = 'dc=example,dc=org'
              def search_scope = 'sub'
              def search_filter = '(objectClass=inetOrgPerson)'
              def test_dir = 'tests/simple-db'
              def volumes = "$WORKSPACE/$test_dir/config:/etc/openldap/config:ro"
              def ldif = "$test_dir/data/example.ldif"
              def container
              try {
                container = docker.image("$IMAGE").run("-p $LOCALHOST::$LDAP_PORT -v $volumes")
                sleep 5
                def mapped_port = container.port(env.LDAP_PORT.toInteger()).tokenize(':')[1]
                sh "ldapadd -h $LOCALHOST -p $mapped_port -D $ROOT_DN -w '$ROOT_PW' -f $ldif"
                sh "ldapsearch -h $LOCALHOST -p $mapped_port -x -LLL " +
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
      script {
        def msg = sh(
          returnStdout: true,
          script: 'git log --oneline --format=%B -n 1 HEAD | head -n 1'
        )
        slackSend(
          message: "Built <$BUILD_URL|$JOB_NAME $BUILD_NUMBER>: $msg",
          color: "good"
        )
      }
    }
  }
}
