pipeline {
    agent any
    options {
        timestamps()
    }
    environment {
        CI = 'true'
        SQL_USER = credentials('SQL_USER')
    }
    stages {
        stage("Init") {
            steps {
                sh "make init"
            }
        }
        stage("Down") {
            steps {
                sh "make docker-down-clear"
            }
        }
    }
    post {
        always {
            sh 'make docker-down-clear || true'
        }
    }
}