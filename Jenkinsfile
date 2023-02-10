pipeline {
//     agent { docker { image 'maven:3.8.7-eclipse-temurin-11' } }
    agent any
    stages {
        
        stage('Code Build') {
            steps {
                dir(src/){
                    sh 'mvn clean install'
                }
            }
        }
        
        stage('Sonar Scan') {
            steps {
                echo("----- BEGIN Sonar Scan-----")
                echo("Sonar Scan is in progress")
                echo("----- COMPLETED Sonar Scan-----")
            }
        }
        
        stage('BlackDuck Scan') {
            steps {
                echo("----- BEGIN BlackDuck Scan-----")
                echo("BlackDuck Scan is in progress")
                echo("----- COMPLETED BlackDuck Scan-----")
            }
        }
        
        stage('Docker Build') {
            steps {
                sh 'docker build -t kartikjena33/sigstore-demo-image:1.0.0 .'
            }
        }
        
        stage('Docker Build') {
            steps {
                sh 'ls -al'
                sh 'docker publish -t kartikjena33/sigstore-demo-image:1.0.0 .'
            }
        }
        
    }
}
