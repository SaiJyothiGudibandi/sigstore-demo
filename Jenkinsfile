pipeline {
//     agent { docker { image 'maven:3.8.7-eclipse-temurin-11' } }
    agent any
    stages {
        stage('Docker Build') {
            steps {
                sh 'ls -al'
                sh 'docker build -t sigstore-demo-image:1.0.0 .'
            }
        }
    }
}
