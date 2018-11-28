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
    LDAPS_PORT = 636
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
      parallel {

        stage('Smoke test') {
          steps {
            withDockerContainer(image: env.IMAGE, args: '-u 0:0') {
              sh '''
                /slapinit.sh &
                for i in $(seq 60); do
                  sleep 1
                  ldapsearch -H ldap://localhost -x -LLL -b cn=Subschema -s base \
                      '(objectClass=subschema)' createTimestamp modifyTimestamp objectClass \
                    && break
                done
                '''
            }
          }
        }

        stage('Simple DB') {
          steps {
            withDockerContainer(
              image: env.IMAGE,
              args: "-u 0:0 -v $WORKSPACE/tests/simple-db/config:/etc/openldap/config:ro"
            ) {
              sh """
                export LDAPURI=ldap://localhost
                /slapinit.sh &
                for i in \$(seq 60); do
                  sleep 1
                  ldapsearch -x -b cn=Subschema -s base > /dev/null && break || :
                done
                ldapadd -D $ROOT_DN -w '$ROOT_PW' -f "$WORKSPACE/tests/simple-db/data/example.ldif"
                ldapsearch -x -LLL -b dc=example,dc=org '(objectClass=inetOrgPerson)'
              """
            }
          }
        }

        stage('TLS') {
          steps {
            withDockerContainer(
              image: env.IMAGE,
              args: "-u 0:0 -v $WORKSPACE/tests/tls/config:/etc/openldap/config:ro " +
                '-e LISTEN_URIS=ldaps:///'
            ) {
              sh """
                export LDAPTLS_REQCERT=allow
                /slapinit.sh &
                for i in \$(seq 60); do
                  sleep 1
                  ldapsearch -H ldaps://localhost -x -LLL -b cn=Subschema -s base \
                      '(objectClass=subschema)' createTimestamp modifyTimestamp objectClass \
                    && break
                done
              """
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
